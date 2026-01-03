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
            text: "Device ID: "+ ble.deviceID
            font.pixelSize: 16
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
            width: parent.width
            spacing: 5
            TextField {
                id: input
                placeholderText: qsTr("Send data")
                width: parent.width * 0.7
            }

            Button {
                text: "SEND"
                onClicked: {
                    ble.sendData(input.text)
                }

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

        ComboBox{
            id: deviceSelector
            width:200
            height: 50
            font.bold: true
            font.pixelSize: 14
            property string selectedClass: ""

            model: ["NONE","Class A", "Class B", "Class C","Class D", "Class E", "Class F"]

            onCurrentTextChanged: {
                //ble.setDeviceClass(currentText)
                console.log("Selected:", currentText)
                console.log("CurrentIndex: ", currentIndex)
                if(currentIndex === 0){
                    selectedClass = ""
                } else if(currentIndex === 1){
                    selectedClass = "a"
                } else if(currentIndex === 2){
                    selectedClass = "b"
                } else if(currentIndex === 3){
                    selectedClass = "c"
                } else if(currentIndex === 4){
                    selectedClass = "d"
                } else if(currentIndex === 5){
                    selectedClass = "e"
                } else if(currentIndex === 6){
                    selectedClass = "f"
                }

                if(currentIndex > 0){
                    firmButton.enabled = true
                } else {
                    firmButton.enabled = false
                }
            }

        }

        Button {
            id: firmButton
            text: "Load Firmware"
            enabled: false
            onClicked: {
                fileDownloader.startDownload(deviceSelector.selectedClass)
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
