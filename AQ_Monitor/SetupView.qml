import QtQuick
import QtQuick.Controls
import QtPositioning
import QtCore
import QtQuick.Dialogs

Item {

    property string uuid: ""
    property string deviceID: ""

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
            }else if(ble.dataReceived() === "online"){
                //ble.status = "Online"
                statusText.text = "Status: Device Online"
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
        active: false
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
        title: "Select CSV"
        currentFolder: DocumentsFolder
        //nameFilters: ["CSV files (*.csv)"]
        fileMode: FileDialog.OpenFile   // IMPORTANT

        onAccepted: {
            console.log("Selected file: " + fileDialog.selectedFile)
            csvModel.loadCsv(fileDialog.selectedFile)
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 5
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

        Row{
            spacing: 10

            CheckBox{
                text: "New Device"

                onCheckedChanged: {
                    ble.isNewDevice(checked)
                    console.log("isNewDevice:", checked)
                    if(checked){
                        csvSection.enabled = false
                    }else{
                        csvSection.enabled = true
                    }
                }
            }

            CheckBox{
                id: gpsCheckbox
                text: "Enable GPS"
                checked: false

                onCheckedChanged: {
                    console.log("GPS Enabled:", checked)
                    if(checked){
                        gps.start()
                    }else{
                        gps.stop()
                    }
                }
            }
        }

        Rectangle{
            id: csvSection
            width: parent.width
            height: openCsvButton.height + rowDropdown.height + 20
            border.width: 1
            border.color: "gray"
            radius: 10

            Column{
                spacing: 5
                width: parent.width *0.9
                anchors.centerIn: parent
                Button {
                    id: openCsvButton
                    text: "Fetch Device IDs from CSV"
                    onClicked: {
                        console.log("Opening file dialog: ")
                        console.log(DocumentsFolder)
                        fileDialog.open()
                    }
                }

                ComboBox {
                    id: rowDropdown
                    model: csvModel
                    width: parent.width
                    displayText: "Select Device ID"

                    textRole: "rowData"

                    // Display row nicely
                    delegate: ItemDelegate {
                        text: rowData.join(" | ")
                        font.pixelSize: 12
                    }


                    onCurrentValueChanged: {

                        if (currentIndex >= 0) {
                            // let row = csvModel.get(currentIndex).rowData
                            // console.log("Selected row:", row)
                            console.log(rowDropdown.currentValue)
                            var device = String(rowDropdown.currentValue).split(",")
                            console.log("UUID: ", device[0])
                            console.log("ID: ", device[1])
                            uuid = device[0]
                            deviceID = device[1]
                            ble.sendData("id_:"+device[1])
                            dataIn += "UUID: "+ device[0] + "\n" + "ID: "+ device[1] + "\n"
                        }
                    }
                }
            }
        }



        Text {
            id: statusText
            text: "Status: "+ ble.status
            font.pixelSize: 16
        }

        Row{
            id: scanRow
            spacing: 10
            CheckBox{
                id: autoScanCheckbox
                text: "Auto Scan & Connect"
                checked: false

                onCheckedChanged: {
                    ble.autoScanConnect(checked)
                    console.log("Auto Scan & Connect:", checked)
                }
            }
            Button {
                text: qsTr("Scan & Connect")
                onClicked: ble.startScan()
            }
        }



        Row{
            id: configRow
            spacing: 10
            ComboBox{
                id: simCardSelector
                property string selectedSim: "0"
                width:150
                font.bold: true
                font.pixelSize: 14
                model: ["onomondo","MTN-NG","Airtel-NG","Glo-NG","9mobile-NG"]
                onCurrentTextChanged: {
                    console.log("Selected SIM:", currentText)
                    if(currentText === "onomondo"){
                        selectedSim = "1"
                    }else if(currentText === "MTN-NG"){
                        selectedSim = "2"
                    }else if(currentText === "Airtel-NG"){
                        selectedSim = "3"
                    }else if(currentText === "Glo-NG"){
                        selectedSim = "4"
                    }else if(currentText === "9mobile-NG"){
                        selectedSim = "5"
                    }
                }
            }

            Button {
                id: uuidButton
                text: qsTr("Configure UUID")
                onClicked: {
                    if(ble.status === "Ready"){
                        ble.sendData("config: {uuid: "+uuid+",deviceID: "+deviceID+",simType: "+simCardSelector.selectedSim+",}")
                    }
                }
            }
        }



        Rectangle {
            id: txtArea
            width: parent.width
            height: 50
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

            model: ["Select Class","Class A", "Class B", "Class C","Class D", "Class E", "Class F"]

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
