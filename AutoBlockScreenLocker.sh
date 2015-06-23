#!/bin/sh

stopScreenSaver(){
    qdbus org.freedesktop.ScreenSaver /ScreenSaver SimulateUserActivity > /dev/null
}
promptPreventScreenLocker(){
    echo "$1 browser is playing flash video. try to prevent screen locker from running."
}
promptNoFlashProcessDetected(){
    echo "no browser is playing flash video. sleep $SLEEP_TIME seconds and continue detection."
    sleep $SLEEP_TIME
}

readonly SLEEP_TIME=30
while true; do
    
    # if chrome/chromium is playing a flash video, a chrome/chromium process with parameter '--type=ppapi' will be launched.
    # when chrome exit playing flash video ,a chrome/chromium process with parameter '--type=ppapi' will still remains. WTF !
    pids_of_chrome_flash_proc=($(ps aux|grep "chromium\|chrome"|grep "type=ppapi"|grep -v 'grep\|type=ppapi-broker'| awk '{print $2}'))
    if test ${#pids_of_chrome_flash_proc[@]} -ne 0
    then
        promptPreventScreenLocker "chrome/chromium"
        stopScreenSaver
        sleep $SLEEP_TIME && continue
    fi
    
    
    # if yandex is playing a flash video, a yandex process with parameter '--type=ppapi' will be launched.
    pids_of_yandex_flash_proc=($(ps aux|grep "yandex_browser"|grep "type=ppapi"|grep -v 'grep'| awk '{print $2}'))
    if test ${#pids_of_yandex_flash_proc[@]} -ne 0
    then
        promptPreventScreenLocker "yandex"
        stopScreenSaver
        sleep $SLEEP_TIME && continue
        
    fi
    
    # if slimjet is playing a flash video, a slimjet process with parameter '--type=ppapi' will be launched.
    # if you playing a flash video and then close that flash-playing tab, the slimjet process with parameter '--type=ppapi' will remains ! WTF!
    pids_of_slimjet_flash_proc=($(ps aux|grep "slimjet"|grep "type=ppapi"|grep -v 'grep'| awk '{print $2}'))
    if test ${#pids_of_slimjet_flash_proc[@]} -ne 0
    then
        promptPreventScreenLocker "slimjet"
        stopScreenSaver
        sleep $SLEEP_TIME && continue
        
    fi    
    
    # if firefox is playing a flash video, a process named 'plugin-container' and with argument 'libflashplayer.so' or 'libfreshwrapper-pepperflash.so' will be launched.
    pids_of_firefox_flash_proc=($(ps -ef|grep firefox/plugin-container|grep 'libflashplayer.so\|libfreshwrapper-pepperflash.so'|grep -v 'grep' | awk '{print $2}'))
    if test ${#pids_of_firefox_flash_proc[@]} -ne 0
    then
        promptPreventScreenLocker "firefox"
        stopScreenSaver
        sleep $SLEEP_TIME && continue
    fi
    
    # recently there is no way to distinguish opera flash process from other opera processes. so i prevent screen saver anyway.
    pids_of_opera_flash_proc=($(ps -ef|grep opera |grep -v 'grep'| awk '{print $2}'))
    if test ${#pids_of_opera_flash_proc[@]} -ne 0
    then
        promptPreventScreenLocker "opera"
        stopScreenSaver
        sleep $SLEEP_TIME && continue
    fi    
    
    promptNoFlashProcessDetected
    
done
