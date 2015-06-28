#!/bin/bash

trim() {
    # Determine if 'extglob' is currently on.
    local extglobWasOff=1
    shopt extglob >/dev/null && extglobWasOff=0 
    (( extglobWasOff )) && shopt -s extglob # Turn 'extglob' on, if currently turned off.
    # Trim leading and trailing whitespace
    local var=$1
    var=${var##+([[:space:]])}
    var=${var%%+([[:space:]])}
    (( extglobWasOff )) && shopt -u extglob # If 'extglob' was off before, turn it back off.
    echo -n "$var"  # Output trimmed string.
}
indexOf(){
    echo "$1indexOfInnerSeparator$2" | awk -F'indexOfInnerSeparator' '{print index($1,$2)}'
}

export LANG=c
echo 'this script will call "zypper update" with additional features as follows:
(1) automatically disable unreachable repositories.
(2) automatically kill the process which is blocking "zypper update", such as packagekitd.
(3) do not ask anything, use default answers automatically.
(4) automatically trust and import new repository signing keys.
(5) automatically say "yes" to third party license confirmation prompt.
'
# index of repository. used to disable repository
repo_idx=0
# store all unreachable repositories. only for display purpose.
unreachable_repos=()

update_options_str="-l"

# -2 是为了排除列标题和紧接着的空行
repo_count=`zypper ls -u | awk -F'|' 'END{  print NR - 2}'`
OLD_IFS=$IFS

# 由于 repo name 可能包含空格，所以必须要求 for in 只按换行符来识别数组元素
IFS=$'\n' 
for name_url in `zypper ls -u | awk -F'|' '{ if (NR > 2) print $3"|"$8}'`;do

    # 数值相加
    repo_idx=$((repo_idx + 1))
    
    # 按 | 来分割名称和URL
    repo_name=`echo $name_url|awk -F'|' '{print $1}'`
    repo_url=`echo $name_url|awk -F'|' '{print $2}'`
    
    repo_url=$(trim "$repo_url")
    
    # bash 方式的 startsWith
    if [[ $repo_url == http* ]]; then
    
       # 访问文件并获取 HTTP STATUS CODE
       url_status=`curl --connect-timeout 5 -m 10 -Is $repo_url/repodata/repomd.xml | head -n 1 |awk '{print $2}'`
       
       # 判断字符串是否只包含数字
       if [[ $url_status =~ ^-?[0-9]+$ ]] && [[ $url_status -eq 200 ]] ; then
           echo '('$repo_idx'/'$repo_count')' "$repo_name Access OK" 
           
           # 组装 update_options_str。包括只从可达的 repo 更新软件
           update_options_str="$update_options_str -r $repo_idx"
       else 
           echo '('$repo_idx'/'$repo_count')' "$repo_name Access Failed" 
           unreachable_repos[${#unreachable_repos[@]}]=$repo_name
       fi       
    fi
done
echo "unavailable repositories :"
for repo in "${unreachable_repos[@]}"
do
    echo "$repo"
done
echo "temporarily disable these repositories and start to update."
IFS=$OLD_IFS 
zypper_output=`sudo zypper -n --gpg-auto-import-keys up $update_options_str 2>&1`
blocked_str_exists=`indexOf "$zypper_output" "System management is locked by the application with pid"`
if [ "$blocked_str_exists" != "0" ]; then
    blocking_pid=`echo $zypper_output | awk '{print $10}'`
    echo "process $blocking_pid is blocking \"zypper update\", try to kill it."
    sudo kill -9 "$blocking_pid"
    sudo zypper -n --gpg-auto-import-keys up $update_options_str
fi


