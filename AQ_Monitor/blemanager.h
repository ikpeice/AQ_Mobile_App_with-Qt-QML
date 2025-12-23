#ifndef BLEMANAGER_H
#define BLEMANAGER_H

#include <QObject>
#include <QtBluetooth>


typedef struct Packet{
    QChar type;
    unsigned int total_len;
    unsigned int current_len;
    QChar data[512];
}Packet;

class BleManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString receivedData READ receivedData NOTIFY receivedDataChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)

public:
    explicit BleManager(QObject *parent = nullptr);

    Q_INVOKABLE void startScan();
    Q_INVOKABLE void sendData(const QString &text);

    QString receivedData() const { return m_receivedData; }
    QString status() const { return m_status; }
    void requestBlePermissions();

signals:
    void receivedDataChanged();
    void statusChanged();

private slots:
    void deviceDiscovered(const QBluetoothDeviceInfo &info);
    void scanFinished();
    void controllerConnected();
    void controllerDisconnected();
    void serviceScanDone();
    void serviceStateChanged(QLowEnergyService::ServiceState s);
    void characteristicChanged(const QLowEnergyCharacteristic &, const QByteArray &value);
    void startBleScan();
    void process_data(QString data);

private:
    void setStatus(const QString &s);

    QBluetoothDeviceDiscoveryAgent *discoveryAgent;
    QLowEnergyController *controller = nullptr;
    QLowEnergyService *uartService = nullptr;
    QLowEnergyCharacteristic uartChar;
    QBluetoothSocket *socket = nullptr;

    QString m_receivedData;
    QString m_status;

    bool m_ready = false;
    bool m_dataAvailable = false;

    const QBluetoothUuid UART_SERVICE_UUID =
        QBluetoothUuid("0000FFE0-0000-1000-8000-00805F9B34FB");
    const QBluetoothUuid UART_CHAR_UUID =
        QBluetoothUuid("0000FFE1-0000-1000-8000-00805F9B34FB");//
    const QBluetoothUuid CCCID = QBluetoothUuid("00002902-0000-1000-8000-00805F9B34FB");

    Packet packet;
};
#endif // BLEMANAGER_H

#pragma once



