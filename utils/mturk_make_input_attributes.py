import sys, os, subprocess;
import argparse;
from collections import namedtuple;
from PIL import Image;

import AnnotationLib as al;

if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument("hit_dir", help="hit directory for storing mturk related data (eg. hit id's and worker results)");
    parser.add_argument("annolist_filename", help="annotation list in idl/al/pal format, object bounding boxes in the annotation list will be pre-loaded to mturk");
    
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

    for aidx in xrange(0, len(annolist)):
        (imgdir, imgname) = os.path.split(annolist[aidx].imageName);
        assert(imgname);
        assert(imgdir);

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

        # MA: also assume that parent directory can be derived from filename
        mturk_input_string_base = s3_host_dir + "/" + parent_dir + "/" + imgname;
        mturk_input_string_params = "&imgwidth=" + str(img_dims[imgdir].width) + "&imgheight=" + str(img_dims[imgdir].height);

        img_width = img_dims[imgdir].width;
        img_height = img_dims[imgdir].height;

        for r in annolist[aidx].rects:
            mturk_input_string = mturk_input_string_base;

            # MA: turns out sometimes boxes in annolist have negative coordinates -> result of mturk (?)
            x1 = max(1, min(int(r.x1), img_width - 1));
            x2 = max(1, min(int(r.x2), img_width - 1));

            y1 = max(1, min(int(r.y1), img_height - 1));
            y2 = max(1, min(int(r.y2), img_height - 1));
            
            assert(x1 > 0 and x2 > 0 and y1 > 0 and y2 > 0);

            mturk_input_string += "," + str(x1) + "," + str(y1) + "," + str(x2) + "," + str(y2)  
            mturk_input_string += mturk_input_string_params;

            if len(mturk_input_string) >= 255:
                print "warning, input string longer than 255 characters, hit might fail to upload";

            input_file.write(mturk_input_string + "\n");

    input_file.close();
        
    preload_params_filename = args.hit_dir + "/preload_params.sh";
    print "storing preload annolist name in", preload_params_filename;
    preload_params = open(preload_params_filename, "w");
    preload_params.write("PRELOAD_ANNOLIST={0}\n".format(os.path.abspath(args.annolist_filename)));
    preload_params.close()
        

    

