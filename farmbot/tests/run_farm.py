"""Escenarios del Farm Bot en el simulador (mock_farm.lua).
Uso:  python farmbot/tests/run_farm.py [-v]
Sale con codigo 1 si algun escenario no da el resultado esperado.
"""
import json
import os
import shutil
import sys
import tempfile

import lupa.lua51 as L

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = open(os.path.join(HERE, '..', 'FRLG_FarmBot.lua'), encoding='utf-8').read()
MOCK = open(os.path.join(HERE, 'mock_farm.lua'), encoding='utf-8').read()
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


# Ruta al Centro del simulador: (8,10) -> (10,10) -> (10,3) -> puerta -> enfermera (5,3)
HEAL_ROUTE = 'GO ' + pts([(3, 20, 8, 10, 0)], line(3, 20, 9, 10, 10, 10, 4), line(3, 20, 10, 9, 10, 3, 2),
                         line(4, 1, 5, 8, 5, 3, 2)) + '\n' + \
             'BACK ' + pts([(4, 1, 5, 3, 0)], line(4, 1, 5, 4, 5, 8, 1), line(3, 20, 10, 3, 10, 10, 1),
                           line(3, 20, 9, 10, 8, 10, 3)) + '\n'
# Ruta de entrenadores: (8,10) -> (15,10) y vuelta
TRAINER_ROUTE = 'GO ' + pts([(3, 20, 8, 10, 0)], line(3, 20, 9, 10, 15, 10, 4)) + '\n' + \
                'BACK ' + pts([(3, 20, 15, 10, 0)], line(3, 20, 14, 10, 8, 10, 3)) + '\n'


def run(scen, cfg, show=False):
    d = tempfile.mkdtemp()
    old = os.getcwd()
    os.chdir(d)
    try:
        open('FRLG_FarmBot.json', 'w').write(json.dumps(cfg))
        open('FRLG_TrainRoute.txt', 'w').write(HEAL_ROUTE)
        open('FRLG_FarmTrainers.txt', 'w').write(TRAINER_ROUTE)
        lua = L.LuaRuntime()
        ls = lua.eval('function(s,n) return assert(loadstring(s,n)) end')
        r = dict(zip(FIELDS, tuple(ls(MOCK, 'mock')(scen)(ls(SRC, 'bot')))))
        log = open('logs/farm_log.txt').read() if os.path.exists('logs/farm_log.txt') else ''
    finally:
        os.chdir(old)
        shutil.rmtree(d, ignore_errors=True)
    r['err'] = str(r['err']).split('\n')[0]
    r['log'] = log
    if show:
        print('--- print ---\n' + r['printed'][-1500:] + '\n--- log ---\n' + log[-2000:] + '\n--- events ---\n' + r['events'][-800:])
    return r


CASES = [
    ('nivel', 'nivel', {'mode': 'nivel', 'targetLevel': 14},
     lambda r: 'PAUSED' in r['err'] and r['level'] >= 14 and 'FARMEO COMPLETO' in r['log']),
    ('objetos', 'objetos', {'mode': 'objetos', 'itemTarget': 4},
     lambda r: 'PAUSED' in r['err'] and r['taken'] >= 4 and 'FARMEO COMPLETO' in r['log'] and r['menus'] >= 2),
    ('mochila llena', 'bagfull', {'mode': 'objetos', 'itemTarget': 4},
     # halt() pausa con pcall(emu.pause): en el simulador acaba en IDLE con el bot detenido
     lambda r: ('PAUSED' in r['err'] or 'IDLE' in r['err']) and 'mochila no tiene espacio' in r['log'] and r['taken'] == 0),
    ('objetos en pausa', 'pausa', {'mode': 'objetos', 'takeItems': 'pause'},
     lambda r: ('PAUSED' in r['err'] or 'IDLE' in r['err']) and 'Quita los objetos' in r['log'] and r['menus'] == 0),
    ('menu con CORTE', 'campo', {'mode': 'objetos', 'itemTarget': 2},
     lambda r: 'PAUSED' in r['err'] and r['taken'] >= 2 and 'FARMEO COMPLETO' in r['log']),
    ('sin Recogida', 'nivel', {'mode': 'objetos'},
     lambda r: 'Recogida' in r['printed'] and r['battles'] == 0),
    ('sin Ladron', 'nivel', {'mode': 'robar'},
     lambda r: 'Ladron (Thief)' in r['printed'] and r['battles'] == 0),
    ('sin Buscapelea', 'nivel', {'mode': 'dinero'},
     lambda r: 'Registra el Buscapelea' in r['printed'] and r['battles'] == 0),
    ('config invalida', 'nivel', {'mode': 'farmear', 'targetLevel': 200},
     lambda r: 'mode debe ser' in r['printed'] and 'targetLevel debe ser' in r['printed'] and r['battles'] == 0),
    ('robar', 'robar', {'mode': 'robar', 'wantedItems': ['Nugget'], 'itemTarget': 2},
     lambda r: 'PAUSED' in r['err'] and r['steals'] >= 2 and r['taken'] >= 2 and 'FARMEO COMPLETO' in r['log']),
    ('diagnostico', 'diag', {'mode': 'objetos'},
     # read-only: the player opens the menus, the log records each step, the bot presses nothing
     lambda r: 'IDLE' in r['err'] and 'DIAG START POKEMON' in r['log'] and 'equipo 1 Charmander' in r['log']
     and 'acciones DATOS' in r['log'] and r['battles'] == 0),
    ('dinero', 'dinero', {'mode': 'dinero', 'moneyTarget': 3000 + 480 * 4},
     lambda r: 'PAUSED' in r['err'] and r['money'] >= 4920 and r['trainer'] >= 4 and r['vsuses'] >= 2
     and 'FARMEO COMPLETO' in r['log']),
]

def check_configs():
    """The shipped JSON and every example load without config problems."""
    import glob
    files = [os.path.join(HERE, '..', 'FRLG_FarmBot.json')] + sorted(glob.glob(os.path.join(HERE, '..', 'examples', '*.json')))
    bad = 0
    for f in files:
        d = tempfile.mkdtemp()
        old = os.getcwd()
        os.chdir(d)
        try:
            shutil.copy(f, 'FRLG_FarmBot.json')
            lua = L.LuaRuntime()
            ls = lua.eval('function(s,n) return assert(loadstring(s,n)) end')
            mock = MOCK.replace('local MAXF = 400000', 'local MAXF = 50')
            printed = str(tuple(ls(mock, 'mock')('nivel')(ls(SRC, 'bot')))[17])
        finally:
            os.chdir(old)
            shutil.rmtree(d, ignore_errors=True)
        ok = 'Config cargada' in printed and 'Config:' not in printed
        bad += not ok
        print('%s config %s' % ('ok  ' if ok else 'FAIL', os.path.basename(f)))
        if not ok:
            print('   ' + printed[-300:])
    return bad


if __name__ == '__main__':
    show = '-v' in sys.argv
    only = [a for a in sys.argv[1:] if not a.startswith('-')]
    bad = 0
    for name, scen, cfg, check in CASES:
        if only and scen not in only:
            continue
        r = run(scen, cfg, show)
        ok = check(r)
        bad += not ok
        print('%s %-16s err=%-24s frame=%-6d battles=%-3d fought=%-3d ran=%-3d heals=%d level=%d pickups=%d taken=%d '
              'held=%s bag=%s steals=%d thief=%d money=%d trainer=%d vs=%d menus=%d' % (
                  'ok  ' if ok else 'FAIL', name, r['err'][-24:], r['frame'], r['battles'], r['fought'], r['ran'],
                  r['heals'], r['level'], r['pickups'], r['taken'], r['held'], r['bag'], r['steals'], r['thief'],
                  r['money'], r['trainer'], r['vsuses'], r['menus']))
        if not ok and not show:
            print('   log: ' + r['log'][-600:].replace('\n', '\n        '))
    if not only:
        bad += check_configs()
    sys.exit(1 if bad else 0)
