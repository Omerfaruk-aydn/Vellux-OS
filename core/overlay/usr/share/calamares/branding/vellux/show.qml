import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
    id: presentation

    function nextSlide() {
        presentation.goToNextSlide()
    }

    Timer {
        id: advanceTimer
        interval: 6000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: nextSlide()
    }

    function slideBody(title, text) {
        return { "title": title, "text": text }
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0b0f1c"
            Text {
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
                color: "#e6ebff"
                font.pixelSize: 26
                text: "Vellux OS'a hos geldiniz\n\nSaf Wayland. Akici hareket. Cam arayuz."
            }
        }
    }
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0b0f1c"
            Text {
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
                color: "#e6ebff"
                font.pixelSize: 24
                text: "Geri alinabilir guncellemeler\n\nHer guncelleme oncesi otomatik anlik goruntu.\nSorun olursa tek komutla geri donun."
            }
        }
    }
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0b0f1c"
            Text {
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
                color: "#e6ebff"
                font.pixelSize: 24
                text: "Verileriniz guvende\n\nIstege bagli tam disk sifreleme (LUKS),\nAppArmor ve guvenlik duvari varsayilan olarak acik."
            }
        }
    }
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0b0f1c"
            Text {
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
                color: "#e6ebff"
                font.pixelSize: 24
                text: "Kurulum surerken...\n\nBirkac dakika icinde Vellux OS hazir olacak."
            }
        }
    }

    function onActivate() { }
    function onLeave() { }
}
