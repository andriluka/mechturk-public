import sys

out_file = sys.argv[1]

with open(out_file, 'w') as fh:
    fh.write('#!/bin/bash\n\n')
    fh.write('OBJECT_BONUS_USD=%f\n' % float(sys.argv[2]))
    fh.write('MIN_BOX_WIDTH=%d\n' % int(sys.argv[3]))
