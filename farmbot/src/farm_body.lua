-- ===================================================================
--  FRLG Farm Bot v1.0  (FireRed / LeafGreen - VBA-ReRecording)
--
--  SEPARATE script from the Shiny Bot and the Train Bot: farms items, levels or money.
--  Load ONLY this script (not together with the other bots).
--
--  Modes ("mode" in FRLG_FarmBot.json):
--    "nivel"   - fights everything until the first party Pokemon reaches targetLevel.
--    "objetos" - wins battles with PICKUP Pokemon in the party and takes the
--                items they pick up (START > POKEMON > ITEM > TAKE menu).
--    "robar"   - uses THIEF / COVET when the wild Pokemon holds an item you want
--                and runs; then stores the item in the bag.
--    "dinero"  - uses the VS SEEKER (registered on SELECT) and walks the trainers'
--                route for rematches, until it has moneyTarget.
--
--  Teclas:
--    7 = start / stop
--    6 = record the route to the Pokemon Center (same as in the Train Bot)
--    5 = record the trainers' route ("dinero" mode)
--    8 = view Pokemon: stats, IVs, EVs, nature, moves (party 1-6 and opponent)
--    9 = panel (compact / full / hidden)
--    0 = reload FRLG_FarmBot.json
-- ===================================================================

local CONFIG = {
  mode           = "nivel",   -- "nivel", "objetos" (Pickup), "robar" (Thief/Covet) or "dinero" (trainers)
  targetLevel    = nil,       -- nivel: stop when the first party Pokemon reaches this level
  itemTarget     = nil,       -- objetos/robar: stop after storing this many items (nil = no limit)
  takeItems      = "auto",    -- objetos/robar: "auto" = take them through the menu; "pause" = pause and tell you
  wantedItems    = nil,       -- robar: items worth stealing (English name); nil = any
  moneyTarget    = nil,       -- dinero: stop when this much money is reached (nil = no limit)
  trainerRouteFile = "FRLG_FarmTrainers.txt",  -- dinero: walk through the trainers' lines of sight (key 5)
  maxBattles     = nil,       -- stop after this many battles, in any mode (nil = no limit)
  species        = nil,       -- fight ONLY these species (nil = all of them)
  avoidSpecies   = nil,       -- never fight these
  healBelow      = 40,        -- go heal if HP drops below this % (after the battle)
  fleeBelow      = 20,        -- run mid-battle if HP drops below this % (not against trainers)
  minPP          = 3,         -- go heal if fewer total PP are left in useful moves
  learnMoves     = "auto",    -- "auto" = learns if it is better, "never" = never, "ask" = lets you decide
  keepMoves      = nil,       -- moves that are never forgotten, e.g. {"Thief"}
  wantedMoves    = nil,       -- wanted final moves (max 4): learns only these and rejects the rest
  askTimeout     = 300,       -- "ask": seconds to wait for your decision before deciding alone (nil = always wait)
  notify         = nil,       -- phone notifications: {ntfy = "your-topic"} and/or {discord = "webhook url"}
  evolve         = false,     -- false = cancel evolutions (B), true = let it evolve (you decide)
  stopOnShiny    = true,      -- pause if a wild shiny appears
  walkAxis       = "horizontal",
  walkFrames     = 16,
  routeFile      = "FRLG_TrainRoute.txt",  -- route to the Center (key 6); the Train Bot's one works
  healMode       = "nurse",   -- "nurse" = talk to the nurse; "tile" = healing tile (Tower 5F purified zone)
  logFile        = "farm_log.txt",
  logDir         = "logs",
  language       = "es",      -- "es", "en" or "ja" (romaji): panel, console and log text
}
local CONFIG_FILE = "FRLG_FarmBot.json"
--@@LANG@@

local read32  = memory.readdwordunsigned
local read16  = memory.readwordunsigned
local read8   = memory.readbyte
local write32 = memory.writedword
local rshift, band, bxor = bit.rshift, bit.band, bit.bxor
local floor = math.floor

--@@TABLES@@
--@@DATA@@

-- ------------------------- Version / addresses ---------------------
local gameCode = read8(0x080000AE)
local gameLang = read8(0x080000AF)
local gameRev1 = read8(0x080000BC) == 0x1
local gameName = (gameCode == 0x52 and "FireRed") or (gameCode == 0x47 and "LeafGreen") or nil

local A = {}
if gameLang == 0x45 then        -- USA
  A.currSeed, A.enemy, A.party, A.partyCnt = 0x03005000, 0x0202402C, 0x02024284, 0x02024029
  A.sb1, A.sb2, A.gMain = 0x03005008, 0x0300500C, 0x030030F0
elseif gameLang == 0x4A then    -- JPN
  if gameRev1 then A.currSeed, A.sb1, A.sb2 = 0x03004FA0, 0x03004FA8, 0x03004FAC
  else A.currSeed, A.sb1, A.sb2 = 0x03005040, 0x03005048, 0x0300504C end
  A.enemy, A.party, A.partyCnt = 0x02023F8C, 0x020241E4, 0x02023F89
else                            -- EUR (ESP, FRA, ITA, GER)
  A.currSeed, A.enemy, A.party, A.partyCnt = 0x03004F50, 0x0202402C, 0x02024284, 0x02024029
  A.sb1, A.sb2 = 0x03004F58, 0x03004F5C
end
A.gMain = A.gMain or (A.currSeed - 0x1F10)
A.inBattleByte = A.gMain + 0x439
A.callback2    = A.gMain + 4
-- Battle variables (pokefirered, USA) at the same distance from gEnemyParty
A.actionCursor = A.enemy - 0x34    -- gActionSelectionCursor[0]
A.moveCursor   = A.enemy - 0x30    -- gMoveSelectionCursor[0]
A.battleMons   = A.enemy - 0x448   -- gBattleMons[0..3] (0x58 c/u)
A.bufferA      = A.enemy - 0x1468  -- gBattleBufferA[0][0] = player command
A.execFlags    = A.enemy - 0x464   -- gBattleControllerExecFlags
A.scriptPtr    = A.enemy - 0x2B8   -- gBattlescriptCurrInstr
A.yesNoCursor  = A.enemy - 0x1A9   -- gBattleCommunication[1]
A.battleOutcome = A.enemy - 0x1A2
A.avatar  = (gameLang == 0x4A) and 0x02036FAC or 0x02037078   -- gPlayerAvatar
A.objects = A.avatar - 0x240                                   -- gObjectEvents

A.battleType = A.enemy - 0x14E0    -- gBattleTypeFlags (0x02022B4C in USA)

-- Field menus (pokefirered, "symbols" branch). RAM is the same in the four
-- USA versions (FireRed / LeafGreen 1.0 and 1.1); the functions differ.
-- Other versions have no verified map: taking items falls back to "pause".
local MENU = nil
if gameLang == 0x45 and gameName then
  local fn = ({
    FireRed0   = { 0x0806F1F0, 0x0811EBA0, 0x0811FB28, 0x08122C5C, 0x0810C670 },
    FireRed1   = { 0x0806F204, 0x0811EC18, 0x0811FBA0, 0x08122CD4, 0x0810C6E8 },
    LeafGreen0 = { 0x0806F1F0, 0x0811EB78, 0x0811FB00, 0x08122C34, 0x0810C648 },
    LeafGreen1 = { 0x0806F204, 0x0811EBF0, 0x0811FB78, 0x08122CAC, 0x0810C6C0 },
  })[gameName .. (gameRev1 and "1" or "0")]
  if fn then
    MENU = {
      startCursor = 0x020370F4, startCount = 0x020370F5, startOrder = 0x020370F6,
      partyMenu = 0x0203B0A0, partyInternal = 0x0203B09C, menuCursor = 0x0203ADE6, tasks = 0x03005090,
      -- functions (+1: Thumb code)
      taskStartMenu = fn[1] + 1, cbParty = fn[2] + 1, taskChooseMon = fn[3] + 1, taskSelection = fn[4] + 1,
      taskVsSeeker = fn[5] + 1,
    }
  end
end
-- Game constants (a single table: Lua 5.1 allows 200 locals per block)
local K = {
  STARTMENU_POKEMON = 1,
  OPT_ITEM = 3, OPT_TAKE = 5,                  -- CURSOR_OPTION_ITEM / CURSOR_OPTION_TAKE_ITEM
  ITEM_VS_SEEKER = 362,
  ABILITY_PICKUP = 53,
  MOVE_THIEF = 168, MOVE_COVET = 343,
  BT_DOUBLE = 0x01, BT_TRAINER = 0x08,
  -- SaveBlock1 / SaveBlock2 (pokefirered include/global.h)
  SB1_MONEY = 0x290, SB1_REGISTERED = 0x296, SB1_VSSEEKER = 0x638, SB2_KEY = 0xF20,
  POCKETS = { { 0x310, 42 }, { 0x3B8, 30 }, { 0x430, 13 }, { 0x464, 58 }, { 0x54C, 43 } },
}

local CMD_CHOOSEACTION, CMD_CHOOSEMOVE = 18, 20
local OP_LEARNMOVE, OP_STOPLEARNING = 0x5A, 0x5B
A.moveToLearn = A.enemy - 0xA       -- gMoveToLearn
A.sumCursor   = A.enemy + 0x17141   -- sMoveSelectionCursorPos (summary screen, picking the move to forget)
local HM_MOVES = { [15] = true, [19] = true, [57] = true, [70] = true, [127] = true, [148] = true, [249] = true, [291] = true }

-- ------------------------------ Utilidades ---------------------------
local SCRIPT_DIR = ""
pcall(function()
  local src = debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then SCRIPT_DIR = src:sub(2):match("^(.*[/\\])") or "" end
end)

local function jsonDecode(str)
  local pos = 1
  local function err(msg) error(string.format(TX"JSON: %s (caracter %d)", msg, pos), 0) end
  local function skip()
    while true do
      local _, e = str:find("^[ \t\r\n]+", pos)
      if e then pos = e + 1 end
      if str:sub(pos, pos + 1) == "//" then pos = (str:find("\n", pos) or #str) + 1 else return end
    end
  end
  local value
  local function parseString()
    pos = pos + 1
    local out = {}
    while true do
      local c = str:sub(pos, pos)
      if c == "" then err(TX"texto sin cerrar") end
      if c == '"' then pos = pos + 1; break end
      if c == "\\" then out[#out + 1] = str:sub(pos + 1, pos + 1); pos = pos + 2
      else out[#out + 1] = c; pos = pos + 1 end
    end
    return table.concat(out)
  end
  value = function()
    skip()
    local c = str:sub(pos, pos)
    if c == "{" then
      pos = pos + 1
      local obj = {}
      skip()
      if str:sub(pos, pos) == "}" then pos = pos + 1; return obj end
      while true do
        skip()
        if str:sub(pos, pos) ~= '"' then err(TX"se esperaba un nombre entre comillas") end
        local k = parseString()
        skip()
        if str:sub(pos, pos) ~= ":" then err(TX"falta ':'") end
        pos = pos + 1
        obj[k] = value()
        skip()
        local d = str:sub(pos, pos); pos = pos + 1
        if d == "}" then return obj end
        if d ~= "," then err(TX"falta ',' o '}'") end
        skip()
        if str:sub(pos, pos) == "}" then pos = pos + 1; return obj end
      end
    elseif c == "[" then
      pos = pos + 1
      local arr = {}
      skip()
      if str:sub(pos, pos) == "]" then pos = pos + 1; return arr end
      while true do
        arr[#arr + 1] = value()
        skip()
        local d = str:sub(pos, pos); pos = pos + 1
        if d == "]" then return arr end
        if d ~= "," then err(TX"falta ',' o ']'") end
        skip()
        if str:sub(pos, pos) == "]" then pos = pos + 1; return arr end
      end
    elseif c == '"' then return parseString()
    elseif str:sub(pos, pos + 3) == "true" then pos = pos + 4; return true
    elseif str:sub(pos, pos + 4) == "false" then pos = pos + 5; return false
    elseif str:sub(pos, pos + 3) == "null" then pos = pos + 4; return nil
    else
      local num = str:match("^-?%d+%.?%d*", pos)
      if not num or num == "" then err(TX"valor no valido") end
      pos = pos + #num
      return tonumber(num)
    end
  end
  local v = value()
  skip()
  if pos <= #str then err(TX"texto de mas al final") end
  return v
end

local function simplify(name)
  name = tostring(name):lower()
  local acc = { ["\195\161"] = "a", ["\195\169"] = "e", ["\195\173"] = "i", ["\195\179"] = "o",
                ["\195\186"] = "u", ["\195\177"] = "n" }
  for k, v in pairs(acc) do name = name:gsub(k, v) end
  return (name:gsub("[^%w]", ""))
end

local tcfg = {}   -- parsed configuration

local function speciesName(idx)
  local dex = nationalDexList[idx + 1]
  return (dex and speciesNamesList[dex]) or ("#" .. idx)
end
local function speciesSet(list, problems)
  if type(list) ~= "table" and list ~= nil then list = { list } end
  if not list or #list == 0 then return nil end
  local set = {}
  for _, n in ipairs(list) do
    local sn, found = simplify(n), false
    for idx = 1, 411 do
      if simplify(speciesName(idx)) == sn then set[idx] = true; found = true end
    end
    if not found then problems[#problems + 1] = TX"especie desconocida: " .. tostring(n) end
  end
  return set
end

local function itemIdByName(name)
  local sn = simplify(name)
  for id, n in pairs(TT_ITEMNAME) do if simplify(n) == sn then return id end end
  return nil
end
local function itemName(id) return (id and id ~= 0) and (TT_ITEMNAME[id] or ("#" .. id)) or "-" end

local FARM_MODES = { nivel = true, objetos = true, robar = true, dinero = true }
local function interpretConfig(problems)
  tcfg = { target = nil }
  -- First, so the other messages already come out in the chosen language.
  local lang = simplify(CONFIG.language or "es")
  if lang ~= "es" and lang ~= "en" and lang ~= "ja" then
    CONFIG.language = "es"
    problems[#problems + 1] = TX"language debe ser \"es\", \"en\" o \"ja\""; lang = "es"
  end
  CONFIG.language = lang
  local mode = simplify(CONFIG.mode or "nivel")
  if not FARM_MODES[mode] then
    problems[#problems + 1] = TX"mode debe ser \"nivel\", \"objetos\", \"robar\" o \"dinero\""; mode = "nivel"
  end
  tcfg.mode = mode
  local tk = simplify(CONFIG.takeItems or "auto")
  if tk ~= "auto" and tk ~= "pause" then problems[#problems + 1] = TX"takeItems debe ser \"auto\" o \"pause\""; tk = "pause" end
  tcfg.take = tk
  tcfg.wantedItems = nil
  if CONFIG.wantedItems ~= nil then
    local list = type(CONFIG.wantedItems) == "table" and CONFIG.wantedItems or { CONFIG.wantedItems }
    if #list > 0 then
      tcfg.wantedItems = {}
      for _, n in ipairs(list) do
        local id = itemIdByName(n)
        if id then tcfg.wantedItems[id] = true
        else problems[#problems + 1] = TX"objeto desconocido en wantedItems: " .. tostring(n) .. TX" (usa el nombre en ingles)" end
      end
    end
  end
  local function num(key, lo, hi)
    local v = CONFIG[key]
    if v == nil then return end
    if type(v) ~= "number" or v < lo or v > hi or floor(v) ~= v then
      problems[#problems + 1] = string.format(TX"%s debe ser un numero entero entre %d y %d", key, lo, hi)
      CONFIG[key] = nil
    end
  end
  num("targetLevel", 1, 100); num("itemTarget", 1, 99999); num("moneyTarget", 1, 999999); num("maxBattles", 1, 999999)
  if mode == "nivel" and not CONFIG.targetLevel and not CONFIG.maxBattles then
    problems[#problems + 1] = TX"el modo \"nivel\" necesita targetLevel (o maxBattles)"
  end
  tcfg.only = speciesSet(CONFIG.species, problems)
  tcfg.avoid = speciesSet(CONFIG.avoidSpecies, problems)
  local lm = simplify(CONFIG.learnMoves or "auto")
  if lm ~= "never" and lm ~= "ask" and lm ~= "auto" then
    problems[#problems + 1] = TX"learnMoves debe ser \"auto\", \"never\" o \"ask\""; lm = "never"
  end
  tcfg.learn = lm
  local function moveSet(list, key)
    if list == nil then return nil, 0 end
    if type(list) ~= "table" then list = { list } end
    local set, n = {}, 0
    for _, name in ipairs(list) do
      local sn, found = simplify(name), false
      for id, mv in pairs(TT_MOVE) do
        if simplify(mv[7]) == sn then set[id] = true; found = true; n = n + 1; break end
      end
      if not found then problems[#problems + 1] = TX"ataque desconocido en " .. key .. ": " .. tostring(name) .. TX" (usa el nombre en ingles)" end
    end
    return set, n
  end
  tcfg.keep = moveSet(CONFIG.keepMoves, "keepMoves") or {}
  -- In "robar" the stealing move is never forgotten
  if mode == "robar" then tcfg.keep[K.MOVE_THIEF] = true; tcfg.keep[K.MOVE_COVET] = true end
  local wn
  tcfg.wanted, wn = moveSet(CONFIG.wantedMoves, "wantedMoves")
  if tcfg.wanted and wn == 0 then tcfg.wanted = nil end
  if wn > 4 then problems[#problems + 1] = TX"wantedMoves tiene " .. wn .. TX" ataques (maximo 4)" end
  if CONFIG.notify ~= nil and type(CONFIG.notify) ~= "table" then problems[#problems + 1] = TX"notify debe ser {\"ntfy\": \"tema\"}" end
end

local function loadConfig()
  local problems = {}
  local ok, msg = pcall(function()
    local f = io.open(SCRIPT_DIR .. CONFIG_FILE, "r")
    if not f then return "no existe" end
    local data = f:read("*a"); f:close()
    local cfg = jsonDecode(data)
    if type(cfg) ~= "table" then error(TX"el archivo debe ser un objeto { ... }", 0) end
    local optional = { targetLevel = 1, itemTarget = 1, wantedItems = 1, moneyTarget = 1, maxBattles = 1, species = 1,
                       avoidSpecies = 1, keepMoves = 1, wantedMoves = 1, askTimeout = 1, notify = 1 }
    for k, v in pairs(cfg) do
      if CONFIG[k] == nil and not optional[k] then problems[#problems + 1] = TX"opcion desconocida: " .. k end
      CONFIG[k] = v
    end
    for k in pairs(optional) do if cfg[k] == nil then CONFIG[k] = nil end end
    return "ok"
  end)
  interpretConfig(problems)
  return ok, msg, problems
end
local cfgOk, cfgMsg, cfgProblems = loadConfig()

local LOGDIR = SCRIPT_DIR
if CONFIG.logDir and CONFIG.logDir ~= "" then
  LOGDIR = SCRIPT_DIR .. tostring(CONFIG.logDir):gsub("[/\\]+$", "") .. "/"
  local okDir = false
  pcall(function()
    local f = io.open(LOGDIR .. ".write_test", "w")
    if f then f:close(); os.remove(LOGDIR .. ".write_test"); okDir = true end
  end)
  if not okDir then
    pcall(function()
      local d = LOGDIR:gsub("/$", "")
      if d:find('["%%$`]') then return end   -- never pass paths with quotes or variables to the shell
      if package and package.config and package.config:sub(1, 1) == "\\" then
        os.execute('mkdir "' .. d:gsub("/", "\\") .. '" 2>nul')
      else os.execute('mkdir -p "' .. d .. '" 2>/dev/null') end
    end)
    pcall(function()
      local f = io.open(LOGDIR .. ".write_test", "w")
      if f then f:close(); os.remove(LOGDIR .. ".write_test"); okDir = true end
    end)
    if not okDir then LOGDIR = SCRIPT_DIR end
  end
end

local LANG_NAMES = { [0x45] = "USA", [0x4A] = "JPN", [0x53] = "ESP", [0x46] = "FRA", [0x49] = "ITA", [0x44] = "GER" }
local GAME_LABEL = string.format("%s %s %s", gameName or "?", LANG_NAMES[gameLang] or string.format("0x%02X", gameLang),
                                 gameRev1 and "v1.1" or "v1.0")
local function logLine(text)
  local stamp = ""
  pcall(function() stamp = os.date("%Y-%m-%d %H:%M:%S") end)
  print(text)
  pcall(function()
    local f = io.open(LOGDIR .. CONFIG.logFile, "a")
    if f then f:write(string.format("[%s] [%s] %s\n", stamp, GAME_LABEL, text)); f:close() end
  end)
end

-- Phone notification (ntfy.sh and/or Discord) via curl, without blocking the emulator.
-- curl ships with Windows 10/11.
local function notify(text)
  local n = CONFIG.notify
  if type(n) ~= "table" then return end
  local clean = ("[" .. GAME_LABEL .. "] " .. text):gsub("[^%w%s%.,:;%-/!%?%(%)]", "")
  local win = package and package.config and package.config:sub(1, 1) == "\\"
  local function run(cmd)
    pcall(function()
      if win then os.execute('start "" /B ' .. cmd) else os.execute(cmd .. " >/dev/null 2>&1 &") end
    end)
  end
  if type(n.ntfy) == "string" and n.ntfy:match("^[%w_%-]+$") then
    run(string.format('curl -s -m 15 -H "Title: FRLG Farm Bot" -d "%s" https://ntfy.sh/%s', clean, n.ntfy))
  end
  if type(n.discord) == "string" and n.discord:match("^https://[%w%./_%-]+$") then
    run(string.format('curl -s -m 15 -H "Content-Type: application/json" -d "{\\"content\\":\\"%s\\"}" %s', clean, n.discord))
  end
end

local function validPtr(p) return p >= 0x02000000 and p < 0x02040000 end
local function s16(v) if v >= 0x8000 then return v - 0x10000 end return v end

-- ------------------------- Pokemon data --------------------------
-- Order of the 4 substructures by PID % 24 (G=growth A=attacks E=EVs M=misc)
local SUB_ORDER = { "GAEM", "GAME", "GEAM", "GEMA", "GMAE", "GMEA", "AGEM", "AGME", "AEGM", "AEMG", "AMGE", "AMEG",
                    "EGAM", "EGMA", "EAGM", "EAMG", "EMGA", "EMAG", "MGAE", "MGEA", "MAGE", "MAEG", "MEGA", "MEAG" }
local function subOffset(pid, letter)
  return (SUB_ORDER[(pid % 24) + 1]:find(letter) - 1) * 12
end

local function ivsFromWord(w)   -- screen order: HP/Atk/Def/SpA/SpD/Spe
  return { band(w, 0x1F), band(rshift(w, 5), 0x1F), band(rshift(w, 10), 0x1F),
           band(rshift(w, 20), 0x1F), band(rshift(w, 25), 0x1F), band(rshift(w, 15), 0x1F) }
end

-- Reads a party Pokemon (100 bytes) with checksum
local function readPartyMon(addr)
  local pid = read32(addr)
  if pid == 0 then return nil end
  local otid = read32(addr + 4)
  local key = bxor(pid, otid)
  local words, sum = {}, 0
  for i = 0, 11 do
    local w = bxor(read32(addr + 0x20 + i * 4), key)
    if w < 0 then w = w + 4294967296 end
    words[i] = w
    sum = sum + band(w, 0xFFFF) + band(rshift(w, 16), 0xFFFF)
  end
  if band(sum, 0xFFFF) ~= read16(addr + 0x1C) then return nil end
  local function sub(letter) return subOffset(pid, letter) / 4 end
  local g, a, e, m = sub("G"), sub("A"), sub("E"), sub("M")
  local species = band(words[g], 0xFFFF)
  if species == 0 or species > 411 then return nil end
  local mon = { pid = pid, otid = otid, species = species, item = band(rshift(words[g], 16), 0xFFFF),
    friendship = band(rshift(words[g + 2], 8), 0xFF),
    moves = { band(words[a], 0xFFFF), band(rshift(words[a], 16), 0xFFFF),
              band(words[a + 1], 0xFFFF), band(rshift(words[a + 1], 16), 0xFFFF) },
    pp = { band(words[a + 2], 0xFF), band(rshift(words[a + 2], 8), 0xFF),
           band(rshift(words[a + 2], 16), 0xFF), band(rshift(words[a + 2], 24), 0xFF) },
    evs = { band(words[e], 0xFF), band(rshift(words[e], 8), 0xFF), band(rshift(words[e], 16), 0xFF),
            band(rshift(words[e], 24), 0xFF), band(words[e + 1], 0xFF), band(rshift(words[e + 1], 8), 0xFF) },
    pokerus = band(words[m], 0xFF), ivs = ivsFromWord(words[m + 1]), ivWord = words[m + 1],
    exp = words[g + 1], abilityBit = band(rshift(words[m + 1], 31), 1), ppBonuses = band(words[g + 2], 0xFF),
    level = read8(addr + 0x54), hp = read16(addr + 0x56), maxHP = read16(addr + 0x58) }
  mon.sv = bxor(bxor(otid % 0x10000, floor(otid / 0x10000)), bxor(pid % 0x10000, floor(pid / 0x10000)))
  return mon
end

-- Wild opponent: accepted once stable for 3 frames (it may be half-created)
local gFrame = 0
local enemyWatch = nil
local function readEnemyStable()
  local m = readPartyMon(A.enemy)
  if not m or m.level == 0 or m.level > 100 then enemyWatch = nil; return nil end
  local sig = string.format("%08X%08X%d", m.pid, m.otid, m.level)
  if not enemyWatch or enemyWatch.sig ~= sig then enemyWatch = { sig = sig, since = gFrame }; return nil end
  if gFrame - enemyWatch.since < 3 then return nil end
  return m
end
local function zeroEnemy() write32(A.enemy, 0); enemyWatch = nil end

-- Pokemon in battle (gBattleMons): 0 = yours, 1 = the opponent
local function battleMon(i)
  local b = A.battleMons + i * 0x58
  return { species = read16(b), atk = read16(b + 2), def = read16(b + 4), spe = read16(b + 6),
           spa = read16(b + 8), spd = read16(b + 0xA),
           moves = { read16(b + 0xC), read16(b + 0xE), read16(b + 0x10), read16(b + 0x12) },
           ivWord = read32(b + 0x14), ability = read8(b + 0x20), type1 = read8(b + 0x21), type2 = read8(b + 0x22),
           pp = { read8(b + 0x24), read8(b + 0x25), read8(b + 0x26), read8(b + 0x27) },
           hp = read16(b + 0x28), level = read8(b + 0x2A), friendship = read8(b + 0x2B), maxHP = read16(b + 0x2C),
           status = read32(b + 0x4C) }
end

-- Item held by a Pokemon in battle (gBattleMons[i].item)
local function battleItem(i) return read16(A.battleMons + i * 0x58 + 0x2E) end

-- Real ability of a party Pokemon (TT_SPECX = {ability1, ability2, gender})
local function abilityOf(m)
  local sx = m and TT_SPECX[m.species]
  if not sx then return 0 end
  return (m.abilityBit == 1 and sx[2] ~= 0) and sx[2] or sx[1]
end

-- Money and bag: stored XORed with the save key (SaveBlock2 + 0xF20)
local function saveKey()
  local sb2 = read32(A.sb2)
  if sb2 < 0x02000000 or sb2 >= 0x02040000 then return nil end
  return read32(sb2 + K.SB2_KEY)
end
local function money()
  local sb1, key = read32(A.sb1), saveKey()
  if not key or sb1 < 0x02000000 or sb1 >= 0x02040000 then return nil end
  local v = bxor(read32(sb1 + K.SB1_MONEY), key)
  if v < 0 then v = v + 4294967296 end
  return v
end
local function bagCount(itemId)
  local sb1, key = read32(A.sb1), saveKey()
  if not key or itemId == 0 then return 0 end
  local k16 = band(key, 0xFFFF)
  for _, pk in ipairs(K.POCKETS) do
    for i = 0, pk[2] - 1 do
      local a = sb1 + pk[1] + i * 4
      if read16(a) == itemId then return bxor(read16(a + 2), k16) end
    end
  end
  return 0
end
local function vsSeekerCharge()
  local sb1 = read32(A.sb1)
  if sb1 < 0x02000000 or sb1 >= 0x02040000 then return 0 end
  return read8(sb1 + K.SB1_VSSEEKER)
end
local function registeredItem()
  local sb1 = read32(A.sb1)
  if sb1 < 0x02000000 or sb1 >= 0x02040000 then return 0 end
  return read16(sb1 + K.SB1_REGISTERED)
end

local function inBattle() return band(read8(A.inBattleByte), 0x02) ~= 0 end
local function partyCount() local c = read8(A.partyCnt); if c > 6 then return 0 end return c end
local function lead() return readPartyMon(A.party) end
local function partyMon(i) return readPartyMon(A.party + i * 0x64) end
-- Party slots (0-5) with Pickup, and the ones holding an item
local function pickupSlots()
  local t = {}
  for i = 0, partyCount() - 1 do
    local m = partyMon(i)
    if m and abilityOf(m) == K.ABILITY_PICKUP then t[#t + 1] = i end
  end
  return t
end
local function holdingSlots(slots)
  local t = {}
  for _, i in ipairs(slots) do
    local m = partyMon(i)
    if m and m.item ~= 0 then t[#t + 1] = { slot = i, item = m.item } end
  end
  return t
end

local function playerPos()
  local sb1 = read32(A.sb1)
  if not validPtr(sb1) then return nil end
  local id = read8(A.avatar + 5)
  if id >= 16 then return nil end
  local o = A.objects + id * 0x24
  return { g = read8(sb1 + 4), n = read8(sb1 + 5), x = s16(read16(o + 0x10)), y = s16(read16(o + 0x12)),
           face = band(read8(o + 0x18), 0x0F) }
end
local function samePos(a, b) return a and b and a.g == b.g and a.n == b.n and a.x == b.x and a.y == b.y end
local DIR_KEY = { [1] = "down", [2] = "up", [3] = "left", [4] = "right" }

-- ------------------------ Types and damage ------------------------------
local TYPE_NAMES = { [0] = "Normal", "Lucha", "Volador", "Veneno", "Tierra", "Roca", "Bicho", "Fantasma", "Acero", "???",  --@i18n
  "Fuego", "Agua", "Planta", "Electrico", "Psiquico", "Hielo", "Dragon", "Siniestro" }  --@i18n
local EFFM = {}
do
  local i = 1
  while i <= #TT_EFF do
    if TT_EFF[i] == -1 then i = i + 1
    else
      local a, d, m = TT_EFF[i], TT_EFF[i + 1], TT_EFF[i + 2]
      EFFM[a * 32 + d] = m / 10
      i = i + 3
    end
  end
end
local function typeMult(mt, t1, t2)
  local m = EFFM[mt * 32 + t1] or 1
  if t2 ~= t1 then m = m * (EFFM[mt * 32 + t2] or 1) end
  return m
end

local ABIL_VOLT, ABIL_WATER, ABIL_FLASHFIRE, ABIL_WONDERGUARD, ABIL_LEVITATE = 10, 11, 18, 25, 26
local NEVER = {}
for _, k in ipairs({ "EXPLOSION", "DREAM_EATER", "FOCUS_PUNCH", "FALSE_SWIPE", "SNORE", "COUNTER", "MIRROR_COAT",
                     "BIDE", "FUTURE_SIGHT", "SPIT_UP", "OHKO", "ENDEAVOR", "PRESENT" }) do
  if EF[k] then NEVER[EF[k]] = true end
end

local function hiddenPower(ivWord)
  local iv = ivsFromWord(ivWord)   -- PS/At/Df/AtE/DfE/Vel
  local hp, at, df, sa, sd, sp = iv[1], iv[2], iv[3], iv[4], iv[5], iv[6]
  local t = floor(((hp % 2) + 2 * (at % 2) + 4 * (df % 2) + 8 * (sp % 2) + 16 * (sa % 2) + 32 * (sd % 2)) * 15 / 63)
  local function b(x) return floor(x / 2) % 2 end
  local pw = floor((b(hp) + 2 * b(at) + 4 * b(df) + 8 * b(sp) + 16 * b(sa) + 32 * b(sd)) * 40 / 63) + 30
  local typ = t + 1                 -- 1..16 = Fighting..Dark (without the ??? type)
  if typ >= 9 then typ = typ + 1 end
  return typ, pw
end

-- Expected damage of a move (already multiplied by accuracy)
local function moveValue(moveId, me, foe)
  local mv = TT_MOVE[moveId]
  if not mv then return 0, 0 end
  local power, mtype, acc, eff = mv[1], mv[2], mv[3], mv[4]
  if NEVER[eff] then return 0, 0 end
  if eff == EF.HIDDEN_POWER then mtype, power = hiddenPower(me.ivWord) end
  local mult = typeMult(mtype, foe.type1, foe.type2)
  if foe.ability == ABIL_LEVITATE and mtype == 4 then mult = 0 end
  if foe.ability == ABIL_VOLT and mtype == 13 then mult = 0 end
  if foe.ability == ABIL_WATER and mtype == 11 then mult = 0 end
  if foe.ability == ABIL_FLASHFIRE and mtype == 10 then mult = 0 end
  if foe.ability == ABIL_WONDERGUARD and mult <= 1 then mult = 0 end
  if mult == 0 then return 0, 0 end
  local accF = (acc == 0) and 1 or acc / 100
  -- Fixed damage
  if eff == EF.LEVEL_DAMAGE or eff == EF.PSYWAVE then return me.level * accF, me.level end
  if eff == EF.DRAGON_RAGE then return 40 * accF, 40 end
  if eff == EF.SONICBOOM then return 20 * accF, 20 end
  if eff == EF.SUPER_FANG then local d = math.max(floor(foe.hp / 2), 1); return d * accF, d end
  -- Variable power
  if eff == EF.RETURN then power = math.max(floor(me.friendship * 10 / 25), 1)
  elseif eff == EF.FRUSTRATION then power = math.max(floor((255 - me.friendship) * 10 / 25), 1)
  elseif eff == EF.FLAIL then
    local r = floor(me.hp * 48 / math.max(me.maxHP, 1))
    power = (r <= 1 and 200) or (r <= 4 and 150) or (r <= 9 and 100) or (r <= 16 and 80) or (r <= 32 and 40) or 20
  elseif eff == EF.ERUPTION then power = math.max(floor(150 * me.hp / math.max(me.maxHP, 1)), 1)
  elseif eff == EF.LOW_KICK then power = 60
  elseif eff == EF.MAGNITUDE then power = 71
  elseif eff == EF.FACADE and me.status ~= 0 then power = 140 end
  if power <= 1 then return 0, 0 end
  local factor = 1
  if eff == EF.MULTI_HIT then factor = 3 elseif eff == EF.DOUBLE_HIT or eff == EF.TWINEEDLE then factor = 2
  elseif eff == EF.TRIPLE_KICK then factor = 4.7 end
  if eff == EF.RAZOR_WIND or eff == EF.SKY_ATTACK or eff == EF.SOLAR_BEAM or eff == EF.SKULL_BASH
     or eff == EF.SEMI_INVULNERABLE then factor = factor * 0.5 end
  if eff == EF.RECHARGE then factor = factor * 0.6 end
  if eff == EF.RAMPAGE then factor = factor * 0.8 end
  local physical = mtype < 9
  local atk = physical and me.atk or me.spa
  local def = math.max(physical and foe.def or foe.spd, 1)
  local dmg = floor(floor(floor(2 * me.level / 5 + 2) * power * atk / def) / 50) + 2
  if mtype == me.type1 or mtype == me.type2 then dmg = dmg * 1.5 end
  dmg = dmg * mult * 0.925 * factor
  return dmg * accF, dmg
end

-- Best move against the opponent: the one with the most expected damage, without going
-- over its remaining HP (so it doesn't waste a strong move when a weak one is enough).
local function bestMove(blocked, meIdx, foeIdx)
  local me, foe = battleMon(meIdx or 0), battleMon(foeIdx or 1)
  local best, bestScore, bestPP = nil, 0, -1
  for i = 1, 4 do
    local id = me.moves[i]
    if id ~= 0 and me.pp[i] > 0 and not (blocked and blocked[i]) then
      local exp, raw = moveValue(id, me, foe)
      if exp > 0 then
        local acc = (TT_MOVE[id][3] == 0) and 1 or TT_MOVE[id][3] / 100
        local score = math.min(raw, math.max(foe.hp, 1)) * acc
        if score > bestScore + 0.01 or (math.abs(score - bestScore) <= 0.01 and me.pp[i] > bestPP) then
          best, bestScore, bestPP = i, score, me.pp[i]
        end
      end
    end
  end
  return best, bestScore
end

-- PP left in damaging moves (outside battle, from the party)
local function usefulPP(mon)
  local total = 0
  for i = 1, 4 do
    local mv = TT_MOVE[mon.moves[i]]
    if mv and not NEVER[mv[4]] and (mv[1] > 1 or mv[4] == EF.LEVEL_DAMAGE or mv[4] == EF.DRAGON_RAGE
       or mv[4] == EF.SONICBOOM or mv[4] == EF.SUPER_FANG or mv[4] == EF.PSYWAVE or mv[4] == EF.HIDDEN_POWER
       or mv[4] == EF.RETURN or mv[4] == EF.FRUSTRATION or mv[4] == EF.FLAIL or mv[4] == EF.ERUPTION
       or mv[4] == EF.LOW_KICK or mv[4] == EF.MAGNITUDE) then
      total = total + mon.pp[i]
    end
  end
  return total
end

-- --------------------- Learning new moves ----------------------
-- Who learns: gBattleStruct->expGetterMonId (party index)
local function learnerIndex()
  local p = read32(A.enemy - 0x44)
  if validPtr(p) then local i = read8(p + 0x10); if i < 6 then return i end end
  return 0
end
local function monAsAttacker(idx)
  local addr = A.party + idx * 0x64
  local m = readPartyMon(addr)
  if not m then return nil end
  local sp = TT_SPEC[m.species] or { 0, 0 }
  return { mon = m, level = m.level, atk = read16(addr + 0x5A), def = read16(addr + 0x5C), spe = read16(addr + 0x5E),
           spa = read16(addr + 0x60), spd = read16(addr + 0x62), type1 = sp[1], type2 = sp[2], ivWord = m.ivWord,
           friendship = m.friendship, hp = m.hp, maxHP = m.maxHP, status = read32(addr + 0x50) }
end
-- Value of a move against a neutral opponent (no type advantage), with STAB and accuracy
local function moveWorth(id, me)
  if id == 0 or not TT_MOVE[id] then return 0 end
  local ref = { type1 = 9, type2 = 9, ability = 0, def = math.max(me.def, 1), spd = math.max(me.spd, 1), hp = math.max(me.maxHP, 1) * 4 }
  return (moveValue(id, me, ref))
end
local function moveName(id) return (TT_MOVE[id] and TT_MOVE[id][7]) or ("#" .. tostring(id)) end
-- Returns (slot to forget 1-4 or nil, new move, move that would be forgotten)
local function planLearn()
  local new = read16(A.moveToLearn)
  local me = monAsAttacker(learnerIndex())
  if not me or not TT_MOVE[new] then return nil, new end
  -- Only the trained Pokemon's moves change (the first in the party)
  if learnerIndex() ~= 0 then return nil, new end
  if tcfg.wanted then
    -- Wanted moves list: learns only those, and forgets one NOT on the list
    if not tcfg.wanted[new] then return nil, new end
    local worst, worstW
    for i = 1, 4 do
      local id = me.mon.moves[i]
      if id ~= 0 and not HM_MOVES[id] and not tcfg.keep[id] and not tcfg.wanted[id] then
        local w = moveWorth(id, me)
        if not worst or w < worstW then worst, worstW = i, w end
      end
    end
    if worst then return worst, new, me.mon.moves[worst] end
    return nil, new
  end
  local newW = moveWorth(new, me)
  if newW <= 0 then return nil, new end
  local worst, worstW
  for i = 1, 4 do
    local id = me.mon.moves[i]
    if id ~= 0 and not HM_MOVES[id] and not tcfg.keep[id] then
      local w = moveWorth(id, me)
      if not worst or w < worstW then worst, worstW = i, w end
    end
  end
  if worst and newW > worstW * 1.1 + 0.5 then return worst, new, me.mon.moves[worst] end
  return nil, new
end

-- Status of each wanted move: already known, level it is learned at, or not by level
local function wantedStatus(m)
  if not tcfg.wanted or not m then return nil end
  local out = {}
  local ls = TT_LEARN[m.species] or {}
  local ids = {}
  for id in pairs(tcfg.wanted) do ids[#ids + 1] = id end
  table.sort(ids)
  for _, id in ipairs(ids) do
    local has = false
    for i = 1, 4 do if m.moves[i] == id then has = true end end
    local txt
    if has then txt = "OK"
    else
      local lv
      for k = 1, #ls, 2 do if ls[k + 1] == id and ls[k] > m.level and not lv then lv = ls[k] end end
      if lv then txt = "Nv." .. lv
      else
        local past
        for k = 1, #ls, 2 do if ls[k + 1] == id then past = ls[k] end end
        txt = past and (TX"ya paso Nv." .. past .. TX": Recordador") or TX"MT/tutor"
      end
    end
    out[#out + 1] = moveName(id) .. " " .. txt
  end
  return table.concat(out, ", ")
end

-- Decides whether fighting a wild Pokemon is worth it. Returns (fight, reason)
local function shouldFight(mon, species)
  if tcfg.mode == "dinero" then return false, TX"solo entrenadores" end
  if tcfg.avoid and tcfg.avoid[species] then return false, TX"evitada" end
  if tcfg.only and not tcfg.only[species] then return false, TX"no esta en la lista" end
  return true, (tcfg.mode == "objetos") and TX"Recogida (hay que ganar)" or TX"experiencia"
end

-- Steal: returns the move slot (1-4) or nil, and the reason
local function stealPlan(foe)
  if foe.item == 0 then return nil, TX"no lleva objeto" end
  if tcfg.wantedItems and not tcfg.wantedItems[foe.item] then return nil, TX"lleva " .. itemName(foe.item) .. TX" (no lo quieres)" end
  if battleItem(0) ~= 0 then return nil, TX"tu Pokemon ya lleva un objeto" end
  local bm = battleMon(0)
  for k = 1, 4 do
    if (bm.moves[k] == K.MOVE_THIEF or bm.moves[k] == K.MOVE_COVET) and bm.pp[k] > 0 then return k, TX"robar " .. itemName(foe.item) end
  end
  return nil, TX"sin PP de Ladron/Antojo"
end

-- ------------------------------ Estado -------------------------------
local bot = { running = false, st = "idle", t = 0, panel = 1, msg = "",
  battles = 0, fought = 0, fled = 0, heals = 0, lastFoe = nil, lastWhy = "" }
local queue = {}
local function push(buttons, frames) queue[#queue + 1] = { b = buttons, n = frames } end
local function wait(frames) if frames > 0 then push(nil, frames) end end
local function tap(btn, after) push({ [btn] = true }, 2); wait(after or 6) end
local function runQueue()
  local item = queue[1]
  if not item then return false end
  if item.b then joypad.set(1, item.b) end
  item.n = item.n - 1
  if item.n <= 0 then table.remove(queue, 1) end
  return true
end
local function hold(dir) joypad.set(1, { [dir] = true }) end

-- ------------------------- Route to the Center ----------------------------
local route = { go = nil, back = nil }             -- to the Center (key 6)
local troute = { go = nil, back = nil }            -- through the trainers' lines of sight (key 5)
local rec = nil      -- recording in progress

local function routeToText(r)
  local t = {}
  for _, p in ipairs(r) do t[#t + 1] = string.format("%d %d %d %d %d", p.g, p.n, p.x, p.y, p.d or 0) end
  return table.concat(t, ";")
end
local function routeFromText(s)
  local r = {}
  for g, n, x, y, d in s:gmatch("(%-?%d+) (%-?%d+) (%-?%d+) (%-?%d+) (%-?%d+)") do
    r[#r + 1] = { g = tonumber(g), n = tonumber(n), x = tonumber(x), y = tonumber(y), d = tonumber(d) }
  end
  return #r > 0 and r or nil
end
local function saveRoute()
  pcall(function()
    local f = io.open(SCRIPT_DIR .. CONFIG.routeFile, "w")
    if f then
      f:write("GO " .. routeToText(route.go) .. "\n")
      f:write("BACK " .. routeToText(route.back) .. "\n")
      f:close()
    end
  end)
end
-- Route cleanup: when going through a door the game changes the map a few frames
-- before the coordinates (and the map memory moves), so bogus points were
-- left: new map with the old coordinates, or impossible maps.
local function cleanRoute(r)
  if not r then return nil end
  local out = {}
  for _, q in ipairs(r) do
    local last = out[#out]
    local junk = q.g > 42 or q.n > 120
    if last and not junk then
      if samePos(q, last) then junk = true
      elseif (q.g ~= last.g or q.n ~= last.n) and q.x == last.x and q.y == last.y then junk = true end
    end
    if not junk then out[#out + 1] = q end
  end
  return out
end

-- If the way there ended OUTSIDE the Center and the walk to the nurse was recorded
-- at the start of the way back, that stretch is moved to the way there (up to the
-- innermost point, which is where you talk to the nurse).
local function fixRoute(go, back)
  if not go or not back or #go < 2 or #back < 2 then return go, back end
  -- Tile mode: if the way back starts with a "detour" that returns to the same
  -- point (you entered the healing zone AFTER pressing 6), that detour goes to the way there.
  if simplify(CONFIG.healMode or "nurse") == "tile" then
    local k
    for j = 2, math.min(#back, 40) do if samePos(back[j], back[1]) then k = j; break end end
    if k then
      local best, bestD = 1, -1
      for j = 1, k do
        local d = math.abs(back[j].x - back[1].x) + math.abs(back[j].y - back[1].y)
        if back[j].g == back[1].g and back[j].n == back[1].n and d > bestD then best, bestD = j, d end
      end
      local ng, nb = {}, {}
      for _, q in ipairs(go) do ng[#ng + 1] = q end
      for j = 2, best do ng[#ng + 1] = back[j] end
      for j = best, #back do nb[#nb + 1] = back[j] end
      nb[1] = { g = nb[1].g, n = nb[1].n, x = nb[1].x, y = nb[1].y, d = 0 }
      go, back = cleanRoute(ng), cleanRoute(nb)
    end
  end
  local goMaps = {}
  for _, q in ipairs(go) do goMaps[q.g * 256 + q.n] = true end
  local first, lastIn = nil, nil
  for k = 2, #back do
    local key = back[k].g * 256 + back[k].n
    if not goMaps[key] then first = first or k; lastIn = k
    elseif first then break end
  end
  if not first then return go, back end
  -- point farthest from the entrance within that stretch
  local e = back[first]
  local best, bestD = first, -1
  for k = first, lastIn do
    local d = math.abs(back[k].x - e.x) + math.abs(back[k].y - e.y)
    if back[k].g == e.g and back[k].n == e.n and d > bestD then best, bestD = k, d end
  end
  local ng, nb = {}, {}
  for _, q in ipairs(go) do ng[#ng + 1] = q end
  for k = 2, best do ng[#ng + 1] = back[k] end
  for k = best, #back do nb[#nb + 1] = back[k] end
  nb[1] = { g = nb[1].g, n = nb[1].n, x = nb[1].x, y = nb[1].y, d = 0 }
  return ng, nb
end

local function loadRoute()
  route.go, route.back = nil, nil
  pcall(function()
    local f = io.open(SCRIPT_DIR .. CONFIG.routeFile, "r")
    if not f then return end
    local data = f:read("*a"); f:close()
    route.go = routeFromText(data:match("GO ([^\n]*)") or "")
    route.back = routeFromText(data:match("BACK ([^\n]*)") or "")
  end)
  if not (route.go and route.back) then route.go, route.back = nil, nil; return end
  local g0, b0 = #route.go, #route.back
  route.go, route.back = cleanRoute(route.go), cleanRoute(route.back)
  route.go, route.back = fixRoute(route.go, route.back)
  if #route.go ~= g0 or #route.back ~= b0 then
    print(string.format(TX"Ruta corregida: ida %d -> %d pasos, vuelta %d -> %d", g0, #route.go, b0, #route.back))
    saveRoute()
  end
end
loadRoute()

local function saveTrainerRoute()
  pcall(function()
    local f = io.open(SCRIPT_DIR .. CONFIG.trainerRouteFile, "w")
    if f then
      f:write("GO " .. routeToText(troute.go) .. "\n")
      f:write("BACK " .. routeToText(troute.back) .. "\n")
      f:close()
    end
  end)
end
local function loadTrainerRoute()
  troute.go, troute.back = nil, nil
  pcall(function()
    local f = io.open(SCRIPT_DIR .. CONFIG.trainerRouteFile, "r")
    if not f then return end
    local data = f:read("*a"); f:close()
    troute.go = cleanRoute(routeFromText(data:match("GO ([^\n]*)") or ""))
    troute.back = cleanRoute(routeFromText(data:match("BACK ([^\n]*)") or ""))
  end)
  if not (troute.go and troute.back and #troute.go > 1 and #troute.back > 1) then troute.go, troute.back = nil, nil end
end
loadTrainerRoute()

local function recStep()
  if not rec then return end
  local p = playerPos()
  if not p then return end
  local list = rec.list
  local last = list[#list]
  local junk = p.g > 42 or p.n > 120
  -- new map with the old coordinates = halfway through a door: wait
  if last and (p.g ~= last.g or p.n ~= last.n) and p.x == last.x and p.y == last.y then junk = true end
  if not junk and not samePos(p, last) then
    list[#list + 1] = { g = p.g, n = p.n, x = p.x, y = p.y, d = rec.prevFace or p.face }
  end
  if not junk then rec.prevFace = p.face end
end

-- kind = "heal" (key 6, to the Center) or "trainer" (key 5, past the trainers)
local REC_TEXT = {  --@i18n
  heal = { "GRABANDO IDA: camina hasta quedar frente a la enfermera y pulsa 6",  --@i18n
           "GRABANDO VUELTA: cura (si quieres) y vuelve al punto de inicio; pulsa 6", "6" },  --@i18n
  trainer = { "GRABANDO RUTA: pasa por donde te ven los entrenadores y pulsa 5 al final",  --@i18n
              "GRABANDO VUELTA: vuelve al punto de inicio (donde usas el Buscapelea) y pulsa 5", "5" },  --@i18n
}
local function recHotkey(kind)
  if bot.running then bot.msg = TX"Deten el bot (7) antes de grabar una ruta"; return end
  local p = playerPos()
  if not p then bot.msg = TX"Carga tu partida antes de grabar"; return end
  if rec and rec.kind ~= kind then bot.msg = TX"Termina primero la ruta que estas grabando (tecla " .. REC_TEXT[rec.kind][3] .. ")"; return end
  local txt = REC_TEXT[kind]
  if not rec then
    rec = { kind = kind, phase = "go", list = { { g = p.g, n = p.n, x = p.x, y = p.y, d = 0 } }, prevFace = p.face }
    bot.msg = TX(txt[1])
  elseif rec.phase == "go" then
    if #rec.list < 2 then bot.msg = TX"Aun no te has movido"; return end
    rec.go = rec.list
    rec.phase = "back"
    rec.list = { { g = p.g, n = p.n, x = p.x, y = p.y, d = 0 } }
    bot.msg = TX(txt[2])
  else
    if #rec.list < 2 then bot.msg = TX"Aun no te has movido: vuelve al punto de inicio"; return end
    if kind == "heal" then
      route.go, route.back = fixRoute(cleanRoute(rec.go), cleanRoute(rec.list))
      saveRoute()
      bot.msg = string.format(TX"Ruta al Centro guardada (%d pasos ida, %d vuelta)", #route.go, #route.back)
    else
      troute.go, troute.back = cleanRoute(rec.go), cleanRoute(rec.list)
      saveTrainerRoute()
      bot.msg = string.format(TX"Ruta de entrenadores guardada (%d pasos ida, %d vuelta)", #troute.go, #troute.back)
    end
    rec = nil
  end
  print(bot.msg)
end

-- Follow a recorded route. Returns "done", "fail" or nil (keep going).
local nav = nil
local function navStart(r) nav = { r = r, idx = 1, stuck = 0, tries = 0, cool = 0, lastMap = nil } end
local function navFind(p)
  local r = nav.r
  for j = nav.idx, #r do if samePos(p, r[j]) then return j end end
  for j = 1, nav.idx - 1 do if samePos(p, r[j]) then return j end end
  return nil
end
local function navStep()
  local p = playerPos()
  if not p then nav.cool = 20; return nil end
  local mapKey = p.g * 256 + p.n
  if nav.lastMap and nav.lastMap ~= mapKey then nav.cool = 40 end   -- map change: release for a moment
  nav.lastMap = mapKey
  if nav.cool > 0 then nav.cool = nav.cool - 1; return nil end
  local r = nav.r
  local j = navFind(p)
  local nxt
  if j then
    if j ~= nav.idx then nav.idx = j; nav.stuck = 0 end
    if nav.idx >= #r then return "done" end
    nxt = r[nav.idx + 1]
  else
    -- off the route (pushed by an NPC, etc.): look for a nearby route point
    for k = nav.idx, #r do
      local q = r[k]
      if q.g == p.g and q.n == p.n and math.abs(q.x - p.x) + math.abs(q.y - p.y) == 1 then nxt = q; nav.idx = math.max(k - 1, 1); break end
    end
    if not nxt then
      nav.stuck = nav.stuck + 1
      if nav.stuck > 300 then return "fail" end
      return nil
    end
  end
  local cur = j and r[nav.idx] or p
  local dir
  if nxt.g == cur.g and nxt.n == cur.n and math.abs(nxt.x - cur.x) + math.abs(nxt.y - cur.y) == 1 then
    if nxt.x > cur.x then dir = "right" elseif nxt.x < cur.x then dir = "left"
    elseif nxt.y > cur.y then dir = "down" else dir = "up" end
  else
    dir = DIR_KEY[nxt.d] or "up"      -- map change (door): the direction used when entering
  end
  nav.stuck = nav.stuck + 1
  if nav.stuck > 120 then
    -- stuck (NPC in the way or a sign open): release, close text and retry
    nav.stuck, nav.tries = 0, nav.tries + 1
    if nav.tries > 12 then return "fail" end
    tap("B", 20)
    return nil
  end
  hold(dir)
  return nil
end

-- ------------------------------ Control ------------------------------
local stopBot
-- Stop with a message: shown, written to the log and sent to the phone
local function halt(msg)
  stopBot()
  bot.msg = msg
  logLine(msg)
  notify(msg)
  pcall(emu.pause)            -- pause so you see it
end
local function leadOk()
  local m = lead()
  if not m then return nil end
  return m
end

local function needHeal(m)
  if m.hp == 0 then return TX"debilitado" end
  if m.maxHP > 0 and m.hp * 100 < m.maxHP * CONFIG.healBelow then return TX"PS bajos" end
  if usefulPP(m) < CONFIG.minPP then return TX"sin PP" end
  return nil
end

-- Really healed: full HP, no status condition and every move at full PP
-- (before, only HP was checked and, if it went to the Center for lack of PP, it left without talking)
local function partyHealed()
  local n = partyCount()
  if n == 0 then return false end
  for i = 0, n - 1 do
    local a = A.party + i * 0x64
    local mx = read16(a + 0x58)
    if read32(a) ~= 0 and mx > 0 then
      if read16(a + 0x56) < mx then return false end
      if read32(a + 0x50) ~= 0 then return false end
      local m = readPartyMon(a)
      if m then
        for k = 1, 4 do
          local d = TT_MOVE[m.moves[k]]
          if d then
            local maxPP = floor(d[5] * (5 + band(rshift(m.ppBonuses, (k - 1) * 2), 3)) / 5)
            if m.pp[k] < maxPP then return false end
          end
        end
      end
    end
  end
  return true
end

local function inOverworld()
  return not inBattle() and bot.cbOW and read32(A.callback2) == bot.cbOW
end

local function startWalk()
  queue = {}; zeroEnemy()
  bot.st, bot.t = "walk", 0
end

local function beginHeal(reason)
  if not route.go then
    halt(TX"Necesita curarse (" .. reason .. TX"): cura, vuelve al punto y pulsa 7. (Graba la ruta con 6)")
    return
  end
  bot.heals = bot.heals + 1
  logLine(TX"Al Centro Pokemon: " .. reason)
  queue = {}
  zeroEnemy()
  navStart(route.go)
  bot.st, bot.t = "heal_go", 0
end

-- Goal reached? Returns the summary text or nil
local function farmDone(m)
  if CONFIG.maxBattles and bot.battles >= CONFIG.maxBattles then return string.format(TX"%d combates", bot.battles) end
  if tcfg.mode == "nivel" and CONFIG.targetLevel and m.level >= CONFIG.targetLevel then
    return string.format(TX"%s llego al Nv.%d", speciesName(m.species), m.level)
  end
  if (tcfg.mode == "objetos" or tcfg.mode == "robar") and CONFIG.itemTarget and bot.items >= CONFIG.itemTarget then
    return string.format(TX"%d objetos guardados en la mochila", bot.items)
  end
  if tcfg.mode == "dinero" and CONFIG.moneyTarget then
    local mn = money()
    if mn and mn >= CONFIG.moneyTarget then return string.format(TX"$%d (ganado +%d)", mn, bot.earned) end
  end
  return nil
end

local function completeFarm(why)
  stopBot()
  bot.done = true
  bot.msg = TX"FARMEO COMPLETO: " .. why
  logLine(bot.msg)
  notify(bot.msg)
  emu.pause()
end

local function trackMoney()
  local mn = money()
  if mn and bot.lastMoney and mn > bot.lastMoney then
    bot.earned = bot.earned + (mn - bot.lastMoney)
    logLine(string.format(TX"+$%d  (total $%d)", mn - bot.lastMoney, mn))
  end
  if mn then bot.lastMoney = mn end
end

-- Items in the party: records the new ones and counts as stored the ones that are gone.
-- Returns the list of the ones to take.
local function itemSlots() return (tcfg.mode == "objetos") and bot.pickSlots or { 0 } end
local function scanItems()
  local held = holdingSlots(itemSlots())
  local now = {}
  for _, h in ipairs(held) do now[h.slot] = h.item end
  for slot, item in pairs(bot.seenHeld) do
    if not now[slot] then
      bot.items = bot.items + 1
      logLine(string.format(TX"Guardado en la mochila: %s (tienes %d)", itemName(item), bagCount(item)))
      bot.seenHeld[slot] = nil
    end
  end
  for _, h in ipairs(held) do
    if not bot.seenHeld[h.slot] then
      bot.seenHeld[h.slot] = h.item
      bot.found = bot.found + 1
      bot.lastItem = itemName(h.item)
      local who = partyMon(h.slot)
      logLine(string.format(TX"%s consiguio %s", who and speciesName(who.species) or "?", itemName(h.item)))
    end
  end
  return held
end

local beginTake, beginTrainerLoop

-- After a battle (or on start): decide what comes next
local function afterBattleDecide()
  local m = leadOk()
  if not m then halt(TX"No se pudo leer el Pokemon del equipo"); return end
  if m.species ~= bot.leadSpecies then
    logLine(string.format(TX"%s evoluciono a %s", speciesName(bot.leadSpecies), speciesName(m.species)))
    bot.leadSpecies = m.species
  end
  if bot.lastLevel and m.level > bot.lastLevel then
    logLine(string.format(TX"%s subio al Nv.%d", speciesName(m.species), m.level))
  end
  bot.lastLevel = m.level
  if tcfg.mode == "dinero" then trackMoney() end
  if tcfg.mode == "objetos" or tcfg.mode == "robar" then
    local held = scanItems()
    local slots = itemSlots()
    local full = #held > 0 and (tcfg.mode == "robar" or #held >= #slots
      or (CONFIG.itemTarget and bot.items + #held >= CONFIG.itemTarget))
    if full then beginTake(held); return end
  end
  local done = farmDone(m)
  if done then completeFarm(done); return end
  local why = needHeal(m)
  if why then beginHeal(why); return end
  -- If it is not at the starting point (e.g. it lost and woke up at the Center)
  local p = playerPos()
  if bot.spot and p and not (p.g == bot.spot.g and p.n == bot.spot.n and math.abs(p.x - bot.spot.x) <= 2
     and math.abs(p.y - bot.spot.y) <= 2) then
    if route.back then
      for k = 1, #route.back do
        if samePos(p, route.back[k]) then navStart(route.back); nav.idx = k; bot.st, bot.t = "heal_back", 0; return end
      end
    end
    halt(TX"El personaje no esta en el punto de inicio: llevalo alli y pulsa 7")
    return
  end
  if tcfg.mode == "dinero" then beginTrainerLoop(); return end
  startWalk()
end

-- Only one Train Bot at a time: if another Lua window was left running (for example
-- an old version), both would press buttons at the same time.
local MY_TOKEN = string.format("%d%d", math.random(100000, 999999), math.random(100000, 999999))
local LOCK_FILE = "farm_running.lock"
local TRAIN_LOCK = "train_running.lock"   -- the Train Bot also presses buttons: don't run both at once
local lastLockWrite = -1
local function nowSec() local t = 0; pcall(function() t = os.time() end); return t end
local function lockAlive(name)
  local data
  pcall(function() local f = io.open(LOGDIR .. name, "r"); if f then data = f:read("*a"); f:close() end end)
  if not data then return false end
  local t, tok = data:match("(%d+)%s+(%d+)")
  t = tonumber(t)
  return tok ~= nil and tok ~= MY_TOKEN and t ~= nil and nowSec() - t <= 5
end
local function otherInstanceAlive() return lockAlive(LOCK_FILE) or lockAlive(TRAIN_LOCK) end
local function writeLock()
  local t = nowSec()
  if t == lastLockWrite then return end
  lastLockWrite = t
  pcall(function() local f = io.open(LOGDIR .. LOCK_FILE, "w"); if f then f:write(t .. " " .. MY_TOKEN); f:close() end end)
end

local function startBot()
  if otherInstanceAlive() then
    bot.msg = TX"Hay otro Farm Bot o un Train Bot corriendo en otra ventana de Lua: detenlo/cierralo primero"
    print(bot.msg); return
  end
  if bot.cfgError then bot.msg = TX"Corrige " .. CONFIG_FILE .. TX" (mira la consola) y pulsa 0"; print(bot.msg); return end
  if rec then bot.msg = TX"Termina de grabar la ruta antes de iniciar"; return end
  if inBattle() then bot.msg = TX"Inicia el bot fuera de combate"; return end
  local m = leadOk()
  local p = playerPos()
  if not m or not p then bot.msg = TX"Carga tu partida (en el mapa) antes de iniciar"; print(bot.msg); return end
  local mode = tcfg.mode
  if mode == "objetos" then
    bot.pickSlots = pickupSlots()
    if #bot.pickSlots == 0 then bot.msg = TX"Ningun Pokemon del equipo tiene la habilidad Recogida (Pickup)"; print(bot.msg); return end
  elseif mode == "robar" then
    local has = false
    for k = 1, 4 do if m.moves[k] == K.MOVE_THIEF or m.moves[k] == K.MOVE_COVET then has = true end end
    if not has then bot.msg = TX"El primero del equipo necesita Ladron (Thief) o Antojo (Covet)"; print(bot.msg); return end
  elseif mode == "dinero" then
    if not troute.go then bot.msg = TX"Graba la ruta de los entrenadores con la tecla 5"; print(bot.msg); return end
    if registeredItem() ~= K.ITEM_VS_SEEKER then bot.msg = TX"Registra el Buscapelea en SELECT (mochila > Buscapelea > Registrar)"; print(bot.msg); return end
  end
  if (mode == "objetos" or mode == "robar") and (tcfg.take == "pause" or not MENU) and not bot.warnedTake then
    print(TX"Aviso: en esta version el bot no quita los objetos solo; pausara para que lo hagas tu")
    bot.warnedTake = true
  end
  bot.cbOW = read32(A.callback2)
  bot.leadSpecies = m.species
  if mode == "dinero" then bot.spot = troute.back[#troute.back]
  else bot.spot = route.back and route.back[#route.back] or p end
  bot.running, bot.done, bot.msg = true, false, ""
  bot.battles, bot.fought, bot.fled, bot.heals = 0, 0, 0, 0
  bot.items, bot.found, bot.steals, bot.trainers, bot.laps, bot.earned = 0, 0, 0, 0, 0, 0
  bot.seenHeld, bot.lastItem, bot.healAfter, bot.take = {}, nil, nil, nil
  bot.lastMoney, bot.startMoney = money(), money()
  bot.lastLevel = m.level
  bot.startTime = 0
  pcall(function() bot.startTime = os.time() end)
  bot.startLevel = m.level
  logLine(string.format(TX"Farmeo iniciado (modo %s): %s Nv.%d", mode, speciesName(m.species), m.level))
  -- Items they were already holding are not counted as found
  if mode == "objetos" or mode == "robar" then
    for _, h in ipairs(holdingSlots(itemSlots())) do bot.seenHeld[h.slot] = h.item end
  end
  local ws = wantedStatus(m)
  if ws then logLine(TX"Ataques deseados: " .. ws) end
  afterBattleDecide()
end

stopBot = function()
  bot.running, bot.st = false, "idle"
  queue = {}
end

-- ------------------------------ Battle ------------------------------
local function enterBattle(returnTo)
  queue = {}
  bot.st, bot.t = "battle", 0
  bot.foe, bot.fight, bot.forceRun = nil, nil, (returnTo ~= nil)
  bot.returnTo = returnTo
  bot.blocked, bot.lastMoveSlot, bot.sawMove = {}, nil, false
  bot.outT = 0
  bot.battles = bot.battles + 1
end

-- Double battles (trainers only): both of your Pokemon attack. The game asks battler 0 and
-- then battler 2, each with its own command buffer (gBattleBufferA, 0x200 per battler),
-- waiting bit in gBattleControllerExecFlags and cursors. After a single-target move it asks
-- for the target with the same CHOOSEMOVE command: A confirms the default foe.
local function stepDouble()
  local D = bot.dbl
  local flags, who, cmd = read32(A.execFlags), nil, nil
  for i, bitv in pairs({ [0] = 1, [2] = 4 }) do       -- battler -> its waiting bit
    local c = read8(A.bufferA + i * 0x200)
    if band(flags, bitv) ~= 0 and (c == CMD_CHOOSEACTION or c == CMD_CHOOSEMOVE) and (not who or i < who) then who, cmd = i, c end
  end
  if not who then tap("B", 10); return end      -- battle texts
  if cmd == CMD_CHOOSEACTION then
    bot.cbBattle = read32(A.callback2)
    D.picked, D.confirmed = nil, nil
    local c = band(read8(A.actionCursor + who), 3)   -- always FIGHT: trainers can't be fled
    if c == 0 then tap("A", 16) elseif band(c, 1) == 1 then tap("left", 4) else tap("up", 4) end
    return
  end
  if D.picked == who then
    if D.confirmed ~= who then tap("A", 16); D.confirmed = who; return end   -- target screen
    D.blocked[who][D.slot] = true                       -- asked again: that move could not be used
    D.picked, D.confirmed = nil, nil
  end
  local foe = (battleMon(1).hp > 0) and 1 or 3
  local slot = bestMove(D.blocked[who], who, foe)
  if not slot then halt(TX"Sin ataques utiles contra un entrenador: terminalo tu"); return end
  local want, c = slot - 1, band(read8(A.moveCursor + who), 3)
  if c == want then tap("A", 20); D.picked, D.slot, D.confirmed = who, slot, nil
  elseif band(c, 1) ~= band(want, 1) then tap(band(want, 1) == 1 and "right" or "left", 4)
  else tap(band(want, 2) == 2 and "down" or "up", 4) end
end

local function stepBattle()
  bot.t = bot.t + 1
  local ib = inBattle()
  if not ib then
    bot.outT = bot.outT + 1
    if bot.outT > 10 then queue = {}; bot.st, bot.t, bot.owT = "after", 0, 0 end
    return
  end
  bot.outT = 0

  if not bot.foe then
    local foe = readEnemyStable()
    if foe then
      bot.foe = foe
      bot.lastFoe = foe
      if foe.sv < 8 and CONFIG.stopOnShiny and band(read32(A.battleType), K.BT_TRAINER) == 0 then
        stopBot()
        bot.msg = TX"SHINY SALVAJE: " .. speciesName(foe.species) .. TX"! Capturalo tu (juego en pausa)"
        logLine(bot.msg)
        notify(bot.msg)
        emu.pause()
        return
      end
      local m = lead()
      local bt = read32(A.battleType)
      bot.trainer = band(bt, K.BT_TRAINER) ~= 0
      bot.steal = nil
      bot.double = bot.trainer and band(bt, K.BT_DOUBLE) ~= 0
      bot.dbl = bot.double and { blocked = { [0] = {}, [2] = {} } } or nil
      if bot.trainer then
        bot.fight, bot.forceRun, bot.lastWhy = true, false, TX"entrenador (no se puede huir)"
        bot.trainers = (bot.trainers or 0) + 1
      elseif bot.forceRun then bot.fight, bot.lastWhy = false, TX"de camino"
      elseif tcfg.mode == "robar" then
        local slot, why = stealPlan(foe)
        bot.lastWhy = why
        if slot then bot.fight, bot.steal = true, { slot = slot, tries = 0, item = foe.item }
        else bot.fight = false end
      elseif m then bot.fight, bot.lastWhy = shouldFight(m, foe.species) end
      if bot.fight then bot.fought = bot.fought + 1 else bot.fled = bot.fled + 1 end
    end
  end
  if #queue > 0 then return end

  if bot.trainer and (battleMon(0).hp == 0 or (bot.double and battleMon(2).hp == 0)) then
    halt(TX"Tu Pokemon se debilito contra un entrenador: elige tu el siguiente y termina el combate")
    return
  end

  -- Evolution scene: the game shows it with gMain.inBattle still set,
  -- but on another screen (callback2 differs from the battle one). Before, this
  -- kept pressing B for the texts and that cancelled the evolution.
  if bot.cbBattle and read32(A.callback2) ~= bot.cbBattle then
    bot.evoT = (bot.evoT or 0) + 1
    if CONFIG.evolve then
      local m = lead()
      if m and m.species ~= bot.leadSpecies then
        logLine(string.format(TX"%s esta evolucionando a %s", speciesName(bot.leadSpecies), speciesName(m.species)))
        bot.st, bot.manualFrom, bot.owT = "manual", "evolve", 0
        bot.msg = TX"Evoluciono: termina tu la escena (textos / ataque nuevo). El bot sigue solo despues"
        notify(TX"Tu Pokemon evoluciono a " .. speciesName(m.species) .. TX": termina la escena y el bot sigue solo")
        print(bot.msg)
        pcall(emu.pause)        -- pause: unpause, finish the scene and the bot carries on by itself
        return
      end
      -- The animation advances by itself; only if it stays on a text for a long time, press A
      if bot.evoT > 1800 and bot.evoT % 60 == 0 then tap("A", 10) end
    else
      tap("B", 6)                                       -- holding B cancels the evolution
    end
    return
  end
  bot.evoT = 0

  -- "Learn move" prompts
  local sp = read32(A.scriptPtr)
  local op = (sp >= 0x08000000 and sp < 0x0A000000) and read8(sp) or 0
  if op == OP_LEARNMOVE or op == OP_STOPLEARNING then
    local mode = bot.learnForce or tcfg.learn
    if mode == "ask" then
      local slot, new, old = planLearn()
      local idx = learnerIndex()
      local who = monAsAttacker(idx)
      bot.st, bot.manualFrom, bot.t = "manual", "learn", 0
      bot.msg = string.format(TX"%s quiere aprender %s: decide tu", who and speciesName(who.mon.species) or "?", moveName(new))
      notify(bot.msg .. (slot and (TX" (el bot olvidaria " .. moveName(old) .. ")") or TX" (el bot no lo aprenderia)"))
      return
    end
    if op == OP_LEARNMOVE then
      local slot, new, old = nil, nil, nil
      if mode == "auto" then slot, new, old = planLearn() end
      if slot then
        -- "Forget a move to learn X?" -> YES, then pick which one on the summary screen
        if read8(A.yesNoCursor) ~= 0 then tap("up", 6)
        else
          tap("A", 12)
          bot.learn = { slot = slot, new = new, old = old }
          bot.st, bot.t, bot.sumSeen, bot.probe, bot.picked = "learn_pick", 0, false, false, false
        end
      else
        tap("B", 12)                                    -- -> NO
      end
    else
      if read8(A.yesNoCursor) ~= 0 then tap("up", 6) else tap("A", 12) end  -- "Stop learning?" -> YES
    end
    return
  end
  bot.learnForce = nil

  if bot.double then stepDouble(); return end
  local waiting = band(read32(A.execFlags), 1) ~= 0
  local cmd = read8(A.bufferA)
  if waiting and cmd == CMD_CHOOSEACTION then
    bot.cbBattle = read32(A.callback2)
    if not bot.foe then tap("B", 6); return end
    bot.sawMove = false
    local me = battleMon(0)
    -- Steal done (or too many attempts): run with the item
    if bot.steal and not bot.steal.done then
      if battleItem(0) ~= 0 then
        bot.steal.done = true; bot.fight = false; bot.lastWhy = TX"robado: " .. itemName(battleItem(0))
        bot.steals = (bot.steals or 0) + 1
      elseif bot.steal.tries >= 3 then
        bot.steal.done = true; bot.fight = false; bot.lastWhy = TX"no se pudo robar"
      end
    end
    local run = not bot.fight or bot.forceRun
    if bot.trainer then run = false
    elseif not run and me.maxHP > 0 and me.hp * 100 < me.maxHP * CONFIG.fleeBelow then run = true; bot.lastWhy = TX"PS muy bajos" end
    if not run and not bestMove(bot.blocked) and not (bot.steal and not bot.steal.done) then
      if bot.trainer then halt(TX"Sin ataques utiles contra un entrenador: terminalo tu"); return end
      run = true; bot.lastWhy = TX"sin ataques utiles"
    end
    local want = run and 3 or 0
    local c = band(read8(A.actionCursor), 3)
    if c == want then tap("A", 16)
    elseif band(c, 1) ~= band(want, 1) then tap(band(want, 1) == 1 and "right" or "left", 4)
    else tap(band(want, 2) == 2 and "down" or "up", 4) end
    return
  end
  if waiting and cmd == CMD_CHOOSEMOVE then
    if bot.sawMove and bot.lastMoveSlot then
      -- it asked for a move again without going through the menu: that move could not be used
      bot.blocked[bot.lastMoveSlot] = true
    end
    local slot = bestMove(bot.blocked)
    if bot.steal and not bot.steal.done and not bot.blocked[bot.steal.slot] then slot = bot.steal.slot end
    if not slot then
      if bot.trainer then halt(TX"Sin ataques utiles contra un entrenador: terminalo tu"); return end
      tap("B", 10); bot.forceRun = true; return
    end
    local want = slot - 1
    local c = band(read8(A.moveCursor), 3)
    if c == want then
      tap("A", 20); bot.lastMoveSlot, bot.sawMove = slot, true
      if bot.steal and slot == bot.steal.slot and not bot.steal.done then bot.steal.tries = bot.steal.tries + 1 end
    elseif band(c, 1) ~= band(want, 1) then tap(band(want, 1) == 1 and "right" or "left", 4)
    else tap(band(want, 2) == 2 and "down" or "up", 4) end
    return
  end
  -- Battle texts: B (never picks YES by mistake nor enters menus)
  tap("B", 10)
end

local function stepAfter()
  bot.t = bot.t + 1
  if inBattle() then enterBattle(bot.returnTo); return end
  local m = lead()
  if CONFIG.evolve and m and m.species ~= bot.leadSpecies then
    bot.st, bot.manualFrom = "manual", "evolve"
    bot.msg = TX"Esta evolucionando: termina tu (ataques nuevos, textos). El bot sigue solo despues"
    pcall(emu.pause)
    notify(TX"Tu Pokemon esta evolucionando: termina la escena y el bot sigue solo")
    return
  end
  if inOverworld() then bot.owT = bot.owT + 1 else bot.owT = 0 end
  if bot.owT >= 40 then
    queue = {}
    zeroEnemy()
    if bot.returnTo then
      local r = bot.returnTo
      bot.returnTo = nil
      local m2 = lead()
      if r == "heal_back" and m2 and needHeal(m2) then beginHeal(needHeal(m2)); return end
      if tcfg.mode == "dinero" and m2 then
        trackMoney()
        local d = farmDone(m2)
        if d then completeFarm(d); return end
        if needHeal(m2) and (r == "tr_go" or r == "tr_back" or r == "tr_charge") then bot.healAfter = needHeal(m2) end
      end
      bot.st, bot.t = r, 0
      if r == "heal_go" then
        -- resume from where it stopped
      end
      return
    end
    afterBattleDecide()
    return
  end
  -- Off the map (texts, evolution): B cancels the evolution and advances texts.
  -- On the map A is not pressed (it could talk to someone or read a sign).
  if #queue == 0 and not inOverworld() then
    if CONFIG.evolve then tap("A", 10) else tap("B", 6) end
  end
  if bot.t > 5400 then halt(TX"Aviso: no se pudo volver al mapa tras el combate") end
end

local function stepManual()
  -- The player decides; the bot waits for the map to come back or the prompt to end
  if bot.manualFrom == "learn" then
    bot.t = bot.t + 1
    local sp = read32(A.scriptPtr)
    local op = (sp >= 0x08000000 and sp < 0x0A000000) and read8(sp) or 0
    if inBattle() and op ~= OP_LEARNMOVE and op ~= OP_STOPLEARNING then
      bot.msg = ""; bot.st = "battle"; return
    end
    -- Nobody answered: decide alone (only if still on the prompt, not on the summary screen)
    local onPrompt = not bot.cbBattle or read32(A.callback2) == bot.cbBattle
    if CONFIG.askTimeout and bot.t > CONFIG.askTimeout * 60 and onPrompt and inBattle() then
      bot.learnForce = "auto"
      logLine(TX"Sin respuesta: el bot decide solo si aprende el ataque")
      bot.msg = ""; bot.st = "battle"; return
    end
    if not inBattle() then bot.msg = ""; bot.st, bot.t, bot.owT = "after", 0, 0 end
    return
  end
  if inOverworld() then bot.owT = (bot.owT or 0) + 1 else bot.owT = 0 end
  if bot.owT >= 60 then
    local m = lead()
    if m then bot.leadSpecies = m.species end
    bot.msg = ""
    bot.st, bot.t, bot.owT = "after", 0, 0
  end
end

-- Summary screen: pick the move to forget
local function stepLearnPick()
  bot.t = bot.t + 1
  if #queue > 0 then return end
  local inSummary = bot.cbBattle and read32(A.callback2) ~= bot.cbBattle
  local L = bot.learn
  if not bot.sumSeen then
    if inSummary then bot.sumSeen = true; bot.t = 0
    elseif bot.t > 90 then bot.st = "battle" end    -- the A did not register: try again
    return
  end
  if not inSummary then
    local who = monAsAttacker(learnerIndex())
    if who and L and who.mon.moves[L.slot] == L.new then
      logLine(string.format(TX"%s aprendio %s (olvido %s)", speciesName(who.mon.species), moveName(L.new), moveName(L.old)))
    end
    bot.st, bot.t = "battle", 0
    return
  end
  if bot.picked or bot.t < 60 then return end        -- wait for the fade and the cry
  local c = read8(A.sumCursor)
  local function abort(why)
    tap("B", 30); bot.picked = true; bot.learnForce = "never"
    logLine(TX"No se aprendio " .. moveName(L.new) .. ": " .. why .. TX" (usa \"learnMoves\": \"ask\")")
    notify(TX"No se pudo elegir el ataque a olvidar: " .. why)
  end
  if not bot.probe then
    -- check that the cursor direction is right: down must go from 0 to 1
    if c == 1 then bot.probe = true
    elseif bot.t > 400 then abort(TX"el cursor no responde")
    elseif c == 0 then tap("down", 20)
    else abort(TX"cursor inesperado") end
    return
  end
  local want = L.slot - 1
  if c == want then tap("A", 30); bot.picked = true
  elseif bot.t > 1200 then abort(TX"tiempo agotado")
  elseif c < want then tap("down", 14) else tap("up", 14) end
end

local walkToggle = false
local function stepWalk()
  bot.t = bot.t + 1
  if inBattle() then enterBattle(nil); return end
  if #queue == 0 then
    local d1, d2 = "left", "right"
    local vertical = CONFIG.walkAxis == "vertical"
    if vertical then d1, d2 = "up", "down" end
    walkToggle = not walkToggle
    local dir = walkToggle and d1 or d2
    -- Don't drift from the training spot: if it ended up to one side, walk back to it
    local p = playerPos()
    if p and bot.spot and p.g == bot.spot.g and p.n == bot.spot.n then
      local off = vertical and (p.y - bot.spot.y) or (p.x - bot.spot.x)
      if off > 0 then dir = d1 elseif off < 0 then dir = d2 end
    end
    push({ [dir] = true }, CONFIG.walkFrames)
    wait(math.random(0, 2))
  end
end

local function stepHealGo()
  bot.t = bot.t + 1
  if inBattle() then nav.cool = 0; enterBattle("heal_go"); return end
  if #queue > 0 then return end
  local r = navStep()
  if r == "done" then
    if simplify(CONFIG.healMode or "nurse") == "tile" then bot.st, bot.t = "heal_tile", 0
    else bot.st, bot.t = "nurse", 0; tap("up", 10) end
  elseif r == "fail" then halt(TX"No pude seguir la ruta al Centro (graba otra con 6)") end
end

local function stepNurse()
  bot.t = bot.t + 1
  if #queue > 0 then return end
  if bot.t > 60 and partyHealed() then
    bot.st, bot.t = "nurse_exit", 0
    return
  end
  if bot.t > 2400 then
    halt(TX"No pude curar: la ida debe terminar DENTRO del Centro, frente a la enfermera (graba otra con 6)")
    return
  end
  tap("A", 14)
end

-- Tile that heals when stepped on (purified zone): just close the message and wait
local function stepHealTile()
  bot.t = bot.t + 1
  if #queue > 0 then return end
  if bot.t > 30 and partyHealed() then
    bot.st, bot.t = "nurse_exit", 0
    return
  end
  if bot.t > 1200 then
    halt(TX"La casilla no curo al equipo: la ida debe terminar DENTRO de la zona que cura (graba otra con 6)")
    return
  end
  if bot.t % 20 == 0 then tap("B", 6) end
end

local function stepNurseExit()
  bot.t = bot.t + 1
  if #queue > 0 then return end
  if bot.t < 150 then tap("B", 12); return end
  navStart(route.back)
  bot.st, bot.t = "heal_back", 0
end

local function stepHealBack()
  bot.t = bot.t + 1
  if inBattle() then nav.cool = 0; enterBattle("heal_back"); return end
  if #queue > 0 then return end
  local r = navStep()
  if r == "done" then
    logLine(TX"De vuelta en el punto de entreno")
    afterBattleDecide()
  elseif r == "fail" then halt(TX"No pude volver al punto de entreno (graba otra ruta con 6)") end
end

-- -------------------- Take items (party menu) --------------------
-- START > POKEMON > (Pokemon) > ITEM > TAKE, checking every step in memory.
local function taskActive(fnAddr)
  for i = 0, 15 do
    local t = MENU.tasks + i * 40
    if read8(t + 4) ~= 0 and read32(t) == fnAddr then return true end
  end
  return false
end
local function s8(v) if v >= 0x80 then return v - 0x100 end return v end
local function menuActions()
  local p = read32(MENU.partyInternal)
  if p < 0x02000000 or p >= 0x02040000 then return {} end
  local n, t = read8(p + 0x17), {}
  if n > 8 then return {} end
  for k = 0, n - 1 do t[#t + 1] = read8(p + 0x0F + k) end
  return t
end
local function indexOf(list, v) for k, x in ipairs(list) do if x == v then return k - 1 end end return nil end
local function moveCursor(cur, want) if want > cur then tap("down", 8) else tap("up", 8) end end

beginTake = function(held)
  local names = {}
  for _, h in ipairs(held) do names[#names + 1] = itemName(h.item) end
  if tcfg.take == "pause" or not MENU then
    stopBot()
    bot.msg = TX"Quita los objetos (START > POKEMON > OBJETO > QUITAR): " .. table.concat(names, ", ") .. TX". Luego pulsa 7"
    logLine(bot.msg)
    notify(TX"Quita los objetos del equipo: " .. table.concat(names, ", "))
    pcall(emu.pause)
    return
  end
  logLine(TX"Guardando en la mochila: " .. table.concat(names, ", "))
  queue = {}
  zeroEnemy()
  bot.take = { list = held, i = 1, phase = "settle", tries = 0 }
  bot.st, bot.t = "take", 0
end

local function stepTake()
  bot.t = bot.t + 1
  if #queue > 0 then return end
  local T = bot.take
  local function fail(why)
    bot.take = nil
    halt(TX"No pude quitar los objetos: " .. why .. TX". Terminalo tu en el menu y pulsa 7")
  end
  local function go(phase) T.phase, bot.t = phase, 0 end
  if T.phase == "settle" then
    -- on the map, standing still, before opening the menu
    if inOverworld() then T.ow = (T.ow or 0) + 1 else T.ow = 0 end
    if T.ow >= 30 then tap("start", 20); go("startmenu") end
    if bot.t > 600 then fail(TX"no vuelve el mapa") end
  elseif T.phase == "startmenu" then
    if not taskActive(MENU.taskStartMenu) then
      if bot.t > 90 then
        T.tries = T.tries + 1
        if T.tries > 3 then fail(TX"el menu START no se abre") return end
        go("settle")
      end
      return
    end
    local n = read8(MENU.startCount)
    local want
    for k = 0, math.min(n, 9) - 1 do if read8(MENU.startOrder + k) == K.STARTMENU_POKEMON then want = k end end
    if not want then fail(TX"no hay opcion POKEMON en el menu START") return end
    local cur = read8(MENU.startCursor)
    if cur == want then tap("A", 30); go("party")
    elseif bot.t > 300 then fail(TX"el cursor del menu START no llega a POKEMON")
    else moveCursor(cur, want) end
  elseif T.phase == "party" then
    if read32(A.callback2) == MENU.cbParty and taskActive(MENU.taskChooseMon) then
      T.ready = (T.ready or 0) + 1
      if T.ready > 20 then T.ready = nil; go("pick") end
    elseif bot.t > 600 then fail(TX"no se abrio la pantalla del equipo") end
  elseif T.phase == "pick" then
    local e = T.list[T.i]
    if not e then go("exit") return end
    local m = partyMon(e.slot)
    if not m or m.item == 0 then T.i = T.i + 1 return end
    if not taskActive(MENU.taskChooseMon) then
      if bot.t > 300 then fail(TX"la pantalla del equipo no responde") end
      if bot.t % 30 == 0 then tap("B", 10) end
      return
    end
    local cur = s8(read8(MENU.partyMenu + 9))
    if cur == e.slot then tap("A", 20); go("actions")
    elseif bot.t > 300 then fail(TX"no llego al Pokemon " .. (e.slot + 1))
    elseif cur < e.slot or cur > 5 then tap("down", 8) else tap("up", 8) end
  elseif T.phase == "actions" or T.phase == "itemmenu" then
    local opt = (T.phase == "actions") and K.OPT_ITEM or K.OPT_TAKE
    local acts = menuActions()
    local want = taskActive(MENU.taskSelection) and indexOf(acts, opt) or nil
    if not want then
      if bot.t > 240 then fail(T.phase == "actions" and TX"no aparece OBJETO" or TX"no aparece QUITAR") end
      return
    end
    local cur = s8(read8(MENU.menuCursor))
    if cur == want then
      tap("A", 20)
      if T.phase == "actions" then go("itemmenu") else go("taking") end
    elseif bot.t > 240 then fail(TX"el cursor no llega a la opcion")
    else moveCursor(cur, want) end
  elseif T.phase == "taking" then
    local e = T.list[T.i]
    local m = partyMon(e.slot)
    if m and m.item == 0 then
      -- "Received X": close the message and go back to the party list
      if taskActive(MENU.taskChooseMon) and bot.t > 30 then T.i = T.i + 1; go("pick") return end
      if bot.t % 12 == 0 then tap("B", 8) end
    elseif bot.t > 240 then
      fail(TX"la mochila no tiene espacio para " .. itemName(e.item))
    end
  elseif T.phase == "exit" then
    -- leave the party and close the START menu (B until on the map with no menu)
    local onMap = inOverworld() and not taskActive(MENU.taskStartMenu)
    if onMap then T.ow = (T.ow or 0) + 1 else T.ow = 0 end
    if T.ow >= 40 then
      bot.take = nil
      bot.st, bot.t = "after", 0
      afterBattleDecide()
      return
    end
    if not onMap and bot.t % 20 == 0 then tap("B", 10) end
    if bot.t > 1200 then fail(TX"no pude cerrar los menus") end
  end
end

-- ------------------- Money: rematches with the VS Seeker --------------------
beginTrainerLoop = function()
  queue = {}
  zeroEnemy()
  if bot.healAfter then local why = bot.healAfter; bot.healAfter = nil; beginHeal(why); return end
  bot.st, bot.t = "tr_charge", 0
end

-- Charge the VS Seeker by walking side to side at the starting point (100 steps)
local function stepTrCharge()
  bot.t = bot.t + 1
  if inBattle() then enterBattle("tr_charge"); return end
  if bot.healAfter then beginTrainerLoop(); return end
  if #queue > 0 then return end
  if vsSeekerCharge() >= 100 then
    -- SELECT only works with the character standing still: tr_use waits before pressing it
    bot.st, bot.t, bot.ow, bot.vsPressed = "tr_use", 0, 0, false
    return
  end
  stepWalk()
  bot.st = "tr_charge"      -- stepWalk left it in "walk"
end

-- Use the VS Seeker: wait for the animation and close its messages
local function stepTrUse()
  bot.t = bot.t + 1
  if inBattle() then enterBattle("tr_charge"); return end     -- a wild battle before using it: retry later
  if #queue > 0 then return end
  if not bot.vsPressed then
    if inOverworld() then bot.ow = (bot.ow or 0) + 1 else bot.ow = 0 end
    if bot.ow >= 20 then tap("select", 20); bot.vsPressed, bot.t, bot.ow = true, 0, 0 end
    if bot.t > 600 then halt(TX"No puedo usar el Buscapelea: el personaje no se queda quieto en el mapa") end
    return
  end
  local busy = MENU and taskActive(MENU.taskVsSeeker)
  local quiet = inOverworld() and not busy
  if quiet then bot.ow = (bot.ow or 0) + 1 else bot.ow = 0 end
  if bot.t > 60 and bot.ow >= 60 then
    bot.laps = bot.laps + 1
    if vsSeekerCharge() >= 100 then logLine(string.format(TX"Vuelta %d: ningun entrenador quiere revancha todavia", bot.laps))
    else logLine(string.format(TX"Vuelta %d: Buscapelea usado", bot.laps)) end
    navStart(troute.go)
    bot.st, bot.t = "tr_go", 0
    return
  end
  if bot.t > 40 and bot.t % 25 == 0 then tap("B", 10) end    -- close messages ("no trainers", etc.)
  if bot.t > 2400 then halt(TX"El Buscapelea no termino (revisa que este registrado en SELECT)") end
end

local function stepTrRoute(back)
  bot.t = bot.t + 1
  local r0 = back and troute.back or troute.go
  if not nav or nav.r ~= r0 then navStart(r0) end
  if inBattle() then nav.cool = 0; enterBattle(back and "tr_back" or "tr_go"); return end
  if #queue > 0 then return end
  local r = navStep()
  if r == "done" then
    if back then afterBattleDecide()
    else navStart(troute.back); bot.st, bot.t = "tr_back", 0 end
  elseif r == "fail" then halt(TX"No pude seguir la ruta de los entrenadores (graba otra con 5)") end
end

-- ------------------------------ Teclas -------------------------------
local reportConfig

-- --------------------- Diagnostic (key 4) ---------------------
-- Read-only: never presses a button. The player opens the menus by hand and compares the
-- panel with the screen; every change is written to the log so it can be reported.
local DG = {
  on = false, last = nil,
  START = { [0] = "POKEDEX", "POKEMON", "MOCHILA", "JUGADOR", "GUARDAR", "OPCIONES", "SALIR", "RETIRARSE", "JUGADOR" },  --@i18n
  ACT = { [0] = "DATOS", "MOVER", "SALIR", "OBJETO", "DAR", "QUITAR", "CARTA", "QUITAR CARTA", "LEER", "SALIR",  --@i18n
    "CAMBIAR", "ENVIAR", "ENTRAR", "NO ENTRAR", "GUARDAR", "REGISTRAR", "CAMBIAR", "CAMBIAR" },  --@i18n
}
function DG.actName(id) return TX(DG.ACT[id]) or (id >= 18 and TX"MOV. CAMPO" or ("#" .. id)) end
-- Returns the diagnostic lines and a one-line summary for the log.
function DG.read()
  local L, sum = {}, {}
  local function add(text, short) L[#L + 1] = text; if short then sum[#sum + 1] = short end end
  add(string.format(TX"Juego: %s  menus: %s", GAME_LABEL, MENU and TX"verificados (USA)" or TX"NO verificados: quitar objetos pausara"))
  if MENU then
    local n, c = read8(MENU.startCount), read8(MENU.startCursor)
    local open = taskActive(MENU.taskStartMenu)
    local names = {}
    for k = 0, math.min(n, 9) - 1 do names[#names + 1] = TX(DG.START[read8(MENU.startOrder + k)]) or "?" end
    local cur = (n > 0 and n <= 9 and c < n) and (TX(DG.START[read8(MENU.startOrder + c)]) or "?") or "?"
    add(string.format(TX"Menu START: %s  cursor %d/%d -> %s", open and TX"ABIERTO" or TX"cerrado", c + 1, n, cur),
      TX"START " .. (open and cur or TX"cerrado"))
    add(TX"  opciones: " .. table.concat(names, " "))
    local pOpen = read32(A.callback2) == MENU.cbParty
    local slot = s8(read8(MENU.partyMenu + 9))
    local pm = (slot >= 0 and slot < 6) and partyMon(slot) or nil
    local who = (slot == 7) and TX"SALIR" or (pm and (speciesName(pm.species) .. (pm.item ~= 0 and (TX" lleva " .. itemName(pm.item)) or "")) or "?")
    add(string.format(TX"Equipo: %s  elegido %d -> %s", pOpen and TX"ABIERTO" or TX"cerrado", slot + 1, who),
      TX"equipo " .. (pOpen and (slot + 1 .. " " .. who) or TX"cerrado"))
    if pOpen and taskActive(MENU.taskSelection) then
      local acts, names2 = menuActions(), {}
      for _, a in ipairs(acts) do names2[#names2 + 1] = DG.actName(a) end
      local mc = read8(MENU.menuCursor)
      local sel = acts[mc + 1] and DG.actName(acts[mc + 1]) or "?"
      add(string.format(TX"Acciones: [%s]  cursor -> %s", table.concat(names2, ", "), sel), TX"acciones " .. sel)
    else
      add(TX"Acciones: cerrado")
    end
  end
  local reg = registeredItem()
  add(string.format(TX"SELECT: %s  Buscapelea %d/100", reg ~= 0 and itemName(reg) or TX"nada", vsSeekerCharge()),
    TX"SELECT " .. (reg ~= 0 and itemName(reg) or TX"nada"))
  local bt = TX"no"
  if inBattle() then
    local f = read32(A.battleType)
    bt = (band(f, K.BT_TRAINER) ~= 0 and TX"entrenador" or TX"salvaje") .. (band(f, K.BT_DOUBLE) ~= 0 and TX" doble" or "")
  end
  local mn = money()
  add(string.format(TX"Dinero $%s  Combate: %s", mn and tostring(mn) or "?", bt), TX"combate " .. bt)
  local slots = pickupSlots()
  local held = {}
  for _, h in ipairs(holdingSlots(slots)) do held[#held + 1] = itemName(h.item) end
  add(string.format(TX"Recogida: %d en el equipo  llevan objeto: %s", #slots, #held > 0 and table.concat(held, ", ") or TX"ninguno"))
  return L, table.concat(sum, " | ")
end
function DG.toggle()
  DG.on = not DG.on
  DG.last = nil
  bot.msg = DG.on and TX"Diagnostico: abre los menus a mano y compara (4 = salir)" or ""
  if DG.on then logLine(TX"Diagnostico activado (" .. GAME_LABEL .. ")") end
end
function DG.draw()
  local lines, sum = DG.read()
  if sum ~= DG.last then DG.last = sum; logLine(TX"DIAG " .. sum) end
  local y = 1
  gui.text(1, y, TX"DIAGNOSTICO (solo lee, no pulsa nada)  4 = salir", "green"); y = y + 9
  for _, t in ipairs(lines) do gui.text(1, y, t); y = y + 9 end
  gui.text(1, y + 2, TX"Compara con la pantalla; los cambios van al log.", "orange")
end

local prevKeys = {}
local function pressed(k, keys)
  return (keys[k] or keys["numpad" .. k]) and not (prevKeys[k] or prevKeys["numpad" .. k])
end
local function handleHotkeys()
  local keys = input.get()
  if pressed("7", keys) then
    if bot.running then stopBot(); bot.msg = TX"Detenido" else startBot() end
  elseif pressed("6", keys) then
    recHotkey("heal")
  elseif pressed("5", keys) then
    recHotkey("trainer")
  elseif pressed("4", keys) then
    DG.toggle()
  elseif pressed("8", keys) then
    -- Inspection mode: party 1..6, then the opponent (if in battle), then off
    local n = partyCount()
    local nxt = (bot.inspect or 0) + 1
    while true do
      if nxt <= 6 and nxt > n then nxt = 7 end
      if nxt == 7 and not (inBattle() and readPartyMon(A.enemy)) then nxt = 8 end
      if nxt >= 8 then nxt = 0 end
      break
    end
    bot.inspect = nxt
  elseif pressed("9", keys) then
    bot.panel = (bot.panel + 1) % 3
  elseif pressed("0", keys) and not bot.running then
    local ok, msg, problems = loadConfig()
    loadRoute()
    loadTrainerRoute()
    reportConfig(ok, msg, problems)
  end
  prevKeys = keys
end

reportConfig = function(ok, msg, problems)
  bot.cfgError = (not ok) or #problems > 0
  if not ok then bot.msg = TX"Error en " .. CONFIG_FILE .. ": " .. tostring(msg)
  elseif msg == "no existe" then bot.msg = TX"No hay " .. CONFIG_FILE .. TX": uso la configuracion por defecto"
  elseif #problems > 0 then bot.msg = TX"Config: " .. problems[1] .. (#problems > 1 and string.format(" (+%d)", #problems - 1) or "")
  else bot.msg = TX"Config cargada" end
  print(bot.msg)
  for i = 2, #problems do print(TX"Config: " .. problems[i]) end
end

-- ------------------------------- Panel -------------------------------
local PHASE = { idle = "Detenido", walk = "Buscando combate", battle = "Combate", after = "Fin del combate",  --@i18n
  take = "Guardando objetos", tr_charge = "Cargando Buscapelea", tr_use = "Usando Buscapelea",  --@i18n
  tr_go = "Ruta de entrenadores", tr_back = "Volviendo al inicio",  --@i18n
  heal_tile = "Curando", manual = "Esperando tu decision", learn_pick = "Aprendiendo ataque", heal_go = "Yendo al Centro", nurse = "Curando", nurse_exit = "Curando",  --@i18n
  heal_back = "Volviendo al punto" }  --@i18n

-- ------------------------- Inspection mode ---------------------------
local NATURE_STAT = { "At", "Df", "Vel", "AtE", "DfE" }   -- nature order in the game  --@i18n
local function drawInspect()
  local which = bot.inspect
  local addr = (which == 7) and A.enemy or (A.party + (which - 1) * 0x64)
  local m = readPartyMon(addr)
  local y = 1
  local function line(text, color) gui.text(1, y, text, color); y = y + 9 end
  local title = (which == 7) and TX"Rival" or string.format(TX"Equipo %d/%d", which, partyCount())
  if not m then line(title .. TX": vacio  (8 = siguiente)"); return end
  local shiny = m.sv < 8
  local nat = m.pid % 25
  local natName = natureNamesList[nat + 1] or "?"
  local up, down = floor(nat / 5) + 1, (nat % 5) + 1
  local natFx = (up == down) and TX"neutra" or string.format("+%s -%s", TX(NATURE_STAT[up]), TX(NATURE_STAT[down]))
  local sx = TT_SPECX[m.species]
  local gender = ""
  if sx then
    local gr = sx[3]
    if gr == 255 then gender = "" elseif gr == 0 then gender = " M" elseif gr == 254 then gender = " F"
    else gender = (band(m.pid, 0xFF) < gr) and " F" or " M" end
  end
  local abilId = sx and ((m.abilityBit == 1 and sx[2] ~= 0) and sx[2] or sx[1]) or 0
  line(string.format(TX"%s: %s%s Nv.%d%s", title, speciesName(m.species), gender, m.level, shiny and TX"  * SHINY *" or ""),
       shiny and "green" or nil)
  line(string.format(TX"%s (%s)  Hab: %s", natName, natFx, TT_ABILNAME[abilId] or "?"))
  -- Real stats (in memory: max HP 0x58, Atk 0x5A, Def 0x5C, Spe 0x5E, SpA 0x60, SpD 0x62)
  local st = { read16(addr + 0x58), read16(addr + 0x5A), read16(addr + 0x5C), read16(addr + 0x60), read16(addr + 0x62),
               read16(addr + 0x5E) }
  local ev = { m.evs[1], m.evs[2], m.evs[3], m.evs[5], m.evs[6], m.evs[4] }   -- screen order
  local function row(label, t, fmt)
    local parts = {}
    for i = 1, 6 do parts[i] = string.format(fmt or "%4d", t[i]) end
    return string.format("%-5s", label) .. table.concat(parts)
  end
  local hdr = { TX"PS", TX"At", TX"Df", TX"AtE", TX"DfE", TX"Vel" }
  line(row("", hdr, "%4s"))
  local statColor = {}
  line(row(TX"Stat", st))
  local perfect = true
  for i = 1, 6 do if m.ivs[i] < 31 then perfect = false end end
  line(row("IV", m.ivs), perfect and "green" or nil)
  local tot = 0
  for i = 1, 6 do tot = tot + ev[i] end
  line(row("EV", ev) .. string.format("  (%d/510)", tot))
  local hpType, hpPow = hiddenPower(m.ivWord)
  line(string.format(TX"PS %d/%d  Poder Oculto: %s %d", m.hp, m.maxHP, TX(TYPE_NAMES[hpType]) or "?", hpPow))
  local pkr = (m.pokerus == 0) and TX"no" or ((band(m.pokerus, 0x0F) > 0) and TX"SI (activo)" or TX"lo tuvo")
  line(string.format(TX"Exp %d  Amistad %d  Pokerus %s", m.exp, m.friendship, pkr))
  line(string.format(TX"Objeto: %s", m.item == 0 and "-" or (TT_ITEMNAME[m.item] or ("#" .. m.item))))
  for i = 1, 4, 2 do
    local function mv(k)
      local id = m.moves[k]
      if id == 0 then return "-" end
      local d = TT_MOVE[id]
      local maxPP = d and floor(d[5] * (5 + band(rshift(m.ppBonuses, (k - 1) * 2), 3)) / 5) or 0
      return string.format("%s %d/%d", d and d[7] or ("#" .. id), m.pp[k], maxPP)
    end
    line(string.format("%-18s %s", mv(i), mv(i + 1)))
  end
  local otid = m.otid % 0x10000
  line(string.format(TX"PID %08X  TID %d  SID %d   (8 = siguiente)", m.pid, otid, floor(m.otid / 0x10000)))
end

local MODE_LABEL = { nivel = "nivel", objetos = "objetos (Recogida)", robar = "robar objetos", dinero = "dinero" }  --@i18n
local function rate(n)
  local secs = 0
  pcall(function() secs = os.time() - (bot.startTime or os.time()) end)
  if n <= 0 or secs < 60 then return "" end
  return string.format("  ~%d/h", floor(n * 3600 / secs + 0.5))
end

local function draw()
  if DG.on then DG.draw(); return end
  if bot.inspect and bot.inspect > 0 then drawInspect(); return end
  if bot.panel == 0 then return end
  local y = 1
  local function line(text, color) gui.text(1, y, text, color); y = y + 9 end
  local status = bot.done and TX"COMPLETO" or (bot.running and (TX(PHASE[bot.st]) or bot.st) or "OFF")
  if rec then status = TX"GRABANDO " .. ((rec.kind == "trainer") and TX"ENTRENADORES " or TX"CENTRO ") .. ((rec.phase == "go") and "(IDA)" or "(VUELTA)") end
  line(string.format(TX"Farmear v1.0 [%s]: %s", TX(MODE_LABEL[tcfg.mode]) or "?", status), (bot.done or rec) and "green" or nil)
  local m = lead()
  if m then
    local lv = (tcfg.mode == "nivel" and CONFIG.targetLevel) and string.format("Nv.%d/%d", m.level, CONFIG.targetLevel) or ("Nv." .. m.level)
    line(string.format(TX"%s %s  PS %d/%d  PP %d", speciesName(m.species), lv, m.hp, m.maxHP, usefulPP(m)))
  end
  local running = bot.running or bot.done
  if tcfg.mode == "nivel" and m and running then
    line(string.format(TX"Niveles +%d desde el inicio%s", m.level - (bot.startLevel or m.level), rate(m.level - (bot.startLevel or m.level))))
  elseif tcfg.mode == "objetos" or tcfg.mode == "robar" then
    local tgt = CONFIG.itemTarget and ("/" .. CONFIG.itemTarget) or ""
    if running then
      line(string.format(TX"Guardados %d%s  encontrados %d%s", bot.items or 0, tgt, bot.found or 0, rate(bot.found or 0)),
        (CONFIG.itemTarget and (bot.items or 0) >= CONFIG.itemTarget) and "green" or nil)
    end
    if tcfg.mode == "objetos" then
      local slots = bot.pickSlots or pickupSlots()
      line(string.format(TX"Con Recogida: %d  llevan objeto: %d", #slots, #holdingSlots(slots)))
    elseif running then
      line(string.format(TX"Robos %d", bot.steals or 0))
    end
    if bot.lastItem and running then line(TX"Ultimo: " .. bot.lastItem) end
  elseif tcfg.mode == "dinero" then
    local mn = money()
    line(string.format(TX"Dinero $%s%s%s", mn and tostring(mn) or "?", CONFIG.moneyTarget and (TX"  meta $" .. CONFIG.moneyTarget) or "",
      running and (TX"  ganado +" .. (bot.earned or 0) .. rate(bot.earned or 0)) or ""))
    line(string.format(TX"Buscapelea %d/100  vueltas %d  entrenadores %d  Ruta: %s", vsSeekerCharge(), bot.laps or 0, bot.trainers or 0,
      troute.go and string.format(TX"%d/%d pasos", #troute.go, #troute.back) or TX"no grabada (tecla 5)"))
  end
  if bot.panel == 2 or not bot.running then
    if not bot.running and not rec then
      line(string.format(TX"7 iniciar  6 ruta Centro  5 ruta entrenadores  4 diagnostico  8 ver  9 panel  0 config   Centro: %s",
        route.go and string.format(TX"%d/%d pasos", #route.go, #route.back) or TX"no grabada"))
    end
    line(string.format(TX"Combates %d  peleados %d  huidos %d  curas %d", bot.battles, bot.fought, bot.fled, bot.heals))
  end
  if bot.lastFoe and bot.running then
    local held = bot.lastFoe.item ~= 0 and (TX"  lleva " .. itemName(bot.lastFoe.item)) or ""
    line(string.format(TX"Rival: %s Nv.%d%s  -> %s (%s)", speciesName(bot.lastFoe.species), bot.lastFoe.level, held,
      bot.fight and TX"pelear" or TX"huir", bot.lastWhy or ""))
  end
  if bot.panel == 2 then
    local p = playerPos()
    line(string.format(TX"Menu %d  Espera %d  Cursor %d/%d  Combate %d  Pos %s", read8(A.bufferA),
      band(read32(A.execFlags), 1), band(read8(A.actionCursor), 3), band(read8(A.moveCursor), 3),
      inBattle() and 1 or 0, p and string.format("%d.%d (%d,%d)", p.g, p.n, p.x, p.y) or "?"))
    if MENU then
      line(string.format(TX"START %d/%d  equipo %d  menu %d  tareas: start %s equipo %s acciones %s", read8(MENU.startCursor),
        read8(MENU.startCount), s8 and read8(MENU.partyMenu + 9) or 0, read8(MENU.menuCursor),
        taskActive(MENU.taskStartMenu) and TX"si" or TX"no", taskActive(MENU.taskChooseMon) and TX"si" or TX"no",
        taskActive(MENU.taskSelection) and TX"si" or TX"no"))
    end
  end
  if bot.msg ~= "" then gui.text(1, 150, bot.msg, "orange") end
end

-- ------------------------------- Inicio ------------------------------
print("FRLG Farm Bot v1.0")
if not gameName then
  print(TX"Este ROM no es Rojo Fuego / Verde Hoja. El bot no se ejecutara.")
  return
end
print(string.format(TX"Juego: %s", GAME_LABEL))
print(TX"7 = iniciar/detener   6 = ruta al Centro   5 = ruta de entrenadores   4 = diagnostico   8 = ver Pokemon   9 = panel   0 = recargar " .. CONFIG_FILE)
print(string.format(TX"Modo: %s", TX(MODE_LABEL[tcfg.mode]) or "?"))
if not MENU then print(TX"Aviso: menus no verificados en esta version: para quitar objetos el bot pausara y te avisara") end
reportConfig(cfgOk, cfgMsg, cfgProblems)
if route.go then print(string.format(TX"Ruta al Centro cargada: %d pasos de ida, %d de vuelta", #route.go, #route.back)) end
if troute.go then print(string.format(TX"Ruta de entrenadores cargada: %d pasos de ida, %d de vuelta", #troute.go, #troute.back)) end

local badFrames = 0
while true do
  gFrame = gFrame + 1
  handleHotkeys()
  recStep()
  if bot.running then
    if otherInstanceAlive() then halt(TX"Hay otro Farm Bot o un Train Bot corriendo en otra ventana de Lua: deja solo uno") end
  end
  if bot.running then
    writeLock()
    if validPtr(read32(A.sb1)) then badFrames = 0 else badFrames = badFrames + 1 end
    if badFrames > 30 then halt(TX"El juego se reinicio: bot detenido") end
  end
  if bot.running then
    local busy = runQueue()
    local st = bot.st
    if st == "walk" then stepWalk()
    elseif st == "battle" then stepBattle()
    elseif st == "after" then stepAfter()
    elseif st == "manual" then stepManual()
    elseif st == "heal_go" then stepHealGo()
    elseif st == "nurse" then stepNurse()
    elseif st == "heal_tile" then stepHealTile()
    elseif st == "nurse_exit" then stepNurseExit()
    elseif st == "heal_back" then stepHealBack()
    elseif st == "learn_pick" then stepLearnPick()
    elseif st == "take" then stepTake()
    elseif st == "tr_charge" then stepTrCharge()
    elseif st == "tr_use" then stepTrUse()
    elseif st == "tr_go" then stepTrRoute(false)
    elseif st == "tr_back" then stepTrRoute(true) end
    if not busy then runQueue() end
  end
  draw()
  emu.frameadvance()
end
