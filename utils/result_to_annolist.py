#!/usr/bin/env python

import os
import collections

import AnnotationLib
import argparse
import csv
import subprocess
from generate_accept_reject import get_hit_name
import AnnoList_pb2

from bash_var_to_py import bash_var_to_py


def parse_boxes(results):
    rest = results.split(',')[2:]
    boxes = []
    for i in range(0, len(rest), 6):
        boxes.append(map(float, rest[i:i+4]))
    return boxes

def get_path_from_s3(s3url, url_prefix):
    if not s3url.startswith(url_prefix):
        print "mismatch in url prefix\n\ts3url: {}\n\turl prefix: {}".format(s3url, url_prefix)
        assert(False);

    #return '/'.join(s3url.split('/')[4:])
    res = s3url[len(url_prefix):]
    return res;
    
def annotation_from_result(result, columns, url_prefix):
    hit_type = result[columns['Answer.results']].split(',')[0];

    if hit_type == "label_act":
        return annotation_labelact_from_result(result, columns, url_prefix);
    elif hit_type == "label_cars":
        return annotation_labelbox_from_result(result, columns, url_prefix);
    elif hit_type == "":
        #print "empty result, workerid: ", result[columns['workerid']]
        return annotation_empty_from_result(result, columns, url_prefix);
    else:
        print "unknown hit type: {}, result: {}".format(hit_type, result[columns['Answer.results']])
        assert(False);

def merge_labelact_annolist(annolist):
    name_to_idx = {};
    res_annolist = AnnotationLib.AnnoList();


    for a in annolist:
        if a.imageName in name_to_idx:
            aidx = name_to_idx[a.imageName];
            res_annolist[aidx].rects.extend(a.rects);
        else:
            res_annolist.append(a);
            name_to_idx[a.imageName] = len(res_annolist) - 1;

    return res_annolist;


def annotation_empty_from_result(result, columns, url_prefix):
    annotation = AnnotationLib.Annotation()
    image_url = get_path_from_s3(result[columns['annotation']], url_prefix)

    # remove parameters from filename
    param_idx = image_url.index('&');    
    annotation.imageName = image_url[:param_idx];

    # MA: assume filenames don't contain ","
    cidx = annotation.imageName.find(',')
    if cidx >= 0:
        annotation.imageName = annotation.imageName[:cidx];

    assert(len(annotation.imageName) > 0);

    return annotation


ATTR_VAL_GENDER_MALE = 0;
ATTR_VAL_GENDER_FEMALE = 1;

ATTR_VAL_PTYPE_SALES = 0;
ATTR_VAL_PTYPE_CUST = 1;

ATTR_VAL_ACT_SALES_INT = 0;
ATTR_VAL_ACT_SALES_CLEAN = 1;
ATTR_VAL_ACT_SALES_OTHER = 2;

ATTR_VAL_ACT_CUST_QUEUE = 3;
ATTR_VAL_ACT_CUST_INT = 4;
ATTR_VAL_ACT_CUST_BROWSE = 5;
ATTR_VAL_ACT_CUST_OTHER = 6;

def annotation_labelact_from_result(result, columns, url_prefix):
    annotation = AnnotationLib.Annotation()
    image_url = get_path_from_s3(result[columns['annotation']], url_prefix)

    # remove parameters from filename
    param_idx = image_url.index('&');    

    image_url_split = image_url[:param_idx].split(',');
    assert(len(image_url_split) == 5);

    annotation.imageName = image_url_split[0];

    rect = AnnotationLib.AnnoRect();
    rect.x1 = int(image_url_split[1])
    rect.y1 = int(image_url_split[2])
    rect.x2 = int(image_url_split[3])
    rect.y2 = int(image_url_split[4])

    result_split = result[columns['Answer.results']].split(',');
    assert(len(result_split) == 1 + 1 + 4 + 4);

    # male/female
    gender_idx_to_val = {0: ATTR_VAL_GENDER_MALE, 1: ATTR_VAL_GENDER_FEMALE};
    ptype_idx_to_val = {0: ATTR_VAL_PTYPE_SALES, 1: ATTR_VAL_PTYPE_CUST};

    sales_act_idx_to_val = {0: ATTR_VAL_ACT_SALES_INT, 1: ATTR_VAL_ACT_SALES_CLEAN, 2: ATTR_VAL_ACT_SALES_OTHER};
    cust_act_idx_to_val = {0: ATTR_VAL_ACT_CUST_QUEUE, 1: ATTR_VAL_ACT_CUST_INT, 2: ATTR_VAL_ACT_CUST_BROWSE, 3: ATTR_VAL_ACT_CUST_OTHER};

    gender_idx = int(result_split[-4]);
    rect.at["gender"] = gender_idx_to_val[gender_idx];

    # sales/cust
    ptype_idx = int(result_split[-3]);
    rect.at["ptype"] = ptype_idx_to_val[ptype_idx];
    
    if ptype_idx == 0:
        # interact/clean/other
        act_idx = int(result_split[-2]);
        rect.at["act"] = sales_act_idx_to_val[act_idx];
    else:
        # queue/interact/browse/other
        act_idx = int(result_split[-1]);
        rect.at["act"] = cust_act_idx_to_val[act_idx];
    
    annotation.rects.append(rect);
    return annotation
    

def annotation_labelbox_from_result(result, columns, url_prefix):
    annotation = AnnotationLib.Annotation()
    image_url = get_path_from_s3(result[columns['annotation']], url_prefix)
    boxes = parse_boxes(result[columns['Answer.results']])
    for box in boxes:
        annotation.rects.append(AnnotationLib.AnnoRect(*box))

    # remove parameters from filename
    param_idx = image_url.index('&');    
    annotation.imageName = image_url[:param_idx];

    return annotation

def main():
    parser = argparse.ArgumentParser()

    parser.add_argument("hits_dir", help="hit directory")
    parser.add_argument("--print_empty", action="store_true", help="print info on empty hits");
    parser.add_argument("--save_worker_results", action="store_true", help="save results for each individual worker");

    #parser.add_argument("output_ext", default=".al", help="output format .idl/.al/.pal")
    #parser.add_argument("--url_prefix", help="path on S3 that should be removed when converting to annolist")   

    args = parser.parse_args()

    #url_prefix = bash_var_to_py("./data_utils_init.sh", "S3_HOST_DIR")
    url_prefix = bash_var_to_py(args.hits_dir + "/hit_params.sh", "S3_HOST_DIR")

    args.output_ext = ".pal"

    if url_prefix[-1] != os.sep:
        url_prefix += os.sep;
    
    hit_name = get_hit_name(args.hits_dir)
    #pal_name = args.hits_dir + '/' + hit_name + '.pal'
    pal_name = args.hits_dir + '/' + hit_name + args.output_ext

    results_filename = args.hits_dir + '/' + hit_name + '.results'
    results_by_worker_dir = '%s/results_by_worker_%s' % (args.hits_dir, hit_name)
    subprocess.call(['mkdir', '-p', results_by_worker_dir])
    try:
        with open(args.hits_dir + '/bad_workers.txt', 'r') as f:
            bad_workerids = set(x.strip() for x in f.readlines())
    except IOError:
        bad_workerids = set()

    with open(results_filename, 'r') as results_file:
        results_list = list(csv.reader(results_file, delimiter='\t'))
        invert = lambda d: {v:k for k,v in d.iteritems()}
        columns = invert(dict(enumerate(results_list[0])))

        annotation_list = AnnotationLib.AnnoList();
        hit_type = "";

        for each in results_list[1:]:
            if each[columns['hitstatus']] == 'Reviewable' and each[columns['workerid']] not in bad_workerids:
                cur_hit_type = each[columns['Answer.results']].split(',')[0];
                if not hit_type:
                    hit_type = cur_hit_type;
                else:
                    assert(hit_type == cur_hit_type);

                a = annotation_from_result(each, columns, url_prefix);
                annotation_list.append(a);

        # MA: some hit types require special post-processing
        if hit_type == "label_act":
            annotation_list = merge_labelact_annolist(annotation_list);
            annotation_list.add_attribute("gender", int);
            annotation_list.add_attribute("ptype", int);
            annotation_list.add_attribute("act", int);

            annotation_list.add_attribute_val("gender", "male", ATTR_VAL_GENDER_MALE);
            annotation_list.add_attribute_val("gender", "female", ATTR_VAL_GENDER_FEMALE);

            annotation_list.add_attribute_val("ptype", "sales", ATTR_VAL_PTYPE_SALES);
            annotation_list.add_attribute_val("ptype", "customer", ATTR_VAL_PTYPE_CUST);

            annotation_list.add_attribute_val("act", "interact_with_customer", ATTR_VAL_ACT_SALES_INT);
            annotation_list.add_attribute_val("act", "clean", ATTR_VAL_ACT_SALES_CLEAN);
            annotation_list.add_attribute_val("act", "other_sales", ATTR_VAL_ACT_SALES_OTHER);

            annotation_list.add_attribute_val("act", "queue", ATTR_VAL_ACT_CUST_QUEUE);
            annotation_list.add_attribute_val("act", "interact_with_sales", ATTR_VAL_ACT_CUST_INT);
            annotation_list.add_attribute_val("act", "browse", ATTR_VAL_ACT_CUST_BROWSE);
            annotation_list.add_attribute_val("act", "other_customer", ATTR_VAL_ACT_CUST_OTHER);


        AnnotationLib.save(pal_name, annotation_list)

        if args.save_worker_results:
            for workerid in set(x[columns['workerid']] for x in results_list[1:]):
                if workerid == '':
                    print '%s missing entries' % sum(1 for each in results_list[1:]
                                                     if each[columns['workerid']] == '')
                    continue

                annotation_list = AnnotationLib.AnnoList([annotation_from_result(each, columns, url_prefix)
                                                          for each in results_list[1:]
                                                          if each[columns['hitstatus']] == 'Reviewable'
                                                          and each[columns['workerid']] == workerid]);

                output_filename = '%s/%s.pal' % (results_by_worker_dir, workerid);
                #print "saving ", output_filename;

                print "worker: {}, number of annotations: {}".format(workerid, len(annotation_list));
                AnnotationLib.save(output_filename, annotation_list)

        if args.print_empty:
            for res in results_list[1:]:
                if res[columns['Answer.results']] == "":
                    print "empty hit: ", res

        # show statistics on empty results (happens due to unknown bug in javascript tool)
        empty_res_workers = [each[columns['workerid']] for each in results_list[1:] if each[columns['Answer.results']] == ""];

        print "empty output by workerid: " 
        for workerid, worker_empty_count in collections.Counter(empty_res_workers).items():
            print workerid, worker_empty_count

        num_empty = sum((1 for each in results_list[1:] if each[columns['Answer.results']] == ""));
        print "number of empty results: ", num_empty

            

if __name__ == '__main__':
    main()
