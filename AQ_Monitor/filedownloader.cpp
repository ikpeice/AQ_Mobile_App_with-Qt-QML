#include "filedownloader.h"
#include <QFile>

FileDownloader::FileDownloader(QObject *parent)
    : QObject(parent)
{
    connect(&manager, &QNetworkAccessManager::finished,
            this, &FileDownloader::onFinished);
}

void FileDownloader::downloadFile()
{

    QNetworkRequest request((QUrl("http://device.weatherdata.africa/ota/check?type=a&class=d")));
    manager.get(request);
}

void FileDownloader::onFinished(QNetworkReply *reply)
{
    if (reply->error() != QNetworkReply::NoError) {
        emit downloadError(reply->errorString());
        reply->deleteLater();
        return;
    }

    // QFile file(targetPath);
    // if (!file.open(QIODevice::WriteOnly)) {
    //     emit downloadError("Cannot write file");
    //     reply->deleteLater();
    //     return;
    // }

    qDebug()<<(reply->readAll());
    // file.close();

    emit downloadFinished(targetPath);
    reply->deleteLater();
}
