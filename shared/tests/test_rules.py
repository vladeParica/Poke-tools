"""Unit tests for the pure decision rules (shared/lua/rules.lua, ADR-0015).

No emulator and no simulator: the rules take data, so each case is one call.
Usage:  python shared/tests/test_rules.py      (exit code 1 on failure)
"""
import os
import sys

import lupa.lua51 as L

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = open(os.path.join(HERE, '..', 'lua', 'rules.lua'), encoding='utf-8').read()

lua = L.LuaRuntime()
R = lua.execute(SRC + '\nreturn Rules')
T = lua.table_from

# gBattleMons ability / type ids (pret constants)
SHADOW_TAG, ARENA_TRAP, MAGNET_PULL, LEVITATE, RUN_AWAY, BLAZE = 23, 71, 42, 26, 50, 66
GROUND, FLYING, STEEL, FIRE = 4, 2, 8, 10
SMOKE_BALL = 194


def me(ability=BLAZE, t1=GROUND, t2=GROUND, item=0, bits=0):
    return T({'ability': ability, 'type1': t1, 'type2': t2, 'item': item, 'trappedBits': bits})


def foe(ability):
    return T({'ability': ability})


def evs(*v):
    return T(dict(enumerate(v, 1)))     # memory order: HP, Atk, Def, Spe, SpA, SpD


CASES = [
    # --- trappedBy: pret IsRunningFromBattleImpossible
    ('Shadow Tag traps', R.trappedBy(me(), foe(SHADOW_TAG)) == SHADOW_TAG),
    ('Arena Trap traps a Ground type (Sandslash in Diglett\'s Cave)', R.trappedBy(me(), foe(ARENA_TRAP)) == ARENA_TRAP),
    ('Arena Trap doesn\'t trap a Flying type', R.trappedBy(me(t2=FLYING), foe(ARENA_TRAP)) is None),
    ('Arena Trap doesn\'t trap Levitate', R.trappedBy(me(ability=LEVITATE), foe(ARENA_TRAP)) is None),
    ('Magnet Pull traps a Steel type', R.trappedBy(me(t1=STEEL), foe(MAGNET_PULL)) == MAGNET_PULL),
    ('Magnet Pull doesn\'t trap others', R.trappedBy(me(t1=FIRE, t2=FIRE), foe(MAGNET_PULL)) is None),
    ('Mean Look / Wrap (status2) trap', R.trappedBy(me(bits=0x2000), foe(0)) == 'move'),
    ('Smoke Ball always escapes', R.trappedBy(me(item=SMOKE_BALL), foe(SHADOW_TAG)) is None),
    ('Run Away always escapes', R.trappedBy(me(ability=RUN_AWAY), foe(SHADOW_TAG)) is None),
    ('nothing: can run', R.trappedBy(me(), foe(BLAZE)) is None),
]


def step(e, g, t, allow=False):
    over, useful = R.evStep(e, g, t, allow)
    return over, useful


TARGET = evs(6, 252, 0, 252, 0, 0)         # 6 HP / 252 Atk / 252 Spe
CASES += [
    # --- evStep: what beating a Pokemon does to the EVs
    ('missing Atk, +1 Atk: useful', step(evs(0, 100, 0, 0, 0, 0), evs(0, 1, 0, 0, 0, 0), TARGET) == (None, True)),
    ('251 Atk, +2 Atk: passes the goal', step(evs(0, 251, 0, 0, 0, 0), evs(0, 2, 0, 0, 0, 0), TARGET)[0] == 2),
    ('251 Atk, +2 Atk, allowOvershoot: allowed', step(evs(0, 251, 0, 0, 0, 0), evs(0, 2, 0, 0, 0, 0), TARGET, True) == (None, True)),
    ('252 Spe, +1 Spe: passes (the Diglett case)', step(evs(0, 252, 0, 252, 0, 0), evs(0, 0, 0, 1, 0, 0), TARGET)[0] == 4),
    ('unwanted Def: passes even with allowOvershoot', step(evs(0, 0, 0, 0, 0, 0), evs(0, 0, 1, 0, 0, 0), TARGET, True)[0] == 3),
    ('510 in total: nothing grows, nothing passes', step(evs(3, 252, 0, 255, 0, 0), evs(1, 0, 0, 0, 0, 0), TARGET) == (None, False)),
    ('255 in a stat: it can\'t grow', step(evs(0, 255, 0, 0, 0, 0), evs(0, 1, 0, 0, 0, 0), evs(0, 255, 0, 0, 0, 0)) == (None, False)),
    ('room for only part of the gain: still checked', step(evs(0, 252, 0, 252, 0, 5), evs(2, 0, 0, 0, 0, 0), TARGET) == (None, True)),
]


def main():
    bad = 0
    for name, ok in CASES:
        bad += not ok
        print('%s %s' % ('ok  ' if ok else 'FAIL', name))
    print('%d cases, %d failed' % (len(CASES), bad))
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
