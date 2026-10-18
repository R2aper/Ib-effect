import QtQuick
import QtQuick.Effects

Item {
    id: root

    property string name: ""
    property color color: Theme.text
    property int size: 20

    implicitWidth: size
    implicitHeight: size
    width: size
    height: size

    readonly property string iconPath: name ? ("qrc:/qt/qml/Ibe/assets/icons/" + name + ".svg") : ""

    Image {
        id: iconImg
        anchors.fill: parent
        source: root.iconPath
        sourceSize.width: Math.max(32, root.size * 2)
        sourceSize.height: Math.max(32, root.size * 2)
        fillMode: Image.PreserveAspectFit
        smooth: true
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: iconImg
        colorization: 1.0
        colorizationColor: root.color
    }
}
