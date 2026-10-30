"""Genera FRLG_FarmBot.lua (CRLF, para Windows) a partir de src/.
Usa las tablas de nombres del Shiny Bot y los datos del juego del Train Bot
(trainbot/src/train_tables.lua, generado desde pret/pokefirered), sin copiarlos.
Uso:  python farmbot/build.py
"""
import os
H = os.path.dirname(os.path.abspath(__file__))
s = open(os.path.join(H, 'src', 'farm_body.lua'), encoding='utf-8').read()
t = open(os.path.join(H, '..', 'shinybot', 'src', 'tables2.lua'), encoding='utf-8').read().rstrip() + '\n'
d = open(os.path.join(H, '..', 'trainbot', 'src', 'train_tables.lua'), encoding='utf-8').read().rstrip() + '\n'
out = s.replace('--@@TABLES@@', t).replace('--@@DATA@@', d)
open(os.path.join(H, 'FRLG_FarmBot.lua'), 'w', newline='\r\n', encoding='utf-8').write(out)
print('FRLG_FarmBot.lua:', len(out.splitlines()), 'lineas')
