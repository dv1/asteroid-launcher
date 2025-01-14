/*
 * Copyright (C) 2022 - Darrel Griët <dgriet@gmail.com>
 * Copyright (C) 2022 - Timo Könnecke <github.com/eLtMosen>
 * Copyright (C) 2015 - Florent Revest <revestflo@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.15
import QtGraphicalEffects 1.12
import org.asteroid.controls 1.0


Item {
    id: root
    property int itemIndexOffset: 4
    property var selectedLauncherItem: null
    // Scaling for when the launcher is shown as full screen (1.0) or in the settings app (0.5).
    property var viewScale: (root.width > root.height ? root.height : root.width) / Dims.l(100)
    property alias currentIndex: pv.currentIndex
    property alias count: pv.count

    function getAtOffset(index) {
        // Calculate the item index/offset using the itemIndexOffset constant taking into account overflow.
        if (index + itemIndexOffset >= launcherModel.itemCount) {
            index = index - launcherModel.itemCount + itemIndexOffset
        } else {
            index += itemIndexOffset
        }
        return index
    }

    Connections {
        target: grid
        function onCurrentVerticalPosChanged() {
            if (grid.currentVerticalPos === 1) {
                forbidTop = false
                grid.changeAllowedDirections()
            }
        }
    }

    PathView {
        id: pv
        property int borderRadius: pv.width*0.71
        anchors.fill: parent
        model: launcherModel
        focus: true
        pathItemCount: 8
        path: Path {
            startX: pv.width/2-pv.borderRadius/2 + pv.borderRadius
            startY: pv.height/2-pv.borderRadius/2 + pv.borderRadius/2 + 1
            PathArc {
                x: pv.width/2-pv.borderRadius/2 + pv.borderRadius
                y: pv.height/2-pv.borderRadius/2 + pv.borderRadius/2 - 1
                radiusX: pv.borderRadius/2
                radiusY: radiusX
                useLargeArc: true
            }
        }
        delegate: MouseArea {
            id: launcherItem
            width: PathView.view.width/3.5
            height: width
            onPressed: {
                forbidTop = true
                grid.changeAllowedDirections()
                root.selectedLauncherItem = model.object

                launcherCenterColor = alb.centerColor(root.selectedLauncherItem.filePath);
                launcherOuterColor = alb.outerColor(root.selectedLauncherItem.filePath);
            }
            onClicked: model.object.launchApplication()

            Rectangle {
                id: circleWrapper
                width: parent.width * .86
                radius: width / 2
                height: width
                anchors.centerIn: parent
                visible: false
                color: launcherItem.pressed | fakePressed ? "#cccccc" : "#f4f4f4"

                Icon {
                    id: icon

                    width: circleWrapper.width * .7
                    height: width
                    anchors.centerIn: circleWrapper
                    color: launcherItem.pressed | fakePressed ? "#444444" : "#000000"
                    name: model.object.iconId === "" ? "ios-help" : model.object.iconId
                    Behavior on color {
                        PropertyAnimation { target: icon; property: "color"; duration: 70 }
                    }
                }
            }

            DropShadow {
                id: shadow
                anchors.fill: circleWrapper
                horizontalOffset: 0
                verticalOffset: 0
                radius: 8.0
                samples: 17
                color: "#80000000"
                source: circleWrapper
                cached: true
            }

            InnerShadow {
                id: innerShadow
                visible: (root.selectedLauncherItem == model.object)
                fast: true
                cached: true
                anchors.fill: circleWrapper
                radius: 50.0
                samples: 16
                color: alb.centerColor(model.object.filePath)
                source: circleWrapper
            }
        }

        onCurrentItemChanged: {
            root.selectedLauncherItem = launcherModel.get(getAtOffset(pv.currentIndex))
            if (root.selectedLauncherItem.object !== undefined) {
                root.selectedLauncherItem = root.selectedLauncherItem.object
            }
        }
        onOffsetChanged: {
            var itemOffset = launcherModel.itemCount - offset;
            var index = getAtOffset(itemOffset)
            var lowerStop = Math.floor(index)
            var upperStop = lowerStop + 1
            var ratio = index % 1

            if (upperStop >= launcherModel.itemCount) upperStop = 0

            var upperCenterColor = alb.centerColor(launcherModel.get(upperStop).filePath);
            var lowerCenterColor = alb.centerColor(launcherModel.get(lowerStop).filePath);

            launcherCenterColor = Qt.rgba(
                    upperCenterColor.r * ratio + lowerCenterColor.r * (1-ratio),
                    upperCenterColor.g * ratio + lowerCenterColor.g * (1-ratio),
                    upperCenterColor.b * ratio + lowerCenterColor.b * (1-ratio)
                );

            var upperOuterColor = alb.outerColor(launcherModel.get(upperStop).filePath);
            var lowerOuterColor = alb.outerColor(launcherModel.get(lowerStop).filePath);
            launcherOuterColor = Qt.rgba(
                    upperOuterColor.r * ratio + lowerOuterColor.r * (1-ratio),
                    upperOuterColor.g * ratio + lowerOuterColor.g * (1-ratio),
                    upperOuterColor.b * ratio + lowerOuterColor.b * (1-ratio)
                );
        }
        layer.enabled: true
        layer.effect: ShaderEffect {

            fragmentShader: "
                #ifdef GL_ES
                precision mediump float;
                #endif
                varying highp vec2 qt_TexCoord0;
                uniform sampler2D source;
                void main(void)
                {
                    vec4 sourceColor = texture2D(source, qt_TexCoord0);
                    float alpha = 1.0;
                    float x = qt_TexCoord0.x - 0.5;
                    float y = qt_TexCoord0.y - 0.5;

                    // Behind the bar, hide all items.
                    if (abs(y) < 0.125 && x > 0.0) {
                        alpha = 0.0;
                    }

                    // Soften the transition between the bar and above/below it.
                    if (abs(y) > 0.125 && x > 0.0) {
                        alpha = abs(y) * 5.0;
                    }

                    if (alpha > 1.0) alpha = 1.0;
                    gl_FragColor = sourceColor * alpha;
                }"
        }
        Item {
            id: barLeft
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: -width/2
            clip: true
            width: root.width * 0.26
            height: root.width * 0.26
            Rectangle {
                width: parent.width*2
                height: parent.height
                radius: height/2
                color: barRight.color
            }
        }
        MouseArea {
            anchors.fill: parent
            onPressed: {
                forbidTop = false
                grid.changeAllowedDirections()
            }
        }
    }

    Rectangle {
        id: barRight
        anchors.centerIn: parent
        // Avoid overlap by moving to the right a pixel if needed.
        anchors.horizontalCenterOffset: Math.ceil(width/2)
        clip: true
        width: root.width * 0.9
        height: barLeft.height
        color: "#66000000"
    }
    Label {
        id: currentAppLabel
        anchors.left: parent.left
        anchors.leftMargin: root.width * 0.3
        anchors.verticalCenter: parent.verticalCenter
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        // This defines the width of the text, it will autoshrink.
        width: root.width * 0.66
        font.pixelSize: Dims.l(12)
        font.letterSpacing: Dims.l(0.2)
        font.styleName: "SemiCondensed Bold"
        fontSizeMode: Text.Fit
        style: Text.Normal
        text: root.selectedLauncherItem.title + localeManager.changesObserver
        opacity: currentAppMouseArea.pressed ? 0.5 : 1.0
        MouseArea {
            id: currentAppMouseArea
            anchors.fill: parent
            onPressed: {
                forbidTop = false
                grid.changeAllowedDirections()
            }
            onClicked: root.selectedLauncherItem.launchApplication()
        }

        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: 0
            radius: 3.0
            samples: 3
            color: "#80000000"
        }
    }

    Component.onCompleted: {
        toLeftAllowed = false
        toRightAllowed = false
        toTopAllowed = false
        toBottomAllowed =  Qt.binding(function() { return forbidTop })
        forbidBottom = false
        forbidLeft = false
        forbidRight = false
        launcherColorOverride = false

        pv.positionViewAtIndex(-itemIndexOffset, PathView.Beginning)

        launcherCenterColor = alb.centerColor(launcherModel.get(getAtOffset(pv.currentIndex)).filePath);
        launcherOuterColor = alb.outerColor(launcherModel.get(getAtOffset(pv.currentIndex)).filePath);
    }
}