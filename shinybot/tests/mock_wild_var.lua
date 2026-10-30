REG_ITEM = rawget(_G, "REG_ITEM")
USER_RESET_AT = rawget(_G, "USER_RESET_AT")
-- Minimal VBA-rr + FRLG game simulator to test the bot logic
local MODE_TO_TEST, SHINY_AT, CLEAR_ON_RESET, RNG = ...
SHINY_AT = SHINY_AT or 3

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

-- ---------- memoria ----------
local mem = {}
local function r8(a) return mem[a] or 0 end
local function w8(a, v) mem[a] = v % 256 end
local function r16(a) return r8(a) + r8(a + 1) * 256 end
local function r32(a) return r16(a) + r16(a + 2) * 65536 end
local function w32(a, v) v = tou(v); for i = 0, 3 do w8(a + i, v % 256); v = math.floor(v / 256) end end
local function w16(a, v) w8(a, v % 256); w8(a + 1, math.floor(v / 256)) end
memory = { readdwordunsigned = r32, readwordunsigned = r16, readbyte = r8, writedword = w32, writebyte = w8,
           registerwrite = function() end }

local ENEMY, PARTY, PCNT, SB1P, SB2P, INB = 0x0202402C, 0x02024284, 0x02024029, 0x03005008, 0x0300500C, 0x03003529
local SB1, SB2 = 0x0202552C, 0x02024588
local TID, SID = 12345, 54321

local function bootRAM()
  w8(0x080000AE, 0x52); w8(0x080000AF, 0x45); w8(0x080000BC, 0)
end
local WD = 0x020386D0
local HDR = 0x083C9CB8
local function writeRom()
  -- encounter table: 40 maps, ours is group 3 map 19
  for i = 0, 39 do
    local a = HDR + i * 20
    w8(a, 3); w8(a + 1, i); w8(a + 2, 0); w8(a + 3, 0)
    w32(a + 4, 0x08400000 + i * 64); w32(a + 8, 0); w32(a + 12, 0); w32(a + 16, 0)
    local info = 0x08400000 + i * 64
    w8(info, 21); w32(info + 4, info + 8)
    for k = 0, 11 do
      local m = info + 8 + k * 4
      w8(m, 3); w8(m + 1, 5); w16(m + 2, (k % 4 == 0) and 25 or (16 + k))   -- Pikachu in slots 0,4,8
    end
  end
  w8(HDR + 40 * 20, 0xFF)
end
local function loadSave()
  w32(SB1P, SB1); w32(SB2P, SB2); w32(SB2 + 0xA, TID + SID * 65536); w8(PCNT, 2)
  w8(0x02037078, 1); w16(SB1 + 0x296, REG_ITEM or 366)
  w8(SB1 + 4, 3); w8(SB1 + 5, 19)
  writeRom()
  w32(WD, 0x1234)
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

local function randPid(shiny)
  local hi = math.random(0, 65535)
  local lo
  if shiny then lo = bit.bxor(bit.bxor(TID, SID), hi) % 65536
  else repeat lo = math.random(0, 65535) until bit.bxor(bit.bxor(bit.bxor(TID, SID), hi), lo) >= 8 end
  return hi * 65536 + lo
end

-- ---------- "game" state ----------
local frame, held, prevHeld = 0, {}, {}
local realFrame = 0
local function nextSeed(x)
  local lo, hi = x % 65536, math.floor(x / 65536)
  local a = 0x41C6 * lo + hi * 0x4E6D
  local b = 0x4E6D * lo + (a % 65536) * 65536 + 0x6073
  return b % 4294967296
end
w32(0x03005000, 0x1EE7); w16(0x02020000, 0x1EE7)
local stats = { encounters = 0, resets = 0, flees = 0, resetFrames = {} }
local g = { walkHeld = 0, steps = 0, battle = nil, loadAt = nil, aCount = 0, made = 0 }

local function edge(b) return held[b] and not prevHeld[b] end

local function gameFrame()
  if RNG then
    w32(0x03005000, nextSeed(r32(0x03005000)))
    if frame % 97 == 0 then w32(0x03005000, nextSeed(r32(0x03005000))) end  -- NPC
    if g.genAt and frame == g.genAt then
      g.genAt = nil
      local s1 = nextSeed(r32(0x03005000)); local lo = math.floor(s1/65536)
      local s2 = nextSeed(s1); local hi = math.floor(s2/65536)
      local s3 = nextSeed(s2); local i1 = math.floor(s3/65536) % 32768
      local s4 = nextSeed(s3); local i2 = math.floor(s4/65536) % 32768
      local pid = hi*65536 + lo
      g.made = g.made + 1
      stats.lastPid = pid
      if MODE_TO_TEST == "static" then createMon(ENEMY, pid, 150, i1 + i2*32768)
      elseif MODE_TO_TEST == "gift" then createMon(PARTY + 2 * 0x64, pid, 133, i1 + i2*32768); w8(PCNT, 3)
      else local r = SB1 + 0x30D0; w32(r, i1 % 256); w32(r + 4, pid); w16(r + 8, 243); w8(r + 0x13, 1) end
    end
  end
  -- soft reset
  if held.A and held.B and held.select and held.start then
    if not g.resetting then
      g.resetting = true
      stats.resets = stats.resets + 1
      stats.resetFrames[#stats.resetFrames + 1] = frame
      if CLEAR_ON_RESET then mem = {}; bootRAM(); if RNG then local x = math.random(0, 65535); w16(0x02020000, x); w32(0x03005000, x) end end
      g.loadAt = frame + 200; g.aCount = 0; g.battle = nil; w8(INB, 0)
    end
    return
  end
  g.resetting = false
  if g.loadAt then
    if frame >= g.loadAt then
      loadSave(); g.loadAt = nil
      w8(SB1 + 0x30D0 + 0x13, 0)        -- roamer inactive in the save
      w8(PCNT, 2)
    end
    return
  end

  if RNG then
    if g.tv then
      if not g.tv.exitAt then for _ = 1, 312 do w32(0x03005000, nextSeed(r32(0x03005000))) end end
      if edge("B") and not g.tv.exitAt then g.tv.exitAt = frame + 40 end
      if g.tv.exitAt and frame >= g.tv.exitAt then g.tv = nil; stats.tvUses = (stats.tvUses or 0) + 1 end
      return
    elseif edge("select") and not g.battle then
      g.tv = {}
      return
    end
  end
  if MODE_TO_TEST == "wild" then
    if not g.battle then
      if held.left or held.right then g.walkHeld = g.walkHeld + 1 else g.walkHeld = 0 end
      if RNG and g.walkHeld > 0 and g.walkHeld % 16 == 0 then
        w16(SB1, (r16(SB1) + (held.left and -1 or 1)) % 65536)      -- posicion
        local function Rand() local x = nextSeed(r32(0x03005000)); w32(0x03005000, x); return math.floor(x / 65536) end
        local function WRand() local x = (r32(WD) * 1103515245 + 12345) % 4294967296
          -- exact multiplication
          local lo, hi = r32(WD) % 65536, math.floor(r32(WD) / 65536)
          local a = 0x41C6 * lo + hi * 0x4E6D
          x = (0x4E6D * lo + (a % 65536) * 65536 + 0x3039) % 4294967296
          w32(WD, x); return math.floor(x / 65536) end
        local minSteps, pass = 6, false
        if r8(WD + 8) >= minSteps then pass = true
        else w8(WD + 8, r8(WD + 8) + 1); pass = (Rand() % 100) < 5 end
        if pass then
          local rate = 21 * 16 + math.floor(r16(WD + 6) * 16 / 200)
          if WRand() % 1600 < rate then
            local roll = Rand() % 100
            local T = {20,40,50,60,70,80,85,90,94,98,99,100}
            local slot = 12
            for i, t in ipairs(T) do if roll < t then slot = i; break end end
            local level = 3 + Rand() % 3
            local nature = Rand() % 25
            local pid
            repeat local lo = Rand(); local hi = Rand(); pid = hi * 65536 + lo until pid % 25 == nature
            local i1 = Rand() % 32768; local i2 = Rand() % 32768
            local sp = ((slot - 1) % 4 == 0) and 25 or (16 + slot - 1)
            stats.encounters = stats.encounters + 1
            createMon(ENEMY, pid, sp, i1 + i2 * 32768, level)
            w16(WD + 6, 0); w8(WD + 8, 0)
            g.battle = { start = frame, cx = 0, cy = 0, sub = false, ending = nil }
          else
            w16(WD + 6, r16(WD + 6) + 21)
            for _ = 1, frame % 3 do Rand() end      -- the game spends extra RNG on some steps
          end
        end
      end
      if not RNG and g.walkHeld > 0 and g.walkHeld % 16 == 0 then
        g.steps = g.steps + 1
        if g.steps % 4 == 0 then
          stats.encounters = stats.encounters + 1
          createMon(ENEMY, randPid(stats.encounters == SHINY_AT), 25, 0x3FFFFFFF)
          g.battle = { start = frame, cx = 0, cy = 0, sub = false, ending = nil }
        end
      end
    else
      local b = g.battle
      local CUR, OUT = 0x02023FF8, 0x02023E8A
      local t = frame - b.start
      if t == 80 then w8(INB, 2); w8(CUR, 0); w8(OUT, 0); b.phase = "text"; b.texts = 2 end
      if b.phase == "text" and t > 100 then
        if edge("A") or edge("B") then b.texts = b.texts - 1; if b.texts <= 0 then b.phase = "menu" end end
      elseif b.phase == "menu" then
        if edge("right") and r8(CUR) % 2 == 0 then w8(CUR, r8(CUR) + 1) end
        if edge("left") and r8(CUR) % 2 == 1 then w8(CUR, r8(CUR) - 1) end
        if edge("down") and r8(CUR) < 2 then w8(CUR, r8(CUR) + 2) end
        if edge("up") and r8(CUR) >= 2 then w8(CUR, r8(CUR) - 2) end
        if edge("A") then
          if r8(CUR) == 3 then
            if math.random() < 0.3 then b.phase = "text"; b.texts = 2; stats.fails = (stats.fails or 0) + 1
            else w8(OUT, 4); b.phase = "gotaway"; stats.flees = stats.flees + 1 end
          elseif r8(CUR) == 0 then b.phase = "moves" end
        end
      elseif b.phase == "moves" then
        if edge("A") then error("BOT USED A MOVE") end
        if edge("B") then b.phase = "menu" end
      elseif b.phase == "gotaway" then
        if edge("B") or edge("A") then b.phase = "ending"; b.ending = frame + 60 end
      end
      if b.ending and frame >= b.ending then w8(INB, 0); g.battle = nil end
    end
  else
    if edge("A") then
      g.aCount = g.aCount + 1
      if g.aCount == 1 then g.firstA = frame end
      if RNG and g.aCount == 6 then g.genAt = frame + 25 + ((g.firstA % 4 == 0) and 1 or 0) end
      if not RNG and g.aCount == 6 then
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

-- ---------- emulator API ----------
local MAXF = 3000000
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
    if USER_RESET_AT and (realFrame or frame) >= USER_RESET_AT and (realFrame or frame) < USER_RESET_AT + 3 then held = { A = true, B = true, select = true, start = true } end
    gameFrame()
    frame = frame + 1
    realFrame = realFrame + 1
    if realFrame > MAXF then error("TIMEOUT") end
  end,
}
_G.print = function(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring(select(i, ...)) end io.write("  | " .. table.concat(t, " ") .. "\n") end
io = { open = function() return nil end, write = io.write }

-- press 8 (change mode) as many times as needed and 7 to start
local modeIndex = (RNG and MODE_TO_TEST == "wild") and 8 or (({ wild = 1, static = 2, gift = 3, roamer = 4 })[MODE_TO_TEST] + (RNG and 3 or 0))
local f = 300
for i = 2, modeIndex do hotkeys[f] = { ["8"] = true }; f = f + 3 end
hotkeys[f] = { ["7"] = true }

return function(chunk)
  local ok, err = pcall(chunk)
  local gaps = {}
  for i = 2, #stats.resetFrames do gaps[#gaps + 1] = stats.resetFrames[i] - stats.resetFrames[i - 1] end
  return table.concat(prevTexts, "\n") .. string.format("\n[TV usada %d veces]", stats.tvUses or 0), tostring(err), realFrame, stats.encounters, stats.resets, stats.flees, g.made, table.concat(gaps, ","), (g.battle ~= nil), stats.loads or 0, stats.lastPid or 0
end
