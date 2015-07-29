#!/usr/bin/env sh

. ./mturk_init.sh

# sandbox
exec "$MTURK_CMD_HOME"/bin/invoke.sh GetResults -sandbox -successfile $OUR_DIR/$OUR_NAME.success -outputfile $OUR_DIR/$OUR_NAME.results
