#ifndef FILEDOWNLOADER_H
#define FILEDOWNLOADER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>

class FileDownloader : public QObject
{
    Q_OBJECT

    Q_PROPERTY(float percentageProgress READ percentageProgress  NOTIFY percentageProgressChanged FINAL)
public:
    explicit FileDownloader(QObject *parent = nullptr);

    Q_INVOKABLE void startDownload(const QString _url){
        url = _url;
        downloadFile();
    }

    float percentageProgress() const {return downloadProgress;}
    //Q_INVOKABLE uint checkUpdate();

signals:
    void downloadFinished(const QString &filePath);
    void downloadError(const QString &error);
    void percentageProgressChanged();

private slots:
    void onFinished(QNetworkReply *reply);
    void downloadFile();

private:
    QNetworkAccessManager manager;
    QString targetPath;
    QString url;
    float downloadProgress = 0.00;
    uint totalFile = 0;
    uint currentFile = 0;
};

#endif // FILEDOWNLOADER_H
