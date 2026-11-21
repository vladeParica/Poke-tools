"""Far RNG target without the Teachy TV.

The bot must save a state shortly before the target and start the following tries from it,
instead of waiting again from the base. Checks that it still pauses on the target (PAUSED),
that the state was saved and that the run took far fewer frames than waiting from the base
on every try would.
Usage:  cd shinybot/tests && python run_near.py      (exit code 1 on failure)
"""
import os
import re
import sys
os.chdir(os.path.dirname(os.path.abspath(__file__)))  # the tests run from shinybot/tests
import lupa.lua51 as L  # noqa: E402

base = open('../FRLG_ShinyBot.lua', encoding='utf-8').read()
mock = open('mock_rng.lua', encoding='utf-8').read()
src = base.replace('teachy        = true,', 'teachy        = false,')
assert src != base


def run(mode):
    lua = L.LuaRuntime()
    out = []
    lua.globals().py_out = out.append
    # capture what the bot prints (the mock writes it through io.write)
    lua.execute('local w = io.write; io.write = function(s) py_out(s); return w(s) end')
    ls = lua.eval('function(s,n) return assert(loadstring(s,n)) end')
    r = tuple(ls(mock, 'mock')(mode, 0, True, True)(ls(src, 'bot')))
    return ''.join(out), str(r[1]), int(r[2])


bad, seen = 0, False
# The simulator is random: run until one far target needed retries (that is the case this covers)
for i in range(8):
    mode = ['static', 'gift', 'roamer'][i % 3]
    text, err, frames = run(mode)
    # a target can be given up after its tries: take the farthest one the run waited for
    target = max([int(x) for x in re.findall(r'Objetivo: avance (\d+)', text)] or [0])
    tries = len(re.findall(r'Intento \d+', text))
    saved = 'Estado guardado cerca del objetivo' in text
    useful = saved and tries > 0
    # waiting from the base on every try would cost about target * (tries + 1) frames
    ok = 'PAUSED' in err and (not useful or frames < target * (tries + 1))
    print('%s %-6s err=%s target=%d tries=%d saved=%s frames=%d' % (
        'ok  ' if ok else 'FAIL', mode, err.split(':')[-1].strip(), target, tries, saved, frames))
    bad += not ok
    seen = seen or useful
    if seen and i >= 2:
        break
if not seen:
    print('FAIL no run saved a state near a far target and retried from it')
sys.exit(1 if bad or not seen else 0)
