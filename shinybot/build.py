"""Generates FRLG_ShinyBot.lua (CRLF, for Windows) from src/.
Usage:  python shinybot/build.py
"""
import os
import sys
H = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(H, '..', 'shared'))
from langgen import lang_lua  # noqa: E402
s = open(os.path.join(H, 'src', 'bot_body.lua'), encoding='utf-8').read()
t = open(os.path.join(H, 'src', 'tables2.lua'), encoding='utf-8').read()
out = s.replace('--@@TABLES@@', t.rstrip() + '\n').replace('--@@LANG@@', lang_lua())
open(os.path.join(H, 'FRLG_ShinyBot.lua'), 'w', newline='\r\n', encoding='utf-8').write(out)
print('FRLG_ShinyBot.lua:', len(out.splitlines()), 'lineas')
