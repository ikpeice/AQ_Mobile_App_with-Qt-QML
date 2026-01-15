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

    Component.onCompleted: {
        console.log("OS:", Qt.platform.os)
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
                    monitorView1.z = -1
                    setupView1.z = 3
                }
            }

            Button {
                id: monitorButton
                text: "Start Monitoring"
                width: mainColumn.width
                onClicked: {
                    setupView1.z = -1
                    monitorView1.z = 3
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

}
