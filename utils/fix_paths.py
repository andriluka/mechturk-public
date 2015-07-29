import sys
import os
import mechturk.annolib as al
from mechturk.utils.set_bonus import get_worker_al_files

def main():
    al_files = [sys.argv[1]]
    hits_dir = '../hits/%s' % os.path.basename(al_files[0]).split('.')[0]
    al_files.extend(get_worker_al_files(hits_dir))
    for al_file in al_files:
        fix_paths(al_file)

def fix_paths(al_file):
    parse = al.parse(al_file)
    for p in parse:
        if len(p.imageName.split('/')) < 2 or len(p.imageName.split('/')[0]) == 0:
            inp = p.imageName.split('/')[-1]
            p.imageName = '_'.join(inp.split('_')[:-1]) + '/' + inp[:inp.find('.jpeg')+5]

    al.save(al_file, parse)


if __name__ == '__main__':
    main()
