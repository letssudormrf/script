sudo apt install ffmpeg
adb devices
adb connect ip:port
adb shell screenrecord --bit-rate 1200000 --output-format h264 --size 540x960 - | ffplay -
