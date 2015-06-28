#!/bin/bash

str_trim() {
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


export LANG=c
echo 'this script will call "zypper update" with additional features as follows:
(1) automatically disable unreachable repositories
(2) do not ask anything, use default answers automatically
(3) automatically trust and import new repository signing keys.
(4) automatically say "yes" to third party license confirmation prompt.
'
repo_idx=0
unreachable_repos=()
update_options_str=""
repo_count=`zypper ls -u | awk -F'|' 'END{  print NR - 2}'`
OLD_IFS=$IFS
IFS=$'\n' 
for name_url in `zypper ls -u | awk -F'|' '{ if (NR > 2) print $3"|"$8}'`;do
    repo_idx=$((repo_idx + 1))
    
    repo_name=`echo $name_url|awk -F'|' '{print $1}'`
    repo_url=`echo $name_url|awk -F'|' '{print $2}'`
    
    repo_url=$(str_trim "$repo_url")
    if [[ $repo_url == http* ]]; then
       url_status=`curl --connect-timeout 10 -Is $repo_url/repodata/repomd.xml | head -n 1 |awk '{print $2}'`
       
       if [ $url_status -eq 200 ] ; then
           echo '('$repo_idx'/'$repo_count')' "$repo_name Access OK" 
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
sudo zypper -n --gpg-auto-import-keys up -l $update_options_str

