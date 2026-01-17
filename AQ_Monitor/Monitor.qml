import QtQuick
import QtQuick.Controls

Item {
    id: monitorView
    property string dataInMonitor: dataInField.text
    property bool debugMode: false
    signal requestData
    width: mainWindow.width
    height: mainWindow.height

    Connections{
        target: ble
        function onReceivedDataChanged(){
            if(ble.dataReceived() === "online"){
                mainWindow.indicatorColor = "#4CAF50"
            }
            //dataInField.text += ble.dataReceived()
        }

        function onBleConnectedChanged(){
            if(ble.bleConnected()){
                mainWindow.indicatorColor = "#4CAF50"
            } else {
                mainWindow.indicatorColor = "#db3232"
            }
        }

        function onDebugDataChanged(){
            dataInField.text += ble.debugData()
        }
    }

    Rectangle {
        id: backgroundRect
        anchors.fill: parent
        color: "#f0f0f0"

        Rectangle{
            id: navigationBar
            width: parent.width
            height: 50
            color: "#7ab4fa"
            Text{
                text: "Monitor"
                anchors.centerIn: parent
                font.pixelSize: 20
                font.bold: true
                color: "white"
            }

            Rectangle{
                id: onlineIndicator
                width: 20
                height: 20
                radius: 10
                color: mainWindow.indicatorColor
                anchors{
                    right: parent.right
                    rightMargin: 10
                    verticalCenter: parent.verticalCenter
                }
            }

            Button {
                id: backButton
                text: "<< Back"
                height: parent.height * 0.7
                anchors{
                    left: parent.left
                    leftMargin: 5
                    verticalCenter: parent.verticalCenter
                }

                onClicked: {
                    monitorView1.z = -1
                    setupView1.z = -1
                }
            }
        }

        Rectangle{
            id: contentArea
            width: parent.width*0.9
            height: parent.height - navigationBar.heigh - 20
            anchors.top: navigationBar.bottom
            anchors.topMargin: 20
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            color: "transparent"

            ScrollView {
                width: contentArea.width
                anchors.top: contentArea.top
                anchors.bottom: controlArea.top
                anchors.bottomMargin: 10


                TextArea {
                    id: dataInField
                    width: contentArea.width
                    readOnly: true
                    wrapMode: TextArea.WrapAnywhere
                    placeholderText: "Monitoring data will appear here..."

                    onTextChanged:{

                        cursorPosition = text.length
                        const maxChars = 5000
                        if (dataInField.text.length > maxChars)
                            dataInField.text = dataInField.text.slice(-maxChars)
                    }
                }

            }

            Rectangle{
                id: controlArea
                width: contentArea.width
                height: 50
                anchors.bottom: contentArea.bottom
                color: "transparent"

                Button {
                    id: enableButton
                    text: "Enable Monitoring"
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: {
                        debugMode = !debugMode
                        ble.sendData("{debug: "+debugMode+",}")
                    }
                }

                Button{
                    id:clearScreenButton
                    text: "Clear Screen"
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: {
                        dataInField.text =""
                    }
                }
            }
        }

    }


}
