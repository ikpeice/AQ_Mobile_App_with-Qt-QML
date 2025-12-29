#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "blemanager.h"
#include "filedownloader.h"







int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    FileDownloader fileD(nullptr);
    BleManager ble(nullptr, &fileD);


    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("ble", &ble);
    engine.rootContext()->setContextProperty("fileDownloader", &fileD);
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
