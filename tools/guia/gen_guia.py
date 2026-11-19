"""Generates the FireRed / LeafGreen reference guide (docs/guia/) from game data.

Game data comes only from the pret/pokefirered decompilation. Spanish (and English display)
names come from the PokeAPI CSV tables, matched by national number, move/ability id or item
identifier. Nothing is typed by hand: a value that can't be read from those sources is
written as "sin verificar".

pret is read through tools/gamedata/pret.py (a sparse clone in trainbot/tools/pret_cache, shared
with the game data extractor, ADR-0015); the PokeAPI tables are downloaded to
trainbot/tools/pret_cache/pokeapi. Later runs reuse both.

Usage:  python tools/guia/gen_guia.py            (writes docs/guia/)
        python tools/guia/gen_guia.py --check    (also prints the verification report)
"""
import csv
import json
import os
import re
import sys
import urllib.request
from collections import defaultdict

# pret access is shared with the game data extractor (ADR-0015)
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'gamedata'))
import gamedata  # noqa: E402
import pret  # noqa: E402
from pret import CACHE, PRET, ROOT, asm_version, c_version, defines, rd  # noqa: E402,F401

PAPI = os.path.join(CACHE, 'pokeapi')
OUT = os.path.join(ROOT, 'docs', 'guia')
PAPI_URL = 'https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/'
PAPI_FILES = ['pokemon_species_names', 'move_names', 'item_names', 'items', 'ability_names', 'type_names',
              'types']
ES, EN = '7', '9'               # PokeAPI language ids
VERS = ('FR', 'LG')
VER_NAME = {'FR': 'Rojo Fuego', 'LG': 'Verde Hoja'}
NV = 'sin verificar'


# ------------------------------------------------------------------ sources
def fetch():
    rev = pret.fetch()
    os.makedirs(PAPI, exist_ok=True)
    for f in PAPI_FILES:
        p = os.path.join(PAPI, f + '.csv')
        if not os.path.exists(p):
            print('downloading PokeAPI', f)
            urllib.request.urlretrieve(PAPI_URL + f + '.csv', p)
    return rev


def csv_rows(name):
    with open(os.path.join(PAPI, name + '.csv'), encoding='utf-8') as f:
        return list(csv.DictReader(f))


def norm(s):
    s = s.lower().replace('é', 'e').replace('♀', 'f').replace('♂', 'm')
    return re.sub(r'[^a-z0-9]', '', s)


# ------------------------------------------------------------------ data model
class G:
    pass


def load():
    g = G()
    g.SP = defines('include/constants/species.h', 'SPECIES_')
    g.MV = defines('include/constants/moves.h', 'MOVE_')
    g.AB = defines('include/constants/abilities.h', 'ABILITY_')
    g.TRN = defines('include/constants/opponents.h', 'TRAINER_')
    g.TC = defines('include/constants/trainers.h', 'TRAINER_CLASS_')
    # national dex order
    body = re.search(r'enum\s*\{(.*?)\}', rd('include/constants/pokedex.h'), re.S).group(1)
    body = re.sub(r'//[^\n]*|/\*.*?\*/', '', body, flags=re.S)
    nat = [x.strip() for x in body.split(',') if x.strip().startswith('NATIONAL_DEX_')]
    g.nat = {n[len('NATIONAL_DEX_'):]: i for i, n in enumerate(nat)}          # OLD_NAME -> number
    # species, moves, learnsets, TM/HM, tutors and evolutions: the shared game data (ADR-0015)
    D = gamedata.load()
    const = {i: s['const'] for i, s in D['species'].items()}
    g.sp_name = {s['const']: s['name'] for s in D['species'].values()}
    g.mv_name = {m['const']: m['name'] for m in D['moves'].values()}
    g.ab_name = {a['const']: a['const'] for a in D['abilities'].values()}
    g.info = {}
    for s in D['species'].values():
        b, e = s['base'], s['ev']
        g.info[s['const']] = dict(
            stats=[b['hp'], b['atk'], b['def'], b['spa'], b['spd'], b['spe']],
            ev=[e['hp'], e['atk'], e['def'], e['spa'], e['spd'], e['spe']],
            types=list(s['types']), catch=s['catchRate'], exp=s['expYield'], growth=s['growthRate'],
            gender=s['genderRatio'], abilities=list(s['abilities']), eggs=list(s['eggGroups']), items=list(s['items']))
    g.moves = {m['const']: dict(power=m['power'], type=m['type'], acc=m['accuracy'], pp=m['pp'],
                                effect='EFFECT_' + m['effect']) for m in D['moves'].values()}
    g.lvl = {const[i]: [tuple(x) for x in v] for i, v in D['learnsets'].items() if i in const}
    g.tm = dict(D['tm'])
    g.tmlearn = defaultdict(list, {const[i]: list(v) for i, v in D['tmLearnsets'].items() if i in const})
    g.tutor_moves = list(D['tutorMoves'])
    g.tutorlearn = defaultdict(list, {const[i]: list(v) for i, v in D['tutorLearnsets'].items() if i in const})
    g.evo = defaultdict(list)
    g.prev = {}
    for i, evs in D['evolutions'].items():
        for meth, par, tgt in evs:
            g.evo[const[i]].append(('EVO_' + meth, par, tgt))
            g.prev[tgt] = const[i]
    # evolution methods the FR/LG code actually checks (cases that never set targetSpecies are disabled)
    pc = rd('src/pokemon.c')
    g.evo_off = set()
    for m in re.finditer(r'case (EVO_\w+):(.*?)break;', pc, re.S):
        code = re.sub(r'/\*.*?\*/', '', m.group(2), flags=re.S)
        if 'targetSpecies' not in code:
            g.evo_off.add(m.group(1))
    # items (same fields as items.json: english name, price)
    g.item = {it['const']: {'itemId': 'ITEM_' + it['const'], 'english': it['name'], 'price': it['price'],
                            'pocket': it['pocket'], 'holdEffect': it['holdEffect']} for it in D['items'].values()}
    # TMs are consumed, HMs are not (party_menu.c removes the item only below ITEM_HM01)
    g.tm_consumed = bool(re.search(r'if \(gSpecialVar_ItemId < ITEM_HM01\)\s*RemoveBagItem', rd('src/party_menu.c')))
    # trainers
    parties = {}
    for m in re.finditer(r'static const struct (\w+) (sParty_\w+)\[\]\s*=\s*\{(.*?)\n\};', rd('src/data/trainer_parties.h'), re.S):
        mons = []
        for mb in re.finditer(r'\{(.*?)\n    \}', m.group(3), re.S):
            b = mb.group(1)
            mv = re.search(r'\.moves\s*=\s*\{([^}]*)\}', b)
            it = re.search(r'\.heldItem\s*=\s*ITEM_(\w+)', b)
            mons.append(dict(lvl=int(re.search(r'\.lvl\s*=\s*(\d+)', b).group(1)),
                             species=re.search(r'\.species\s*=\s*SPECIES_(\w+)', b).group(1),
                             iv=int(re.search(r'\.iv\s*=\s*(\d+)', b).group(1)),
                             moves=[x.strip()[5:] for x in mv.group(1).split(',') if x.strip() not in ('', 'MOVE_NONE')] if mv else None,
                             item=it.group(1) if it and it.group(1) != 'NONE' else None))
        parties[m.group(2)] = mons
    g.trainers = {}
    for m in re.finditer(r'\[TRAINER_(\w+)\]\s*=\s*\{(.*?)\n    \}', rd('src/data/trainers.h'), re.S):
        b = m.group(2)
        pm = re.search(r'\.party\s*=\s*\w+\((sParty_\w+)\)', b)
        if not pm:
            continue
        g.trainers[m.group(1)] = dict(cls=re.search(r'\.trainerClass\s*=\s*TRAINER_CLASS_(\w+)', b).group(1),
                                      name=re.search(r'\.trainerName\s*=\s*_\("([^"]*)"\)', b).group(1),
                                      double=('TRUE' in re.search(r'\.doubleBattle\s*=\s*(\w+)', b).group(1)),
                                      items=[x[5:] for x in re.findall(r'ITEM_\w+', re.search(r'\.items\s*=\s*\{([^}]*)\}', b).group(1)) if x != 'ITEM_NONE'],
                                      party=parties.get(pm.group(1), []))
    g.money = {m.group(1): int(m.group(2)) for m in re.finditer(r'\{TRAINER_CLASS_(\w+),\s*(\d+)\}', rd('src/battle_main.c'))}
    g.money_formula = re.search(r'moneyReward = (4 \* lastMonLevel[^;]*);', rd('src/battle_script_commands.c')).group(1)
    # region map names and maps
    g.mapsec = {s['id']: s.get('name', '') for s in json.loads(rd('src/data/region_map/region_map_sections.json'))['map_sections']}
    g.maps = {}
    for d in sorted(os.listdir(os.path.join(PRET, 'data', 'maps'))):
        p = os.path.join(PRET, 'data', 'maps', d, 'map.json')
        if os.path.exists(p):
            with open(p, encoding='utf-8') as f:
                g.maps[d] = json.load(f)
    g.map_by_id = {m['id']: d for d, m in g.maps.items()}
    g.wild = json.loads(rd('src/data/wild_encounters.json'))
    # roamers (species chosen from the starter) and level
    ro = rd('src/roamer.c')
    g.roamers = re.findall(r'case SPECIES_(\w+):\\?\s*a = SPECIES_(\w+);', ro)
    dflt = re.search(r'default:\\?\s*a = SPECIES_(\w+);', ro)
    g.roamer_default = dflt.group(1) if dflt else None
    lv = re.search(r'ROAMER->level = (\d+);', ro)
    g.roamer_lvl = int(lv.group(1)) if lv else None
    g.trades = {v: [] for v in VERS}
    for v in VERS:
        t = c_version(rd('src/data/ingame_trades.h'), v)
        for m in re.finditer(r'\[INGAME_TRADE_(\w+)\]\s*=\s*\{(.*?)\n    \}', t, re.S):
            b = m.group(2)
            g.trades[v].append(dict(id=m.group(1), species=re.search(r'\.species\s*=\s*SPECIES_(\w+)', b).group(1),
                                    wants=re.search(r'\.requestedSpecies\s*=\s*SPECIES_(\w+)', b).group(1),
                                    ot=re.search(r'\.otName\s*=\s*_\("([^"]*)"\)', b).group(1)))
    cb = rd('src/field_specials.c')
    g.capebrink = re.findall(r'SPECIES_(\w+)', re.search(r'sCapeBrinkCompatibleSpecies\[\]\s*=\s*\{(.*?)\};', cb, re.S).group(1))
    fr = re.search(r'MON_DATA_FRIENDSHIP\)\s*!=\s*(\d+)', cb)
    g.capebrink_friend = int(fr.group(1)) if fr else None
    names(g)
    for v in VERS:
        scripts(g, v)
    return g


# ------------------------------------------------------------------ names (PokeAPI)
def names(g):
    sp_es, sp_en = {}, {}
    for r in csv_rows('pokemon_species_names'):
        if r['local_language_id'] == ES:
            sp_es[int(r['pokemon_species_id'])] = r['name']
        elif r['local_language_id'] == EN:
            sp_en[int(r['pokemon_species_id'])] = r['name']
    mv_es, mv_en = {}, {}
    for r in csv_rows('move_names'):
        (mv_es if r['local_language_id'] == ES else mv_en if r['local_language_id'] == EN else {})[int(r['move_id'])] = r['name']
    ab_es, ab_en = {}, {}
    for r in csv_rows('ability_names'):
        (ab_es if r['local_language_id'] == ES else ab_en if r['local_language_id'] == EN else {})[int(r['ability_id'])] = r['name']
    tid = {r['identifier']: r['id'] for r in csv_rows('types')}
    ty_es, ty_en = {}, {}
    for r in csv_rows('type_names'):
        (ty_es if r['local_language_id'] == ES else ty_en if r['local_language_id'] == EN else {})[r['type_id']] = r['name']
    iid = {r['identifier']: r['id'] for r in csv_rows('items')}
    it_es, it_en = {}, {}
    for r in csv_rows('item_names'):
        (it_es if r['local_language_id'] == ES else it_en if r['local_language_id'] == EN else {})[r['item_id']] = r['name']
    en_to_id = {norm(v): k for k, v in it_en.items()}
    g.unmatched = defaultdict(list)

    g.N = {}
    for sp in g.info:
        num = g.nat.get(sp)
        en = sp_en.get(num)
        if not num or not en or norm(en) != norm(g.sp_name.get(sp, '')):
            g.unmatched['species'].append(sp)
            g.N['sp', sp] = (g.sp_name.get(sp, sp).title(), None)
        else:
            g.N['sp', sp] = (en, sp_es.get(num))
    for mv in g.moves:
        i = g.MV.get('MOVE_' + mv)
        en = mv_en.get(i)
        if not i or not en:
            g.unmatched['moves'].append(mv)
            g.N['mv', mv] = (g.mv_name.get(mv, mv).title(), None)
        else:
            if norm(en) != norm(g.mv_name.get(mv, '')):
                g.unmatched['move names that differ (same id)'].append('%s / %s' % (g.mv_name.get(mv), en))
            g.N['mv', mv] = (en, mv_es.get(i))
    for ab, i in g.AB.items():
        ab = ab[8:]
        en = ab_en.get(i)
        g.N['ab', ab] = (en, ab_es.get(i)) if en else (g.ab_name.get(ab, ab).title(), None)
    for t in ['NORMAL', 'FIGHTING', 'FLYING', 'POISON', 'GROUND', 'ROCK', 'BUG', 'GHOST', 'STEEL', 'FIRE', 'WATER',
              'GRASS', 'ELECTRIC', 'PSYCHIC', 'ICE', 'DRAGON', 'DARK', 'MYSTERY']:
        i = tid.get(t.lower())
        g.N['ty', t] = (ty_en.get(i), ty_es.get(i)) if i else (t.title(), None)
    ident = {v: k for k, v in iid.items()}
    g.item_ident = {}                               # pret item -> PokeAPI identifier (for its icon)
    for it, d in g.item.items():
        i = iid.get(it.lower().replace('_', '-')) or en_to_id.get(norm(d['english']))
        if i:
            g.item_ident[it] = ident[i]
            g.N['it', it] = (it_en.get(i), it_es.get(i))
        else:
            g.unmatched['items'].append(it)
            g.N['it', it] = (d['english'].title(), None)
    g.N['it', 'COINS'] = ('Coins', 'Fichas')       # hidden Game Corner coins are not an item


def nm(g, kind, key):
    """'Spanish (English)', or the English name and 'sin verificar' if there is no Spanish one."""
    en, es = g.N.get((kind, key), (key, None))
    if not es:
        return '%s (nombre en español %s)' % (en, NV)
    return es if norm(es) == norm(en) else '%s (%s)' % (es, en)


def short(g, kind, key):
    en, es = g.N.get((kind, key), (key, None))
    return es or en


def dex(g, sp):
    return g.nat.get(sp, 0)


def slug(g, sp):
    return '%03d-%s' % (dex(g, sp), re.sub(r'[^a-z0-9]+', '-', g.N['sp', sp][0].lower()).strip('-'))


def splink(g, sp, base='pokemon/'):
    return '[%s](%s%s.md)' % (nm(g, 'sp', sp), base, slug(g, sp))


# ------------------------------------------------------------------ sprites (linked, never stored)
# Images come from the PokeAPI sprites repository and are only linked, like the configurator
# backgrounds (ADR-0013): the browser loads them when the page is viewed. Every URL is checked
# once (cached in pret_cache/pokeapi/sprites.json); one that doesn't exist gets no image.
SPR = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/'


def poke_url(g, sp, shiny=False):
    return SPR + 'pokemon/versions/generation-iii/firered-leafgreen/%s%d.png' % ('shiny/' if shiny else '', dex(g, sp))


def item_urls(g, it):
    """Candidate icons of an item, best first: TMs and HMs use the disc of their move's type."""
    if it in g.tm:
        t = g.moves[g.tm[it]]['type'].lower()
        kind = it[:2].lower()
        return [SPR + 'items/%s-%s.png' % (kind, t), SPR + 'items/%s-normal.png' % kind]
    return [SPR + 'items/%s.png' % g.item_ident[it]] if it in g.item_ident else []


def check_sprites(g):
    import concurrent.futures
    path = os.path.join(PAPI, 'sprites.json')
    try:
        with open(path, encoding='utf-8') as f:
            cache = json.load(f)
    except (OSError, ValueError):
        cache = {}
    urls = {poke_url(g, s, sh) for s in g.info if dex(g, s) for sh in (False, True)}
    urls |= {u for it in list(g.item) + list(g.tm) for u in item_urls(g, it)}
    todo = sorted(u for u in urls if u not in cache)

    def head(u):
        try:
            req = urllib.request.Request(u, method='HEAD')
            with urllib.request.urlopen(req, timeout=30) as r:
                return u, r.status == 200
        except urllib.error.HTTPError as e:
            return u, False if e.code == 404 else None
        except OSError:
            return u, None                     # offline: unknown, not cached, no image this time
    if todo:
        print('checking %d sprite URLs...' % len(todo))
        with concurrent.futures.ThreadPoolExecutor(16) as ex:
            for u, ok in ex.map(head, todo):
                if ok is not None:
                    cache[u] = ok
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(cache, f, indent=0, sort_keys=True)
    g.sprite_ok = {u for u, ok in cache.items() if ok}


def img(url, alt, size):
    return '<img src="%s" alt="%s" width="%d" height="%d">' % (url, alt.replace('"', ''), size, size)


def pimg(g, sp, size=32, shiny=False):
    u = poke_url(g, sp, shiny)
    return img(u, short(g, 'sp', sp) + (' shiny' if shiny else ''), size) if u in g.sprite_ok else ''


def iimg(g, it, size=24):
    u = next((u for u in item_urls(g, it) if u in g.sprite_ok), None)
    return img(u, short(g, 'it', it), size) if u else ''


def ipre(g, it, size=24):
    """Icon followed by a space, or nothing."""
    i = iimg(g, it, size)
    return i + ' ' if i else ''


def ppre(g, sp, size=32):
    i = pimg(g, sp, size)
    return i + ' ' if i else ''


def mv_anchor(mv):
    return 'mv-' + mv.lower().replace('_', '-')


def mvlink(g, mv, base=''):
    return '[%s](%sataques.md#%s)' % (nm(g, 'mv', mv), base, mv_anchor(mv))


def map_name(g, mapdir):
    m = g.maps.get(mapdir)
    if not m:
        return mapdir
    sec = g.mapsec.get(m.get('region_map_section'), '')
    sec_t = sec.title().replace("'S", "'s") if sec else ''

    def words(ps):
        return ' '.join(re.sub(r'(?<=[a-z])(?=[A-Z0-9])|(?<=[A-Z])(?=[A-Z][a-z])', ' ', p) for p in ps)
    parts = mapdir.split('_')
    if not sec_t:
        return words(parts) or mapdir
    # "OneIsland_KindleRoad_EmberSpa" in section "EMBER SPA" -> "Ember Spa (One Island · Kindle Road)"
    at = next((i for i, p in enumerate(parts) if norm(p) == norm(sec)), None)
    if at is None:
        rest = words(parts)
        return '%s · %s' % (sec_t, rest) if rest else sec_t
    before, after = parts[:at], parts[at + 1:]
    s = sec_t + (' · ' + words(after) if after else '')
    return s + (' (%s)' % ' · '.join(words([p]) for p in before) if before else '')


def human(label):
    s = label.split('EventScript_')[-1]
    return re.sub(r'(?<=[a-z])(?=[A-Z0-9])', ' ', s)


# ------------------------------------------------------------------ event scripts
END_CMDS = ('end', 'return', 'goto', 'releaseend', 'step_end', 'warp', 'warpsilent', 'endtrainerbattle')


def scripts(g, ver):
    """Walks every event script of one version from each map's objects, signs and triggers.
    Collects items on the floor, hidden items, gifts, marts, prizes, gift/static Pokemon,
    trades and trainer battles, each with the map and the object that starts it."""
    files = []
    for d in g.maps:
        p = os.path.join('data', 'maps', d, 'scripts.inc')
        if os.path.exists(os.path.join(PRET, p)):
            files.append((d, p))
    for f in sorted(os.listdir(os.path.join(PRET, 'data', 'scripts'))):
        if f.endswith('.inc'):
            files.append((None, os.path.join('data', 'scripts', f)))
    files.append((None, os.path.join('data', 'event_scripts.s')))
    labels, order, owner = {}, [], {}
    for mapdir, p in files:
        text = asm_version(rd(p), ver)
        alias = dict(re.findall(r'^\.equ\s+(\w+),\s*(\w+)', text, re.M))
        cur = None
        for line in text.split('\n'):
            m = re.match(r'^(\w+)::?\s*$', line.strip())
            if m and not line.startswith((' ', '\t')):
                cur = m.group(1)
                labels[cur] = []
                order.append(cur)
                owner[cur] = mapdir
                continue
            if cur and line.strip() and not line.strip().startswith('@'):
                s = line.strip()
                for a, b in alias.items():
                    s = re.sub(r'\b%s\b' % a, b, s)
                labels[cur].append(s)
    nxt = {a: b for a, b in zip(order, order[1:]) if owner[a] == owner[b]}
    edges = {}
    for lb, lines in labels.items():
        e = set()
        for s in lines:
            for tok in re.findall(r'\b\w+\b', s.split(' ', 1)[1] if ' ' in s else ''):
                if tok in labels and tok != lb:
                    e.add(tok)
        cmds = [x for x in lines if not x.startswith('.')]        # .byte/.2byte are data, not code
        last = cmds[-1].split()[0] if cmds else 'end'
        if lb in nxt and last not in END_CMDS and not lb.endswith('_MapScripts'):
            e.add(nxt[lb])
        edges[lb] = e
    # entry points: object events, signs, coordinate triggers and the map script tables
    entries = []
    for d, m in g.maps.items():
        for i, o in enumerate(m.get('object_events') or []):
            if o.get('script') in labels:
                entries.append((d, o['script'], o))
        for o in (m.get('bg_events') or []) + (m.get('coord_events') or []):
            if o.get('script') in labels:
                entries.append((d, o['script'], o))
        ms = d + '_MapScripts'
        if ms in labels:
            entries.append((d, ms, None))
    rank = {}
    for d, start, obj in entries:
        rank[d, start] = 0 if obj and 'graphics_id' in obj else (1 if obj else 2)
    reach = defaultdict(list)          # label -> [(map, entry label, object)]
    for d, start, obj in entries:
        seen, stack = {start}, [start]
        while stack:
            x = stack.pop()
            for y in edges.get(x, ()):
                # never walk into another map's own scripts: they belong to that map
                if owner.get(y) not in (None, d) or y in seen:
                    continue
                seen.add(y); stack.append(y)
        for x in seen:
            reach[x].append((d, start, obj))
    R = G()
    R.ground, R.hidden, R.gifts, R.marts, R.coins, R.mons, R.trades, R.battles, R.tutors = ([] for _ in range(9))
    case_species = {}
    for lb, lines in labels.items():
        for s in lines:
            m = re.match(r'case SPECIES_(\w+),\s*(\w+)', s)
            if m:
                case_species[m.group(2)] = m.group(1)
    file_vars = defaultdict(lambda: defaultdict(set))       # owner -> var -> species
    for lb, lines in labels.items():
        for s in lines:
            m = re.match(r'setvar (\w+),\s*SPECIES_(\w+)', s)
            if m:
                file_vars[owner[lb]][m.group(1)].add(m.group(2))
    # items held in a variable ("setvar VAR_0x8009, ITEM_TM16" ... "additem VAR_0x8009"):
    # the labels of the same map that set it and lead to the label that gives it
    item_setters = defaultdict(list)                         # (owner, var) -> [(label, item, {var: item})]
    for lb, lines in labels.items():
        sets = dict(re.findall(r'^setvar (VAR_\w+),\s*ITEM_(\w+)$', '\n'.join(lines), re.M))
        for var, it in sets.items():
            item_setters[owner[lb], var].append((lb, it, sets))

    def leads_to(a, b):
        seen, stack = {a}, [a]
        while stack:
            x = stack.pop()
            if x == b:
                return True
            for y in edges.get(x, ()):
                if owner.get(y) == owner.get(a) and y not in seen:
                    seen.add(y); stack.append(y)
        return False
    for lb, lines in labels.items():
        where = reach.get(lb) or ([(owner[lb], lb, None)] if owner[lb] else [])
        if not where:
            continue
        # per map keep only the best kind of entry (a person beats a trigger, a trigger the map script)
        best = {}
        for d, start, obj in where:
            best[d] = min(best.get(d, 9), rank.get((d, start), 0))
        where = [w for w in where if rank.get((w[0], w[1]), 0) == best[w[0]]]
        for s in lines:
            cmd, _, args = s.partition(' ')
            a = [x.strip() for x in args.split(',')]
            for d, start, obj in where:
                who = human(start)
                if cmd == 'finditem':
                    xy = (obj['x'], obj['y']) if obj else None
                    R.ground.append(dict(map=d, item=a[0][5:], qty=int(a[1]) if len(a) > 1 and a[1].isdigit() else 1, xy=xy))
                elif cmd in ('giveitem', 'giveitem_msg', 'additem'):
                    it = next((x for x in a if x.startswith('ITEM_')), None)
                    if it:
                        i = a.index(it)
                        q = int(a[i + 1]) if len(a) > i + 1 and a[i + 1].isdigit() else 1
                        R.gifts.append(dict(map=d, item=it[5:], qty=q, who=who, label=lb))
                    elif a and a[0].startswith('VAR_') and 'GameCorner_PrizeRoom' not in (owner[lb] or ''):
                        # (coin prizes are listed from their price instead)
                        # what you pay: an item variable this label removes, money the setter checks,
                        # or berry powder (Script_TakeBerryPowder takes the amount the setter stores)
                        taken = [re.match(r'removeitem (VAR_\w+)', x).group(1) for x in lines if re.match(r'removeitem VAR_', x)]
                        powder = any('Script_TakeBerryPowder' in x for x in lines)
                        for setter, item, sets in item_setters.get((owner[lb], a[0]), []):
                            if not leads_to(setter, lb):
                                continue
                            sl = labels[setter]
                            swap = [sets[v] for v in taken if v in sets]
                            cost = next((int(re.match(r'checkmoney (\d+)', x).group(1)) for x in sl if re.match(r'checkmoney \d+', x)), None)
                            pw = next((int(re.match(r'setvar VAR_\w+,\s*(\d+)$', x).group(1)) for x in sl
                                       if powder and re.match(r'setvar VAR_\w+,\s*\d+$', x)), None)
                            R.gifts.append(dict(map=d, item=item, qty=1, who=who, label=lb, swap=swap[0] if swap else None,
                                                money=cost, powder=pw))
                elif cmd == 'pokemart':
                    R.marts.append(dict(map=d, label=a[0], who=who))
                elif cmd in ('givemon', 'giveegg'):
                    lvl = int(a[1]) if len(a) > 1 and a[1].isdigit() else None
                    one = None
                    if a[0].startswith('SPECIES_'):
                        sps = [a[0][8:]]
                    elif lb in case_species:
                        sps = [case_species[lb]]
                    else:      # a variable: every species the map sets it to (you get one of them)
                        sps = sorted(file_vars[owner[lb]].get(a[0], ()))
                        one = True
                    for sp in sps:
                        R.mons.append(dict(map=d, species=sp, lvl=lvl, how='huevo' if cmd == 'giveegg' else 'regalo',
                                           who=None if one else who, choice=[x for x in sps if x != sp] if one else None))
                elif cmd in ('setwildbattle', 'seteventmon'):
                    R.mons.append(dict(map=d, species=a[0][8:], lvl=int(a[1]), how='estático', who=who))
                elif cmd == 'setvar' and a[0] == 'VAR_0x8008' and a[1].startswith('INGAME_TRADE_'):
                    R.trades.append(dict(map=d, id=a[1][len('INGAME_TRADE_'):], who=who))
                elif cmd.startswith('trainerbattle') and a and a[0].startswith('TRAINER_'):
                    R.battles.append(dict(map=d, trainer=a[0][8:], who=who, label=lb))
                elif cmd == 'setvar' and a[0] == 'VAR_0x8005' and a[1].startswith('MOVETUTOR_'):
                    R.tutors.append(dict(map=d, tutor=a[1][len('MOVETUTOR_'):], who=who, start=start, label=lb))
            # coin prizes: a label that sets the prize (VAR_TEMP_1) and its price (VAR_TEMP_2)
        if owner[lb] and 'GameCorner_PrizeRoom' in owner[lb]:
            prize = next((re.match(r'setvar VAR_TEMP_1,\s*((?:ITEM|SPECIES)_\w+)', s) for s in lines
                          if re.match(r'setvar VAR_TEMP_1,\s*(ITEM|SPECIES)_', s)), None)
            cost = next((re.match(r'setvar VAR_TEMP_2,\s*(\d+)', s) for s in lines if re.match(r'setvar VAR_TEMP_2,\s*\d+', s)), None)
            if prize and cost:
                R.coins.append(dict(map=owner[lb], prize=prize.group(1), coins=int(cost.group(1))))
    # coin prize Pokemon come with the level of their givemon label
    for c in R.coins:
        if c['prize'].startswith('SPECIES_'):
            lv = [x['lvl'] for x in R.mons if x['species'] == c['prize'][8:] and x['map'] == c['map']]
            c['lvl'] = lv[0] if lv else None
    R.mons = [x for x in R.mons if 'GameCorner_PrizeRoom' not in x['map']]
    for d, m in g.maps.items():
        for b in m.get('bg_events') or []:
            if b.get('type') == 'hidden_item':
                it = b['item'][5:]
                if it == 'NONE' and 'COINS' in b.get('flag', ''):
                    it = 'COINS'          # hidden coins: no item, the flag names them (FLAG_HIDDEN_ITEM_..._COINS)
                R.hidden.append(dict(map=d, item=it, qty=b.get('quantity', 1), xy=(b['x'], b['y'])))
    R.mart_items = {}
    for lb, lines in labels.items():
        its = [s.split()[1][5:] for s in lines if s.startswith('.2byte ITEM_')]
        if its:
            R.mart_items[lb] = [x for x in its if x != 'NONE']
    R.labels, R.reach, R.owner = labels, reach, owner
    # dedupe (a script reachable from several objects of the same map counts once)
    for k in ('ground', 'hidden', 'gifts', 'marts', 'coins', 'mons', 'trades', 'battles', 'tutors'):
        seen, out = set(), []
        for x in getattr(R, k):
            key = json.dumps({a: b for a, b in x.items() if a not in (('start',) if k == 'marts' else ('label', 'start'))}, sort_keys=True, default=str)
            if key not in seen:
                seen.add(key); out.append(x)
        setattr(R, k, out)
    setattr(g, 'R' + ver, R)


# ------------------------------------------------------------------ helpers for the pages
STAT_ES = ['PS', 'Ataque', 'Defensa', 'At. Esp.', 'Def. Esp.', 'Velocidad']
GROWTH_ES = {'GROWTH_FAST': 'Rápido', 'GROWTH_MEDIUM_FAST': 'Medio', 'GROWTH_MEDIUM_SLOW': 'Medio lento',
             'GROWTH_SLOW': 'Lento', 'GROWTH_ERRATIC': 'Errático', 'GROWTH_FLUCTUATING': 'Fluctuante'}
METHOD_ES = {'land_mons': 'Andando (hierba o cueva)', 'water_mons': 'Surf', 'rock_smash_mons': 'Golpe Roca',
             'old_rod': 'Caña Vieja', 'good_rod': 'Caña Buena', 'super_rod': 'Supercaña'}
# a selection of item ids (the data about them comes from pret)
VITAMINS = ['HP_UP', 'PROTEIN', 'IRON', 'CALCIUM', 'ZINC', 'CARBOS', 'PP_UP', 'PP_MAX', 'RARE_CANDY']


def physical_types(g):
    """IS_TYPE_PHYSICAL in include/battle.h: every type below TYPE_MYSTERY is physical."""
    rule = re.search(r'IS_TYPE_PHYSICAL\(moveType\)\s*\(moveType < (TYPE_\w+)\)', rd('include/battle.h'))
    ids = defines('include/constants/pokemon.h', 'TYPE_')
    lim = ids[rule.group(1)]
    return {k[5:] for k, v in ids.items() if v < lim}


def cat(g, mv):
    m = g.moves[mv]
    if m['power'] == 0:
        return 'Estado'
    return 'Físico' if m['type'] in g.PHYS else 'Especial'


def tyn(g, t):
    return short(g, 'ty', t)


def fmt_power(m):
    return '—' if m['power'] == 0 else ('variable' if m['power'] == 1 else str(m['power']))


def move_row(g, mv, first, base=''):
    m = g.moves[mv]
    acc = '—' if m['acc'] == 0 else str(m['acc'])
    return '| %s | %s | %s | %s | %s | %s | %d |' % (first, mvlink(g, mv, base), tyn(g, m['type']), cat(g, mv), fmt_power(m), acc, m['pp'])


MOVE_HEAD = '| %s | Ataque | Tipo | Categoría | Potencia | Precisión | PP |\n|---|---|---|---|---|---|---|'


def gender(s):
    if s == 'MON_GENDERLESS':
        return 'Sin género'
    if s == 'MON_MALE':
        return '100 % macho'
    if s == 'MON_FEMALE':
        return '100 % hembra'
    m = re.match(r'PERCENT_FEMALE\(([\d.]+)\)', s or '')
    if m:
        return '%s %% hembra' % ('%g' % float(m.group(1))).replace('.', ',')
    return NV


def default_moves(g, sp, lvl):
    """The moveset a Pokemon gets when it is created: the last 4 level-up moves up to its level."""
    known = []
    for lv, mv in g.lvl.get(sp, []):
        if lv > lvl:
            break
        if mv in known:
            continue
        if len(known) == 4:
            known.pop(0)
        known.append(mv)
    return known


def evo_text(g, meth, par):
    lv = par if par.isdigit() else None
    fr = re.search(r'case EVO_FRIENDSHIP:\s*if \(friendship >= (\d+)\)', rd('src/pokemon.c'))
    if meth in g.evo_off:
        return 'amistad (%s) — no ocurre en Rojo Fuego / Verde Hoja: el código está desactivado en pret' % (
            'de día' if meth.endswith('DAY') else 'de noche')
    t = {
        'EVO_LEVEL': 'nivel %s' % lv,
        'EVO_ITEM': 'usar %s' % nm(g, 'it', par[5:]),
        'EVO_TRADE': 'intercambio',
        'EVO_TRADE_ITEM': 'intercambio llevando %s' % nm(g, 'it', par[5:]),
        'EVO_FRIENDSHIP': 'subir de nivel con amistad ≥ %s' % (fr.group(1) if fr else NV),
        'EVO_LEVEL_ATK_GT_DEF': 'nivel %s con Ataque > Defensa' % lv,
        'EVO_LEVEL_ATK_EQ_DEF': 'nivel %s con Ataque = Defensa' % lv,
        'EVO_LEVEL_ATK_LT_DEF': 'nivel %s con Ataque < Defensa' % lv,
        'EVO_LEVEL_SILCOON': 'nivel %s (según su personalidad)' % lv,
        'EVO_LEVEL_CASCOON': 'nivel %s (según su personalidad)' % lv,
        'EVO_LEVEL_NINJASK': 'nivel %s' % lv,
        'EVO_LEVEL_SHEDINJA': 'nivel %s, a la vez que la evolución a Ninjask' % lv,
        'EVO_BEAUTY': 'subir de nivel con Belleza ≥ %s' % par,
    }
    return t.get(meth, '%s %s (%s)' % (meth, par, NV))


def merge(fr, lg, key):
    """[(entry, versions)] with the entries of both versions joined by key."""
    out, idx = [], {}
    for v, lst in (('FR', fr), ('LG', lg)):
        for e in lst:
            k = key(e)
            if k in idx:
                idx[k][1].add(v)
            else:
                idx[k] = (e, {v})
                out.append(idx[k])
    return out


def vtag(vs):
    return '' if len(vs) == 2 else (' *(solo RF)*' if 'FR' in vs else ' *(solo VH)*')


def price(g, it):
    p = g.item.get(it, {}).get('price')
    return '%d ₽' % p if p is not None else NV


MONEY_CODE = '4*lastMonLevel*gBattleStruct->moneyMultiplier*(gBattleTypeFlags&BATTLE_TYPE_DOUBLE?2:1)*gTrainerMoneyTable[i].value'


def money(g, tr):
    t = g.trainers[tr]
    if not t['party'] or t['cls'] not in g.money or g.money_formula.replace(' ', '') != MONEY_CODE:
        return NV                                   # unknown class or the formula changed in pret: don't guess
    return '%d ₽' % (4 * t['party'][-1]['lvl'] * (2 if t['double'] else 1) * g.money[t['cls']])


def write(rel, text):
    p = os.path.join(OUT, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, 'w', encoding='utf-8', newline='\n') as f:
        f.write(text.rstrip() + '\n')


NAV = '[Guía](%sREADME.md)'


# ------------------------------------------------------------------ where each species is
def encounters(g, ver):
    """species -> [(map, method, levels, percent)] for one version."""
    out = defaultdict(list)
    fields = {f['type']: f for f in g.wild['wild_encounter_groups'][0]['fields']}
    tail = 'FireRed' if ver == 'FR' else 'LeafGreen'
    for e in g.wild['wild_encounter_groups'][0]['encounters']:
        if not e['base_label'].endswith(tail):
            continue
        mapdir = g.map_by_id.get(e['map'], e['map'])
        for kind in ('land_mons', 'water_mons', 'rock_smash_mons', 'fishing_mons'):
            if kind not in e:
                continue
            rates = fields[kind]['encounter_rates']
            groups = fields[kind].get('groups') or {kind: list(range(len(rates)))}
            for gname, slots in groups.items():
                acc = {}
                for i in slots:
                    mon = e[kind]['mons'][i]
                    sp = mon['species'][8:]
                    a = acc.setdefault(sp, [0, 999, 0])
                    a[0] += rates[i]
                    a[1] = min(a[1], mon['min_level']); a[2] = max(a[2], mon['max_level'])
                total = sum(rates[i] for i in slots)
                for sp, (r, lo, hi) in acc.items():
                    out[sp].append((mapdir, METHOD_ES.get(gname, gname), (lo, hi), 100.0 * r / total))
    return out


def obtain(g, ver):
    """species -> [(map, method text, levels text)] for statics, gifts, prizes, trades, roamers."""
    R = getattr(g, 'R' + ver)
    out = defaultdict(list)
    for x in R.mons:
        how = {'estático': 'Estático', 'regalo': 'Regalo', 'huevo': 'Huevo de regalo'}[x['how']]
        if x.get('who'):
            how += ' (%s)' % x['who']
        if x.get('choice'):
            how += ' — uno a elegir entre ' + ', '.join(short(g, 'sp', c) for c in sorted([x['species']] + x['choice'], key=lambda s: dex(g, s)))
        out[x['species']].append((x['map'], how, 'Nv %d' % x['lvl'] if x['lvl'] else 'huevo'))
    for c in R.coins:
        if c['prize'].startswith('SPECIES_'):
            out[c['prize'][8:]].append((c['map'], 'Premio del Casino: %d fichas' % c['coins'],
                                        'Nv %d' % c['lvl'] if c.get('lvl') else NV))
    trades = {t['id']: t for t in g.trades[ver]}
    for x in R.trades:
        t = trades.get(x['id'])
        if t:
            out[t['species']].append((x['map'], 'Intercambio: das %s (%s)' % (short(g, 'sp', t['wants']), x['who']),
                                      'el del Pokémon que das'))
    starters = sorted({x['species'] for x in R.mons if x['map'] == 'PalletTown_ProfessorOaksLab'})
    named = {a for a, _ in g.roamers}
    for st, rm in g.roamers + [(s, g.roamer_default) for s in starters if s not in named and g.roamer_default]:
        out[rm].append((None, 'Errante por Kanto si tu inicial es %s' % short(g, 'sp', st),
                        'Nv %s' % (g.roamer_lvl or NV)))
    return out


# ------------------------------------------------------------------ pages
def page_pokemon(g, sp, enc, obt):
    i = g.info[sp]
    L = ['# #%03d %s' % (dex(g, sp), nm(g, 'sp', sp)), '', '[← Pokémon](README.md) · ' + NAV % '../', '']
    pics = [p for p in (pimg(g, sp, 96), pimg(g, sp, 96, shiny=True)) if p]
    if pics:
        L += [' '.join(pics), '']
    t1, t2 = i['types']
    types = tyn(g, t1) + ('' if t2 == t1 else ' / ' + tyn(g, t2))
    abil = ' / '.join(nm(g, 'ab', a) for a in dict.fromkeys(i['abilities']) if a != 'NONE')
    evs = ', '.join('%d %s' % (v, STAT_ES[k]) for k, v in enumerate(i['ev']) if v) or 'ninguno'
    items = ['%s%s (común)' % (ipre(g, i['items'][0]), nm(g, 'it', i['items'][0]))] if i['items'][0] != 'NONE' else []
    items += ['%s%s (raro)' % (ipre(g, i['items'][1]), nm(g, 'it', i['items'][1]))] if i['items'][1] != 'NONE' else []
    eggs = ' / '.join(dict.fromkeys(e.replace('_', ' ').title() for e in i['eggs']))
    L += ['| Dato | Valor |', '|---|---|', '| Tipo | %s |' % types, '| Habilidades | %s |' % abil,
          '| EVs al derrotarlo | %s |' % evs, '| Ratio de captura | %d |' % i['catch'],
          '| Experiencia base | %d |' % i['exp'],
          '| Crecimiento | %s (`%s`) |' % (GROWTH_ES.get(i['growth'], NV), i['growth']),
          '| Género | %s |' % gender(i['gender']), '| Grupos huevo | %s |' % eggs,
          '| Objeto que puede llevar (salvaje) | %s |' % (', '.join(items) or 'ninguno'), '']
    L += ['## Stats base', '', '| ' + ' | '.join(STAT_ES) + ' | Total |', '|' + '---|' * 7,
          '| ' + ' | '.join(str(x) for x in i['stats']) + ' | %d |' % sum(i['stats']), '']
    L += ['## Evolución', '']
    if sp in g.prev:
        p = g.prev[sp]
        how = [evo_text(g, m, a) for m, a, t in g.evo[p] if t == sp]
        L.append('- Evoluciona de %s%s: %s.' % (ppre(g, p), splink(g, p, ''), '; '.join(how)))
    for m, a, t in g.evo.get(sp, []):
        L.append('- Evoluciona a %s%s: %s.' % (ppre(g, t), splink(g, t, ''), evo_text(g, m, a)))
    if sp not in g.prev and sp not in g.evo:
        L.append('No evoluciona.')
    L += ['', '## Ataques por nivel', '', MOVE_HEAD % 'Nv']
    L += [move_row(g, mv, str(lv), '../') for lv, mv in g.lvl.get(sp, [])]
    L += ['', '## MT y MO', '']
    tms = g.tmlearn.get(sp, [])
    if tms:
        L.append(MOVE_HEAD % 'MT/MO')
        L += [move_row(g, g.tm[t], '%s[%s](../mts.md#%s)' % (ipre(g, t), t.replace('TM', 'MT').replace('HM', 'MO'), t.lower()), '../')
              for t in tms]
    else:
        L.append('No aprende ninguna MT ni MO.')
    L += ['', '## Tutores de ataques', '']
    tut = list(g.tutorlearn.get(sp, []))
    if sp in g.capebrink:
        tut.append(['FRENZY_PLANT', 'BLAST_BURN', 'HYDRO_CANNON'][g.capebrink.index(sp)])
    if tut:
        L.append(MOVE_HEAD % 'Tutor')
        L += [move_row(g, mv, '[ver](../tutores.md)', '../') for mv in tut]
    else:
        L.append('Ningún tutor le enseña ataques.')
    L += ['', '## Dónde encontrarlo', '']
    for v in VERS:
        L += ['### %s' % VER_NAME[v], '']
        rows = sorted(enc[v].get(sp, []), key=lambda r: (map_name(g, r[0]), r[1]))
        other = obt[v].get(sp, [])
        if not rows and not other:
            L.append('No se encuentra directamente.' + (' Evoluciona de %s.' % splink(g, g.prev[sp], '') if sp in g.prev else ''))
            L.append('')
            continue
        if rows:
            L += ['| Lugar | Método | Niveles | Probabilidad |', '|---|---|---|---|']
            for mp, meth, (lo, hi), pct in rows:
                L.append('| %s | %s | %s | %s %% |' % (map_name(g, mp), meth, lo if lo == hi else '%d–%d' % (lo, hi),
                                                       ('%.1f' % pct).rstrip('0').rstrip('.').replace('.', ',')))
            L.append('')
        if other:
            L += ['| Lugar | Cómo | Nivel |', '|---|---|---|']
            for mp, how, lv in other:
                L.append('| %s | %s | %s |' % (map_name(g, mp) if mp else '—', how, lv))
            L.append('')
    write('pokemon/%s.md' % slug(g, sp), '\n'.join(L))


def all_pokemon(g):
    enc = {v: encounters(g, v) for v in VERS}
    obt = {v: obtain(g, v) for v in VERS}
    sps = sorted((s for s in g.info if dex(g, s)), key=lambda s: dex(g, s))
    for sp in sps:
        page_pokemon(g, sp, enc, obt)
    L = ['# Pokémon', '', NAV % '../', '', '| N.º | | Pokémon | Tipo |', '|---|---|---|---|']
    for sp in sps:
        t1, t2 = g.info[sp]['types']
        L.append('| %03d | %s | %s | %s |' % (dex(g, sp), pimg(g, sp, 40), splink(g, sp, ''),
                                             tyn(g, t1) + ('' if t1 == t2 else ' / ' + tyn(g, t2))))
    write('pokemon/README.md', '\n'.join(L))
    return enc, obt


def gift_kind(g, x):
    """(kind, detail) of an item handed over by a script: free, bought, or exchanged."""
    if x.get('money'):
        return 'Compra', '%s, %d ₽' % (x['who'], x['money'])
    if x.get('powder'):
        return 'Canje', '%s, %d de polvo de bayas' % (x['who'], x['powder'])
    if x.get('swap'):
        return 'Regalo', '%s, a cambio de %s' % (x['who'], short(g, 'it', x['swap']))
    return 'Regalo', x['who']


def gift_text(g, x):
    kind, detail = gift_kind(g, x)
    return '%s (%s)' % (kind, detail)


def item_sources(g, ver):
    """item -> [text] (how to get it in one version)."""
    R = getattr(g, 'R' + ver)
    out = defaultdict(list)
    for x in R.ground:
        out[x['item']].append('Suelo: %s%s' % (map_name(g, x['map']), ' (x %d, y %d)' % tuple(x['xy']) if x['xy'] else ''))
    for x in R.hidden:
        out[x['item']].append('Oculto: %s (x %d, y %d)' % ((map_name(g, x['map']),) + tuple(x['xy'])))
    for x in R.gifts:
        out[x['item']].append('%s: %s' % (gift_text(g, x), map_name(g, x['map'])))
    for x in R.marts:
        for it in R.mart_items.get(x['label'], []):
            out[it].append('Tienda: %s — %s' % (map_name(g, x['map']), price(g, it)))
    for c in R.coins:
        if c['prize'].startswith('ITEM_'):
            out[c['prize'][5:]].append('Casino: %d fichas (%s)' % (c['coins'], map_name(g, c['map'])))
    return out


def sources_cell(src, it):
    rows = merge(src['FR'].get(it, []), src['LG'].get(it, []), lambda x: x)
    return ('<br>'.join(t + vtag(vs) for t, vs in sorted(rows, key=lambda r: r[0]))
            or 'no aparece en los guiones de pret (%s)' % NV)


def page_mts(g):
    src = {v: item_sources(g, v) for v in VERS}
    L = ['# MT y MO', '', NAV % '', '',
         ('Las MT se gastan al usarlas y las MO no: en pret (`src/party_menu.c`) el juego solo quita el objeto de la '
          'mochila si es anterior a `ITEM_HM01`.') if g.tm_consumed else 'Uso de las MT y MO: %s.' % NV, '',
         '| N.º | Ataque | Tipo | Categoría | Potencia | Precisión | PP | Un solo uso | Cómo se consigue |',
         '|---|---|---|---|---|---|---|---|---|']
    for t in sorted(g.tm, key=lambda x: (x[:2] == 'HM', x)):
        mv = g.tm[t]
        m = g.moves[mv]
        one = (('Sí' if t.startswith('TM') else 'No') if g.tm_consumed else NV)
        L.append('| <a id="%s"></a>%s%s | %s | %s | %s | %s | %s | %d | %s | %s |' % (
            t.lower(), ipre(g, t), t.replace('TM', 'MT').replace('HM', 'MO'), mvlink(g, mv), tyn(g, m['type']), cat(g, mv), fmt_power(m),
            '—' if m['acc'] == 0 else m['acc'], m['pp'], one, sources_cell(src, t)))
    write('mts.md', '\n'.join(L))
    return src


def page_objetos(g, src):
    L = ['# Objetos', '', NAV % '', '',
         'Objetos del suelo y ocultos (con las coordenadas del mapa), regalos y tiendas. Precios de '
         '`src/data/items.json`. Lo marcado *(solo RF)* o *(solo VH)* solo está en esa versión.', '',
         '- [Vitaminas y caramelos](#vitaminas-y-caramelos)', '- [Piedras evolutivas](#piedras-evolutivas)',
         '- [Tiendas](#tiendas)', '- [Por mapa](#por-mapa)', '']
    stones = sorted({p[5:] for v in g.evo.values() for m, p, t in v if m == 'EVO_ITEM'})
    for title, lst in (('Vitaminas y caramelos', VITAMINS), ('Piedras evolutivas', stones)):
        L += ['## ' + title, '', '| Objeto | Cómo se consigue |', '|---|---|']
        L += ['| %s%s | %s |' % (ipre(g, it), nm(g, 'it', it), sources_cell(src, it)) for it in lst]
        L.append('')
    L += ['## Tiendas', '']
    marts = merge(g.RFR.marts, g.RLG.marts, lambda x: (x['map'], x['label']))
    per_map = defaultdict(int)
    for x, _ in marts:
        per_map[x['map']] += 1
    for x, vs in sorted(marts, key=lambda e: (map_name(g, e[0]['map']), e[0]['label'])):
        its = merge(g.RFR.mart_items.get(x['label'], []), g.RLG.mart_items.get(x['label'], []), lambda y: y)
        # several lists on one map (a stock that grows, or two counters): name each by its pret label
        which = ' — `%s`' % x['label'] if per_map[x['map']] > 1 else ''
        L += ['### %s%s%s' % (map_name(g, x['map']), which, vtag(vs)), '', '| Objeto | Precio |', '|---|---|']
        L += ['| %s%s%s | %s |' % (ipre(g, it), nm(g, 'it', it), vtag(v2), price(g, it)) for it, v2 in its]
        L.append('')
    coins = merge(g.RFR.coins, g.RLG.coins, lambda c: (c['prize'], c['coins']))
    L += ['### Casino de Azulona: premios con fichas', '', '| Premio | Fichas |', '|---|---|']
    for c, vs in coins:
        p = c['prize']
        name = ((ppre(g, p[8:]) + splink(g, p[8:]) + (' Nv %s' % c.get('lvl') if c.get('lvl') else '')) if p.startswith('SPECIES_')
                else ipre(g, p[5:]) + nm(g, 'it', p[5:]))
        L.append('| %s%s | %d |' % (name, vtag(vs), c['coins']))
    L += ['', '## Por mapa', '']
    per = defaultdict(lambda: defaultdict(list))
    for kind, name in (('ground', 'Suelo'), ('hidden', 'Oculto'), ('gifts', 'Regalo')):
        for x, vs in merge(getattr(g.RFR, kind), getattr(g.RLG, kind), lambda y: json.dumps(y, sort_keys=True, default=str)):
            extra = ' (x %d, y %d)' % tuple(x['xy']) if x.get('xy') else ''
            how, who = (gift_kind(g, x)[0], ' — ' + gift_kind(g, x)[1]) if kind == 'gifts' else (name, '')
            per[map_name(g, x['map'])][how].append('%s%s%s%s%s%s' % (ipre(g, x['item'], 20), nm(g, 'it', x['item']),
                                                                    ' ×%d' % x['qty'] if x['qty'] > 1 else '', extra, who, vtag(vs)))
    for mp in sorted(per):
        L += ['### ' + mp, '']
        for name in ('Suelo', 'Oculto', 'Regalo', 'Compra', 'Canje'):
            for t in per[mp].get(name, []):
                L.append('- %s: %s' % (name, t))
        L.append('')
    write('objetos.md', '\n'.join(L))


def page_tutores(g):
    L = ['# Tutores de ataques', '', NAV % '', '']
    seen = {}
    for x, vs in merge(g.RFR.tutors, g.RLG.tutors, lambda y: (y['map'], y['tutor'])):
        seen.setdefault(x['tutor'], (x, vs))
    L += ['| Ataque | Tipo | Dónde | Requisitos | Quién puede aprenderlo |', '|---|---|---|---|---|']
    for tut in g.tutor_moves:
        x, vs = seen.get(tut, (None, set()))
        if not x:
            L.append('| %s | %s | %s | %s | %s |' % (nm(g, 'mv', tut), tyn(g, g.moves[tut]['type']), NV, NV, NV))
            continue
        req = []
        for s in g.RFR.labels.get(x['start'], []):
            m = re.match(r'checkitem ITEM_(\w+)', s)
            if m:
                req.append('llevar %s' % nm(g, 'it', m.group(1)))
        if any(re.match(r'goto_if_set FLAG_TUTOR_', s) for s in g.RFR.labels.get(x['label'], [])):
            req.append('una sola vez por partida')
        who = sorted((s for s in g.info if tut in g.tutorlearn.get(s, [])), key=lambda s: dex(g, s))
        L.append('| %s | %s | %s%s | %s | %s |' % (mvlink(g, tut), tyn(g, g.moves[tut]['type']), map_name(g, x['map']), vtag(vs),
                                                  '; '.join(req) or 'ninguno', ', '.join(splink(g, s) for s in who)))
    L += ['', '## Ataques definitivos de los iniciales', '']
    cb = [k for k in g.RFR.labels if k.endswith('_EventScript_StarterTutor')]
    where = map_name(g, cb[0].split('_EventScript_')[0]) if cb else NV
    L.append('Un tutor en %s enseña un ataque al Pokémon que vaya **primero** en el equipo, si es una de estas '
             'especies y tiene la amistad a %s (`src/field_specials.c`). Cada ataque se enseña una sola vez por partida '
             '(`FLAG_TUTOR_FRENZY_PLANT`, `FLAG_TUTOR_BLAST_BURN`, `FLAG_TUTOR_HYDRO_CANNON`).' % (
                 where, g.capebrink_friend if g.capebrink_friend is not None else NV))
    L += ['', MOVE_HEAD % 'Pokémon']
    for sp, mv in zip(g.capebrink, ['FRENZY_PLANT', 'BLAST_BURN', 'HYDRO_CANNON']):
        L.append(move_row(g, mv, ppre(g, sp) + splink(g, sp)))
    write('tutores.md', '\n'.join(L))


def party_table(g, tr):
    t = g.trainers[tr]
    L = ['| Pokémon | Nv | Ataques | Objeto |', '|---|---|---|---|']
    for p in t['party']:
        mv = p['moves'] if p['moves'] else default_moves(g, p['species'], p['lvl'])
        note = '' if p['moves'] else ' *(por defecto)*'
        mvs = ', '.join('[%s](ataques.md#%s)' % (short(g, 'mv', m), mv_anchor(m)) for m in mv)
        L.append('| %s%s | %d | %s%s | %s |' % (ppre(g, p['species']), splink(g, p['species']), p['lvl'], mvs, note,
                                                (ipre(g, p['item']) + nm(g, 'it', p['item'])) if p['item'] else '—'))
    return L


def page_entrenadores(g):
    R = g.RFR
    fought = defaultdict(list)
    for x in R.battles:
        fought[x['trainer']].append(x)
    L = ['# Entrenadores', '', NAV % '', '',
         'Equipos de `src/data/trainer_parties.h`. *(por defecto)*: el entrenador no tiene ataques propios '
         'y su Pokémon lleva los 4 últimos que aprende por nivel. Dinero = 4 × nivel de su último Pokémon × '
         'valor de su clase (× 2 en combate doble), de `src/battle_script_commands.c` y `gTrainerMoneyTable`.', '',
         '- [Líderes de gimnasio](#líderes-de-gimnasio)', '- [Alto Mando y Campeón](#alto-mando-y-campeón)', '- [Rival](#rival)', '']
    L += ['## Líderes de gimnasio', '']
    leaders = []
    for tr, xs in fought.items():
        if g.trainers.get(tr, {}).get('cls') != 'LEADER':
            continue
        x = xs[0]
        badge = None
        for lb, w in R.reach.items():
            if any(d == x['map'] and human(st) == x['who'] for d, st, _ in w):
                for s in R.labels[lb]:
                    m = re.match(r'setflag FLAG_BADGE0(\d)_GET', s)
                    if m:
                        badge = int(m.group(1))
        leaders.append((badge or 99, tr, x))
    for badge, tr, x in sorted(leaders):
        t = g.trainers[tr]
        gifts = [y for y in R.gifts if y['map'] == x['map'] and y['who'] == x['who']]
        prize = ', '.join(ipre(g, y['item']) + ('[%s](mts.md#%s) (%s)' % (nm(g, 'it', y['item']), y['item'].lower(), short(g, 'mv', g.tm[y['item']]))
                                                if y['item'] in g.tm else nm(g, 'it', y['item'])) for y in gifts)
        L += ['### %s — %s' % (t['name'].title(), map_name(g, x['map'])), '',
              '- Medalla n.º %s' % (badge if badge != 99 else NV),
              '- Premio: %s%s' % (money(g, tr), ', ' + prize if prize else ''),
              '- Objetos que usa: %s' % (', '.join(short(g, 'it', i) for i in t['items']) or 'ninguno'), '']
        L += party_table(g, tr) + ['']
    L += ['## Alto Mando y Campeón', '']
    for cls in ('ELITE_FOUR', 'CHAMPION'):
        for tr in sorted((k for k in fought if g.trainers.get(k, {}).get('cls') == cls), key=lambda k: g.TRN.get('TRAINER_' + k, 0)):
            t = g.trainers[tr]
            x = fought[tr][0]
            title = t['name'].title()
            if cls == 'CHAMPION':
                # trainers.h gives the rival a default name; in the game it is the one you chose
                title = 'Campeón: tu rival (en pret, %s), su inicial: %s' % (title, short(g, 'sp', tr.split('_')[-1]))
            again = ' (revancha)' if (tr.endswith('_2') or 'REMATCH' in tr) else ''
            L += ['### %s%s — %s' % (title, again, map_name(g, x['map'])), '',
                  '- Premio: %s' % money(g, tr),
                  '- Objetos que usa: %s' % (', '.join(short(g, 'it', i) for i in t['items']) or 'ninguno'), '']
            L += party_table(g, tr) + ['']
    L += ['## Rival', '', 'Su equipo depende de su inicial (el que tiene ventaja sobre el tuyo).', '']
    rivals = sorted((k for k in g.trainers if k.startswith('RIVAL_')), key=lambda k: g.TRN.get('TRAINER_' + k, 0))
    stage = defaultdict(list)
    for k in rivals:
        stage[k.rsplit('_', 1)[0]].append(k)
    for n, (st, ks) in enumerate(stage.items(), 1):
        maps = sorted({map_name(g, x['map']) for k in ks for x in fought.get(k, [])})
        L += ['### Combate %d — %s' % (n, ', '.join(maps) or NV), '', '`%s_*`' % ('TRAINER_' + st), '']
        for k in ks:
            L += ['**Su inicial: %s** — premio %s' % (short(g, 'sp', k.split('_')[-1]), money(g, k)), '']
            L += party_table(g, k) + ['']
    write('entrenadores.md', '\n'.join(L))


def page_evs(g, enc):
    L = ['# Dónde entrenar EVs', '', NAV % '', '',
         'Para cada stat, las zonas que dan más EVs de ese stat por combate, andando o con Surf: la suma de '
         '(probabilidad × EVs que da cada especie). "Solo ese EV" es la parte de los combates que no da EVs '
         'de otros stats. Datos de `wild_encounters.json` y `species_info.h`.', '']
    for k, st in enumerate(STAT_ES):
        L += ['## %s' % st, '']
        for v in VERS:
            zones = defaultdict(lambda: [0.0, 0.0, [], 999, 0])
            for sp, rows in enc[v].items():
                ev = g.info.get(sp, {}).get('ev', [0] * 6)
                for mp, meth, (lo, hi), pct in rows:
                    if meth not in (METHOD_ES['land_mons'], METHOD_ES['water_mons']):
                        continue
                    z = zones[mp, meth]
                    z[0] += pct * ev[k] / 100
                    if ev[k] and sum(ev) == ev[k]:
                        z[1] += pct
                    if ev[k]:
                        z[2].append((pct, sp))
                    z[3] = min(z[3], lo); z[4] = max(z[4], hi)
            top = sorted(((z[0], z[1], mp, meth, z[2], z[3], z[4]) for (mp, meth), z in zones.items() if z[0] > 0), reverse=True)[:6]
            L += ['### %s' % VER_NAME[v], '', '| Zona | Método | EVs por combate | Solo ese EV | Niveles | Especies que lo dan |',
                  '|---|---|---|---|---|---|']
            for val, pure, mp, meth, sps, lo, hi in top:
                L.append('| %s | %s | %s | %d %% | %d–%d | %s |' % (
                    map_name(g, mp), meth, ('%.2f' % val).replace('.', ','), round(pure), lo, hi,
                    ', '.join('%s %d %%' % (short(g, 'sp', s), round(p)) for p, s in sorted(sps, reverse=True))))
            L.append('')
    write('evs.md', '\n'.join(L))


def page_diferencias(g, enc, obt):
    have = {}
    for v in VERS:
        s = set(enc[v]) | set(obt[v])
        grow = True
        while grow:                                  # what you get by evolving them too
            n = {t for sp in s for _, _, t in g.evo.get(sp, [])} - s
            grow = bool(n)
            s |= n
        have[v] = s
    L = ['# Diferencias entre versiones', '', NAV % '', '',
         'Pokémon que se pueden conseguir en una versión y no en la otra: salvajes, estáticos, regalos, premios, '
         'intercambios con personajes del juego, errantes y sus evoluciones. No cuenta la cría ni los intercambios '
         'entre partidas.', '']
    for v, o in (('FR', 'LG'), ('LG', 'FR')):
        ex = sorted(have[v] - have[o], key=lambda s: dex(g, s))
        L += ['## Solo en %s (%d)' % (VER_NAME[v], len(ex)), '', '| N.º | | Pokémon | Cómo |', '|---|---|---|---|']
        for sp in ex:
            how = sorted({r[1] for r in enc[v].get(sp, [])} | {r[1].split(' (')[0].split(':')[0] for r in obt[v].get(sp, [])})
            if not how and sp in g.prev:
                how = ['evolución de ' + short(g, 'sp', g.prev[sp])]
            L.append('| %03d | %s | %s | %s |' % (dex(g, sp), pimg(g, sp, 40), splink(g, sp), ', '.join(how)))
        L.append('')
    write('diferencias.md', '\n'.join(L))


def page_ataques(g):
    lvl, tmw, tut = defaultdict(list), defaultdict(list), defaultdict(list)
    sps = sorted((s for s in g.info if dex(g, s)), key=lambda s: dex(g, s))
    for sp in sps:
        levels = defaultdict(list)
        for lv, mv in g.lvl.get(sp, []):
            levels[mv].append(lv)
        for mv, lvs in levels.items():
            lvl[mv].append((sp, lvs))
        for t in g.tmlearn.get(sp, []):
            tmw[g.tm[t]].append(sp)
        for mv in g.tutorlearn.get(sp, []):
            tut[mv].append(sp)
    for sp, mv in zip(g.capebrink, ['FRENZY_PLANT', 'BLAST_BURN', 'HYDRO_CANNON']):
        tut[mv].append(sp)
    tm_of = {mv: t for t, mv in g.tm.items()}
    moves = sorted((m for m in g.moves if m != 'NONE'), key=lambda m: norm(short(g, 'mv', m)))

    def tmcell(mv):
        t = tm_of.get(mv)
        return '%s[%s](mts.md#%s)' % (ipre(g, t), t.replace('TM', 'MT').replace('HM', 'MO'), t.lower()) if t else '—'
    L = ['# Ataques', '', NAV % '', '',
         'Todos los ataques del juego y qué Pokémon los aprenden: por nivel (con el nivel), por MT/MO y por tutor. '
         'Datos de `battle_moves.h`, `level_up_learnsets.h`, `tmhm_learnsets.h` y `tutor_learnsets.h`.', '',
         '| Ataque | Tipo | Categoría | Potencia | Precisión | PP | MT/MO | Por nivel | Por MT/MO | Por tutor |',
         '|---|---|---|---|---|---|---|---|---|---|']
    for mv in moves:
        m = g.moves[mv]
        L.append('| [%s](#%s) | %s | %s | %s | %s | %d | %s | %d | %d | %d |' % (
            nm(g, 'mv', mv), mv_anchor(mv), tyn(g, m['type']), cat(g, mv), fmt_power(m), '—' if m['acc'] == 0 else m['acc'],
            m['pp'], tmcell(mv), len(lvl[mv]), len(tmw[mv]), len(tut[mv])))
    L += ['', '## Quién aprende cada ataque', '']
    for mv in moves:
        m = g.moves[mv]
        L += ['### <a id="%s"></a>%s' % (mv_anchor(mv), nm(g, 'mv', mv)), '',
              '%s · %s · potencia %s · precisión %s · %d PP%s' % (
                  tyn(g, m['type']), cat(g, mv), fmt_power(m), '—' if m['acc'] == 0 else m['acc'], m['pp'],
                  ' · ' + tmcell(mv) if mv in tm_of else ''), '']
        if lvl[mv]:
            L.append('- **Por nivel:** ' + ', '.join('%s (Nv %s)' % (splink(g, sp), ', '.join(map(str, lvs))) for sp, lvs in lvl[mv]))
        if tmw[mv]:
            L.append('- **Por %s:** ' % tm_of[mv].replace('TM', 'MT').replace('HM', 'MO') + ', '.join(splink(g, sp) for sp in tmw[mv]))
        if tut[mv]:
            L.append('- **Por [tutor](tutores.md):** ' + ', '.join(splink(g, sp) for sp in tut[mv]))
        if not (lvl[mv] or tmw[mv] or tut[mv]):
            L.append('Ningún Pokémon lo aprende por nivel, MT/MO ni tutor.')
        L.append('')
    write('ataques.md', '\n'.join(L))


def page_index(g, rev):
    unmatched = [u for u in g.unmatched.get('items', []) if u != 'NONE']
    L = ['# Guía de Rojo Fuego y Verde Hoja', '',
         'Guía de referencia generada desde los datos del juego, sin datos escritos a mano: '
         '`python tools/guia/gen_guia.py` la vuelve a crear.', '',
         '| Sección | Contenido |', '|---|---|',
         '| [Pokémon](pokemon/README.md) | Una página por especie: tipos, habilidades, stats, EVs, captura, crecimiento, '
         'evolución, ataques, MT/MO, tutores y dónde encontrarlo en cada versión |',
         '| [Ataques](ataques.md) | Todos los ataques y qué Pokémon los aprenden por nivel (con el nivel), por MT/MO y por tutor |',
         '| [MT y MO](mts.md) | Todas, con su ataque y cómo se consigue cada una |',
         '| [Objetos](objetos.md) | Suelo, ocultos, regalos y tiendas por mapa; vitaminas y piedras evolutivas |',
         '| [Tutores](tutores.md) | Tutores de ataques y los ataques definitivos de los iniciales |',
         '| [Entrenadores](entrenadores.md) | Líderes, Alto Mando, Campeón y rival, con equipos y premios |',
         '| [EVs](evs.md) | Mejores zonas para entrenar cada EV en cada versión |',
         '| [Diferencias](diferencias.md) | Pokémon exclusivos de cada versión |', '',
         '## De dónde salen los datos', '',
         '- **Juego**: la decompilación [pret/pokefirered](https://github.com/pret/pokefirered), commit `%s`: '
         'especies, ataques, MT, tutores, evoluciones, encuentros, guiones de los mapas, tiendas, premios y '
         'entrenadores.' % rev,
         '- **Nombres en español e inglés**: las tablas de [PokeAPI](https://github.com/PokeAPI/pokeapi/tree/master/data/v2/csv), '
         'unidas por número nacional (Pokémon), número de ataque o habilidad (son los mismos en la 3.ª generación) y '
         'nombre del objeto. Si no hay nombre en español, la guía pone "nombre en español %s".' % NV,
         '- Los **lugares** llevan el nombre en inglés del juego (las secciones del mapa de pret): no hay una fuente de '
         'datos con los nombres en español de Kanto y las Islas Sete.',
         '- **Físico o especial**: en la 3.ª generación depende del tipo del ataque (`IS_TYPE_PHYSICAL` en `include/battle.h`).',
         '- **Potencia "variable"**: pret pone potencia 1 a los ataques que calculan el daño a su manera.',
         '- **Probabilidad** de un encuentro: la de ese método (andando, Surf, Golpe Roca o cada caña), sumando los '
         'huecos de la especie.',
         '- **Imágenes**: los sprites de Rojo Fuego/Verde Hoja y los iconos de objetos del repositorio '
         '[PokeAPI/sprites](https://github.com/PokeAPI/sprites). Solo se enlazan: no se guardan en este repositorio '
         'y se cargan al ver la página (como los fondos del configurador, ADR-0013). Sin conexión no se ven.', '']
    if unmatched:
        L += ['Objetos sin nombre en español en PokeAPI: ' + ', '.join('`%s`' % u for u in unmatched) + '.', '']
    write('README.md', '\n'.join(L))


# ------------------------------------------------------------------ verification
def verify(g, seed=None):
    """Reads values again straight from the pret files (simple separate parsing) and checks the pages say the same."""
    import random
    rnd = random.Random(seed)
    res = []

    def page(rel):
        with open(os.path.join(OUT, rel), encoding='utf-8') as f:
            return f.read()

    def check(desc, ok, where):
        res.append(('OK  ' if ok else 'FAIL') + '  ' + desc + '   <- ' + where)

    si = rd('src/data/pokemon/species_info.h')
    for _ in range(3):
        sp = rnd.choice([s for s in g.info if dex(g, s)])
        blk = re.search(r'\[SPECIES_%s\]\s*=\s*\{(.*?)\n    \}' % sp, si, re.S).group(1)
        hp = re.search(r'baseHP\s*=\s*(\d+)', blk).group(1)
        cr = re.search(r'catchRate\s*=\s*(\d+)', blk).group(1)
        p = page('pokemon/%s.md' % slug(g, sp))
        check('%s: PS base %s, ratio de captura %s' % (sp, hp, cr),
              ('\n| %s |' % hp) in p and ('| Ratio de captura | %s |' % cr) in p, 'src/data/pokemon/species_info.h')
    ls = rd('src/data/pokemon/level_up_learnsets.h')
    sp = rnd.choice([s for s in g.info if dex(g, s) and g.lvl.get(s)])
    lv, mv = rnd.choice(g.lvl[sp])
    raw = re.search(r'LEVEL_UP_MOVE\(\s*%d,\s*MOVE_%s\)' % (lv, mv), ls)
    check('%s aprende %s al Nv %d' % (sp, mv, lv),
          bool(raw) and ('| %d | [%s](' % (lv, nm(g, 'mv', mv))) in page('pokemon/%s.md' % slug(g, sp)),
          'src/data/pokemon/level_up_learnsets.h')
    bm = rd('src/data/battle_moves.h')
    mv = rnd.choice([m for m in g.moves if m != 'NONE' and g.moves[m]['power'] > 1 and any(x == m for s in g.lvl.values() for _, x in s)])
    pw = re.search(r'\[MOVE_%s\]\s*=\s*\{.*?\.power\s*=\s*(\d+)' % mv, bm, re.S).group(1)
    sp = next(s for s in g.info if dex(g, s) and any(x == mv for _, x in g.lvl.get(s, [])))
    row = next(l for l in page('pokemon/%s.md' % slug(g, sp)).split('\n') if ('[%s](' % nm(g, 'mv', mv)) in l)
    check('%s: potencia %s (en la página de %s)' % (mv, pw, sp), (' | %s | ' % pw) in row, 'src/data/battle_moves.h')
    tl = rd('src/data/pokemon/tmhm_learnsets.h')
    sp = rnd.choice([s for s in g.tmlearn if dex(g, s)])
    t = rnd.choice(g.tmlearn[sp])
    check('%s aprende la %s' % (sp, t), re.search(r'\[SPECIES_%s\][^\[]*TMHM\(%s_' % (sp, t), tl) is not None and
          ('#%s)' % t.lower()) in page('pokemon/%s.md' % slug(g, sp)), 'src/data/pokemon/tmhm_learnsets.h')
    items = json.loads(rd('src/data/items.json'))['items']
    it = rnd.choice(sorted({i for lst in g.RFR.mart_items.values() for i in lst}))
    raw = next(x['price'] for x in items if x['itemId'] == 'ITEM_' + it)
    check('precio de %s en las tiendas: %d' % (it, raw), (' %s | %d ₽ |' % (nm(g, 'it', it), raw)) in page('objetos.md'),
          'src/data/items.json')
    tp = rd('src/data/trainer_parties.h')
    leaders = [k for k in g.trainers if g.trainers[k]['cls'] == 'LEADER' and any(b['trainer'] == k for b in g.RFR.battles)]
    tr = rnd.choice(leaders)
    last = g.trainers[tr]['party'][-1]
    check('%s: último Pokémon %s Nv %d' % (tr, last['species'], last['lvl']),
          re.search(r'\.lvl = %d,\s*\.species = SPECIES_%s' % (last['lvl'], last['species']), tp) is not None and
          (' %s | %d |' % (splink(g, last['species']), last['lvl'])) in page('entrenadores.md'), 'src/data/trainer_parties.h')
    x = rnd.choice(g.RFR.ground)
    mj = json.loads(rd('data/maps/%s/map.json' % x['map']))
    ok = any(o.get('x') == x['xy'][0] and o.get('y') == x['xy'][1] and 'ITEM_BALL' in o.get('graphics_id', '') for o in mj['object_events'])
    sec = page('objetos.md').split('\n### %s\n' % map_name(g, x['map']))
    sec = sec[-1].split('\n### ')[0] if len(sec) > 1 else ''
    check('%s en el suelo de %s (x %d, y %d)' % (x['item'], x['map'], x['xy'][0], x['xy'][1]),
          ok and any(ln.startswith('- Suelo: ') and (nm(g, 'it', x['item']) + ' ') in ln and ('(x %d, y %d)' % tuple(x['xy'])) in ln
                     for ln in sec.split('\n')),
          'data/maps/%s/map.json' % x['map'])
    res.append('--- casos conocidos')
    mts = page('mts.md')
    row22 = next(l for l in mts.split('\n') if 'id="tm22"' in l)
    check('MT22 Rayo Solar en el sótano de la Mansión Pokémon', 'Rayo Solar' in row22 and 'Suelo: ' + map_name(g, 'PokemonMansion_B1F') in row22,
          'data/scripts/item_ball_scripts.inc + data/maps/PokemonMansion_B1F/map.json')
    row38 = next(l for l in mts.split('\n') if 'id="tm38"' in l)
    check('MT38 Llamarada la da Blaine', 'Regalo (Blaine)' in row38 and 'Llamarada' in row38, 'data/maps/CinnabarIsland_Gym/scripts.inc')
    p = page('pokemon/%s.md' % slug(g, 'CHARMANDER'))
    check('Charmander aprende Lanzallamas al Nv 31', '| 31 | [Lanzallamas (Flamethrower)](' in p, 'src/data/pokemon/level_up_learnsets.h')
    check('Lanzallamas en la página de ataques: Charmander al Nv 31', '[Charmander](pokemon/004-charmander.md) (Nv 31)' in page('ataques.md'),
          'src/data/pokemon/level_up_learnsets.h')
    p = page('pokemon/%s.md' % slug(g, 'GASTLY'))
    check('Gastly da 1 EV de At. Esp.', '| EVs al derrotarlo | 1 At. Esp. |' in p, 'src/data/pokemon/species_info.h')
    return res


def main():
    rev = fetch()
    g = load()
    g.PHYS = physical_types(g)
    check_sprites(g)
    enc, obt = all_pokemon(g)
    page_ataques(g)
    src = page_mts(g)
    page_objetos(g, src)
    page_tutores(g)
    page_entrenadores(g)
    page_evs(g, enc)
    page_diferencias(g, enc, obt)
    page_index(g, rev)
    print('docs/guia written: %d species' % len([s for s in g.info if dex(g, s)]))
    if '--check' in sys.argv:
        for line in verify(g):
            print(line)
        print('PokeAPI matching:', dict(g.unmatched))


if __name__ == '__main__':
    main()
