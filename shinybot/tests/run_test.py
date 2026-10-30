import os, tempfile
os.chdir(os.path.dirname(os.path.abspath(__file__)))  # the tests run from shinybot/tests
import lupa.lua51 as L
src=open('../FRLG_ShinyBot.lua').read()
mock=open('mock.lua').read()
for mode in ['wild','static','gift','roamer']:
  for clear in [True, False]:
    lua=L.LuaRuntime()
    ls=lua.eval('function(s,n) return assert(loadstring(s,n)) end')
    runner=ls(mock,'mock')(mode,3,clear)
    res=runner(ls(src,'bot'))
    print(mode, 'clearRAM' if clear else 'keepRAM', '->', tuple(res)[:6], 'gaps:', str(res[6])[:50], 'inBattle:',res[7])
