#!/bin/bash
##################################################################
# Description: Uses wget's spider with aria2c's parallel downloading
# Usage: ./theripper.sh "opendirlink" "opendirsubstring"
# Example ./theripper.sh "libgen.io/comics0/_DC/100%20Bullets%20-%20Deluxe%20Edition%20%282013%29%20%5b1-5%5d/" "libgen.io/comics0/_DC"
# Future plan: Implement GNU Parallel so two or more files can be downloaded at the same time.
####################################################################
URL=$1
ROOTHPATH=$2
echo "Creating list of urls..."
wget -o ./opendir.log -e robots=off -r --no-parent --spider $URL
cat ./opendir.log|grep -i Removing|sed -e "s/Removing //g"|sed 's/.$//'|sed '/index.html/d' > list.txt
rm opendir.log
echo $URL|sed 's/[/].*$//'|xargs rm -rf
echo "Index created!"
LIST='list.txt'
while read link; do
    echo "Downloading $link"
    FULLPATH=$(echo $link|sed 's%/[^/]*$%/%') #Remove text after last /
    FILEPATH=${FULLPATH#${ROOTHPATH}/}
    echo "Saving to $FILEPATH"
    DOWNLOADLINK=$(echo $link|awk '$0="http://"$0') #since the links in the files doesn't have an identifier aria2c will error
    aria2c --continue=true --max-connection-per-server=16 --split=16 --min-split-size=1M --dir="$FILEPATH" "$DOWNLOADLINK"
done  < $LIST
