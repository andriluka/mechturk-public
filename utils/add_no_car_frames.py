import mechturk.annolib as al
import os
import sys
import glob
import subprocess

def main():
    source_file('data_utils_init.sh')
    img_step = int(os.environ['IMG_STEP'])

    al_file = sys.argv[1]
    annos = al.parse(al_file)
    img_dirs = sorted(sys.argv[2:])
    images = []
    for img_dir in img_dirs:
        images.extend(sorted(glob.glob(img_dir + '/*jpeg'))[::img_step])

    new_annos = []
    anno_idx = 0
    for image in images:
        image_name = u'/'.join(image.split('/')[-2:])
        if anno_idx == len(annos) or image_name != annos[anno_idx].imageName:
            new_anno = al.Annotation()
            new_anno.imageName = image_name
        else:
            new_anno = annos[anno_idx]
            anno_idx += 1
        new_annos.append(new_anno)

    assert anno_idx == len(annos)
    al.save(sys.argv[1].replace('.al', '.pal'), new_annos)
    if sys.argv[1].find('.al') != -1:
        os.remove(sys.argv[1])

def source_file(fname):
    command = ['bash', '-c', 'source %s && env' % fname]
    proc = subprocess.Popen(command, stdout = subprocess.PIPE)
    for line in proc.stdout:
        (key, _, value) = line.partition("=")
        os.environ[key] = value
    proc.communicate()

if __name__ == '__main__':
    main()
