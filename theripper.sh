#!/usr/bin/env bash

##################################################################
# Description: Uses wget's spider with aria2c's parallel downloading
# Usage: ./theripper.sh "opendirlink" "opendirsubstring"
# Example ./theripper.sh "libgen.io/comics0/_DC/100%20Bullets%20-%20Deluxe%20Edition%20%282013%29%20%5b1-5%5d/" "libgen.io/comics0/_DC"
#
# TODO: Implement GNU Parallel so two or more files can be downloaded at the same time.
####################################################################

set -e

URL=$1
ROOT_PATH=$2
LIST=$TMP/list-$$.txt
MAX_CONNECTIONS_PER_SERVER=16

usage() {
  cat <<EOF
Uses wget's spider with aria2c's parallel for downloading open
directories.

Usage: $SCRIPT_NAME [options] URL PATH
EOF
}

spider() {
  local logfile=$TMP/opendir-$$.log
  wget -o $logfile -e robots=off -r --no-parent --spider "$URL"
  cat $logfile | grep -i Removing | sed -e "s/Removing //g" | \
    sed 's/.$//' | sed '/index.html/d' > $LIST
  echo $URL | sed 's/[/].*$//' | xargs rm -rf
}

download() {
  while read link; do
      echo "Downloading $link"

      # Remove text after last /
      FULL_PATH=$(echo $link | sed 's%/[^/]*$%/%')
      FILE_PATH=${FULL_PATH#${ROOT_PATH}/}

      echo "Saving to $FILE_PATH"
      # Since the links in the file doesn't have an identifier aria2c will error
      IDN="http"
      if [[ ${URL:0:5} == "https" ]]; then
        IDN="https"
      fi
      DOWNLOAD_LINK=$(echo $link | sed -e "s/$URL/$IDN:\/\/$URL/g")
      aria2c --continue=true \
        --max-connection-per-server=$MAX_CONNECTIONS_PER_SERVER \
        --split=16 --min-split-size=1M --dir="$FILE_PATH" "$DOWNLOAD_LINK"
  done  < $LIST
}

if [[ -z $1 || -z $2 ]]; then
  usage
  exit 1
fi

echo "Creating list of urls..."
spider
echo "Index created!"
download

# Cleanup
trap "rm -f '$LIST'" EXIT
