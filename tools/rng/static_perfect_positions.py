M=0xFFFFFFFF
A,C=0x41C64E6D,0x6073; RA,RC=0xEEB9EB65,0x0A3561A1
nx=lambda s:(s*A+C)&M; pv=lambda s:(s*RA+RC)&M
N="Hardy Lonely Brave Adamant Naughty Bold Docile Relaxed Impish Lax Timid Hasty Serious Jolly Naive Modest Mild Quiet Bashful Rash Calm Gentle Sassy Careful Quirky".split()
# Uso: python static_perfect_positions.py [TID SID [TID SID ...]]
# Sin argumentos lista las posiciones; con TID/SID dice en cuales partidas son shiny.
import sys
_a=[int(x) for x in sys.argv[1:]]
if len(_a)%2: sys.exit("Uso: python static_perfect_positions.py [TID SID [TID SID ...]]")
saves={f"{_a[i]}/{_a[i+1]}":_a[i]^_a[i+1] for i in range(0,len(_a),2)}
res=[]
for hi in range(0x7FFF<<1|0, (0x7FFF<<1)+2):
  pass
for top in (0x7FFF,0xFFFF):
  for lo in range(65536):
    s3=(top<<16)|lo           # IV1 call result state
    s4=nx(s3)
    if (s4>>16)&0x7FFF!=0x7FFF: continue
    s2=pv(s3); s1=pv(s2); s0=pv(s1)   # s1 -> PID low, s2 -> PID high
    pid=((s2>>16)<<16)|(s1>>16)
    res.append((s0,pid))
for s0,pid in res:
  nat=N[pid%25]; sv=(pid>>16)^(pid&0xFFFF)
  sh=[k for k,t in saves.items() if (t^sv)<8]
  # find nearest 16-bit initial seed by walking back
  s=s0; best=None
  for a in range(1,3000000):
    if s<0x10000: best=(s,a-1); break
    s=pv(s)
  print(f"PID {pid:08X} {nat:8s} semilla {best[0]:04X} avance {best[1]}  shiny en: {sh or '-'}" if best else f"{pid:08X} {nat} sin semilla cercana")
