import QtQuick
import QtQuick.Controls

Window {
    width: 360
    height: 640
    visible: true
    title: "HC-42 BLE Demo"

    // Connections{
    //     target: ble
    // }

    Column {
        anchors.centerIn: parent
        spacing: 10
        width: parent.width * 0.9

        Text {
            text: ble.status
            font.pixelSize: 16
        }

        Button {
            text: "Scan & Connect"
            onClicked: ble.startScan()
        }

        TextField {
            id: input
            placeholderText: "Send data"
        }

        Button {
            text: "Send"
            onClicked: ble.sendData(input.text + "\r\n")
        }

        Rectangle {
            width: parent.width
            height: 200
            color: "#eeeeee"
            radius: 6

            ScrollView {
                anchors.fill: parent
                Text {
                    text: ble.receivedData
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}
