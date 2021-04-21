# @Author: Aliao  
# @Repository: https://github.com/vod-ka   
# @Date: 2021-04-21 20:17:13  
# @Last Modified by:   Aliao  
# @Last Modified time: 2021-04-21 20:17:13  
for line in $(cat b.txt)
do
    find ./ -name "$line".txt -exec rm -rf {} \;
    find ./ -name "$line".mp4 -exec rm -rf {} \;
    find ./ -name "$line".evb -exec rm -rf {} \;
done