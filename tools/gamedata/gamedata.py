"""The one extractor of FireRed / LeafGreen game data (ADR-0015).

Reads pret/pokefirered once and writes shared/gamedata/gamedata.json: species, moves, move
effects, type chart, level-up learnsets, TM/HM and tutor learnsets, evolutions, items and
abilities, with the pret commit they come from. The bots' build.py and the guide take what they
need from that file, so the C sources are parsed in one place only.

Usage:  python tools/gamedata/gamedata.py          (refresh the JSON from pret)
        python tools/gamedata/gamedata.py --check  (fail if the JSON is not what pret gives)
"""
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pret import ROOT, defines, entries, fetch, rd  # noqa: E402

OUT = os.path.join(ROOT, 'shared', 'gamedata', 'gamedata.json')
STAT_KEYS = ('hp', 'atk', 'def', 'spe', 'spa', 'spd')
BASE_FIELDS = {'hp': 'baseHP', 'atk': 'baseAttack', 'def': 'baseDefense', 'spe': 'baseSpeed',
               'spa': 'baseSpAttack', 'spd': 'baseSpDefense'}
EV_FIELDS = {'hp': 'evYield_HP', 'atk': 'evYield_Attack', 'def': 'evYield_Defense', 'spe': 'evYield_Speed',
             'spa': 'evYield_SpAttack', 'spd': 'evYield_SpDefense'}


def field(block, name):
    m = re.search(r'\.' + name + r'\s*=\s*([^,\n]+)', block)
    return m.group(1).strip() if m else None


def pair(block, name):
    m = re.search(r'\.' + name + r'\s*=\s*\{(\w+),\s*(\w+)\}', block)
    return [m.group(1), m.group(2)] if m else None


def extract():
    rev = fetch()
    SP = defines('include/constants/species.h', 'SPECIES_')
    MV = defines('include/constants/moves.h', 'MOVE_')
    EF = defines('include/constants/battle_move_effects.h', 'EFFECT_')
    AB = defines('include/constants/abilities.h', 'ABILITY_')
    TY = {k: v for k, v in defines('include/constants/pokemon.h', 'TYPE_').items() if v < 255 and not k.startswith('TYPE_MUL')}
    types = [k[5:] for k, _ in sorted(TY.items(), key=lambda kv: kv[1])]

    # national dex order (comments removed: they break the enum list)
    body = re.search(r'enum\s*\{(.*?)\}', rd('include/constants/pokedex.h'), re.S).group(1)
    body = re.sub(r'//[^\n]*|/\*.*?\*/', '', body, flags=re.S)
    nat = [x.strip()[len('NATIONAL_DEX_'):] for x in body.split(',') if x.strip().startswith('NATIONAL_DEX_')]
    natnum = {name: i for i, name in enumerate(nat)}
    sp_names = dict(re.findall(r'\[SPECIES_(\w+)\]\s*=\s*_\("([^"]*)"\)', rd('src/data/text/species_names.h')))
    mv_names = dict(re.findall(r'\[MOVE_(\w+)\]\s*=\s*_\("([^"]*)"\)', rd('src/data/text/move_names.h')))
    ab_names = dict(re.findall(r'\[ABILITY_(\w+)\]\s*=\s*_\("([^"]*)"\)', rd('src/data/text/abilities.h')))

    species = {}
    for const, b in entries('src/data/pokemon/species_info.h', 'SPECIES_'):
        if 'SPECIES_' + const not in SP or not pair(b, 'types'):
            continue
        species[SP['SPECIES_' + const]] = {
            'const': const, 'name': sp_names.get(const, const), 'dex': natnum.get(const, 0),
            'types': [t[5:] for t in pair(b, 'types')],
            'base': {k: int(field(b, f)) for k, f in BASE_FIELDS.items()},
            'ev': {k: int(field(b, f)) for k, f in EV_FIELDS.items()},
            'catchRate': int(field(b, 'catchRate')), 'expYield': int(field(b, 'expYield')),
            'growthRate': field(b, 'growthRate'), 'genderRatio': field(b, 'genderRatio'),
            'eggGroups': [e[len('EGG_GROUP_'):] for e in pair(b, 'eggGroups')],
            'abilities': [a[len('ABILITY_'):] for a in pair(b, 'abilities')],
            'items': [field(b, 'itemCommon')[5:], field(b, 'itemRare')[5:]],
        }
    moves = {}
    for const, b in entries('src/data/battle_moves.h', 'MOVE_'):
        moves[MV['MOVE_' + const]] = {
            'const': const, 'name': mv_names.get(const, '?'),
            'power': int(field(b, 'power')), 'type': field(b, 'type')[5:], 'accuracy': int(field(b, 'accuracy')),
            'pp': int(field(b, 'pp')), 'effect': field(b, 'effect')[len('EFFECT_'):], 'priority': int(field(b, 'priority')),
        }
    # type chart: (attacking type, defending type, multiplier x10) in game order; None = the
    # TYPE_FORESIGHT / TYPE_ENDTABLE separators the game uses to stop or skip
    eff = re.search(r'gTypeEffectiveness\[\d+\]\s*=\s*\{(.*?)\};', rd('src/battle_main.c'), re.S).group(1)
    toks = [x.strip() for x in eff.replace('\n', ' ').split(',') if x.strip()]
    mul = {'TYPE_MUL_NO_EFFECT': 0, 'TYPE_MUL_NOT_EFFECTIVE': 5, 'TYPE_MUL_SUPER_EFFECTIVE': 20}
    chart = []
    for i in range(0, len(toks), 3):
        a, d, c = toks[i:i + 3]
        chart.append(None if a in ('TYPE_FORESIGHT', 'TYPE_ENDTABLE') else [a[5:], d[5:], mul[c]])
    # level-up learnsets
    sets = {}
    for m in re.finditer(r'static const u16 (s\w+LevelUpLearnset)\[\]\s*=\s*\{(.*?)\};',
                         rd('src/data/pokemon/level_up_learnsets.h'), re.S):
        sets[m.group(1)] = [[int(lv), mv] for lv, mv in re.findall(r'LEVEL_UP_MOVE\(\s*(\d+),\s*MOVE_(\w+)\)', m.group(2))]
    learnsets = {}
    for const, label in re.findall(r'\[SPECIES_(\w+)\]\s*=\s*(s\w+LevelUpLearnset)',
                                   rd('src/data/pokemon/level_up_learnset_pointers.h')):
        if SP.get('SPECIES_' + const, 0) > 0:
            learnsets[SP['SPECIES_' + const]] = sets[label]
    # TM/HM
    tm, tmlearn = {}, {}
    parts = re.split(r'\[SPECIES_(\w+)\]\s*=', rd('src/data/pokemon/tmhm_learnsets.h'))
    for const, body in zip(parts[1::2], parts[2::2]):
        found = re.findall(r'TMHM\(((?:TM|HM))(\d\d)_(\w+)\)', body)
        for kind, num, mv in found:
            tm[kind + num] = mv
        if 'SPECIES_' + const in SP:
            tmlearn[SP['SPECIES_' + const]] = [kind + num for kind, num, _ in found]
    # move tutors (the three starter moves are taught at Cape Brink, see field_specials.c)
    tl = rd('src/data/pokemon/tutor_learnsets.h')
    tutor_moves = re.findall(r'\[TUTOR_MOVE_\w+\]\s*=\s*MOVE_(\w+)', tl)
    tutorlearn = {}
    for const, body in re.findall(r'\[SPECIES_(\w+)\]\s*=\s*([^\[]*?),\s*\n', tl, re.S):
        if 'SPECIES_' + const in SP:
            tutorlearn[SP['SPECIES_' + const]] = re.findall(r'TUTOR\(MOVE_(\w+)\)', body)
    # evolutions: [method, parameter as written, target]
    evo = {}
    for m in re.finditer(r'\[SPECIES_(\w+)\]\s*=\s*\{(\{.*?\})\}', rd('src/data/pokemon/evolution.h'), re.S):
        evo[SP['SPECIES_' + m.group(1)]] = [[meth, par, tgt] for meth, par, tgt in
                                             re.findall(r'\{EVO_(\w+),\s*(\w+),\s*SPECIES_(\w+)\}', m.group(2))]
    # the position in items.json is the item id (unused ids are ITEM_NONE entries)
    items = {}
    for i, x in enumerate(json.loads(rd('src/data/items.json'))['items']):
        items[i] = {
            'const': x['itemId'][5:], 'name': x['english'], 'price': x['price'], 'pocket': x['pocket'],
            'holdEffect': x['holdEffect'], 'importance': x['importance']}
    abilities = {v: {'const': k[8:], 'name': ab_names.get(k[8:])} for k, v in sorted(AB.items(), key=lambda kv: kv[1])
                 if not k.endswith('_COUNT')}
    return {
        'source': {'repo': 'https://github.com/pret/pokefirered', 'commit': rev},
        'types': types,
        'effects': {k[len('EFFECT_'):]: v for k, v in EF.items()},
        'species': species, 'moves': moves, 'typeChart': chart, 'learnsets': learnsets,
        'tm': tm, 'tmLearnsets': tmlearn, 'tutorMoves': tutor_moves, 'tutorLearnsets': tutorlearn,
        'evolutions': evo, 'items': items, 'abilities': abilities,
    }


def dump(data):
    """Stable JSON: integer keys in numeric order, one record per line (small diffs)."""
    def ordered(d):
        return {str(k): d[k] for k in sorted(d)} if all(isinstance(k, int) for k in d) else d
    out = {k: ordered(v) if isinstance(v, dict) else v for k, v in data.items()}
    return json.dumps(out, ensure_ascii=False, indent=1, sort_keys=False) + '\n'


def load():
    """The committed game data, with the numeric keys turned back into integers."""
    with open(OUT, encoding='utf-8') as f:
        data = json.load(f)
    for k, v in data.items():
        if isinstance(v, dict) and v and all(x.lstrip('-').isdigit() for x in v):
            data[k] = {int(x): y for x, y in v.items()}
    return data


def main():
    text = dump(extract())
    if '--check' in sys.argv:
        with open(OUT, encoding='utf-8') as f:
            ok = f.read() == text
        print('gamedata.json is up to date' if ok else 'gamedata.json differs from pret: run tools/gamedata/gamedata.py')
        sys.exit(0 if ok else 1)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, 'w', encoding='utf-8', newline='\n') as f:
        f.write(text)
    d = json.loads(text)
    print('gamedata.json: %d species, %d moves, %d items, pret %s' % (
        len(d['species']), len(d['moves']), len(d['items']), d['source']['commit'][:7]))


if __name__ == '__main__':
    main()
