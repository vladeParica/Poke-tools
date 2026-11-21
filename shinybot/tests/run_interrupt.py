"""Wild RNG when the game interrupts a generation (mock_wild.lua).

VBlank calls Random() every frame; if it lands in the middle of a generation, that encounter
looks like another call order (here H-4: one extra call between the IVs).
- first:  only the calibration encounter is interrupted. The bot used to search every target
          with that order and, for an exact target, found none ("No hay objetivo con esos
          filtros"). The search must stay on H-1.
- target: the target itself is always interrupted (same PID, other IVs), as a frame that always
          overruns would be. Retrying the same thing gives the same result, so the bot must say
          so and stop, not loop or mistake it for another call order.
Usage:  cd shinybot/tests && python run_interrupt.py      (exit code 1 on failure)
"""
import os
import sys
os.chdir(os.path.dirname(os.path.abspath(__file__)))  # the tests run from shinybot/tests
import lupa.lua51 as L  # noqa: E402

BOT = (open('../FRLG_ShinyBot.lua', encoding='utf-8').read()
       .replace('species       = nil,', 'species       = {"Pikachu"},')
       .replace('reseed        = true,', 'reseed        = false,'))
MOCK = open('mock_wild.lua', encoding='utf-8').read()


def run(setup, src):
    lua = L.LuaRuntime()
    out = []
    lua.globals().py_out = out.append
    lua.execute(setup + ' io.write = function(s) py_out(s) end')
    ls = lua.eval('function(s,n) return assert(loadstring(s,n)) end')
    r = tuple(ls(MOCK, 'mock')('wild', 0, True, True)(ls(src, 'bot')))
    return str(r[1]), int(r[2]), ''.join(out)


bad = 0
err, frames, text = run('INTERRUPT_FIRST = true;', BOT.replace('natures       = nil,', 'natures       = {"Jolly"},'))
ok = 'PAUSED' in err and 'llamada extra' in text and 'No hay objetivo' not in text
print('%s interrupted calibration  err=%s frames=%d' % ('ok  ' if ok else 'FAIL', err.split(':')[-1].strip(), frames))
bad += not ok
if not ok:
    print(text[-1200:])

# the shiny target (Speed 31 asked: the shifted second IV call almost never keeps it) is interrupted
src = BOT.replace('minIVs        = nil,', 'minIVs        = {spe = 31},')
assert src != BOT
err, frames, text = run('INTERRUPT_SHINY = true;', src)
# it stops (the mock then runs to its end: TIMEOUT) after two tries on the target
ok = (text.count('interrumpio la generacion') == 2 and 'otra casilla' in text and 'PAUSED' not in err
      and 'Orden de llamadas detectado' not in text)
print('%s interrupted target       err=%s frames=%d' % ('ok  ' if ok else 'FAIL', err.split(':')[-1].strip(), frames))
bad += not ok
if not ok:
    print(text[-1500:])
sys.exit(1 if bad else 0)
