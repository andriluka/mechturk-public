import sys
import os
import shutil
import mechturk.utils.label_input_with_boxes as liwb
import mechturk.utils.environment as env
import mechturk.annolib as al


def main():
    hits_dir = sys.argv[1]
    old_anno_file = liwb.get_old_anno(hits_dir)
    new_anno_file = old_anno_file.replace('.al', '-redo-verified.al')

    old_annos = al.parse(old_anno_file)
    new_annos = al.parse(new_anno_file)

    old_name2anno = {p.imageName: p for p in old_annos}
    for na in new_annos:
        if na.imageName not in old_name2anno:
            print "old anno %s doesn't have %s, skipping..." % (os.path.basename(old_anno_file), na.imageName)
            continue
        na.rects.extend(old_name2anno[na.imageName].rects)

    al.saveXML(old_anno_file.replace('.al', '-verified.al'), new_annos)
    #shutil.move(old_anno_file, env.trash + os.path.basename(old_anno_file))
    shutil.move(new_anno_file, env.trash + os.path.basename(new_anno_file))


if __name__ == '__main__':
    main()
