#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "blemanager.h"
#include "filedownloader.h"
#include "csvmodel.h"



QString getPublicCsvFolder() {
#ifdef Q_OS_ANDROID
    return "/storage/emulated/0/Documents"; // Public folder
#else
    return QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
#endif
}


int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    FileDownloader fileD(nullptr);
    BleManager ble(nullptr, &fileD);
    CsvModel csvModel(nullptr, &fileD);
    // Get the user-accessible documents folder
    QString publicPath = getPublicCsvFolder();//QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
    // QString documentsPath = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);

    // Expose to QML
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("ble", &ble);
    engine.rootContext()->setContextProperty("fileDownloader", &fileD);
    engine.rootContext()->setContextProperty("csvModel", &csvModel);
    engine.rootContext()->setContextProperty("DocumentsFolder", publicPath);
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
