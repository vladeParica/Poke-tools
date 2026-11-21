"""Fishing mode (Pesca) in mock.lua: SELECT casts the registered rod, B closes the texts.

- bite:     it fishes, runs from the first two (Magikarp) and stops on the shiny one (PAUSED),
            never pressing A on the map (facing water, A would offer Surf).
- no rod:   no rod registered on SELECT: it says so and doesn't start.
- dry:      not facing water (nothing ever bites): it stops and says why instead of looping.
Usage:  cd shinybot/tests && python run_fish.py      (exit code 1 on failure)
"""
import os
import sys
os.chdir(os.path.dirname(os.path.abspath(__file__)))  # the tests run from shinybot/tests
import lupa.lua51 as L  # noqa: E402

src = open('../FRLG_ShinyBot.lua', encoding='utf-8').read()
mock = open('mock.lua', encoding='utf-8').read()


def run(setup=''):
    lua = L.LuaRuntime()
    out = []
    lua.globals().py_out = out.append
    lua.execute(setup + ' io.write = function(s) py_out(s) end')
    ls = lua.eval('function(s,n) return assert(loadstring(s,n)) end')
    r = tuple(ls(mock, 'mock')('fish', 3, False)(ls(src, 'bot')))
    return {'err': str(r[0]), 'frames': int(r[1]), 'enc': int(r[2]), 'flees': int(r[4]), 'casts': int(r[8]),
            'mapA': int(r[9]), 'text': ''.join(out)}


bad = 0


def check(name, r, ok):
    global bad
    print('%s %-8s err=%s frames=%d casts=%d encounters=%d flees=%d mapA=%d' % (
        'ok  ' if ok else 'FAIL', name, r['err'].split(':')[-1].strip(), r['frames'], r['casts'], r['enc'], r['flees'],
        r['mapA']))
    if not ok:
        bad += 1
        print(r['text'][-1200:])


r = run()
check('bite', r, 'PAUSED' in r['err'] and r['enc'] == 3 and r['flees'] == 2 and r['mapA'] == 0
      and 'SHINY' in r['text'] and 'Magikarp' in r['text'])
r = run('FISH_ROD = 0')
check('no rod', r, 'registra la Cana' in r['text'] and r['casts'] == 0 and 'Bot iniciado' not in r['text'])
r = run('FISH_DRY = true')
check('dry', r, 'no pica nada' in r['text'] and r['enc'] == 0 and r['casts'] < 100)   # stopped, not looping
sys.exit(1 if bad else 0)
