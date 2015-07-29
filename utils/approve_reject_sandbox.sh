#!/usr/bin/env sh

. ./mturk_init.sh

"$MTURK_CMD_HOME"/bin/approveWork.sh -sandbox -approvefile $OUR_DIR/$OUR_NAME.accept

"$MTURK_CMD_HOME"/bin/rejectWork.sh -sandbox -rejectfile $OUR_DIR/$OUR_NAME.reject

# don't reject empty, check them and them run amt_process_noeval.m
#"$MTURK_CMD_HOME"/bin/rejectWork.sh -rejectfile $OUR_DIR/$OUR_NAME.empty

BONUS_FILE="${OUR_DIR}/${OUR_NAME}-grant-bonus.sh"
echo BONUS_FILE: ${BONUS_FILE}

if [ -e $BONUS_FILE ]; then
    echo
    echo "Granting bonus to workers, press a key to continue or Ctrl+C to abort."
    echo "Note: rerun ***amt_process_cars.m*** if process is interrupted before completion.";
    bash -c "read -n1 -s"

    # MA: we are in sh here, not in bash
    #source $BONUS_FILE

    . $BONUS_FILE
    mv ${BONUS_FILE} "${BONUS_FILE}-paid"
else
    echo
    echo "INFO: no bonus file found (bonus already paid or taks without bonus)";
fi