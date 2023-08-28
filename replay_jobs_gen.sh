#!/bin/sh

################################################################
#
# Written by Sean Jeffas (sj9ry@virginia.edu)
# Last Updated: November 11, 2022
#
#
# This script is flexible and will split a GEn replay into many jobs
# based on the first event, total events, and number of events per
# job. It will split things up between the aonl machines evenly and
# automatically reduce jobs if the machine is low on memory. It will
# open one xterm for each aonl machine and will run the script
# replay_fast_segments_gen.sh in each xterm. This second script will 
# start all the replay jobs, while showing one job on the screen so the
# user can watch the progress.
#
#
# To run execute: replay_jobs_gen.sh #runnumber #first_event #total_events #events_per_job #use_sbs_gems
#
#
# Alternatively you can run full replays of a number of segments 
# instead of splitting it by events. This is done be setting
# first_event = -1. It will then split the jobs into 1 segment per job
# up to nsegments specified by the user
#
# To run execute: replay_jobs_gen.sh #runnumber 0 -1 10 #use_sbs_gems #nsegments
#
################################################################

#This function is called when prompting the user
function yes_or_no(){
  while true; do
    read -p "$* [y/n]: " yn
    case $yn in
      [Yy]*) return 0 ;;
      [Nn]*) echo "No entered" ; exit;;
    esac
  done
}


runnumber=$1
first_event=$2
nevents=$3
nevents_per_job=$4
CM_plots=$5
sbs_gems=$6
nseg_replay=$7

if [ -z "$nseg_replay" ]
then
    nseg_replay=1
fi

DATA_DIR=/adaqeb1/data1/
DATA_DIR2=/cache/halla/sbs/GEnII/raw/


#These variables define how we want our jobs to be distributed
nevents_per_seg=200000
max_jobs=20
n_machines=4
n_machines_real=3 #this is needed temporarily while we wait for a new aonl3 computer

nseg=-1
maxstream=0



#Loop over EVIO files to see how many segments there are
for ((iseg=0; iseg<200; iseg++))
do

   
    FILE1=${DATA_DIR}e1209016_${runnumber}.evio.0.${iseg}
    FILE2=${DATA_DIR}e1209016_${runnumber}.evio.1.${iseg}
    FILE3=${DATA_DIR}e1209016_${runnumber}.evio.2.${iseg}

    FILE4=${DATA_DIR2}e1209016_${runnumber}.evio.0.${iseg}
    FILE5=${DATA_DIR2}e1209016_${runnumber}.evio.1.${iseg}
    FILE6=${DATA_DIR2}e1209016_${runnumber}.evio.2.${iseg}
        
   
    if [ ! -f $FILE1 ] && [ ! -f $FILE2 ] && [ ! -f $FILE3 ] && [ ! -f $FILE4 ] && [ ! -f $FILE5 ] && [ ! -f $FILE6 ]; then
	break
    fi
    
    nseg=$iseg
    
done


FILE1=/adaqeb1/data1/e1209016_${runnumber}.evio.2.0
FILE2=/adaqeb2/data1/e1209016_${runnumber}.evio.2.0
FILE3=/adaqeb3/data1/e1209016_${runnumber}.evio.2.0
FILE4=/cache/halla/sbs/GEnII/raw/e1209016_${runnumber}.evio.2.0

# This is done to get the right stream number on the output
# If these files aren't found then we know if is single stream
if [ -f $FILE1 ] || [ -f $FILE2 ] || [ -f $FILE3 ] || [ -f $FILE4 ]; then
    maxstream=2
fi


#Exit if there are no EVIO files
if (($nseg == -1)); then
    echo "No EVIO files found for run "$runnumber
    exit
fi

njobs=$((($nevents - $first_event) / $nevents_per_job))

#Get number of segments for each machine to process
job_per_machine=$((($njobs) / $n_machines_real));
job_remainder=$((($njobs) % $n_machines_real));

# Only replay segments that actually exist
if (($nseg < $nseg_replay)); then
    nseg_replay=$nseg
fi

# if nevents = -1 then set things up to do a full replay
if (($nevents == -1)); then
    njobs=$(($nseg_replay + 1))   # Add 1 because segments start at 0
    job_per_machine=$((($njobs) / $n_machines_real));
    job_remainder=$((($njobs) % $n_machines_real));
fi

#This is a special case of running < $n_machines segments
if (($job_per_machine == 0 && $job_remainder != 0)); then
    n_machines_real=$job_remainder
fi

#Limit the number of segments to replay to the maximum
if (($job_per_machine > $max_jobs)); then
    njobs=$(($max_jobs * $n_machines_real))
    job_per_machine=$max_jobs
    nevents=$(($njobs * $nevents_per_job))
    if (($nevents == -1)); then
	echo "User entered more segments than possible. Will instead replay "$nseg_replay" segments."
    else
	echo "User entered more events than possible. Will instead replay "$nevents" events."
    fi
fi


ievents=$first_event
imachine_real=0    #this counts over the machines we are using
start_seg=0  #count segments if we are doing full replays 

if (($nevents == -1)); then
    yes_or_no "This will replay "$(($nseg_replay + 1))" segments of run "$runnumber" with "$njobs" jobs. Are you sure you want to continue?"
elif (($nevents == 1000000)); then
    yes_or_no "This will replay "$nevents" events of run "$runnumber" with "$njobs" jobs. This run number MUST HAVE 1M EVENTS for this to work. Are you sure you want to continue?"
else
    yes_or_no "This will replay "$nevents" events of run "$runnumber" with "$njobs" jobs. Are you sure you want to continue?"
fi

time_replay_1=`date +%s`

#Loop over machines and start running the jobs
for ((imachine=1; imachine <= n_machines; imachine++))
do

    #necessary because aonl3 is down
    if [ $imachine == 3 ]; then
	continue
    fi

    imachine_real=$(($imachine_real + 1))  #increment the number of real machines being used

    # If we are running less jobs than machines then just run all the jobs on the last machine
    if (($job_per_machine == 0));then
	imachine=$n_machines
	imachine_real=$n_machines_real
    fi

    start_event=$ievents
    end_event=$(($start_event + $job_per_machine*$nevents_per_job)) 

    end_seg=$(($start_seg + $job_per_machine))

    print_n_jobs=$job_per_machine #This variable is just for printing info to the terminal

    # If we are on the last machine then add the remainder of jobs here
    if (($imachine_real == $n_machines_real));then
	end_event=$(($end_event + $job_remainder*$nevents_per_job)) #subtract one because segments start at 0
	end_seg=$(($start_seg + $job_per_machine + $job_remainder))

	print_n_jobs=$(($print_n_jobs + $job_remainder))
    fi



    echo "Submitted "$print_n_jobs" jobs on aonl"$imachine 

    n_jobs=$((($end_event - $start_event) / $nevents_per_job))  #calculate the number of jobs
    
    if (($nevents == -1)); then
	
    	#Open an xterm for this machine and start the replays 
	echo "$runnumber   $start_seg  $end_seg" 
    	if (($imachine == $n_machines));then
    	    xterm -e "ssh a-onl@aonl"$imachine" 'cd ~/sbs_tools && submit_jobs_gen_full.sh "$runnumber" "$start_seg" "$end_seg" "$CM_plots" "$sbs_gems"'"
    	else
            xterm -e "ssh a-onl@aonl"$imachine" 'cd ~/sbs_tools && submit_jobs_gen_full.sh "$runnumber" "$start_seg" "$end_seg" "$CM_plots" "$sbs_gems"'" &
    	fi
    else
	
    	#Open an xterm for this machine and start the replays 
    	if (($imachine == $n_machines));then
    	    xterm -e "ssh a-onl@aonl"$imachine" 'cd ~/sbs_tools && submit_jobs_gen.sh "$runnumber" "$start_event" "$nevents_per_job" "$n_jobs" "$nseg" "$nevents_per_seg" "$CM_plots" "$sbs_gems"'"
    	else
            xterm -e "ssh a-onl@aonl"$imachine" 'cd ~/sbs_tools && submit_jobs_gen.sh "$runnumber" "$start_event"  "$nevents_per_job" "$n_jobs" "$nseg" "$nevents_per_seg" "$CM_plots" "$sbs_gems"'" &
    	fi
    fi
  
  
    #set starting segment for the next machine
    ievents=$(($end_event))
    start_seg=$(($end_seg + 1))

done

echo "Finished all replays"

time_replay_2=`date +%s`

#Now we will add all the replays to one file for panguin plots
combine_files.sh $runnumber $first_event $(($first_event + $nevents)) $nevents_per_job $nseg

time_replay_3=`date +%s`


echo "Replay time = "$(($time_replay_2 - $time_replay_1))
echo "Hadd time = "$(($time_replay_3 - $time_replay_2))
