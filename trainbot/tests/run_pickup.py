"""Train Bot with Pickup Pokemon in slots 2-6 (option "pickup").

Runs FRLG_TrainBot.lua in the Farm Bot simulator (farmbot/tests/mock_farm.lua), which has the
same memory layout plus Pickup Meowth and the START / party / item menus. The Farm Bot's
takeItems code was copied into the Train Bot, so it is checked with the same menus.
Usage:  python trainbot/tests/run_pickup.py [-v]      (exit code 1 on failure)
"""
import json
import os
import shutil
import sys
import tempfile

import lupa.lua51 as L

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = open(os.path.join(HERE, '..', 'FRLG_TrainBot.lua'), encoding='utf-8').read()
MOCK = open(os.path.join(HERE, '..', '..', 'farmbot', 'tests', 'mock_farm.lua'), encoding='utf-8').read()
FIELDS = ('err frame battles fought ran heals level pickups taken held bag steals thief money '
          'trainer vsuses menus printed events').split()


def pts(*segs):
    return ';'.join('%d %d %d %d %d' % p for seg in segs for p in seg)


def line(g, n, x0, y0, x1, y1, d):
    out = []
    if x0 == x1:
        step = 1 if y1 > y0 else -1
        for y in range(y0, y1 + step, step):
            out.append((g, n, x0, y, d))
    else:
        step = 1 if x1 > x0 else -1
        for x in range(x0, x1 + step, step):
            out.append((g, n, x, y0, d))
    return out


# The simulator's route to the Center, the same one farmbot/tests/run_farm.py uses
HEAL_ROUTE = 'GO ' + pts([(3, 20, 8, 10, 0)], line(3, 20, 9, 10, 10, 10, 4), line(3, 20, 10, 9, 10, 3, 2),
                         line(4, 1, 5, 8, 5, 3, 2)) + '\n' + \
             'BACK ' + pts([(4, 1, 5, 3, 0)], line(4, 1, 5, 4, 5, 8, 1), line(3, 20, 10, 3, 10, 10, 1),
                           line(3, 20, 9, 10, 8, 10, 3)) + '\n'


def run(scen, cfg, show=False):
    d = tempfile.mkdtemp()
    old = os.getcwd()
    os.chdir(d)
    try:
        open('FRLG_TrainBot.json', 'w').write(json.dumps(cfg))
        open('FRLG_TrainRoute.txt', 'w').write(HEAL_ROUTE)
        lua = L.LuaRuntime()
        ls = lua.eval('function(s,n) return assert(loadstring(s,n)) end')
        r = dict(zip(FIELDS, tuple(ls(MOCK, 'mock')(scen)(ls(SRC, 'bot')))))
        log = open('logs/train_log.txt').read() if os.path.exists('logs/train_log.txt') else ''
    finally:
        os.chdir(old)
        shutil.rmtree(d, ignore_errors=True)
    r['err'] = str(r['err']).split('\n')[0]
    r['log'] = log
    if show:
        print('--- print ---\n' + r['printed'][-1200:] + '\n--- log ---\n' + log[-1800:])
    return r


def stopped(r):
    # halt()/pause: the simulator ends PAUSED, or IDLE with the bot stopped
    return 'PAUSED' in r['err'] or 'IDLE' in r['err']


CASES = [
    # 2 Meowth with Pickup: train to the level cap, take their items, and empty them before ending
    ('recogida', 'objetos', {'pickup': 'auto', 'maxLevel': 14},
     lambda r: 'PAUSED' in r['err'] and 'ENTRENAMIENTO COMPLETO' in r['log'] and r['taken'] >= 2
     and r['menus'] >= 1 and r['held'].split(',')[1:] == ['0'] * (len(r['held'].split(',')) - 1)),
    ('recogida cada 1', 'objetos', {'pickup': 'auto', 'pickupTakeAt': 1, 'maxLevel': 14},
     lambda r: 'PAUSED' in r['err'] and 'ENTRENAMIENTO COMPLETO' in r['log'] and r['taken'] >= 2),
    ('recogida en pausa', 'pausa', {'pickup': 'pause', 'maxLevel': 30},
     lambda r: stopped(r) and 'Quita los objetos' in r['log'] and r['menus'] == 0),
    ('mochila llena', 'bagfull', {'pickup': 'auto', 'maxLevel': 30},
     lambda r: stopped(r) and 'mochila no tiene espacio' in r['log'] and r['taken'] == 0),
    # off (the default): the same Train Bot as before, it never opens a menu
    ('sin la opcion', 'objetos', {'maxLevel': 14},
     lambda r: 'PAUSED' in r['err'] and 'ENTRENAMIENTO COMPLETO' in r['log'] and r['menus'] == 0 and r['taken'] == 0),
    ('sin Recogida', 'nivel', {'pickup': 'auto', 'maxLevel': 14},
     lambda r: 'PAUSED' in r['err'] and 'no hay Pokemon con Recogida' in r['log'] and r['menus'] == 0),
]


def main():
    show = '-v' in sys.argv
    bad = 0
    for name, scen, cfg, check in CASES:
        r = run(scen, cfg, show)
        ok = check(r)
        bad += not ok
        print('%s %-18s err=%-22s battles=%-3d level=%-3d pickups=%-3d taken=%-3d menus=%-2d held=%s' % (
            'ok  ' if ok else 'FAIL', name, r['err'][-22:], r['battles'], r['level'], r['pickups'], r['taken'],
            r['menus'], r['held']))
        if not ok and not show:
            print(r['log'][-900:])
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
