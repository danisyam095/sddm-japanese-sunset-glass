import QtQuick 2.15
import QtQuick.Effects
import QtQuick.Window 2.15
import "components"

Item {
    id: root

    width: Screen.width
    height: Screen.height

    FontLoader {
        id: instrumentRegular
        source: Qt.resolvedUrl("assets/fonts/InstrumentSans-Regular.ttf")
    }

    FontLoader {
        id: instrumentMedium
        source: Qt.resolvedUrl("assets/fonts/InstrumentSans-Medium.ttf")
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        source: Qt.resolvedUrl(config.background || "assets/background.png")
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        cache: true
    }

    LoginPanel {
        id: loginPanel
        x: parent.width * 0.137
        y: parent.height * 0.17
        width: parent.width * 0.24
        height: parent.height * 0.61
        z: 2
        fontFamily: instrumentRegular.status === FontLoader.Ready
                    ? instrumentRegular.name : "sans-serif"
        mediumFontFamily: instrumentMedium.status === FontLoader.Ready
                          ? instrumentMedium.name : fontFamily
    }

    ShaderEffectSource {
        id: panelBackdrop
        x: loginPanel.x
        y: loginPanel.y
        width: loginPanel.width
        height: loginPanel.height
        sourceItem: wallpaper
        sourceRect: Qt.rect(loginPanel.x, loginPanel.y, loginPanel.width, loginPanel.height)
        live: false
        hideSource: false
    }

    MultiEffect {
        anchors.fill: loginPanel
        source: panelBackdrop
        blurEnabled: true
        blur: 0.65
        blurMax: 48
        maskEnabled: true
        maskSource: Rectangle {
            width: loginPanel.width
            height: loginPanel.height
            radius: loginPanel.width * 0.045
            color: "white"
        }
        z: 1
    }

    ClockDate {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: parent.height * 0.045
        anchors.rightMargin: parent.width * 0.033
        width: parent.width * 0.31
        height: parent.height * 0.12
        fontFamily: instrumentRegular.status === FontLoader.Ready
                    ? instrumentRegular.name : "sans-serif"
    }

    Rectangle {
        id: loginStatus
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: parent.width * 0.035
        anchors.bottomMargin: parent.height * 0.04
        width: Math.min(parent.width * 0.38,
                        Math.max(parent.width * 0.16, statusText.implicitWidth + 32))
        height: Math.max(44, statusText.implicitHeight + 18)
        radius: height / 2
        color: "#D9211A20"
        border.width: 1
        border.color: "#70F5E7D0"
        visible: loginPanel.statusMessage.length > 0 || loginPanel.loginInProgress
        z: 10

        Text {
            id: statusText
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: 8
            anchors.bottomMargin: 8
            text: loginPanel.loginInProgress && !loginPanel.statusMessage
                  ? "Signing in…" : loginPanel.statusMessage
            color: text.indexOf("failed") >= 0 || text.indexOf("timed out") >= 0
                   ? "#FFB095" : "#F2D1AC"
            font.family: instrumentRegular.status === FontLoader.Ready
                         ? instrumentRegular.name : "sans-serif"
            font.pixelSize: Math.max(12, parent.width * 0.027)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            maximumLineCount: 2
            wrapMode: Text.Wrap
        }
    }
}
