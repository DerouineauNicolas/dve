#!/bin/bash -e

set -e

function on_finish() {
	echo "Cleaning up temporary working files"
    cd "$CWD"
	rm  commands.txt
	echo "Finished cleaning"
}

function usage() {
    cat << EOF

This script breaks a set of images into chunks and encodes them in parallel via SSH on
multiple hosts.
This scripts assumes that NFS folder used for input/outputs are already mounted on the hosts.

usage: 

$0 -i /sledge/sledge03/SLEDGE03_D2/footage/IN-HUMBLE-GUISE/GRAB/1920x1080/IN_HUMBLE_GUISE_%07d.dpx -l root@10.20.173.1,root@10.20.173.2 -s 864000 -n 31561 -j 4 -f 24 -o /nas_restau/nasrestau6/footage/IN-HUMBLE-GUISE/PRORES/

OPTIONS:
    -h  this help message.
    -l  comma separated list of hosts to use to encode. (default=${SERVERS})
    -s  Number of frames to skip at the beginning
    -n  number of frames to encode
    -f  fps
    -i  input
    -j  number of jobs to be run in parrallel
    -o  output dir
EOF
}

while getopts “h:l:s:n:f:b:i:j:o:v” OPTION; do
    case $OPTION in
    h)
    usage
    exit 1
    ;;
    l)
    SERVERS="$OPTARG"
    ;;
    s)
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

trap on_finish EXIT

declare -i DURATION=${NUMFRAME}/${NUMJOBS}
declare -i CURRENT_OFFSET=${OFFSET}
echo ${CURRENT_OFFSET}
ffmpegCommands=()

for (( i=0; i < $NUMJOBS; i++ ))
do
    if [ $i = $(($NUMJOBS-1)) ]; then
        #On the last chunk, we add the modulo of the frame duration
        DURATION+=$((${NUMFRAME}%${NUMJOBS}))
    fi
    CurrentChunk="ffmpeg -framerate ${FPS} -start_number ${CURRENT_OFFSET} -i ${INPUTDIR} -vframes ${DURATION} -vcodec ffv1 -level 3 -threads 16 -coder 1 -context 1 -g 1 -slices 24 -slicecrc 1 -r 24 ${OUTPUTDIR}chunk_$i.mkv"
    ffmpegCommands+=( "${CurrentChunk}")
    CURRENT_OFFSET+=${DURATION} 
done

touch commands.txt

for ((i = 0; i < ${#ffmpegCommands[@]}; i++))
do
    echo "${ffmpegCommands[$i]}" >> commands.txt
done

echo "The following commands are going to be run"
cat commands.txt

parallel --progress -S ${SERVERS} --workdir ... < commands.txt

