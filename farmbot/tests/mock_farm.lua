-- VBA-rr + FRLG simulator to test FRLG_FarmBot: map, battle, Pokemon Center,
-- START menu, party screen (take item), Pickup, Thief, encrypted money,
-- VS Seeker and trainers. FireRed USA 1.0 addresses (pokefirered.sym).
local SCEN = ...
SCEN = SCEN or "nivel"
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

-- ---------------- addresses (FireRed USA 1.0) ----------------
local ENEMY, PARTY, PCNT = 0x0202402C, 0x02024284, 0x02024029
local SB1P, SB2P, SB1, SB2 = 0x03005008, 0x0300500C, 0x0202552C, 0x02024588
local GMAIN = 0x030030F0
local INB, CB2 = GMAIN + 0x439, GMAIN + 4
local AVATAR, OBJ = 0x02037078, 0x02036E38
local BMONS, BUFA, FLAGS = 0x02023BE4, 0x02022BC4, 0x02023BC8
local ACUR, MCUR, SPTR, YN, OUTC = 0x02023FF8, 0x02023FFC, 0x02023D74, 0x02023E83, 0x02023E8A
local BTYPE = 0x02022B4C
local OP_TEXT = 0x08100000
local CB_OW, CB_BATTLE, CB_TRANS = 0x080565B5, 0x08011101, 0x080F0001
-- menus
local START_CUR, START_CNT, START_ORD = 0x020370F4, 0x020370F5, 0x020370F6
local PMENU, PINT, MCURSOR, TASKS = 0x0203B0A0, 0x0203B09C, 0x0203ADE6, 0x03005090
local INTERNAL = 0x02031000          -- where sPartyMenuInternal "lives" in the simulator
local F_START, CB_PARTY, F_CHOOSE, F_SELECT, F_VSSEEK = 0x0806F1F1, 0x0811EBA1, 0x0811FB29, 0x08122C5D, 0x0810C671
local F_MSG = 0x08123001             -- any other task (message in the party screen)
local KEY = 0x1234ABCD
local MTL, BSTRUCT = 0x02024022, 0x02023FE8
w32(BSTRUCT, 0x02030000); w8(0x02030010, 0)

w8(0x080000AE, 0x52); w8(0x080000AF, 0x45); w8(0x080000BC, 0)
w8(OP_TEXT, 0x10)
w32(SB1P, SB1); w32(SB2P, SB2)
local TID, SID = 12345, 54321
w32(SB2 + 0xA, TID + SID * 65536)
w32(SB2 + 0xF20, KEY)
w8(AVATAR + 5, 0)
w32(CB2, CB_OW)

local stats = { battles = 0, fought = 0, ran = 0, heals = 0, events = {}, taken = 0, pickups = 0, steals = 0,
  trainerBattles = 0, vsUses = 0, menuOpens = 0 }
local frame = 0
local function ev(s) stats.events[#stats.events + 1] = frame .. ":" .. s end

-- money and bag (encrypted with the key)
local cash = 3000
local function syncMoney() w32(SB1 + 0x290, bit.bxor(cash, KEY)) end
syncMoney()
local bag = {}                 -- itemId -> quantity (items pocket)
local BAGMAX = (SCEN == "bagfull") and 0 or 999
local function syncBag()
  local i = 0
  for id, q in pairs(bag) do
    w16(SB1 + 0x310 + i * 4, id); w16(SB1 + 0x310 + i * 4 + 2, bit.bxor(q, KEY % 65536)); i = i + 1
  end
end
if SCEN == "dinero" then w16(SB1 + 0x296, 362) end         -- VS Seeker registered on SELECT
local charge = 0
local function syncCharge() w8(SB1 + 0x638, charge) end
syncCharge()

-- ---------------- encode a Pokemon ----------------
local ORDER = { "GAEM", "GAME", "GEAM", "GEMA", "GMAE", "GMEA", "AGEM", "AGME", "AEGM", "AEMG", "AMGE", "AMEG",
                "EGAM", "EGMA", "EAGM", "EAMG", "EMGA", "EMAG", "MGAE", "MGEA", "MAGE", "MAEG", "MEGA", "MEAG" }
local function encodeMon(addr, m)
  local otid = TID + SID * 65536
  local subs = {
    G = { m.species + m.item * 65536, 0, 0 + m.friendship * 256, 0 },
    A = { m.moves[1] + m.moves[2] * 65536, m.moves[3] + m.moves[4] * 65536,
          m.pp[1] + m.pp[2] * 256 + m.pp[3] * 65536 + m.pp[4] * 16777216 },
    E = { 0, 0, 0 },
    M = { 0, m.ivword, 0 },
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

-- party: the first one fights; in "objetos" there are two Meowth (Pickup)
local party = {
  { pid = 0x1234567A, species = 4, item = 0, friendship = 70, moves = { 10, 52, 0, 0 }, pp = { 35, 25, 0, 0 },
    ivword = 0x3FFFFFFF, level = 12, hp = 40, maxHP = 40 },
}
if SCEN == "robar" then party[1].moves = { 10, 168, 0, 0 }; party[1].pp = { 35, 10, 0, 0 } end
if SCEN == "objetos" or SCEN == "bagfull" or SCEN == "pausa" or SCEN == "campo" then
  party[2] = { pid = 0x0BADBEEF, species = 52, item = 0, friendship = 70, moves = { 10, 0, 0, 0 }, pp = { 35, 0, 0, 0 },
    ivword = 0, level = 10, hp = 30, maxHP = 30 }
  party[3] = { pid = 0x0BADBE00, species = 52, item = 0, friendship = 70, moves = { 10, 0, 0, 0 }, pp = { 35, 0, 0, 0 },
    ivword = 0, level = 10, hp = 30, maxHP = 30 }
end
local leadM = party[1]
local function syncParty()
  for i, m in ipairs(party) do encodeMon(PARTY + (i - 1) * 0x64, m) end
  w8(PCNT, #party)
end
syncParty()

-- ---------------- mundo ----------------
local held, prevHeld = {}, {}
local function edge(b) return held[b] and not prevHeld[b] end
local W = { g = 3, n = 20, x = 8, y = 10, face = 3, walkT = 0, cool = 0, dialog = nil, battle = nil, auto = nil,
  menu = nil, ready = false, beaten = {} }

local function writePos()
  w8(SB1 + 4, W.g); w8(SB1 + 5, W.n)
  w16(OBJ + 0x10, W.x); w16(OBJ + 0x12, W.y); w8(OBJ + 0x18, W.face)
end
writePos()

-- tasks (gTasks): func + isActive
local function setTask(slot, fn) w32(TASKS + slot * 40, fn or 0); w8(TASKS + slot * 40 + 4, fn and 1 or 0) end

local POOL = { 19, 16, 43, 56, 23 }
local PICKUP_ITEMS = { 139, 110, 68 }        -- Oran Berry, Nugget, Rare Candy

local function setBattleMon(i, sp, lvl, hp, maxHP, moves, pp, types, item)
  local b = BMONS + i * 0x58
  w16(b, sp); w16(b + 2, 20); w16(b + 4, 15); w16(b + 6, 20); w16(b + 8, 18); w16(b + 0xA, 15)
  for k = 1, 4 do w16(b + 0xC + (k - 1) * 2, moves[k]); w8(b + 0x24 + k - 1, pp[k]) end
  w32(b + 0x14, 0x3FFFFFFF); w8(b + 0x20, 0); w8(b + 0x21, types[1]); w8(b + 0x22, types[2])
  w16(b + 0x28, hp); w8(b + 0x2A, lvl); w8(b + 0x2B, 70); w16(b + 0x2C, maxHP); w16(b + 0x2E, item or 0); w32(b + 0x4C, 0)
end

local function startBattle(trainer)
  stats.battles = stats.battles + 1
  local sp = trainer and 66 or POOL[math.random(1, #POOL)]
  local lvl = math.random(3, 5)
  local pid
  repeat pid = math.random(0, 0xFFFFFFF) until bit.bxor(bit.bxor(TID, SID), bit.bxor(pid % 65536, math.floor(pid / 65536))) >= 8
  local item = 0
  if SCEN == "robar" and not trainer then
    local r = math.random()
    if r < 0.4 then item = 110 elseif r < 0.6 then item = 139 end      -- Nugget (wanted) / Oran Berry (not)
  end
  encodeMon(ENEMY, { pid = pid, species = sp, item = item, friendship = 70, moves = { 33, 0, 0, 0 }, pp = { 35, 0, 0, 0 },
    ivword = 0, level = lvl, hp = lvl * 4, maxHP = lvl * 4 })
  W.battle = { phase = "intro", t = 0, texts = 2, sp = sp, ehp = lvl * 4, lvl = lvl, trainer = trainer, foeItem = item }
  w8(INB, 2); w32(CB2, CB_BATTLE); w32(SPTR, OP_TEXT); w32(FLAGS, 0); w8(BUFA, 0); w8(OUTC, 0)
  w32(BTYPE, trainer and 0x08 or 0x04)
  setBattleMon(0, leadM.species, leadM.level, leadM.hp, leadM.maxHP, leadM.moves, leadM.pp, { 10, 10 }, leadM.item)
  setBattleMon(1, sp, lvl, lvl * 4, lvl * 4, { 33, 0, 0, 0 }, { 35, 0, 0, 0 }, { 0, 0 }, item)
  ev((trainer and "trainer " or "battle ") .. sp .. (item ~= 0 and (" holds " .. item) or ""))
end

local DMG = { [10] = 6, [52] = 9, [168] = 2 }
local wins = 0

local function winBattle(b)
  wins = wins + 1
  if wins % 3 == 0 then leadM.level = leadM.level + 1; leadM.maxHP = leadM.maxHP + 2 end
  -- Pickup: only after a win, only if holding nothing (60% in the simulator to go fast)
  for i = 2, #party do
    local m = party[i]
    if m.species == 52 and m.item == 0 and math.random() < 0.6 then
      m.item = PICKUP_ITEMS[math.random(1, #PICKUP_ITEMS)]; stats.pickups = stats.pickups + 1; ev("pickup " .. m.item)
    end
  end
  if b.trainer then cash = cash + 480; syncMoney(); stats.trainerBattles = stats.trainerBattles + 1 end
  syncParty()
end

local function battleFrame()
  local b = W.battle
  b.t = b.t + 1
  local function toAction() b.phase = "action"; w8(BUFA, 18); w32(FLAGS, 1); b.ready = b.t + 8 end
  local function textPhase(n, nextf) b.phase = "text"; b.texts = n; b.after = nextf; b.ready = b.t + 10; w32(SPTR, OP_TEXT) end
  local function finish() b.phase = "ending"; b.endT = b.t end
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
        if b.trainer then error("RAN FROM TRAINER") end
        stats.ran = stats.ran + 1; w8(OUTC, 4)
        textPhase(1, finish)
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
      w32(FLAGS, 0)
      leadM.pp[c + 1] = leadM.pp[c + 1] - 1; w8(BMONS + 0x24 + c, leadM.pp[c + 1]); syncParty()
      if mv == 168 then
        stats.thiefUses = (stats.thiefUses or 0) + 1
        if b.foeItem == 0 then error("THIEF ON A MON WITHOUT ITEM") end
        if b.foeItem == 139 then error("THIEF ON AN UNWANTED ITEM") end
        if r16(BMONS + 0x2E) == 0 then
          w16(BMONS + 0x2E, b.foeItem); w16(BMONS + 0x58 + 0x2E, 0)
          b.stolen = b.foeItem; b.foeItem = 0; stats.steals = stats.steals + 1; ev("stole " .. b.stolen)
        end
      end
      b.ehp = b.ehp - (DMG[mv] or 5); w16(BMONS + 0x58 + 0x28, math.max(b.ehp, 0))
      if b.ehp <= 0 then
        stats.fought = stats.fought + 1
        textPhase(2, function() winBattle(b); finish() end)
      else
        textPhase(1, function()
          leadM.hp = math.max(leadM.hp - 3, 0); syncParty(); w16(BMONS + 0x28, leadM.hp)
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
  elseif b.phase == "ending" then
    if b.t - b.endT == 20 then w8(INB, 0); w32(CB2, CB_TRANS) end
    if b.t - b.endT == 50 then
      if b.stolen then leadM.item = b.stolen; syncParty() end
      w32(CB2, CB_OW); W.battle = nil; W.cool = 10
    end
  end
end

-- ---------------- START menu and party screen ----------------
-- Order: POKEDEX, POKEMON, BAG, PLAYER, SAVE, OPTION, EXIT. The cursor
-- remembers its position (it starts on SAVE to force the bot to move it).
for i, v in ipairs({ 0, 1, 2, 3, 4, 5, 6 }) do w8(START_ORD + i - 1, v) end
w8(START_CNT, 7); w8(START_CUR, 4)
w32(PINT, INTERNAL)

local function setActions(list)
  for k = 0, 7 do w8(INTERNAL + 0x0F + k, list[k + 1] or 0) end
  w8(INTERNAL + 0x17, #list); w8(MCURSOR, 0)
end

local function menuFrame()
  local M = W.menu
  M.t = M.t + 1
  if M.kind == "start" then
    if M.t < 6 then return end
    local c, n = r8(START_CUR), r8(START_CNT)
    if edge("down") then w8(START_CUR, (c + 1) % n)
    elseif edge("up") then w8(START_CUR, (c - 1) % n)
    elseif edge("B") or edge("start") then setTask(0, nil); W.menu = nil; W.cool = 6
    elseif edge("A") then
      if r8(START_ORD + c) ~= 1 then error("BOT OPENED START OPTION " .. r8(START_ORD + c)) end
      setTask(0, nil); M.kind = "fadein"; M.t = 0; stats.menuOpens = stats.menuOpens + 1
    end
  elseif M.kind == "fadein" then
    if M.t == 30 then w32(CB2, CB_PARTY); w8(PMENU + 9, 0); setTask(1, F_CHOOSE); M.kind = "choose"; M.t = 0 end
  elseif M.kind == "choose" then
    if M.t < 6 then return end
    local s = r8(PMENU + 9)
    if s >= 0x80 then s = s - 0x100 end
    local n = #party
    if edge("down") then
      if s == 7 then s = 0 elseif s + 1 >= n then s = 7 else s = s + 1 end; w8(PMENU + 9, s)
    elseif edge("up") then
      if s == 7 then s = n - 1 elseif s == 0 then s = 7 else s = s - 1 end; w8(PMENU + 9, s)
    elseif edge("B") then setTask(1, nil); M.kind = "fadeout"; M.t = 0
    elseif edge("A") then
      if s == 7 then setTask(1, nil); M.kind = "fadeout"; M.t = 0; return end
      -- With a field move (e.g. CUT) the list changes and ITEM moves down one place
      local acts = (SCEN == "campo") and { 0, 19, 1, 3, 2 } or { 0, 1, 3, 2 }
      M.slot = s; setActions(acts); setTask(1, F_SELECT); M.kind = "actions"; M.t = 0
    end
  elseif M.kind == "actions" or M.kind == "itemmenu" then
    if M.t < 6 then return end
    local c = r8(MCURSOR)
    local n = r8(INTERNAL + 0x17)
    if edge("down") then w8(MCURSOR, (c + 1) % n)
    elseif edge("up") then w8(MCURSOR, (c - 1) % n)
    elseif edge("B") then setTask(1, F_CHOOSE); M.kind = "choose"; M.t = 0
    elseif edge("A") then
      local opt = r8(INTERNAL + 0x0F + c)
      if M.kind == "actions" then
        if opt ~= 3 then error("BOT PICKED ACTION " .. opt) end
        setActions({ 4, 5, 9 }); M.kind = "itemmenu"; M.t = 0
      else
        if opt ~= 5 then error("BOT PICKED ITEM ACTION " .. opt) end
        local m = party[M.slot + 1]
        if m.item ~= 0 and (bag[m.item] or 0) < BAGMAX then
          bag[m.item] = (bag[m.item] or 0) + 1; syncBag()
          stats.taken = stats.taken + 1; ev("took " .. m.item); m.item = 0; syncParty()
        end
        setTask(1, F_MSG); M.kind = "message"; M.t = 0
      end
    end
  elseif M.kind == "message" then
    if M.t > 20 and (edge("A") or edge("B")) then setTask(1, F_CHOOSE); M.kind = "choose"; M.t = 0 end
  elseif M.kind == "fadeout" then
    -- back to the map with the START menu open again (CB2_ReturnToFieldWithOpenMenu)
    if M.t == 30 then w32(CB2, CB_OW); setTask(0, F_START); M.kind = "start"; M.t = 0 end
  elseif M.kind == "msg" then
    -- field message (VS Seeker): close with A/B
    if M.t > 20 and (edge("A") or edge("B")) then W.menu = nil; W.cool = 6 end
  elseif M.kind == "vsseeker" then
    if M.t == 70 then setTask(2, nil); M.kind = "msg"; M.t = 0; W.ready = true end
  elseif M.kind == "trainer" then
    -- the trainer walks up to you and talks: close the text and the battle starts
    if M.t > 40 and (edge("A") or edge("B")) then W.menu = nil; W.beaten[M.who] = true; startBattle(true) end
  end
end

-- ---------------- Pokemon Center ----------------
local function passable(g, n, x, y)
  if g == 3 then return x >= 0 and x <= 30 and y >= 3 and y <= 20 end
  return x >= 1 and x <= 9 and y >= 3 and y <= 8
end

local function healAll()
  for _, m in ipairs(party) do
    m.hp = m.maxHP
    local BASEPP = { [10] = 35, [52] = 25, [168] = 10 }
    for k = 1, 4 do m.pp[k] = BASEPP[m.moves[k]] or 0 end
  end
  syncParty()
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
    if d.t == 60 then healAll(); stats.heals = stats.heals + 1; ev("healed") end
    if d.t > 70 then d.step = 4; d.t = 0 end
  elseif d.step == 4 or d.step == 5 then if d.t > 10 and adv then d.step = d.step + 1; d.t = 0 end
  elseif d.step == 6 then W.dialog = nil; W.cool = 10 end
end

-- trainers (dinero): they see you on these tiles, after using the VS Seeker
local TRAINERS = { { x = 11, y = 10 }, { x = 14, y = 10 } }

local function worldFrame()
  if W.battle then battleFrame(); return end
  if W.menu then menuFrame(); return end
  if W.dialog then nurseFrame(); return end
  if W.cool > 0 then W.cool = W.cool - 1; return end
  if W.walkT > 0 then
    W.walkT = W.walkT - 1
    if W.walkT == 0 then
      if charge < 100 then charge = charge + 1; syncCharge() end
      if SCEN == "dinero" and W.ready and W.g == 3 then
        for i, t in ipairs(TRAINERS) do
          if W.x == t.x and W.y == t.y and not W.beaten[i] then W.menu = { kind = "trainer", t = 0, who = i }; return end
        end
      end
      if W.g == 3 and W.y == 10 and not W.noEnc and math.random() < 0.25 then startBattle(false) end
      if W.auto then local a = W.auto; W.auto = nil; W.x, W.y, W.face = a.x, a.y, a.face; W.walkT = 16 end
    end
    return
  end
  if edge("start") then W.menu = { kind = "start", t = 0 }; setTask(0, F_START); return end
  if edge("select") then
    if r16(SB1 + 0x296) ~= 362 then error("SELECT WITHOUT REGISTERED ITEM") end
    if charge >= 100 then
      charge = 0; syncCharge(); stats.vsUses = stats.vsUses + 1; W.beaten = {}; ev("vs seeker")
      W.menu = { kind = "vsseeker", t = 0 }; setTask(2, F_VSSEEK)
    else W.menu = { kind = "msg", t = 0 } end
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
  if W.g == 3 and W.x == 10 and W.y == 3 and dir == "up" then
    W.g, W.n, W.x, W.y, W.face = 4, 1, 5, 8, 2; W.cool = 40; ev("enter center"); return
  end
  if W.g == 4 and W.x == 5 and W.y == 8 and dir == "down" then
    W.g, W.n, W.x, W.y, W.face = 3, 20, 10, 2, 1; W.cool = 40; W.auto = { x = 10, y = 3, face = 1 }; W.walkT = 1
    ev("exit center"); return
  end
  local nx, ny = W.x + dx, W.y + dy
  if passable(W.g, W.n, nx, ny) then W.x, W.y = nx, ny; W.walkT = 16 end
end

-- ---------------- API ----------------
local MAXF = 400000
local pendingPad = {}
joypad = { set = function(_, t)
  if SCEN == "diag" and next(t or {}) then error("BOT PRESSED A BUTTON IN DIAGNOSTIC MODE") end
  for k, v in pairs(t or {}) do pendingPad[k] = v end
end }
-- "diag": the player opens the menus by hand (START, up to POKEMON, picks the first one)
local userPads = { [400] = "start", [440] = "up", [460] = "up", [480] = "up", [520] = "A", [600] = "A" }
gui = { text = function() end }
savestate = { create = function() return {} end, save = function() end, load = function() end }
local hotkeys = {}
input = { get = function() return hotkeys[frame] or {} end }
local lastInput = 0
emu = {
  framecount = function() return frame end,
  pause = function() error("PAUSED") end,
  frameadvance = function()
    prevHeld = held; held = pendingPad; pendingPad = {}
    if SCEN == "diag" and userPads[frame] then held[userPads[frame]] = true end
    if next(held) then lastInput = frame end
    if frame - lastInput > 20000 then error("IDLE") end
    worldFrame()
    writePos()
    frame = frame + 1
    if frame > MAXF then error("TIMEOUT") end
  end,
}
local printed = {}
_G.print = function(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring(select(i, ...)) end
  printed[#printed + 1] = table.concat(t, " ") end

hotkeys[300] = { [(SCEN == "diag") and "4" or "7"] = true }

return function(chunk)
  local ok, err = pcall(chunk)
  local heldNow = {}
  for i, m in ipairs(party) do heldNow[i] = m.item end
  local bagTxt = {}
  for id, q in pairs(bag) do bagTxt[#bagTxt + 1] = id .. "x" .. q end
  table.sort(bagTxt)
  return tostring(err), frame, stats.battles, stats.fought, stats.ran, stats.heals, leadM.level,
    stats.pickups, stats.taken, table.concat(heldNow, ","), table.concat(bagTxt, " "), stats.steals,
    stats.thiefUses or 0, cash, stats.trainerBattles, stats.vsUses, stats.menuOpens,
    table.concat(printed, "\n"), table.concat(stats.events, " ")
end
