#!/usr/bin/env sh

. ./mturk_init.sh

exec "$MTURK_CMD_HOME"/bin/invoke.sh GetResults -successfile $OUR_DIR/$OUR_NAME.success -outputfile $OUR_DIR/$OUR_NAME.results
