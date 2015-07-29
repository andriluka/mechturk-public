#!/usr/bin/env sh

. ./mturk_init.sh

# general MPII qualificatin for pose estimation
#QUALIFICATION_ID=2UC3NAB6BFMHBURPFUSTRFDGEZYUHJ

# video labeling (Kristina)
#QUALIFICATION_ID=314S7VMDGP3NIAMXDQS8T75T2M4MJS

# video labeling (WIlliam)
#QUALIFICATION_ID=39D9NJEN74WONALUCXQKY42KGIYDHQ

# video labeling (Steve)
#QUALIFICATION_ID=3UMO2T1VLA2YFR7HGALAIDZLS4LODY

# video labeling (Stephanie)
#QUALIFICATION_ID=3EM95XO6DDJDR8WW5K75WUDDAWMGML

echo WORKER ID: ${1}
exec "$MTURK_CMD_HOME"/bin/assignQualification.sh -qualtypeid $QUALIFICATION_ID -workerid ${1}






