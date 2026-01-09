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


    SetupView {
        id: setupView1
        width: mainWindow.width
        height: mainWindow.height
        anchors{
            top: parent.top

        }
    }

}
