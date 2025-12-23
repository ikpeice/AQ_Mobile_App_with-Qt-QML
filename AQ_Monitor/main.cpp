#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "blemanager.h"







int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // // Request Android runtime permissions
    // QList<QString> permissions;
    // permissions << "android.permission.BLUETOOTH"
    //             << "android.permission.BLUETOOTH_ADMIN"
    //             << "android.permission.BLUETOOTH_SCAN"
    //             << "android.permission.BLUETOOTH_CONNECT"
    //             << "android.permission.ACCESS_FINE_LOCATION";

    // QtAndroid::requestPermissionsSync(permissions);

    // requestBlePermissions(); // request runtime BLE permissions safely

    BleManager ble;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("ble", &ble);
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("AQ_Monitor", "Main");

    // // Delay permission request slightly
    // QTimer::singleShot(5000, [&ble]() {
    //     ble.requestBlePermissions();
    // });

    return app.exec();
}
