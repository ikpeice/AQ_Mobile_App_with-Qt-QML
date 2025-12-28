#ifndef FILEDOWNLOADER_H
#define FILEDOWNLOADER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>

typedef struct UpdateInfo {
    bool updateAvailable;
    double totalChunks;
    double totalSize;
    QString version;

}UpdateInfo;

class FileDownloader : public QObject
{
    Q_OBJECT

    //Q_PROPERTY(float percentageProgress READ percentageProgress  NOTIFY percentageProgressChanged)
public:
    explicit FileDownloader(QObject *parent = nullptr);

    Q_INVOKABLE void startDownload(const QString _class){
        deviceClass = _class;
        checkOTA(_class);
    }

    Q_INVOKABLE double percentageProgress() const {return downloadProgress;}

signals:
    void downloadFinished(const QString &filePath);
    void downloadError(const QString &error);
    void percentageProgressChanged();

private slots:
    void onFinished(QNetworkReply *reply);
    void downloadFile(uint fileNumber);
    void checkOTA(QString _class);
    bool parseJson(const QString &jsonString);
    // UpdateInfo decodeUpdateJson(const QString json);

private:
    QNetworkAccessManager manager;
    QString targetPath;
    QString deviceClass;
    float downloadProgress = 0.00;
    uint totalFile = 0;
    double currentFile = 0;
    bool downloadFlag = false;

    UpdateInfo updateInfo;

};

#endif // FILEDOWNLOADER_H
