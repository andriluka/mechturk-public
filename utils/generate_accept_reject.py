import sys
import argparse
import subprocess
import os
import csv
from itertools import groupby

from bash_var_to_py import bash_var_to_py;

def get_hit_name(directory):
    dnull = open(os.devnull, 'w')
    hit_name = subprocess.check_output(['readlink', '-f', directory], stderr=dnull).split('/')[-1].strip() 
    return hit_name

def main():
    from result_to_annolist import parse_boxes

    parser = argparse.ArgumentParser()
    parser.add_argument("hits_dir")

    args = parser.parse_args()

    hit_name = get_hit_name(args.hits_dir)
    object_bonus_usd = float(bash_var_to_py(args.hits_dir + "/hit_params.sh", "OBJECT_BONUS_USD"));
    
    print "\nOBJECT_BONUS_USD: {}\n\n".format(object_bonus_usd);

    results_filename = args.hits_dir + '/' + hit_name + '.results'
    accept_filename = args.hits_dir + '/' + hit_name + '.accept'
    reject_filename = args.hits_dir + '/' + hit_name + '.reject'
    bonus_filename = args.hits_dir + '/' + hit_name + '-grant-bonus.sh'
    bonus_log_filename = hit_name + '-grant-bonus.log'
    with open(results_filename, 'r') as results_file:
        results_list = csv.reader(results_file, delimiter='\t')
        invert = lambda d: {v:k for k,v in d.iteritems()}
        columns = invert(dict(enumerate(next(results_list))))

        with open(accept_filename, 'w') as accept_file:
            accept_file.write('assignmentIdToApprove\tassignmentIdToApproveComment\n')
            counter = 0
            for x in results_list:
                assignmentid = x[columns['assignmentid']]
                if assignmentid:
                    accept_file.write('%s\t"thank you for your work"\n' % assignmentid)
                else:
                    counter += 1
            if counter > 0:
                sys.stderr.write('WARNING: %s assignments not yet completed\n' % counter)
            print('created %s' % accept_filename)
        with open(reject_filename, 'w') as reject_file:
            reject_file.write('assignmentIdToReject\tassignmentIdToRejectComment\n')
            print('created %s' % reject_filename)

    with open(results_filename, 'r') as results_file:
        results_list = csv.reader(results_file, delimiter='\t')
        invert = lambda d: {v:k for k,v in d.iteritems()}
        columns = invert(dict(enumerate(next(results_list))))

        if object_bonus_usd > 1: 
            with open(bonus_filename, 'w') as bonus_file:
                wid = lambda x: x[columns['workerid']]
                for k, v in groupby(sorted(results_list, key=wid), key=wid):
                    num_people = 0
                    for x in v:
                        assignmentid = x[columns['assignmentid']]
                        workerid = x[columns['workerid']]
                        #num_people = int(x[columns['numcomplete']])
                        num_people += len(parse_boxes(x[columns['Answer.results']]))
                    if assignmentid and workerid and num_people > 0:
                        bonus_per_person = 0.0125
                        bonus_params = {
                            'assignmentid': assignmentid,
                            'amount': num_people * bonus_per_person,
                            'workerid': workerid,
                            'num_people': num_people,
                            'bonus_per_person': bonus_per_person,
                            'bonus_log_filename': bonus_log_filename,
                        }
                        bonus_file.write('''"$MTURK_CMD_HOME"/bin/grantBonus.sh --workerid %(workerid)s --amount %(amount)0.2f --assignment %(assignmentid)s --reason "labeled people: %(num_people)d, bonus per person: %(bonus_per_person)0.4f"
    echo "%(workerid)s,%(assignmentid)s" >> %(bonus_log_filename)s
    ''' % bonus_params)

                print('created %s' % bonus_filename)


if __name__ == '__main__':
    main()
