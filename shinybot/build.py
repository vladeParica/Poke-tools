"""Genera FRLG_ShinyBot.lua (CRLF, para Windows) a partir de src/.
Uso:  python shinybot/build.py
"""
import os
H = os.path.dirname(os.path.abspath(__file__))
s = open(os.path.join(H, 'src', 'bot_body.lua'), encoding='utf-8').read()
t = open(os.path.join(H, 'src', 'tables2.lua'), encoding='utf-8').read()
out = s.replace('--@@TABLES@@', t.rstrip() + '\n')
open(os.path.join(H, 'FRLG_ShinyBot.lua'), 'w', newline='\r\n', encoding='utf-8').write(out)
print('FRLG_ShinyBot.lua:', len(out.splitlines()), 'lineas')
