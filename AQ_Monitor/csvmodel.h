#ifndef CSVMODEL_H
#define CSVMODEL_H

#include "filedownloader.h"
#include <QAbstractListModel>
#include <QStringList>

class CsvModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Roles {
        RowDataRole = Qt::UserRole + 1
    };

    explicit CsvModel(QObject *parent = nullptr, FileDownloader *_fileDownloader = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE bool loadCsv(const QString &filePath);


private:
    bool loadCsvFromString(const QString &csvContent);

private:
    QList<QStringList> m_rows;
};


#endif // CSVMODEL_H
