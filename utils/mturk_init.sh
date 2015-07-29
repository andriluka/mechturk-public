#!/bin/bash

#export JAVA_HOME=/usr/lib/jvm/java-6-openjdk-amd64/jre/
export JAVA_HOME=/usr

#export MTURK_CMD_HOME=/afs/cs.stanford.edu/u/andriluka/code/mechturk/mturk

export MTURK_CMD_HOME=$(readlink -f ../mturk)
export PATH=$MTURK_CMD_HOME/bin:$PATH

BATCH_ABS_PATH=`cd "$1"; pwd`
OUR_DIR=$BATCH_ABS_PATH
OUR_NAME=`basename $OUR_DIR`
SUCCESS_FILE=${OUR_DIR}/${OUR_NAME}.success

echo BATCH_PATH: $BATCH_ABS_PATH
echo OUR_DIR: $OUR_DIR
echo OUR_NAME: $OUR_NAME
echo "SUCCESS_FILE: "$SUCCESS_FILE;
