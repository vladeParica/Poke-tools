"""Access to the pret/pokefirered sources (ADR-0015).

A sparse clone in trainbot/tools/pret_cache/pokefirered with only the folders the tools read.
Shared by the game data extractor (gamedata.py) and the guide generator (tools/guia).
"""
import os
import re
import subprocess

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
CACHE = os.path.join(ROOT, 'trainbot', 'tools', 'pret_cache')
PRET = os.path.join(CACHE, 'pokefirered')
PRET_REPO = 'https://github.com/pret/pokefirered.git'
SPARSE = ['/data/maps/', '/data/scripts/', '/data/event_scripts.s', '/src/data/', '/include/constants/',
          '/src/battle_main.c', '/src/battle_script_commands.c', '/src/party_menu.c',
          '/src/field_specials.c', '/src/pokemon.c', '/src/roamer.c', '/include/battle.h']
VER_SYM = {'FR': 'FIRERED', 'LG': 'LEAFGREEN'}


def fetch():
    """Makes sure the sparse clone exists with every folder the tools need; returns its commit."""
    if not os.path.isdir(os.path.join(PRET, '.git')):
        os.makedirs(CACHE, exist_ok=True)
        print('cloning pret/pokefirered (sparse)...')
        subprocess.check_call(['git', 'clone', '-q', '--depth', '1', '--filter=blob:none', '--sparse',
                               PRET_REPO, PRET])
    have = subprocess.check_output(['git', '-C', PRET, 'sparse-checkout', 'list'], text=True).split()
    if any(p not in have for p in SPARSE):
        env = dict(os.environ, MSYS_NO_PATHCONV='1')    # Git Bash would rewrite the /paths
        subprocess.check_call(['git', '-C', PRET, 'sparse-checkout', 'add'] + SPARSE, env=env)
    return subprocess.check_output(['git', '-C', PRET, 'rev-parse', 'HEAD'], text=True).strip()


def rd(rel):
    with open(os.path.join(PRET, rel), encoding='utf-8') as f:
        return f.read()


def defines(rel, prefix):
    """#define PREFIX_X value -> {name: int}, following defines that point to other defines."""
    d = {}
    for m in re.finditer(r'#define\s+(' + prefix + r'\w+)\s+(\S+)', rd(rel)):
        v = m.group(2)
        try:
            d[m.group(1)] = int(v, 0)
        except ValueError:
            if v in d:
                d[m.group(1)] = d[v]
    return d


def c_version(text, ver):
    """Keeps the #if defined(FIRERED) / #elif / #else branches of one version ('FR' or 'LG')."""
    out, stack = [], []
    for line in text.split('\n'):
        s = line.strip()
        m = re.match(r'#if\s+defined\s*\(?\s*(FIRERED|LEAFGREEN)\s*\)?', s)
        if m:
            stack.append(m.group(1) == VER_SYM[ver]); continue
        m = re.match(r'#elif\s+defined\s*\(?\s*(FIRERED|LEAFGREEN)\s*\)?', s)
        if m and stack:
            stack[-1] = m.group(1) == VER_SYM[ver]; continue
        if s.startswith('#else') and stack:
            stack[-1] = not stack[-1]; continue
        if s.startswith('#endif') and stack:
            stack.pop(); continue
        if all(stack):
            out.append(line)
    return '\n'.join(out)


def asm_version(text, ver):
    """Keeps the .ifdef FIRERED / .else / .ifdef LEAFGREEN branches of one version."""
    out, stack = [], []
    for line in text.split('\n'):
        s = line.strip()
        m = re.match(r'\.ifdef\s+(FIRERED|LEAFGREEN)\b', s)
        if m:
            stack.append(m.group(1) == VER_SYM[ver]); continue
        m = re.match(r'\.ifndef\s+(FIRERED|LEAFGREEN)\b', s)
        if m:
            stack.append(m.group(1) != VER_SYM[ver]); continue
        if s.startswith('.else') and stack:
            stack[-1] = not stack[-1]; continue
        if s.startswith('.endif') and stack:
            stack.pop(); continue
        if all(stack):
            out.append(line)
    return '\n'.join(out)


def entries(rel, prefix):
    """Blocks of a designated initializer laid out as '    [PREFIX_X] =' then '    {' ... '    }'
    (battle_moves.h, species_info.h). A one-line entry such as '[SPECIES_NONE] = {0},' is not
    one of them: matching it lazily up to the next closing brace would swallow the next entry."""
    return re.findall(r'^    \[' + prefix + r'(\w+)\] =\n    \{(.*?)\n    \}', rd(rel), re.S | re.M)
