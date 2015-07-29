import sys
import os
import mechturk.annolib as al
import mechturk.utils.environment as env
import cv2


def main():
    """
    This will block out the previously labeled cars so resources are not spent relabeling them.
    """
    input_file = sys.argv[1]
    reset = len(sys.argv) > 2 and sys.argv[2] == 'reset'
    assert '-redo' in input_file
    with open(input_file) as fh:
        inputs = fh.readlines()[1:]

    if 'driving_data' in inputs[0]:
        amt2local = lambda inp: env.extracted + '/'.join(inp[inp.find('driving_data'):inp.find('.jpeg')+5].split('/')[1:])
    else:
        amt2local = lambda inp: env.extracted + '_'.join(inp.split('_')[:-1]) + '/' + inp[:inp.find('.jpeg')+5]
    images = [amt2local(inp) for inp in inputs]
    name2anno = find_previous_annos(os.path.dirname(input_file))
    local2anno = lambda image: u'/'.join(image.split('/')[-2:])

    for image in images:
        image_hidden = image.replace('.jpeg', '.hidden')
        if reset:
            if os.path.exists(image_hidden):
                os.rename(image_hidden, image)
        else:
            anno = name2anno[local2anno(image)]
            img = cv2.imread(image)
            draw_anno(img, anno)
            assert not os.path.exists(image_hidden)
            os.rename(image, image_hidden)
            cv2.imwrite(image, img)


def find_previous_annos(hits_dir):
    old_al = get_old_anno(hits_dir)
    name2anno = {p.imageName: p for p in  al.parse(old_al)}
    return name2anno


def get_old_anno(hits_dir):
    old_al = env.extracted + os.path.basename(hits_dir[:hits_dir.rfind('-redo')]) + '.al'
    return old_al


def draw_anno(img, anno):
    #color = (0, 255, 0)
    color = (44, 44, 44)
    pixel_thickness = cv2.cv.CV_FILLED
    for rect in anno.rects:
        top_left = (int(rect.x1), int(rect.y1))
        bottom_right = (int(rect.x2), int(rect.y2))
        cv2.rectangle(img, top_left, bottom_right, color, pixel_thickness)


if __name__ == '__main__':
    main()
