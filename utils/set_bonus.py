import sys
import os
import glob
import numpy as np
import mechturk.annolib as al

def main():
    hits_dir = sys.argv[1]
    while hits_dir[-1] == '/':
        hits_dir = hits_dir[:-1]
    vid = os.path.basename(hits_dir)
    base_pay = get_base_pay(hits_dir)
    # get total images
    id2work = {}
    total_num_images = 0
    al_files = get_worker_al_files(hits_dir)

    for f in al_files:
        workerid = os.path.basename(f).split('_')[1].split('.al')[0]
        num_images = len(al.parse(f))
        total_num_images += num_images
        id2work[workerid] = TurkWorker(workerid, num_images, base_pay)

    # get the bonus payments
    with open('%s/%s-grant-bonus.sh' % (hits_dir, vid)) as fh:
        payments = fh.readlines()
        payments = payments[::2]

    for payment in payments:
        workerid = get_following_word(payment, '--workerid')
        id2work[workerid].add_payment(payment)

    total = np.zeros(4)
    for turkwork in id2work.values():
        print turkwork
        total += turkwork.totals()

    print "TOTALS -- base: $%5.2f, bonus: $%5.2f, total: $%5.2f, " \
    "num images: %d, num cars: %d, %.2f cars/image, avg price: $%4.3f/image, $%4.3f/car" % \
        (total[0], total[1], total[2],
         total_num_images, total[3], float(total[3])/total_num_images, total[2]/total_num_images, total[2]/total[3])

    with open('%s/%s-grant-bonus.sh' % (hits_dir, vid), 'w') as fh:
        for turkwork in id2work.values():
            fh.write(turkwork.bonus_str(hits_dir))


def get_worker_al_files(hits_dir):
    al_files = glob.glob('%s/results_by_worker_%s/*al' % \
                      (hits_dir, os.path.basename(hits_dir)))
    return al_files


class TurkWorker(object):
    def __init__(self, workerid, num_images, base_pay):
        self.workerid = workerid
        self.num_bonus_images = 0
        self.num_cars = 0
        self.bonus = 0
        self.base_pay = base_pay
        self.num_images = num_images
        self.assignment = None
        self.ppc = None

    def add_payment(self, payment):
        stats = self.parse_payment(payment)
        self.num_bonus_images += 1
        assert self.num_bonus_images <= self.num_images
        self.num_cars += stats['num_cars']
        self.bonus += stats['payment']
        self.ppc = stats['ppc']
        if self.assignment is None:
            self.assignment = stats['assignment']

    def parse_payment(self, payment):
        ppc = float(get_following_word(payment, 'vehicle:')[:-2])
        num_cars = int(get_following_word(payment, 'vehicles:')[:-1])
        workerid = get_following_word(payment, '--workerid')
        amount = float(get_following_word(payment, '--amount'))
        assignment = get_following_word(payment, '--assignment')
        #assert ppc * num_cars == amount
        assert workerid == self.workerid
        return {'num_cars': num_cars, 'payment': amount, 'assignment': assignment, 'ppc': ppc}

    @property
    def payment(self):
        return self.bonus + self.num_images * self.base_pay

    def totals(self):
        return [self.num_images * self.base_pay,
                self.bonus, self.payment, self.num_cars]

    def bonus_str(self, hits_dir):
        if self.bonus == 0:
            return ''
        video = os.path.basename(hits_dir)
        line = '"$MTURK_CMD_HOME"/bin/grantBonus.sh --workerid %s --amount %0.2f ' \
                '--assignment %s --reason "labeled vehicles: %d, bonus per vehicle: %0.3f"\n' % \
                (self.workerid, self.bonus, self.assignment, self.num_cars, self.ppc)
        line += 'echo "%s,%s" >> %s/%s-grant-bonus.log\n' % (self.workerid, self.assignment,
                                                             os.path.abspath(hits_dir), video)
        return line

    def __str__(self):
        return "%-15s labeled %3d images %4d cars with on average %5.2f cars/image" \
            " for bonus $%5.2f, base $%5.2f, total $%5.2f, and avg $%4.3f/image" % \
            (self.workerid, self.num_images, self.num_cars,
             float(self.num_cars) / self.num_images, self.bonus,
             self.num_images * self.base_pay, self.payment,
             self.payment / self.num_images)

def get_following_word(sent, word):
    words = sent.split(' ')
    for idx, w in enumerate(words):
        if w == word:
            return words[idx + 1]

def get_base_pay(hits_dir):
    with open('%s/properties' % hits_dir) as fh:
        for line in fh.readlines():
            if line.find('reward:') != -1:
                base_pay = float(line[len('reward:'):])
                return base_pay


if __name__ == '__main__':
    main()
