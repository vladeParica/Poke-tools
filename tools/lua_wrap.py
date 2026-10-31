"""One-off helper used to wrap the bots' player-facing Spanish text in TX"..." (ADR-0014).

  python tools/lua_wrap.py <file.lua> plan     print what would be wrapped
  python tools/lua_wrap.py <file.lua> apply    rewrite the file

Rules (kept conservative so game logic never changes):
- a literal is wrapped if it reads like text (has a space, ':' or '%' with letters, or is
  in SINGLE), it is not next to == / ~=, and its line is not a command, path or pattern;
- literals listed in NEVER are left alone;
- lines marked --@i18n hold lookup tables translated where they are used, so their
  literals are not wrapped here.
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lua_i18n import lua_strings  # noqa: E402

# Single words that are shown to the player (no space, so the generic rule misses them).
SINGLE = {
    'Detenido', 'Combate', 'Curando', 'cerrado', 'ABIERTO', 'nada', 'ninguno', 'entrenador', 'salvaje',
    'pelear', 'huir', 'neutra', 'Rival', 'Stat', 'COMPLETO', 'evitada', 'experiencia', 'debilitado',
    'MT/tutor', 'SALIR', 'PS', 'At', 'Df', 'AtE', 'DfE', 'Vel', 'no', 'si',
}
# Never wrapped: compared values, protocol words, file names, emulator colors…
NEVER = {'no existe', 'OFF', 'green', 'orange', 'red', 'yellow', 'white', 'IV',
         # log formats the configurator's stats parse, kept the same in every language
         '[Instancia %d] %s', '[%s] [%s] [Instancia %d] %s', 'SHINY Square', 'SHINY Star'}
BAD_CONTEXT = re.compile(r'writeFile\(|os\.execute|io\.open|f:write|:match\(|:gmatch\(|:find\(|:gsub\(|curl |mkdir|os\.remove|require\(')


def candidates(src):
    out = []
    for a, b, val, q in lua_strings(src):
        line_start = src.rfind('\n', 0, a) + 1
        line_end = src.find('\n', b)
        line = src[line_start:line_end if line_end >= 0 else len(src)]
        if '--@i18n' in line or BAD_CONTEXT.search(line):
            continue
        if val in NEVER or not re.search(r'[A-Za-záéíóúñ]', val) or re.match(r'FRLG \w+ Bot v[\d.]+|H-\d', val):
            continue
        before = src[max(0, a - 6):a]
        after = src[b:b + 6]
        if re.search(r'[=~]=\s*$', before) or re.match(r'\s*[=~]=', after):
            continue
        if re.search(r'\bTX\s*\(?\s*$', before):
            continue  # already wrapped
        texty = (' ' in val or ':' in val) and re.search(r'[A-Za-z]{2}', val)
        if not (texty or val in SINGLE):
            continue
        out.append((a, b, val))
    return out


def main():
    path, cmd = sys.argv[1], sys.argv[2]
    src = open(path, encoding='utf-8', newline='').read()
    cands = candidates(src)
    if cmd == 'plan':
        for a, b, val in cands:
            print('%d\t%s' % (src.count('\n', 0, a) + 1, val))
        print('%d literals' % len(cands), file=sys.stderr)
    elif cmd == 'apply':
        out, last = [], 0
        for a, b, val in cands:
            out.append(src[last:a]); out.append('TX' + src[a:b]); last = b
        out.append(src[last:])
        open(path, 'w', encoding='utf-8', newline='').write(''.join(out))
        print('wrapped %d literals' % len(cands))


if __name__ == '__main__':
    main()
