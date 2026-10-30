"""Integration test: the real bots accept every JSON the configurator exports.

Each exported config is loaded by the generated bot inside the Lua simulator (lupa) with
a tiny frame budget: the bot parses and validates its JSON at startup and prints
"Config cargada" on success, "Config: ..." or "Error en ..." otherwise.
Also checks that the configurator's option list matches the bots' CONFIG tables.
Run:  python configurator/tests/test_bots_accept.py
"""
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

import lupa.lua51 as L

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
OBSOLETE = {'rngMaxSearch', 'wildMaxSearch', 'reseedBeyond'}


def node(script):
    return subprocess.run(['node', '-e', script], cwd=ROOT, capture_output=True, text=True, check=True).stdout


def lua_config_keys(path):
    src = open(path, encoding='utf-8').read()
    block = re.search(r'^local CONFIG = \{(.*?)^\}', src, re.S | re.M).group(1)
    return {k for k in re.findall(r'^\s*(\w+)\s*=', block, re.M)}


def run_shiny(text):
    d = tempfile.mkdtemp()
    try:
        open(os.path.join(d, 'FRLG_ShinyBot.json'), 'w', encoding='utf-8', newline='').write(text)
        src = open(os.path.join(ROOT, 'shinybot', 'FRLG_ShinyBot.lua'), encoding='utf-8').read()
        mock = open(os.path.join(ROOT, 'shinybot', 'tests', 'mock_io.lua'), encoding='utf-8').read()
        mock = mock.replace('io = { open = function() return nil end, write = io.write }', '')
        mock = mock.replace('local MAXF = 400000', 'local MAXF = 120')
        # Capture print() into a Lua table instead of writing to the console.
        mock = mock.replace('io.write("  | " .. table.concat(t, " ") .. "\\n")', 'PRINTED[#PRINTED + 1] = table.concat(t, " ")')
        lua = L.LuaRuntime()
        lua.execute('PRINTED = {}')
        ls = lua.eval('function(s,n) return assert(loadstring(s,n)) end')
        ls(mock, 'mock')('wild', 3, True, None)(ls(src, '@' + d.replace('\\', '/') + '/FRLG_ShinyBot.lua'))
        printed = lua.globals().PRINTED
        return '\n'.join(printed[i] for i in range(1, len(printed) + 1))
    finally:
        shutil.rmtree(d, ignore_errors=True)


def run_train(text):
    d = tempfile.mkdtemp()
    old = os.getcwd()
    try:
        os.chdir(d)
        open('FRLG_TrainBot.json', 'w', encoding='utf-8', newline='').write(text)
        src = open(os.path.join(ROOT, 'trainbot', 'FRLG_TrainBot.lua'), encoding='utf-8').read()
        mock = open(os.path.join(ROOT, 'trainbot', 'tests', 'mock_train.lua'), encoding='utf-8').read()
        mock = mock.replace('local MAXF = 600000', 'local MAXF = 120')
        lua = L.LuaRuntime()
        ls = lua.eval('function(s,n) return assert(loadstring(s,n)) end')
        r = tuple(ls(mock, 'mock')('evs')(ls(src, 'bot')))
        return str(r[9])
    finally:
        os.chdir(old)
        shutil.rmtree(d, ignore_errors=True)


def main():
    failures = 0

    # 1. Option parity with the Lua CONFIG tables.
    schema_keys = json.loads(node(
        "const s=require('./configurator/js/schema.js');"
        "process.stdout.write(JSON.stringify({shinybot:s.fields('shinybot').map(f=>f.key),trainbot:s.fields('trainbot').map(f=>f.key)}))"))
    for bot, path in (('shinybot', 'shinybot/src/bot_body.lua'), ('trainbot', 'trainbot/src/train_body.lua')):
        lua_keys = lua_config_keys(os.path.join(ROOT, path)) - OBSOLETE
        ui_keys = set(schema_keys[bot])
        missing, extra = sorted(lua_keys - ui_keys), sorted(ui_keys - lua_keys)
        if missing or extra:
            failures += 1
            print('FAIL %s schema parity: missing in configurator %s, unknown to the bot %s' % (bot, missing, extra))
        else:
            print('ok   %s schema matches CONFIG (%d options)' % (bot, len(ui_keys)))

    # 2. Every exported config loads cleanly in the real bot.
    fixtures = json.loads(subprocess.run(['node', os.path.join(ROOT, 'configurator', 'tests', 'fixtures.js')],
                                         capture_output=True, text=True, check=True).stdout)
    for bot, runner in (('shinybot', run_shiny), ('trainbot', run_train)):
        for i, text in enumerate(fixtures[bot]):
            out = runner(text)
            bad = [l for l in out.splitlines() if l.startswith('Config: ') or l.startswith('Error en ')]
            if 'Config cargada' in out and not bad:
                print('ok   %s fixture %d accepted by the bot' % (bot, i))
            else:
                failures += 1
                print('FAIL %s fixture %d: %s' % (bot, i, bad or out[-400:]))

    if failures:
        print('%d failure(s)' % failures)
        sys.exit(1)
    print('all good')


if __name__ == '__main__':
    main()
