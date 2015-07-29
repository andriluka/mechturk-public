import os
import sys

def main():
    """
    This file will checkout the empty file from the previous submission and have them relabeled.
    """
    input_file = sys.argv[1]
    assert 'input' in input_file
    old_dir = input_file.replace('-redo', '').replace('/input', '')
    while old_dir[-1] == '/':
        old_dir = old_dir[:-1]
    old_empty_file = old_dir + '/' + os.path.basename(old_dir) + '.empty'
    with open(old_empty_file) as fh:
        assignmentIDs = [line.split()[0] for line in fh.readlines()[1:]]

    old_results_file = old_empty_file.replace('.empty', '.results')
    with open(old_results_file) as fh:
        results = fh.readlines()

    inputs = ['urls\n']
    for aid in assignmentIDs:
        result = [result for result in results if aid in result]
        assert len(result) == 1
        result = result[0]
        input_line = [r.replace('"', '')+'\n' for r in result.split() if '.jpeg' in r][0]
        inputs.append(input_line)

    with open(input_file, 'w') as fh:
        fh.writelines(inputs)

if __name__ == '__main__':
    main()
