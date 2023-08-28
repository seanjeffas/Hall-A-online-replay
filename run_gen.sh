#!/bin/sh 

################################################################
#
# Written by Sean Jeffas (sj9ry@virginia.edu)
# Last Updated: January 27, 2023
#
#
# This script is the main shift replay for GEn. It will run a number of
# events entered by the user. It will divide those events into jobs
# of 1000 events, and then combine the output. Then it will force the 
# user to look through some panguin plots and post them to the logbook.
# This should only be done for 50k events or less. The computer cannot 
# handle running more jobs. Scroll down to the "main script" if you want
# to edit anything.
#
#
# Total events is in thousands
# To run execute: run_gen.sh #runnumber #total_events
#
# example: run_gen.sh 1700 50
# This will replay 50000 events from run 1700
#
################################################################

source $HOME/sbs/sbs_devel/install/bin/sbsenv.sh

###############################################################################
###############################################################################
##################This section is for functions###############################
###############################################################################
###############################################################################

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

#This function is called when prompting the user
function yes_or_no_complicated(){
  while true; do
    read -p "$* [yes I am sure/n]: " yn
    case $yn in
      "yes I am sure") return 0 ;;
      [Nn]*) echo "No entered" ; exit;;
      *) echo "Because of the failure mode you must type 'yes I am sure' to make this work" ;;
    esac
  done
}

#check if the run is currently going in CODA
function check_current_run(){

    runnum=$1
    is_run=0

    #this command returns the run number if we are using the GEnII-3Stream config
    current_run_num=$(ssh -o LogLevel=QUIET -t adaq@adaq2 ssh -o LogLevel=QUIET -t sbs-onl@adaq2 "plask -h adaq2 -n SBSDAQ -c:srn,GEnII-3Stream")
    current_run_num="${current_run_num%?}" #there is an extra space on the end of the run number that must be removed

       
    if [[ $current_run_num =~ ^-?[0-9]+$ ]]; then  #check if the response is an integer
	if (($runnum == $current_run_num)); then  #check if it matches the run in question
	    is_run=1
	fi
    fi

    #Repeat the process above but for the  GEnII-NoSBSGems config
    current_run_num=$(ssh -o LogLevel=QUIET -t adaq@adaq2 ssh -o LogLevel=QUIET -t sbs-onl@adaq2 "plask -h adaq2 -n SBSDAQ -c:srn,GEnII-NoSBSGems")
    current_run_num="${current_run_num%?}"

    if [[ $current_run_num =~ ^-?[0-9]+$ ]]; then
	if (($runnum == $current_run_num)); then
	    is_run=1
	fi
    fi

    echo $is_run
}

#Check the number of events for a run currently going in CODA
function check_current_run_events(){

    events=$1
    events_good=0

    #this command returns the event number if we are using the GEnII-3Stream config
    current_run_events=$(ssh -o LogLevel=QUIET -t adaq@adaq2 ssh -o LogLevel=QUIET -t sbs-onl@adaq2 "plask -h adaq2 -n SBSDAQ -c:cen,GEnII-3Stream,sbsTS21")
    current_run_events="${current_run_events%?}"   #remove extra space at the end of the number
    
    if [[ $current_run_events =~ ^-?[0-9]+$ ]]; then #check if it is an integer
	if (($current_run_events > $events)); then  #check if enough events have been collected to run this replay
	    events_good=1
	fi
    fi

    #Repeat the process above but for the  GEnII-NoSBSGems config
    current_run_events=$(ssh -o LogLevel=QUIET -t adaq@adaq2 ssh -o LogLevel=QUIET -t sbs-onl@adaq2 "plask -h adaq2 -n SBSDAQ -c:cen,GEnII-NoSBSGems,sbsTS21")
    current_run_events="${current_run_events%?}"
    
    if [[ $current_run_events =~ ^-?[0-9]+$ ]]; then
	if (($current_run_events > $events)); then
	    events_good=1
	fi
    fi

    echo $events_good
}


###############################################################################
###############################################################################
###############################################################################



###############################################################################
####This is the start of the main script



runnum=$1
events=$2  #in thousands

if [ -z "$events" ]
then
    events=50
fi

######### These are the variables that the user can change. Everything else should remain untouched #########
nevents_per_job=1000
CM_plots=1
sbs_gems=0 #0 for no sbs gems, 1 for yes
golden_run=4574 #type in an unrealistic number if you don't want any golden run
########################################################################


#Now we start some logic checks to see if this run has enough events to analyze
good_run=0
good_events=0
is_cur_run=$(check_current_run $runnum)    #check if the run is question is still going in CODA
run_events=$(./get_final_events_from_dalma.sh $runnum)  #Check the number of events, which only works if the run is over

failure_mode=0   #start with no failure mode

#if the run is ongoing check that it has enough events to rreplay
if (($is_cur_run == 1)); then
    good_events=$(check_current_run_events $(($events*1000)))
fi

if (($is_cur_run == 1 && $good_events == 0)); then #The run is ongoing and not enough events yet
    failure_mode=1
elif (($is_cur_run == 0)); then
    if [[ $run_events =~ ^-?[0-9]+$ ]]; then   #the run can be found in the logs
	if (($run_events > $(($events*1000)))); then   #the run has enough events
	    good_run=1
	else
	    failure_mode=2
	fi
    else
	failure_mode=3
    fi
fi

#print a failure message to the screen
if (($failure_mode == 1)); then
    echo "!!!!!!!!!!!!!!!!!!!!!FAILURE!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "FAILURE: The current run has not reached "$events"k events. Please wait until it gets to that number"
elif (($failure_mode == 2)); then
    echo "!!!!!!!!!!!!!!!!!!!!!FAILURE!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "FAILURE: This run is completed but does not have "$events"k events. Therefore it cannot be replayed properly"
elif (($failure_mode == 3)); then
    echo "!!!!!!!!!!!!!!!!!!!!!FAILURE!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "FAILURE: The run cannot be found, therefore it may not be replayed properly"
fi

#make the user answer a more complex message so they can't say yes without reading the failure messages
if (($failure_mode != 0)); then
    yes_or_no_complicated "It looks like this run will not replay properly, but you may overide this. Are you sure?"
fi

#We are now done checking if this is a good run and can continue on to the replay



tempevents=$((1000*$events))

#This script splits up into jobs of 1000 events and then recombines them
replay_jobs_gen.sh $runnum 0 $tempevents $nevents_per_job $CM_plots $sbs_gems

# THis is the output root file name
ROOTFILE=~/sbs/Rootfiles/gen_replayed_${runnum}_${events}k_events.root
GOLDENROOTFILE=~/sbs/Rootfiles/gen_replayed_${golden_run}_${events}k_events.root

# set environment to get panguin scripts
export PANGUIN_CONFIG_PATH=/adaqfs/home/a-onl/sbs/sbs_devel/SBS-replay/onlineGUIconfig:/adaqfs/home/a-onl/sbs/sbs_devel/SBS-replay/onlineGUIconfig/scripts

# Directory where output panguin plots will be stored
PLOTS_DIR=/chafs2/work1/sbs/plots/
echo  $ROOTFILE $GOLDENROOTFILE $PLOTS_DIR
panguin_plots_gen.sh $runnum $events"k" $ROOTFILE $GOLDENROOTFILE $PLOTS_DIR

#grep -i 'scaler summary' $LOG_DIR/*_${runnum}_*.log
