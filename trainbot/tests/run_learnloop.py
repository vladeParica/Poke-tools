"""Train Bot: a move the bot doesn't want, and the "Stop learning X?" box (mock_train.lua, learnloop).

pret BattleScript_AskToLearnMove: "Stop learning X?" needs no button; the script waits for it and only
then shows the YES/NO box. The bot pressed B for battle texts there too: a B landing on the box's first
frame is NO, which asks the whole question again ("is trying to learn..."), and the emulator being
deterministic the B landed there every time: an endless loop. Every phase of the bot's B rhythm
against that text is tried; none may loop.
Usage:  python trainbot/tests/run_learnloop.py      (exit code 1 on failure)
"""
import json
import os
import shutil
import sys
import tempfile
import lupa.lua51 as L

here = os.path.dirname(os.path.abspath(__file__))
src = open(os.path.join(here, '..', 'FRLG_TrainBot.lua'), encoding='utf-8').read()
mock = open(os.path.join(here, 'mock_train.lua'), encoding='utf-8').read()
sys.path.insert(0, here)
import run_train  # noqa: E402

_, route = run_train.run('record', {"evs": {"atk": 6}, "healBelow": 40})
CFG = {"evs": None, "targetLevel": 9, "healBelow": 40, "learnMoves": "auto", "wantedMoves": ["Thunder"]}


def run(stop_wait):
    d = tempfile.mkdtemp()
    old = os.getcwd()
    os.chdir(d)
    try:
        open('FRLG_TrainBot.json', 'w').write(json.dumps(CFG))
        open('FRLG_TrainRoute.txt', 'w').write(route)
        lua = L.LuaRuntime()
        lua.execute('STOP_WAIT = %d' % stop_wait)
        ls = lua.eval('function(s,n) return assert(loadstring(s,n)) end')
        r = tuple(ls(mock, 'mock')('learnloop')(ls(src, 'bot')))
    finally:
        os.chdir(old)
        shutil.rmtree(d)
    return str(r[0]), int(r[6]), r[8], str(r[12])


bad = 0
for w in range(40, 52):
    err, prompts, lvl, learned = run(w)
    ok = 'LEARN LOOP' not in err and 'PAUSED' in err and prompts >= 1 and 'learned= ' in learned + ' '
    print('%s stop text %d frames  err=%s prompts=%d level=%s %s' % ('ok  ' if ok else 'FAIL', w, err.split(':')[-1].strip(),
                                                                     prompts, lvl, learned))
    bad += not ok
sys.exit(1 if bad else 0)
