#!/bin/bash
# @Author: Aliao  
# @Repository: https://github.com/vod-ka   
# @Date: 2021-04-21 20:14:36  
# @Last Modified by:   Aliao  
# @Last Modified time: 2021-04-21 20:14:36  
for line in $(cat a.txt)
do
    #touch "$line".{txt,mp4,3gp,evb}
    find /mnt/* -name "$line".mp4 -exec mv {} /home/music/ \;
    find /mnt/* -name "$line".3gp -exec mv {} /home/music/ \;
    find /mnt/* -name "$line".evb -exec mv {} /home/music/ \;
    find /mnt/* -name "$line".mkv -exec mv {} /home/music/ \;
    find /mnt/* -name "$line".mov -exec mv {} /home/music/ \;
done