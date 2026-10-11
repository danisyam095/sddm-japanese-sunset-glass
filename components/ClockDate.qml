import QtQuick 2.15

Item {
    id: root

    property string fontFamily: "sans-serif"
    property date now: new Date()
    property string dateText: now.toLocaleDateString(Qt.locale("en_US"),
                                                     "dddd, dd MMMM yyyy").toUpperCase()
    property string timeText: now.toLocaleTimeString(Qt.locale("en_US"), "HH:mm")

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.now = new Date()
    }

    Text {
        id: dateLabel
        anchors.top: parent.top
        anchors.right: parent.right
        width: parent.width
        text: root.dateText
        color: "#F5E7D0"
        font.family: root.fontFamily
        font.pixelSize: Math.max(11, root.height * 0.135)
        font.letterSpacing: Math.max(1.1, root.width * 0.0014)
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideLeft
        maximumLineCount: 1
    }

    Rectangle {
        anchors.top: dateLabel.bottom
        anchors.topMargin: root.height * 0.12
        anchors.right: parent.right
        width: Math.max(36, root.width * 0.12)
        height: 2
        color: "#FF9B54"
        opacity: 0.9
    }

    Text {
        anchors.top: dateLabel.bottom
        anchors.topMargin: root.height * 0.19
        anchors.right: parent.right
        text: root.timeText
        color: "#F5E7D0"
        font.family: root.fontFamily
        font.pixelSize: Math.max(38, root.height * 0.49)
        font.letterSpacing: Math.max(1.5, root.width * 0.0018)
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
    }
}
