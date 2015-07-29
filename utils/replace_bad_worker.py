from optparse import OptionParser
import mechturk.annolib as al

def main():
    """
    This will update a bad al file with a good one, and will overwrite the bad file with the updated images.
    """
    parser = OptionParser()
    parser.add_option('-b', '--bad', dest='bad_file', type='string')
    parser.add_option('-g', '--good', dest='good_file', type='string')
    (opts, _) = parser.parse_args()

    bad = al.parse(opts.bad_file)
    good = al.parse(opts.good_file)

    name2anno = {}
    for g in good:
        name2anno[g.imageName] = g

    fixed = []
    for b in bad:
        fixed.append(name2anno.get(b.imageName, b))

    al.save(opts.bad_file, fixed)


if __name__ == '__main__':
    main()
