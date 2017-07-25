#!/usr/bin/env bash

##################################################################
# Description: Uses wget's spider with aria2c's parallel downloading
# Usage: ./theripper.sh "opendirlink" "opendirsubstring"
# Example: ./theripper.sh "http://link.com/blabla/doraemon/" "http://link.com/blabla"
####################################################################

set -e

URL=$1
ROOT_PATH=$2
LIST=./list-$$.txt
MAX_CONNECTIONS_PER_SERVER=16

usage() {
	cat <<EOF
Uses wget's spider with aria2c's parallel for downloading open
directories.
Usage: $SCRIPT_NAME [options] URL PATH
EOF
}

spider() {
	local logfile=./opendir-$$.log
	wget -o $logfile -e robots=off -r --no-parent --spider "$URL" || true
	#Grabs all lines with the pattern --2017-07-12 15:40:31-- then from the results removes everthing that ends in / (meaning it's a directory
	#then removes pattern from every line
	grep -B 2 -E '... 404 Not Found|... 403 Forbidden|... 301 Moved Permanently' $logfile | \
	grep -i '^--[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]--' | \
	grep '[^'/']$'  | sed -e 's/^--[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]--  //g' > $logfile.tmp
	while read line; do
		sed -i "\|$line|d" $logfile
	done < $logfile.tmp
	cat $logfile | grep -i '^--[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]--' | \
	grep '[^'/']$'  | sed -e 's/^--[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]--  //g' > $LIST
	#Delete the folder made by wget (deletes all empty directories in the directory this script is run
	find . -type d -empty -delete #If you have a fix for this contact me since it should only delete the folder created by wget
}

download() {
	while read link; do
		#urldecode the links
		DECODED_LINK=$(echo $link | printf "%b\n" "$(sed 's/+/ /g; s/%\([0-9a-f][0-9a-f]\)/\\x\1/g;')";)
		DECODED_ROOT_PATH=$(echo $ROOT_PATH | printf "%b\n" "$(sed 's/+/ /g; s/%\([0-9a-f][0-9a-f]\)/\\x\1/g;')";)
		# Remove text after last /
		FULL_PATH=$(echo $DECODED_LINK | sed 's%/[^/]*$%/%')
		FILE_PATH=${FULL_PATH#${DECODED_ROOT_PATH}/}
		echo "${link}" >> link-$$.down
		echo " dir=$FILE_PATH" >> link-$$.down
		echo " continue=true" >> link-$$.down
		echo " max-connection-per-server=$MAX_CONNECTIONS_PER_SERVER" >> link-$$.down
		echo " split=16" >> link-$$.down
		echo " user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36" >> link-$$.down
		echo " header=Accept: text/html" >> link-$$.down
		echo -e " min-split-size=1M\n" >> link-$$.down
	done  < $LIST
	#Download links
	aria2c -i link-$$.down -j 10

}

if [[ -z $1 || -z $2 || $# -ge 3 ]]; then
	usage
	exit 1
fi

echo "Creating list of urls..."
spider
echo "Index created!"
download

# Cleanup
rm opendir-$$.log
rm opendir-$$.log.tmp
rm list-$$.txt
rm link-$$.down
