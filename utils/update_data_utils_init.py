import sys

fname = './data_utils_init.sh'

with open(fname) as fh:
    lines = fh.readlines()

for idx, l in enumerate(lines):
    if l.find('#VIDEO_DIR') == -1 and l.find('VIDEO_DIR=/') != -1:
        lines[idx] = 'VIDEO_DIR=/scail/group/deeplearning/driving_data/q50_data/%s\n' % sys.argv[1]
    elif l.find('export IMG_STEP') != -1:
        lines[idx] = 'export IMG_STEP=%d\n' % int(sys.argv[2])
    elif l.find('OBJECT_BONUS_USD=') != -1:
        lines[idx] = 'OBJECT_BONUS_USD=%s\n' % sys.argv[3]
    elif l.find('MIN_BOX_WIDTH=') != -1:
        lines[idx] = 'MIN_BOX_WIDTH=%s\n' % sys.argv[4]

with open(fname, 'w') as fh:
    fh.writelines(lines)
