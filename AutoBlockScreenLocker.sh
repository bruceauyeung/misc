#!/bin/sh


while true; do
    pids_of_libpepflashplayer=($(ps aux|grep libpepflashplayer.so|grep -v "grep" | awk '{print $2}'))
    pids_of_firefox_plugin_container=($(ps aux|grep 'firefox/plugin-container'|grep -v "grep" | awk '{print $2}'))
    if test ${#pids_of_libpepflashplayer[@]} -ne 0
    then
        echo "libpepflashplayer processes detected. try to prevent screen locker from running."
        qdbus org.freedesktop.ScreenSaver /ScreenSaver SimulateUserActivity > /dev/null
    elif test ${#pids_of_firefox_plugin_container[@]} -ne 0
    then
      echo "firefox plugin container process detected. try to prevent screen locker from running."
      qdbus org.freedesktop.ScreenSaver /ScreenSaver SimulateUserActivity > /dev/null
    fi
    sleep 30
done
