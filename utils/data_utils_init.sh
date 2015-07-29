#!/bin/bash

#location on the S3 server
#S3_DIR=sv-images/driving_data_twangcat
#S3_DIR=sv-images/driving_data_sameep
#S3_DIR=sv-images/driving_data_q50_data
#S3_DIR=andriluka/angelcam

# MA: used by s3copy, other scripts use the value from hit_params.sh 
S3_DIR=andriluka/sail-camstore 
S3_HOST_DIR=https://s3.amazonaws.com/$S3_DIR

# path to videos
#VIDEO_DIR=/afs/cs.stanford.edu/u/andriluka/mount/scail_group/deeplearning/driving_data/twangcat/raw_data_backup
#VIDEO_DIR=/afs/cs.stanford.edu/u/andriluka/mount/scail_group_deeplearning/driving_data/sameep
#VIDEO_DIR=/afs/cs.stanford.edu/u/andriluka/mount/scail_group_deeplearning/driving_data/q50_data
VIDEO_DIR=/scail/group/deeplearning/driving_data/q50_data/LV

# path to images
#EXTRACT_DIR=/local/IMAGES/driving_data_twangcat/
#EXTRACT_DIR=/local/IMAGES/driving_data_sameep
#EXTRACT_DIR=/local/IMAGES/driving_data_q50_data
EXTRACT_DIR=/scail/group/deeplearning/driving_data/andriluka/IMAGES/driving_data_q50_data

IMG_DIR_BASE=$EXTRACT_DIR/all_extracted;

# step to use when copying images to S3 and creating HITs
#IMG_STEP=50;
#IMG_STEP=20;
#export IMG_STEP=0
IMG_STEP=1;

# resize factor for wide FOV images
RESCALE_FACTOR=60;
RESCALE_WIDTH=1280;

# how much bonus we pay per labeled vehicle
OBJECT_BONUS_USD=0.0125
# 0.01

# minimal width of bounding box, smaller boxes don't get bonus
MIN_BOX_WIDTH=18
# 25
