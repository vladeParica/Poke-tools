-- Simulador de VBA-rr + FRLG para probar FRLG_TrainBot (mapa, combate, Centro Pokemon)
local SCEN = ...
SCEN = SCEN or "evs"
math.randomseed(12345)

local function tou(x) return x % 4294967296 end
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

local mem = {}
local function r8(a) return mem[a] or 0 end
local function w8(a, v) mem[a] = v % 256 end
local function r16(a) return r8(a) + r8(a + 1) * 256 end
local function r32(a) return r16(a) + r16(a + 2) * 65536 end
local function w16(a, v) v = v % 65536; w8(a, v % 256); w8(a + 1, math.floor(v / 256)) end
local function w32(a, v) v = tou(v); for i = 0, 3 do w8(a + i, v % 256); v = math.floor(v / 256) end end
memory = { readdwordunsigned = r32, readwordunsigned = r16, readbyte = r8, writedword = w32, writebyte = w8 }

-- direcciones (USA)
local ENEMY, PARTY, PCNT = 0x0202402C, 0x02024284, 0x02024029
local SB1P, SB2P, SB1, SB2 = 0x03005008, 0x0300500C, 0x0202552C, 0x02024588
local GMAIN = 0x030030F0
local INB, CB2 = GMAIN + 0x439, GMAIN + 4
local AVATAR, OBJ = 0x02037078, 0x02036E38
local BMONS, BUFA, FLAGS = 0x02023BE4, 0x02022BC4, 0x02023BC8
local ACUR, MCUR, SPTR, YN, OUTC = 0x02023FF8, 0x02023FFC, 0x02023D74, 0x02023E83, 0x02023E8A
local OP_TEXT, OP_5A, OP_5B = 0x08100000, 0x08100010, 0x08100020
local CB_OW, CB_BATTLE, CB_TRANS, CB_SUM = 0x080567DD, 0x08011101, 0x080F0001, 0x08134001
local MTL, BSTRUCT, SUMCUR = 0x02024022, 0x02023FE8, 0x0203B16D
w32(BSTRUCT, 0x02030000); w8(0x02030010, 0)
local LEARN_LIST = { 53, 108, 232, 53 }
w8(0x080000AE, 0x52); w8(0x080000AF, 0x45); w8(0x080000BC, 0)
w8(OP_TEXT, 0x10); w8(OP_5A, 0x5A); w8(OP_5B, 0x5B)
w32(SB1P, SB1); w32(SB2P, SB2)
local TID, SID = 12345, 54321
w32(SB2 + 0xA, TID + SID * 65536)
w8(AVATAR + 5, 0)
w32(CB2, CB_OW)

-- ---------------- codificar un Pokemon ----------------
local ORDER = { "GAEM", "GAME", "GEAM", "GEMA", "GMAE", "GMEA", "AGEM", "AGME", "AEGM", "AEMG", "AMGE", "AMEG",
                "EGAM", "EGMA", "EAGM", "EAMG", "EMGA", "EMAG", "MGAE", "MGEA", "MAGE", "MAEG", "MEGA", "MEAG" }
local function encodeMon(addr, m)
  local otid = TID + SID * 65536
  local subs = {
    G = { m.species + m.item * 65536, 0, 0 + m.friendship * 256, 0 },
    A = { m.moves[1] + m.moves[2] * 65536, m.moves[3] + m.moves[4] * 65536,
          m.pp[1] + m.pp[2] * 256 + m.pp[3] * 65536 + m.pp[4] * 16777216 },
    E = { m.evs[1] + m.evs[2] * 256 + m.evs[3] * 65536 + m.evs[4] * 16777216, m.evs[5] + m.evs[6] * 256, 0 },
    M = { m.pokerus, m.ivword, 0 },
  }
  local data = {}
  local o = ORDER[(m.pid % 24) + 1]
  for k = 1, 4 do
    local s = subs[o:sub(k, k)]
    for j = 1, 3 do data[(k - 1) * 3 + j - 1] = s[j] or 0 end
  end
  local sum = 0
  for i = 0, 11 do sum = sum + data[i] % 65536 + math.floor(data[i] / 65536) end
  w32(addr, m.pid); w32(addr + 4, otid); w16(addr + 0x1C, sum % 65536)
  w8(addr + 0x54, m.level); w16(addr + 0x56, m.hp); w16(addr + 0x58, m.maxHP)
  local key = bit.bxor(m.pid, otid)
  for i = 0, 11 do w32(addr + 0x20 + i * 4, bit.bxor(data[i], key)) end
end

local leadM = { pid = 0x1234567A, species = 4, item = 0, friendship = 70, moves = { 10, 45, 52, 43 }, pp = { 35, 40, 25, 30 },
  evs = { 0, 0, 0, 0, 0, 0 }, pokerus = 0, ivword = 0x3FFFFFFF, level = 5, hp = 20, maxHP = 20 }
local secondM = { pid = 0x0BADBEEF, species = 16, item = 0, friendship = 70, moves = { 33, 0, 0, 0 }, pp = { 35, 0, 0, 0 },
  evs = { 0, 0, 0, 0, 0, 0 }, pokerus = 0, ivword = 0, level = 3, hp = 10, maxHP = 15 }
if SCEN == "pokerus" then leadM.pokerus = 0x13 end
local function syncParty() encodeMon(PARTY, leadM); encodeMon(PARTY + 0x64, secondM); w8(PCNT, 2) end
syncParty()

-- ---------------- mundo ----------------
local frame, held, prevHeld = 0, {}, {}
local function edge(b) return held[b] and not prevHeld[b] end
local W = { g = 3, n = 20, x = 8, y = 10, face = 3, walkT = 0, cool = 0, dialog = nil, battle = nil, auto = nil }
local stats = { battles = 0, fought = 0, ran = 0, heals = 0, learnPrompts = 0, maxY = 0, events = {} }
local function ev(s) stats.events[#stats.events + 1] = frame .. ":" .. s end

local function writePos()
  w8(SB1 + 4, W.g); w8(SB1 + 5, W.n)
  w16(OBJ + 0x10, W.x); w16(OBJ + 0x12, W.y); w8(OBJ + 0x18, W.face)
end
writePos()

local SPECIES = {
  [19] = { 0, 0, 0, 1, 0, 0 }, [16] = { 0, 0, 0, 1, 0, 0 }, [43] = { 0, 0, 0, 0, 1, 0 },
  [56] = { 0, 1, 0, 0, 0, 0 }, [23] = { 0, 1, 0, 0, 0, 0 } }
local POOL = { 19, 16, 43, 56, 23 }

local function setBattleMon(i, sp, lvl, hp, maxHP, moves, pp, types)
  local b = BMONS + i * 0x58
  w16(b, sp); w16(b + 2, 20); w16(b + 4, 15); w16(b + 6, 20); w16(b + 8, 18); w16(b + 0xA, 15)
  for k = 1, 4 do w16(b + 0xC + (k - 1) * 2, moves[k]); w8(b + 0x24 + k - 1, pp[k]) end
  w32(b + 0x14, 0x3FFFFFFF); w8(b + 0x20, 0); w8(b + 0x21, types[1]); w8(b + 0x22, types[2])
  w16(b + 0x28, hp); w8(b + 0x2A, lvl); w8(b + 0x2B, 70); w16(b + 0x2C, maxHP); w32(b + 0x4C, 0)
end

local function startBattle()
  stats.battles = stats.battles + 1
  local sp = POOL[math.random(1, #POOL)]
  local lvl = math.random(3, 5)
  local pid
  repeat pid = math.random(0, 0xFFFFFFF) until bit.bxor(bit.bxor(TID, SID), bit.bxor(pid % 65536, math.floor(pid / 65536))) >= 8
  encodeMon(ENEMY, { pid = pid, species = sp, item = 0, friendship = 70, moves = { 33, 0, 0, 0 }, pp = { 35, 0, 0, 0 },
    evs = { 0, 0, 0, 0, 0, 0 }, pokerus = 0, ivword = 0, level = lvl, hp = lvl * 4, maxHP = lvl * 4 })
  W.battle = { phase = "intro", t = 0, texts = 2, sp = sp, ehp = lvl * 4, lvl = lvl }
  w8(INB, 2); w32(CB2, CB_BATTLE); w32(SPTR, OP_TEXT); w32(FLAGS, 0); w8(BUFA, 0); w8(OUTC, 0)
  setBattleMon(0, leadM.species, leadM.level, leadM.hp, leadM.maxHP, leadM.moves, leadM.pp, { 10, 10 })
  setBattleMon(1, sp, lvl, lvl * 4, lvl * 4, { 33, 0, 0, 0 }, { 35, 0, 0, 0 }, { 0, 0 })
  ev("battle " .. sp)
end

local DMG = { [10] = 6, [52] = 9, [45] = 0, [43] = 0, [53] = 14, [232] = 8, [108] = 0 }
local wins = 0

local function battleFrame()
  local b = W.battle
  b.t = b.t + 1
  local function toAction() b.phase = "action"; w8(BUFA, 18); w32(FLAGS, 1); b.ready = b.t + 8 end
  local function textPhase(n, nextf) b.phase = "text"; b.texts = n; b.after = nextf; b.ready = b.t + 10; w32(SPTR, OP_TEXT) end
  local adv = (edge("A") or edge("B"))
  if b.phase == "intro" then
    if b.t > 30 and adv then b.texts = b.texts - 1; if b.texts <= 0 then toAction() end end
  elseif b.phase == "text" then
    if b.t >= b.ready and adv then b.texts = b.texts - 1; if b.texts <= 0 then b.after() end end
  elseif b.phase == "action" then
    if b.t < b.ready then return end
    local c = r8(ACUR)
    if edge("A") then
      w32(FLAGS, 0)
      if c == 0 then b.phase = "tomove"; b.ready = b.t + 10
      elseif c == 3 then
        stats.ran = stats.ran + 1; w8(OUTC, 4)
        textPhase(1, function() b.phase = "ending"; b.endT = b.t end)
      else error("BOT OPENED BAG/POKEMON") end
    elseif edge("left") and c % 2 == 1 then w8(ACUR, c - 1)
    elseif edge("right") and c % 2 == 0 then w8(ACUR, c + 1)
    elseif edge("up") and c >= 2 then w8(ACUR, c - 2)
    elseif edge("down") and c < 2 then w8(ACUR, c + 2) end
  elseif b.phase == "tomove" then
    if b.t >= b.ready then b.phase = "move"; w8(BUFA, 20); w32(FLAGS, 1); b.ready = b.t + 8 end
  elseif b.phase == "move" then
    if b.t < b.ready then return end
    local c = r8(MCUR)
    local nm = 0
    for k = 1, 4 do if leadM.moves[k] ~= 0 then nm = nm + 1 end end
    if edge("A") then
      local mv = leadM.moves[c + 1]
      if leadM.pp[c + 1] == 0 then textPhase(1, function() b.phase = "move"; b.ready = b.t + 8 end); return end
      w32(FLAGS, 0)
      stats.lastMove = mv
      if mv == 45 then stats.usedGrowl = (stats.usedGrowl or 0) + 1 end
      leadM.pp[c + 1] = leadM.pp[c + 1] - 1; w8(BMONS + 0x24 + c, leadM.pp[c + 1]); syncParty()
      b.ehp = b.ehp - (DMG[mv] or 5); w16(BMONS + 0x58 + 0x28, math.max(b.ehp, 0))
      if b.ehp <= 0 then
        stats.fought = stats.fought + 1
        textPhase(2, function()
          -- EVs como MonGainEVs
          local y = SPECIES[b.sp]
          local mult = (leadM.pokerus ~= 0) and 2 or 1
          local total = 0
          for k = 1, 6 do total = total + leadM.evs[k] end
          for k = 1, 6 do
            local inc = y[k] * mult
            if total + inc > 510 then inc = 510 - total end
            if leadM.evs[k] + inc > 255 then inc = 255 - leadM.evs[k] end
            leadM.evs[k] = leadM.evs[k] + inc; total = total + inc
          end
          wins = wins + 1
          if wins % 3 == 0 then
            leadM.level = leadM.level + 1; leadM.maxHP = leadM.maxHP + 2
            syncParty()
            textPhase(2, function()
              if SCEN ~= "nolearn" and leadM.level % 2 == 0 then
                stats.learnPrompts = stats.learnPrompts + 1
                b.phase = "5A"; w32(SPTR, OP_5A); b.loops = 0; b.ready = b.t + 5
                w16(MTL, LEARN_LIST[(stats.learnPrompts - 1) % #LEARN_LIST + 1])
              else b.phase = "ending"; b.endT = b.t end
            end)
          else
            syncParty()
            b.phase = "ending"; b.endT = b.t
          end
        end)
      else
        textPhase(1, function()
          if SCEN ~= "immune" then leadM.hp = math.max(leadM.hp - 4, 0) end; syncParty(); w16(BMONS + 0x28, leadM.hp)
          if leadM.hp == 0 then error("LEAD FAINTED") end
          textPhase(1, toAction)
        end)
      end
    elseif edge("B") then w32(FLAGS, 0); b.phase = "toaction"; b.ready = b.t + 6
    elseif edge("left") and c % 2 == 1 then w8(MCUR, c - 1)
    elseif edge("right") and c % 2 == 0 and c + 1 < nm then w8(MCUR, c + 1)
    elseif edge("up") and c >= 2 then w8(MCUR, c - 2)
    elseif edge("down") and c < 2 and c + 2 < nm then w8(MCUR, c + 2) end
  elseif b.phase == "toaction" then
    if b.t >= b.ready then toAction() end
  elseif b.phase == "5A" then
    if b.t < b.ready then return end
    if edge("A") and r8(YN) == 0 then b.phase = "sumfade"; b.ready = b.t + 20
    elseif edge("A") then b.phase = "5B"; w32(SPTR, OP_5B); w8(YN, 0); b.ready = b.t + 10
    elseif edge("down") then w8(YN, 1) elseif edge("up") then w8(YN, 0)
    elseif edge("B") then b.phase = "5B"; w32(SPTR, OP_5B); w8(YN, 0); b.ready = b.t + 10 end
  elseif b.phase == "sumfade" then
    if b.t >= b.ready then b.phase = "sum"; w32(CB2, CB_SUM); w8(SUMCUR, 0); b.ready = b.t + 70 end
  elseif b.phase == "sum" then
    if b.t < b.ready then return end
    local c = r8(SUMCUR)
    if edge("down") then if c < 4 then w8(SUMCUR, c + 1) else w8(SUMCUR, 0) end
    elseif edge("up") then if c > 0 then w8(SUMCUR, c - 1) else w8(SUMCUR, 4) end
    elseif edge("A") or edge("B") then
      local slot = edge("A") and c or 4
      b.phase = "sumout"; b.ready = b.t + 20; b.slot = slot
    end
  elseif b.phase == "sumout" then
    if b.t >= b.ready then
      w32(CB2, CB_BATTLE)
      if b.slot < 4 then
        local new = r16(MTL)
        stats.learned = (stats.learned or "") .. string.format("%d->%d ", leadM.moves[b.slot + 1], new)
        leadM.moves[b.slot + 1] = new; leadM.pp[b.slot + 1] = ({ [53] = 15, [232] = 35, [108] = 20 })[new] or 15; syncParty()
        w16(BMONS + 0xC + b.slot * 2, new); w8(BMONS + 0x24 + b.slot, 15)
        textPhase(1, function() b.phase = "ending"; b.endT = b.t end)
      else b.phase = "5B"; w32(SPTR, OP_5B); w8(YN, 0); b.ready = b.t + 10 end
    end
  elseif b.phase == "5B" then
    if b.t < b.ready then return end
    if edge("down") then w8(YN, 1) elseif edge("up") then w8(YN, 0) end
    if edge("A") then
      if r8(YN) == 0 then textPhase(1, function() b.phase = "ending"; b.endT = b.t end)
      else b.loops = b.loops + 1; b.phase = "5A"; w32(SPTR, OP_5A); b.ready = b.t + 10 end
    elseif edge("B") then
      b.loops = b.loops + 1; if b.loops > 3 then error("LEARN LOOP") end
      b.phase = "5A"; w32(SPTR, OP_5A); b.ready = b.t + 10
    end
  elseif b.phase == "ending" and (SCEN == "evo" or SCEN == "evono") and leadM.level >= 7 and not W.evoDone and b.t - b.endT == 10 then
    b.phase = "evo"; b.evoT = 0; w32(CB2, 0x080CE001)
  elseif b.phase == "evo" then
    b.evoT = b.evoT + 1
    if b.evoT > 30 and b.evoT < 200 and held.B then
      stats.evo = "cancelada"; W.evoDone = true; b.phase = "ending"; b.endT = b.t - 11; w32(CB2, CB_BATTLE)
    elseif b.evoT == 200 then leadM.species = 5; syncParty(); stats.evo = "evoluciono"
    elseif b.evoT > 200 and edge("A") then W.evoDone = true; b.phase = "ending"; b.endT = b.t - 11; w32(CB2, CB_BATTLE) end
  elseif b.phase == "ending" then
    if b.t - b.endT == 20 then w8(INB, 0); w32(CB2, CB_TRANS) end
    if b.t - b.endT == 50 then w32(CB2, CB_OW); W.battle = nil; W.cool = 10 end
  end
end

local function passable(g, n, x, y)
  if g == 3 then return x >= 0 and x <= 30 and y >= 3 and y <= 20 end
  return x >= 1 and x <= 9 and y >= 3 and y <= 8
end

local function nurseFrame()
  local d = W.dialog
  d.t = d.t + 1
  local adv = edge("A") or edge("B")
  if d.step == 1 then if d.t > 10 and adv then d.step = 2; d.t = 0 end
  elseif d.step == 2 then
    if d.t > 10 and edge("A") then d.step = 3; d.t = 0
    elseif d.t > 10 and edge("B") then W.dialog = nil; W.cool = 10 end
  elseif d.step == 3 then
    if d.t == 60 then
      leadM.hp = leadM.maxHP
      local BASEPP = { [10] = 35, [45] = 40, [52] = 25, [43] = 30, [53] = 15, [232] = 35, [108] = 20, [33] = 35 }
      for k = 1, 4 do leadM.pp[k] = BASEPP[leadM.moves[k]] or 0 end
      secondM.hp = secondM.maxHP; secondM.pp[1] = 35; syncParty()
      stats.heals = stats.heals + 1; ev("healed")
    end
    if d.t > 70 then d.step = 4; d.t = 0 end
  elseif d.step == 4 or d.step == 5 then if d.t > 10 and adv then d.step = d.step + 1; d.t = 0 end
  elseif d.step == 6 then W.dialog = nil; W.cool = 10 end
end

local function worldFrame()
  if W.battle then battleFrame(); return end
  if W.dialog then nurseFrame(); return end
  if W.cool > 0 then W.cool = W.cool - 1; return end
  if W.walkT > 0 then
    W.walkT = W.walkT - 1
    if W.walkT == 0 then
      if W.g == 3 and W.y == 10 and not W.noEnc and math.random() < 0.25 then startBattle() end
      if W.auto then local a = W.auto; W.auto = nil; W.x, W.y, W.face = a.x, a.y, a.face; W.walkT = 16 end
    end
    return
  end
  if W.g == 4 and W.x == 5 and W.y == 3 and W.face == 2 and edge("A") then W.dialog = { step = 1, t = 0 }; return end
  local dir
  for _, k in ipairs({ "up", "down", "left", "right" }) do if held[k] then dir = k end end
  if not dir then return end
  local face = ({ down = 1, up = 2, left = 3, right = 4 })[dir]
  W.face = face
  local dx, dy = 0, 0
  if dir == "up" then dy = -1 elseif dir == "down" then dy = 1 elseif dir == "left" then dx = -1 else dx = 1 end
  -- puertas
  if W.g == 3 and W.x == 10 and W.y == 3 and dir == "up" then
    W.g, W.n, W.x, W.y, W.face = 4, 1, 5, 8, 2; W.cool = 40; ev("enter center"); return
  end
  if W.g == 4 and W.x == 5 and W.y == 8 and dir == "down" then
    W.g, W.n, W.x, W.y, W.face = 3, 20, 10, 2, 1; W.cool = 40; W.auto = { x = 10, y = 3, face = 1 }; W.walkT = 1
    ev("exit center"); return
  end
  local nx, ny = W.x + dx, W.y + dy
  if passable(W.g, W.n, nx, ny) then
    W.x, W.y = nx, ny; W.walkT = 16
    if SCEN == "tile" and W.g == 4 and nx == 5 and ny == 5 then
      leadM.hp = leadM.maxHP
      local BASEPP = { [10] = 35, [45] = 40, [52] = 25, [43] = 30, [53] = 15, [232] = 35, [108] = 20, [33] = 35 }
      for k = 1, 4 do leadM.pp[k] = BASEPP[leadM.moves[k]] or 0 end
      secondM.hp = secondM.maxHP; syncParty(); stats.heals = stats.heals + 1; ev("tile heal")
      W.dialog = { step = 5, t = 0 }
    end
  end
end

-- ---------------- API ----------------
local MAXF = 600000
local pendingPad = {}
joypad = { set = function(_, t) for k, v in pairs(t or {}) do pendingPad[k] = v end end }
gui = { text = function() end }
savestate = { create = function() return {} end, save = function() end, load = function() end }
local hotkeys = {}
input = { get = function() return hotkeys[frame] or {} end }
emu = {
  framecount = function() return frame end,
  pause = function() error("PAUSED") end,
  frameadvance = function()
    prevHeld = held; held = pendingPad; pendingPad = {}
    if next(held) then lastInput = frame end
    if frame - (lastInput or 0) > 20000 then error("IDLE") end
    worldFrame()
    writePos()
    frame = frame + 1
    if frame > MAXF then error("TIMEOUT") end
  end,
}
local printed = {}
_G.print = function(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring(select(i, ...)) end
  printed[#printed + 1] = table.concat(t, " ") end

-- Grabacion de la ruta (simula al jugador) o inicio directo
local script = {}
if SCEN == "record" then
  -- el "jugador" camina: 6, ida hasta la enfermera, 6, vuelta, 6
  local f = 100
  local function key(k) hotkeys[f] = { [k] = true }; f = f + 5 end
  local function walk(dir, n) for _ = 1, n do script[#script + 1] = { at = f, dir = dir }; f = f + 20 end end
  W.noEnc = true
  key("6")
  walk("right", 2); walk("up", 7); walk("up", 1); f = f + 60; walk("up", 5)  -- (10,10)->(10,3)->puerta->(5,3)
  key("6")
  walk("down", 5); f = f + 80; walk("down", 1); f = f + 40; walk("down", 7); walk("left", 2)
  f = f + 30
  key("6")
  W.noEnc = true
  stats.recordEnd = f
  hotkeys[f + 50] = { ["7"] = true }
else
  hotkeys[300] = { ["7"] = true }
  if SCEN == "panel2" then hotkeys[200] = { ["9"] = true } end
end
local oldAdvance = emu.frameadvance
emu.frameadvance = function()
  for _, s in ipairs(script) do if frame >= s.at and frame < s.at + 16 then pendingPad[s.dir] = true end end
  if stats.recordEnd and frame == stats.recordEnd then W.noEnc = false end
  oldAdvance()
end

return function(chunk)
  local ok, err = pcall(chunk)
  return tostring(err), frame, stats.battles, stats.fought, stats.ran, stats.heals, stats.learnPrompts,
    table.concat(leadM.evs, ","), leadM.level, table.concat(printed, "\n"), table.concat(stats.events, " "),
    string.format("%d,%d,%d", W.g, W.x, W.y), (stats.usedGrowl or 0) .. " learned=" .. (stats.learned or "") .. " evo=" .. tostring(stats.evo)
end
