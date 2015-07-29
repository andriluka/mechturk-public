import glob
import sys

def main():
    hits_dir = sys.argv[1]
    input_files = [inp for inp in glob.glob(hits_dir + '/input*') if '.txt' not in inp]
    inputs = ['urls\n']
    for input_file in input_files:
        with open(input_file) as fh:
            inputs.extend(fh.readlines()[1:])

    with open(hits_dir + '/input', 'w') as fh:
        fh.writelines(inputs)

if __name__ == '__main__':
    main()
