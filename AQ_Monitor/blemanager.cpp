#include "blemanager.h"
#include <QDebug>
#include <QTimer>

#include <QJniObject>
#include <QJniEnvironment>
#include <QStringList>
#include <QBluetoothPermission>
#include <QPermission>

#include <QBluetoothSocket>


void BleManager::requestBlePermissions()
{
    QStringList perms = {
        "android.permission.BLUETOOTH",
        "android.permission.BLUETOOTH_ADMIN",
        "android.permission.BLUETOOTH_SCAN",
        "android.permission.BLUETOOTH_CONNECT",
        "android.permission.ACCESS_FINE_LOCATION"
    };

    // Get the activity
    QJniObject activity = QJniObject::callStaticObjectMethod(
        "org/qtproject/qt5/android/QtNative",
        "activity",
        "()Landroid/app/Activity;"
        );

    if (!activity.isValid()) {
        qWarning() << "Failed to get Qt activity!";
        return;
    }

    QJniEnvironment env;

    // Create Java String array
    jclass stringClass = env->FindClass("java/lang/String");
    if (!stringClass) {
        qWarning() << "Failed to find java/lang/String";
        return;
    }

    jobjectArray permissionArray = env->NewObjectArray(perms.size(), stringClass, nullptr);
    for (int i = 0; i < perms.size(); ++i) {
        jstring jstr = env->NewStringUTF(perms[i].toUtf8().constData());
        env->SetObjectArrayElement(permissionArray, i, jstr);
        env->DeleteLocalRef(jstr);
    }

    // Use activity.requestPermissions(String[] permissions, int requestCode)
    jclass activityClass = env->GetObjectClass(activity.object<jobject>());
    if (!activityClass) {
        qWarning() << "Failed to get activity class";
        return;
    }

    jmethodID requestPermissionsMethod = env->GetMethodID(
        activityClass,
        "requestPermissions",
        "([Ljava/lang/String;I)V"
        );

    if (!requestPermissionsMethod) {
        qWarning() << "requestPermissions method not found!";
        return;
    }

    env->CallVoidMethod(activity.object<jobject>(), requestPermissionsMethod, permissionArray, 0);
    env->DeleteLocalRef(permissionArray);
}

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

BleManager::BleManager(QObject *parent)
    : QObject(parent)
{
    discoveryAgent = new QBluetoothDeviceDiscoveryAgent(this);
    discoveryAgent->setLowEnergyDiscoveryTimeout(5000);
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
    setStatus("Connected, discovering services...");
    controller->discoverServices();
}

void BleManager::controllerDisconnected()
{
    setStatus("Disconnected");
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
    // QString text = "PING\r\n";
    // QTimer *timer = new QTimer(this);
    // connect(timer, &QTimer::timeout, this, [=]() {
    //     uartService->writeCharacteristic(
    //         uartChar,
    //         text.toUtf8(),
    //         QLowEnergyService::WriteWithoutResponse
    //         );
    // });
    // timer->start(1000);

    qDebug() << "Enable notifications";
    QLowEnergyDescriptor notificationDesc = uartChar.descriptor(
        QBluetoothUuid(CCCID)//UART_CHAR_UUID"00002902-0000-1000-8000-00805F9B34FB"
        );

    if (notificationDesc.isValid()) {
        uartService->writeDescriptor(notificationDesc, QByteArray::fromHex("0100")); // enable notifications
    }

}

void BleManager::process_data(QString data){
    if(data.startsWith('*') && data.endsWith('#')){
        packet.type = data[1];
        if(packet.type == '~'){
            qDebug()<<"Header found";
            QString xLen = "0x"+QString(data[2]) + QString(data[3]);
            qDebug()<<"Len:"<<xLen;
            uint xlen= xLen.toUInt(nullptr, 16);
            QString Len = "";
            for(uint i=0; i<xlen; i++){
                Len += QString(data[i+4]);
            }
            packet.total_len = Len.toUInt();
            qDebug()<<"Total Len: "<<packet.total_len;
        }
        emit receivedDataChanged();
    }
}

void BleManager::characteristicChanged(const QLowEnergyCharacteristic &,
                                       const QByteArray &value)
{
    m_receivedData = QString::fromUtf8(value);
    qDebug()<<"Raw: "<<value;
    process_data(m_receivedData);
}

void BleManager::sendData(const QString &text)
{
    if (!uartService || !uartChar.isValid())
        return;
    qDebug()<<"Sending: "<<text;
    uartService->writeCharacteristic(
        uartChar,
        text.toUtf8(),
        QLowEnergyService::WriteWithoutResponse
        );
}
