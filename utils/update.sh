#!/usr/bin/env sh

. ./mturk_init.sh

"$MTURK_CMD_HOME"/bin/updateHITs.sh -success $OUR_DIR/$OUR_NAME.success -properties $OUR_DIR/properties



