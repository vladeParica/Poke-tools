"""The bots behave the same in every language (ADR-0014).

Runs the Farm Bot and Train Bot simulator scenarios with "language": "es", "en" and "ja"
and checks that every number (frames, battles, items, money, EVs, level…) is identical,
and that the log really is in the chosen language.
Usage:  python shared/tests/run_lang.py        (exit code 1 on any difference)
"""
import contextlib
import io
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, 'farmbot', 'tests'))
sys.path.insert(0, os.path.join(ROOT, 'trainbot', 'tests'))
import run_farm  # noqa: E402
import run_train  # noqa: E402

LANGS = ('es', 'en', 'ja')
# A line that must appear in each language's log for the "nivel" farm scenario.
FARM_DONE = {'es': 'FARMEO COMPLETO', 'en': 'FARMING DONE', 'ja': 'FARM KANRYO'}
TRAIN_DONE = {'es': 'ENTRENAMIENTO COMPLETO', 'en': 'TRAINING DONE', 'ja': 'IKUSEI KANRYO'}
TEXT_FIELDS = {'err', 'log', 'printed', 'events'}


def farm_numbers(r):
    return {k: v for k, v in r.items() if k not in TEXT_FIELDS}


def main():
    bad = 0
    for name, scen, cfg, _check in run_farm.CASES:
        res = {}
        for lang in LANGS:
            res[lang] = run_farm.run(scen, dict(cfg, language=lang))
        base = farm_numbers(res['es'])
        for lang in LANGS[1:]:
            if farm_numbers(res[lang]) != base:
                bad += 1
                print('FAIL farm %-16s %s differs: %s vs %s' % (name, lang, farm_numbers(res[lang]), base))
        if name == 'nivel':
            for lang in LANGS:
                if FARM_DONE[lang] not in res[lang]['log']:
                    bad += 1
                    print('FAIL farm %s: log not in %s' % (name, lang))
        print('ok   farm %s' % name)

    # Train Bot: record a route once, then the level scenario in each language.
    with contextlib.redirect_stdout(io.StringIO()):
        _, route = run_train.run('record', {"evs": {"atk": 6}, "healBelow": 40})
    for scen, cfg in [('evs', {"evs": {"atk": 6}, "healBelow": 40}),
                      ('level', {"evs": None, "targetLevel": 9, "healBelow": 40}),
                      ('nolearn', {"evs": {"atk": 2, "spe": 3}, "healBelow": 40, "avoidSpecies": ["Pidgey"]})]:
        res = {}
        for lang in LANGS:
            with contextlib.redirect_stdout(io.StringIO()):
                r, _ = run_train.run(scen, dict(cfg, language=lang), route=route)
            err, frame, battles, fought, ran, heals, learn, evs, lvl, printed, events, pos, growl = r
            res[lang] = (str(err).split(':')[-1].strip(), frame, battles, fought, ran, heals, learn, evs, lvl, pos, growl, printed)
        for lang in LANGS[1:]:
            if res[lang][:-1] != res['es'][:-1]:
                bad += 1
                print('FAIL train %s %s differs: %s vs %s' % (scen, lang, res[lang][:-1], res['es'][:-1]))
        if scen == 'level':
            for lang in LANGS:
                if TRAIN_DONE[lang] not in res[lang][-1]:
                    bad += 1
                    print('FAIL train %s: console not in %s' % (scen, lang))
        print('ok   train %s' % scen)
    print('%d differences' % bad)
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
