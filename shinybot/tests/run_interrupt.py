"""Wild RNG when the calibration encounter was interrupted (mock_wild.lua, INTERRUPT_FIRST).

VBlank calls Random() every frame; if it lands in the middle of one generation, that encounter
looks like another call order (here H-4: one extra call between the IVs). The bot used to search
every target with that order and, for an exact target, found none ("No hay objetivo con esos
filtros"). The search must stay on H-1 unless the same order repeats.
Usage:  cd shinybot/tests && python run_interrupt.py      (exit code 1 on failure)
"""
import os
import sys
os.chdir(os.path.dirname(os.path.abspath(__file__)))  # the tests run from shinybot/tests
import lupa.lua51 as L  # noqa: E402

src = (open('../FRLG_ShinyBot.lua', encoding='utf-8').read()
       .replace('species       = nil,', 'species       = {"Pikachu"},')
       .replace('natures       = nil,', 'natures       = {"Jolly"},')
       .replace('reseed        = true,', 'reseed        = false,'))
mock = open('mock_wild.lua', encoding='utf-8').read()
lua = L.LuaRuntime()
out = []
lua.globals().py_out = out.append
lua.execute('INTERRUPT_FIRST = true; io.write = function(s) py_out(s) end')
ls = lua.eval('function(s,n) return assert(loadstring(s,n)) end')
r = tuple(ls(mock, 'mock')('wild', 0, True, True)(ls(src, 'bot')))
text = ''.join(out)
err = str(r[1])
ok = 'PAUSED' in err and 'llamada extra' in text and 'No hay objetivo' not in text
print('%s interrupted calibration  err=%s frames=%d' % ('ok  ' if ok else 'FAIL', err.split(':')[-1].strip(), int(r[2])))
if not ok:
    print(text[-1200:])
sys.exit(0 if ok else 1)
