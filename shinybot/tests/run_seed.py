"""Initial seed mode handing over to Gift RNG (the Eevee case), in mock_seed.lua.

- hit:       the bot reaches one of the seeds, loads the save and gets the gift (PAUSED).
- full party: with 6 Pokemon the gift would go to the PC, where the bot can't see it, and it
             retried forever ("Comprobando"). Now it refuses to start and says why.
- at title:  7 pressed before the save is loaded read TID 0 / SID 0. Now it asks to load the save.
Usage:  cd shinybot/tests && python run_seed.py      (exit code 1 on failure)
"""
import os
import sys
os.chdir(os.path.dirname(os.path.abspath(__file__)))  # the tests run from shinybot/tests
import lupa.lua51 as L  # noqa: E402

base = open('../FRLG_ShinyBot.lua', encoding='utf-8').read()
mock = open('mock_seed.lua', encoding='utf-8').read()
# 64 consecutive seeds: one of every class mod 64, so every reset can reach one
SEEDS = '{' + ','.join('"%04X"' % (0x1000 + i) for i in range(64)) + '}'
src = (base.replace('initialSeeds  = nil,', 'initialSeeds  = %s,' % SEEDS)
           .replace('afterSeedMode = nil,', 'afterSeedMode = "Regalo RNG",')
           .replace('shiny         = true,', 'shiny         = false,')
           .replace('resetOnLoad   = true,', 'resetOnLoad   = false,'))   # start with the save loaded, like pressing 7 in game
assert src.count('"Regalo RNG",') >= 1 and SEEDS in src


def run(party, at_title=False, src_=None):
    lua = L.LuaRuntime()
    out = []
    lua.globals().py_out = out.append
    lua.execute('PARTY_N = %d; START_AT_TITLE = %s; io.write = function(s) py_out(s) end'
                % (party, 'true' if at_title else 'nil'))
    ls = lua.eval('function(s,n) return assert(loadstring(s,n)) end')
    r = tuple(ls(mock, 'mock')('seed', 0, True, True)(ls(src_ or src, 'bot')))
    return str(r[1]), int(r[2]), ''.join(out)


bad = 0
err, frames, text = run(2)
ok = 'PAUSED' in err and 'conseguida' in text
print('%s hit         err=%s frames=%d' % ('ok  ' if ok else 'FAIL', err.split(':')[-1].strip(), frames))
bad += not ok
if not ok:
    print(text[-1200:])
err, frames, text = run(6)
ok = 'Equipo lleno' in text and 'conseguida' not in text
print('%s full party  err=%s frames=%d' % ('ok  ' if ok else 'FAIL', err.split(':')[-1].strip(), frames))
bad += not ok
if not ok:
    print(text[-1200:])
# 7 before the save is loaded: it used to start with TID 0 / SID 0 (and check shininess against them)
err, frames, text = run(2, at_title=True)
ok = 'Carga tu partida' in text and 'TID 0 / SID 0' not in text and 'conseguida' not in text
print('%s at title    err=%s frames=%d' % ('ok  ' if ok else 'FAIL', err.split(':')[-1].strip(), frames))
bad += not ok
if not ok:
    print(text[-1200:])
# pauseAfterSeed: it pauses once the save is loaded on the seed, before the gift mode starts
err, frames, text = run(2, src_=src.replace('pauseAfterSeed = false,', 'pauseAfterSeed = true,'))
ok = 'PAUSED' in err and 'Semilla cargada: guarda un savestate' in text and 'Shift+F1' in text
print('%s pause seed  err=%s frames=%d' % ('ok  ' if ok else 'FAIL', err.split(':')[-1].strip(), frames))
bad += not ok
if not ok:
    print(text[-1200:])
sys.exit(1 if bad else 0)
