import sys

fname = sys.argv[1] + '/properties'

with open(fname) as fh:
    lines = fh.readlines()

for idx, l in enumerate(lines):
    if l.find('reward:') != -1:
        lines[idx] = 'reward:%s\n' % sys.argv[2]

with open(fname,'w') as fh:
    fh.writelines(lines)
