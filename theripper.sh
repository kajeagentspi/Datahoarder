#!/bin/bash
##################################################################
# Description: Uses wget's spider with aria2c's parallel downloading
# Usage: ./theripper.sh "opendirlink" "opendirsubstring"
# Example ./theripper.sh "libgen.io/comics0/_DC/100%20Bullets%20-%20Deluxe%20Edition%20%282013%29%20%5b1-5%5d/" "libgen.io/comics0/_DC"
# Future plan: Implement GNU Parallel so two or more files can be downloaded at the same time.
####################################################################
URL=$1
ROOTHPATH=$2
LIST=$3
echo "Creating list of urls..."
wget -o ./${LIST}.log -e robots=off -r --no-parent --spider $URL
cat ./${LIST}.log|grep -i Removing|sed -e "s/Removing //g"|sed 's/.$//'|sed '/index.html/d' > $LIST
rm ${LIST}.log
echo $URL|sed 's/[/].*$//'|xargs rm -rf
echo "Index created!"
while read link; do
    echo "Downloading $link"
    FULLPATH=$(echo $link|sed 's%/[^/]*$%/%') #Remove text after last /
    FILEPATH=${FULLPATH#${ROOTHPATH}/}
    echo "Saving to $FILEPATH"
    DOWNLOADLINK=$(echo $link|awk '$0="http://"$0') #since the links in the files doesn't have an identifier aria2c will error
    echo $DOWNLOADLINK >> ${LIST}.down
    echo " dir=$FILEPATH" >> ${LIST}.down
    echo " continue=true" >> ${LIST}.down
    echo " max-connection-per-server=16" >> ${LIST}.down
    echo " split=16" >> ${LIST}.down
    echo " min-split-size=1M\n" >> ${LIST}.down
done  < $LIST
aria2c -i ${LIST}.down -j 10
