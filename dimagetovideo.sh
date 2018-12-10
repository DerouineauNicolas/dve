#!/bin/bash -e

set -e

function usage() {
    cat << EOF

This script breaks a set of images into chunks and encodes them in parallel via SSH on
multiple hosts.

usage: 

$0 -i /sledge/sledge03/SLEDGE03_D2/footage/IN-HUMBLE-GUISE/GRAB/1920x1080/IN_HUMBLE_GUISE_%07d.dpx -o 864000 -n 31561 -j 4 -f 24 -o /nas_restau/nasrestau6/footage/IN-HUMBLE-GUISE/PRORES/

OPTIONS:
    -h  this help message.
    -l  comma separated list of hosts to use to encode. (default=${SERVERS})
    -o  Number of frames to skip at the beginning
    -n  number of frames to encode
    -f  fps
    -i  input
    -j  number of jobs to be run in parrallel
    -o  output dir
EOF
}

while getopts “h:l:o:n:f:b:i:j:o” OPTION; do
    case $OPTION in
    h)
    usage
    exit 1
    ;;
    l)
    SERVERS="$OPTARG"
    ;;
    o)
    OFFSET="$OPTARG"
    ;;
    n)
    NUMFRAME="$OPTARG"
    ;;    
    f)
    FPS="$OPTARG"
    ;;
    i)
    INPUTDIR="$OPTARG"
    ;;
    j)
    NUMJOBS="$OPTARG"
    ;;    
    o)
    OUTPUTDIR="$OPTARG"
    ;;
    v)
    VERBOSE="info"
    ;;
    ?)
    usage
    exit
    ;;
    esac
done
shift $((OPTIND-1))

DURATION=NUMFRAME/(NUMJOBS*FPS)

#echo "ffmpeg -framerate ${FPS} -start_number ${OFFSET} -i ${INPUTDIR}/${BASENAME} -t ${DURATION} -vcodec ffv1 -level 3 -threads 16 -coder 1 -context 1 -g 1 -slices 24 -slicecrc 1 -r 24 /nas_restau/nasrestau6/footage/IN-HUMBLE-GUISE/PRORES/test1.mkv