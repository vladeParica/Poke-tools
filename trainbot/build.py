"""Genera FRLG_TrainBot.lua (CRLF, para Windows) a partir de src/.
src/train_tables.lua se regenera con tools/gen_tables.py (datos de pret/pokefirered).
Uso:  python trainbot/build.py
"""
import os
H = os.path.dirname(os.path.abspath(__file__))
s = open(os.path.join(H, 'src', 'train_body.lua'), encoding='utf-8').read()
t = open(os.path.join(H, '..', 'shinybot', 'src', 'tables2.lua'), encoding='utf-8').read().rstrip() + '\n'
d = open(os.path.join(H, 'src', 'train_tables.lua'), encoding='utf-8').read().rstrip() + '\n'
out = s.replace('--@@TABLES@@', t).replace('--@@DATA@@', d)
open(os.path.join(H, 'FRLG_TrainBot.lua'), 'w', newline='\r\n', encoding='utf-8').write(out)
print('FRLG_TrainBot.lua:', len(out.splitlines()), 'lineas')
