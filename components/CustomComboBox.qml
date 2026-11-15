import QtQuick
import QtQuick.Controls
import ".."

ComboBox {
    id: root

    implicitHeight: 26
    implicitWidth: 200

    font.family: Style.fontSans
    font.pixelSize: Style.fontSizeBodyMd

    background: Rectangle {
        implicitHeight: 26
        color: root.hovered ? Style.surfaceHover : Style.panelSurface
        border.color: root.activeFocus ? Style.primary : Style.hairlineBorder
        border.width: 1
    }

    contentItem: Text {
        leftPadding: 8
        rightPadding: 24
        text: root.displayText
        font: root.font
        color: Style.textPrimary
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    indicator: Canvas {
        x: root.width - width - 6
        y: (root.height - height) / 2
        width: 10
        height: 6
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.moveTo(0, 0);
            ctx.lineTo(width, 0);
            ctx.lineTo(width / 2, height);
            ctx.closePath();
            ctx.fillStyle = Style.textSecondary;
            ctx.fill();
        }
    }

    popup: Popup {
        y: root.height
        width: root.width
        implicitHeight: contentItem.implicitHeight + 4
        padding: 1

        contentItem: ListView {
            clip: true
            implicitHeight: Math.min(contentHeight, 220)
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex

            ScrollIndicator.vertical: ScrollIndicator {}
        }

        background: Rectangle {
            color: Style.panelSurface
            border.color: Style.hairlineBorder
            border.width: 1
        }
    }

    delegate: ItemDelegate {
        width: root.width
        height: 24
        highlighted: root.highlightedIndex === index

        contentItem: Text {
            text: modelData
            color: highlighted ? Style.textPrimary : Style.textSecondary
            font: root.font
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            leftPadding: 8
        }

        background: Rectangle {
            color: highlighted ? Style.surfaceActive : (hovered ? Style.surfaceHover : "transparent")
        }
    }
}
