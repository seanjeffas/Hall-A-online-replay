#!/bin/sh 

################################################################
#
# Written by Sean Jeffas
# Last Updated: October 15, 2022
#
#
# This script is for creating the panguin plots for GEnII. Its main use
# is to be called by other scripts, but you can also call it from the 
# command line if needed. It will put all the plots into the PLOTS_DIR
#
# To run execute: panguin_plots_gen.sh #runnumber #events #ROOTFILE #GOLDENROOTFILE #PLOTS_DIR
#
# example: panguin_plots_gen.sh 1234 50k e1209016_1234.root e1209016_1235.root /chafs2/work1/sbs/plots
#
################################################################


runnum=$1
events=$2
ROOTFILE=$3
GOLDENROOTFILE=$4
PLOTS_DIR=$5
sbs_gems=$6

if [ -z "$sbs_gems" ]
then
    sbs_gems=0  #default to no SBS GEMs
fi


# set environment to get panguin scripts
export PANGUIN_CONFIG_PATH=/adaqfs/home/a-onl/sbs/sbs_devel/SBS-replay/onlineGUIconfig:/adaqfs/home/a-onl/sbs/sbs_devel/SBS-replay/onlineGUIconfig/scripts

LOG_FILE=$HOME/sbs/logs/gen_replayed_${runnum}_logs.txt

#call first time to 'force' shift crew to have a look
if (($sbs_gems == 1)); then
    panguin -f SBS_critical.cfg -r $runnum -R $ROOTFILE -G $GOLDENROOTFILE
else
    panguin -f SBS_critical_noSBSGEMs.cfg -r $runnum -R $ROOTFILE -G $GOLDENROOTFILE
fi
panguin -f BBCal.cfg -r $runnum -R $ROOTFILE -G $GOLDENROOTFILE 
panguin -f hcal.cfg -r $runnum -R $ROOTFILE -G $GOLDENROOTFILE 
panguin -f grinch.cfg -r $runnum -R $ROOTFILE -G $GOLDENROOTFILE 
panguin -f BBTH.cfg -r $runnum -R $ROOTFILE -G $GOLDENROOTFILE
panguin -f BBSpectro.cfg -r $runnum -R $ROOTFILE -G $GOLDENROOTFILE

echo ""
echo "Printing pdfs, this will take a minute"

# call second time to print the plots to PDF
if (($sbs_gems == 1)); then
    panguin -f SBS_critical.cfg -r $runnum -R $ROOTFILE -G $GOLDENROOTFILE -P >> $LOG_FILE 2>&1   
else
    panguin -f SBS_critical_noSBSGEMs.cfg -r $runnum -R $ROOTFILE -G $GOLDENROOTFILE -P >> $LOG_FILE 2>&1   
fi
panguin -f bb_gem.cfg -r $runnum -R $ROOTFILE -G $GOLDENROOTFILE -P >> $LOG_FILE 2>&1
panguin -f bb_gem_basic.cfg -r $runnum -R $ROOTFILE -G $GOLDENROOTFILE -P >> $LOG_FILE 2>&1
panguin -f BBGEM_ped_and_commonmode.cfg -r $runnum -R $ROOTFILE -G $GOLDENROOTFILE -P >> $LOG_FILE 2>&1 
if (($sbs_gems == 1)); then
    panguin -f sbs_gem.cfg -r $runnum -R $ROOTFILE -G $GOLDENROOTFILE -P >> $LOG_FILE 2>&1
    panguin -f sbs_gem_basic.cfg -r $runnum -R $ROOTFILE -G $GOLDENROOTFILE -P >> $LOG_FILE 2>&1
    panguin -f SBSGEM_ped_and_commonmode.cfg -r $runnum -R $ROOTFILE -G $GOLDENROOTFILE -P >> $LOG_FILE 2>&1 
fi
panguin -f BBCal.cfg -r $runnum -R $ROOTFILE -G $GOLDENROOTFILE  -P >> $LOG_FILE 2>&1
panguin -f hcal.cfg -r $runnum -R $ROOTFILE -G $GOLDENROOTFILE  -P >> $LOG_FILE 2>&1
panguin -f grinch.cfg -r $runnum -R $ROOTFILE -G $GOLDENROOTFILE  -P >> $LOG_FILE 2>&1
panguin -f BBTH.cfg -r $runnum -R $ROOTFILE -G $GOLDENROOTFILE  -P >> $LOG_FILE 2>&1
panguin -f BBSpectro.cfg -r $runnum -R $ROOTFILE -G $GOLDENROOTFILE -P >> $LOG_FILE 2>&1


# Move the PDFs to the proper directory
if (($sbs_gems == 1)); then
    mv summaryPlots_${runnum}_SBS_critical.pdf $PLOTS_DIR
else
    mv summaryPlots_${runnum}_SBS_critical_noSBSGEMs.pdf $PLOTS_DIR
fi
mv summaryPlots_${runnum}_bb_gem.pdf $PLOTS_DIR
mv summaryPlots_${runnum}_bb_gem_basic.pdf $PLOTS_DIR
mv summaryPlots_${runnum}_BBGEM_ped_and_commonmode.pdf $PLOTS_DIR
if (($sbs_gems == 1)); then
    mv summaryPlots_${runnum}_sbs_gem.pdf $PLOTS_DIR
    mv summaryPlots_${runnum}_sbs_gem_basic.pdf $PLOTS_DIR
    mv summaryPlots_${runnum}_SBSGEM_ped_and_commonmode.pdf $PLOTS_DIR
fi
mv summaryPlots_${runnum}_BBCal.pdf $PLOTS_DIR
mv summaryPlots_${runnum}_hcal.pdf $PLOTS_DIR
mv summaryPlots_${runnum}_grinch.pdf $PLOTS_DIR
mv summaryPlots_${runnum}_BBTH.pdf $PLOTS_DIR
mv summaryPlots_${runnum}_BBSpectro.pdf $PLOTS_DIR

# function used to prompt user for questions
function yes_or_no(){
  while true; do
    read -p "$* [y/n]: " yn
    case $yn in
      [Yy]*) return 0 ;;
      [Nn]*) echo "No entered" ; return 1 ;;
    esac
  done
}

# Upload the plots to the HALOG
if (($sbs_gems == 1)); then
    yes_or_no "Upload these plots to logbook HALOG? " && \
	/adaqfs/apps/bin/logentry \
	--logbook "HALOG" \
	--tag Autolog \
	--title ${events}" replay plots for run ${runnum}" \
	--attach ${PLOTS_DIR}/summaryPlots_${runnum}_SBS_critical.pdf \
	--attach ${PLOTS_DIR}/summaryPlots_${runnum}_bb_gem.pdf \
	--attach ${PLOTS_DIR}/summaryPlots_${runnum}_bb_gem_basic.pdf \
	--attach ${PLOTS_DIR}/summaryPlots_${runnum}_BBGEM_ped_and_commonmode.pdf \
	--attach ${PLOTS_DIR}/summaryPlots_${runnum}_BBCal.pdf \
	--attach ${PLOTS_DIR}/summaryPlots_${runnum}_hcal.pdf \
	--attach ${PLOTS_DIR}/summaryPlots_${runnum}_grinch.pdf \
	--attach ${PLOTS_DIR}/summaryPlots_${runnum}_BBTH.pdf \
	--attach ${PLOTS_DIR}/summaryPlots_${runnum}_BBSpectro.pdf &&
    /adaqfs/apps/bin/logentry \
	--logbook "HALOG" \
	--tag Autolog \
	--title ${events}" SBS GEM replay plots for run ${runnum}" \
	--attach ${PLOTS_DIR}/summaryPlots_${runnum}_sbs_gem.pdf \
	--attach ${PLOTS_DIR}/summaryPlots_${runnum}_sbs_gem_basic.pdf \
	--attach ${PLOTS_DIR}/summaryPlots_${runnum}_SBSGEM_ped_and_commonmode.pdf
else
    yes_or_no "Upload these plots to logbook HALOG? " && \
	/adaqfs/apps/bin/logentry \
	--logbook "HALOG" \
	--tag Autolog \
	--title ${events}" replay plots for run ${runnum}" \
	--attach ${PLOTS_DIR}/summaryPlots_${runnum}_SBS_critical_noSBSGEMs.pdf \
	--attach ${PLOTS_DIR}/summaryPlots_${runnum}_bb_gem.pdf \
	--attach ${PLOTS_DIR}/summaryPlots_${runnum}_bb_gem_basic.pdf \
	--attach ${PLOTS_DIR}/summaryPlots_${runnum}_BBGEM_ped_and_commonmode.pdf \
	--attach ${PLOTS_DIR}/summaryPlots_${runnum}_BBCal.pdf \
	--attach ${PLOTS_DIR}/summaryPlots_${runnum}_hcal.pdf \
	--attach ${PLOTS_DIR}/summaryPlots_${runnum}_grinch.pdf \
	--attach ${PLOTS_DIR}/summaryPlots_${runnum}_BBTH.pdf \
	--attach ${PLOTS_DIR}/summaryPlots_${runnum}_BBSpectro.pdf
fi


    



