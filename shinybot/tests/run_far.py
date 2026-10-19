import os, tempfile
os.chdir(os.path.dirname(os.path.abspath(__file__)))  # las pruebas corren desde shinybot/tests
import lupa.lua51 as L, time, sys
base=open('../FRLG_ShinyBot.lua').read()
cases=[
 ('static','mock_rng.lua','nil','{"Timid"}'),
 ('wild','mock_wild.lua','{"Pikachu"}','{"Timid"}'),
 ('wild','mock_wild.lua','nil','nil'),
]
for mode,mock,sp,nat in cases:
  src=base.replace('species       = nil,','species       = %s,'%sp).replace('natures       = nil,','natures       = %s,'%nat)
  lua=L.LuaRuntime(); ls=lua.eval('function(s,n) return assert(loadstring(s,n)) end')
  t=time.time()
  r=tuple(ls(open(mock).read(),'mock')(mode,0,True,True)(ls(src,'bot')))
  print('=====',mode,sp,nat,'->',r[1],'frames',r[2],'%.1fs'%(time.time()-t)); print(r[0]); sys.stdout.flush()
