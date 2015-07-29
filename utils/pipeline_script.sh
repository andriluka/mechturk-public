#!/bin/bash
set -x

# define the environment variables
export command=$1 # either {submit, get, pay}
export cams=2 #(2 4 5 6)
export cams_str=$(printf -- '%s,' "${cams[@]}" | py -x 'x[:-1]')
export newvideo=$2 #6-16-14-101
export newhits=../hits/$newvideo-cam$cams_str
export redo=true
export empty=true
export driving_folder=vw_data

if [ $redo = true ]; then
    export oldhits=$newhits
    export newhits=$newhits-redo
    export bad_worker=false
fi

reward=0.04
object_bonus=0.004
min_box_width=18

# update the data_utils_init script
python update_data_utils_init.py $newvideo 0 $object_bonus $min_box_width &&

if [ "$command" = submit ]; then
    # create HIT's directory
    mkdir -p $newhits &&
    # copy the properties & questions from any pre-existing folder
    cp ../hits/6-10-14-280/properties ../hits/6-10-14-280/question $newhits &&
    python create_hit_params.py $newhits/hit_params.sh $object_bonus $min_box_width
    python update_reward.py $newhits $reward &&

    # extract  all the data from videos and place them in inputs
    for cam in ${cams[*]}; do
    	if [ $cam -eq 5 ]; then
    	    img_step=5
    	elif [ $cam -eq 4 ]; then
    	    img_step=5
    	elif [ $cam -eq 6 ]; then
    	    img_step=5
    	elif [ $cam -eq 2 ]; then
    	    img_step=8
    	fi
    	# update the data_utils_init script
    	python update_data_utils_init.py $newvideo $img_step $object_bonus $min_box_width &&

    	if [ $redo != true ]; then
    	    # extract data from videos
    	    find /scail/group/deeplearning/driving_data/$driving_folder/$newvideo/ -maxdepth 1 -name "split_0*$cam.avi" | sort -n > /scail/group/deeplearning/driving_data/$driving_folder/$newvideo/$newvideo-cam$cam.txt &&
    	    ./extract_data.sh /scail/group/deeplearning/driving_data/$driving_folder/$newvideo/$newvideo-cam$cam.txt
    	fi
    	# create input
    	./mturk_make_input.sh $newhits /scail/group/deeplearning/driving_data/andriluka/IMAGES/driving_data_q50_data/all_extracted/$newvideo-*$cam
    	mv $newhits/input $newhits/input-cam$cam
    done

    python merge_inputs.py $newhits

    if [ $redo = true ]; then
    	if [ $bad_worker != false ]; then
    	    python redo_bad_worker.py -f $oldhits/results_by_worker_$(basename $oldhits)/$bad_worker.al -i $newhits/input
    	fi

	if [ $empty = true ]; then
	    python redo_input_from_empty.py $newhits/input
	else
    	    python label_input_with_boxes.py $newhits/input reset &&
    	    python label_input_with_boxes.py $newhits/input
	fi

    fi

    # copy data to S3 (later migrate to mtserve)
    for cam in ${cams[*]}; do
	if [ $cam -eq 5 ]; then
	    img_step=5
	elif [ $cam -eq 4 ]; then
	    img_step=5
	elif [ $cam -eq 6 ]; then
	    img_step=5
	elif [ $cam -eq 2 ]; then
	    img_step=8
	fi
	# update the data_utils_init script
	python update_data_utils_init.py $newvideo $img_step $object_bonus $min_box_width &&

	if [ $redo = true -a $empty = false ]; then
	    ./copy_data_s3.sh `find /scail/group/deeplearning/driving_data/andriluka/IMAGES/driving_data_q50_data/all_extracted -mindepth 1 -maxdepth 1 -name "$newvideo-*$cam" -type l`
	fi
    done

    # submit the job
    # ./run.sh $newhits

elif [ "$command" = get ]; then
    cam=$cams

    if [ -d $newhits/results_by_worker_$(basename $newhits) ]; then
	rm -r $newhits/results_by_worker_$(basename $newhits)
    fi

    # get the results
    ./get.sh $newhits &&

    cd ../matlab_utils/ &&
    echo "amt_process_cars('/afs/cs.stanford.edu/u/brodyh/scr/projects/mechturk/hits/`basename $newhits`/`basename $newhits`.results')" | matlab -nodesktop -nosplash &&
    cd -

    echo "Total amount labeled --- " $(python tot_count.py $newhits) / $(expr $(cat $newhits/input | wc -l) - 1)
    echo ""

    # print payments
    python set_bonus.py $newhits

    # add the frames with no cars back in
    if [ $cam -eq 5 ]; then
    	python add_no_car_frames.py /scail/group/deeplearning/driving_data/andriluka/IMAGES/driving_data_q50_data/all_extracted/$newvideo-cam$cam.al `find /scail/group/deeplearning/driving_data/andriluka/IMAGES/driving_data_q50_data/all_extracted -mindepth 1 -maxdepth 1 -name "$newvideo-*$cam" -type l`
    fi

    python fix_paths.py /scail/group/deeplearning/driving_data/andriluka/IMAGES/driving_data_q50_data/all_extracted/$(basename $newhits).al

elif [ "$command" = pay ]; then
    ./approve_reject.sh $newhits

    if [ $redo = true ]; then
	python merge_redo_files.py $newhits
	python label_input_with_boxes.py $newhits/input reset
    fi
fi
