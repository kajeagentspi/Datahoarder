# Datahoarder
Scripts for grabbing files of the Internet

theripper.sh 

Description: Uses wget's spider with aria2c's parallel downloading

Usage: ./theripper.sh "opendirlink" "opendirsubstring"

Example ./theripper.sh "libgen.io/comics0/_DC/100%20Bullets%20-%20Deluxe%20Edition%20%282013%29%20%5b1-5%5d/" "libgen.io/comics0/_DC"

Future plan: Implement GNU Parallel so two or more files can be downloaded at the same time.
