"""Generate configurator/js/data.js from the bots' own Lua tables and example configs.

The configurator must accept exactly the names the bots accept, so every list here is
read from the bot sources instead of being typed by hand.
Usage:  python configurator/tools/build_data.py
"""
import glob
import json
import os
import re

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
OUT = os.path.join(ROOT, 'configurator', 'js', 'data.js')


def read(*parts):
    return open(os.path.join(ROOT, *parts), encoding='utf-8').read()


def lua_block(src, name):
    m = re.search(r'local ' + name + r'\s*=\s*\{', src)
    if not m:
        raise SystemExit('table not found: ' + name)
    i, depth = m.end(), 1
    while depth:
        c = src[i]
        if c == '{':
            depth += 1
        elif c == '}':
            depth -= 1
        i += 1
    return src[m.end():i - 1]


def lua_strings(block):
    block = re.sub(r'--[^\n]*', '', block)
    return re.findall(r'"([^"]*)"', block)


def lua_map(block):
    return dict(re.findall(r'(\w+)\s*=\s*"([^"]*)"', block))


def lua_index_map(block):
    return {k: int(v) for k, v in re.findall(r'(\w+)\s*=\s*(\d+)', block)}


def strip_comments(text):
    """Remove // comments outside strings (same rule as the bots' parser)."""
    out, i, n, in_str = [], 0, len(text), False
    while i < n:
        c = text[i]
        if in_str:
            out.append(c)
            if c == '\\':
                out.append(text[i + 1])
                i += 1
            elif c == '"':
                in_str = False
        elif c == '"':
            in_str = True
            out.append(c)
        elif text.startswith('//', i):
            while i < n and text[i] != '\n':
                i += 1
            continue
        else:
            out.append(c)
        i += 1
    return ''.join(out)


tables = read('shinybot', 'src', 'tables2.lua')
shiny = read('shinybot', 'src', 'bot_body.lua')
train_tables = read('trainbot', 'src', 'train_tables.lua')

natures = lua_strings(lua_block(tables, 'natureNamesList'))
species = lua_strings(lua_block(tables, 'speciesNamesList'))
dex = [int(x) for x in re.findall(r'\d+', re.sub(r'--[^\n]*', '', lua_block(tables, 'nationalDexList')))]
natures_es = lua_map(lua_block(shiny, 'NATURES_ES'))
hp_types = lua_strings(lua_block(shiny, 'HP_TYPES'))
hp_types_es = lua_index_map(lua_block(shiny, 'HP_TYPES_ES'))
modes = lua_strings(lua_block(shiny, 'MODES'))

moves = []
for name in re.findall(r'\[\d+\]=\{[^}]*?"([^"]*)"\}', lua_block(train_tables, 'TT_MOVE')):
    if name and name != '?':
        moves.append(name.title().replace("'S", "'s"))

items = []
for name in re.findall(r'\[\d+\]="([^"]*)"', lua_block(train_tables, 'TT_ITEMNAME')):
    if name and '{' not in name and '?' not in name:
        items.append(name.title().replace("'S", "'s"))

# EV yields: TT_SPEC[internal] = {type1, type2, hp, atk, def, spe, spa, spd}
ev_yield = {}
for idx, vals in re.findall(r'\[(\d+)\]=\{([^}]*)\}', lua_block(train_tables, 'TT_SPEC')):
    v = [int(x) for x in vals.split(',')]
    internal = int(idx)
    if internal + 1 > len(dex):
        continue
    national = dex[internal]
    if not 1 <= national <= len(species):
        continue
    hp, atk, de, spe, spa, spd = v[2:8]
    gains = {k: n for k, n in (('hp', hp), ('atk', atk), ('def', de), ('spa', spa), ('spd', spd), ('spe', spe)) if n}
    if gains:
        ev_yield[species[national - 1]] = gains

presets = {'shinybot': [], 'trainbot': [], 'farmbot': []}
for bot, path, label in (('shinybot', ('shinybot', 'FRLG_ShinyBot.json'), 'Por defecto'),
                         ('trainbot', ('trainbot', 'FRLG_TrainBot.json'), 'Por defecto'),
                         ('farmbot', ('farmbot', 'FRLG_FarmBot.json'), 'Por defecto')):
    presets[bot].append({'name': label, 'config': json.loads(strip_comments(read(*path)))})
for bot, pattern in (('trainbot', ('trainbot', 'examples', 'configs', '*.json')),
                     ('farmbot', ('farmbot', 'examples', '*.json'))):
    for f in sorted(glob.glob(os.path.join(ROOT, *pattern))):
        text = open(f, encoding='utf-8').read()
        first = re.search(r'//\s*EJEMPLO:\s*([^\n]*)', text)
        presets[bot].append({'name': first.group(1).strip() if first else os.path.basename(f),
                             'file': os.path.basename(f),
                             'config': json.loads(strip_comments(text))})

route_files = sorted(glob.glob(os.path.join(ROOT, 'trainbot', 'examples', 'routes', '*.txt')))
routes = [os.path.basename(f) for f in route_files]
# Contents too, so the configurator's route viewer can show the ready-made routes.
route_text = {os.path.basename(f): open(f, encoding='utf-8').read() for f in route_files}

data = {
    'natures': natures,
    'naturesEs': {v: k for k, v in natures_es.items()},
    'species': species,
    'moves': sorted(set(moves)),
    'items': sorted(set(items)),
    'hpTypes': hp_types,
    'hpTypesEs': {hp_types[i - 1]: k for k, i in hp_types_es.items()},
    'modes': modes,
    'evYield': ev_yield,
    'presets': presets,
    'routes': routes,
    'routeText': route_text,
}

body = json.dumps(data, ensure_ascii=False, indent=None, separators=(',', ':'))
with open(OUT, 'w', encoding='utf-8', newline='\n') as fh:
    fh.write('// Generated by configurator/tools/build_data.py from the bots\' Lua tables. Do not edit.\n')
    fh.write('window.PT = window.PT || {};\nwindow.PT.data = ' + body + ';\n')
print('data.js:', len(natures), 'natures,', len(species), 'species,', len(data['moves']), 'moves,',
      len(ev_yield), 'EV yields,', sum(len(p) for p in presets.values()), 'presets')
