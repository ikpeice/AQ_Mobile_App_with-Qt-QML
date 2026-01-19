import QtQuick
import QtQuick.Controls
import QtPositioning
import QtCore
import QtQuick.Dialogs

Window {
    id: mainWindow
    width: 720
    height: 1438
    visible: true
    title: "AQ Monitor"
    property string dataIn: ""
    property double latitude: 0
    property double longitude: 0
    property string indicatorColor: "#db3232"//"#4CAF50"

    Component.onCompleted: {
        console.log("OS:", Qt.platform.os)
    }

    function enableView(viewIndex){
        if(viewIndex === 1){
            monitorView1.z = -1
            monitorView1.enabled = false

            sensorView.z = -1
            sensorView.enabled = false

            setupView1.z = 3
            setupView1.enabled = true

        }else if(viewIndex === 2){
            setupView1.z = -1
            setupView1.enabled = false

            sensorView.z = -1
            sensorView.enabled = false

            monitorView1.z = 3
            monitorView1.enabled = true
        }else if(viewIndex === 3){
            setupView1.z = -1
            setupView1.enabled = false

            monitorView1.z = -1
            monitorView1.enabled = false

            sensorView.z = 3
            sensorView.enabled = true
        }
    }

    Rectangle {
        id: backgroundRect
        anchors.fill: parent
        color: "#f0f0f0"

        Column{
            id: mainColumn
            width: backgroundRect.width*0.7
            anchors.centerIn: parent
            spacing: 20
            Button {
                id: deviceSetupButton
                text: "Device Setup"
                width: mainColumn.width
                onClicked: {
                    enableView(1)
                }
            }

            Button {
                id: monitorButton
                text: "Open Monitoring"
                width: mainColumn.width
                onClicked: {
                    enableView(2)
                }
            }

            Button {
                id: sensorViewButton
                text: "Sensor View"
                width: mainColumn.width
                onClicked: {
                    enableView(3)
                }
            }
        }
    }




    SetupView {
        id: setupView1
        width: mainWindow.width
        height: mainWindow.height
        z: -1
        anchors{
            top: parent.top
        }
    }

    Monitor {
        id: monitorView1
        width: mainWindow.width
        height: mainWindow.height
        z: -1
        anchors{
            top: parent.top
        }
    }

    SensorView{
        id: sensorView
        width: mainWindow.width
        height: mainWindow.height
        z: -1
        anchors{
            top: parent.top
        }
    }

}
