"""Wild RNG surfing in a pond two tiles wide (mock_wild.lua with POND).

The bot must only walk between the tile it starts on and the neighbour walkAxis names: any
third tile is the shore, and stepping on it ends the surfing (the mock stops with LEFT THE
WATER). Before, it alternated left/right blindly and, after the preparation steps, could
start the search from the neighbour and step one tile further.
Usage:  cd shinybot/tests && python run_pond.py      (exit code 1 on failure)
"""
import os
import sys
os.chdir(os.path.dirname(os.path.abspath(__file__)))  # the tests run from shinybot/tests
import lupa.lua51 as L  # noqa: E402

BASE = open('../FRLG_ShinyBot.lua', encoding='utf-8').read().replace('species       = nil,', 'species       = {"Pikachu"},')
MOCK = open('mock_wild.lua', encoding='utf-8').read()
# (name, walkAxis, the two water tiles: the start x = 0 and its neighbour)
CASES = [('left (horizontal)', 'horizontal', (0, 65535)),
         ('right', 'right', (0, 1))]

bad = 0
for name, axis, pond in CASES:
    src = BASE.replace('walkAxis      = "horizontal",', 'walkAxis      = "%s",' % axis)
    lua = L.LuaRuntime()
    out = []
    lua.globals().py_out = out.append
    lua.execute('POND = {%d, %d}; io.write = function(s) py_out(s) end' % pond)
    ls = lua.eval('function(s,n) return assert(loadstring(s,n)) end')
    r = tuple(ls(MOCK, 'mock')('wild', 0, True, True)(ls(src, 'bot')))
    err = str(r[1])
    ok = 'PAUSED' in err
    print('%s %-18s err=%s frames=%d' % ('ok  ' if ok else 'FAIL', name, err.split(':')[-1].strip(), int(r[2])))
    if not ok:
        print(''.join(out)[-800:])
    bad += not ok
sys.exit(1 if bad else 0)
