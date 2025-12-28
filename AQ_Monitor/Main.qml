import QtQuick
import QtQuick.Controls
import QtPositioning
import QtCore

Window {
    width: 720
    height: 1438
    visible: true
    title: "AQ Monitor"
    property string dataIn: ""
    property double latitude: 0
    property double longitude: 0

    Component.onCompleted: {
        console.log("OS:", Qt.platform.os)
    }

    Connections{
        target: fileDownloader

        function onPercentageProgressChanged(){
            progressBar.value =fileDownloader.percentageProgress().toFixed(2)
        }
    }

    Connections{
        target: ble
        function onReceivedDataChanged(){
            if(ble.dataReceived() === "GPS-200"){
                gps.stop()
            }

            dataIn += ble.dataReceived() + "\n"
        }
    }

    PositionSource {
        id: gps
        active: true
        updateInterval: 5000

        onPositionChanged: {
            console.log("Latitude:", position.coordinate.latitude)
            console.log("Longitude:", position.coordinate.longitude)
            console.log("Accuracy:",position.timestamp)
            latitude = position.coordinate.latitude
            longitude = position.coordinate.longitude
            ble.sendData("location:{lat: "+latitude.toFixed(6)+",lon: "+longitude.toFixed(6)+",}")
        }

        onActiveChanged: {
            console.log("GPS: ", gps.active)
            if(gps.active === false){
                console.log("GPS not active")
            }

        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 10
        width: parent.width *0.9
        anchors{
            leftMargin: 20
            rightMargin: 20
        }

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
            height: 100
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
        Rectangle {
            id: downloadSection
            width: parent.width
            height: 50

            Row{
                id: rowID
                anchors.fill: parent
                Button {
                    id: firmButton
                    text: "Load Firmware"
                    onClicked: {
                        fileDownloader.startDownload("d");
                    }
                }
                ProgressBar {
                    id: progressBar
                    width: (parent.width - firmButton.width)*0.85
                    height: 20
                    anchors{
                        margins: 10
                        verticalCenter: parent.verticalCenter
                    }
                    from: 0
                    to: 100
                    value: 0.00   // example value
                }
                Text {
                    id: progressText
                    anchors.verticalCenter: parent.verticalCenter
                    text: progressBar.value + "%"
                }
            }


        }

    }
}
