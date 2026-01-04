import QtQuick
import QtQuick.Controls
import QtPositioning
import QtCore
import QtQuick.Dialogs

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
            if(ble.dataReceived() === "GPS-200 OK"){
                gps.stop()
            }

            dataIn += ble.dataReceived() + "\n"
        }

        function onFlashProgressChanged(){
            flashProgressBar.value = ble.flashProgressReceived()
        }

        function onDownloadProgressChanged(){
            progressBar.value = ble.downloadProgressReceived();
        }
    }

    PositionSource {
        id: gps
        active: true
        updateInterval: 5000

        onPositionChanged: {
            console.log("Latitude:", position.coordinate.latitude)
            console.log("Longitude:", position.coordinate.longitude)

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

    FileDialog {
        id: fileDialog
        title: "Select CSV File"
        nameFilters: ["CSV files (*.csv)"]
        onAccepted: csvModel.loadCsv(selectedFile)
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
            text: "Device ID: "+ ble.deviceID
            font.pixelSize: 16
            font.bold: true
        }

        Text {
            text: "Status: "+ ble.status
            font.pixelSize: 16
        }

        Button {
            text: qsTr("Scan & Connect")
            onClicked: ble.startScan()
        }

        Row{
            // width: parent.width
            // spacing: 5
            // TextField {
            //     id: input
            //     placeholderText: qsTr("Send data")
            //     width: parent.width * 0.7
            // }

            // Button {
            //     text: "SEND"
            //     onClicked: {
            //         ble.sendData(input.text)
            //     }

            // }


            Button {
                text: "Open CSV"
                onClicked: fileDialog.open()
            }

            ComboBox {
                id: rowDropdown
                width: parent.width
                model: csvModel

                textRole: "rowData"

                // Display row nicely
                delegate: ItemDelegate {
                    width: parent.width
                    text: rowData.join(" | ")
                }

                onCurrentIndexChanged: {
                    if (currentIndex >= 0) {
                        let row = csvModel.get(currentIndex).rowData
                        console.log("Selected row:", row)
                    }
                }
            }

            Text {
                text: rowDropdown.currentIndex >= 0
                      ? "Selected: " + csvModel.get(rowDropdown.currentIndex).rowData.join(", ")
                      : "No row selected"
                wrapMode: Text.Wrap
            }

        }

        Rectangle {
            id: txtArea
            width: parent.width
            height: 100
            color: "#eeeeee"
            radius: 6


            ScrollView {
                anchors.fill: txtArea
                Text {
                    text: dataIn
                    wrapMode: Text.Wrap
                }
            }
        }

        Button {
            id: firmButton
            text: "Load Firmware"
            onClicked: {
                fileDownloader.startDownload("d");
            }
        }
        Rectangle {
            id: downloadSection
            width: parent.width
            height: 100
            border.color: "gray"
            border.width: 1
            radius: 10

            Text {
                id: downloadProgressLabel
                text: qsTr("Downloading...")
                font.bold: true
                font.pixelSize: 16
                anchors.left: progressBar.left
                anchors.bottom: progressBar.bottom
                anchors.bottomMargin: 5
            }

            ProgressBar {
                id: progressBar
                width: (downloadSection.width)*0.7
                anchors.top: downloadSection.top
                anchors.topMargin: 30
                anchors.left: parent.left
                anchors.leftMargin: 10
                from: 0
                to: 100
                value: 0.00   // example value
            }
            Text {
                id: progressText
                anchors.verticalCenter: progressBar.verticalCenter
                anchors.left: progressBar.right
                anchors.leftMargin: 10
                text: progressBar.value + "%"
                font.bold: true
                font.pixelSize: 16
            }


            Text {
                id: flashProgressLabel
                text: qsTr("Flashing...")
                font.bold: true
                font.pixelSize: 16
                anchors.left: flashProgressBar.left
                anchors.bottom: flashProgressBar.bottom
                anchors.bottomMargin: 5
            }

            ProgressBar {
                id: flashProgressBar
                width: (downloadSection.width)*0.7
                anchors.top: progressBar.top
                anchors.topMargin: 40
                anchors.left: parent.left
                anchors.leftMargin: 10
                from: 0
                to: 100
                value: 0.00   // example value
            }
            Text {
                id: progressText2
                anchors.verticalCenter: flashProgressBar.verticalCenter
                anchors.left: flashProgressBar.right
                anchors.leftMargin: 10
                text: flashProgressBar.value + "%"
                font.bold: true
                font.pixelSize: 16
            }


        }

        Button{
            id: resetButton
            text: qsTr("Reset Device");
            onClicked: {
                ble.resetDevice()
            }
        }
    }
}
