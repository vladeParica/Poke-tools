"""Lua tables for the bots, rendered from shared/gamedata/gamedata.json (ADR-0015).

build.py of the Train Bot and the Farm Bot insert train_tables() at their --@@DATA@@ marker.
The layout is the one the bots have always read: TT_MOVE, TT_SPEC, TT_EFF, EF, TT_LEARN,
TT_ITEMNAME, TT_ABILNAME, TT_SPECX.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gamedata import load  # noqa: E402

# Move effects the battle code looks up by name (EF.LEVEL_DAMAGE...)
EFFECTS_USED = [
    'LEVEL_DAMAGE', 'DRAGON_RAGE', 'SONICBOOM', 'SUPER_FANG', 'OHKO', 'EXPLOSION', 'DREAM_EATER', 'FOCUS_PUNCH',
    'FALSE_SWIPE', 'SNORE', 'COUNTER', 'MIRROR_COAT', 'BIDE', 'PSYWAVE', 'ENDEAVOR', 'FUTURE_SIGHT', 'RECHARGE',
    'MULTI_HIT', 'DOUBLE_HIT', 'TRIPLE_KICK', 'TWINEEDLE', 'RAZOR_WIND', 'SKY_ATTACK', 'SOLAR_BEAM', 'SKULL_BASH',
    'SEMI_INVULNERABLE', 'SPIT_UP', 'HIDDEN_POWER', 'RETURN', 'FRUSTRATION', 'LOW_KICK', 'FLAIL', 'MAGNITUDE',
    'PRESENT', 'ROLLOUT', 'FURY_CUTTER', 'ERUPTION', 'RECOIL', 'DOUBLE_EDGE', 'ABSORB', 'TRAP', 'RAMPAGE',
    'UPROAR', 'PURSUIT', 'REVENGE', 'SMELLINGSALT', 'FACADE', 'WEATHER_BALL', 'FAKE_OUT', 'VITAL_THROW',
    'ALWAYS_HIT', 'SUPERPOWER', 'OVERHEAT', 'TRI_ATTACK', 'FLINCH_HIT']
EV_ORDER = ('hp', 'atk', 'def', 'spe', 'spa', 'spd')          # the bots' memory order


def gender_ratio(text):
    """genderRatio as the game stores it: 0 male only, 254 female only, 255 genderless."""
    if text == 'MON_MALE':
        return 0
    if text == 'MON_FEMALE':
        return 254
    if text == 'MON_GENDERLESS':
        return 255
    pct = float(text[len('PERCENT_FEMALE('):-1])
    return min(254, int(pct * 255 / 100))


def train_tables(data=None):
    d = data or load()
    ty = {t: i for i, t in enumerate(d['types'])}
    mv = {m['const']: i for i, m in d['moves'].items()}
    ab = {a['const']: i for i, a in d['abilities'].items()}
    out = ['-- Generated from shared/gamedata/gamedata.json (tools/gamedata, ADR-0015): do not edit']
    out.append('local TT_MOVE = {')
    for i in sorted(d['moves']):
        if i == 0:
            continue
        m = d['moves'][i]
        out.append('[%d]={%d,%d,%d,%d,%d,%d,"%s"},' % (i, m['power'], ty[m['type']], m['accuracy'], d['effects'][m['effect']],
                                                     m['pp'], m['priority'], m['name'].replace('$', '').replace('"', '')))
    out.append('}')
    out.append('local TT_SPEC = {')
    for i in sorted(d['species']):
        s = d['species'][i]
        out.append('[%d]={%s},' % (i, ','.join(str(x) for x in [ty[s['types'][0]], ty[s['types'][1]]] +
                                                [s['ev'][k] for k in EV_ORDER])))
    out.append('}')
    trip = ['-1' if t is None else '%d,%d,%d' % (ty[t[0]], ty[t[1]], t[2]) for t in d['typeChart']]
    out.append('local TT_EFF = {' + ','.join(trip) + '}')
    out.append('local EF = {' + ', '.join('%s=%d' % (n, d['effects'][n]) for n in EFFECTS_USED if n in d['effects']) + '}')
    out.append('local TT_LEARN = {')
    for i in sorted(d['learnsets']):
        out.append('[%d]={%s},' % (i, ','.join('%d,%d' % (lv, mv[m]) for lv, m in d['learnsets'][i])))
    out.append('}')
    names = [(i, it['name']) for i, it in sorted(d['items'].items()) if i > 0 and it['const'] != 'NONE']
    out.append('local TT_ITEMNAME = {' + ','.join('[%d]="%s"' % (i, n.replace('"', '').replace('\\', '')) for i, n in names) + '}')
    out.append('local TT_ABILNAME = {' + ','.join('[%d]="%s"' % (i, a['name']) for i, a in sorted(d['abilities'].items())
                                                 if i > 0 and a['name']) + '}')
    out.append('local TT_SPECX = {' + ','.join('[%d]={%d,%d,%d}' % (i, ab[s['abilities'][0]], ab[s['abilities'][1]],
                                                                    gender_ratio(s['genderRatio']))
                                               for i, s in sorted(d['species'].items())) + '}')
    return '\n'.join(out) + '\n'


if __name__ == '__main__':
    sys.stdout.write(train_tables())
