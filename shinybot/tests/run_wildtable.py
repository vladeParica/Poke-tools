"""Wild RNG with a species filter on every ROM layout of the encounter table.

gWildMonHeaders is at a different address in each build. In LeafGreen 1.1 the FireRed 1.0
address falls on the table's 18th header, so the maps before it (Viridian Forest among them)
used to be missing ("Este mapa (1.0) no tiene encuentros"). Each case hunts on map 3.3, the
4th header, and must reach the target (PAUSED).
Usage:  cd shinybot/tests && python run_wildtable.py      (exit code 1 on failure)
"""
import os
import sys
os.chdir(os.path.dirname(os.path.abspath(__file__)))  # the tests run from shinybot/tests
import lupa.lua51 as L  # noqa: E402

bot = open('../FRLG_ShinyBot.lua', encoding='utf-8').read().replace('species       = nil,', 'species       = {"Pikachu"},')
mock0 = open('mock_wild.lua', encoding='utf-8').read()
HEADER = 'w8(0x080000AE, 0x52); w8(0x080000AF, 0x45); w8(0x080000BC, 0)'
assert 'local HDR = 0x083C9CB8' in mock0 and HEADER in mock0 and 'w8(SB1 + 4, 3); w8(SB1 + 5, 19)' in mock0
# as many headers as the real table (about 132), so a start 17 headers late still looks valid
assert 'for i = 0, 39 do' in mock0 and 'HDR + 40 * 20' in mock0
mock0 = mock0.replace('for i = 0, 39 do', 'for i = 0, 131 do').replace('HDR + 40 * 20', 'HDR + 132 * 20')

# (name, game code, language, revision, table address). The mock has USA RAM, so the language
# stays 'E'; the last case moves the table so the bot has to search for it.
CASES = [
    ('FireRed 1.0', 0x52, 0x45, 0, 0x083C9CB8),
    ('FireRed 1.1', 0x52, 0x45, 1, 0x083C9D28),
    ('LeafGreen 1.0', 0x47, 0x45, 0, 0x083C9AF4),
    ('LeafGreen 1.1', 0x47, 0x45, 1, 0x083C9B64),
    ('table at another address (search)', 0x52, 0x45, 0, 0x083D1000),
]


def run(code, lang, rev, hdr):
    mock = (mock0.replace('local HDR = 0x083C9CB8', 'local HDR = 0x%08X' % hdr)
                 .replace(HEADER, 'w8(0x080000AE, 0x%02X); w8(0x080000AF, 0x%02X); w8(0x080000BC, %d)' % (code, lang, rev))
                 .replace('w8(SB1 + 4, 3); w8(SB1 + 5, 19)', 'w8(SB1 + 4, 3); w8(SB1 + 5, 3)'))
    lua = L.LuaRuntime()
    out = []
    lua.globals().py_out = out.append
    lua.execute('io.write = function(s) py_out(s) end')
    ls = lua.eval('function(s,n) return assert(loadstring(s,n)) end')
    r = tuple(ls(mock, 'mock')('wild', 0, True, True)(ls(bot, 'bot')))
    return str(r[1]), int(r[2]), ''.join(out)


bad = 0
for name, code, lang, rev, hdr in CASES:
    err, frames, text = run(code, lang, rev, hdr)
    ok = 'PAUSED' in err
    print('%s %-40s err=%s frames=%d' % ('ok  ' if ok else 'FAIL', name, err.split(':')[-1].strip(), frames))
    if not ok:
        print('\n'.join(l for l in text.split('\n') if 'mapa' in l.lower() or 'tabla' in l.lower())[:400])
    bad += not ok
sys.exit(1 if bad else 0)
