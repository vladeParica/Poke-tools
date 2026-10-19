import os, tempfile
os.chdir(os.path.dirname(os.path.abspath(__file__)))  # las pruebas corren desde shinybot/tests
import lupa.lua51 as L, json, os, sys
D=tempfile.mkdtemp()+"/"
src=open('../FRLG_ShinyBot.lua').read()
tmpl=open('../FRLG_ShinyBot.json').read()
def run(mock, mode, rng, overrides, shinyAt=3):
  t=tmpl.replace('"mode": "Salvaje RNG",','"mode": null,')
  for k,v in overrides.items():
    import re
    t=re.sub(r'(?m)^(\s*)"%s": [^\n]*?(,?)\s*(//.*)?$'%k, lambda m: '%s"%s": %s%s'%(m.group(1),k,v,m.group(2)), t, count=1)
  t=t.replace('"stopOthers": true','"stopOthers": false')
  open(D+'FRLG_ShinyBot.json','w').write(t)
  [os.remove(D+f) for f in os.listdir(D) if f.endswith('.flag')]
  lua=L.LuaRuntime(); ls=lua.eval('function(s,n) return assert(loadstring(s,n)) end')
  m=open(mock).read().replace('io = { open = function() return nil end, write = io.write }','')
  r=tuple(ls(m,'mock')(mode,shinyAt,True,rng)(ls(src,'@'+D+'FRLG_ShinyBot.lua')))
  return r
for name,mock,mode,rng,ov in [
  ('json ok, salvaje', 'mock_io.lua','wild',None,{}),
  ('wild RNG pikachu modesta spe>=20','mock_wild.lua','wild',True,{'species':'["pikachu"]','natures':'["Modesta"]','minIVs':'{"vel": 20}'}),
  ('static RNG sin shiny hp31 spa31','mock_rng.lua','static',True,{'shiny':'false','minIVs':'{"hp":31,"spa":31}'}),
  ('static RNG shiny PO fuego','mock_rng.lua','static',True,{'hiddenPower':'{"type":"Fuego","minPower":50}'}),
  ('config con errores','mock_io.lua','wild',None,{'natures':'["Adamantx"]','species':'["Magnemite"]'}),
]:
  r=run(mock,mode,rng,ov)
  print('=====',name,'->',r[1][-30:], 'frames',r[2])
  print(r[0])
