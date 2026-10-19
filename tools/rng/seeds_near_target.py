"""Semillas iniciales (16 bits) desde las que se llega a un estado del RNG.

Uso:  python seeds_near_target.py <estado_hex> [max_avances]
  estado_hex   estado del RNG ANTES de la primera llamada del objetivo
               (para wild_h1_search.c: la primera columna; para estaticos:
               el estado anterior a la llamada del PID bajo)
  max_avances  distancia maxima (por defecto 2.000.000: con la Tele Pokemon
               el bot llega en 1-2 minutos)

Imprime la lista lista para "initialSeeds" del FRLG_ShinyBot.json y cuantas
"clases" (semilla mod 64) cubre: cuantas mas, mas probable caer en un reinicio.
"""
import sys
M = 0xFFFFFFFF
pv = lambda s: (s * 0xEEB9EB65 + 0x0A3561A1) & M   # LCRNG hacia atras

def seeds(target, limit=2000000):
    s, out = target, []
    for a in range(limit):
        if s < 0x10000:
            out.append((s, a))
        s = pv(s)
    return out

if __name__ == '__main__':
    t = int(sys.argv[1], 16)
    lim = int(sys.argv[2]) if len(sys.argv) > 2 else 2000000
    res = seeds(t, lim)
    print(len(res), 'semillas;', len(set(x & 63 for x, _ in res)), 'de 64 clases')
    for s, a in res[:10]:
        print('  %04X  a %d avances' % (s, a))
    print('"initialSeeds": [' + ', '.join('"%04X"' % s for s, _ in res) + ']')
