#include "csvmodel.h"
#include <QFile>
#include <QTextStream>
#include <qjniobject.h>
#include <QJniEnvironment>

#ifdef Q_OS_ANDROID
void requestStoragePermission()
{
    // Get the Qt Activity
    QJniObject activity = QJniObject::callStaticObjectMethod(
        "org/qtproject/qt/QtNative",
        "activity",
        "()Landroid/app/Activity;"
        );

    if (!activity.isValid()) {
        qDebug() << "Failed to get Qt activity!";
        return;
    }

    // Permissions to request
    QStringList permissions = {
        "android.permission.READ_EXTERNAL_STORAGE",
        "android.permission.WRITE_EXTERNAL_STORAGE"
    };

    // Get JNI environment
    QJniEnvironment env;

    // Find the String class
    jclass stringClass = env->FindClass("java/lang/String");

    // Create a new Java String array
    jobjectArray javaPermissions = env->NewObjectArray(
        permissions.size(),
        stringClass,
        nullptr
        );

    // Fill the array
    for (int i = 0; i < permissions.size(); ++i) {
        jstring str = env->NewStringUTF(permissions[i].toUtf8().constData());
        env->SetObjectArrayElement(javaPermissions, i, str);
        env->DeleteLocalRef(str);
    }

    // Call requestPermissions on the activity
    activity.callMethod<void>(
        "requestPermissions",
        "([Ljava/lang/String;I)V",
        javaPermissions,
        1 // request code
        );

    env->DeleteLocalRef(javaPermissions);
}
#endif

CsvModel::CsvModel(QObject *parent, FileDownloader *_fileDownloader) : QAbstractListModel(parent) {
    requestStoragePermission();
}

int CsvModel::rowCount(const QModelIndex &) const
{
    return m_rows.count();
}

QVariant CsvModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_rows.size())
        return {};

    if (role == RowDataRole)
        return m_rows.at(index.row());

    return {};
}

QHash<int, QByteArray> CsvModel::roleNames() const
{
    return {
        { RowDataRole, "rowData" }
    };
}

bool CsvModel::loadCsv(const QString &filePath)
{

    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)){
        qDebug() << "Failed to open file:" << filePath;
        return false;
    }

    beginResetModel();
    m_rows.clear();

    QTextStream in(&file);
    while (!in.atEnd()) {
        QString line = in.readLine();
        m_rows.append(line.split(","));  // simple CSV
    }

    endResetModel();
    return true;
}

