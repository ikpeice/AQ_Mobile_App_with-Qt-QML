#include "csvmodel.h"
#include <QFile>
#include <QTextStream>

CsvModel::CsvModel(QObject *parent) : QAbstractListModel(parent) {}

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
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return false;

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
