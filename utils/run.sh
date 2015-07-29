#!/usr/bin/env sh

. ./mturk_init.sh

if [ -s "$SUCCESS_FILE" ]; then
    echo "Success file exists and is not empty, remove it before re-submitting the HITs in this dir";
else 
    exec "$MTURK_CMD_HOME"/bin/invoke.sh LoadHITs -label $OUR_DIR/$OUR_NAME -input $OUR_DIR/input -question $OUR_DIR/question -properties $OUR_DIR/properties
    touch $OUR_DIR/production_hit
fi
