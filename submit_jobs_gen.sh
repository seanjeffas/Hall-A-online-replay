#!/bin/sh

################################################################
#
# Written by Sean Jeffas
# Last Updated: October 10, 2022
#
#
#
# This script only exists to be called by replay_jobs_gen.sh. It will submit 
# many jobs as a nohup process, while running the last job in the terminal
# so the user can see the progress. Again the user should never use this in
# the terminal but instead use the replay_jobs_gen.sh script. But the input
# should be
#
# Input: submit_jobs_gen.sh #runnumber #first_event #events_per_job #number_of_jobs #number_of_segments #events_in_a_segment #use_sbs_gems
#
#
#
################################################################


runnum=$1
first_event=$2
nevents_per_job=$3
n_jobs=$4
last_seg=$5
nevents_per_seg=$6
CM_plots=$7
sbs_gems=$8



#Get the percentage of memory currently in use
musage=$(free | awk '/Mem/{printf("RAM Usage: %.2f%\n"), $3/$2*100}' |  awk '{print $3}' | cut -d"." -f1)

jobusage=50 #jobs take from ~5% memory with CM plots. I will just use 3.3 for now

if [ $CM_plots == 0 ]; then
    jobusage=30   # 3% memory with CM plots turned off
fi


mem_jobs=$(((1000 - $musage*10) / $jobusage)) #calculate space for jobs

echo "Memory avialable for "$mem_jobs" jobs"
echo "Replaying Run "$runnumber

#stop if there is no memory available
if (($mem_jobs == 0)); then
    exit
fi

#Reduce jobs if there is not enough memory available
if (($mem_jobs < $n_jobs)); then
    n_jobs=$mem_jobs
fi

#get environments
source ~/.bashrc
gosbs

#echo $last_seg" "$first_seg
ievent=$first_event
last_event=$(($first_event + $nevents_per_job*($n_jobs)))

#Loop over all jobs from last segment downward
#The point of this is because we run the last job in the terminal and we don't want it to be the last segment, which could have a low number of events
until [ $ievent -gt $(($last_event - $nevents_per_job)) ]
do

    iseg=$(($ievent / $nevents_per_seg))

    echo "Submitted events "$ievent" to "$(($ievent + $nevents_per_job))
    fnameout_pattern=""$HOME"/sbs/logs/gen_replayed_"$runnum"_out_first_event_"$ievent".txt"
    
    #Start nohup processes except for the last job, which is done on the screen
    if (($ievent == $(($last_event - $nevents_per_job))));then
    	replay_gen.sh $runnum $nevents_per_job $ievent 0 $(($last_seg + 1)) $CM_plots $sbs_gems
    else
    	nohup replay_gen.sh $runnum $nevents_per_job $ievent 0 $(($last_seg + 1)) $CM_plots $sbs_gems >$fnameout_pattern 2>&1 &
    fi
  
    #Iterate for the next job
    let "ievent+="$nevents_per_job

done

#Sleep at the end to make sure that all the jobs catch up
sleep 30s




