import mechturk.annolib as al
import glob
import sys
import os

tot_len = 0
hits_dir = sys.argv[1]
while hits_dir[-1] == '/':
    hits_dir = hits_dir[:-1]
files = glob.glob('%s/results_by_worker_%s/*al' % (hits_dir, os.path.basename(hits_dir)))
for f in files:
    tot_len += len(al.parse(f))

print tot_len
