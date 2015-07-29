import sys, os, subprocess;
import argparse;
from collections import namedtuple;
from PIL import Image;

import AnnotationLib as al;

# short string from number  
def url_num2str(num):

    # this has to be the same as in ma_static_test2.js
    chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
    alpha_len = len(chars);

    a1 = int(num / alpha_len);
    assert(a1 <= alpha_len);

    a2 = num % alpha_len;
    
    return chars[a1] + chars[a2];

if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument("hit_dir", help="hit directory for storing mturk related data (eg. hit id's and worker results)");
    parser.add_argument("annolist_filename", help="annotation list in idl/al/pal format, object bounding boxes in the annotation list will be pre-loaded to mturk");

    parser.add_argument("--empty_only", action="store_true", help="only add images without annotations");
    
    args = parser.parse_args()

    print "hit_dir: ", args.hit_dir;
    print "annolist_filename: ", args.annolist_filename;

    annolist = al.parse(args.annolist_filename);

    print "generating hits for {0} images".format(len(annolist));
    
    # load hit-specific parameters
    if not os.path.isdir(args.hit_dir):
        print args.hit_dir, "does not exist, exiting...";
        sys.exit();
    else:
        hit_params_filename = args.hit_dir + "/hit_params.sh";

        print "loading hit parameters from: ", hit_params_filename;

        if not os.path.isfile(hit_params_filename):
            print hit_params_filename, "does not exist, exiting...";
            sys.exit();
        else:
            str_min_box_width = subprocess.check_output(["bash", "-c", "source " + hit_params_filename + "; echo  $MIN_BOX_WIDTH"]);
            min_box_width = int(str_min_box_width[:-1]);
            
            str_object_bonus_usd = subprocess.check_output(["bash", "-c", "source " + hit_params_filename + "; echo  $OBJECT_BONUS_USD"]);
            object_bonus_usd = float(str_object_bonus_usd[:-1]);

            s3_host_dir = subprocess.check_output(["bash", "-c", "source " + hit_params_filename + "; echo  $S3_HOST_DIR"]);
            s3_host_dir = s3_host_dir[:-1];

    print "min_box_width: ", min_box_width;
    print "object_bonus_usd: ", object_bonus_usd;
    print "s3_host_dir: ", s3_host_dir;

    input_filename = args.hit_dir + "/input";
    print "generating hits input:", input_filename;

    input_file = open(input_filename, "w");
    input_file.write("urls\n");

    img_dims = {};
    ImageSize = namedtuple("ImageSize", ["width", "height"])

    num_skipped_not_empty = 0;
    num_generated = 0;

    for aidx in xrange(0, len(annolist)):
        (imgdir, imgname) = os.path.split(annolist[aidx].imageName);
        assert(imgname);
        assert(imgdir);

        if args.empty_only and len(annolist[aidx].rects) > 0:
            num_skipped_not_empty += 1;
            continue;

        (imgdir2, parent_dir) = os.path.split(imgdir);
        assert(parent_dir);

        # assume all images in the same dir have same dimensions (this has been true so far)
        if not imgdir in img_dims:
            abs_img_name = annolist[aidx].imageName;

            # image name can be relative to location of annotation file
            if not os.path.isabs(abs_img_name):
                (aldir, alname) = os.path.split(args.annolist_filename);
                abs_img_name = aldir + "/" + abs_img_name;

            im = Image.open(abs_img_name)
            img_dims[imgdir] = ImageSize(width=im.size[0], height=im.size[1]);         

        #mturk_input_string = "{}/{}/{}&imgwidth={}&imgheight={}&object_bonus_usd={}&min_box_width={}".format(s3_host_dir, parent_dir, imgname, img_dims[imgdir].width, img_dims[imgdir].height, object_bonus_usd, min_box_width);

        mturk_input_string = s3_host_dir + "/" + parent_dir + "/" + imgname;
        
        # MA: do not transmit s3 directory, currently it is HARDCODED in ma_static_test2.js in job.frameurl = ...
        # this is because input url is limited to 255 characters and we now need space to 
        # transmit locations of preloaded bounding boxes

        # MA: also assume that parent directory can be derived from filename
        # mturk_input_string = parent_dir + "/" + imgname;

        # MA: ? 
        #mturk_input_string = imgname;

        mturk_input_string += "&imgwidth=" + str(img_dims[imgdir].width) + "&imgheight=" + str(img_dims[imgdir].height);
        #mturk_input_string += "&object_bonus_usd=" + str(object_bonus_usd);
        #mturk_input_string += "&min_box_width=" + str(min_box_width);

        mturk_input_string += "&ob=" + str(object_bonus_usd);
        mturk_input_string += "&mw=" + str(min_box_width);

        if annolist[aidx].rects:
            mturk_input_string += "&r=";
            for (ridx, r) in enumerate(annolist[aidx].rects):
                # if ridx > 0:
                #     mturk_input_string += ",";
                #mturk_input_string += str(int(r.x1)) + "," + str(int(r.y1)) + "," + str(int(r.x2)) + "," + str(int(r.y2));
                mturk_input_string += url_num2str(int(r.x1)) + url_num2str(int(r.y1)) + url_num2str(int(r.x2)) + url_num2str(int(r.y2));
        

        if len(mturk_input_string) >= 255:
            print "warning, input string longer than 255 characters, hit might fail to upload";

        input_file.write(mturk_input_string + "\n");
        num_generated += 1;

    input_file.close();
        
    print "num_skipped (not empty): ", num_skipped_not_empty
    print "num_generated: ", num_generated

    preload_params_filename = args.hit_dir + "/preload_params.sh";
    print "storing preload annolist name in", preload_params_filename;
    preload_params = open(preload_params_filename, "w");
    preload_params.write("PRELOAD_ANNOLIST={0}".format(os.path.abspath(args.annolist_filename)));
    preload_params.close()
        

    

