"""Fishing RNG mode (Pesca RNG) in mock_fish.lua, which follows pret's Task_Fishing.

Each case must cast until something bites, save the state on the "on the hook!" text, calibrate
the B press and get the target the filters ask for (PAUSED), or refuse with a reason.
Usage:  cd shinybot/tests && python run_fishrng.py [-v]      (exit code 1 on failure)
"""
import os
import sys
os.chdir(os.path.dirname(os.path.abspath(__file__)))  # the tests run from shinybot/tests
import lupa.lua51 as L  # noqa: E402

BASE = open('../FRLG_ShinyBot.lua', encoding='utf-8').read()
MOCK = open('mock_fish.lua', encoding='utf-8').read()
SHOW = '-v' in sys.argv


def bot(species='nil', natures='nil', shiny=True):
    src = (BASE.replace('species       = nil,', 'species       = %s,' % species)
               .replace('natures       = nil,', 'natures       = %s,' % natures))
    if not shiny:
        src = src.replace('shiny         = true,', 'shiny         = false,')
    return src


def run(src, setup=''):
    lua = L.LuaRuntime()
    out = []
    lua.globals().py_out = out.append
    lua.execute(setup + ' io.write = function(s) py_out(s) end')
    ls = lua.eval('function(s,n) return assert(loadstring(s,n)) end')
    r = tuple(ls(MOCK, 'mock')()(ls(src, 'bot')))
    return {'err': str(r[0]), 'frames': int(r[1]), 'casts': int(r[2]), 'bites': int(r[3]), 'made': int(r[4]),
            'loads': int(r[5]), 'earlyB': int(r[6]), 'msgs': int(r[7]), 'panel': str(r[8]), 'text': ''.join(out)}


bad = 0


def check(name, r, ok):
    global bad
    found = [l for l in r['text'].split('\n') if 'OBJETIVO' in l or 'SHINY' in l]
    print('%s %-28s err=%s frames=%d casts=%d bites=%d made=%d %s' % (
        'ok  ' if ok else 'FAIL', name, r['err'].split(':')[-1].strip(), r['frames'], r['casts'], r['bites'], r['made'],
        (found[-1].split('] ')[-1][:70] if found else '')))
    if not ok or SHOW:
        print(r['text'][-1500:])
    bad += not ok


# Super Rod, Dratini (slot 10, 1%) Jolly: calibrates, then presses B on the target frame
r = run(bot('{"Dratini"}', '{"Jolly"}', shiny=False))
check('Super Rod Dratini Jolly', r, 'PAUSED' in r['err'] and 'Dratini' in r['text'] and 'Jolly' in r['text']
      and 'Calibrado' in r['text'] and r['earlyB'] == 0)
# shiny, any species
r = run(bot())
check('Super Rod shiny', r, 'PAUSED' in r['err'] and 'SHINY' in r['text'])
# Old Rod: only slots 1-2 (Magikarp)
r = run(bot('{"Magikarp"}', '{"Adamant"}', shiny=False), 'FISH_ROD = 262')
check('Old Rod Magikarp Adamant', r, 'PAUSED' in r['err'] and 'Magikarp' in r['text'] and 'Adamant' in r['text'])
# Good Rod, a slow text speed: B must wait until the text is printed
r = run(bot('{"Poliwag"}', '{"Timid"}', shiny=False), 'FISH_ROD = 263; TEXT_SPEED = 8')
check('Good Rod Poliwag, slow text', r, 'PAUSED' in r['err'] and 'Poliwag' in r['text'] and r['earlyB'] == 0)
# a species the rod can't catch: the search says so instead of waiting forever
r = run(bot('{"Dratini"}', shiny=False), 'FISH_ROD = 262')
check('Old Rod, Dratini impossible', r, "ninguna especie de 'species'" in r['text'] and r['made'] == 0)
# refusals
r = run(bot(), 'FISH_ROD = 0')
check('no rod registered', r, 'registra la Cana' in r['text'] and 'Bot iniciado' not in r['text'])
r = run(bot(), 'FISH_DRY = true')
check('not facing water', r, 'no sale la cana' in r['text'] and r['made'] == 0)
# a build without verified symbols (other languages): Game.taskFishing is nil there
r = run(bot().replace('G.taskFishing = fishing and (fishing + 1)', 'G.taskFishing = nil'))
check('build without symbols', r, 'solo en Rojo Fuego / Verde Hoja USA' in r['text'] and 'Bot iniciado' not in r['text'])
sys.exit(1 if bad else 0)
