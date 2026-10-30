"""Generates FRLG_FarmBot.lua (CRLF, for Windows) from src/.
Uses the Shiny Bot name tables and the Train Bot game data
(trainbot/src/train_tables.lua, generated from pret/pokefirered) without copying them.
Usage:  python farmbot/build.py
"""
import os
H = os.path.dirname(os.path.abspath(__file__))
s = open(os.path.join(H, 'src', 'farm_body.lua'), encoding='utf-8').read()
t = open(os.path.join(H, '..', 'shinybot', 'src', 'tables2.lua'), encoding='utf-8').read().rstrip() + '\n'
d = open(os.path.join(H, '..', 'trainbot', 'src', 'train_tables.lua'), encoding='utf-8').read().rstrip() + '\n'
out = s.replace('--@@TABLES@@', t).replace('--@@DATA@@', d)
open(os.path.join(H, 'FRLG_FarmBot.lua'), 'w', newline='\r\n', encoding='utf-8').write(out)
print('FRLG_FarmBot.lua:', len(out.splitlines()), 'lineas')
