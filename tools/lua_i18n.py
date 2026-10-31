"""Player-facing text in the Lua bots.

  python tools/lua_i18n.py scan <file.lua>      list string literals with their context
  python tools/lua_i18n.py keys <file.lua>...   list the TX"..." keys (the Spanish source texts)
  python tools/lua_i18n.py check                every key of every bot is translated in
                                                shared/lang/<code>.json with the same format
                                                specifiers (Japanese in ASCII romaji)

The bots write Spanish and wrap what the player sees in TX"..."; lookup tables whose
entries are shown with TX(t[k]) carry --@i18n on their lines. See ADR-0014.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BOT_SOURCES = ['shinybot/src/bot_body.lua', 'trainbot/src/train_body.lua', 'farmbot/src/farm_body.lua']
FMT = re.compile(r'%[-+ #0]*\d*(?:\.\d+)?[sdqxXfgicoeEuA%]')


def lua_strings(src):
    """Yield (start, end, value, quote) for every short string literal outside comments."""
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        if src.startswith('--', i):
            m = re.match(r'--\[(=*)\[', src[i:])
            if m:
                j = src.find(']' + m.group(1) + ']', i)
                i = n if j < 0 else j + len(m.group(1)) + 2
            else:
                j = src.find('\n', i)
                i = n if j < 0 else j
        elif c in '"\'':
            j, val = i + 1, []
            while j < n and src[j] != c:
                if src[j] == '\\':
                    val.append(src[j:j + 2]); j += 2
                else:
                    val.append(src[j]); j += 1
            yield i, j + 1, ''.join(val), c
            i = j + 1
        elif src.startswith('[[', i) or re.match(r'\[=+\[', src[i:i + 8]):
            m = re.match(r'\[(=*)\[', src[i:])
            j = src.find(']' + m.group(1) + ']', i)
            i = n if j < 0 else j + len(m.group(1)) + 2
        else:
            i += 1


def unescape(s):
    return re.sub(r'\\(.)', lambda m: {'n': '\n', 't': '\t'}.get(m.group(1), m.group(1)), s)


def keys_in(src):
    """Keys wrapped as TX"..." plus the literals of lines marked --@i18n."""
    out = []
    for a, b, val, q in lua_strings(src):
        line = src[src.rfind('\n', 0, a) + 1:src.find('\n', b)]
        if re.search(r'\bTX\s*\(?\s*$', src[max(0, a - 4):a]):
            out.append(unescape(val))
        elif '--@i18n' in line and re.search(r'[A-Za-z]', val):
            out.append(unescape(val))
    return out


def load_lang():
    import json
    return {code: json.load(open(os.path.join(ROOT, 'shared', 'lang', code + '.json'), encoding='utf-8'))
            for code in ('en', 'ja')}


def main():
    cmd = sys.argv[1]
    if cmd == 'scan':
        src = open(sys.argv[2], encoding='utf-8').read()
        for a, b, val, q in lua_strings(src):
            if re.search(r'[A-Za-záéíóúñ]{3}', val):
                line = src.count('\n', 0, a) + 1
                ctx = src[src.rfind('\n', 0, a) + 1:src.find('\n', b)].strip()
                print('%d\t%s\t%s' % (line, val, ctx[:150]))
    elif cmd == 'keys':
        for f in sys.argv[2:]:
            for k in keys_in(open(f, encoding='utf-8').read()):
                print(k)
    elif cmd == 'check':
        dicts = load_lang()
        keys = []
        for f in BOT_SOURCES:
            keys += keys_in(open(os.path.join(ROOT, f), encoding='utf-8').read())
        keys = list(dict.fromkeys(keys))
        bad = 0
        for lang in ('en', 'ja'):
            d = dicts.get(lang, {})
            for k in keys:
                if k not in d:
                    print('%s missing: %r' % (lang, k)); bad += 1
                elif FMT.findall(k) != FMT.findall(d[k]):
                    print('%s format mismatch: %r -> %r' % (lang, k, d[k])); bad += 1
                elif lang == 'ja' and not all(ord(ch) < 128 for ch in d[k]):
                    print('ja must be ASCII (romaji): %r' % d[k]); bad += 1
            for k in d:
                if k not in keys:
                    print('%s unused: %r' % (lang, k)); bad += 1
        print('%d keys, %d problems' % (len(keys), bad))
        sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
