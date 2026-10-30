import os, tempfile
os.chdir(os.path.dirname(os.path.abspath(__file__)))  # the tests run from shinybot/tests
import lupa.lua51 as L, time, sys
base=open('../FRLG_ShinyBot.lua').read()
cases=[('nil','nil'),('{"Pikachu"}','nil'),('{"Pikachu"}','{"Jolly"}')]
for sp,nat in cases:
  src=base.replace('species       = nil,','species       = %s,'%sp).replace('natures       = nil,','natures       = %s,'%nat)
  lua=L.LuaRuntime(); ls=lua.eval('function(s,n) return assert(loadstring(s,n)) end')
  t=time.time()
  r=tuple(ls(open('mock_wild.lua').read(),'mock')('wild',0,True,True)(ls(src,'bot')))
  print('species',sp,'nature',nat,'-> err=',r[1],'frames=',r[2],'encounters=',r[2],'flees=',r[4],'loads=',r[8],'%.1fs'%(time.time()-t)); sys.stdout.flush()
