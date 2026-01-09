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
    Q_INVOKABLE void fetchCsvFile(){
        downloadCsvFile();
    }

    Q_INVOKABLE double percentageProgress() const {return downloadProgress;}
    void downloadFile(void);
    void checkOTA(QString _class);



public:
    QString chunckFile = "";
    UpdateInfo updateInfo;
    double currentFile = 0;
    QString csvFile = "";

signals:
    void downloadFinished();
    void chunckReady();
    void headerFound();
    void downloadError(const QString &error);
    void percentageProgressChanged();
    void csvDownloaded();

private slots:
    void onFinished(QNetworkReply *reply);

    bool parseJson(const QString &jsonString);
    void downloadCsvFile();
    // UpdateInfo decodeUpdateJson(const QString json);

private:
    QNetworkAccessManager manager;

    QString deviceClass;
    float downloadProgress = 0.00;
    uint totalFile = 0;

    bool downloadFlag = false;

    const QString csvDataURL = "https://docs.google.com/spreadsheets/d/e/2PACX-1vR9AX4IyrB_v27aTarpj11L-U-6RVPPBLynF4wFLlPiBDQk85k1FrGg-KSjg4RsNj16pWeVnyXUi-zZ/pub?gid=0&single=true&output=csv";


};

#endif // FILEDOWNLOADER_H
