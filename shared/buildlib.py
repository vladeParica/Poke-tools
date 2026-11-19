"""Builds a bot's single .lua file from its src/ (ADR-0015).

Every bot is still ONE file, the one VBA-rr loads. Markers in the bot's body are replaced:
  --@@INCLUDE name@@   shared/lua/name.lua (code shared by several bots)
  --@@TABLES@@         shinybot/src/tables2.lua (names the JSON configs accept)
  --@@DATA@@           game data tables, rendered from shared/gamedata/gamedata.json
  --@@LANG@@           translations (ADR-0014)
"""
import os
import re
import sys

SHARED = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(SHARED)
sys.path.insert(0, SHARED)
sys.path.insert(0, os.path.join(ROOT, 'tools', 'gamedata'))
from langgen import lang_lua  # noqa: E402
from to_lua import train_tables  # noqa: E402


def read(*parts):
    with open(os.path.join(ROOT, *parts), encoding='utf-8') as f:
        return f.read()


def include(src):
    def one(m):
        return read('shared', 'lua', m.group(1) + '.lua').rstrip() + '\n'
    return re.sub(r'^--@@INCLUDE (\w+)@@\n', one, src, flags=re.M)


def build(body, out_name):
    """body: the bot's src file (path from the repo root); out_name: the generated file."""
    s = include(read(*body.split('/')))
    out = s.replace('--@@TABLES@@', read('shinybot', 'src', 'tables2.lua').rstrip() + '\n')
    if '--@@DATA@@' in out:
        out = out.replace('--@@DATA@@', train_tables().rstrip() + '\n')
    out = out.replace('--@@LANG@@', lang_lua())
    path = os.path.join(ROOT, os.path.dirname(os.path.dirname(body)), out_name)
    with open(path, 'w', newline='\r\n', encoding='utf-8') as f:
        f.write(out)
    print('%s: %d lineas' % (out_name, len(out.splitlines())))
    return out
