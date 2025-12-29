#include "blemanager.h"
#include <QDebug>
#include <QTimer>

#include <QJniObject>
#include <QJniEnvironment>
#include <QStringList>
#include <QBluetoothPermission>
#include <QPermission>

#include <QBluetoothSocket>


#define HEADER_PACKET '~'
#define DATA_PACKET '>'
#define ACK_PACKET '<'
#define NACK_PACKET '?'
#define EOF_PACKET '@'

#define MAX_DATA_LEN 220



void requestQtBlePermission(QObject *context, std::function<void()> onGranted)
{
    QBluetoothPermission permission;
    permission.setCommunicationModes(QBluetoothPermission::Access);

    switch (qApp->checkPermission(permission)) {

    case Qt::PermissionStatus::Granted:
        onGranted();
        break;

    case Qt::PermissionStatus::Denied:
        qWarning() << "Bluetooth permission denied permanently";
        break;

    case Qt::PermissionStatus::Undetermined:
        qApp->requestPermission(permission, context,
                                [onGranted](const QPermission &perm) {
                                    if (perm.status() == Qt::PermissionStatus::Granted) {
                                        onGranted();
                                    } else {
                                        qWarning() << "Bluetooth permission denied";
                                    }
                                });
        break;
    }
}

BleManager::BleManager(QObject *parent, FileDownloader *_fileDownloader)
    : QObject(parent)
{
    discoveryAgent = new QBluetoothDeviceDiscoveryAgent(this);
    discoveryAgent->setLowEnergyDiscoveryTimeout(5000);
    packet.current_len = 0;
    packet.data = "";
    packet.total_len = 0;
    packet.type = ' ';
    fileDownloader = _fileDownloader;
    connect(fileDownloader, &FileDownloader::chunckReady, this, [this]{
        if(bleStatus == true){
            sendData(fileDownloader->chunckFile);
        }else{
            qDebug()<<"[BLE]: Disconnected";
        }

    });
}



void BleManager::setStatus(const QString &s)
{
    m_status = s;
    emit statusChanged();
}

void BleManager::startBleScan()
{
    auto *agent = new QBluetoothDeviceDiscoveryAgent(this);
    agent->setLowEnergyDiscoveryTimeout(5000);

    discoveryAgent = agent;
    connect(discoveryAgent, &QBluetoothDeviceDiscoveryAgent::deviceDiscovered,
            this, &BleManager::deviceDiscovered);
    connect(discoveryAgent, &QBluetoothDeviceDiscoveryAgent::finished,
            this, &BleManager::scanFinished);

    agent->start(QBluetoothDeviceDiscoveryAgent::LowEnergyMethod);
}

void BleManager::startScan()
{
    requestQtBlePermission(this, [this]() {
        setStatus("Scanning...");
        // discoveryAgent->start(QBluetoothDeviceDiscoveryAgent::LowEnergyMethod);
        startBleScan();
    });
}

void BleManager::deviceDiscovered(const QBluetoothDeviceInfo &info)
{
    qDebug() << "BLE:" << info.name() << info.address().toString();

    if (info.name().contains("2iBA", Qt::CaseInsensitive)) {
        discoveryAgent->stop();
        setStatus("Connecting...");

        controller = QLowEnergyController::createCentral(info, this);

        connect(controller, &QLowEnergyController::connected,
                this, &BleManager::controllerConnected);
        connect(controller, &QLowEnergyController::disconnected,
                this, &BleManager::controllerDisconnected);
        connect(controller, &QLowEnergyController::discoveryFinished,
                this, &BleManager::serviceScanDone);

        controller->connectToDevice();

    }
}

void BleManager::scanFinished()
{
    setStatus("Scan finished");
}

void BleManager::controllerConnected()
{
    bleStatus = true;
    setStatus("Connected, discovering services...");
    controller->discoverServices();
}

void BleManager::controllerDisconnected()
{
    setStatus("Disconnected");
    bleStatus = false;
}

void BleManager::serviceScanDone()
{
    uartService = controller->createServiceObject(UART_SERVICE_UUID, this);
    if (!uartService) {
        setStatus("UART service not found");
        return;
    }

    connect(uartService, &QLowEnergyService::stateChanged,
            this, &BleManager::serviceStateChanged);
    connect(uartService, &QLowEnergyService::characteristicChanged,
            this, &BleManager::characteristicChanged);

    // connect(uartService, &QLowEnergyService::characteristicRead, this, [](
    //     const QLowEnergyCharacteristic &info, const QByteArray &value){
    //     qDebug()<< info.name().toStdString()<< ": "<< value.toStdString();
    // });

    uartService->discoverDetails();
}

void BleManager::serviceStateChanged(QLowEnergyService::ServiceState s)
{
    if (s != QLowEnergyService::RemoteServiceDiscovered)
        return;

    uartChar = uartService->characteristic(UART_CHAR_UUID);
    if (!uartChar.isValid()) {
        setStatus("UART char not found");
        return;
    }

    setStatus("Ready");

    qDebug() << "Enable notifications";
    QLowEnergyDescriptor notificationDesc = uartChar.descriptor(
        QBluetoothUuid(CCCID)//UART_CHAR_UUID"00002902-0000-1000-8000-00805F9B34FB"
        );

    if (notificationDesc.isValid()) {
        uartService->writeDescriptor(notificationDesc, QByteArray::fromHex("0100")); // enable notifications
    }

}

void BleManager::send_ack(void){
    QString data = "*<00#";
    sendPacket(data);
}
void BleManager::send_nack(void){
    QString data = "*?00#";
    sendPacket(data);
}
void BleManager::send_EOF(void){
    QString data = "*@00#";
    sendPacket(data);
}

void BleManager::process_data(QString data){
    if(data.startsWith('*') && data.endsWith('#')){
        packet.type = data[1];
        if(packet.type == HEADER_PACKET){
            qDebug()<<"Header found";
            packet.current_len = 0;
            packet.data = "";
            packet.total_len = 0;
            QString xLen = "0x"+QString(data[2]) + QString(data[3]);
            qDebug()<<"Len:"<<xLen;
            uint xlen= xLen.toUInt(nullptr, 16);
            QString Len = "";
            for(uint i=0; i<xlen; i++){
                Len += QString(data[i+4]);
            }
            packet.total_len = Len.toUInt();
            qDebug()<<"Total Len: "<<packet.total_len;
            send_ack();
        }
        else if(packet.type == DATA_PACKET){
            qDebug()<<"DATA found";
            QString xLen = "0x"+QString(data[2]) + QString(data[3]);
            qDebug()<<"HEX Len:"<<xLen;
            uint xlen= xLen.toUInt(nullptr, 16);
            qDebug()<<"Len:"<<xlen;
            QString sdata = data.sliced(4,xlen);
            qDebug()<<"Received: "<<sdata;
            packet.current_len += xlen;
            packet.data += sdata;
            send_ack();
        }
        else if(packet.type == EOF_PACKET){
            qDebug()<<"End of File found";
            qDebug()<<"File Len: "<<packet.current_len;
            if(packet.total_len == packet.current_len){
                qDebug()<<"Received successfully";
               emit receivedDataChanged();
            }

        }
        else if(packet.type == ACK_PACKET){
            qDebug()<<"ACK found";
            if(outPacket.total_len == outPacket.current_len){
                qDebug()<<"Done sending data";
                send_EOF();
            }else{
                m_sendData();
            }
        }
        else if(packet.type == NACK_PACKET){
            qDebug()<<"ACK found";
        }

    }
}

void BleManager::characteristicChanged(const QLowEnergyCharacteristic &,
                                       const QByteArray &value)
{ 
    qDebug()<<"Raw: "<<value;
    process_data(QString::fromUtf8(value));
}

void BleManager::sendData(const QString &text)
{
    outPacket.data = text;
    outPacket.total_len = text.length();
    outPacket.current_len = 0;

    // QString hexStr = QString::number(outPacket.total_len, 16).toUpper();
    QString hexStr = QString("%1").arg(outPacket.total_len, 2, 16, QLatin1Char('0')).toUpper();

    QString headerStr = "*" + QString(HEADER_PACKET) + hexStr + QString::number(outPacket.total_len) + "#";
    if (!uartService || !uartChar.isValid())
        return;
    qDebug()<<"Sending: "<<headerStr;
    uartService->writeCharacteristic(
        uartChar,
        headerStr.toUtf8(),
        QLowEnergyService::WriteWithoutResponse
        );
}

void BleManager::m_sendData(void){
    QString sub = "";
    if((outPacket.total_len-outPacket.current_len) > MAX_DATA_LEN){
        //memcpy(tempstr, outPacket.data + outPacket.current_len, MAX_DATA_LEN);
        sub = outPacket.data.mid(outPacket.current_len, MAX_DATA_LEN);
        outPacket.current_len += MAX_DATA_LEN;
    }else{
        //memcpy(tempstr, outPacket.data + outPacket.current_len, outPacket.total_len - outPacket.current_len);
        sub = outPacket.data.mid(outPacket.current_len, outPacket.total_len - outPacket.current_len);
        outPacket.current_len += outPacket.total_len - outPacket.current_len;
    }

    qDebug()<<"sub: "<<sub;

    // QString hexStr = QString::number(sub.length(), 16).toUpper();
    QString hexStr = QString("%1").arg(sub.length(), 2, 16, QLatin1Char('0')).toUpper();
    QString outStr = "*" + QString(DATA_PACKET) + hexStr + sub + "#";
    sendPacket(outStr);
}

void BleManager::sendPacket(QString str){
    if (!uartService || !uartChar.isValid())
        return;
    qDebug()<<"Sending: "<<str;
    uartService->writeCharacteristic(
        uartChar,
        str.toUtf8(),
        QLowEnergyService::WriteWithoutResponse
        );
}
