"""Train Bot: the end of training, or of a phase, heals at the Center and then pauses.

- fase:      'species' only gives Attack and Speed is still missing: once Attack is done the
             spot is finished ("FASE TERMINADA"), instead of running from everything forever.
- sin lista: no species list and no opponent gives the missing Defense: after 40 battles in a
             row without a useful one it stops too.
- completo:  the EVs are done: it heals first, then pauses ("ENTRENAMIENTO COMPLETO").
Usage:  python trainbot/tests/run_phase.py [-v]      (exit code 1 on failure)
"""
import contextlib
import io
import json
import os
import shutil
import sys
import tempfile

import lupa.lua51 as L

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = open(os.path.join(HERE, '..', 'FRLG_TrainBot.lua'), encoding='utf-8').read()
MOCK = open(os.path.join(HERE, 'mock_train.lua'), encoding='utf-8').read()
FIELDS = 'err frame battles fought ran heals learn evs lvl printed events pos growl'.split()


def run(scen, cfg, route=None):
    d = tempfile.mkdtemp()
    old = os.getcwd()
    os.chdir(d)
    try:
        open('FRLG_TrainBot.json', 'w').write(json.dumps(cfg))
        if route:
            open('FRLG_TrainRoute.txt', 'w').write(route)
        lua = L.LuaRuntime()
        ls = lua.eval('function(s,n) return assert(loadstring(s,n)) end')
        r = dict(zip(FIELDS, tuple(ls(MOCK, 'mock')(scen)(ls(SRC, 'bot')))))
        r['route'] = open('FRLG_TrainRoute.txt').read() if os.path.exists('FRLG_TrainRoute.txt') else ''
        r['log'] = open('logs/train_log.txt').read() if os.path.exists('logs/train_log.txt') else ''
    finally:
        os.chdir(old)
        shutil.rmtree(d, ignore_errors=True)
    r['err'] = str(r['err']).split('\n')[0]
    return r


def main():
    show = '-v' in sys.argv
    with contextlib.redirect_stdout(io.StringIO()):
        route = run('record', {'evs': {'atk': 6}, 'healBelow': 40})['route']
    cases = [
        ('fase', {'evs': {'atk': 3, 'spe': 5}, 'species': ['Mankey', 'Ekans'], 'healBelow': 40},
         lambda r: 'PAUSED' in r['err'] and 'FASE TERMINADA' in r['log'] and '5 Vel' in r['log']
         and r['evs'].split(',')[1] == '3' and 'ENTRENAMIENTO COMPLETO' not in r['log']),
        ('sin lista', {'evs': {'atk': 2, 'def': 5}, 'healBelow': 40},
         lambda r: 'PAUSED' in r['err'] and 'FASE TERMINADA: 40 combates' in r['log']),
        ('completo', {'evs': {'atk': 6}, 'healBelow': 40},
         lambda r: 'PAUSED' in r['err'] and 'ENTRENAMIENTO COMPLETO' in r['log']
         and r['log'].rfind('fin del entrenamiento') < r['log'].rfind('ENTRENAMIENTO COMPLETO')),
    ]
    cases.append(('510', {'evs': {'atk': 252, 'spe': 252, 'hp': 6}, 'healBelow': 40},
                  lambda r: 'PAUSED' in r['err'] and 'ya tiene 510 EVs' in r['log'] and '3 PS' in r['log']
                  and r['fought'] == 0, 'full510'))
    bad = 0
    for case in cases:
        name, cfg, check = case[:3]
        r = run(case[3] if len(case) > 3 else 'evs', cfg, route)
        ok = check(r)
        bad += not ok
        print('%s %-10s err=%-24s battles=%-3d fought=%-3d ran=%-3d heals=%d evs=%s' % (
            'ok  ' if ok else 'FAIL', name, r['err'][-24:], r['battles'], r['fought'], r['ran'], r['heals'], r['evs']))
        if show or not ok:
            print(r['log'][-900:])
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
