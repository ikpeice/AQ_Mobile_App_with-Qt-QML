#include "filedownloader.h"
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>




FileDownloader::FileDownloader(QObject *parent)
    : QObject(parent)
{
    connect(&manager, &QNetworkAccessManager::finished,
            this, &FileDownloader::onFinished);
}

void FileDownloader::checkOTA(QString _class)
{
    QNetworkRequest request((QUrl("http://device.weatherdata.africa/ota/check?type=a&class="+_class)));
    manager.get(request);
}

void FileDownloader::downloadFile(uint fileNumber)
{
    QNetworkRequest request((QUrl("http://device.weatherdata.africa/ota/download/"+QString::number(fileNumber)+"?type=a&class="+deviceClass)));
    manager.get(request);
}

void FileDownloader::onFinished(QNetworkReply *reply)
{
    if (reply->error() != QNetworkReply::NoError) {
        emit downloadError(reply->errorString());
        reply->deleteLater();
        return;
    }
    QString json =
        "{\"update_available\": true, "
        "\"total_chunks\": 240, "
        "\"total_size\": 122748.0, "
        "\"version\": \"1.1.6\"}\n";


    if(downloadFlag == false){
        //updateInfo = decodeUpdateJson(QString(reply->readAll()));
        if(parseJson(reply->readAll())){
            if(updateInfo.updateAvailable){
                downloadFlag = true;
                currentFile = 1;
                downloadFile(currentFile);
            }
        }

    }else{
        qDebug() <<reply->readAll();
        if(currentFile < updateInfo.totalChunks){
            currentFile +=1;
            downloadFile(currentFile);
        }else{
            qDebug()<<"Download Complete";
            downloadFlag = false;
        }
    }
    qDebug()<<"Dowloading: "<<currentFile<<"  Total: "<<updateInfo.totalChunks;

    downloadProgress = (currentFile/updateInfo.totalChunks)*100;
    emit percentageProgressChanged();
    reply->deleteLater();
}

bool FileDownloader::parseJson(const QString &jsonString)
{

    QJsonParseError error;
    QJsonDocument doc = QJsonDocument::fromJson(
        jsonString.toUtf8(), &error);

    if (error.error != QJsonParseError::NoError) {
        qWarning() << "JSON parse error:" << error.errorString();
        return false;
    }

    if (!doc.isObject()) {
        qWarning() << "JSON is not an object";
        return false;
    }

    QJsonObject obj = doc.object();


    updateInfo.updateAvailable = obj.contains("update_available")? obj.value("update_available").toBool(): false;
    updateInfo.totalChunks       = obj.contains("total_chunks")? obj.value("total_chunks").toInt(): 0;
    updateInfo.totalSize      = obj.contains("total_size")? obj.value("total_size").toDouble(): 0.0;
    updateInfo.version       = obj.contains("version")? obj.value("version").toString(): "";

    qDebug() << "update_available:" << updateInfo.updateAvailable;
    qDebug() << "total_chunks:" << updateInfo.totalChunks;
    qDebug() << "total_size:" << updateInfo.totalSize;
    qDebug() << "version:" << updateInfo.version;
    return true;
}
