import QtQuick
import QtQuick.Controls

Item {

    id: sensorViewRoot


    property string pm25Data: "--.--"
    property string pm10Data: "--.--"
    property string tempData: "--.--"
    property string humidityData: "--.--"
    property string vocData: "--.--"
    property string co2Data: "--.--"
    property string batteryData: "--.--"
    property string pressureData: "--.--"
    property string coData: "--.--"
    property string ch4Data: "--.--"
    property string no2Data: "--.--"
    property string o3Data: "--.--"
    property string so2Data: "--.--"
    property string ch2oData: "--.--"

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
                text: "Sensor Data"
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
                    sensorView.z = -1
                }
            }
        }

        Row{
            id: sensorRow
            spacing: 10
            anchors{
                horizontalCenter: parent.horizontalCenter
                top: navigationBar.bottom
                topMargin: 10
                leftMargin: 10
                rightMargin: 10
            }

            Column {
                id: sensorColumn1
                spacing: 5


                SensorCard{
                    id: pm25Card
                    sensorName: "PM2.5 (ppm)"
                    sensorValue: pm25Data
                }

                SensorCard{
                    id: pm10Card
                    sensorName: "PM10 (ppm)"
                    sensorValue: pm10Data
                }
                SensorCard{
                    id: tempCard
                    sensorName: "Temperature (°C)"
                    sensorValue: tempData
                }
                SensorCard{
                    id: co2Card
                    sensorName: "CO2 (ppm)"
                    sensorValue: co2Data
                }
                SensorCard{
                    id: coCard
                    sensorName: "CO (ppm)"
                    sensorValue: coData
                }
                SensorCard{
                    id: ch4Card
                    sensorName: "CH4 (ppm)"
                    sensorValue: ch4Data
                }
                SensorCard{
                    id: ch2oCard
                    sensorName: "CH2O (ppm)"
                    sensorValue: ch2oData
                }

            }

            Column {
                id: sensorColumn2
                spacing: 5

                SensorCard{
                    id: humidityCard
                    sensorName: "Humidity (%)"
                    sensorValue: humidityData
                }
                SensorCard{
                    id: vocCard
                    sensorName: "VOC (index)"
                    sensorValue: vocData
                }
                SensorCard{
                    id: pressureCard
                    sensorName: "Pressure (hPa)"
                    sensorValue: pressureData
                }
                SensorCard{
                    id: batteryCard
                    sensorName: "Battery (%)"
                    sensorValue: batteryData
                }
                SensorCard{
                    id: no2Card
                    sensorName: "NO2 (ppm)"
                    sensorValue: no2Data
                }
                SensorCard{
                    id: o3Card
                    sensorName: "O3 (ppm)"
                    sensorValue: o3Data
                }
                SensorCard{
                    id: so2Card
                    sensorName: "SO2 (ppm)"
                    sensorValue: so2Data
                }
            }
        }


    }



}
