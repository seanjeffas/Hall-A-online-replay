#!/bin/sh 

################################################################
#
# Written by Sean Jeffas
# Last Updated: November 11, 2022
#
#
# This script is for combining many root files. It is called by other scripts,
# like replay_jobs_gen.sh to automatically combine things for panguin
# plots to use. 
#
# To run execute: combine_files.sh #runnum #first_event #last_event #nevents_per_job #nseg
#
# This script can either combine runs that were split by event number or 
# segment numbers. To combine segments set first_event = -1 and then it will 
# combine things assuming full replays instead.
#
################################################################



runnumber=$1
first_event=$2
last_event=$3
nevents_per_job=$4
nseg=$5

maxstream=0

FILE1=/adaqeb1/data1/e1209016_${runnumber}.evio.2.0
FILE2=/adaqeb2/data1/e1209016_${runnumber}.evio.2.0
FILE3=/adaqeb3/data1/e1209016_${runnumber}.evio.2.0
FILE4=/cache/halla/sbs/GEnII/raw/e1209016_${runnumber}.evio.2.0

# This is done to get the right stream number on the output
# If these files aren't found then we know if is single stream
if [ -f $FILE1 ] || [ -f $FILE2 ] || [ -f $FILE3 ] || [ -f $FILE4 ]; then
    maxstream=2
fi

total_events=$(($last_event - $first_event))
total_events=$(($total_events / 1000))

cd ~/sbs/Rootfiles

out_file=gen_replayed_${runnumber}_${total_events}k_events.root

if [ $first_event == -1 ]; then
   out_file=gen_replayed_${runnumber}_full.root
fi


cmd=""

ievent=$first_event

if [ $first_event == -1 ]; then
    for ((iseg=0; iseg <= $nseg; iseg++))
    do
	
	cmd=$cmd" e1209016_fullreplay_"$runnumber"_stream0_"$maxstream"_seg"$iseg"_"$iseg".root"
	
    done
else
    until [ $ievent -gt $last_event ]
    do
	
	cmd=$cmd" e1209016_replayed_"$runnumber"_stream0_"$maxstream"_seg0_"$nseg"_firstevent"$ievent"_nevent"$nevents_per_job".root"
	
	ievent=$(($ievent + $nevents_per_job))
    done
fi

LOG_FILE=$HOME/sbs/logs/gen_replayed_${runnumber}_logs.txt

echo ""
echo "Putting many ROOT files together. This will take 2-5 minutes"

hadd -k -f -j 16 $out_file $cmd >> $LOG_FILE 2>&1

echo "All events in ROOT file "$out_file
