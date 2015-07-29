from optparse import OptionParser
import mechturk.annolib as al

def main():
    """
    This modifies the input file in the new hits directory to only have hits from the bad worker
    """
    parser = OptionParser()
    parser.add_option('-f', '--al-file', dest='al_file', type='string', default=None,
                      help="al file from bad worker to resubmit")
    parser.add_option('-i', '--input-file', dest='input_file', type='string', default=None,
                      help="input file in new hits directory to be resubmitted")
    (opts, args) = parser.parse_args()
    assert opts.al_file is not None and opts.input_file is not None

    parse = al.parse(opts.al_file)
    images = []
    for p in parse:
        images.append(p.imageName)

    with open(opts.input_file) as fh:
        lines = fh.readlines()

    new_lines = ['urls\n']
    for line in lines:
        for image in images:
            if line.find(image) != -1:
                new_lines.append(line)
                break

    with open(opts.input_file, 'w') as fh:
        fh.writelines(new_lines)


if __name__ == '__main__':
    main()
