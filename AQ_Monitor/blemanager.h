#ifndef BLEMANAGER_H
#define BLEMANAGER_H

#include <QObject>
#include <QtBluetooth>
#include "filedownloader.h"

typedef enum{
    NONE,
    RECEIVING,
    SENDING
}DataDirection;


typedef struct Packet{
    QChar type;
    uint total_len;
    uint current_len;
    QString data;
    DataDirection status;
}Packet;

class BleManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString receivedData READ receivedData NOTIFY receivedDataChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(QString deviceID READ deviceID NOTIFY deviceIDChanged)

public:
    explicit BleManager(QObject *parent = nullptr, FileDownloader *_fileDownloader = nullptr);

    Q_INVOKABLE void startScan();
    Q_INVOKABLE void sendData(const QString &text);
    Q_INVOKABLE QString dataReceived(){return packet.data;}
    Q_INVOKABLE double flashProgressReceived(){return flashingProgress;}
    Q_INVOKABLE void resetDevice(void);
    Q_INVOKABLE double downloadProgressReceived(){return downloadProgress;}
    Q_INVOKABLE void isNewDevice(bool state){
        if(state){
            m_deviceID = "HC-42"; emit deviceIDChanged(); deviceID() = m_deviceID;
        }else{
            m_deviceID = ""; emit deviceIDChanged(); deviceID() = m_deviceID;
        }
    }
    Q_INVOKABLE void autoScanConnect(bool state){
        autoConnectEnabled = state;
    }

    QString receivedData() const { return packet.data; }//m_receivedData
    QString status() const { return m_status; }
    void requestBlePermissions();
    QString deviceID() const {return m_deviceID;}

signals:
    void receivedDataChanged();
    void statusChanged();
    void flashProgressChanged();
    void downloadProgressChanged();
    void deviceIDChanged();

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
    void send_ack(void);
    void send_nack(void);
    void send_EOF(void);
    void sendPacket(QString str);
    void m_sendData(void);
    void retryScan();

private:
    void setStatus(const QString &s);

    QBluetoothDeviceDiscoveryAgent *discoveryAgent;
    QLowEnergyController *controller = nullptr;
    QLowEnergyService *uartService = nullptr;
    QLowEnergyCharacteristic uartChar;
    QBluetoothSocket *socket = nullptr;


    QString m_sendingData;
    QString m_status;
    QString m_deviceID;

    bool bleStatus = false;
    bool autoConnectEnabled = false;
    double flashingProgress = 0.00;
    double downloadProgress = 0.00;


    bool m_ready = false;
    bool m_dataAvailable = false;

    FileDownloader* fileDownloader = nullptr;

    const QBluetoothUuid UART_SERVICE_UUID =
        QBluetoothUuid("0000FFE0-0000-1000-8000-00805F9B34FB");
    const QBluetoothUuid UART_CHAR_UUID =
        QBluetoothUuid("0000FFE1-0000-1000-8000-00805F9B34FB");//
    const QBluetoothUuid CCCID = QBluetoothUuid("00002902-0000-1000-8000-00805F9B34FB");

    Packet packet;
    Packet outPacket;
};
#endif // BLEMANAGER_H

#pragma once



