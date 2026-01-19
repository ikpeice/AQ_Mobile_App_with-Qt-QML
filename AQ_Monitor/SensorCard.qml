import QtQuick
import QtQuick.Controls

Item {
    id: sensorCard
    property string sensorName: "Sensor"
    property string sensorValue: "0"
    property string statusColor: "#db3232"
    width: 160
    height: 75

    Rectangle {
        id: cardBackground
        anchors.fill: parent
        color: "#ffffff"
        border.color: "#cccccc"
        radius: 10


        Column {
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: sensorName
                font.pixelSize: 18
                font.bold: true
                color: "#333333"
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                text: sensorValue
                font.pixelSize: 24
                font.bold: true
                color: "#0078d7"
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Rectangle{
            id: onlineIndicator
            width: 10
            height: 10
            radius: 5
            color: statusColor
            anchors{
                right: parent.right
                rightMargin: 3
                verticalCenter: parent.verticalCenter
            }
        }
    }

}
