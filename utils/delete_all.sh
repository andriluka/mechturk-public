#!/usr/bin/env sh

. ./mturk_init.sh

# empty means not done, or not answer yet, only reject them when deleting the HITs
"$MTURK_CMD_HOME"/bin/invoke.sh DeleteHITs -successfile $OUR_DIR/$OUR_NAME.success -expire 


