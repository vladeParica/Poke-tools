"""Initial seed mode (mock_seed.lua). It only gets the seed: no mode launches another.

- hit:       the bot reaches one of the seeds and pauses (PAUSED), without loading the save or
             starting another mode.
- at title:  7 pressed before the save is loaded read TID 0 / SID 0. It asks to load the save.
- old JSON:  a FRLG_ShinyBot.json that still has "afterSeedMode" (removed) is not an error: the bot
             says the key is no longer used and works as usual.
Usage:  cd shinybot/tests && python run_seed.py      (exit code 1 on failure)
"""
import os
import sys
import tempfile
os.chdir(os.path.dirname(os.path.abspath(__file__)))  # the tests run from shinybot/tests
import lupa.lua51 as L  # noqa: E402

base = open('../FRLG_ShinyBot.lua', encoding='utf-8').read()
mock = open('mock_seed.lua', encoding='utf-8').read()
# 64 consecutive seeds: one of every class mod 64, so every reset can reach one
SEEDS = ['%04X' % (0x1000 + i) for i in range(64)]
src = (base.replace('initialSeeds  = nil,', 'initialSeeds  = {%s},' % ','.join('"%s"' % s for s in SEEDS))
           .replace('resetOnLoad   = true,', 'resetOnLoad   = false,'))   # start with the save loaded, like pressing 7 in game
assert SEEDS[0] in src and 'afterSeedMode' not in base.split('local CONFIG_FILE')[0]


def run(at_title=False, json_text=None):
    lua = L.LuaRuntime()
    out = []
    lua.globals().py_out = out.append
    lua.execute('PARTY_N = 2; START_AT_TITLE = %s; io.write = function(s) py_out(s) end' % ('true' if at_title else 'nil'))
    ls = lua.eval('function(s,n) return assert(loadstring(s,n)) end')
    m, name = mock, 'bot'
    if json_text is not None:
        d = tempfile.mkdtemp() + '/'
        open(d + 'FRLG_ShinyBot.json', 'w', encoding='utf-8').write(json_text)
        m = mock.replace('io = { open = function() return nil end, write = io.write }', '')
        name = '@' + d + 'FRLG_ShinyBot.lua'
    r = tuple(ls(m, 'mock')('seed', 0, True, True)(ls(src, name)))
    return str(r[1]), int(r[2]), ''.join(out)


bad = 0


def check(name, err, frames, text, ok):
    global bad
    print('%s %-9s err=%s frames=%d' % ('ok  ' if ok else 'FAIL', name, err.split(':')[-1].strip(), frames))
    if not ok:
        print(text[-1200:])
    bad += not ok


err, frames, text = run()
check('hit', err, frames, text, 'PAUSED' in err and 'conseguida' in text and 'lista: continua, guarda un savestate' in text
      and 'cargando la partida' not in text)
err, frames, text = run(at_title=True)
check('at title', err, frames, text, 'Carga tu partida' in text and 'TID 0 / SID 0' not in text and 'conseguida' not in text)
# (no "mode": the mock presses 8 from mode 1 up to Initial seed)
old = ('{\n  "initialSeeds": [%s],\n  "afterSeedMode": "Salvaje RNG",\n'
       '  "resetOnLoad": false,\n  "stopOthers": false\n}\n' % ', '.join('"%s"' % s for s in SEEDS))
err, frames, text = run(json_text=old)
check('old JSON', err, frames, text, 'afterSeedMode ya no se usa' in text and 'opcion desconocida' not in text
      and 'PAUSED' in err and 'conseguida' in text)
sys.exit(1 if bad else 0)
