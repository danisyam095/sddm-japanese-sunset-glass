import QtQuick 2.15

Item {
    id: root

    property string fontFamily: "sans-serif"

    Repeater {
        model: [
            {
                label: "Shutdown",
                iconPath: "../assets/icons/shutdown.svg",
                available: sddm.canPowerOff,
                action: "shutdown"
            },
            {
                label: "Restart",
                iconPath: "../assets/icons/restart.svg",
                available: sddm.canReboot,
                action: "restart"
            },
            {
                label: "Sleep",
                iconPath: "../assets/icons/sleep.svg",
                available: sddm.canSuspend,
                action: "sleep"
            }
        ]

        delegate: Item {
            required property var modelData
            required property int index

            x: index * (root.width / 3)
            width: root.width / 3
            height: root.height

            Image {
                id: actionIcon
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                width: Math.min(root.height * 0.47, parent.width * 0.27)
                height: width
                source: Qt.resolvedUrl(modelData.iconPath)
                fillMode: Image.PreserveAspectFit
                opacity: modelData.available ? 1 : 0.62
            }

            Text {
                anchors.top: actionIcon.bottom
                anchors.topMargin: root.height * 0.08
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData.label
                color: modelData.available ? "#E6D9C8" : "#B5A797"
                font.family: root.fontFamily
                font.pixelSize: Math.max(10, root.height * 0.19)
                horizontalAlignment: Text.AlignHCenter
            }

            MouseArea {
                anchors.fill: parent
                enabled: modelData.available
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (modelData.action === "shutdown" && sddm.canPowerOff)
                        sddm.powerOff()
                    else if (modelData.action === "restart" && sddm.canReboot)
                        sddm.reboot()
                    else if (modelData.action === "sleep" && sddm.canSuspend)
                        sddm.suspend()
                }
            }
        }
    }

    Rectangle {
        x: root.width / 3
        y: root.height * 0.05
        width: 1
        height: root.height * 0.74
        color: "#52F5E7D0"
    }

    Rectangle {
        x: root.width * 2 / 3
        y: root.height * 0.05
        width: 1
        height: root.height * 0.74
        color: "#52F5E7D0"
    }
}
