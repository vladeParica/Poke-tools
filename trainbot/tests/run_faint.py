"""Train Bot: the trained Pokemon faints in a wild battle and the game asks for another one.

That party screen (CONTROLLER_CHOOSEPOKEMON) can't be closed with B and its cursor starts on
the fainted lead. The bot must send out the healthy Pokemon with the highest level (a Meowth
Lv 15, not the fainted Pidgey Lv 20 nor the Meowth Lv 10), run, heal and carry on.
Runs in the Farm Bot simulator, scenario "faint" (see run_pickup.py).
Usage:  python trainbot/tests/run_faint.py [-v]      (exit code 1 on failure)
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from run_pickup import run  # noqa: E402


def main():
    show = '-v' in sys.argv
    r = run('faint', {'maxLevel': 14}, show)
    ev = r['events']
    ok = ('sent out 52 Lv15' in ev and 'tried to send out a fainted' not in ev and r['ran'] >= 1
          and r['heals'] >= 1 and 'PAUSED' in r['err'] and 'ENTRENAMIENTO COMPLETO' in r['log']
          and 'saco a Meowth (Nv.15)' in r['log'])
    print('%s faint  err=%s battles=%d ran=%d heals=%d level=%d' % (
        'ok  ' if ok else 'FAIL', r['err'][-24:], r['battles'], r['ran'], r['heals'], r['level']))
    if not ok and not show:
        print(r['log'][-900:])
        print(ev[-500:])
    sys.exit(0 if ok else 1)


if __name__ == '__main__':
    main()
