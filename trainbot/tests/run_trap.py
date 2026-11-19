"""Train Bot: a wild Pokemon that doesn't let you run (Shadow Tag) must be fought, not fled.

In the Farm Bot simulator, scenario "trap", wild Rattata have Shadow Tag and RUN only shows
"Can't escape!". The config avoids Rattata, so the bot wants to run: it has to see it is
trapped (pret IsRunningFromBattleImpossible) and fight instead of choosing RUN forever.
Usage:  python trainbot/tests/run_trap.py [-v]      (exit code 1 on failure)
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from run_pickup import run  # noqa: E402


def main():
    show = '-v' in sys.argv
    r = run('trap', {'avoidSpecies': ['Rattata'], 'maxLevel': 14}, show)
    ev = r['events']
    trapped = ev.count('battle 19')
    ok = ('PAUSED' in r['err'] and 'ENTRENAMIENTO COMPLETO' in r['log'] and trapped >= 1
          and 'No puede huir de Rattata' in r['log'] and ev.count('cannot escape') == 0)
    print('%s trap  err=%s battles=%d rattata=%d ran=%d level=%d' % (
        'ok  ' if ok else 'FAIL', r['err'][-24:], r['battles'], trapped, r['ran'], r['level']))
    if not ok and not show:
        print(r['log'][-900:])
        print(ev[-500:])
    sys.exit(0 if ok else 1)


if __name__ == '__main__':
    main()
