import sys
import os
import boto.mturk.connection as mtc
import mechturk.utils.environment as env

mt = mtc.MTurkConnection(env.amt_access_key, env.amt_secret_key)
hits_dir = sys.argv[1]
while hits_dir[-1] == '/':
    hits_dir = hits_dir[:-1]
with open(hits_dir + '/' + os.path.basename(hits_dir) + '.success') as fh:
    hits = [line.split()[0] for line in fh.readlines()[1:]]

for hit in hits:
    mt.expire_hit(hit)
