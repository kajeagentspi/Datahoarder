#!/usr/bin/env bash

##################################################################
# Description: Uses wget's spider with aria2c's parallel downloading
# Usage: ./theripper.sh "opendirlink" "opendirsubstring"
# Example: ./theripper.sh "link.com/blabla/doraemon/" "link.com/blabla"
# Note: Make sure that the path doesn't contain %20's or others. You can use this site http://www.asiteaboutnothing.net/c_decode-url.html
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
	wget -o $logfile -e robots=off -r --no-parent --spider "$URL"
	cat $logfile | grep -i Removing | sed -e "s/Removing //g" | \
	sed 's/.$//' | sed '/index.html/d' > $LIST

	#Delete the folder made by wget
	echo $ROOT_PATH | sed 's/[/].*$//' | xargs rm -rf
}

download() {
	while read link; do

		# Remove text after last /
		FULL_PATH=$(echo $link | sed 's%/[^/]*$%/%')
		FILE_PATH=${FULL_PATH#${ROOT_PATH}/}

		# Since the links in the file doesn't have an identifier aria2c will error
		IDN="http://"
		if [[ ${URL:0:5} == "https" ]]; then
		IDN="https://"
		elif [[ ${URL:0:3} == "ftp" ]]; then
		IDN="ftp://"
		fi
		DOWNLOAD_LINK=$(echo "$IDN$link")
		#Enclosed the Downlaod link in quotes since echo replaces multiple spaces with a single one
		echo "${DOWNLOAD_LINK}" >> link-$$.down
		echo " dir=$FILE_PATH" >> link-$$.down
		echo " continue=true" >> link-$$.down
		echo " max-connection-per-server=$MAX_CONNECTIONS_PER_SERVER" >> link-$$.down
		echo " split=16" >> link-$$.down
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
rm list-$$.txt
rm link-$$.down

