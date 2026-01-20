import QtQuick
import QtQuick.Controls

Item {

    id: sensorViewRoot

    property bool testMode: false

    property string pm25StatusColor: "#db3232"
    property string pm10StatusColor: "#db3232"
    property string tempStatusColor: "#db3232"
    property string humidityStatusColor: "#db3232"
    property string vocStatusColor: "#db3232"
    property string co2StatusColor: "#db3232"
    property string batteryStatusColor: "#db3232"
    property string pressureStatusColor: "#db3232"
    property string coStatusColor: "#db3232"
    property string ch4StatusColor: "#db3232"
    property string no2StatusColor: "#db3232"
    property string o3StatusColor: "#db3232"
    property string so2StatusColor: "#db3232"
    property string ch2oStatusColor: "#db3232"
    property string tamper1StatusColor: "#db3232"
    property string tamper2StatusColor: "#db3232"

    Connections{
        target: ble

        function onSensorsDataChanged(){
            let sensorList = ble.getSensorList()
            // ch4, so2, co, ch2o, o3, voc, co2, tamper1, tamper2
            console.log("sensor list: ", sensorList)
            if(sensorList[0] === 1){
                ch4StatusColor = "#0f9d58"
            }else{
                ch4StatusColor = "#db3232"
            }

            if(sensorList[1] === 1){
                so2StatusColor = "#0f9d58"
            }else{
                so2StatusColor = "#db3232"
            }

            if(sensorList[2] === 1){
                coStatusColor = "#0f9d58"
            }else{
                coStatusColor = "#db3232"
            }

            if(sensorList[3] === 1){
                ch2oStatusColor = "#0f9d58"
            }else{
                ch2oStatusColor = "#db3232"
            }

            if(sensorList[4] === 1){
                o3StatusColor = "#0f9d58"
            }else{
                o3StatusColor = "#db3232"
            }

            if(sensorList[5] === 1){
                vocStatusColor = "#0f9d58"
            }else{
                vocStatusColor = "#db3232"
            }

            if(sensorList[6] === 1){
                co2StatusColor = "#0f9d58"
            }else{
                co2StatusColor = "#db3232"
            }

            if(sensorList[7] === 0){
                tamper1StatusColor = "#0f9d58"
            }else{
                tamper1StatusColor = "#db3232"
            }

            if(sensorList[8] === 0){
                tamper2StatusColor = "#0f9d58"
            }else{
                tamper2StatusColor = "#db3232"
            }
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

        Rectangle{
            id: tamperIndicatorArea
            width: parent.width
            height: 50
            color: "transparent"
            anchors{
                top: navigationBar.bottom
                topMargin: 5
            }
            Rectangle{
                id: tamperIndicator1
                width: tamperIndicatorArea.width * 0.4
                height: 45
                radius: 5
                color: "transparent"
                border.color: "black"
                border.width: 2
                anchors{
                    left: parent.left
                    leftMargin: 10
                }
                Text{
                    id: tamperText1
                    text: "Tamper Switch 1"
                    anchors.top: parent.top
                    anchors.topMargin: 4
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: 14
                    color: "black"
                }
                Rectangle{
                    id: tamperStatusIndicator1
                    width: 15
                    height: 15
                    radius: 7.5
                    color: tamper1StatusColor
                    anchors{
                        bottom: parent.bottom
                        bottomMargin: 4
                        horizontalCenter: parent.horizontalCenter
                    }
                }
            }
            Rectangle{
                id: tamperIndicator2
                width: tamperIndicatorArea.width * 0.4
                height: tamperIndicator1.height
                radius: tamperIndicator1.radius
                color: "transparent"
                border.color: "black"
                border.width: 2
                anchors{
                    right: parent.right
                    rightMargin: 10
                }
                Text{
                    id: tamperText2
                    text: "Tamper Switch 2"
                    anchors.top: parent.top
                    anchors.topMargin: 4
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: 14
                    color: "black"
                }

                Rectangle{
                    id: tamperStatusIndicator2
                    width: tamperStatusIndicator1.width
                    height: tamperStatusIndicator1.height
                    radius: tamperStatusIndicator1.radius
                    color: tamper2StatusColor
                    anchors{
                        bottom: parent.bottom
                        bottomMargin: 4
                        horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }

        Row{
            id: sensorRow
            spacing: 10
            anchors{
                horizontalCenter: parent.horizontalCenter
                top: tamperIndicatorArea.bottom
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
                    statusColor: ble.sensorsData.pm25>0? "#0f9d58" : "#db3232"
                }

                SensorCard{
                    id: pm10Card
                    sensorName: "PM10 (ppm)"
                    sensorValue: ble.sensorsData.pm10
                    statusColor: ble.sensorsData.pm10>0? "#0f9d58" : "#db3232"
                }
                SensorCard{
                    id: tempCard
                    sensorName: "Temperature (°C)"
                    sensorValue: ble.sensorsData.temp
                    statusColor: ble.sensorsData.temp>0? "#0f9d58" : "#db3232"
                }
                SensorCard{
                    id: co2Card
                    sensorName: "CO2 (ppm)"
                    sensorValue: ble.sensorsData.co2
                    statusColor: co2StatusColor
                }
                SensorCard{
                    id: coCard
                    sensorName: "CO (ppm)"
                    sensorValue: ble.sensorsData.co
                    statusColor: coStatusColor
                }
                SensorCard{
                    id: ch4Card
                    sensorName: "CH4 (ppm)"
                    sensorValue: ble.sensorsData.ch4
                    statusColor: ch4StatusColor
                }
                SensorCard{
                    id: ch2oCard
                    sensorName: "CH2O (ppm)"
                    sensorValue: ble.sensorsData.ch2o
                    statusColor: ch2oStatusColor
                }

            }

            Column {
                id: sensorColumn2
                spacing: 5

                SensorCard{
                    id: humidityCard
                    sensorName: "Humidity (%)"
                    sensorValue: ble.sensorsData.humi
                    statusColor: ble.sensorsData.humi>0? "#0f9d58" : "#db3232"
                }
                SensorCard{
                    id: vocCard
                    sensorName: "VOC (index)"
                    sensorValue: ble.sensorsData.voc
                    statusColor: vocStatusColor
                }
                SensorCard{
                    id: pressureCard
                    sensorName: "Pressure (hPa)"
                    sensorValue: ble.sensorsData.pres
                    statusColor: ble.sensorsData.pres>400? "#0f9d58" : "#db3232"
                }
                SensorCard{
                    id: batteryCard
                    sensorName: "Battery (%)"
                    sensorValue: ble.sensorsData.bat
                    statusColor: ble.sensorsData.bat>3.6? "#0f9d58" : "#db3232"
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
                    statusColor: o3StatusColor
                }
                SensorCard{
                    id: so2Card
                    sensorName: "SO2 (ppm)"
                    sensorValue: ble.sensorsData.so2
                    statusColor: so2StatusColor
                }
            }
        }

        Rectangle{
            id: footerBar
            width: parent.width
            height: 70
            color: "#7ab4fa"
            anchors{
                bottom: parent.bottom
            }

            Button{
                id: enableButton
                text: "Enable Sensors"
                height: footerBar.height * 0.8
                anchors{
                    right: parent.right
                    rightMargin: 10
                    verticalCenter: parent.verticalCenter
                }
                onClicked: {
                    testMode = !testMode
                    ble.sendData("{testMode: "+testMode+",}")
                }
            }

        }


    }



}
