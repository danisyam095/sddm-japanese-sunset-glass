import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Effects

Rectangle {
    id: root

    property string fontFamily: "sans-serif"
    property string mediumFontFamily: fontFamily
    property int selectedUserIndex: userModel.count > 0
                                    ? (userModel.lastIndex >= 0
                                       && userModel.lastIndex < userModel.count
                                       ? userModel.lastIndex : 0)
                                    : -1
    property string selectedUsername: ""
    property string selectedRealName: ""
    property string selectedUserIcon: ""
    property var userAccounts: []
    property bool loginInProgress: false
    property string statusMessage: ""
    property int selectedSessionIndex: sessionModel.count > 0
                                      ? (sessionModel.lastIndex >= 0
                                         && sessionModel.lastIndex < sessionModel.count
                                         ? sessionModel.lastIndex : 0)
                                      : -1

    color: "#D9211A20"
    radius: width * 0.045
    border.width: 1
    border.color: "#70F5E7D0"
    clip: true

    function cacheAccount(index, name, realName, icon) {
        userAccounts[index] = {
            name: name || "",
            realName: (realName || "").trim(),
            icon: icon || ""
        }

        if ((userModel.lastUser && name === userModel.lastUser)
                || (index === selectedUserIndex && !selectedUsername)) {
            selectAccount(index)
        }
    }

    function selectAccount(index) {
        var account = userAccounts[index]
        if (!account)
            return

        selectedUserIndex = index
        selectedUsername = account.name
        selectedRealName = account.realName
        selectedUserIcon = account.icon
        avatarImage.avatarFailed = false
        statusMessage = ""
        accountChooser.visible = false
    }

    function submitLogin() {
        if (loginInProgress)
            return

        var accountName = userModel.count > 0 ? selectedUsername : usernameInput.text
        if (!accountName || !accountName.trim()) {
            statusMessage = "Select or enter a username."
            return
        }
        if (selectedSessionIndex < 0 || selectedSessionIndex >= sessionModel.count) {
            statusMessage = "No login session is available."
            return
        }

        statusMessage = ""
        accountChooser.visible = false
        loginInProgress = true
        loginTimeout.restart()
        sddm.login(accountName.trim(), passwordInput.text, selectedSessionIndex)
    }

    Timer {
        id: loginTimeout
        interval: 15000
        repeat: false
        onTriggered: {
            if (root.loginInProgress) {
                root.loginInProgress = false
                root.statusMessage = "Login timed out. Please try again."
                passwordInput.clear()
            }
        }
    }

    Connections {
        target: sddm

        function onLoginSucceeded() {
            loginTimeout.stop()
            root.statusMessage = "Login successful."
        }

        function onLoginFailed() {
            loginTimeout.stop()
            root.loginInProgress = false
            root.statusMessage = "Login failed. Check your password and try again."
            passwordInput.clear()
        }

        function onInformationMessage(message) {
            root.statusMessage = message
        }

        function onErrorMessage(message) {
            root.statusMessage = message
        }
    }

    Repeater {
        model: userModel

        delegate: Item {
            required property string name
            required property string realName
            required property string icon
            required property int index

            width: 0
            height: 0
            visible: false
            Component.onCompleted: root.cacheAccount(index, name, realName, icon)
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: root.radius - 1
        color: "transparent"
        border.width: 1
        border.color: "#20FFFFFF"
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: parent.height * 0.38
        radius: root.radius
        color: "transparent"
        gradient: Gradient {
            GradientStop { position: 0; color: "#16FFB66F" }
            GradientStop { position: 1; color: "#00FFB66F" }
        }
    }

    Text {
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.115
        anchors.horizontalCenter: parent.horizontalCenter
        text: "JAPANESE SUNSET GLASS"
        color: "#F2B17D"
        font.family: root.fontFamily
        font.pixelSize: Math.max(9, root.width * 0.027)
        font.letterSpacing: root.width * 0.004
        horizontalAlignment: Text.AlignHCenter
    }

    Text {
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.165
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width * 0.82
        text: "Welcome back"
        color: "#F5E7D0"
        font.family: root.fontFamily
        font.pixelSize: Math.max(23, root.width * 0.082)
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
    }

    Text {
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.255
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width * 0.82
        text: "Sign in to continue"
        color: "#D6C8B8"
        font.family: root.fontFamily
        font.pixelSize: Math.max(12, root.width * 0.036)
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
    }

    Rectangle {
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.335
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width * 0.12
        height: 2
        color: "#FF7139"
    }

    Row {
        id: accountRow
        anchors.left: parent.left
        anchors.leftMargin: parent.width * 0.115
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.39
        width: parent.width * 0.77
        height: parent.height * 0.11
        spacing: parent.width * 0.055

        Item {
            id: avatar
            width: accountRow.height * 0.92
            height: width
            anchors.verticalCenter: parent.verticalCenter

            Image {
                id: avatarImage
                anchors.fill: parent
                property bool avatarFailed: false
                source: root.selectedUserIcon && !avatarFailed
                        ? root.selectedUserIcon
                        : Qt.resolvedUrl("../assets/avatar-placeholder.svg")
                fillMode: Image.PreserveAspectCrop
                smooth: true
                onStatusChanged: {
                    if (status === Image.Error && root.selectedUserIcon)
                        avatarFailed = true
                }
            }

            ShaderEffectSource {
                id: avatarTexture
                anchors.fill: parent
                sourceItem: avatarImage
                live: false
                hideSource: true
                visible: false
            }

            MultiEffect {
                anchors.fill: parent
                source: avatarTexture
                maskEnabled: true
                maskSource: Rectangle {
                    width: avatar.width
                    height: avatar.height
                    radius: width / 2
                    color: "white"
                    antialiasing: true
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.width: 1
                border.color: "#D7B992"
            }
        }

        Text {
            visible: userModel.count > 0
            width: accountRow.width - avatar.width - accountRow.spacing
                   - (userModel.count > 1 ? accountRow.height * 0.42 : 0)
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            text: root.selectedRealName || root.selectedUsername || "Select an account"
            color: "#F2E8DA"
            font.family: root.fontFamily
            font.pixelSize: Math.max(14, root.width * 0.05)
            elide: Text.ElideRight
        }

        TextInput {
            id: usernameInput
            visible: userModel.count === 0
            width: accountRow.width - avatar.width - accountRow.spacing
            height: parent.height
            verticalAlignment: TextInput.AlignVCenter
            color: "#F2E8DA"
            selectionColor: "#FF9B54"
            selectedTextColor: "#17141A"
            font.family: root.fontFamily
            font.pixelSize: Math.max(14, root.width * 0.05)
            clip: true
            selectByMouse: true
            activeFocusOnTab: true
            onTextEdited: root.statusMessage = ""
            Keys.onReturnPressed: root.submitLogin()
            Keys.onEnterPressed: root.submitLogin()

            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                text: "Username"
                color: "#AFA49A"
                font: usernameInput.font
                visible: !usernameInput.text && !usernameInput.activeFocus
            }
        }

        Text {
            visible: userModel.count > 1
            width: accountRow.height * 0.42
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: "⌄"
            color: "#FFB273"
            font.family: root.fontFamily
            font.pixelSize: Math.max(15, root.width * 0.05)
        }
    }

    Row {
        id: sessionRow
        anchors.left: parent.left
        anchors.leftMargin: parent.width * 0.105
        anchors.right: parent.right
        anchors.rightMargin: parent.width * 0.105
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.915
        height: parent.height * 0.055

        ComboBox {
            id: sessionSelector
            anchors.fill: parent
            height: parent.height
            model: sessionModel
            textRole: "name"
            currentIndex: root.selectedSessionIndex
            enabled: sessionModel.count > 0 && !root.loginInProgress
            hoverEnabled: true
            onActivated: function(index) {
                root.selectedSessionIndex = index
                root.statusMessage = ""
            }

            background: Rectangle {
                radius: height / 2
                color: sessionSelector.popup.visible ? "#D43A2C25" : "#A824201F"
                border.width: 1
                border.color: sessionSelector.activeFocus || sessionSelector.hovered
                             ? "#E2B27D" : "#806F5A"
            }

            contentItem: Text {
                leftPadding: sessionSelector.indicator.width + 16
                rightPadding: sessionSelector.indicator.width + 16
                text: sessionModel.count > 0
                      ? "SESSION  ·  " + sessionSelector.currentText
                      : "NO SESSIONS AVAILABLE"
                color: sessionModel.count > 0 ? "#F2E8DA" : "#AFA49A"
                font.family: root.fontFamily
                font.pixelSize: Math.max(10, root.width * 0.034)
                font.letterSpacing: root.width * 0.0012
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            indicator: Item {
                width: 34
                height: sessionSelector.height
                visible: sessionModel.count > 0

                Rectangle {
                    width: 7
                    height: 1.5
                    x: parent.width / 2 - 5
                    y: parent.height / 2 - 1
                    rotation: 45
                    radius: height / 2
                    color: "#FFB273"
                }

                Rectangle {
                    width: 7
                    height: 1.5
                    x: parent.width / 2
                    y: parent.height / 2 - 1
                    rotation: -45
                    radius: height / 2
                    color: "#FFB273"
                }
            }

            delegate: ItemDelegate {
                required property string name
                required property int index
                width: sessionSelector.popup.width - 4
                height: Math.max(36, sessionRow.height * 1.15)
                highlighted: sessionSelector.highlightedIndex === index

                contentItem: Text {
                    leftPadding: 16
                    text: name
                    color: "#F2E8DA"
                    font.family: root.fontFamily
                    font.pixelSize: Math.max(10, root.width * 0.034)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                background: Rectangle {
                    radius: height / 2
                    color: parent.highlighted || parent.hovered
                           ? "#805B4033" : "transparent"
                }

                onClicked: {
                    root.selectedSessionIndex = index
                    sessionSelector.popup.close()
                    root.statusMessage = ""
                }
            }

            popup: Popup {
                y: -implicitHeight - 2
                width: sessionSelector.width
                padding: 4
                implicitHeight: Math.min(contentItem.implicitHeight + padding * 2,
                                         root.height * 0.22)

                contentItem: ListView {
                    clip: true
                    implicitHeight: contentHeight
                    model: sessionSelector.popup.visible
                           ? sessionSelector.delegateModel : null
                    currentIndex: sessionSelector.highlightedIndex
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollIndicator.vertical: ScrollIndicator { }
                }

                background: Rectangle {
                    radius: 12
                    color: "#F01C1918"
                    border.width: 1
                    border.color: "#806F5A"
                }
            }
        }
    }

    MouseArea {
        anchors.left: accountRow.left
        anchors.right: accountRow.right
        anchors.top: accountRow.top
        anchors.bottom: accountRow.bottom
        visible: userModel.count > 1
        enabled: !root.loginInProgress
        cursorShape: Qt.PointingHandCursor
        onClicked: accountChooser.visible = !accountChooser.visible
    }

    ListView {
        id: accountChooser
        visible: false
        enabled: !root.loginInProgress
        z: 5
        x: accountRow.x
        y: accountRow.y + accountRow.height * 0.86
        width: accountRow.width
        height: Math.min(userModel.count * root.height * 0.075,
                         root.height * 0.3)
        clip: true
        model: userModel
        boundsBehavior: Flickable.StopAtBounds

        delegate: Item {
            required property string name
            required property string realName
            required property string icon
            required property int index

            width: accountChooser.width
            height: Math.min(root.height * 0.075, 42)

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: height * 0.2
                color: accountMouse.containsMouse ? "#B33A2E2D" : "#75302625"
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: realName || name
                color: "#F5E7D0"
                font.family: root.fontFamily
                font.pixelSize: Math.max(12, root.width * 0.04)
                elide: Text.ElideRight
            }

            MouseArea {
                id: accountMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.cacheAccount(index, name, realName, icon)
                    root.selectAccount(index)
                    accountChooser.visible = false
                }
            }
        }
    }

    Rectangle {
        id: passwordField
        anchors.left: parent.left
        anchors.leftMargin: parent.width * 0.115
        anchors.right: parent.right
        anchors.rightMargin: parent.width * 0.105
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.59
        height: parent.height * 0.08
        radius: height * 0.5
        color: "#241C20"
        border.width: 1
        border.color: passwordInput.activeFocus ? "#E2B27D" : "#9D7B5F"

        Image {
            id: lockIcon
            anchors.left: parent.left
            anchors.leftMargin: parent.height * 0.3
            anchors.verticalCenter: parent.verticalCenter
            width: parent.height * 0.42
            height: width
            source: Qt.resolvedUrl("../assets/icons/lock.svg")
            fillMode: Image.PreserveAspectFit
        }

        TextField {
            id: passwordInput
            anchors.left: lockIcon.right
            anchors.leftMargin: parent.height * 0.22
            anchors.right: loginButton.left
            anchors.rightMargin: parent.height * 0.15
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            verticalAlignment: TextInput.AlignVCenter
            color: "#F5E7D0"
            selectionColor: "#FF9B54"
            selectedTextColor: "#17141A"
            font.family: root.fontFamily
            font.pixelSize: Math.max(15, root.width * 0.052)
            echoMode: TextInput.Password
            passwordCharacter: "•"
            passwordMaskDelay: 0
            renderType: Text.QtRendering
            selectByMouse: true
            activeFocusOnTab: true
            enabled: !root.loginInProgress
            placeholderText: "Password"
            placeholderTextColor: "#AFA49A"
            onTextEdited: root.statusMessage = ""
            onAccepted: root.submitLogin()

            background: Item {
                implicitWidth: 0
                implicitHeight: 0
            }
        }

        Rectangle {
            id: loginButton
            anchors.right: parent.right
            anchors.rightMargin: height * 0.11
            anchors.verticalCenter: parent.verticalCenter
            width: parent.height * 0.78
            height: width
            radius: width / 2
            color: root.loginInProgress ? "#B96036" : "#F36E36"
            opacity: loginMouse.pressed ? 0.82 : 1

            Image {
                anchors.centerIn: parent
                width: parent.width * 0.78
                height: width
                source: Qt.resolvedUrl("../assets/icons/login.svg")
                sourceClipRect: Qt.rect(14, 14, 36, 36)
                fillMode: Image.PreserveAspectFit
                visible: !root.loginInProgress
            }

            Text {
                anchors.centerIn: parent
                text: "…"
                color: "#2B201D"
                font.family: root.mediumFontFamily
                font.pixelSize: parent.width * 0.58
                visible: root.loginInProgress
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }

            MouseArea {
                id: loginMouse
                anchors.fill: parent
                enabled: !root.loginInProgress
                cursorShape: Qt.PointingHandCursor
                onClicked: root.submitLogin()
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: parent.width * 0.13
        anchors.right: parent.right
        anchors.rightMargin: parent.width * 0.13
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.74
        height: 1
        color: "#36F5E7D0"
    }

    PowerActions {
        anchors.left: parent.left
        anchors.leftMargin: parent.width * 0.105
        anchors.right: parent.right
        anchors.rightMargin: parent.width * 0.105
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.765
        height: parent.height * 0.105
        fontFamily: root.fontFamily
    }
}
