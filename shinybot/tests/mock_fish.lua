-- Fishing simulator for the Shiny Bot (modes Pesca RNG): the parts of the game the bot reads,
-- following pret field_player_avatar.c (Task_Fishing) and wild_encounter.c (fishing slots).
-- Globals the runner may set before loading it:
--   FISH_ROD   registered item: 262 Old, 263 Good, 264 Super (default), 0 = none
--   FISH_DRY   the player doesn't face water: SELECT only shows a message
--   TEXT_SPEED frames per character of "A POKeMON's on the hook!" (default 2; 8 = slow)
--   GAME_LANG  language byte of the ROM header (default 0x45, USA)
local FISH_ROD = rawget(_G, "FISH_ROD") or 264
local FISH_DRY = rawget(_G, "FISH_DRY")
local TEXT_SPEED = rawget(_G, "TEXT_SPEED") or 2
local GAME_LANG = rawget(_G, "GAME_LANG") or 0x45
local MODE_INDEX = rawget(_G, "MODE_INDEX") or 12

-- ---------- bit (LuaBitOp semantics: signed 32-bit results) ----------
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

-- ---------- memory ----------
local mem = {}
local function r8(a) return mem[a] or 0 end
local function w8(a, v) mem[a] = v % 256 end
local function r16(a) return r8(a) + r8(a + 1) * 256 end
local function r32(a) return r16(a) + r16(a + 2) * 65536 end
local function w32(a, v) v = tou(v); for i = 0, 3 do w8(a + i, v % 256); v = math.floor(v / 256) end end
local function w16(a, v) w8(a, v % 256); w8(a + 1, math.floor(v / 256)) end
memory = { readdwordunsigned = r32, readwordunsigned = r16, readbyte = r8, writedword = w32, writebyte = w8,
           registerwrite = function() end }

local ENEMY, PCNT, SB1P, SB2P, INB = 0x0202402C, 0x02024029, 0x03005008, 0x0300500C, 0x03003529
local SB1, SB2 = 0x0202552C, 0x02024588
local TID, SID = 12345, 54321
local RNGV = 0x03005000
local TASKS = 0x03005090
local TASK = TASKS + 3 * 40                 -- the fishing task takes slot 3
local TASK_FISHING = 0x0805D304 + 1          -- FireRed 1.0 USA, Thumb
local HDR = 0x083C9CB8                       -- gWildMonHeaders, FireRed 1.0 USA

-- fishing table of map 3.19 (10 slots: Old Rod 1-2, Good Rod 3-5, Super Rod 6-10)
local FISH = {
  { 5, 5, 129 }, { 5, 5, 129 },                                  -- Magikarp
  { 5, 15, 118 }, { 5, 15, 60 }, { 5, 15, 129 },                 -- Goldeen, Poliwag, Magikarp
  { 15, 25, 116 }, { 15, 25, 98 }, { 20, 30, 118 }, { 25, 35, 119 }, { 15, 25, 147 },  -- ... Dratini
}
local FISH_T = { [0] = { 70, 100 }, [1] = { 60, 80, 100 }, [2] = { 40, 80, 95, 99, 100 } }
local FISH_FIRST = { [0] = 1, [1] = 3, [2] = 6 }

local function bootRAM()
  w8(0x080000AE, 0x52); w8(0x080000AF, GAME_LANG); w8(0x080000BC, 0)
end
local function writeRom()
  for i = 0, 39 do
    local a = HDR + i * 20
    w8(a, 3); w8(a + 1, i); w8(a + 2, 0); w8(a + 3, 0)
    local land = 0x08400000 + i * 128
    w32(a + 4, land); w32(a + 8, 0); w32(a + 12, 0); w32(a + 16, land + 64)
    w8(land, 21); w32(land + 4, land + 8)
    for k = 0, 11 do local m = land + 8 + k * 4; w8(m, 3); w8(m + 1, 5); w16(m + 2, 16) end
    local fi = land + 64
    w8(fi, 20); w32(fi + 4, fi + 8)
    for k = 0, 9 do local m = fi + 8 + k * 4; w8(m, FISH[k + 1][1]); w8(m + 1, FISH[k + 1][2]); w16(m + 2, FISH[k + 1][3]) end
  end
  w8(HDR + 40 * 20, 0xFF)
end
local function loadSave()
  w32(SB1P, SB1); w32(SB2P, SB2); w32(SB2 + 0xA, TID + SID * 65536); w8(PCNT, 2)
  w8(0x02037078, 1); w16(SB1 + 0x296, FISH_ROD)
  w8(SB1 + 4, 3); w8(SB1 + 5, 19)
  writeRom()
end
bootRAM(); loadSave()

local function growthOff(o) if o <= 5 then return 0 elseif o % 6 <= 1 then return 12 elseif o % 2 == 0 then return 24 else return 36 end end
local function miscOff(o) if o >= 18 then return 0 elseif o % 6 >= 4 then return 12 elseif o % 2 == 1 then return 24 else return 36 end end

local function createMon(addr, pid, species, ivword, level)
  local otid = TID + SID * 65536
  local data = {}
  for i = 0, 11 do data[i] = 0 end
  local o = pid % 24
  data[growthOff(o) / 4] = species
  data[miscOff(o) / 4 + 1] = ivword
  local sum = 0
  for i = 0, 11 do sum = sum + data[i] % 65536 + math.floor(data[i] / 65536) end
  w32(addr, pid); w32(addr + 4, otid); w16(addr + 0x1C, sum % 65536); w8(addr + 0x54, level or 5)
  local key = bit.bxor(pid, otid)
  for i = 0, 11 do w32(addr + 0x20 + i * 4, bit.bxor(data[i], key)) end
end

-- ---------- game state ----------
local frame, held, prevHeld = 0, {}, {}
local realFrame = 0
local function nextSeed(x)
  local lo, hi = x % 65536, math.floor(x / 65536)
  local a = 0x41C6 * lo + hi * 0x4E6D
  local b = 0x4E6D * lo + (a % 65536) * 65536 + 0x6073
  return b % 4294967296
end
local function Random() local x = nextSeed(r32(RNGV)); w32(RNGV, x); return math.floor(x / 65536) end
w32(RNGV, 0x1EE7); w16(0x02020000, 0x1EE7)
local stats = { casts = 0, bites = 0, made = 0, earlyB = 0, msgs = 0 }
-- g: game state that a savestate keeps (the task data is also mirrored to gTasks)
local g = { fish = nil, msg = nil, battle = nil }

local function edge(b) return held[b] and not prevHeld[b] end

local function writeTask()
  local f = g.fish
  if not f then w8(TASK + 4, 0); w32(TASK, 0); return end
  w32(TASK, TASK_FISHING); w8(TASK + 4, 1)
  w16(TASK + 8, f.step); w16(TASK + 10, f.counter); w16(TASK + 12, f.numDots); w16(TASK + 14, f.dots)
  w16(TASK + 38, f.rod)
end

local function generate(rod)
  -- FishingWildEncounter: slot, level, nature, PID until the nature matches, IVs
  local roll = Random() % 100
  local slot = FISH_FIRST[rod] + #FISH_T[rod] - 1
  for i, t in ipairs(FISH_T[rod]) do if roll < t then slot = FISH_FIRST[rod] + i - 1; break end end
  local e = FISH[slot]
  local level = e[1] + Random() % (e[2] - e[1] + 1)
  local nature = Random() % 25
  local pid
  repeat local lo = Random(); local hi = Random(); pid = hi * 65536 + lo until pid % 25 == nature
  local i1 = Random() % 32768; local i2 = Random() % 32768
  createMon(ENEMY, pid, e[3], i1 + i2 * 32768, level)
  stats.made = stats.made + 1
  g.battle = { start = frame }
end

local function fishFrame()
  local f = g.fish
  if f.step == 0 then f.step = 1                                                 -- Fishing1
  elseif f.step == 1 then                                                        -- Fishing2
    f.minRounds = 1 + Random() % ({ [0] = 1, 3, 6 })[f.rod]
    f.step, f.counter = 2, 0
  elseif f.step == 2 then                                                        -- Fishing3: 1 s
    f.counter = f.counter + 1
    if f.counter >= 60 then f.step = 3 end
  elseif f.step == 3 then                                                        -- Fishing4 + 5
    local r = Random() % 10
    f.dots = math.min(r + 4, 10); f.numDots, f.counter = 0, 0
    f.step = 4
    f.counter = f.counter + 1
  elseif f.step == 4 then                                                        -- Fishing5: the dots
    f.counter = f.counter + 1
    if f.counter >= 20 then
      f.counter = 0
      if f.numDots >= f.dots then f.step = 5 else f.numDots = f.numDots + 1 end
    end
  elseif f.step == 5 then                                                        -- Fishing6 (+7)
    if Random() % 2 == 1 then f.step, f.textT = 11, 0                             -- no bite
    else f.step = 9; stats.bites = stats.bites + 1 end
  elseif f.step == 9 then f.step, f.counter, f.textT = 10, 0, 0                   -- Fishing10
  elseif f.step == 10 then                                                       -- Fishing11
    if f.counter == 0 then
      local printed = f.textT >= 24 * TEXT_SPEED
      if not printed then
        f.textT = f.textT + 1
        if edge("A") or edge("B") then f.textT = 24 * TEXT_SPEED; stats.earlyB = stats.earlyB + 1 end
      elseif edge("A") or edge("B") then
        f.counter = 1
      end
    else
      g.fish = nil
      generate(f.rod)
    end
  elseif f.step == 11 then                                                       -- "Not even a nibble"
    f.textT = f.textT + 1
    if f.textT > 30 and (edge("A") or edge("B")) then g.fish = nil end
  end
end

local function gameFrame()
  w32(RNGV, nextSeed(r32(RNGV)))                                 -- VBlank: Random() every frame
  if frame % 97 == 0 then w32(RNGV, nextSeed(r32(RNGV))) end    -- an NPC
  if g.battle then
    if frame - g.battle.start == 60 then w8(INB, 2) end
    return
  end
  if g.msg then
    g.msg = g.msg + 1
    if g.msg > 30 and (edge("A") or edge("B")) then g.msg = nil end
    return
  end
  if g.fish then fishFrame(); writeTask(); return end
  if edge("select") and FISH_ROD >= 262 and FISH_ROD <= 264 then
    stats.casts = stats.casts + 1
    if FISH_DRY then g.msg = 0; stats.msgs = stats.msgs + 1
    else g.fish = { step = 0, counter = 0, numDots = 0, dots = 0, rod = FISH_ROD - 262 }; writeTask() end
  end
end

-- ---------- emulator API ----------
local MAXF = 1500000
local pendingPad = {}
joypad = { set = function(_, t) pendingPad = t or {} end }
local texts, prevTexts = {}, {}
gui = { text = function(x, y, t) texts[#texts + 1] = string.format("%3d %s", y, tostring(t)) end, line = function() end }
local function copy(t) local r = {} for k, v in pairs(t) do r[k] = (type(v) == "table") and copy(v) or v end return r end
savestate = { create = function() return {} end,
  save = function(st) st.mem = copy(mem); st.g = copy(g); st.frame = frame end,
  load = function(st) mem = copy(st.mem); g = copy(st.g); frame = st.frame; stats.loads = (stats.loads or 0) + 1 end }
local hotkeys = {}
input = { get = function() return hotkeys[realFrame] or {} end }
emu = {
  framecount = function() return frame end,
  pause = function() error("PAUSED") end,
  frameadvance = function()
    prevTexts = texts; texts = {}
    prevHeld = held; held = pendingPad; pendingPad = {}
    gameFrame()
    frame = frame + 1
    realFrame = realFrame + 1
    if realFrame > MAXF then error("TIMEOUT") end
  end,
}
_G.print = function(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring(select(i, ...)) end io.write("  | " .. table.concat(t, " ") .. "\n") end
io = { open = function() return nil end, write = io.write }

-- press 8 (change mode) as many times as needed and 7 to start
local f = 300
for i = 2, MODE_INDEX do hotkeys[f] = { ["8"] = true }; f = f + 3 end
hotkeys[f] = { ["7"] = true }

return function(chunk)
  local ok, err = pcall(chunk)
  return tostring(err), realFrame, stats.casts, stats.bites, stats.made, stats.loads or 0, stats.earlyB, stats.msgs,
    table.concat(prevTexts, "\n")
end
