#!/bin/bash
DATE=$(date +%y%m%d)
FILE=archive$DATE.tar.gz
CONFIG_FILE=/archive/Files_To_Backup
DESTINATION=/archive/$FILE
if [ -f $CONFIG_FILE ]
then
	echo
else
	echo
	echo "$CONFIG_FILE does not exist."
	echo "Backup not completed due to missing Configuration File"
	echo
	exit
fi
FILE_NO=1
exec < $CONFIG_FILE
read FILE_NAME
while [ $? -eq 0 ]
do
	if [ -f $FILE_NAME -o -d $FILE_NAME ]
	then
		FILE_LIST="$FILE_LIST $FILE_NAME"
	else
		echo
		echo "$FILE_NAME, does not exist."
		echo "Obviously, I will not include it in this archive."
		echo "It is listed on line $FILE_NO of the config file."
		echo "Continuing to build archive list..."
		echo
	fi
	read FILE_NAME
done
echo "Starting archive..."
echo
tar -czf $DESTINATION $FILE_LIST 2> /dev/null
echo "Archive completed"
echo "Resulting archive file is: $DESTINATION"
echo
exit