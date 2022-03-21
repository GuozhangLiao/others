#!/bin/bash
# @Author: Aliao  
# @Repository: https://github.com/vod-ka   
# @Date: 2021-04-21 20:14:36  
# @Last Modified by:   Aliao  
# @Last Modified time: 2021-04-21 20:14:36  

Blue(){
    echo -e "\033[34;01m$1\033[0m"
}

Red(){
    echo -e "\033[31;01m$1\033[0m"
}

Action(){
    for line in $(cat a.txt)
    do
        find /mnt/* -name "$line.*" -exec cp {} /home/music/ \;
    done
}
