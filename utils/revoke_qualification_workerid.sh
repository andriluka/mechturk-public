#!/usr/bin/env sh

. ./mturk_init.sh

#QUALIFICATION_ID=2UC3NAB6BFMHBURPFUSTRFDGEZYUHJ
QUALIFICATION_ID=314S7VMDGP3NIAMXDQS8T75T2M4MJS

echo WORKER ID: ${1}

exec "$MTURK_CMD_HOME"/bin/revokeQualification.sh -qualtypeid $QUALIFICATION_ID -workerid ${1} -reason "annotation results did not pass the quality assurance test, sorry"; done;









