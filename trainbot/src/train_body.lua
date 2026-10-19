-- ===================================================================
--  FRLG Train Bot v1.10  (Rojo Fuego / Verde Hoja - VBA-ReRecording)
--
--  Script APARTE del Shiny Bot: entrena al primer Pokemon del equipo.
--  Carga SOLO este script (no junto con FRLG_ShinyBot.lua).
--
--  Que hace:
--    - Camina en la hierba de lado a lado buscando combates.
--    - Pelea solo contra especies que dan los EVs que pediste (huye del resto).
--    - Elige el ataque que mas dano hace contra cada rival.
--    - No aprende ataques nuevos (o te deja decidir) y cancela evoluciones
--      (configurable en el .json).
--    - Cuando el Pokemon esta debil o sin PP, va al Centro Pokemon por la
--      ruta que grabaste, se cura y vuelve al mismo lugar.
--    - Se detiene al completar los EVs y el nivel objetivo.
--
--  Teclas:
--    7 = iniciar / detener
--    6 = grabar la ruta al Centro Pokemon (ver instrucciones en pantalla)
--    8 = ver Pokemon: stats, IVs, EVs, naturaleza, ataques (equipo 1-6 y rival)
--    9 = panel (compacto / completo / oculto)
--    0 = recargar FRLG_TrainBot.json
-- ===================================================================

local CONFIG = {
  evs            = nil,     -- EVs objetivo, ej. {atk=252, spe=252, hp=4}
  targetLevel    = nil,     -- nivel objetivo (nil = solo EVs)
  maxLevel       = nil,     -- detenerse al llegar a este nivel aunque falten EVs
  species        = nil,     -- pelear SOLO contra estas especies (nil = segun EVs)
  avoidSpecies   = nil,     -- nunca pelear contra estas
  allowOvershoot = false,   -- permitir pasarse del objetivo de EVs
  healBelow      = 40,      -- ir a curarse si los PS bajan de este % (tras el combate)
  fleeBelow      = 20,      -- huir en pleno combate si los PS bajan de este %
  minPP          = 3,       -- ir a curarse si quedan menos PP en total en ataques utiles
  learnMoves     = "auto",  -- "auto" = aprende si es mejor, "never" = nunca, "ask" = te deja decidir
  keepMoves      = nil,     -- ataques que nunca se olvidan, ej. {"Thunder Wave"}
  wantedMoves    = nil,     -- ataques finales deseados (max 4): solo aprende estos y rechaza el resto
  askTimeout     = 300,     -- "ask": segundos esperando tu decision antes de decidir solo (nil = esperar siempre)
  notify         = nil,     -- avisos al celular: {ntfy = "tu-tema"} y/o {discord = "url del webhook"}
  evolve         = false,   -- false = cancelar evoluciones (B), true = dejar evolucionar (decides tu)
  stopOnShiny    = true,    -- pausar si aparece un shiny salvaje
  walkAxis       = "horizontal",
  walkFrames     = 16,
  routeFile      = "FRLG_TrainRoute.txt",
  healMode       = "nurse",   -- "nurse" = hablar con la enfermera; "tile" = casilla que cura al pisarla (zona purificada Torre 5F)
  logFile        = "train_log.txt",
  logDir         = "logs",
}
local CONFIG_FILE = "FRLG_TrainBot.json"

local read32  = memory.readdwordunsigned
local read16  = memory.readwordunsigned
local read8   = memory.readbyte
local write32 = memory.writedword
local rshift, band, bxor = bit.rshift, bit.band, bit.bxor
local floor = math.floor

--@@TABLES@@
--@@DATA@@

-- ------------------------- Version / direcciones ---------------------
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
-- Variables de combate (pokefirered, USA) a la misma distancia de gEnemyParty
A.actionCursor = A.enemy - 0x34    -- gActionSelectionCursor[0]
A.moveCursor   = A.enemy - 0x30    -- gMoveSelectionCursor[0]
A.battleMons   = A.enemy - 0x448   -- gBattleMons[0..3] (0x58 c/u)
A.bufferA      = A.enemy - 0x1468  -- gBattleBufferA[0][0] = comando del jugador
A.execFlags    = A.enemy - 0x464   -- gBattleControllerExecFlags
A.scriptPtr    = A.enemy - 0x2B8   -- gBattlescriptCurrInstr
A.yesNoCursor  = A.enemy - 0x1A9   -- gBattleCommunication[1]
A.battleOutcome = A.enemy - 0x1A2
A.avatar  = (gameLang == 0x4A) and 0x02036FAC or 0x02037078   -- gPlayerAvatar
A.objects = A.avatar - 0x240                                   -- gObjectEvents

local CMD_CHOOSEACTION, CMD_CHOOSEMOVE = 18, 20
local OP_LEARNMOVE, OP_STOPLEARNING = 0x5A, 0x5B
A.moveToLearn = A.enemy - 0xA       -- gMoveToLearn
A.sumCursor   = A.enemy + 0x17141   -- sMoveSelectionCursorPos (pantalla de datos, elegir ataque a olvidar)
local HM_MOVES = { [15] = true, [19] = true, [57] = true, [70] = true, [127] = true, [148] = true, [249] = true, [291] = true }

-- ------------------------------ Utilidades ---------------------------
local SCRIPT_DIR = ""
pcall(function()
  local src = debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then SCRIPT_DIR = src:sub(2):match("^(.*[/\\])") or "" end
end)

local function jsonDecode(str)
  local pos = 1
  local function err(msg) error(string.format("JSON: %s (caracter %d)", msg, pos), 0) end
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
      if c == "" then err("texto sin cerrar") end
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
        if str:sub(pos, pos) ~= '"' then err("se esperaba un nombre entre comillas") end
        local k = parseString()
        skip()
        if str:sub(pos, pos) ~= ":" then err("falta ':'") end
        pos = pos + 1
        obj[k] = value()
        skip()
        local d = str:sub(pos, pos); pos = pos + 1
        if d == "}" then return obj end
        if d ~= "," then err("falta ',' o '}'") end
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
        if d ~= "," then err("falta ',' o ']'") end
        skip()
        if str:sub(pos, pos) == "]" then pos = pos + 1; return arr end
      end
    elseif c == '"' then return parseString()
    elseif str:sub(pos, pos + 3) == "true" then pos = pos + 4; return true
    elseif str:sub(pos, pos + 4) == "false" then pos = pos + 5; return false
    elseif str:sub(pos, pos + 3) == "null" then pos = pos + 4; return nil
    else
      local num = str:match("^-?%d+%.?%d*", pos)
      if not num or num == "" then err("valor no valido") end
      pos = pos + #num
      return tonumber(num)
    end
  end
  local v = value()
  skip()
  if pos <= #str then err("texto de mas al final") end
  return v
end

local function simplify(name)
  name = tostring(name):lower()
  local acc = { ["\195\161"] = "a", ["\195\169"] = "e", ["\195\173"] = "i", ["\195\179"] = "o",
                ["\195\186"] = "u", ["\195\177"] = "n" }
  for k, v in pairs(acc) do name = name:gsub(k, v) end
  return (name:gsub("[^%w]", ""))
end

-- Estadisticas: indice de pantalla 1..6 = PS, At, Df, AtE, DfE, Vel
local STAT_KEYS = { hp = 1, ps = 1, atk = 2, ata = 2, attack = 2, ataque = 2, def = 3, defense = 3, defensa = 3,
  spa = 4, spatk = 4, ate = 4, atesp = 4, ataqueespecial = 4, spd = 5, spdef = 5, dfe = 5, defesp = 5,
  defensaespecial = 5, spe = 6, speed = 6, vel = 6, velocidad = 6 }
local STAT_LABEL = { "PS", "At", "Df", "AtE", "DfE", "Vel" }
-- Los EVs en memoria van en orden PS, At, Df, Vel, AtE, DfE
local EV_OF_STAT = { 1, 2, 3, 5, 6, 4 }

local tcfg = {}   -- configuracion interpretada

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
    if not found then problems[#problems + 1] = "especie desconocida: " .. tostring(n) end
  end
  return set
end

local function interpretConfig(problems)
  tcfg = { target = nil }
  if type(CONFIG.evs) == "table" then
    tcfg.target = { 0, 0, 0, 0, 0, 0 }     -- en orden de memoria
    local total = 0
    for k, v in pairs(CONFIG.evs) do
      local i = STAT_KEYS[simplify(k)]
      v = tonumber(v)
      if not i or not v then problems[#problems + 1] = "EV desconocido: " .. tostring(k)
      else
        if v > 255 then v = 255 end
        tcfg.target[EV_OF_STAT[i]] = v
        total = total + v
      end
    end
    if total > 510 then problems[#problems + 1] = "los EVs suman " .. total .. " (maximo 510)" end
  end
  tcfg.only = speciesSet(CONFIG.species, problems)
  tcfg.avoid = speciesSet(CONFIG.avoidSpecies, problems)
  local lm = simplify(CONFIG.learnMoves or "auto")
  if lm ~= "never" and lm ~= "ask" and lm ~= "auto" then
    problems[#problems + 1] = "learnMoves debe ser \"auto\", \"never\" o \"ask\""; lm = "never"
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
      if not found then problems[#problems + 1] = "ataque desconocido en " .. key .. ": " .. tostring(name) .. " (usa el nombre en ingles)" end
    end
    return set, n
  end
  tcfg.keep = moveSet(CONFIG.keepMoves, "keepMoves") or {}
  local wn
  tcfg.wanted, wn = moveSet(CONFIG.wantedMoves, "wantedMoves")
  if tcfg.wanted and wn == 0 then tcfg.wanted = nil end
  if wn > 4 then problems[#problems + 1] = "wantedMoves tiene " .. wn .. " ataques (maximo 4)" end
  if CONFIG.notify ~= nil and type(CONFIG.notify) ~= "table" then problems[#problems + 1] = "notify debe ser {\"ntfy\": \"tema\"}" end
end

local function loadConfig()
  local problems = {}
  local ok, msg = pcall(function()
    local f = io.open(SCRIPT_DIR .. CONFIG_FILE, "r")
    if not f then return "no existe" end
    local data = f:read("*a"); f:close()
    local cfg = jsonDecode(data)
    if type(cfg) ~= "table" then error("el archivo debe ser un objeto { ... }", 0) end
    local optional = { evs = 1, targetLevel = 1, maxLevel = 1, species = 1, avoidSpecies = 1, keepMoves = 1, wantedMoves = 1,
                       askTimeout = 1, notify = 1 }
    for k, v in pairs(cfg) do
      if CONFIG[k] == nil and not optional[k] then problems[#problems + 1] = "opcion desconocida: " .. k end
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

-- Aviso al celular (ntfy.sh y/o Discord) con curl, sin bloquear el emulador.
-- curl viene incluido en Windows 10/11.
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
    run(string.format('curl -s -m 15 -H "Title: FRLG Train Bot" -d "%s" https://ntfy.sh/%s', clean, n.ntfy))
  end
  if type(n.discord) == "string" and n.discord:match("^https://[%w%./_%-]+$") then
    run(string.format('curl -s -m 15 -H "Content-Type: application/json" -d "{\\"content\\":\\"%s\\"}" %s', clean, n.discord))
  end
end

local function validPtr(p) return p >= 0x02000000 and p < 0x02040000 end
local function s16(v) if v >= 0x8000 then return v - 0x10000 end return v end

-- ------------------------- Datos de Pokemon --------------------------
-- Orden de las 4 subestructuras segun PID % 24 (G=crecimiento A=ataques E=EVs M=varios)
local SUB_ORDER = { "GAEM", "GAME", "GEAM", "GEMA", "GMAE", "GMEA", "AGEM", "AGME", "AEGM", "AEMG", "AMGE", "AMEG",
                    "EGAM", "EGMA", "EAGM", "EAMG", "EMGA", "EMAG", "MGAE", "MGEA", "MAGE", "MAEG", "MEGA", "MEAG" }
local function subOffset(pid, letter)
  return (SUB_ORDER[(pid % 24) + 1]:find(letter) - 1) * 12
end

local function ivsFromWord(w)   -- orden de pantalla: PS/At/Df/AtE/DfE/Vel
  return { band(w, 0x1F), band(rshift(w, 5), 0x1F), band(rshift(w, 10), 0x1F),
           band(rshift(w, 20), 0x1F), band(rshift(w, 25), 0x1F), band(rshift(w, 15), 0x1F) }
end

-- Lee un Pokemon del equipo (100 bytes) con checksum
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

-- Rival salvaje: se acepta cuando lleva 3 frames sin cambiar (puede estar a medio crear)
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

-- Pokemon en combate (gBattleMons): 0 = el tuyo, 1 = el rival
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

local function inBattle() return band(read8(A.inBattleByte), 0x02) ~= 0 end
local function partyCount() local c = read8(A.partyCnt); if c > 6 then return 0 end return c end
local function lead() return readPartyMon(A.party) end

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

-- ------------------------ Tipos y danos ------------------------------
local TYPE_NAMES = { [0] = "Normal", "Lucha", "Volador", "Veneno", "Tierra", "Roca", "Bicho", "Fantasma", "Acero", "???",
  "Fuego", "Agua", "Planta", "Electrico", "Psiquico", "Hielo", "Dragon", "Siniestro" }
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
  local typ = t + 1                 -- 1..16 = Lucha..Siniestro (sin el tipo ???)
  if typ >= 9 then typ = typ + 1 end
  return typ, pw
end

-- Dano esperado de un ataque (ya multiplicado por la precision)
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
  -- Dano fijo
  if eff == EF.LEVEL_DAMAGE or eff == EF.PSYWAVE then return me.level * accF, me.level end
  if eff == EF.DRAGON_RAGE then return 40 * accF, 40 end
  if eff == EF.SONICBOOM then return 20 * accF, 20 end
  if eff == EF.SUPER_FANG then local d = math.max(floor(foe.hp / 2), 1); return d * accF, d end
  -- Poder variable
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

-- Mejor ataque contra el rival: el que mas dano esperado hace, sin pasarse
-- de los PS que le quedan (asi no gasta un ataque fuerte si basta uno debil).
local function bestMove(blocked)
  local me, foe = battleMon(0), battleMon(1)
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

-- PP que quedan en ataques que hacen dano (fuera de combate, del equipo)
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

-- --------------------- Aprender ataques nuevos ----------------------
-- Quien aprende: gBattleStruct->expGetterMonId (indice en el equipo)
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
-- Valor de un ataque contra un rival neutro (sin ventaja de tipo), con STAB y precision
local function moveWorth(id, me)
  if id == 0 or not TT_MOVE[id] then return 0 end
  local ref = { type1 = 9, type2 = 9, ability = 0, def = math.max(me.def, 1), spd = math.max(me.spd, 1), hp = math.max(me.maxHP, 1) * 4 }
  return (moveValue(id, me, ref))
end
local function moveName(id) return (TT_MOVE[id] and TT_MOVE[id][7]) or ("#" .. tostring(id)) end
-- Devuelve (casilla a olvidar 1-4 o nil, ataque nuevo, ataque que se olvidaria)
local function planLearn()
  local new = read16(A.moveToLearn)
  local me = monAsAttacker(learnerIndex())
  if not me or not TT_MOVE[new] then return nil, new end
  -- Solo se cambian ataques del Pokemon que se entrena (el primero del equipo)
  if learnerIndex() ~= 0 then return nil, new end
  if tcfg.wanted then
    -- Lista de ataques deseados: solo aprende esos, y olvida uno que NO este en la lista
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

-- Como va cada ataque deseado: ya lo sabe, a que nivel lo aprende, o si no es por nivel
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
        txt = past and ("ya paso Nv." .. past .. ": Recordador") or "MT/tutor"
      end
    end
    out[#out + 1] = moveName(id) .. " " .. txt
  end
  return table.concat(out, ", ")
end

-- ------------------------------- EVs ---------------------------------
local ITEM_MACHO_BRACE = 181
local function evGain(mon, species)
  local sp = TT_SPEC[species]
  if not sp then return nil end
  local mult = 1
  if mon.pokerus ~= 0 then mult = mult * 2 end
  if mon.item == ITEM_MACHO_BRACE then mult = mult * 2 end
  local g = {}
  for i = 1, 6 do g[i] = sp[2 + i] * mult end
  return g
end

local function evTotal(mon) local t = 0 for i = 1, 6 do t = t + mon.evs[i] end return t end
local function evsDone(mon)
  if not tcfg.target then return true end
  for i = 1, 6 do if mon.evs[i] < tcfg.target[i] then return false end end
  return true
end

-- Decide si conviene pelear contra esta especie. Devuelve (pelear, motivo)
local function shouldFight(mon, species)
  if tcfg.avoid and tcfg.avoid[species] then return false, "evitada" end
  if tcfg.only and not tcfg.only[species] then return false, "no esta en la lista" end
  if not tcfg.target then return true, "nivel" end
  local g = evGain(mon, species)
  if not g then return false, "sin datos" end
  local total = evTotal(mon)
  local room = 510 - total
  local useful = false
  for i = 1, 6 do
    if g[i] > 0 and room > 0 and mon.evs[i] < 255 then
      local add = math.min(g[i], 255 - mon.evs[i], room)
      local after = mon.evs[i] + add
      if after > tcfg.target[i] and not (CONFIG.allowOvershoot and tcfg.target[i] > 0) then
        return false, "daria EVs de " .. STAT_LABEL[({ 1, 2, 3, 6, 4, 5 })[i]]
      end
      if mon.evs[i] < tcfg.target[i] then useful = true end
    end
  end
  if useful then return true, "EVs" end
  if evsDone(mon) and CONFIG.targetLevel and mon.level < CONFIG.targetLevel then return true, "nivel" end
  return false, "no da los EVs que faltan"
end

local function trainingDone(mon)
  if CONFIG.maxLevel and mon.level >= CONFIG.maxLevel then return true end
  if not evsDone(mon) then return false end
  if CONFIG.targetLevel and mon.level < CONFIG.targetLevel then return false end
  return tcfg.target ~= nil or CONFIG.targetLevel ~= nil
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

-- ------------------------- Ruta al Centro ----------------------------
local route = { go = nil, back = nil }
local rec = nil      -- grabacion en curso

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
-- Limpieza de rutas: al cruzar una puerta el juego cambia el mapa unos frames
-- antes que las coordenadas (y la memoria del mapa se mueve), asi que quedaban
-- puntos falsos: mapa nuevo con las coordenadas viejas, o mapas imposibles.
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

-- Si la ida termino AFUERA del Centro y la entrada a la enfermera quedo grabada
-- al principio de la vuelta, se mueve ese tramo a la ida (hasta el punto mas
-- adentro, que es donde se habla con la enfermera).
local function fixRoute(go, back)
  if not go or not back or #go < 2 or #back < 2 then return go, back end
  -- Modo casilla: si la vuelta empieza con un "desvio" que regresa al mismo
  -- punto (entraste a la zona que cura DESPUES de pulsar 6), ese desvio va a la ida.
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
  -- punto mas lejano de la entrada dentro de ese tramo
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
    print(string.format("Ruta corregida: ida %d -> %d pasos, vuelta %d -> %d", g0, #route.go, b0, #route.back))
    saveRoute()
  end
end
loadRoute()

local function recStep()
  if not rec then return end
  local p = playerPos()
  if not p then return end
  local list = rec.list
  local last = list[#list]
  local junk = p.g > 42 or p.n > 120
  -- mapa nuevo con las coordenadas viejas = a mitad de una puerta: esperar
  if last and (p.g ~= last.g or p.n ~= last.n) and p.x == last.x and p.y == last.y then junk = true end
  if not junk and not samePos(p, last) then
    list[#list + 1] = { g = p.g, n = p.n, x = p.x, y = p.y, d = rec.prevFace or p.face }
  end
  if not junk then rec.prevFace = p.face end
end

local function recHotkey()
  if bot.running then bot.msg = "Deten el bot (7) antes de grabar la ruta"; return end
  local p = playerPos()
  if not p then bot.msg = "Carga tu partida antes de grabar"; return end
  if not rec then
    rec = { phase = "go", list = { { g = p.g, n = p.n, x = p.x, y = p.y, d = 0 } }, prevFace = p.face }
    bot.msg = "GRABANDO IDA: camina hasta quedar frente a la enfermera y pulsa 6"
  elseif rec.phase == "go" then
    if #rec.list < 2 then bot.msg = "Aun no te has movido: camina hasta la enfermera"; return end
    rec.go = rec.list
    rec.phase = "back"
    rec.list = { { g = p.g, n = p.n, x = p.x, y = p.y, d = 0 } }
    bot.msg = "GRABANDO VUELTA: cura (si quieres) y vuelve al punto de entreno; pulsa 6"
  else
    if #rec.list < 2 then bot.msg = "Aun no te has movido: vuelve al punto de entreno"; return end
    route.go, route.back = fixRoute(cleanRoute(rec.go), cleanRoute(rec.list))
    rec = nil
    saveRoute()
    bot.msg = string.format("Ruta guardada (%d pasos ida, %d vuelta)", #route.go, #route.back)
  end
  print(bot.msg)
end

-- Seguir una ruta grabada. Devuelve "done", "fail" o nil (sigue).
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
  if nav.lastMap and nav.lastMap ~= mapKey then nav.cool = 40 end   -- cambio de mapa: soltar un momento
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
    -- fuera de la ruta (lo empujo un NPC, etc.): buscar un punto vecino de la ruta
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
    dir = DIR_KEY[nxt.d] or "up"      -- cambio de mapa (puerta): la direccion que se usaba al entrar
  end
  nav.stuck = nav.stuck + 1
  if nav.stuck > 120 then
    -- atascado (NPC en medio o un cartel abierto): soltar, cerrar texto y reintentar
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
-- Detenerse con un mensaje: se muestra, se guarda en el log y se avisa al celular
local function halt(msg)
  stopBot()
  bot.msg = msg
  logLine(msg)
  notify(msg)
  pcall(emu.pause)            -- pausar para que lo veas
end
local function leadOk()
  local m = lead()
  if not m then return nil end
  return m
end

local function needHeal(m)
  if m.hp == 0 then return "debilitado" end
  if m.maxHP > 0 and m.hp * 100 < m.maxHP * CONFIG.healBelow then return "PS bajos" end
  if usefulPP(m) < CONFIG.minPP then return "sin PP" end
  return nil
end

-- Curado de verdad: PS al maximo, sin estado alterado y PP de todos los ataques al maximo
-- (antes solo se miraban los PS y, si iba al Centro por falta de PP, se iba sin hablar)
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
    halt("Necesita curarse (" .. reason .. "): cura, vuelve al punto y pulsa 7. (Graba la ruta con 6)")
    return
  end
  bot.heals = bot.heals + 1
  logLine("Al Centro Pokemon: " .. reason)
  queue = {}
  zeroEnemy()
  navStart(route.go)
  bot.st, bot.t = "heal_go", 0
end

-- Despues de un combate: decidir que sigue
local function afterBattleDecide()
  local m = leadOk()
  if not m then halt("No se pudo leer el Pokemon del equipo"); return end
  -- EVs ganados en el ultimo combate
  if bot.prevEvs then
    local parts = {}
    for st = 1, 6 do
      local i = EV_OF_STAT[st]
      local d = m.evs[i] - bot.prevEvs[i]
      if d > 0 then parts[#parts + 1] = "+" .. d .. " " .. STAT_LABEL[st] end
    end
    if #parts > 0 then
      bot.gainBattles = (bot.gainBattles or 0) + 1
      bot.lastGain = table.concat(parts, ", ") .. (bot.lastFoe and (" (" .. speciesName(bot.lastFoe.species) .. ")") or "")
    end
    for i = 1, 6 do bot.prevEvs[i] = m.evs[i] end
  end
  if m.species ~= bot.leadSpecies then
    logLine(string.format("%s evoluciono a %s", speciesName(bot.leadSpecies), speciesName(m.species)))
    bot.leadSpecies = m.species
  end
  if trainingDone(m) then
    stopBot()
    bot.done = true
    bot.msg = string.format("ENTRENAMIENTO COMPLETO: %s Nv.%d  EVs %s", speciesName(m.species), m.level,
      table.concat({ m.evs[1], m.evs[2], m.evs[3], m.evs[5], m.evs[6], m.evs[4] }, "/"))
    logLine(bot.msg)
    notify(bot.msg)
    emu.pause()
    return
  end
  -- Con Pokerus o Brazal Firme cada combate da 2 o 4 EVs: si falta menos que eso
  -- y no se permite pasarse, nunca se podria completar.
  if tcfg.target and not CONFIG.allowOvershoot then
    local mult = ((m.pokerus ~= 0) and 2 or 1) * ((m.item == ITEM_MACHO_BRACE) and 2 or 1)
    for s = 1, 6 do
      local i = EV_OF_STAT[s]
      local need = tcfg.target[i] - m.evs[i]
      if need > 0 and need < mult and evTotal(m) < 510 then
        halt(string.format("Faltan %d EVs de %s pero cada combate da %d: pon allowOvershoot o usa otro metodo",
          need, STAT_LABEL[s], mult))
        return
      end
    end
  end
  local why = needHeal(m)
  if why then beginHeal(why); return end
  -- Si no esta en el punto de entreno (p. ej. perdio y aparecio en el Centro)
  local p = playerPos()
  if bot.spot and p and not (p.g == bot.spot.g and p.n == bot.spot.n and math.abs(p.x - bot.spot.x) <= 2
     and math.abs(p.y - bot.spot.y) <= 2) then
    if route.back then
      for k = 1, #route.back do
        if samePos(p, route.back[k]) then navStart(route.back); nav.idx = k; bot.st, bot.t = "heal_back", 0; return end
      end
    end
    halt("El personaje no esta en el punto de entreno: llevalo alli y pulsa 7")
    return
  end
  startWalk()
end

-- Solo un Train Bot a la vez: si quedo otra ventana de Lua corriendo (por ejemplo
-- una version vieja), las dos pulsarian botones al mismo tiempo.
local MY_TOKEN = string.format("%d%d", math.random(100000, 999999), math.random(100000, 999999))
local LOCK_FILE = "train_running.lock"
local lastLockWrite = -1
local function nowSec() local t = 0; pcall(function() t = os.time() end); return t end
local function otherInstanceAlive()
  local data
  pcall(function() local f = io.open(LOGDIR .. LOCK_FILE, "r"); if f then data = f:read("*a"); f:close() end end)
  if not data then return false end
  local t, tok = data:match("(%d+)%s+(%d+)")
  t = tonumber(t)
  return tok ~= nil and tok ~= MY_TOKEN and t ~= nil and nowSec() - t <= 5
end
local function writeLock()
  local t = nowSec()
  if t == lastLockWrite then return end
  lastLockWrite = t
  pcall(function() local f = io.open(LOGDIR .. LOCK_FILE, "w"); if f then f:write(t .. " " .. MY_TOKEN); f:close() end end)
end

local function startBot()
  if otherInstanceAlive() then
    bot.msg = "Hay OTRO Train Bot corriendo en otra ventana de Lua: detenlo/cierralo primero"
    print(bot.msg); return
  end
  if bot.cfgError then bot.msg = "Corrige " .. CONFIG_FILE .. " (mira la consola) y pulsa 0"; print(bot.msg); return end
  if rec then bot.msg = "Termina de grabar la ruta (6) antes de iniciar"; return end
  if inBattle() then bot.msg = "Inicia el bot fuera de combate, en la hierba"; return end
  local m = leadOk()
  local p = playerPos()
  if not m or not p then bot.msg = "Carga tu partida (en el mapa) antes de iniciar"; print(bot.msg); return end
  bot.cbOW = read32(A.callback2)
  bot.leadSpecies = m.species
  bot.spot = route.back and route.back[#route.back] or p
  bot.running, bot.done, bot.msg = true, false, ""
  bot.battles, bot.fought, bot.fled, bot.heals = 0, 0, 0, 0
  bot.startEvs = { m.evs[1], m.evs[2], m.evs[3], m.evs[4], m.evs[5], m.evs[6] }
  bot.prevEvs = { m.evs[1], m.evs[2], m.evs[3], m.evs[4], m.evs[5], m.evs[6] }
  bot.lastGain, bot.gainBattles = nil, 0
  bot.startTime = 0
  pcall(function() bot.startTime = os.time() end)
  bot.startLevel = m.level
  logLine(string.format("Entrenamiento iniciado: %s Nv.%d  EVs %s", speciesName(m.species), m.level,
    table.concat({ m.evs[1], m.evs[2], m.evs[3], m.evs[5], m.evs[6], m.evs[4] }, "/")))
  local ws = wantedStatus(m)
  if ws then logLine("Ataques deseados: " .. ws) end
  afterBattleDecide()
end

stopBot = function()
  bot.running, bot.st = false, "idle"
  queue = {}
end

-- ------------------------------ Combate ------------------------------
local function enterBattle(returnTo)
  queue = {}
  bot.st, bot.t = "battle", 0
  bot.foe, bot.fight, bot.forceRun = nil, nil, (returnTo ~= nil)
  bot.returnTo = returnTo
  bot.blocked, bot.lastMoveSlot, bot.sawMove = {}, nil, false
  bot.outT = 0
  bot.battles = bot.battles + 1
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
      if foe.sv < 8 and CONFIG.stopOnShiny then
        stopBot()
        bot.msg = "SHINY SALVAJE: " .. speciesName(foe.species) .. "! Capturalo tu (juego en pausa)"
        logLine(bot.msg)
        notify(bot.msg)
        emu.pause()
        return
      end
      local m = lead()
      if bot.forceRun then bot.fight, bot.lastWhy = false, "camino al Centro"
      elseif m then bot.fight, bot.lastWhy = shouldFight(m, foe.species) end
      if bot.fight then bot.fought = bot.fought + 1 else bot.fled = bot.fled + 1 end
    end
  end
  if #queue > 0 then return end

  -- Escena de evolucion: el juego la muestra con gMain.inBattle todavia activo,
  -- pero con otra pantalla (callback2 distinto al del combate). Antes aqui se
  -- seguia pulsando B para los textos y eso cancelaba la evolucion.
  if bot.cbBattle and read32(A.callback2) ~= bot.cbBattle then
    bot.evoT = (bot.evoT or 0) + 1
    if CONFIG.evolve then
      local m = lead()
      if m and m.species ~= bot.leadSpecies then
        logLine(string.format("%s esta evolucionando a %s", speciesName(bot.leadSpecies), speciesName(m.species)))
        bot.st, bot.manualFrom, bot.owT = "manual", "evolve", 0
        bot.msg = "Evoluciono: termina tu la escena (textos / ataque nuevo). El bot sigue solo despues"
        notify("Tu Pokemon evoluciono a " .. speciesName(m.species) .. ": termina la escena y el bot sigue solo")
        print(bot.msg)
        pcall(emu.pause)        -- pausa: quita la pausa, termina la escena y el bot sigue solo
        return
      end
      -- La animacion avanza sola; solo si se queda en un texto mucho rato, pulsar A
      if bot.evoT > 1800 and bot.evoT % 60 == 0 then tap("A", 10) end
    else
      tap("B", 6)                                       -- mantener B cancela la evolucion
    end
    return
  end
  bot.evoT = 0

  -- Preguntas de "aprender ataque"
  local sp = read32(A.scriptPtr)
  local op = (sp >= 0x08000000 and sp < 0x0A000000) and read8(sp) or 0
  if op == OP_LEARNMOVE or op == OP_STOPLEARNING then
    local mode = bot.learnForce or tcfg.learn
    if mode == "ask" then
      local slot, new, old = planLearn()
      local idx = learnerIndex()
      local who = monAsAttacker(idx)
      bot.st, bot.manualFrom, bot.t = "manual", "learn", 0
      bot.msg = string.format("%s quiere aprender %s: decide tu", who and speciesName(who.mon.species) or "?", moveName(new))
      notify(bot.msg .. (slot and (" (el bot olvidaria " .. moveName(old) .. ")") or " (el bot no lo aprenderia)"))
      return
    end
    if op == OP_LEARNMOVE then
      local slot, new, old = nil, nil, nil
      if mode == "auto" then slot, new, old = planLearn() end
      if slot then
        -- "Olvidar un ataque para aprender X?" -> SI, y luego elegir cual en la pantalla de datos
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
      if read8(A.yesNoCursor) ~= 0 then tap("up", 6) else tap("A", 12) end  -- "Dejar de aprender?" -> SI
    end
    return
  end
  bot.learnForce = nil

  local waiting = band(read32(A.execFlags), 1) ~= 0
  local cmd = read8(A.bufferA)
  if waiting and cmd == CMD_CHOOSEACTION then
    bot.cbBattle = read32(A.callback2)
    if not bot.foe then tap("B", 6); return end
    bot.sawMove = false
    local me = battleMon(0)
    local run = not bot.fight or bot.forceRun
    if not run and me.maxHP > 0 and me.hp * 100 < me.maxHP * CONFIG.fleeBelow then run = true; bot.lastWhy = "PS muy bajos" end
    if not run and not bestMove(bot.blocked) then run = true; bot.lastWhy = "sin ataques utiles" end
    local want = run and 3 or 0
    local c = band(read8(A.actionCursor), 3)
    if c == want then tap("A", 16)
    elseif band(c, 1) ~= band(want, 1) then tap(band(want, 1) == 1 and "right" or "left", 4)
    else tap(band(want, 2) == 2 and "down" or "up", 4) end
    return
  end
  if waiting and cmd == CMD_CHOOSEMOVE then
    if bot.sawMove and bot.lastMoveSlot then
      -- volvio a pedir ataque sin pasar por el menu: ese ataque no se pudo usar
      bot.blocked[bot.lastMoveSlot] = true
    end
    local slot = bestMove(bot.blocked)
    if not slot then tap("B", 10); bot.forceRun = true; return end
    local want = slot - 1
    local c = band(read8(A.moveCursor), 3)
    if c == want then
      tap("A", 20); bot.lastMoveSlot, bot.sawMove = slot, true
    elseif band(c, 1) ~= band(want, 1) then tap(band(want, 1) == 1 and "right" or "left", 4)
    else tap(band(want, 2) == 2 and "down" or "up", 4) end
    return
  end
  -- Textos del combate: B (nunca elige SI por error ni entra en menus)
  tap("B", 10)
end

local function stepAfter()
  bot.t = bot.t + 1
  if inBattle() then enterBattle(bot.returnTo); return end
  local m = lead()
  if CONFIG.evolve and m and m.species ~= bot.leadSpecies then
    bot.st, bot.manualFrom = "manual", "evolve"
    bot.msg = "Esta evolucionando: termina tu (ataques nuevos, textos). El bot sigue solo despues"
    pcall(emu.pause)
    notify("Tu Pokemon esta evolucionando: termina la escena y el bot sigue solo")
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
      bot.st, bot.t = r, 0
      if r == "heal_go" then
        -- retomar desde donde quedo
      end
      return
    end
    afterBattleDecide()
    return
  end
  -- Fuera del mapa (textos, evolucion): B cancela la evolucion y avanza textos.
  -- En el mapa no se pulsa A (podria hablar con alguien o leer un cartel).
  if #queue == 0 and not inOverworld() then
    if CONFIG.evolve then tap("A", 10) else tap("B", 6) end
  end
  if bot.t > 5400 then halt("Aviso: no se pudo volver al mapa tras el combate") end
end

local function stepManual()
  -- El jugador decide; el bot espera a que vuelva el mapa o termine la pregunta
  if bot.manualFrom == "learn" then
    bot.t = bot.t + 1
    local sp = read32(A.scriptPtr)
    local op = (sp >= 0x08000000 and sp < 0x0A000000) and read8(sp) or 0
    if inBattle() and op ~= OP_LEARNMOVE and op ~= OP_STOPLEARNING then
      bot.msg = ""; bot.st = "battle"; return
    end
    -- Nadie respondio: decidir solo (solo si sigue en la pregunta, no en la pantalla de datos)
    local onPrompt = not bot.cbBattle or read32(A.callback2) == bot.cbBattle
    if CONFIG.askTimeout and bot.t > CONFIG.askTimeout * 60 and onPrompt and inBattle() then
      bot.learnForce = "auto"
      logLine("Sin respuesta: el bot decide solo si aprende el ataque")
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

-- Pantalla de datos: elegir el ataque que se olvida
local function stepLearnPick()
  bot.t = bot.t + 1
  if #queue > 0 then return end
  local inSummary = bot.cbBattle and read32(A.callback2) ~= bot.cbBattle
  local L = bot.learn
  if not bot.sumSeen then
    if inSummary then bot.sumSeen = true; bot.t = 0
    elseif bot.t > 90 then bot.st = "battle" end    -- el A no entro: volver a intentarlo
    return
  end
  if not inSummary then
    local who = monAsAttacker(learnerIndex())
    if who and L and who.mon.moves[L.slot] == L.new then
      logLine(string.format("%s aprendio %s (olvido %s)", speciesName(who.mon.species), moveName(L.new), moveName(L.old)))
    end
    bot.st, bot.t = "battle", 0
    return
  end
  if bot.picked or bot.t < 60 then return end        -- esperar el fundido y el grito
  local c = read8(A.sumCursor)
  local function abort(why)
    tap("B", 30); bot.picked = true; bot.learnForce = "never"
    logLine("No se aprendio " .. moveName(L.new) .. ": " .. why .. " (usa \"learnMoves\": \"ask\")")
    notify("No se pudo elegir el ataque a olvidar: " .. why)
  end
  if not bot.probe then
    -- comprobar que la direccion del cursor es la correcta: abajo debe pasar de 0 a 1
    if c == 1 then bot.probe = true
    elseif bot.t > 400 then abort("el cursor no responde")
    elseif c == 0 then tap("down", 20)
    else abort("cursor inesperado") end
    return
  end
  local want = L.slot - 1
  if c == want then tap("A", 30); bot.picked = true
  elseif bot.t > 1200 then abort("tiempo agotado")
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
    -- No alejarse del punto de entreno: si quedo a un lado, volver hacia el
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
  elseif r == "fail" then halt("No pude seguir la ruta al Centro (graba otra con 6)") end
end

local function stepNurse()
  bot.t = bot.t + 1
  if #queue > 0 then return end
  if bot.t > 60 and partyHealed() then
    bot.st, bot.t = "nurse_exit", 0
    return
  end
  if bot.t > 2400 then
    halt("No pude curar: la ida debe terminar DENTRO del Centro, frente a la enfermera (graba otra con 6)")
    return
  end
  tap("A", 14)
end

-- Casilla que cura al pisarla (zona purificada): solo cerrar el mensaje y esperar
local function stepHealTile()
  bot.t = bot.t + 1
  if #queue > 0 then return end
  if bot.t > 30 and partyHealed() then
    bot.st, bot.t = "nurse_exit", 0
    return
  end
  if bot.t > 1200 then
    halt("La casilla no curo al equipo: la ida debe terminar DENTRO de la zona que cura (graba otra con 6)")
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
    logLine("De vuelta en el punto de entreno")
    afterBattleDecide()
  elseif r == "fail" then halt("No pude volver al punto de entreno (graba otra ruta con 6)") end
end

-- ------------------------------ Teclas -------------------------------
local reportConfig
local prevKeys = {}
local function pressed(k, keys)
  return (keys[k] or keys["numpad" .. k]) and not (prevKeys[k] or prevKeys["numpad" .. k])
end
local function handleHotkeys()
  local keys = input.get()
  if pressed("7", keys) then
    if bot.running then stopBot(); bot.msg = "Detenido" else startBot() end
  elseif pressed("6", keys) then
    recHotkey()
  elseif pressed("8", keys) then
    -- Modo inspeccion: equipo 1..6, luego el rival (si hay combate), luego apagado
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
    reportConfig(ok, msg, problems)
  end
  prevKeys = keys
end

reportConfig = function(ok, msg, problems)
  bot.cfgError = (not ok) or #problems > 0
  if not ok then bot.msg = "Error en " .. CONFIG_FILE .. ": " .. tostring(msg)
  elseif msg == "no existe" then bot.msg = "No hay " .. CONFIG_FILE .. ": uso la configuracion por defecto"
  elseif #problems > 0 then bot.msg = "Config: " .. problems[1] .. (#problems > 1 and string.format(" (+%d)", #problems - 1) or "")
  else bot.msg = "Config cargada" end
  print(bot.msg)
  for i = 2, #problems do print("Config: " .. problems[i]) end
end

-- ------------------------------- Panel -------------------------------
local PHASE = { idle = "Detenido", walk = "Buscando combate", battle = "Combate", after = "Fin del combate",
  heal_tile = "Curando", manual = "Esperando tu decision", learn_pick = "Aprendiendo ataque", heal_go = "Yendo al Centro", nurse = "Curando", nurse_exit = "Curando",
  heal_back = "Volviendo al punto" }

-- Bloque de progreso de EVs: barra por estadistica, total, sesion, ritmo y tiempo estimado
local function evBlock(m, line)
  local shown = 0
  for st = 1, 6 do
    local i = EV_OF_STAT[st]
    local tgt = tcfg.target and tcfg.target[i] or 0
    if tgt > 0 or m.evs[i] > 0 then
      local cap = (tgt > 0) and tgt or 255
      local filled = math.min(floor(m.evs[i] * 12 / cap + 0.5), 12)
      local bar = string.rep("#", filled) .. string.rep("-", 12 - filled)
      local gained = bot.startEvs and (m.evs[i] - bot.startEvs[i]) or 0
      local color = nil
      if tgt > 0 and m.evs[i] >= tgt then color = "green" elseif tgt == 0 and m.evs[i] > 0 then color = "orange" end
      line(string.format("%-3s %3d/%-3s [%s]%s", STAT_LABEL[st], m.evs[i], tgt > 0 and tostring(tgt) or "-", bar,
        gained > 0 and ("  +" .. gained) or ""), color)
      shown = shown + 1
    end
  end
  if shown == 0 then line("EVs: 0 (aun no gana ninguno)") end
  local total = evTotal(m)
  local txt = string.format("Total %d/510", total)
  if bot.startEvs and bot.running then
    local gained = 0
    for i = 1, 6 do gained = gained + (m.evs[i] - bot.startEvs[i]) end
    local secs = 0
    pcall(function() secs = os.time() - (bot.startTime or os.time()) end)
    txt = txt .. string.format("  sesion +%d", gained)
    if gained > 0 and secs >= 60 then
      local perH = gained * 3600 / secs
      txt = txt .. string.format("  ~%d/h", floor(perH + 0.5))
      if tcfg.target then
        local left = 0
        for i = 1, 6 do left = left + math.max(tcfg.target[i] - m.evs[i], 0) end
        if left > 0 then
          local eta = floor(left / perH * 60 + 0.5)
          txt = txt .. string.format("  faltan %d (~%dh%02dm)", left, floor(eta / 60), eta % 60)
        end
      end
    end
  end
  line(txt)
  if bot.lastGain and bot.running then line("Ultimo: " .. bot.lastGain) end
end

local function evLine(m)
  local t = {}
  for s = 1, 6 do
    local i = EV_OF_STAT[s]
    if tcfg.target then
      if tcfg.target[i] > 0 or m.evs[i] > 0 then t[#t + 1] = string.format("%s %d/%d", STAT_LABEL[s], m.evs[i], tcfg.target[i]) end
    elseif m.evs[i] > 0 then t[#t + 1] = string.format("%s %d", STAT_LABEL[s], m.evs[i]) end
  end
  if #t == 0 then return "EVs: 0" end
  return "EVs " .. table.concat(t, "  ")
end

-- ------------------------- Modo inspeccion ---------------------------
local NATURE_STAT = { "At", "Df", "Vel", "AtE", "DfE" }   -- orden de naturaleza en el juego
local function drawInspect()
  local which = bot.inspect
  local addr = (which == 7) and A.enemy or (A.party + (which - 1) * 0x64)
  local m = readPartyMon(addr)
  local y = 1
  local function line(text, color) gui.text(1, y, text, color); y = y + 9 end
  local title = (which == 7) and "Rival" or string.format("Equipo %d/%d", which, partyCount())
  if not m then line(title .. ": vacio  (8 = siguiente)"); return end
  local shiny = m.sv < 8
  local nat = m.pid % 25
  local natName = natureNamesList[nat + 1] or "?"
  local up, down = floor(nat / 5) + 1, (nat % 5) + 1
  local natFx = (up == down) and "neutra" or string.format("+%s -%s", NATURE_STAT[up], NATURE_STAT[down])
  local sx = TT_SPECX[m.species]
  local gender = ""
  if sx then
    local gr = sx[3]
    if gr == 255 then gender = "" elseif gr == 0 then gender = " M" elseif gr == 254 then gender = " F"
    else gender = (band(m.pid, 0xFF) < gr) and " F" or " M" end
  end
  local abilId = sx and ((m.abilityBit == 1 and sx[2] ~= 0) and sx[2] or sx[1]) or 0
  line(string.format("%s: %s%s Nv.%d%s", title, speciesName(m.species), gender, m.level, shiny and "  * SHINY *" or ""),
       shiny and "green" or nil)
  line(string.format("%s (%s)  Hab: %s", natName, natFx, TT_ABILNAME[abilId] or "?"))
  -- Stats reales (en memoria: PS max 0x58, At 0x5A, Df 0x5C, Vel 0x5E, AtE 0x60, DfE 0x62)
  local st = { read16(addr + 0x58), read16(addr + 0x5A), read16(addr + 0x5C), read16(addr + 0x60), read16(addr + 0x62),
               read16(addr + 0x5E) }
  local ev = { m.evs[1], m.evs[2], m.evs[3], m.evs[5], m.evs[6], m.evs[4] }   -- orden de pantalla
  local function row(label, t, fmt)
    local parts = {}
    for i = 1, 6 do parts[i] = string.format(fmt or "%4d", t[i]) end
    return string.format("%-5s", label) .. table.concat(parts)
  end
  local hdr = { "PS", "At", "Df", "AtE", "DfE", "Vel" }
  line(row("", hdr, "%4s"))
  local statColor = {}
  line(row("Stat", st))
  local perfect = true
  for i = 1, 6 do if m.ivs[i] < 31 then perfect = false end end
  line(row("IV", m.ivs), perfect and "green" or nil)
  local tot = 0
  for i = 1, 6 do tot = tot + ev[i] end
  line(row("EV", ev) .. string.format("  (%d/510)", tot))
  local hpType, hpPow = hiddenPower(m.ivWord)
  line(string.format("PS %d/%d  Poder Oculto: %s %d", m.hp, m.maxHP, TYPE_NAMES[hpType] or "?", hpPow))
  local pkr = (m.pokerus == 0) and "no" or ((band(m.pokerus, 0x0F) > 0) and "SI (activo)" or "lo tuvo")
  line(string.format("Exp %d  Amistad %d  Pokerus %s", m.exp, m.friendship, pkr))
  line(string.format("Objeto: %s", m.item == 0 and "-" or (TT_ITEMNAME[m.item] or ("#" .. m.item))))
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
  line(string.format("PID %08X  TID %d  SID %d   (8 = siguiente)", m.pid, otid, floor(m.otid / 0x10000)))
end

local function draw()
  if bot.inspect and bot.inspect > 0 then drawInspect(); return end
  if bot.panel == 0 then return end
  local y = 1
  local function line(text, color) gui.text(1, y, text, color); y = y + 9 end
  local status = bot.done and "COMPLETO" or (bot.running and (PHASE[bot.st] or bot.st) or "OFF")
  if rec then status = (rec.phase == "go") and "GRABANDO IDA" or "GRABANDO VUELTA" end
  line("Entrenar v1.10: " .. status, (bot.done or rec) and "green" or nil)
  local m = lead()
  if m then
    local lv = CONFIG.targetLevel and string.format("Nv.%d/%d", m.level, CONFIG.targetLevel) or ("Nv." .. m.level)
    line(string.format("%s %s  PS %d/%d  PP %d", speciesName(m.species), lv, m.hp, m.maxHP, usefulPP(m)))
    evBlock(m, line)
    if tcfg.wanted and (bot.panel == 2 or not bot.running) then line("Ataques: " .. (wantedStatus(m) or "")) end
  end
  if bot.panel == 2 or not bot.running then
    if not bot.running and not rec then
      line(string.format("7 iniciar  6 ruta  8 ver Pokemon  9 panel  0 config   Ruta: %s",
        route.go and string.format("%d/%d pasos", #route.go, #route.back) or "no grabada"))
    end
    line(string.format("Combates %d  peleados %d  huidos %d  curas %d", bot.battles, bot.fought, bot.fled, bot.heals))
  end
  if bot.lastFoe and bot.running then
    line(string.format("Rival: %s Nv.%d  -> %s (%s)", speciesName(bot.lastFoe.species), bot.lastFoe.level,
      bot.fight and "pelear" or "huir", bot.lastWhy or ""))
    if bot.panel == 2 and bot.st == "battle" and inBattle() then
      local slot = bestMove(bot.blocked)
      local me = battleMon(0)
      if slot then line("Ataque: " .. (TT_MOVE[me.moves[slot]] and TT_MOVE[me.moves[slot]][7] or "?")) end
    end
  end
  if bot.panel == 2 then
    -- Para revisar las direcciones en otros idiomas: en el menu LUCHA/HUIR "Menu" debe ser 18 y "Espera" 1
    local p = playerPos()
    line(string.format("Menu %d  Espera %d  Cursor %d/%d  Combate %d  Pos %s", read8(A.bufferA),
      band(read32(A.execFlags), 1), band(read8(A.actionCursor), 3), band(read8(A.moveCursor), 3),
      inBattle() and 1 or 0, p and string.format("%d.%d (%d,%d)", p.g, p.n, p.x, p.y) or "?"))
  end
  if bot.msg ~= "" then gui.text(1, 150, bot.msg, "orange") end
end

-- ------------------------------- Inicio ------------------------------
print("FRLG Train Bot v1.10")
if not gameName then
  print("Este ROM no es Rojo Fuego / Verde Hoja. El bot no se ejecutara.")
  return
end
print(string.format("Juego: %s", GAME_LABEL))
print("7 = iniciar/detener   6 = grabar ruta al Centro   8 = ver Pokemon (stats)   9 = panel   0 = recargar " .. CONFIG_FILE)
reportConfig(cfgOk, cfgMsg, cfgProblems)
if route.go then print(string.format("Ruta al Centro cargada: %d pasos de ida, %d de vuelta", #route.go, #route.back)) end

local badFrames = 0
while true do
  gFrame = gFrame + 1
  handleHotkeys()
  recStep()
  if bot.running then
    if otherInstanceAlive() then halt("Hay OTRO Train Bot corriendo en otra ventana de Lua: deja solo uno") end
  end
  if bot.running then
    writeLock()
    if validPtr(read32(A.sb1)) then badFrames = 0 else badFrames = badFrames + 1 end
    if badFrames > 30 then halt("El juego se reinicio: bot detenido") end
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
    elseif st == "learn_pick" then stepLearnPick() end
    if not busy then runQueue() end
  end
  draw()
  emu.frameadvance()
end
