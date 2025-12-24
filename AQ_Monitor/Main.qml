import QtQuick
import QtQuick.Controls
import QtPositioning
import QtCore

Window {
    width: 360
    height: 640
    visible: true
    title: "AQ Monitor"
    property string dataIn: ""
    property double latitude: 0
    property double longitude: 0

    Component.onCompleted: {
        console.log("OS:", Qt.platform.os)

    }

    Connections{
        target: ble
        function onReceivedDataChanged(){
            dataIn += ble.dataReceived() + "\n"
        }
    }

    PositionSource {
        id: gps
        active: true
        updateInterval: 2000

        onPositionChanged: {
            console.log("Latitude:", position.coordinate.latitude)
            console.log("Longitude:", position.coordinate.longitude)
            console.log("Accuracy:",position.timestamp)
            latitude = position.coordinate.latitude
            longitude = position.coordinate.longitude
            ble.sendData("location:{lat: "+latitude.toFixed(6)+",lon: "+longitude.toFixed(6)+",}")
        }
    }

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
            onClicked: {
                ble.sendData(input.text)
            }

        }

        Rectangle {
            id: txtArea
            width: parent.width
            height: 200
            color: "#eeeeee"
            radius: 6


            ScrollView {
                anchors.fill: parent
                Text {
                    text: dataIn
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}
