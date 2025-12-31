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
    packet.status = NONE;

    outPacket.current_len = 0;
    outPacket.data = "";
    outPacket.total_len = 0;
    outPacket.type = ' ';
    outPacket.status = NONE;


    fileDownloader = _fileDownloader;
    connect(fileDownloader, &FileDownloader::chunckReady, this, [this]{
        if(bleStatus == true){
            sendData(fileDownloader->chunckFile);
        }else{
            qDebug()<<"[BLE]: Disconnected";
        }

    });

    connect(fileDownloader, &FileDownloader::headerFound, this, [this](){
        sendData(fileDownloader->chunckFile);
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
    if(m_deviceID.length() !=  10){
        setStatus("Invalid deviceID");
        return;
    }
    if(bleStatus == true){
        controller->disconnectFromDevice();
    }else{
        requestQtBlePermission(this, [this]() {
            setStatus("Scanning...");
            // discoveryAgent->start(QBluetoothDeviceDiscoveryAgent::LowEnergyMethod);
            startBleScan();
        });
    }

}

void BleManager::deviceDiscovered(const QBluetoothDeviceInfo &info)
{
    qDebug() << "BLE:" << info.name() << info.address().toString();


    if (info.name().contains(m_deviceID, Qt::CaseInsensitive)) {
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
    retryScan();
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
    retryScan();
}

void BleManager::retryScan()
{
    QTimer::singleShot(3000, this, [this]() {
        // discoveryAgent->start(QBluetoothDeviceDiscoveryAgent::LowEnergyMethod);
        startBleScan();
    });
}

void BleManager::resetDevice(void){
    if(bleStatus){
        sendData("reset");
    }
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
            packet.status = RECEIVING;
            packet.current_len = 0;
            packet.data = "";
            packet.total_len = 0;
            QString xLen = "0x"+QString(data[2]) + QString(data[3]);
            qDebug()<<"Len:"<<xLen;
            uint xlen= xLen.toUInt(nullptr, 16);
            QString Len = data.mid(4, xlen);//"";
            // for(uint i=0; i<xlen; i++){
            //     Len += QString(data[i+4]);
            // }
            packet.total_len = Len.toUInt();
            qDebug()<<"Total Len: "<<packet.total_len;
            send_ack();
        }
        else if(packet.type == DATA_PACKET){
            qDebug()<<"DATA found";
            QString xLen = "0x"+QString(data[2]) + QString(data[3]);
            //qDebug()<<"HEX Len:"<<xLen;
            uint xlen= xLen.toUInt(nullptr, 16);
            //qDebug()<<"Len:"<<xlen;
            QString sdata = data.sliced(4,xlen);
            //qDebug()<<"Received: "<<sdata;
            packet.current_len += xlen;
            packet.data += sdata;
            send_ack();
        }
        else if(packet.type == EOF_PACKET){
            packet.status = NONE;
            if(packet.total_len == packet.current_len){
                qDebug()<<"Received: "<<packet.data<<" successfully";
                if(packet.data.contains("[OTA]")){
                    if(packet.data.contains("200 OK")){
                        if(fileDownloader->updateInfo.totalChunks == fileDownloader->currentFile){
                            qDebug()<<"Done";
                            emit receivedDataChanged();
                        }else{
                            fileDownloader->downloadFile();
                        }

                    }else if(packet.data.contains("ERROR")){
                        qDebug()<<"OTA error occured";
                    }
                }
                else if(packet.data.contains("flashing")){
                    QJsonParseError error;
                    QJsonDocument doc = QJsonDocument::fromJson(
                        packet.data.toUtf8(), &error);

                    if (error.error != QJsonParseError::NoError) {
                        qWarning() << "JSON parse error:" << error.errorString();
                        return;
                    }

                    if (!doc.isObject()) {
                        qWarning() << "JSON is not an object";
                        return;
                    }

                    QJsonObject obj = doc.object();

                    flashingProgress = obj.contains("flashing")? obj.value("flashing").toDouble(): 0.0;
                    emit flashProgressChanged();
                }
                else if(packet.data.contains("downloading")){
                    QJsonParseError error;
                    QJsonDocument doc = QJsonDocument::fromJson(
                        packet.data.toUtf8(), &error);

                    if (error.error != QJsonParseError::NoError) {
                        qWarning() << "JSON parse error:" << error.errorString();
                        return;
                    }

                    if (!doc.isObject()) {
                        qWarning() << "JSON is not an object";
                        return;
                    }

                    QJsonObject obj = doc.object();

                    downloadProgress = obj.contains("downloading")? obj.value("downloading").toDouble(): 0.0;
                    emit downloadProgressChanged();
                }
                else{
                    emit receivedDataChanged();
                }

            }else{
                qDebug()<<"File currupted";
            }

        }
        else if(packet.type == ACK_PACKET){
            qDebug()<<"ACK found";
            if(outPacket.status == SENDING && (outPacket.total_len == outPacket.current_len)){
                qDebug()<<"Done sending data";
                outPacket.status = NONE;
                send_EOF();
            }else if(outPacket.status == SENDING){
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
    if(text.contains("id:")){
        m_deviceID = text.mid(3,text.length()-3);
        emit deviceIDChanged();
        return;
    }
    outPacket.data = text;
    outPacket.total_len = text.length();
    outPacket.current_len = 0;
    outPacket.status = SENDING;


    //QString hexStr = QString::number(QString::number(outPacket.total_len).length());
    QString hexStr = QString("%1").arg(QString::number(outPacket.total_len).length(), 2, 16, QLatin1Char('0')).toUpper();

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
        sub = outPacket.data.mid(outPacket.current_len, MAX_DATA_LEN);
        outPacket.current_len += MAX_DATA_LEN;
    }else{
        sub = outPacket.data.mid(outPacket.current_len, outPacket.total_len - outPacket.current_len);
        outPacket.current_len += outPacket.total_len - outPacket.current_len;
    }

    //qDebug()<<"sub: "<<sub;

    // QString hexStr = QString::number(sub.length(), 16).toUpper();
    QString hexStr = QString("%1").arg(sub.length(), 2, 16, QLatin1Char('0')).toUpper();
    QString outStr = "*" + QString(DATA_PACKET) + hexStr + sub + "#";
    sendPacket(outStr);
}

void BleManager::sendPacket(QString str){
    if (!uartService || !uartChar.isValid())
        return;
    //qDebug()<<"Sending: "<<str;
    uartService->writeCharacteristic(
        uartChar,
        str.toUtf8(),
        QLowEnergyService::WriteWithoutResponse
        );
}
