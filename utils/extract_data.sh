#!/bin/bash
source `dirname $0`/data_utils_init.sh

if (( $# < 1 )); then
    echo "usage: extract_data.sh <FILE_WITH_LIST_OF_VIDEOS>"
    exit;
fi

VIDEOLIST=$1
echo "VIDEOLIST: $VIDEOLIST"

for VIDNAME in `cat $VIDEOLIST`; do

    if [[ "$VIDNAME" = /* ]]; then
    	VIDFILE=$VIDNAME
    else
    	VIDFILE=$VIDEO_DIR/$VIDNAME;
    fi

    if [[ $VIDNAME == \#* ]]; then
	continue;
    fi

    if [ ! -e $VIDFILE ]; then
	echo "error: $VIDFILE not found";
	exit;
    else
	echo "VIDFILE: $VIDFILE";
    fi

    if [[ $VIDNAME == *.avi ]]; then
	IMGNAME1=`basename $VIDNAME .avi`;
	IMGPATH=`dirname $VIDNAME`;
	IMGNAME2=`basename $IMGPATH`;
	IMGPATH=`dirname $IMGPATH`;

	# twantcat
	#IMGNAME3=`basename $IMGPATH`;
	#BASENAME=$IMGNAME3-$IMGNAME2-$IMGNAME1;
	#CURDIR=$EXTRACT_DIR/$IMGNAME3/$IMGNAME2/$BASENAME;

	# q50-data
	BASENAME=$IMGNAME2-$IMGNAME1;
	CURDIR=$EXTRACT_DIR/$IMGNAME2/$BASENAME;

	echo extracting to: $CURDIR;
	mkdir -p $CURDIR;

	echo "Removing old jpegs..."
	/bin/rm $CURDIR/$BASENAME*.jpeg
	echo "Done removing old jpegs..."
	mkdir /tmp/extracted_video
	# save to local disk then rsync with limit set to save scail
	ffmpeg -i $VIDFILE -qscale 3 /tmp/extracted_video/${BASENAME}_%06d.jpeg
	rsync --progress --bwlimit=5000 -h -r /tmp/extracted_video/. $CURDIR/
	rm -r /tmp/extracted_video


	IMGSIZE="";
	NUM_RESIZED=0;
	for fname in `find $CURDIR -name "${BASENAME}_*jpeg"`; do
	    if [ -z "$IMGSIZE" ]; then
		IMGSIZE=`identify -format "%w %h" ${fname}`;
		IMGWIDTH=`echo $IMGSIZE | cut -d' ' -f1`;
		IMGHEIGHT=`echo $IMGSIZE | cut -d' ' -f2`;
 		echo "${CURDIR}, image size: "$IMGWIDTH"x"$IMGHEIGHT;
	    fi

	    if ((IMGWIDTH > RESCALE_WIDTH)); then
		resized_fname="${CURDIR}/"`basename $fname .jpeg`"_resize${RESCALE_FACTOR}.jpeg";
		convert $fname -resize ${RESCALE_FACTOR}"%" $resized_fname;
		#/bin/rm $fname;
		mv $resized_fname $fname;
		NUM_RESIZED=$(($NUM_RESIZED + 1));
	    fi
	done

	echo "resize images: "$NUM_RESIZED;

	# make a link in flat hierarchy for easier viewing/copying to S3
	mkdir -p $EXTRACT_DIR/all_extracted
	#ln -s $CURDIR $EXTRACT_DIR/all_extracted/

	# make a relative link (need link that works after copying to the scail filesystem)
	#ln -s ../$IMGNAME3/$IMGNAME2/$BASENAME $EXTRACT_DIR/all_extracted/$BASENAME
	rm $EXTRACT_DIR/all_extracted/$BASENAME
	ln -s ../$IMGNAME2/$BASENAME $EXTRACT_DIR/all_extracted/$BASENAME
    fi

done
