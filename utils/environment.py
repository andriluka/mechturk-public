import getpass

if getpass.getuser() == 'brodyh':
    proj = '/Users/brodyh/Documents/projects/mechturk'
    dropbox = '/Users/brodyh/Dropbox/projects/mechturk/errors/'
    trash = '/afs/cs.stanford.edu/u/brodyh/trash/'
    try:
        dropbox_access_token = open(proj + '/verification/dropbox_access_token.txt').readline().strip()
    except IOError:
        dropbox_access_token = None
    backup_verified = '/Users/brodyh/Dropbox/projects/mechturk/verified/'
    email_addr = 'brodyh@stanford.edu'

# global settings
extracted = '/scail/group/deeplearning/driving_data/andriluka/IMAGES/driving_data_q50_data/all_extracted/'
worker_records = proj + '/verification/worker_records.pkl'
workerid2name = proj + '/verification/workerid2name.pkl'
hits = proj + '/hits/'
amt_access_key = ''
amt_secret_key = ''
