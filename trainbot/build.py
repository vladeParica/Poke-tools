"""Generates FRLG_TrainBot.lua (CRLF, for Windows) from src/.
src/train_tables.lua is regenerated with tools/gen_tables.py (pret/pokefirered data).
Usage:  python trainbot/build.py
"""
import os
import sys
H = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(H, '..', 'shared'))
from langgen import lang_lua  # noqa: E402
s = open(os.path.join(H, 'src', 'train_body.lua'), encoding='utf-8').read()
t = open(os.path.join(H, '..', 'shinybot', 'src', 'tables2.lua'), encoding='utf-8').read().rstrip() + '\n'
d = open(os.path.join(H, 'src', 'train_tables.lua'), encoding='utf-8').read().rstrip() + '\n'
out = s.replace('--@@TABLES@@', t).replace('--@@DATA@@', d).replace('--@@LANG@@', lang_lua())
open(os.path.join(H, 'FRLG_TrainBot.lua'), 'w', newline='\r\n', encoding='utf-8').write(out)
print('FRLG_TrainBot.lua:', len(out.splitlines()), 'lineas')
