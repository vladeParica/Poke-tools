"""New game mode (pick the SID) in the simulator.

- ok:    started right after naming the rival: the bot finds a SID in the wanted range.
- early: started too early (the A presses never create the SID): the bot stops and says
         when to press 7, instead of retrying forever.
Usage:  cd shinybot/tests && python run_newgame.py      (exit code 1 on failure)
"""
import os
import sys
os.chdir(os.path.dirname(os.path.abspath(__file__)))  # the tests run from shinybot/tests
import lupa.lua51 as L  # noqa: E402

src = open('../FRLG_ShinyBot.lua', encoding='utf-8').read()
mock = open('mock_newgame.lua', encoding='utf-8').read()


def run(never):
    lua = L.LuaRuntime()
    if never:
        lua.execute('NG_NEVER = true; STOP_PRINT = "No aparecio el SID"')
    ls = lua.eval('function(s,n) return assert(loadstring(s,n)) end')
    r = tuple(ls(mock, 'mock')('newgame', 0, True, True)(ls(src, 'bot')))
    return r[0], str(r[1]), r[2]


bad = 0
texts, err, frames = run(False)
ok = 'PAUSED' in err   # the bot pauses the game once the SID is in the wanted range
print('%s ok     err=%s frames=%d' % ('ok  ' if ok else 'FAIL', err.split(':')[-1].strip(), frames))
bad += not ok
texts, err, frames = run(True)
ok = 'STOPPED' in err   # the bot gave up with the help message instead of retrying forever
print('%s early  err=%s frames=%d' % ('ok  ' if ok else 'FAIL', err.split(':')[-1].strip(), frames))
bad += not ok
if bad:
    print(texts[-1500:])
sys.exit(1 if bad else 0)
