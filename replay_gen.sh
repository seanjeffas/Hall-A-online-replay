#!/bin/sh 

source $HOME/sbs/sbs_devel/install/bin/sbsenv.sh

#export SBS_REPLAY=$HOME/sbs/sbs_devel/SBS-replay
#export DATA_DIR=$HOME/sbs/data
#export DATA_DIR=/cache/mss/halla/sbs/raw
#export DB_DIR=$SBS_REPLAY/DB
#export OUT_DIR=$HOME/sbs/Rootfiles

runnum=$1
nevents=$2
first_event=$3
begin_seg=$4
nseg=$5
CM_plots=$6
sbs_gems=$7



module purge
module load analyzer/1.7.4

maxstream=0

FILE1=/adaqeb1/data1/e1209016_${runnum}.evio.2.0
FILE2=/adaqeb2/data1/e1209016_${runnum}.evio.2.0
FILE3=/adaqeb3/data1/e1209016_${runnum}.evio.2.0
FILE4=/cache/halla/sbs/GEnII/raw/e1209016_${runnum}.evio.2.0

# This is done to get the right stream number on the output
# If these files aren't found then we know if is single stream
if [ -f $FILE1 ] || [ -f $FILE2 ] || [ -f $FILE3 ] || [ -f $FILE4 ]; then
    maxstream=2
fi

analyzer -b -q 'replay_gen.C+('$runnum','$nevents','$first_event',"e1209016",'$begin_seg$','$nseg','$maxstream',0,'$CM_plots','$sbs_gems')'





