import QtQuick
import QtQuick.Controls

Item {

    id: sensorViewRoot

    property double pm25Data: 00.00
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

    Connections{
        target: ble

        function onSensorsDataChanged(){
        //     pm25Data = ble.sensorsData.pm25
        //     pm10Data = ble.sensorsData.pm10
        //     tempData = ble.sensorsData.temp
        //     humidityData = ble.sensorsData.humi
        //     try{
        //         vocData = ble.sensorsData.voc
        //     } catch(e){
        //         console.log("VOC data error:", e)
        //         vocData = "--.--"
        //     }
        //     co2Data = ble.sensorsData.co2
        //     batteryData = ble.sensorsData.bat
        //     pressureData = ble.sensorsData.pres
        //     coData = ble.sensorsData.co
        //     ch4Data = ble.sensorsData.ch4
        //     no2Data = ble.sensorsData.no2
        //     o3Data = ble.sensorsData.o3
        //     so2Data = ble.sensorsData.so2
        //     ch2oData = ble.sensorsData.ch2o
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
                    sensorValue: ble.sensorsData.pm25
                }

                SensorCard{
                    id: pm10Card
                    sensorName: "PM10 (ppm)"
                    sensorValue: ble.sensorsData.pm10
                }
                SensorCard{
                    id: tempCard
                    sensorName: "Temperature (°C)"
                    sensorValue: ble.sensorsData.temp
                }
                SensorCard{
                    id: co2Card
                    sensorName: "CO2 (ppm)"
                    sensorValue: ble.sensorsData.co2
                }
                SensorCard{
                    id: coCard
                    sensorName: "CO (ppm)"
                    sensorValue: ble.sensorsData.co
                }
                SensorCard{
                    id: ch4Card
                    sensorName: "CH4 (ppm)"
                    sensorValue: ble.sensorsData.ch4
                }
                SensorCard{
                    id: ch2oCard
                    sensorName: "CH2O (ppm)"
                    sensorValue: ble.sensorsData.ch2o
                }

            }

            Column {
                id: sensorColumn2
                spacing: 5

                SensorCard{
                    id: humidityCard
                    sensorName: "Humidity (%)"
                    sensorValue: ble.sensorsData.humi
                }
                SensorCard{
                    id: vocCard
                    sensorName: "VOC (index)"
                    sensorValue: ble.sensorsData.voc
                }
                SensorCard{
                    id: pressureCard
                    sensorName: "Pressure (hPa)"
                    sensorValue: ble.sensorsData.pres
                }
                SensorCard{
                    id: batteryCard
                    sensorName: "Battery (%)"
                    sensorValue: ble.sensorsData.bat
                }
                SensorCard{
                    id: no2Card
                    sensorName: "NO2 (ppm)"
                    sensorValue: ble.sensorsData.no2
                }
                SensorCard{
                    id: o3Card
                    sensorName: "O3 (ppm)"
                    sensorValue: ble.sensorsData.o3
                }
                SensorCard{
                    id: so2Card
                    sensorName: "SO2 (ppm)"
                    sensorValue: ble.sensorsData.so2
                }
            }
        }


    }



}
