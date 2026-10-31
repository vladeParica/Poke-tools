"""Builds the bots' translation table from shared/lang/<code>.json (ADR-0014).

Each JSON maps the Spanish text the bots write to that language. The build scripts
replace the --@@LANG@@ line of a bot with lang_lua(): the LANG table plus TX(), which
returns the text in CONFIG.language (Spanish when there is no entry).
"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
LANGS = ('en', 'ja')


def load(code):
    with open(os.path.join(HERE, 'lang', code + '.json'), encoding='utf-8') as f:
        return json.load(f)


def lua_str(s):
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n') + '"'


def lang_lua():
    out = ['-- Player-facing text is written in Spanish and shown in CONFIG.language (ADR-0014).',
           '-- Generated from shared/lang/*.json by the build script.',
           'local LANG = {']
    for code in LANGS:
        out.append('  %s = {' % code)
        for k, v in sorted(load(code).items()):
            out.append('    [%s] = %s,' % (lua_str(k), lua_str(v)))
        out.append('  },')
    out.append('}')
    out.append('local function TX(s)')
    out.append('  local d = LANG[CONFIG.language]')
    out.append('  return d and d[s] or s')
    out.append('end')
    return '\n'.join(out)
