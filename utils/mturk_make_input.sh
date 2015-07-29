#
# mturk_make_input.sh <HIT_DIR>
# or
# mturk_make_input.sh <HIT_DIR> <IMG_DIR1> <IMG_DIR2> ... <IMG_DIR_N>
#

source `dirname $0`/data_utils_init.sh

HIT_DIR=$1
HIT_NAME=`basename $HIT_DIR`

if [ ! -d "${HIT_DIR}" ]; then
    # MA: some parmeters are now in ${HIT_DIR}/hit_params.sh -> HIT_DIR must exist 
    #mkdir -p $HIT_DIR
    
    echo "${HIT_DIR} does not exist, exiting...";
    exit;
fi

HIT_PARAMS_FILENAME=${HIT_DIR}/hit_params.sh
if [ ! -e "${HIT_PARAMS_FILENAME}" ]; then
    echo "${HIT_PARAMS_FILENAME} does not exist, exitting...";
    exit;
fi

# MA: load hit-specific parameters, currently: bonus and minimal vehicle size
source ${HIT_PARAMS_FILENAME};

if (( $# < 2 )); then
    IMG_DIR[1]="${IMG_DIR_BASE}/${HIT_NAME}";
else
    NARGS=$#
    for i in `seq 2 $NARGS`; do
	IMG_DIR[$((i-1))]=${!i};
    done
fi

echo "HIT_DIR: $HIT_DIR"

rm -f ${HIT_DIR}/input_imgdir.txt

echo "saving results to $HIT_DIR/input"
rm -f ${HIT_DIR}/input
echo "urls" > ${HIT_DIR}/input

TOTALN=0;
for CUR_DIR in "${IMG_DIR[@]}"; do
    if [ -d $CUR_DIR ]; then
	CUR_DIR_1=`basename $CUR_DIR`;
	echo "CUR_DIR: $CUR_DIR"
	echo "CUR_DIR_1: $CUR_DIR_1"

	echo "$CUR_DIR" >> ${HIT_DIR}/input_imgdir.txt

	# for fname in `find -L $CUR_DIR -name "*jpeg" -printf "${S3_HOST_DIR}/${CUR_DIR_1}/%f\n" | sort -n`; do
     	#     echo $fname >> ${HIT_DIR}/input
	# done

	N=0;

	# reset image size (assume all images in the same directory have same size)
	IMGSIZE="";

	for fname in `find -L $CUR_DIR -maxdepth 1 \( -name "*png" -or -name "*jpeg" -or -name "*jpg" \) -printf "%f\n" | sort -n`; do

	    s3fname="${S3_HOST_DIR}/${CUR_DIR_1}/"${fname};

	    # MA: removed redundant parts from the address (needed to shorten url to fit into 255 characters)
	    #s3fname=${fname};

	    MOD_VAL=$(($N % $IMG_STEP));

	    if [ -z "$IMGSIZE" ]; then
		IMGSIZE=`identify -format "%w %h" ${CUR_DIR}/${fname}`;
		IMGWIDTH=`echo $IMGSIZE | cut -d' ' -f1`;
		IMGHEIGHT=`echo $IMGSIZE | cut -d' ' -f2`;
		echo "${CUR_DIR}, image size: "$IMGWIDTH"x"$IMGHEIGHT;
	    fi

     	    if [ "$MOD_VAL" -eq 0 ]; then
		if [ ! -d "$CUR_DIR/with_cars" -o -f "$CUR_DIR/with_cars/`basename $fname`" ]; then
		    #echo $s3fname"&imgwidth="${IMGWIDTH}"&imgheight="${IMGHEIGHT}"&object_bonus_usd="${OBJECT_BONUS_USD}"&min_box_width="${MIN_BOX_WIDTH}"" >> ${HIT_DIR}/input
		    #echo $s3fname >> ${HIT_DIR}/input

		    echo $s3fname"&imgwidth="${IMGWIDTH}"&imgheight="${IMGHEIGHT}"&ob="${OBJECT_BONUS_USD}"&mw="${MIN_BOX_WIDTH}"" >> ${HIT_DIR}/input
		    TOTALN=$(($TOTALN + 1));
		else
		    echo "`basename $fname` has no cars in it, skipping..."
		fi
	    fi
	    N=$(($N + 1));
	done

    else
	echo "error: $CUR_DIR does not exist or is not a directory";
	exit;
    fi
done

echo "total images: $TOTALN"
