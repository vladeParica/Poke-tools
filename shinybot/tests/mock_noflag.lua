-- Simulador minimo de VBA-rr + juego FRLG para probar la logica del bot
local MODE_TO_TEST, SHINY_AT, CLEAR_ON_RESET = ...
SHINY_AT = SHINY_AT or 3

-- ---------- bit (semantica LuaBitOp: resultados con signo 32 bits) ----------
local function tou(x) x = x % 4294967296; return x end
local function tos(x) x = tou(x); if x >= 2147483648 then return x - 4294967296 end return x end
local function bitop(a, b, f)
  a, b = tou(a), tou(b)
  local r, p = 0, 1
  for i = 0, 31 do
    local x, y = a % 2, b % 2
    if f(x, y) then r = r + p end
    a, b, p = (a - x) / 2, (b - y) / 2, p * 2
  end
  return tos(r)
end
bit = {
  band = function(a, b) return bitop(a, b, function(x, y) return x == 1 and y == 1 end) end,
  bxor = function(a, b) return bitop(a, b, function(x, y) return x ~= y end) end,
  rshift = function(a, n) return tos(math.floor(tou(a) / 2 ^ n)) end,
  lshift = function(a, n) return tos(tou(a) * 2 ^ n) end,
}

-- ---------- memoria ----------
local mem = {}
local function r8(a) return mem[a] or 0 end
local function w8(a, v) mem[a] = v % 256 end
local function r16(a) return r8(a) + r8(a + 1) * 256 end
local function r32(a) return r16(a) + r16(a + 2) * 65536 end
local function w32(a, v) v = tou(v); for i = 0, 3 do w8(a + i, v % 256); v = math.floor(v / 256) end end
local function w16(a, v) w8(a, v % 256); w8(a + 1, math.floor(v / 256)) end
memory = { readdwordunsigned = r32, readwordunsigned = r16, readbyte = r8, writedword = w32,
           registerwrite = function() end }

local ENEMY, PARTY, PCNT, SB1P, SB2P, INB = 0x0202402C, 0x02024284, 0x02024029, 0x03005008, 0x0300500C, 0x03003529
local SB1, SB2 = 0x0202552C, 0x02024588
local TID, SID = 12345, 54321

local function bootRAM()
  w8(0x080000AE, 0x52); w8(0x080000AF, 0x45); w8(0x080000BC, 0)
end
local function loadSave()
  w32(SB1P, SB1); w32(SB2P, SB2); w32(SB2 + 0xA, TID + SID * 65536); w8(PCNT, 2)
end
bootRAM(); loadSave()

local function growthOff(o) if o <= 5 then return 0 elseif o % 6 <= 1 then return 12 elseif o % 2 == 0 then return 24 else return 36 end end
local function miscOff(o) if o >= 18 then return 0 elseif o % 6 >= 4 then return 12 elseif o % 2 == 1 then return 24 else return 36 end end

local function createMon(addr, pid, species, ivword)
  local otid = TID + SID * 65536
  local data = {}
  for i = 0, 11 do data[i] = 0 end
  local o = pid % 24
  data[growthOff(o) / 4] = species
  data[miscOff(o) / 4 + 1] = ivword
  local sum = 0
  for i = 0, 11 do sum = sum + data[i] % 65536 + math.floor(data[i] / 65536) end
  w32(addr, pid); w32(addr + 4, otid); w16(addr + 0x1C, sum % 65536); w8(addr + 0x54, 5)
  local key = bit.bxor(pid, otid)
  for i = 0, 11 do w32(addr + 0x20 + i * 4, bit.bxor(data[i], key)) end
end

local function randPid(shiny)
  local hi = math.random(0, 65535)
  local lo
  if shiny then lo = bit.bxor(bit.bxor(TID, SID), hi) % 65536
  else repeat lo = math.random(0, 65535) until bit.bxor(bit.bxor(bit.bxor(TID, SID), hi), lo) >= 8 end
  return hi * 65536 + lo
end

-- ---------- estado del "juego" ----------
local frame, held, prevHeld = 0, {}, {}
local stats = { encounters = 0, resets = 0, flees = 0, resetFrames = {} }
local g = { walkHeld = 0, steps = 0, battle = nil, loadAt = nil, aCount = 0, made = 0 }

local function edge(b) return held[b] and not prevHeld[b] end

local function gameFrame()
  -- soft reset
  if held.A and held.B and held.select and held.start then
    if not g.resetting then
      g.resetting = true
      stats.resets = stats.resets + 1
      stats.resetFrames[#stats.resetFrames + 1] = frame
      if CLEAR_ON_RESET then mem = {}; bootRAM() end
      g.loadAt = frame + 200; g.aCount = 0; g.battle = nil; w8(INB, 0)
    end
    return
  end
  g.resetting = false
  if g.loadAt then
    if frame >= g.loadAt then
      loadSave(); g.loadAt = nil
      w8(SB1 + 0x30D0 + 0x13, 0)        -- roamer inactivo en el save
      w8(PCNT, 2)
    end
    return
  end

  if MODE_TO_TEST == "wild" then
    if not g.battle then
      if held.left or held.right then g.walkHeld = g.walkHeld + 1 else g.walkHeld = 0 end
      if g.walkHeld > 0 and g.walkHeld % 16 == 0 then
        g.steps = g.steps + 1
        if g.steps % 4 == 0 then
          stats.encounters = stats.encounters + 1
          createMon(ENEMY, randPid(stats.encounters == SHINY_AT), 25, 0x3FFFFFFF)
          g.battle = { start = frame, cx = 0, cy = 0, sub = false, ending = nil }
        end
      end
    else
      local b = g.battle
      -- no flag
      if frame - b.start > 140 and not b.ending then
        if b.sub then
          if edge("B") then b.sub = false end
        else
          if edge("right") then b.cx = 1 end
          if edge("left") then b.cx = 0 end
          if edge("down") then b.cy = 1 end
          if edge("up") then b.cy = 0 end
          if edge("A") then
            if b.cx == 1 and b.cy == 1 then b.ending = frame + 60; stats.flees = stats.flees + 1
            elseif b.cx == 0 and b.cy == 0 then b.sub = true end
          end
        end
      end
      if b.ending and frame >= b.ending then w8(INB, 0); g.battle = nil end
    end
  else
    if edge("A") then
      g.aCount = g.aCount + 1
      if g.aCount == 6 then
        g.made = g.made + 1
        local pid = randPid(g.made == SHINY_AT)
        if MODE_TO_TEST == "static" then createMon(ENEMY, pid, 150, 0x12345678)
        elseif MODE_TO_TEST == "gift" then createMon(PARTY + 2 * 0x64, pid, 133, 0x3FFFFFFF); w8(PCNT, 3)
        elseif MODE_TO_TEST == "roamer" then
          local r = SB1 + 0x30D0
          w32(r, 0x1F); w32(r + 4, pid); w16(r + 8, 243); w8(r + 0x13, 1)
        end
      end
    end
  end
end

-- ---------- API emulador ----------
local MAXF = 400000
local pendingPad = {}
joypad = { set = function(_, t) pendingPad = t or {} end }
gui = { text = function() end, line = function() end }
savestate = { create = function() return {} end, save = function() end, load = function() end }
local hotkeys = {}
input = { get = function() return hotkeys[frame] or {} end }
emu = {
  framecount = function() return frame end,
  pause = function() error("PAUSED") end,
  frameadvance = function()
    prevHeld = held; held = pendingPad; pendingPad = {}
    gameFrame()
    frame = frame + 1
    if frame > MAXF then error("TIMEOUT") end
  end,
}
_G.print = function(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring(select(i, ...)) end io.write("  | " .. table.concat(t, " ") .. "\n") end
io = { open = function() return nil end, write = io.write }

-- pulsar 8 (cambiar modo) las veces necesarias y 7 para iniciar
local modeIndex = ({ wild = 1, static = 2, gift = 3, roamer = 4 })[MODE_TO_TEST]
local f = 5
for i = 2, modeIndex do hotkeys[f] = { ["8"] = true }; f = f + 3 end
hotkeys[f] = { ["7"] = true }

return function(chunk)
  local ok, err = pcall(chunk)
  local gaps = {}
  for i = 2, #stats.resetFrames do gaps[#gaps + 1] = stats.resetFrames[i] - stats.resetFrames[i - 1] end
  return tostring(err), frame, stats.encounters, stats.resets, stats.flees, g.made, table.concat(gaps, ","), (g.battle ~= nil)
end
