#!/bin/sh


while true; do
    pids_of_flashplayer_process=($(ps aux|grep "libpepflashplayer.so\|-type=ppapi\|firefox/plugin-container"|grep -v "grep" | awk '{print $2}'))
    if test ${#pids_of_flashplayer_process[@]} -ne 0
    then
        echo "flashplayer processes detected. try to prevent screen locker from running."
        qdbus org.freedesktop.ScreenSaver /ScreenSaver SimulateUserActivity > /dev/null
    fi
    sleep 30
done
