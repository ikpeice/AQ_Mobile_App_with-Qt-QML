import QtQuick
import QtQuick.Controls

Item {
    id: monitorView
    property alias dataIn: dataInField.text
    signal requestData
    width: 720
    height: 1438

    // Component.onCompleted: {
    //     console.log("Monitor View Loaded")
    //     mainColumn.visible = false
    // }

    Rectangle {
        id: backgroundRect
        anchors.fill: parent
        color: "#f0f0f0"
    }
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

    Column {
        id: mainColumn
        width: monitorView.width * 0.9
        anchors.top: navigationBar.bottom
        spacing: 20

        Text {
            id: titleText
            text: "AQ Monitor"
            font.pointSize: 24
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            width: mainColumn.width
        }

        TextArea {
            id: dataInField
            width: mainColumn.width
            height: 400
            readOnly: true
            wrapMode: TextArea.WrapAnywhere
            placeholderText: "Monitoring data will appear here..."
        }

        Button {
            id: refreshButton
            text: "Refresh Data"
            width: mainColumn.width
            onClicked: {
                monitorView.requestData()
            }
        }
    }

}
