-- ===================================================================
--  FRLG Shiny Bot v4.3  (Rojo Fuego / Verde Hoja - VBA-ReRecording)
--
--  Usa las direcciones de memoria de "FRLG_RNG_2.0.lua"
--  (Devon Studios x Real.96). Este archivo es independiente:
--  carga SOLO este script, no los dos a la vez.
--
--  Teclas (teclado, no el control del juego):
--    7 = iniciar / detener el bot
--    8 = cambiar de modo (solo con el bot detenido)
--    9 = mostrar / ocultar el panel
--
--  Modos:
--    Salvaje  : camina de lado a lado, revisa cada encuentro y huye
--    Estatico : soft reset + A hasta que empieza el combate
--               (Snorlax, Mewtwo, aves legendarias, Hypno no, etc.)
--    Regalo   : soft reset + A hasta recibir el Pokemon
--               (iniciales, Eevee, Lapras, fosiles, Hitmon, Magikarp...)
--    Roamer   : soft reset + A hasta que se activa el perro legendario
-- ===================================================================

-- ============================ CONFIGURACION =========================
local CONFIG = {
  -- Que buscar (se puede cambiar en FRLG_ShinyBot.json)
  shiny         = true,         -- false = no exigir shiny (solo naturaleza/IVs)
  species       = nil,          -- solo salvajes, ej. {"Magnemite"}
  natures       = nil,          -- ej. {"Modest","Timid"} (ingles o espanol)
  minIVs        = nil,          -- ej. {hp=31, spa=31}
  maxIVs        = nil,          -- ej. {atk=0}
  minIVTotal    = nil,
  hiddenPower   = nil,          -- ej. {type="Fire", minPower=60}
  mode          = nil,          -- modo al iniciar, ej. "Salvaje RNG"

  -- Caminar
  walkAxis      = "horizontal", -- "horizontal" (izq/der) o "vertical" (arriba/abajo)
  walkFrames    = 16,           -- frames por paso (16 = 1 casilla caminando)
  holdB         = false,        -- correr con B (solo modo Salvaje normal)

  -- Soft reset
  pressGapMin   = 2,
  pressGapMax   = 24,
  resetTimeout  = 5400,

  -- RNG
  farSearch     = 20000000,     -- avances a revisar buscando el objetivo
  teachy        = true,         -- usar la Tele Pokemon (registrada en SELECT) si esta lejos
  teachyBeyond  = 5000,         -- usar la Tele si ahorra mas de estos avances de espera
  teachyMargin  = nil,          -- cerrarla estos avances antes; nil = automatico (retraso + 1500)
  triesPerTarget = 10,          -- intentos de correccion por objetivo
  reseed        = true,         -- soft reset y otra semilla si no hay objetivo / fallan varios
  reseedAfterFailedTargets = 3,
  maxReseeds    = 10,
  newGameTSV    = nil,
  initialSeeds  = nil,          -- Semilla inicial: lista en hex, ej. {"BC75","0A16"}
  afterSeedMode = nil,          -- modo a lanzar al caer en la semilla, ej. "Regalo RNG"          -- Partida nueva: rangos de TID xor SID (nil = los de Ditto 6x31 shiny)
  rngMaxSearch  = nil,          -- (obsoleto, se ignora)
  wildMaxSearch = nil,          -- (obsoleto, se ignora)
  wildOneStep   = true,         -- Salvaje RNG: acercarse a un paso del encuentro antes de buscar el frame
  reseedBeyond  = nil,          -- (obsoleto, se ignora)

  -- Al encontrar / varias instancias
  savestateSlot = nil,          -- nil = no guardar solo (en VBA-rr v22 da "Error creating file")
  logFile       = "shiny_log.txt",
  stopOthers    = true,
  sharedDir     = nil,
  logDir        = "logs",       -- subcarpeta para el log y los archivos de trabajo
  resetOnLoad   = true,
}
local CONFIG_FILE = "FRLG_ShinyBot.json"
-- ====================================================================

local read32  = memory.readdwordunsigned
local read16  = memory.readwordunsigned
local read8   = memory.readbyte
local write32 = memory.writedword
local write8  = memory.writebyte
local rshift, band, bxor = bit.rshift, bit.band, bit.bxor
local floor = math.floor

local natureNamesList = {
 "Hardy", "Lonely", "Brave", "Adamant", "Naughty",
 "Bold", "Docile", "Relaxed", "Impish", "Lax",
 "Timid", "Hasty", "Serious", "Jolly", "Naive",
 "Modest", "Mild", "Quiet", "Bashful", "Rash",
 "Calm", "Gentle", "Sassy", "Careful", "Quirky"}
local speciesNamesList = {
 -- Gen 1
 "Bulbasaur", "Ivysaur", "Venusaur", "Charmander", "Charmeleon", "Charizard", "Squirtle", "Wartortle", "Blastoise",
 "Caterpie", "Metapod", "Butterfree", "Weedle", "Kakuna", "Beedrill", "Pidgey", "Pidgeotto", "Pidgeot", "Rattata",
 "Raticate", "Spearow", "Fearow", "Ekans", "Arbok", "Pikachu", "Raichu", "Sandshrew", "Sandslash", "Nidoran F",
 "Nidorina", "Nidoqueen", "Nidoran M", "Nidorino", "Nidoking", "Clefairy", "Clefable", "Vulpix", "Ninetales",
 "Jigglypuff", "Wigglytuff", "Zubat", "Golbat", "Oddish", "Gloom", "Vileplume", "Paras", "Parasect", "Venonat",
 "Venomoth", "Diglett", "Dugtrio", "Meowth", "Persian", "Psyduck", "Golduck", "Mankey", "Primeape", "Growlithe",
 "Arcanine", "Poliwag", "Poliwhirl", "Poliwrath", "Abra", "Kadabra", "Alakazam", "Machop", "Machoke", "Machamp",
 "Bellsprout", "Weepinbell", "Victreebel", "Tentacool", "Tentacruel", "Geodude", "Graveler", "Golem", "Ponyta",
 "Rapidash", "Slowpoke", "Slowbro", "Magnemite", "Magneton", "Farfetch'd", "Doduo", "Dodrio", "Seel", "Dewgong",
 "Grimer", "Muk", "Shellder", "Cloyster", "Gastly", "Haunter", "Gengar", "Onix", "Drowzee", "Hypno", "Krabby",
 "Kingler", "Voltorb", "Electrode", "Exeggcute", "Exeggutor", "Cubone", "Marowak", "Hitmonlee", "Hitmonchan",
 "Lickitung", "Koffing", "Weezing", "Rhyhorn", "Rhydon", "Chansey", "Tangela", "Kangaskhan", "Horsea", "Seadra",
 "Goldeen", "Seaking", "Staryu", "Starmie", "Mr. Mime", "Scyther", "Jynx", "Electabuzz", "Magmar", "Pinsir", "Tauros",
 "Magikarp", "Gyarados", "Lapras", "Ditto", "Eevee", "Vaporeon", "Jolteon", "Flareon", "Porygon", "Omanyte", "Omastar",
 "Kabuto", "Kabutops", "Aerodactyl", "Snorlax", "Articuno", "Zapdos", "Moltres", "Dratini", "Dragonair", "Dragonite",
 "Mewtwo", "Mew",
 -- Gen 2
 "Chikorita", "Bayleef", "Meganium", "Cyndaquil", "Quilava", "Typhlosion", "Totodile", "Croconaw", "Feraligatr",
 "Sentret", "Furret", "Hoothoot", "Noctowl", "Ledyba", "Ledian", "Spinarak", "Ariados", "Crobat", "Chinchou", "Lanturn",
 "Pichu", "Cleffa", "Igglybuff", "Togepi", "Togetic", "Natu", "Xatu", "Mareep", "Flaaffy", "Ampharos", "Bellossom",
 "Marill", "Azumarill", "Sudowoodo", "Politoed", "Hoppip", "Skiploom", "Jumpluff", "Aipom", "Sunkern", "Sunflora",
 "Yanma", "Wooper", "Quagsire", "Espeon", "Umbreon", "Murkrow", "Slowking", "Misdreavus", "Unown", "Wobbuffet",
 "Girafarig", "Pineco", "Forretress", "Dunsparce", "Gligar", "Steelix", "Snubbull", "Granbull", "Qwilfish", "Scizor",
 "Shuckle", "Heracross", "Sneasel", "Teddiursa", "Ursaring", "Slugma", "Magcargo", "Swinub", "Piloswine", "Corsola",
 "Remoraid", "Octillery", "Delibird", "Mantine", "Skarmory", "Houndour", "Houndoom", "Kingdra", "Phanpy", "Donphan",
 "Porygon2", "Stantler", "Smeargle", "Tyrogue", "Hitmontop", "Smoochum", "Elekid", "Magby", "Miltank", "Blissey",
 "Raikou", "Entei", "Suicune", "Larvitar", "Pupitar", "Tyranitar", "Lugia", "Ho-Oh", "Celebi",
 -- Gen 3
 "Treecko", "Grovyle", "Sceptile", "Torchic", "Combusken", "Blaziken", "Mudkip", "Marshtomp", "Swampert", "Poochyena",
 "Mightyena", "Zigzagoon", "Linoone", "Wurmple", "Silcoon", "Beautifly", "Cascoon", "Dustox", "Lotad", "Lombre", "Ludicolo",
 "Seedot", "Nuzleaf", "Shiftry", "Taillow", "Swellow", "Wingull", "Pelipper", "Ralts", "Kirlia", "Gardevoir", "Surskit",
 "Masquerain", "Shroomish", "Breloom", "Slakoth", "Vigoroth", "Slaking", "Nincada", "Ninjask", "Shedinja", "Whismur",
 "Loudred", "Exploud", "Makuhita", "Hariyama", "Azurill", "Nosepass", "Skitty", "Delcatty", "Sableye", "Mawile", "Aron",
 "Lairon", "Aggron", "Meditite", "Medicham", "Electrike", "Manectric", "Plusle", "Minun", "Volbeat", "Illumise", "Roselia",
 "Gulpin", "Swalot", "Carvanha", "Sharpedo", "Wailmer", "Wailord", "Numel", "Camerupt", "Torkoal", "Spoink", "Grumpig",
 "Spinda", "Trapinch", "Vibrava", "Flygon", "Cacnea", "Cacturne", "Swablu", "Altaria", "Zangoose", "Seviper", "Lunatone",
 "Solrock", "Barboach", "Whiscash", "Corphish", "Crawdaunt", "Baltoy", "Claydol", "Lileep", "Cradily", "Anorith", "Armaldo",
 "Feebas", "Milotic", "Castform", "Kecleon", "Shuppet", "Banette", "Duskull", "Dusclops", "Tropius", "Chimecho", "Absol",
 "Wynaut", "Snorunt", "Glalie", "Spheal", "Sealeo", "Walrein", "Clamperl", "Huntail", "Gorebyss", "Relicanth", "Luvdisc",
 "Bagon", "Shelgon", "Salamence", "Beldum", "Metang", "Metagross", "Regirock", "Regice", "Registeel", "Latias", "Latios",
 "Kyogre", "Groudon", "Rayquaza", "Jirachi", "Deoxys"}
local nationalDexList = {
 1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26,
 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50,
 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74,
 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99,
 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119,
 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139,
 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159,
 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179,
 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199,
 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219,
 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239,
 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 387, 388, 389, 390, 391, 392, 393, 394,
 395, 396, 397, 398, 399, 400, 401, 402, 403, 404, 405, 406, 407, 408, 409, 410, 411, 252, 253, 254,
 255, 256, 257, 258, 259, 260, 261, 262, 263, 264, 265, 266, 267, 268, 269, 270, 271, 272, 273, 274,
 275, 290, 291, 292, 276, 277, 285, 286, 327, 278, 279, 283, 284, 320, 321, 300, 301, 352, 343, 344,
 299, 324, 302, 339, 340, 370, 341, 342, 349, 350, 318, 319, 328, 329, 330, 296, 297, 309, 310, 322,
 323, 363, 364, 365, 331, 332, 361, 362, 337, 338, 298, 325, 326, 311, 312, 303, 307, 308, 333, 334,
 360, 355, 356, 315, 287, 288, 289, 316, 317, 357, 293, 294, 295, 366, 367, 368, 359, 353, 354, 336,
 335, 369, 304, 305, 306, 351, 313, 314, 345, 346, 347, 348, 280, 281, 282, 371, 372, 373, 374, 375,
 376, 377, 378, 379, 382, 383, 384, 380, 381, 385, 386, 358}


-- ------------------------- Version / direcciones ---------------------
local gameCode = read8(0x080000AE)
local gameLang = read8(0x080000AF)
local gameRev1 = read8(0x080000BC) == 0x1
local gameName = (gameCode == 0x52 and "FireRed") or (gameCode == 0x47 and "LeafGreen") or nil

local A = {}
local gMainVerified = false
if gameLang == 0x45 then        -- USA
  A.currSeed = 0x03005000
  A.enemy    = 0x0202402C
  A.party    = 0x02024284
  A.partyCnt = 0x02024029
  A.sb1      = 0x03005008
  A.sb2      = 0x0300500C
  A.gMain    = 0x030030F0
  gMainVerified = true
elseif gameLang == 0x4A then    -- JPN
  if gameRev1 then
    A.currSeed, A.sb1, A.sb2 = 0x03004FA0, 0x03004FA8, 0x03004FAC
  else
    A.currSeed, A.sb1, A.sb2 = 0x03005040, 0x03005048, 0x0300504C
  end
  A.enemy    = 0x02023F8C
  A.party    = 0x020241E4
  A.partyCnt = 0x02023F89
else                            -- EUR (ESP, FRA, ITA, GER)
  A.currSeed = 0x03004F50
  A.enemy    = 0x0202402C
  A.party    = 0x02024284
  A.partyCnt = 0x02024029
  A.sb1      = 0x03004F58
  A.sb2      = 0x03004F5C
end
if not A.gMain then
  -- Estimado: misma distancia que en USA entre gMain y la semilla del RNG.
  -- Revisa en el panel que "Combate" cambie a 1 dentro de una batalla.
  A.gMain = A.currSeed - 0x1F10
end
A.inBattleByte = A.gMain + 0x439   -- gMain.inBattle (bit 1)
-- Verificados con el mapa de simbolos de pokefirered (USA). En otros
-- idiomas se calculan con la misma distancia a gEnemyParty.
A.actionCursor  = A.enemy - 0x34   -- gActionSelectionCursor[0] (0x02023FF8 en USA)
A.battleOutcome = A.enemy - 0x1A2  -- gBattleOutcome (0x02023E8A en USA), 4 = huyo

-- ------------------------------ Utilidades ---------------------------
-- Carpeta de este script (alli se busca el .json)
local SCRIPT_DIR = ""
pcall(function()
  local src = debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then SCRIPT_DIR = src:sub(2):match("^(.*[/\\])") or "" end
end)

-- ------------------------- Lector de JSON ----------------------------
-- JSON normal, y ademas acepta comentarios // hasta el final de la linea.
local function jsonDecode(str)
  local pos = 1
  local function err(msg) error(string.format("JSON: %s (caracter %d)", msg, pos), 0) end
  local function skip()
    while true do
      local _, e = str:find("^[ \t\r\n]+", pos)
      if e then pos = e + 1 end
      if str:sub(pos, pos + 1) == "//" then
        local nl = str:find("\n", pos) or (#str + 1)
        pos = nl + 1
      else
        return
      end
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
      if c == "\\" then
        local n = str:sub(pos + 1, pos + 1)
        local map = { n = "\n", t = "\t", r = "\r", b = "\b", f = "\f" }
        out[#out + 1] = map[n] or n
        pos = pos + 2
      else
        out[#out + 1] = c; pos = pos + 1
      end
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
        local d = str:sub(pos, pos)
        pos = pos + 1
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
        local d = str:sub(pos, pos)
        pos = pos + 1
        if d == "]" then return arr end
        if d ~= "," then err("falta ',' o ']'") end
        skip()
        if str:sub(pos, pos) == "]" then pos = pos + 1; return arr end
      end
    elseif c == '"' then
      return parseString()
    elseif str:sub(pos, pos + 3) == "true" then pos = pos + 4; return true
    elseif str:sub(pos, pos + 4) == "false" then pos = pos + 5; return false
    elseif str:sub(pos, pos + 3) == "null" then pos = pos + 4; return nil
    else
      local num = str:match("^-?%d+%.?%d*[eE]?[-+]?%d*", pos)
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

-- --------------------- Normalizar nombres y filtros ------------------
local function simplify(name)
  name = tostring(name):lower()
  local acc = { ["\195\161"] = "a", ["\195\169"] = "e", ["\195\173"] = "i", ["\195\179"] = "o",
                ["\195\186"] = "u", ["\195\177"] = "n", ["\195\129"] = "a", ["\195\137"] = "e",
                ["\195\141"] = "i", ["\195\147"] = "o", ["\195\154"] = "u", ["\195\145"] = "n" }
  for k, v in pairs(acc) do name = name:gsub(k, v) end
  return (name:gsub("[^%w]", ""))
end

local NATURES_ES = {
  fuerte = "Hardy", hurana = "Lonely", audaz = "Brave", firme = "Adamant", picara = "Naughty",
  osada = "Bold", docil = "Docile", placida = "Relaxed", agitada = "Impish", floja = "Lax",
  miedosa = "Timid", activa = "Hasty", seria = "Serious", alegre = "Jolly", ingenua = "Naive",
  modesta = "Modest", afable = "Mild", mansa = "Quiet", timida = "Bashful", alocada = "Rash",
  serena = "Calm", amable = "Gentle", grosera = "Sassy", cauta = "Careful", rara = "Quirky" }

local STAT_KEYS = { hp = 1, ps = 1, atk = 2, ata = 2, attack = 2, ataque = 2, def = 3, defense = 3, defensa = 3,
  spa = 4, spatk = 4, ate = 4, atesp = 4, ataqueespecial = 4, spd = 5, spdef = 5, dfe = 5, defesp = 5,
  defensaespecial = 5, spe = 6, speed = 6, vel = 6, velocidad = 6 }

local HP_TYPES = { "Fighting", "Flying", "Poison", "Ground", "Rock", "Bug", "Ghost", "Steel",
                   "Fire", "Water", "Grass", "Electric", "Psychic", "Ice", "Dragon", "Dark" }
local HP_TYPES_ES = { lucha = 1, volador = 2, veneno = 3, tierra = 4, roca = 5, bicho = 6, fantasma = 7,
  acero = 8, fuego = 9, agua = 10, planta = 11, electrico = 12, psiquico = 13, hielo = 14, dragon = 15, siniestro = 16 }

local filt = {}     -- filtros ya interpretados

local function toList(v)
  if v == nil then return nil end
  if type(v) ~= "table" then return { v } end
  if #v == 0 then return nil end
  return v
end

local function buildFilters(problems)
  filt = { shiny = CONFIG.shiny ~= false }
  local nl = toList(CONFIG.natures)
  if nl then
    filt.natures = {}
    for _, n in ipairs(nl) do
      local sn, found = simplify(n), nil
      for _, en in ipairs(natureNamesList) do if simplify(en) == sn then found = en end end
      found = found or NATURES_ES[sn]
      if found then filt.natures[found] = true else problems[#problems + 1] = "naturaleza desconocida: " .. tostring(n) end
    end
  end
  local sl = toList(CONFIG.species)
  if sl then
    filt.species = {}
    for _, n in ipairs(sl) do
      local sn, found = simplify(n), false
      for _, en in ipairs(speciesNamesList) do if simplify(en) == sn then filt.species[sn] = true; found = true end end
      if not found then problems[#problems + 1] = "especie desconocida: " .. tostring(n) end
    end
  end
  filt.minIV, filt.maxIV = { 0, 0, 0, 0, 0, 0 }, { 31, 31, 31, 31, 31, 31 }
  for which, src in pairs({ minIV = CONFIG.minIVs, maxIV = CONFIG.maxIVs }) do
    if type(src) == "table" then
      for k, v in pairs(src) do
        local i = STAT_KEYS[simplify(k)]
        if i and tonumber(v) then filt[which][i] = tonumber(v)
        else problems[#problems + 1] = "IV desconocido: " .. tostring(k) end
      end
    end
  end
  filt.minIVTotal = tonumber(CONFIG.minIVTotal)
  local hp = CONFIG.hiddenPower
  if type(hp) == "table" then
    if hp.type then
      local sn = simplify(hp.type)
      for i, t in ipairs(HP_TYPES) do if simplify(t) == sn then filt.hpType = i end end
      filt.hpType = filt.hpType or HP_TYPES_ES[sn]
      if not filt.hpType then problems[#problems + 1] = "tipo de Poder Oculto desconocido: " .. tostring(hp.type) end
    end
    filt.hpPower = tonumber(hp.minPower)
  end
end

local function loadConfig()
  local problems = {}
  local ok, msg = pcall(function()
    local f = io.open(SCRIPT_DIR .. CONFIG_FILE, "r")
    if not f then return "no existe" end
    local data = f:read("*a"); f:close()
    local cfg = jsonDecode(data)
    if type(cfg) ~= "table" then error("el archivo debe ser un objeto { ... }", 0) end
    for k, v in pairs(cfg) do
      local optional = { species = 1, natures = 1, minIVs = 1, maxIVs = 1, minIVTotal = 1, hiddenPower = 1,
        mode = 1, sharedDir = 1, savestateSlot = 1, newGameTSV = 1, initialSeeds = 1, afterSeedMode = 1, rngMaxSearch = 1, wildMaxSearch = 1, reseedBeyond = 1, teachyMargin = 1 }
      if CONFIG[k] == nil and not optional[k] then
        problems[#problems + 1] = "opcion desconocida: " .. k
      end
      CONFIG[k] = v
    end
    -- null en el JSON = quitar el valor
    for _, k in ipairs({ "species", "natures", "minIVs", "maxIVs", "minIVTotal", "hiddenPower", "mode", "sharedDir" }) do
      if cfg[k] == nil then CONFIG[k] = nil end
    end
    return "ok"
  end)
  buildFilters(problems)
  return ok, msg, problems
end

-- Carpeta compartida entre instancias (por defecto, donde esta este script)
local cfgOk, cfgMsg, cfgProblems = loadConfig()
local SHARED = CONFIG.sharedDir
if not SHARED then
  SHARED = SCRIPT_DIR
elseif not SHARED:match("[/\\]$") then
  SHARED = SHARED .. "/"
end

-- Carpeta de archivos generados (log, avisos entre instancias, reservas)
local IS_WINDOWS = package and package.config and package.config:sub(1, 1) == "\\"
local LOGDIR = SHARED
if CONFIG.logDir and CONFIG.logDir ~= "" then
  LOGDIR = SHARED .. tostring(CONFIG.logDir):gsub("[/\\]+$", "") .. "/"
end
local function dirWritable(dir)
  local ok = false
  pcall(function()
    local f = io.open(dir .. ".write_test", "w")
    if f then f:close(); os.remove(dir .. ".write_test"); ok = true end
  end)
  return ok
end
if not dirWritable(LOGDIR) then
  pcall(function()
    local d = LOGDIR:gsub("/$", "")
    if d:find('["%%$`]') then return end   -- no pasar al shell rutas con comillas o variables
    if IS_WINDOWS then
      os.execute('mkdir "' .. d:gsub("/", "\\") .. '" 2>nul')
    else
      os.execute('mkdir -p "' .. d .. '" 2>/dev/null')
    end
  end)
  if not dirWritable(LOGDIR) then LOGDIR = SHARED end   -- si no se pudo crear, usar la carpeta del script
end

local function readFile(name)
  local ok, data = pcall(function()
    local f = io.open(LOGDIR .. name, "r")
    if not f then return nil end
    local d = f:read("*a"); f:close(); return d
  end)
  return ok and data or nil
end
local function writeFile(name, text, mode)
  pcall(function()
    local f = io.open(LOGDIR .. name, mode or "w")
    if f then f:write(text); f:close() end
  end)
end

local now = 0
pcall(function() now = os.time() end)

-- Semilla distinta en cada instancia (si no, todas harian exactamente lo mismo)
do
  local h = 0
  for c in tostring({}):gmatch(".") do h = (h * 31 + c:byte()) % 2147483647 end
  local clk = 0
  pcall(function() clk = floor(os.clock() * 1000) end)
  math.randomseed((now + h + clk) % 2147483647)
  for _ = 1, 5 do math.random() end
end
local TOKEN = string.format("%04x%04x%04x", math.random(0, 65535), math.random(0, 65535), math.random(0, 65535))

-- Numero de instancia: cada ventana "reserva" un numero libre (inst_N.lock)
-- y lo renueva cada pocos segundos. Al cerrar o recargar el script se libera,
-- asi que recargar en la misma ventana conserva el mismo numero.
local INSTANCE = 1
local function lockName(n) return "inst_" .. n .. ".lock" end
do
  for n = 1, 32 do
    local data = readFile(lockName(n))
    local t, tok = nil, nil
    if data then t, tok = data:match("(%d+)%s+(%w+)") end
    t = tonumber(t)
    if not t or now - t > 8 or tok == TOKEN then
      INSTANCE = n
      writeFile(lockName(n), now .. " " .. TOKEN)
      break
    end
  end
end
-- Limpieza al cargar: borrar reservas viejas y, si no hay otra ventana
-- activa, el aviso de shiny de la corrida anterior. El log se conserva.
do
  local othersAlive = false
  for n = 1, 32 do
    if n ~= INSTANCE then
      local data = readFile(lockName(n))
      if data then
        local t = tonumber(data:match("(%d+)"))
        if t and now - t <= 8 then othersAlive = true
        else pcall(function() os.remove(LOGDIR .. lockName(n)) end) end
      end
    end
  end
  if not othersAlive then pcall(function() os.remove(LOGDIR .. "shiny_stop.flag") end) end
  -- Archivos de versiones anteriores que quedaban sueltos junto al script
  if LOGDIR ~= SHARED then
    pcall(function()
      local old = io.open(SHARED .. CONFIG.logFile, "r")
      if old then
        local d = old:read("*a"); old:close()
        local f = io.open(LOGDIR .. CONFIG.logFile, "a")
        if f then f:write(d); f:close(); os.remove(SHARED .. CONFIG.logFile) end
      end
    end)
    for _, name in ipairs({ "shiny_stop.flag", "bot_instances.txt" }) do
      pcall(function() os.remove(SHARED .. name) end)
    end
    for n = 1, 32 do pcall(function() os.remove(SHARED .. lockName(n)) end) end
  end
end

local lastBeat = now
local function heartbeat()
  local t = now
  pcall(function() t = os.time() end)
  if t - lastBeat >= 2 then
    lastBeat = t
    writeFile(lockName(INSTANCE), t .. " " .. TOKEN)
  end
end
pcall(function()
  emu.registerexit(function()
    pcall(function() os.remove(LOGDIR .. lockName(INSTANCE)) end)
  end)
end)

local function validPtr(p) return p >= 0x02000000 and p < 0x02040000 end

local function getMiscOffset(o)
  if o >= 18 then return 0 elseif o % 6 >= 4 then return 12
  elseif o % 2 == 1 then return 24 else return 36 end
end
local function getGrowthOffset(o)
  if o <= 5 then return 0 elseif o % 6 <= 1 then return 12
  elseif o % 2 == 0 then return 24 else return 36 end
end

local function shinyValue(pid, tid, sid)
  return bxor(bxor(tid, sid), bxor(pid % 0x10000, floor(pid / 0x10000)))
end

local function ivsFromWord(w)
  return { band(w, 0x1F), band(rshift(w, 5), 0x1F), band(rshift(w, 10), 0x1F),
           band(rshift(w, 20), 0x1F), band(rshift(w, 25), 0x1F), band(rshift(w, 15), 0x1F) }
  -- orden: PS / Ata / Def / AtEsp / DefEsp / Vel
end

local function speciesName(idx)
  local dex = nationalDexList[idx + 1]
  return (dex and speciesNamesList[dex]) or ("#" .. idx)
end

-- Lee una estructura de Pokemon (100 bytes) y la valida con el checksum.
local function decodeMonRaw(addr)
  local pid = read32(addr)
  if pid == 0 then return nil end
  local otid = read32(addr + 4)
  local key = bxor(pid, otid)
  local sum = 0
  for i = 0, 11 do
    local w = bxor(read32(addr + 0x20 + i * 4), key)
    sum = sum + band(w, 0xFFFF) + band(rshift(w, 16), 0xFFFF)
  end
  if band(sum, 0xFFFF) ~= read16(addr + 0x1C) then return nil end
  local order   = pid % 24
  local growth  = bxor(read32(addr + 0x20 + getGrowthOffset(order)), key)
  local species = band(growth, 0xFFFF)
  if species == 0 or species > 411 then return nil end
  local misc = bxor(read32(addr + 0x20 + getMiscOffset(order) + 4), key)
  local tid, sid = otid % 0x10000, floor(otid / 0x10000)
  return { pid = pid, species = species, ivs = ivsFromWord(misc),
           sv = shinyValue(pid, tid, sid), level = read8(addr + 0x54),
           sig = string.format("%08X%08X%08X%04X%02X", pid, otid, misc % 4294967296, read16(addr + 0x1C), read8(addr + 0x54)) }
end

-- El juego puede estar A MEDIO crear el Pokemon cuando termina un frame
-- (frames con lag): PID ya escrito pero el OT, los IVs o el nivel todavia
-- no. Leerlo asi daba shinies falsos y calibraciones fallidas. Solo se
-- acepta cuando todo (incluido el nivel) lleva 3 frames sin cambiar.
local gFrame = 0
local monWatch = {}
local function decodeMon(addr)
  local m = decodeMonRaw(addr)
  if not m or m.level == 0 or m.level > 100 then monWatch[addr] = nil; return nil end
  local w = monWatch[addr]
  if not w or w.sig ~= m.sig then monWatch[addr] = { sig = m.sig, since = gFrame }; return nil end
  if gFrame - w.since < 3 then return nil end
  return m
end

local function zeroEnemy() write32(A.enemy, 0) end
local function inBattle() return band(read8(A.inBattleByte), 0x02) ~= 0 end

local function playerIDs()
  local sb2 = read32(A.sb2)
  if not validPtr(sb2) then return nil end
  local ids = read32(sb2 + 0xA)
  return ids % 0x10000, floor(ids / 0x10000)
end

-- Roamer: SaveBlock1 + 0x30D0 (IVs u32, PID u32, especie u16, ... activo en +0x13)
local function readRoamer()
  local sb1 = read32(A.sb1)
  if not validPtr(sb1) then return nil end
  local r = sb1 + 0x30D0
  return { active = read8(r + 0x13) == 1, pid = read32(r + 4),
           species = read16(r + 8), ivWord = read32(r) }
end

-- ------------------------------ Estado -------------------------------
local MODES = { "Salvaje", "Estatico", "Regalo", "Roamer", "Estatico RNG", "Regalo RNG", "Roamer RNG", "Salvaje RNG",
                "Partida nueva", "Semilla inicial" }
-- 1 = salvaje, 2 = estatico, 3 = regalo, 4 = roamer (los modos RNG usan el mismo tipo)

local bot = {
  mode = 1, running = false, found = false, st = "idle", t = 0,
  encounters = 0, timeouts = 0, startFrame = 0,
  sawBattle = false, outFrames = 0, ranAt = nil,
  armed = false, baseParty = 0, tid = nil, sid = nil,
  last = nil, panel = 1, msg = "",     -- panel: 1 compacto, 2 completo, 0 oculto
}
local queue = {}
local walkToggle = false
local stopBot   -- se define mas abajo
local function kind()
  if bot.mode == 8 then return 1 end
  if bot.mode == 9 then return 5 end
  if bot.mode == 10 then return 6 end
  return bot.mode <= 4 and bot.mode or bot.mode - 3
end
local function isRngMode() return bot.mode >= 5 and bot.mode <= 7 end
local function isWildRng() return bot.mode == 8 end

local function push(buttons, frames) queue[#queue + 1] = { b = buttons, n = frames } end
local function wait(frames) if frames > 0 then push(nil, frames) end end
local function tap(btn) push({ [btn] = true }, 2); wait(6) end

local function runQueue()
  local item = queue[1]
  if not item then return end
  if item.b then joypad.set(1, item.b) end
  item.n = item.n - 1
  if item.n <= 0 then table.remove(queue, 1) end
end

local function natureOf(pid) return natureNamesList[(pid % 25) + 1] end

local function hiddenPowerOf(iv)  -- iv = {PS, Ata, Def, AtEsp, DefEsp, Vel}
  local hp, at, df, sa, sd, sp = iv[1], iv[2], iv[3], iv[4], iv[5], iv[6]
  local t = floor(((hp % 2) + 2 * (at % 2) + 4 * (df % 2) + 8 * (sp % 2) + 16 * (sa % 2) + 32 * (sd % 2)) * 15 / 63)
  local function b(x) return floor(x / 2) % 2 end
  local pw = floor((b(hp) + 2 * b(at) + 4 * b(df) + 8 * b(sp) + 16 * b(sa) + 32 * b(sd)) * 40 / 63) + 30
  return t + 1, pw
end

-- shinyNeeded=false para revisar solo los demas filtros
local function passesFilters(mon)
  if filt.species and mon.species and (bot.mode == 1 or bot.mode == 8) then
    if not filt.species[simplify(speciesName(mon.species))] then return false end
  end
  if filt.natures and not filt.natures[natureOf(mon.pid)] then return false end
  local iv = mon.ivs
  if iv and bot.mode ~= 4 and bot.mode ~= 7 then  -- roamer: IVs truncados por el bug
    local total = 0
    for i = 1, 6 do
      if iv[i] < filt.minIV[i] or iv[i] > filt.maxIV[i] then return false end
      total = total + iv[i]
    end
    if filt.minIVTotal and total < filt.minIVTotal then return false end
    if filt.hpType or filt.hpPower then
      local t, pw = hiddenPowerOf(iv)
      if filt.hpType and t ~= filt.hpType then return false end
      if filt.hpPower and pw < filt.hpPower then return false end
    end
  end
  return true
end

local function isWanted(mon)
  if filt.shiny and mon.sv >= 8 then return false end
  return passesFilters(mon)
end

local function now_time()
  local t = 0
  pcall(function() t = os.time() end)
  return t
end

local LANG_NAMES = { [0x45] = "USA", [0x4A] = "JPN", [0x53] = "ESP", [0x46] = "FRA", [0x49] = "ITA", [0x44] = "GER" }
local GAME_LABEL = string.format("%s %s %s", gameName or "?", LANG_NAMES[gameLang] or string.format("0x%02X", gameLang),
                                 gameRev1 and "v1.1" or "v1.0")
local function logLine(text)
  local stamp = ""
  pcall(function() stamp = os.date("%Y-%m-%d %H:%M:%S") end)
  print(string.format("[Instancia %d] %s", INSTANCE, text))
  text = string.format("[%s] [%s] [Instancia %d] %s", stamp, GAME_LABEL, INSTANCE, text)
  pcall(function()
    local f = io.open(LOGDIR .. CONFIG.logFile, "a")
    if f then f:write(text .. "\n"); f:close() end
  end)
end

local function onShiny(mon)
  bot.found, bot.running, bot.st = true, false, "found"
  queue = {}
  local ivs = mon.ivs and table.concat(mon.ivs, "/") or "?"
  local tag = (mon.sv < 8) and (mon.sv == 0 and "SHINY Square" or "SHINY Star") or "OBJETIVO"
  local since = ""
  pcall(function() if bot.startTime then since = " | corrida iniciada " .. os.date("%Y-%m-%d %H:%M", bot.startTime) end end)
  logLine(string.format("[%s] %s  PID %08X  %s  IVs %s  tras %d intentos (modo %s)%s",
    tag, speciesName(mon.species), mon.pid, natureOf(mon.pid), ivs, bot.encounters, MODES[bot.mode], since))
  if CONFIG.savestateSlot then
    pcall(function() savestate.save(savestate.create(CONFIG.savestateSlot)) end)
  end
  bot.msg = "ENCONTRADO! Juego en pausa: guarda un estado (Shift+F1) y capturalo"
  print(bot.msg)
  if CONFIG.stopOthers then
    writeFile("shiny_stop.flag", string.format("%d %s %d %s", now_time(), TOKEN, INSTANCE, speciesName(mon.species)))
  end
  emu.pause()
end

-- Devuelve true si se detuvo por shiny
local function evaluate(mon)
  bot.encounters = bot.encounters + 1
  mon.shiny = mon.sv < 8
  bot.last = mon
  if isWanted(mon) then onShiny(mon); return true end
  if mon.shiny then logLine(string.format("Shiny descartado por filtros: %s PID %08X", speciesName(mon.species), mon.pid)) end
  return false
end

-- ---------------------------- Modo salvaje ---------------------------
local function pushWalk()
  local d1, d2 = "left", "right"
  if CONFIG.walkAxis == "vertical" then d1, d2 = "up", "down" end
  walkToggle = not walkToggle
  local dir = walkToggle and d1 or d2
  local b = { [dir] = true }
  if CONFIG.holdB then b.B = true end
  push(b, CONFIG.walkFrames)
  wait(math.random(0, 3))   -- variacion para que cada instancia tenga encuentros distintos
end

-- Menu de combate:  LUCHA(0)   MOCHILA(1)
--                   POKEMON(2) HUIR(3)
-- Se lee la posicion real del cursor (gActionSelectionCursor) y solo se
-- pulsa A cuando el cursor YA esta en HUIR. Asi nunca entra en LUCHA.
local function pushFleeCycle()
  local c = band(read8(A.actionCursor), 3)
  if c == 3 then
    tap("A"); wait(14)            -- elige HUIR (o avanza el texto)
  else
    tap("B"); wait(8)             -- avanza texto / sale de un submenu
    if band(c, 1) == 0 then tap("right") else tap("down") end
    wait(6)
  end
end

local function enterFlee(sawBattle)
  queue = {}
  write8(A.battleOutcome, 0)         -- borrar resultado del combate anterior
  bot.st, bot.t, bot.sawBattle, bot.outFrames, bot.ranAt = "flee", 0, sawBattle, 0, nil
end

local function stepWild()
  if bot.st == "walk" then
    local mon = decodeMon(A.enemy)
    if mon then
      queue = {}
      if evaluate(mon) then return end
      enterFlee(false)
    elseif inBattle() then
      enterFlee(true)                  -- combate sin Pokemon detectado: huir igual
    elseif #queue == 0 then
      pushWalk()
    end
  elseif bot.st == "flee" then
    bot.t = bot.t + 1
    local ib = inBattle()
    if ib then bot.sawBattle = true end
    if not bot.ranAt and read8(A.battleOutcome) == 4 then bot.ranAt = bot.t end

    if bot.ranAt then
      -- Ya huyo: solo B para cerrar "Escapaste sin problemas" hasta volver al mapa
      if ib then bot.outFrames = 0 elseif bot.sawBattle then bot.outFrames = bot.outFrames + 1 end
      local back = (bot.sawBattle and bot.outFrames >= 20)
                or (not bot.sawBattle and bot.t - bot.ranAt > 240)
      if back then
        queue = {}; zeroEnemy(); bot.st = bot.returnState or "walk"
      elseif #queue == 0 and (ib or not bot.sawBattle) then
        tap("B"); wait(10)
      end
      return
    end

    if bot.sawBattle and not ib then
      -- el combate termino sin huir (p. ej. lo terminaste tu)
      queue = {}
      bot.outFrames = bot.outFrames + 1
      if bot.outFrames >= 20 then zeroEnemy(); bot.st = bot.returnState or "walk" end
      return
    end

    if bot.t > 3000 then               -- seguridad: algo raro, volver a caminar
      bot.msg = "Aviso: no se pudo confirmar la huida"
      print(bot.msg)
      queue = {}; zeroEnemy(); bot.st = bot.returnState or "walk"
      return
    end
    if #queue == 0 then pushFleeCycle() end
  end
end

-- ------------------------- Modos con soft reset ----------------------
local function targetReady()
  local m = kind()
  if m == 2 then                                     -- Estatico
    return decodeMon(A.enemy)
  elseif m == 3 then                                 -- Regalo
    local cnt = read8(A.partyCnt)
    if not bot.armed then
      if cnt == bot.baseParty then bot.armed = true end
      return nil
    end
    if cnt == bot.baseParty + 1 then
      return decodeMon(A.party + (cnt - 1) * 0x64)
    end
  elseif m == 4 then                                 -- Roamer
    local r = readRoamer()
    if not r then return nil end
    if not bot.armed then
      if not r.active then bot.armed = true end
      return nil
    end
    if r.active and r.pid ~= 0 then
      local w = r.ivWord  -- bug de Gen 3: solo se guarda el primer byte de IVs
      return { pid = r.pid, species = r.species,
               ivs = { band(w, 0x1F), band(rshift(w, 5), 0x07), 0, 0, 0, 0 },
               sv = shinyValue(r.pid, bot.tid, bot.sid) }
    end
  end
  return nil
end

local function stepReset()
  if bot.st == "reset" then
    queue = {}
    zeroEnemy()
    push({ A = true, B = true, select = true, start = true }, 3)
    wait(math.random(0, 90))
    bot.st, bot.t, bot.armed = "boot", 0, false
  elseif bot.st == "boot" then
    bot.t = bot.t + 1
    if bot.t < 45 then return end                     -- dejar que el reset ocurra
    if bot.t == 45 and kind() == 2 then zeroEnemy(); bot.armed = true end
    local mon = targetReady()
    if mon then
      queue = {}
      if not evaluate(mon) then bot.st = "reset" end
      return
    end
    if bot.t > CONFIG.resetTimeout then
      bot.timeouts = bot.timeouts + 1
      bot.st = "reset"
      return
    end
    if #queue == 0 then
      wait(math.random(CONFIG.pressGapMin, CONFIG.pressGapMax))
      tap("A")
    end
  end
end


-- ---------------------- Manipulacion de RNG (Metodo 1) ---------------
-- Hace lo mismo que RNG Reporter, pero dentro del script:
--  1. Guarda un savestate frente al Pokemon y anota la semilla actual.
--  2. Calibra: pulsa A una vez y mide cuantos avances pasan entre la A
--     y el momento en que el juego genera el PID ("retraso").
--  3. Busca hacia adelante el primer avance que da un shiny (y cumple
--     los filtros), carga el savestate y pulsa A justo en el avance
--     correcto. Si cae unos avances antes o despues, corrige y repite.
-- ------------- Frame actual (como RNG Reporter / FRLG_RNG_2.0) ------------
-- Cuenta los avances desde la semilla inicial del titulo. Si la semilla
-- salta (savestate, reset), lo vuelve a ubicar buscando por partes.
local function lcrng(s, mh, ml, add)
  local lo, hi = s % 0x10000, floor(s / 0x10000)
  local a = mh * lo + hi * ml
  local b = ml * lo + (a % 0x10000) * 0x10000 + add
  return b % 4294967296
end
local function prevSeedOf(s) return lcrng(s, 0xEEB9, 0xEB65, 0x0A3561A1) end

local ft = { init = nil, seed = nil, frame = nil, sSeed = nil, sK = 0 }
local FT_MAX = 50000000

local function updateFrameTracker()
  local init, cur = read16(0x02020000), read32(A.currSeed)
  if init ~= ft.init then
    ft.init, ft.seed, ft.frame = init, init, 0
  end
  if ft.frame then
    if ft.seed == cur then return end
    local f, b = ft.seed, ft.seed
    for i = 1, 20000 do
      f = lcrng(f, 0x41C6, 0x4E6D, 0x6073)
      if f == cur then ft.seed, ft.frame = cur, ft.frame + i; return end
      b = prevSeedOf(b)
      if b == cur then ft.seed, ft.frame = cur, ft.frame - i; return end
    end
    ft.frame, ft.sSeed, ft.sK = nil, init, 0     -- salto grande: buscar desde el inicio
  end
  if not ft.frame and ft.sSeed then
    local s, k = ft.sSeed, ft.sK
    local stop = math.min(k + 30000, FT_MAX)
    while k < stop do
      if s == cur then ft.seed, ft.frame, ft.sSeed = cur, k, nil; return end
      s = lcrng(s, 0x41C6, 0x4E6D, 0x6073); k = k + 1
    end
    ft.sSeed, ft.sK = s, k
    if k >= FT_MAX then ft.sSeed = nil end         -- no encontrado
  end
end


-- ======================= RNG: piezas comunes ==========================
-- Estas funciones hacen lo mismo que RNG Reporter / PokeFinder, pero
-- dentro del script, y ademas pulsan los botones en el frame exacto.
local function nextSeed(s)
  local lo, hi = s % 0x10000, floor(s / 0x10000)
  local a = 0x41C6 * lo + hi * 0x4E6D
  local b = 0x4E6D * lo + (a % 0x10000) * 0x10000 + 0x6073
  return b % 4294967296
end

-- PID e IVs (Metodo 1) generados a partir de la semilla "s"
local function method1(s)
  local s1 = nextSeed(s);  local lo = floor(s1 / 0x10000)
  local s2 = nextSeed(s1); local hi = floor(s2 / 0x10000)
  local s3 = nextSeed(s2); local i1 = floor(s3 / 0x10000) % 0x8000
  local s4 = nextSeed(s3); local i2 = floor(s4 / 0x10000) % 0x8000
  local ivs = { i1 % 32, floor(i1 / 32) % 32, floor(i1 / 1024) % 32,
                floor(i2 / 32) % 32, floor(i2 / 1024) % 32, i2 % 32 }
  return hi * 0x10000 + lo, ivs, lo, hi
end

local function ivsFromCalls(i1, i2)
  return { i1 % 32, floor(i1 / 32) % 32, floor(i1 / 1024) % 32,
           floor(i2 / 32) % 32, floor(i2 / 1024) % 32, i2 % 32 }
end

local rng = { preDelay = 40, pressEvery = 14, pressCount = 60, M = 1600, block = 50000 }
local rngState = nil
local wr = { r = {}, built = 0 }   -- r[k] = k-esima llamada a Random() desde la semilla base

local function trackAdvances()
  local cur = read32(A.currSeed)
  local n = 0
  while rng.seed ~= cur and n < 20000 do
    rng.seed = nextSeed(rng.seed); rng.adv = rng.adv + 1; n = n + 1
  end
  return rng.seed == cur
end

local pendingZero = 0
local function rngLoad()
  savestate.load(rngState)
  queue = {}
  rng.seed, rng.adv, rng.prevAdv = rng.seed0, 0, 0
  bot.armed = false
  monWatch = {}
  if kind() == 2 or kind() == 1 then
    zeroEnemy(); bot.armed = true
    -- en algunos emuladores la carga se aplica al terminar el frame: repetir
    -- el borrado unos frames para no ver el Pokemon del intento anterior
    pendingZero = 3
  end
  bot.t = 0
end

-- Guarda un savestate aqui y lo usa como nueva "base" (avance 0)
local function rebaseHere()
  zeroEnemy()                      -- la base no debe guardar el Pokemon del intento anterior
  monWatch = {}
  rngState = savestate.create()
  savestate.save(rngState)
  rng.seed0 = read32(A.currSeed)
  rng.seed, rng.adv, rng.prevAdv = rng.seed0, 0, 0
  rng.baseFrame = ft.frame
  wr.r, wr.built, wr.lastSeed = {}, 0, rng.seed0
end

local function buildR(limit, budget)
  local s, k = wr.lastSeed, wr.built
  local stop = math.min(limit, k + budget)
  local r = wr.r
  while k < stop do s = nextSeed(s); k = k + 1; r[k] = floor(s / 0x10000) end
  wr.lastSeed, wr.built = s, k
  return k >= limit
end

-- Avance (desde la base) en el que se genero un PID de Metodo 1
local function findHit(pid, limit)
  local s = rng.seed0
  for k = 0, limit do
    if method1(s) == pid then return k end
    s = nextSeed(s)
  end
  return nil
end

-- --------------------------- Filtros rapidos ---------------------------
local fast = {}
local function prepareFastFilters()
  fast.tsv = bxor(bot.tid, bot.sid)
  fast.nat = {}
  for i = 0, 24 do fast.nat[i] = (not filt.natures) or filt.natures[natureNamesList[i + 1]] or false end
end

local function ivsOk(iv)
  local total = 0
  for i = 1, 6 do
    if iv[i] < filt.minIV[i] or iv[i] > filt.maxIV[i] then return false end
    total = total + iv[i]
  end
  if filt.minIVTotal and total < filt.minIVTotal then return false end
  if filt.hpType or filt.hpPower then
    local t, pw = hiddenPowerOf(iv)
    if filt.hpType and t ~= filt.hpType then return false end
    if filt.hpPower and pw < filt.hpPower then return false end
  end
  return true
end

-- ------------------ Salvaje: tabla de encuentros (ROM) -----------------
A.wildData = (gameLang == 0x4A) and 0x0203861C or 0x020386D0   -- sWildEncounterData
A.avatar   = (gameLang == 0x4A) and 0x02036FAC or 0x02037078   -- gPlayerAvatar.flags

local LAND_T  = { 20, 40, 50, 60, 70, 80, 85, 90, 94, 98, 99, 100 }
local WATER_T = { 60, 90, 95, 99, 100 }

local wildTableBase = nil
local function validHeaderTable(base)
  local n = 0
  for i = 0, 400 do
    local a = base + i * 20
    local g = read8(a)
    if g == 0xFF then return n >= 30 end
    if g > 0x30 then return false end
    local any = false
    for o = 4, 16, 4 do
      local q = read32(a + o)
      if q ~= 0 then
        if q < 0x08000000 or q >= 0x0A000000 then return false end
        any = true
      end
    end
    if not any then return false end
    n = n + 1
  end
  return false
end

local function findWildTable()
  if wildTableBase ~= nil then return wildTableBase end
  wildTableBase = false
  if validHeaderTable(0x083C9CB8) then wildTableBase = 0x083C9CB8; return wildTableBase end
  for a = 0x08300000, 0x08500000, 4 do
    if read8(a) < 0x30 and read8(a + 2) == 0 and read8(a + 3) == 0 and validHeaderTable(a) then
      wildTableBase = a; return a
    end
  end
  return false
end

local function currentWildInfo(water)
  local base = findWildTable()
  if not base then return nil end
  local sb1 = read32(A.sb1)
  if not validPtr(sb1) then return nil end
  local g, n = read8(sb1 + 4), read8(sb1 + 5)
  for i = 0, 400 do
    local a = base + i * 20
    local mg = read8(a)
    if mg == 0xFF then return nil end
    if mg == g and read8(a + 1) == n then
      local info = read32(a + (water and 8 or 4))
      if info == 0 then return nil end
      local mons = read32(info + 4)
      local slots = {}
      for k = 0, (water and 5 or 12) - 1 do
        local m = mons + k * 4
        local lo, hi = read8(m), read8(m + 1)
        if hi < lo then lo, hi = hi, lo end
        slots[k + 1] = { lo = lo, hi = hi, species = read16(m + 2) }
      end
      return { rate = read8(info), slots = slots }
    end
  end
  return nil
end

local function slotSpecies(slot)
  if wr.info and wr.info.slots[slot] then return wr.info.slots[slot].species end
  return nil
end

local function slotOfRoll(roll)
  local th = wr.water and WATER_T or LAND_T
  for i, t in ipairs(th) do if roll < t then return i end end
  return #th
end

-- Orden de las llamadas a Random() al generar un salvaje. El normal es
-- el Metodo H-1 (espacio, nivel, naturaleza, PID hasta que coincida la
-- naturaleza, IVs). Si en tu zona el juego mete una llamada extra (por
-- ejemplo una interrupcion de pantalla), la calibracion la detecta.
local LAYOUTS = {
  { name = "H-1",               s = 1, l = 2, a = 3, b = 0, i1 = 2, i2 = 3 },
  { name = "H-1 nivel primero", s = 2, l = 1, a = 3, b = 0, i1 = 2, i2 = 3 },
  { name = "H-1 +1 antes de naturaleza", s = 1, l = 2, a = 4, b = 0, i1 = 2, i2 = 3 },
  { name = "H-1 +1 entre espacio y nivel", s = 1, l = 3, a = 4, b = 0, i1 = 2, i2 = 3 },
  { name = "H-1 +1 tras naturaleza", s = 1, l = 2, a = 3, b = 1, i1 = 2, i2 = 3 },
  { name = "H-2", s = 1, l = 2, a = 3, b = 0, i1 = 3, i2 = 4 },
  { name = "H-4", s = 1, l = 2, a = 3, b = 0, i1 = 2, i2 = 4 },
}

-- Lo que generaria el juego si el encuentro empieza en la semilla E
local function predictWild(E, lay)
  lay = lay or wr.layout or LAYOUTS[1]
  local r = wr.r
  local roll = r[E + lay.s]
  if not roll then return nil end
  local nature = r[E + lay.a] % 25
  local q = E + lay.a + 1 + lay.b
  while true do
    local lo, hi = r[q], r[q + 1]
    if not r[q + lay.i2] then return nil end
    if (hi * 65536 + lo) % 25 == nature then
      return { slot = slotOfRoll(roll % 100), levelRoll = r[E + lay.l], pid = hi * 65536 + lo, lo = lo, hi = hi,
               q = q, i1 = r[q + lay.i1] % 0x8000, i2 = r[q + lay.i2] % 0x8000 }
    end
    q = q + 2
  end
end

-- Encuentra la semilla E (y el orden de llamadas) que produjo el Pokemon observado
local function findWildE(mon, level, minE, expectE, onlyLayout)
  local lo, hi = mon.pid % 65536, floor(mon.pid / 65536)
  local iv = mon.ivs
  local iv1 = iv[1] + iv[2] * 32 + iv[3] * 1024
  local iv2 = iv[6] + iv[4] * 32 + iv[5] * 1024
  local r = wr.r
  local looseE, looseLay = nil, nil
  for li, lay in ipairs(LAYOUTS) do
    if not onlyLayout or lay == onlyLayout then
      for q = minE + 4, wr.built - 5 do
        if r[q] == lo and r[q + 1] == hi and r[q + lay.i1] % 0x8000 == iv1 and r[q + lay.i2] % 0x8000 == iv2 then
          local best, bestCost = nil, nil
          for i = 0, 400 do
            local E = q - lay.a - 1 - lay.b - 2 * i
            if E < minE then break end
            local pr = predictWild(E, lay)
            if pr and pr.q == q then
              local info = wr.info and wr.info.slots[pr.slot]
              local ok = true
              if info then
                if info.species ~= mon.species then ok = false
                elseif info.lo + pr.levelRoll % (info.hi - info.lo + 1) ~= level then ok = false end
              end
              local cost = expectE and math.abs(E - expectE) or i
              if ok then
                if not bestCost or cost < bestCost then best, bestCost = E, cost end
              elseif li == 1 and not looseE then
                looseE, looseLay = E, lay      -- coincide el RNG pero no la especie/nivel
              end
            end
          end
          if best then return best, lay end
          break
        end
      end
    end
  end
  return looseE, looseLay, true
end

-- ------------------- Busqueda lejana (millones de avances) ------------------
-- Recorre el RNG por bloques (sin guardar millones de valores) y devuelve el
-- primer avance que cumple todos los filtros.
local far = nil

local function startFar(from)
  prepareFastFilters()
  far = { from = from, best = nil }
  -- punto de partida: semilla en el indice (inicio del bloque - margen)
  local gs = math.max(from - rng.M, 1)
  local s, k = rng.seed0, 0
  for _, an in ipairs(rng.anchors or {}) do      -- reanudar desde un bloque ya recorrido
    if an.base == rng.seed0 and an.idx <= gs - 1 and an.idx > k then s, k = an.seed, an.idx end
  end
  while k < gs - 1 do s = nextSeed(s); k = k + 1 end
  far.bs, far.seed = math.max(from, 1), s          -- far.seed = semilla del indice gs - 1
  far.gs = gs
  if bot.mode == 8 then
    far.slotOk = {}
    for slot = 1, (wr.water and 5 or 12) do
      local sp = slotSpecies(slot)
      far.slotOk[slot] = (not filt.species) or (sp and filt.species[simplify(speciesName(sp))]) or false
    end
  end
  bot.st = "far"
end

local function scanFarBlock()
  local M, B = rng.M, rng.block
  local bs = far.bs
  local be = bs + B - 1
  local gs = far.gs
  local R = {}
  local s = far.seed
  local n = be + 12 - gs + 1
  local anchorIdx = be + 1 - M - 1            -- semilla para el siguiente bloque
  local nextSeedVal
  for j = 1, n do
    local lo, hi = s % 0x10000, floor(s / 0x10000)
    local a = 0x41C6 * lo + hi * 0x4E6D
    s = (0x4E6D * lo + (a % 0x10000) * 0x10000 + 0x6073) % 4294967296
    R[j] = floor(s / 0x10000)
    if gs + j - 1 == anchorIdx then nextSeedVal = s end
  end
  local needShiny, tsv, natOk = filt.shiny, fast.tsv, fast.nat
  local best = far.best
  if bot.mode == 8 then
    local lay = wr.layout or LAYOUTS[1]
    local pre = lay.a + 1 + lay.b
    local slotOk = far.slotOk
    for q = bs, be do
      local j = q - gs + 1
      local lo, hi = R[j], R[j + 1]
      if (not needShiny) or bxor(tsv, bxor(lo, hi)) < 8 then
        local pid = hi * 65536 + lo
        local nat = pid % 25
        if natOk[nat] then
          local ivs = ivsFromCalls(R[j + lay.i1] % 0x8000, R[j + lay.i2] % 0x8000)
          if ivsOk(ivs) then
            local p = q
            while p - pre - gs + 1 >= 1 do
              local pj = p - gs + 1
              if p < q and (R[pj + 1] * 65536 + R[pj]) % 25 == nat then break end
              local E = p - pre
              local ej = E - gs + 1
              if E >= far.from and R[ej + lay.a] % 25 == nat then
                local slot = slotOfRoll(R[ej + lay.s] % 100)
                if slotOk[slot] and (not best or E < best.E) then
                  best = { E = E, pid = pid, ivs = ivs, sv = bxor(tsv, bxor(lo, hi)), slot = slot }
                end
              end
              p = p - 2
            end
          end
        end
      end
      if best and q > best.E + M + 10 then break end
    end
  else
    for k = bs, be do
      local j = k - gs + 1
      local lo, hi = R[j + 1], R[j + 2]
      if (not needShiny) or bxor(tsv, bxor(lo, hi)) < 8 then
        local pid = hi * 65536 + lo
        if natOk[pid % 25] then
          local ivs = ivsFromCalls(R[j + 3] % 0x8000, R[j + 4] % 0x8000)
          if ivsOk(ivs) and k >= far.from then
            best = { E = k, pid = pid, ivs = ivs, sv = bxor(tsv, bxor(lo, hi)) }
            break
          end
        end
      end
    end
  end
  far.best = best
  rng.anchors = rng.anchors or {}
  rng.anchors[#rng.anchors + 1] = { base = rng.seed0, idx = far.gs - 1, seed = far.seed }
  far.bs, far.gs, far.seed = be + 1, be + 1 - M, nextSeedVal
  local doneByBest = best and (bot.mode ~= 8 or be > best.E + M + 10)
  return doneByBest, be
end

-- ---------------------- Nueva semilla (soft reset) ----------------------
-- Requiere haber GUARDADO la partida en el lugar de la caza.
local function startReseed(reason)
  bot.reseeds = (bot.reseeds or 0) + 1
  bot.seedsTried = (bot.seedsTried or 1) + 1
  bot.msg = string.format("Nueva semilla (%s)", reason)
  print(bot.msg)
  bot.selfReset = true
  queue = {}
  zeroEnemy()
  push({ A = true, B = true, select = true, start = true }, 3)
  wait(math.random(0, 120))
  rng.seed0, rng.target, rng.delay, rng.pressAt, rng.stepsToEnc = nil, nil, nil, nil, nil
  rng.anchors, far = nil, nil
  rngState = nil
  bot.st, bot.t = "rboot", 0
end

local function stepReseed()
  bot.t = bot.t + 1
  if bot.st == "rboot" then
    if bot.t < 45 then return end
    if bot.t > CONFIG.resetTimeout then startReseed("no volvio al mapa"); return end
    if bot.t > 60 and decodeMon(A.enemy) then startReseed("encuentro inesperado"); return end
    if read8(A.avatar) ~= 0 and validPtr(read32(A.sb1)) then
      queue = {}; bot.st, bot.t = "rquest", 0; return
    end
    if #queue == 0 then
      wait(math.random(CONFIG.pressGapMin, CONFIG.pressGapMax))
      tap("A")
    end
  elseif bot.st == "rquest" then
    -- saltar el resumen "Anteriormente en tu aventura..." con B
    if decodeMon(A.enemy) then startReseed("encuentro inesperado"); return end
    if bot.t >= 400 then queue = {}; bot.st, bot.t = "rsettle", 0; return end
    if #queue == 0 then wait(18); tap("B") end
  elseif bot.st == "rsettle" then
    if bot.t >= 60 then
      bot.selfReset = false
      if bot.mode == 8 then
        zeroEnemy()
        bot.prepPos, bot.prepCnt, bot.prepSteps = nil, nil, 0
        bot.returnState = "prep"
        bot.st = "prep"
      else
        rng.startFn()
      end
    end
  end
end

local function isReseedState() return bot.st == "rboot" or bot.st == "rquest" or bot.st == "rsettle" end

-- ------------- Resultado de la busqueda lejana: ir al objetivo --------------
-- La Tele avanza el RNG 312 veces por frame (dibuja su "estatica" con
-- Random) + 1 normal. Al pulsar B deja de hacerlo casi enseguida, asi que
-- se puede cerrar muy cerca del objetivo.
local function teachyMargin()
  return CONFIG.teachyMargin or ((rng.delay or 300) + 1500)
end

local function teachyRegistered()
  local sb1 = read32(A.sb1)
  return validPtr(sb1) and read16(sb1 + 0x296) == 366      -- ITEM_TEACHY_TV
end

local function goToTarget(best)
  rng.target, rng.targetPid, rng.targetIvs, rng.targetSv, rng.targetSlot =
    best.E, best.pid, best.ivs, best.sv, best.slot
  rng.pressAt, rng.tries, rng.tried = best.E - rng.delay, 0, {}
  local sp = (bot.mode == 8) and slotSpecies(best.slot) or nil
  bot.msg = string.format("Objetivo: avance %d%s  PID %08X  %s", best.E,
            sp and ("  " .. speciesName(sp)) or "", best.pid, natureOf(best.pid))
  print(bot.msg)
  local useTv = CONFIG.teachy and (rng.pressAt - teachyMargin()) > CONFIG.teachyBeyond
  if useTv and not teachyRegistered() then
    if not rng.tvWarned then
      print("Aviso: registra la Tele Pokemon en SELECT (Mochila > Obj. clave > Tele Pokemon > Registrar)")
      print("        para avanzar millones de frames en minutos. Por ahora espero a velocidad normal.")
      rng.tvWarned = true
    end
    useTv = false
  end
  if useTv then
    -- lejos: Tele Pokemon (313 avances por frame) hasta acercarse
    rngLoad()
    bot.st, bot.t = "tv_open", 0
    return
  end
  if bot.mode == 8 and wr.built < rng.target + 3000 then
    bot.st = "wbuild2"           -- calcular los valores del RNG hasta el objetivo
    return
  end
  bot.st = "wait"
  rngLoad()
end

local function stepFar()
  local done, be = scanFarBlock()
  bot.msg = string.format("Buscando objetivo... avance %d", be)
  if done then
    goToTarget(far.best)
  elseif be >= CONFIG.farSearch then
    if far.best then goToTarget(far.best); return end
    if CONFIG.reseed and not bot.noReseed and (bot.reseeds or 0) < CONFIG.maxReseeds then
      startReseed(string.format("sin objetivo en %d avances", CONFIG.farSearch)); return
    end
    bot.msg = "No hay objetivo con esos filtros: sube farSearch o quita filtros"
    print(bot.msg); bot.running = false; bot.st = "idle"
  end
end

-- ------------------------- Tele Pokemon (Teachy TV) -------------------------
-- Registrala en SELECT. Mientras esta abierta el RNG avanza ~313 veces por
-- frame: millones de avances en pocos minutos. El bot la abre, la cierra
-- poco antes del objetivo, guarda un savestate alli y sigue normal.
local function stepTeachy()
  local rate = rng.adv - (rng.prevAdv or rng.adv)
  rng.prevAdv = rng.adv
  if bot.st == "tv_open" then
    if bot.t == 1 then queue = {}; wait(10); tap("select"); rng.tvFast = 0 end
    if rate > 30 then rng.tvFast = rng.tvFast + 1 else rng.tvFast = 0 end
    if rng.tvFast >= 5 then bot.st, bot.t = "tv_run", 0; return end
    if bot.t > 600 then
      print("No se abrio la Tele Pokemon: registrala en SELECT. Esperando a velocidad normal.")
      queue = {}; tap("B"); wait(20); tap("B")
      bot.st = "wait"
    end
  elseif bot.st == "tv_run" then
    if rng.adv >= rng.pressAt - teachyMargin() - 313 then
      queue = {}; tap("B")
      bot.st, bot.t, rng.tvSlow = "tv_exit", 0, 0
    end
  elseif bot.st == "tv_exit" then
    if rate <= 3 then rng.tvSlow = rng.tvSlow + 1 else rng.tvSlow = 0 end
    if rate > 3 and #queue == 0 then wait(20); tap("B") end
    if rng.tvSlow >= 90 then queue = {}; bot.st, bot.t = "tv_settle", 0 end
  elseif bot.st == "tv_settle" then
    if bot.t >= 30 then
      -- nueva base cerca del objetivo; el retraso medido sigue valiendo
      local lost = rng.adv > rng.pressAt - rng.preDelay
      rebaseHere()
      zeroEnemy()
      if lost then print("La Tele se paso del objetivo: busco el siguiente") end
      startFar(rng.delay + rng.preDelay + 10)
    end
  end
end

-- =========================== Estatico/Regalo/Roamer RNG =====================
local function wantedTarget(pid, ivs, lo, hi)
  return isWanted({ pid = pid, ivs = ivs, sv = bxor(bxor(bot.tid, bot.sid), bxor(lo, hi)) })
end

local function rngStart()
  rebaseHere()
  rng.nextSearch = nil
  rng.delay, rng.target, rng.targetPid, rng.tries = nil, nil, nil, 0
  rng.stepsToEnc, rng.targetIvs, rng.targetSv, rng.failedTargets = nil, nil, nil, 0
  rng.anchors, far = nil, nil
  rng.pressAt = rng.preDelay
  bot.st = "wait"
  bot.msg = "Calibrando..."
  rngLoad()
end

local function pushPressSchedule()
  tap("A")
  for _ = 1, rng.pressCount do wait(rng.pressEvery - 2); tap("A") end
end

local function stopLostSeed()
  stopBot()
  bot.msg = "La semilla cambio (cargaste un estado o reiniciaste). Bot detenido."
  print(bot.msg)
end

local function retryOrNext(hit)
  rng.tries = rng.tries + 1
  print(string.format("Intento %d: cayo en %d (objetivo %d)", rng.tries, hit, rng.target))
  rng.tried[rng.pressedAdv] = true
  local base = rng.pressedAdv + (rng.target - hit)
  local cand = base
  for _, off in ipairs({ 0, -1, 1, -2, 2, -3, 3 }) do
    if not rng.tried[base + off] then cand = base + off; break end
  end
  rng.pressAt = cand
  if rng.tries >= CONFIG.triesPerTarget or rng.pressAt < rng.preDelay then
    rng.failedTargets = (rng.failedTargets or 0) + 1
    if CONFIG.reseed and not bot.noReseed and bot.mode ~= 9 and rng.failedTargets >= CONFIG.reseedAfterFailedTargets then
      startReseed("objetivos inalcanzables"); return
    end
    if rng.nextSearch then rng.nextSearch(rng.target + 1) else startFar(rng.target + 1) end
  else
    bot.st = "wait"; rngLoad()
  end
end

local function stepRng()
  if isReseedState() then stepReseed(); return end
  if bot.st == "far" then stepFar(); return end

  bot.t = bot.t + 1
  if not trackAdvances() then stopLostSeed(); return end
  if bot.st:sub(1, 3) == "tv_" then stepTeachy(); return end

  if bot.st == "wait" then
    if rng.adv >= rng.pressAt then
      rng.pressedAdv = rng.adv
      bot.t = 0
      pushPressSchedule()
      bot.st = "pressed"
    end
  elseif bot.st == "pressed" then
    local mon = targetReady()
    if mon then
      queue = {}
      local limit = (rng.target or 0) + 20000
      local hit = findHit(mon.pid, limit)
      if evaluate(mon) then return end
      if not hit then
        bot.msg = "El PID no es Metodo 1: usa el modo con soft reset"
        print(bot.msg); bot.running = false; bot.st = "idle"; return
      end
      local d = hit - rng.pressedAdv
      if not rng.delay then
        rng.delay = d
        print(string.format("Calibrado: retraso = %d avances", d))
        startFar(d + rng.preDelay + 10)
        return
      end
      rng.delay = d
      retryOrNext(hit)
    elseif bot.t > CONFIG.resetTimeout then
      bot.timeouts = bot.timeouts + 1
      bot.st = "wait"; rngLoad()
    end
  end
end
rng.startFn = rngStart

-- ===================== Partida nueva: elegir TID/SID =====================
-- Al confirmar TU nombre, el juego fija el TID (contador de tiempo) y
-- reinicia el RNG con ese mismo valor. Al terminar el discurso de Oak,
-- NewGameInitData pide UN numero al RNG: ese es el SID. Asi que el SID
-- depende del frame en que cierras el ultimo dialogo. El bot busca el
-- frame que da un SID tal que TID xor SID quede en los rangos elegidos
-- (por defecto, los que hacen shiny a uno de los Ditto 6x31).
local NG_DEFAULT = { 0x9630, 0xB378, 0x79F8 }
local NG_INFO = {
  [0x9630] = "Ditto 6x31 shiny: Timid (sem. 448B) o Modest (BC75), Ruta 14 / Mansion S1",
  [0xB378] = "Ditto 6x31 shiny: Modest (38F2) o Calm (BDD1), Ruta 14 / Mansion / Cueva Celeste",
  [0x79F8] = "Ditto 6x31 shiny: Modest (5433), Cueva Celeste 1P/2P",
}

local function ngWindows()
  local list = toList(CONFIG.newGameTSV) or NG_DEFAULT
  local out = {}
  for _, v in ipairs(list) do
    local n = tonumber(v) or tonumber(tostring(v), 16)
    if n then out[#out + 1] = n - (n % 8) end
  end
  return out
end

local function ngWindowOf(tid, sid)
  local x = bxor(tid, sid)
  for _, w in ipairs(rng.ngWin) do if x >= w and x <= w + 7 then return w end end
  return nil
end

local function idWord()
  local sb2 = read32(A.sb2)
  if not validPtr(sb2) then return nil end
  return read32(sb2 + 0xA)
end

local function ngSearch(from)
  if not (rng.scanK and rng.scanK <= from and rng.scanBase == rng.seed0) then
    rng.scanK, rng.scanSeed, rng.scanBase = 0, rng.seed0, rng.seed0
  end
  rng.searchFrom = from
  rng.target = nil
  bot.st = "ngsearch"
end

local function ngStart()
  rebaseHere()
  bot.tid = read16(0x02020000)
  bot.sid = nil
  rng.ngWin = ngWindows()
  rng.ngOldId = idWord()
  rng.delay, rng.target, rng.tries, rng.tried, rng.failedTargets = nil, nil, 0, {}, 0
  rng.scanK, rng.nextSearch = nil, ngSearch
  rng.pressAt = rng.preDelay
  bot.st = "wait"
  bot.msg = "Calibrando..."
  rngLoad()
end

local function stepNewGame()
  if bot.st == "ngsearch" then
    local s, k = rng.scanSeed, rng.scanK
    local stop = k + 50000
    while k < stop do
      local nx = nextSeed(s)
      if k >= rng.searchFrom and ngWindowOf(bot.tid, floor(nx / 0x10000)) then
        rng.target, rng.targetSid = k, floor(nx / 0x10000)
        break
      end
      s = nx; k = k + 1
    end
    rng.scanSeed, rng.scanK = s, k
    bot.msg = string.format("Buscando SID... avance %d", k)
    if rng.target then
      rng.pressAt, rng.tries, rng.tried = rng.target - rng.delay, 0, {}
      bot.msg = string.format("Objetivo: SID %d en el avance %d", rng.targetSid, rng.target)
      print(bot.msg)
      bot.st = "wait"; rngLoad()
    elseif k > 5000000 then
      bot.msg = "No encontre un SID valido: revisa newGameTSV"
      print(bot.msg); bot.running = false; bot.st = "idle"
    end
    return
  end

  bot.t = bot.t + 1
  if not trackAdvances() then stopLostSeed(); return end

  if bot.st == "wait" then
    if rng.adv >= rng.pressAt then
      rng.pressedAdv, bot.t = rng.adv, 0
      pushPressSchedule()
      bot.st = "pressed"
    end
  elseif bot.st == "pressed" then
    local id = idWord()
    if id and id ~= rng.ngOldId and id ~= 0 then
      queue = {}
      local tid, sid = id % 0x10000, floor(id / 0x10000)
      -- avance donde salio ese SID (primera coincidencia tras pulsar)
      local s, hit = rng.seed0, nil
      for k = 0, rng.pressedAdv + 30000 do
        local nx = nextSeed(s)
        if k >= rng.pressedAdv and floor(nx / 0x10000) == sid then hit = k; break end
        s = nx
      end
      bot.encounters = bot.encounters + 1
      local w = ngWindowOf(tid, sid)
      if w then
        bot.found, bot.running, bot.st = true, false, "found"
        bot.tid, bot.sid = tid, sid
        logLine(string.format("[TID/SID] TID %d  SID %d  (TID xor SID = %04X) -> %s", tid, sid, bxor(tid, sid),
                NG_INFO[w] or "rango elegido"))
        bot.msg = "LISTO! Juego en pausa: guarda un estado (Shift+F1) y sigue jugando"
        print(bot.msg)
        emu.pause()
        return
      end
      if tid ~= bot.tid then print(string.format("Aviso: el TID salio %d, se esperaba %d", tid, bot.tid)) end
      if not hit then
        bot.msg = "No ubique el SID en el RNG: empieza el modo justo despues de nombrar al rival"
        print(bot.msg); bot.running = false; bot.st = "idle"; return
      end
      local d = hit - rng.pressedAdv
      if not rng.delay then
        rng.delay = d
        print(string.format("Calibrado: retraso = %d avances (TID %d)", d, bot.tid))
        ngSearch(d + rng.preDelay + 10)
        return
      end
      rng.delay = d
      retryOrNext(hit)
    elseif bot.t > CONFIG.resetTimeout then
      bot.timeouts = bot.timeouts + 1
      bot.st = "wait"; rngLoad()
    end
  end
end

-- =================== Semilla inicial (Initial Seed Bot) ===================
-- La semilla inicial es el valor del Timer1 cuando, tras pulsar A en el
-- titulo, termina el grito y el fundido (SeedRngAndSetTrainerId). El timer
-- avanza 280896 ciclos por frame, asi que pulsar d frames mas tarde suma
-- d * 280896 (mod 65536) a la semilla. El bot mide la semilla con dos
-- pulsaciones, calcula en que frame cae la que quieres y la verifica. Si
-- con ese arranque no se puede, cambia el momento en que salta la intro.
local sbSeedWritten = false
pcall(function() memory.registerwrite(0x02020000, function() sbSeedWritten = true end) end)
local TM1CNT_H = 0x04000106
local sb = {}

local function sbTargetList()
  local out = {}
  for _, v in ipairs(toList(CONFIG.initialSeeds) or {}) do
    local n = (type(v) == "number") and v or tonumber(tostring(v), 16)
    if n then out[#out + 1] = n % 65536 end
  end
  return out
end

local function sbTimerOn()
  local v = 0
  pcall(function() v = read16(TM1CNT_H) end)
  return band(v, 0x80) ~= 0
end

local function sbSeedNow() return read16(0x02020000) end

local function modInv(a, m)          -- inverso modular (a y m coprimos, m <= 65536)
  local t, newt, r, newr = 0, 1, m, a % m
  while newr ~= 0 do
    local q = floor(r / newr)
    t, newt = newt, t - q * newt
    r, newr = newr, r - q * newr
  end
  if r ~= 1 then return nil end
  return t % m
end

local function gcd(a, b) while b ~= 0 do a, b = b, a % b end return a end

local function sbStart()
  sb.targets = sbTargetList()
  pcall(function() os.remove(LOGDIR .. "seed_debug.txt") end)
  if #sb.targets == 0 then
    bot.msg = "Pon tus semillas en initialSeeds del .json (ej. [\"BC75\"])"
    print(bot.msg); bot.running = false; bot.st = "idle"; return
  end
  sb.w, sb.tries = 0, 0
  bot.selfReset = true
  queue = {}
  push({ A = true, B = true, select = true, start = true }, 3)
  wait(10)
  bot.st, bot.t = "sb_reset", 0
end

-- Solo cuenta si el VALOR cambio: durante la intro el juego puede escribir
-- en esa direccion (por ejemplo ceros) sin que haya semilla nueva.
local function sbSeedSeen()
  return sbSeedNow() ~= sb.before
end

-- Carga el estado tras el reset, espera w frames y pulsa A n veces (cada 8 frames).
local function sbReplay(n)
  savestate.load(sb.S0)
  queue = {}
  sbSeedWritten = false
  sb.before = sbSeedNow()
  wait(sb.w)
  for _ = 1, n do tap("A") end
  bot.t = 0
end

-- Construye el savestate "titulo listo": repetir K-1 pulsaciones y parar
-- justo antes de la K-esima (la que llega al titulo).
local function sbBuildTitle()
  sbReplay(sb.K - 1)
  wait(7)
  bot.st = "sb_title"
end

local function sbBeginW()
  -- 1) pulsar A cada 8 frames hasta que se escriba una semilla
  sbReplay(400)
  bot.st = "sb_find"
end

local function sbTry(d)
  savestate.load(sb.Stitle)
  queue = {}
  sbSeedWritten = false
  sb.before = sbSeedNow()
  wait(d); tap("A")
  sb.d = d
  bot.st, bot.t = "sb_try", 0
end

local function sbNextW(reason)
  writeFile("seed_debug.txt", string.format("  siguiente arranque: %s\n", reason or "?"), "a")
  sb.w = sb.w + 1
  if sb.w > 400 then
    bot.msg = "No pude caer en esa semilla. Prueba otras semillas o el Initial Seed Bot de FRLG_RNG_2.0"
    print(bot.msg); stopBot(); return
  end
  if sb.K then
    sb.Kfix = 0
    sbBuildTitle()           -- mismo numero de pulsaciones, arrancando 1 frame despues
  else
    sbBeginW()
  end
end

local function sbPlan()
  -- semilla(d) = s1 + paso*(d - 1) (mod 65536)
  local step = (sb.s2 - sb.s1) % 65536
  local g = gcd(step, 65536)
  local m = 65536 / g
  local best = nil
  if step ~= 0 then
    local inv = modInv(floor(step / g), m)
    for _, t in ipairs(sb.targets) do
      local diff = (t - sb.s1) % 65536
      if inv and diff % g == 0 then
        local d = ((diff / g) * inv) % m + 1
        while d < 3 do d = d + m end
        if d <= 2400 and (not best or d < best.d) then best = { d = d, seed = t } end
      end
    end
  end
  return best
end

local function stepSeedBot()
  bot.t = bot.t + 1
  if bot.st == "sb_reset" then
    if #queue == 0 then
      sb.S0 = savestate.create(); savestate.save(sb.S0)
      sbBeginW()
    end
  elseif bot.st == "sb_find" then
    if bot.t > 5 and sbSeedSeen() then
      -- la semilla aparece ~1-2 s despues de la pulsacion (grito + fundido)
      sb.K = math.max(1, floor((bot.t - 130 - sb.w) / 8) + 1)
      sb.Kfix = 0
      sbBuildTitle()
    elseif bot.t > 3500 then
      bot.msg = "No se escribio ninguna semilla: revisa que el juego llegue al titulo"
      print(bot.msg); stopBot()
    end
  elseif bot.st == "sb_title" then
    if sbSeedSeen() then
      -- ya llego al titulo antes de lo pensado: una pulsacion menos
      sb.K = sb.K - 1; sb.Kfix = sb.Kfix + 1
      if sb.K < 1 or sb.Kfix > 40 then sbNextW("no ubico el titulo"); return end
      sbBuildTitle(); return
    end
    if #queue == 0 then
      sb.Stitle = savestate.create(); savestate.save(sb.Stitle)
      sb.phase, sb.s1, sb.s2 = 1, nil, nil
      sbTry(1)
    end
  elseif bot.st == "sb_try" then
    if bot.t > 5 and sbSeedSeen() then
      if bot.t < 15 then return end
      local seed = sbSeedNow()
      sb.tries = sb.tries + 1
      sb.last = seed
      writeFile("seed_debug.txt", string.format("w=%d K=%d d=%d fase=%d semilla=%04X\n", sb.w, sb.K or -1, sb.d, sb.phase or -1, seed), "a")
      bot.msg = string.format("Probada por el bot: semilla %04X (arranque %d, frame %d)", seed, sb.w, sb.d)
      for _, t in ipairs(sb.targets) do
        if seed == t then
          print(string.format("Semilla inicial %04X conseguida (%d pruebas)", seed, sb.tries))
          logLine(string.format("[SEMILLA] %04X conseguida tras %d pruebas", seed, sb.tries))
          local after = CONFIG.afterSeedMode
          local idx = nil
          if after then for i, mname in ipairs(MODES) do if simplify(mname) == simplify(after) then idx = i end end end
          if idx and idx ~= 10 then
            bot.mode = idx
            bot.noReseed = true
            bot.st, bot.t = "rboot", 0
            bot.msg = "Semilla lista: cargando la partida para " .. MODES[idx]
          else
            bot.found, bot.running, bot.st, bot.selfReset = true, false, "found", false
            bot.msg = string.format("Semilla %04X lista: continua la partida y usa el modo RNG", seed)
            emu.pause()
          end
          return
        end
      end
      if sb.phase == 1 then sb.s1 = seed; sb.phase = 2; sbTry(2); return end
      if sb.phase == 2 then
        sb.s2 = seed
        if sb.s2 == sb.s1 then
          -- misma semilla pulsando en frames distintos: una pulsacion anterior ya
          -- habia llegado al titulo. Guardar el titulo una pulsacion antes.
          sb.K = sb.K - 1; sb.Kfix = sb.Kfix + 1
          if sb.K < 1 or sb.Kfix > 40 then sbNextW("no ubico el titulo"); return end
          sbBuildTitle(); return
        end
        local plan = sbPlan()
        writeFile("seed_debug.txt", string.format("  paso=%d plan=%s\n", (sb.s2 - sb.s1) % 65536,
                  plan and string.format("d=%d -> %04X", plan.d, plan.seed) or "ninguno"), "a")
        if plan then sb.phase, sb.plan = 3, plan; sbTry(plan.d); return end
        sbNextW("sin objetivo con este arranque"); return
      end
      if sb.phase == 3 then sb.phase, sb.k = 4, 1 end
      if sb.phase == 4 then
        local offs = { -1, 1, -2, 2, -3, 3 }
        if sb.k <= #offs then
          local d = sb.plan.d + offs[sb.k]; sb.k = sb.k + 1
          if d >= 1 then sbTry(d); return end
        end
        sbNextW("prediccion fallida")
      end
    elseif bot.t > 400 then
      if sb.phase == 1 then
        -- el titulo aun no aceptaba A: una pulsacion mas antes de guardar
        sb.K = sb.K + 1; sb.Kfix = sb.Kfix + 1
        if sb.Kfix > 40 then sbNextW("no ubico el titulo"); return end
        sbBuildTitle(); return
      end
      sbNextW("el titulo no acepto la pulsacion")
    end
  end
end

-- ================== Salvaje RNG (hierba / cueva / surf) ===================
--  1. Prepara: camina (y huye) hasta llenar el contador de pasos minimos
--     entre encuentros. Desde ahi el paso del encuentro no depende del frame.
--  2. Savestate aqui; empieza a caminar y mide el retraso y el orden de
--     llamadas al RNG (calibracion).
--  3. Busca el objetivo (hasta millones de avances), llega con la Tele
--     Pokemon si esta lejos, y empieza a caminar en el avance exacto.
local function stepDir(i)
  local d1, d2 = "left", "right"
  if CONFIG.walkAxis == "vertical" then d1, d2 = "up", "down" end
  return (i % 2 == 1) and d1 or d2
end

-- El jugador esta quieto (gPlayerAvatar.runningState y tileTransitionState = 0)
local function playerStill()
  return read8(A.avatar + 2) == 0 and read8(A.avatar + 3) == 0
end

local function pushWildWalk()
  if rng.oneStep then
    push({ [rng.oneDir] = true }, CONFIG.walkFrames)   -- solo el paso final
    return
  end
  for i = 1, 400 do push({ [stepDir(i)] = true }, CONFIG.walkFrames) end
end

-- ------- Modo "a un paso": como lo harias a mano con RNG Reporter -------
-- Tras la primera calibracion ya sabemos en que paso sale el encuentro (N).
-- Camina N-1 pasos, se queda quieto y guarda ahi la base: desde ese punto
-- basta UN paso en el frame exacto. Caminar muchos pasos acumula variacion
-- (el juego gasta RNG de mas en algunos pasos); un solo paso casi no.
local function startApproach()
  savestate.load(rng.base0State)
  queue = {}
  zeroEnemy()
  for i = 1, rng.approachK do push({ [stepDir(i)] = true }, CONFIG.walkFrames) end
  wait(40)
  bot.st, bot.t = "approach", 0
end

local function oneStepFallback(reason)
  print("Modo a un paso desactivado (" .. reason .. "): sigo caminando desde la base")
  rng.noOneStep, rng.oneStep = true, false
  rngState, rng.seed0 = rng.base0State, rng.base0Seed
  rng.seed, rng.adv = rng.seed0, 0
  rng.baseFrame = rng.base0Frame
  wr.r, wr.built, wr.lastSeed = {}, 0, rng.seed0
  rng.delay, rng.pressAt, rng.stepsToEnc = nil, rng.preDelay, nil
  bot.st = "wbuild"
end

local function wildSetup()
  rebaseHere()
  rng.nextSearch = nil
  rng.delay, rng.target, rng.tries, rng.tried = nil, nil, 0, {}
  rng.stepsToEnc, rng.targetIvs, rng.targetSv, rng.failedTargets = nil, nil, nil, 0
  rng.anchors, far = nil, nil
  rng.calFails = 0
  rng.pressAt = rng.preDelay
  rng.base0State, rng.base0Seed, rng.base0Frame = rngState, rng.seed0, rng.baseFrame
  rng.oneStep, rng.noOneStep, rng.approachK = false, false, nil
  wr.layout = nil
  wr.water = band(read8(A.avatar), 0x08) ~= 0
  wr.info = currentWildInfo(wr.water)
  if filt.species and not wr.info then
    bot.msg = "No pude leer la tabla de encuentros: quita el filtro 'species'"
    print(bot.msg); bot.running = false; bot.st = "idle"; return
  end
  bot.st = "wbuild"
  print(string.format("Savestate listo. Zona: %s%s", wr.water and "agua" or "hierba/cueva",
        wr.info and string.format(" (tasa %d)", wr.info.rate) or " (tabla de encuentros no encontrada)"))
end

local function stepWildRng()
  if isReseedState() then stepReseed(); return end
  if bot.st == "flee" then stepWild(); return end
  if bot.st == "far" then stepFar(); return end

  if bot.st == "prep" then
    local mon = decodeMon(A.enemy)
    if mon then
      queue = {}
      if evaluate(mon) then return end
      bot.returnState = "prep"; enterFlee(false); bot.prepSteps = 0
      return
    end
    local sb1 = read32(A.sb1)
    if validPtr(sb1) then
      local pos = read32(sb1)
      local cnt = read8(A.wildData + 8)
      if bot.prepPos and pos ~= bot.prepPos then
        if cnt ~= bot.prepCnt then bot.prepSteps = 0 else bot.prepSteps = (bot.prepSteps or 0) + 1 end
      end
      bot.prepPos, bot.prepCnt = pos, cnt
      if (bot.prepSteps or 0) >= 2 then
        queue = {}; bot.st, bot.t = "settle", 0
        return
      end
    end
    bot.msg = string.format("Preparando: pasos %d (contador %d)", bot.prepSteps or 0, read8(A.wildData + 8))
    if #queue == 0 then pushWalk() end
    return
  end

  if bot.st == "settle" then
    bot.t = bot.t + 1
    if decodeMon(A.enemy) then bot.st = "prep"; return end
    if not playerStill() then bot.t = math.min(bot.t, 40) end
    if bot.t >= 60 then wildSetup() end
    return
  end

  if bot.st == "approach" then
    bot.t = bot.t + 1
    if decodeMon(A.enemy) then
      -- salio el encuentro antes: un paso menos
      rng.approachK = rng.approachK - 1
      if rng.approachK < 0 then oneStepFallback("el encuentro sale sin caminar"); return end
      startApproach(); return
    end
    if #queue == 0 then
      if playerStill() then rng.stillFrames = (rng.stillFrames or 0) + 1 else rng.stillFrames = 0 end
      if rng.stillFrames < 20 then return end
      rng.stillFrames = 0
      rebaseHere()
      zeroEnemy()
      rng.oneStep, rng.oneDir = true, stepDir(rng.approachK + 1)
      rng.delay, rng.pressAt, rng.stepsToEnc = nil, rng.preDelay, 1
      rng.anchors, far = nil, nil
      print(string.format("A un paso del encuentro (%d pasos caminados): calibro el paso final", rng.approachK))
      bot.st = "wbuild"
    end
    return
  end

  if bot.st == "wbuild" or bot.st == "wbuild2" then
    local need = (bot.st == "wbuild") and 40000 or (rng.target + 3000)
    bot.msg = string.format("Calculando avances... %d%%", floor(wr.built * 100 / need))
    if buildR(need, 100000) then
      if bot.st == "wbuild" then bot.msg = "Calibrando..." end
      bot.st = "wait"
      rngLoad()
    end
    return
  end

  bot.t = bot.t + 1
  if not trackAdvances() then stopLostSeed(); return end
  if bot.st:sub(1, 3) == "tv_" then stepTeachy(); return end

  if bot.st == "wait" then
    local early = (bot.t > 6 and not rng.noPrePressCheck) and decodeMon(A.enemy) or nil
    if early then
      -- salio un encuentro SIN pulsar: la base no estaba quieta. Rehacerla.
      rng.rebuilds = (rng.rebuilds or 0) + 1
      print(string.format("Encuentro antes de dar el paso (%s PID %08X): rehago la base con el jugador quieto",
            speciesName(early.species), early.pid))
      if rng.rebuilds > 2 then
        print("Se repite: dejo de revisar antes del paso")
        rng.noPrePressCheck = true
        zeroEnemy(); monWatch = {}
        return
      end
      if rng.oneStep and rng.base0State then
        rng.delay = nil
        startApproach()
      else
        rngLoad()
      end
      return
    end
    if rng.adv >= rng.pressAt then
      rng.pressedAdv, bot.t = rng.adv, 0
      pushWildWalk()
      rng.walkSteps, rng.lastPos = 0, nil
      bot.st = "walking"
    end
  elseif bot.st == "walking" then
    local sb1 = read32(A.sb1)
    if validPtr(sb1) then
      local pos = read32(sb1)
      if rng.lastPos and pos ~= rng.lastPos then rng.walkSteps = rng.walkSteps + 1 end
      rng.lastPos = pos
    end
    local mon = decodeMon(A.enemy)
    if mon then
      queue = {}
      rng.stepsToEnc = rng.walkSteps
      local level = read8(A.enemy + 0x54)
      if wr.built < rng.pressedAdv + 30000 then buildR(rng.pressedAdv + 30000, 10000000) end
      local expect = rng.delay and (rng.pressedAdv + rng.delay) or nil
      local E, lay, loose = findWildE(mon, level, rng.pressedAdv, expect, wr.layout)
      if not E and wr.layout then E, lay, loose = findWildE(mon, level, rng.pressedAdv, expect) end
      if evaluate(mon) then return end
      if not E and rng.delay and rng.target then
        -- en el objetivo: ese frame dio un encuentro que no cuadra (interrupcion
        -- del juego a mitad de generar). Probar el frame vecino.
        rng.tries = rng.tries + 1
        rng.tried[rng.pressedAdv] = true
        print(string.format("Intento %d: encuentro fuera del calculo (%s), pruebo el frame vecino", rng.tries,
              speciesName(mon.species)))
        local base = rng.target - rng.delay
        local cand = nil
        for _, off in ipairs({ 0, -1, 1, -2, 2, -3, 3 }) do
          if not rng.tried[base + off] then cand = base + off; break end
        end
        if not cand or rng.tries >= CONFIG.triesPerTarget then
          startFar(rng.target + 1); return
        end
        rng.pressAt = cand
        bot.st = "wait"; rngLoad(); return
      end
      if not E then
        rng.calFails = (rng.calFails or 0) + 1
        print(string.format("No ubique este encuentro en el RNG: %s Nv.%d PID %08X (%d)", speciesName(mon.species),
              level, mon.pid, rng.calFails))
        if rng.calFails >= 6 then
          bot.msg = "No pude calibrar aqui (mira la consola). Prueba otra parte de la zona."
          print(bot.msg); bot.running = false; bot.st = "idle"; return
        end
        rng.pressAt = rng.pressAt + 5      -- otro encuentro distinto
        bot.st = "wait"; rngLoad(); return
      end
      if loose then
        print(string.format("Aviso: el RNG coincide pero la especie/nivel no (tabla de la zona?). %s Nv.%d",
              speciesName(mon.species), level))
      end
      if not wr.layout or wr.layout ~= lay then
        wr.layout = lay
        if lay ~= LAYOUTS[1] then print("Orden de llamadas detectado: " .. lay.name) end
      end
      local d = E - rng.pressedAdv
      if not rng.delay then
        if CONFIG.wildOneStep ~= false and not rng.oneStep and not rng.noOneStep and (rng.stepsToEnc or 0) >= 1 then
          rng.approachK = math.max(rng.stepsToEnc - 1, 0)
          rng.stepsMeasured = rng.stepsToEnc
          print(string.format("El encuentro sale en el paso %d: me acerco a un paso", rng.stepsToEnc))
          startApproach()
          return
        end
        rng.delay = d
        print(string.format("Calibrado: retraso = %d avances", d))
        startFar(d + rng.preDelay + 10)
        return
      end
      rng.delay = d
      retryOrNext(E)
    elseif rng.oneStep and bot.t > 150 then
      if not rng.delay then
        -- el paso final no dio encuentro: faltaba un paso por caminar
        rng.approachK = rng.approachK + 1
        if rng.approachK > (rng.stepsMeasured or 0) + 3 then oneStepFallback("no encuentro el paso"); return end
        startApproach(); return
      end
      bot.timeouts = bot.timeouts + 1
      bot.st = "wait"; rngLoad()
    elseif bot.t > 8000 then
      bot.timeouts = bot.timeouts + 1
      bot.st = "wait"; rngLoad()
    end
  end
end

-- ------------------------------ Control ------------------------------
local function startBot()
  if bot.cfgError then
    bot.msg = "Corrige " .. CONFIG_FILE .. " (mira la consola) y pulsa 0"
    print(bot.msg); return
  end
  local tid, sid = playerIDs()
  if not tid and bot.mode ~= 9 then
    bot.msg = "Carga tu partida (en el mapa) antes de iniciar"
    print(bot.msg); return
  end
  bot.tid, bot.sid = tid, sid
  bot.baseParty = read8(A.partyCnt)
  if kind() == 3 and bot.baseParty >= 6 then
    bot.msg = "Equipo lleno: deja un espacio libre para el regalo"
    print(bot.msg); return
  end
  if kind() == 4 then
    local r = readRoamer()
    if r and r.active then
      bot.msg = "El roamer ya esta activo: usa un save de ANTES del evento"
      print(bot.msg); return
    end
  end
  bot.running, bot.found, bot.msg = true, false, ""
  bot.encounters, bot.timeouts, bot.startFrame = 0, 0, emu.framecount()
  bot.startTime = now_time()
  queue = {}
  bot.returnState, bot.selfReset, bot.reseeds, bot.seedsTried, bot.noReseed = nil, false, 0, 1, false
  if bot.mode == 1 then
    zeroEnemy(); bot.st = "walk"
  elseif bot.mode == 9 then
    ngStart()
  elseif bot.mode == 10 then
    sbStart()
  elseif isWildRng() then
    zeroEnemy()
    bot.prepPos, bot.prepCnt, bot.prepSteps = nil, nil, 0
    bot.st = "prep"
  elseif isRngMode() then
    rngStart()
  else
    bot.st = "reset"
  end
  if bot.mode == 9 then
    print(string.format("Bot iniciado: Partida nueva  (TID nuevo %d)", bot.tid))
  else
    print(string.format("Bot iniciado: %s  (TID %d / SID %d)", MODES[bot.mode], tid, sid))
  end
end

stopBot = function()
  bot.running, bot.st, bot.selfReset = false, "idle", false
  queue = {}
end

-- El juego se reinicio (soft reset, reset del emulador): limpiar todo
local function onGameReset()
  stopBot()
  bot.found, bot.last, bot.tid, bot.sid = false, nil, nil, nil
  bot.encounters, bot.timeouts, bot.startFrame = 0, 0, emu.framecount()
  rng.seed0, rng.target, rng.delay, rng.pressAt = nil, nil, nil, nil
  rngState = nil
  wr.r, wr.built = {}, 0
  bot.msg = "Juego reiniciado: carga tu partida y pulsa 7"
  print(bot.msg)
end

local resetFrames = 0
local function watchGameReset()
  -- en los modos con soft reset el propio bot reinicia el juego
  if bot.running and ((kind() >= 2 and not isRngMode()) or bot.selfReset) then resetFrames = 0; return end
  if validPtr(read32(A.sb1)) then resetFrames = 0; return end
  resetFrames = resetFrames + 1
  if resetFrames == 10 and (bot.running or bot.last or bot.tid or bot.msg ~= "") then onGameReset() end
end

local reloadConfig
local function applyModeFromConfig()
  if CONFIG.mode then
    for i, m in ipairs(MODES) do
      if simplify(m) == simplify(CONFIG.mode) then bot.mode = i end
    end
  end
end

local function reportConfig(ok, msg, problems)
  bot.cfgError = (not ok) or #problems > 0
  if not ok then
    bot.msg = "Error en " .. CONFIG_FILE .. ": " .. tostring(msg)
  elseif msg == "no existe" then
    bot.msg = "No hay " .. CONFIG_FILE .. ": uso la configuracion por defecto"
  elseif #problems > 0 then
    bot.msg = "Config: " .. problems[1] .. (#problems > 1 and string.format(" (+%d)", #problems - 1) or "")
  else
    bot.msg = "Config cargada"
  end
  print(bot.msg)
  for i = 2, #problems do print("Config: " .. problems[i]) end
end

reloadConfig = function()
  local ok, msg, problems = loadConfig()
  applyModeFromConfig()
  reportConfig(ok, msg, problems)
end

local prevKeys = {}  -- (reloadConfig definido arriba)
local function pressed(k, keys)
  return (keys[k] or keys["numpad" .. k]) and not (prevKeys[k] or prevKeys["numpad" .. k])
end

local function handleHotkeys()
  local keys = input.get()
  if pressed("7", keys) then
    if bot.running then stopBot(); bot.msg = "" elseif bot.found then bot.found = false; bot.st = "idle" else startBot() end
  elseif pressed("8", keys) and not bot.running then
    bot.mode = bot.mode % #MODES + 1
    bot.found, bot.msg = false, ""
  elseif pressed("9", keys) then
    bot.panel = (bot.panel + 1) % 3
  elseif pressed("0", keys) and not bot.running then
    reloadConfig()
  end
  prevKeys = keys
end

-- ------------------------------- Panel -------------------------------
local function filterSummary()
  local parts = {}
  parts[#parts + 1] = filt.shiny and "Shiny" or "Sin shiny"
  if filt.species and (bot.mode == 1 or bot.mode == 8) then
    local t = {}
    for _, n in ipairs(toList(CONFIG.species) or {}) do t[#t + 1] = tostring(n) end
    parts[#parts + 1] = table.concat(t, "/")
  end
  if filt.natures then
    local t = {}
    for n in pairs(filt.natures) do t[#t + 1] = n end
    parts[#parts + 1] = table.concat(t, "/")
  end
  local ivs, any = {}, false
  for i = 1, 6 do
    local lo, hi = filt.minIV[i], filt.maxIV[i]
    if lo == hi then ivs[i] = tostring(lo); any = true
    elseif lo > 0 or hi < 31 then ivs[i] = lo .. "-" .. hi; any = true
    else ivs[i] = "x" end
  end
  if any then parts[#parts + 1] = "IVs " .. table.concat(ivs, "/") end
  if filt.minIVTotal then parts[#parts + 1] = "Total>=" .. filt.minIVTotal end
  if filt.hpType or filt.hpPower then
    parts[#parts + 1] = "PO " .. (filt.hpType and HP_TYPES[filt.hpType] or "") .. (filt.hpPower and (">=" .. filt.hpPower) or "")
  end
  return table.concat(parts, ", ")
end

local function monLines(y, label, sp, pid, sv, ivs, color)
  local tag = ""
  if sv and sv < 8 then tag = (sv == 0) and " (Square)" or " (Star)" end
  gui.text(1, y, string.format("%s %sPID %08X%s  %s", label, sp and (speciesName(sp) .. "  ") or "", pid, tag,
           natureOf(pid)), color)
  if ivs then
    local t, pw = hiddenPowerOf(ivs)
    gui.text(1, y + 9, string.format("   IVs %s   PO %s %d", table.concat(ivs, "/"), HP_TYPES[t], pw), color)
  end
end

-- Panel compacto: solo lo que se usa en cada momento (2-4 lineas arriba)
local PHASE_SHORT = { prep = "Preparando", settle = "Preparando", wbuild = "Calculando", wbuild2 = "Calculando",
  far = "Buscando objetivo", wait = "Esperando", pressed = "Comprobando", walking = "Caminando",
  flee = "Huyendo", tv_open = "Abriendo Tele", tv_run = "Tele", tv_exit = "Cerrando Tele",
  tv_settle = "Cerrando Tele", rboot = "Nueva semilla", rquest = "Nueva semilla", rsettle = "Nueva semilla",
  walk = "Caminando", reset = "Reset", boot = "Reset", idle = "Detenido", found = "ENCONTRADO",
  sb_reset = "Reiniciando", sb_find = "Buscando el titulo", sb_title = "Preparando titulo",
  sb_try = "Probando semilla", approach = "Acercandose a un paso" }

local function drawCompact()
  local y = 1
  local function line(text, color) gui.text(1, y, text, color); y = y + 9 end
  local m = bot.mode
  local status
  if bot.found then status = "ENCONTRADO"
  elseif not bot.running then status = "OFF"
  else
    status = PHASE_SHORT[bot.st] or bot.st
    if (m >= 5) and bot.st == "wait" and not rng.delay then status = "Calibrando" end
  end
  line(string.format("#%d %s: %s", INSTANCE, MODES[m], status), bot.found and "green" or nil)

  if not bot.running and not bot.found then
    line("7 iniciar  8 modo  9 panel  0 config")
    line("Busca: " .. filterSummary())
  elseif m == 10 then
    line(string.format("Arranque %d   semillas probadas %d   ultima %s", sb.w or 0, sb.tries or 0,
         sb.last and string.format("%04X", sb.last) or "-"))
  elseif m == 9 then
    if bot.found then
      line(string.format("TID %d  SID %d  (xor %04X)", bot.tid or 0, bot.sid or 0, bxor(bot.tid or 0, bot.sid or 0)), "green")
    else
      line(string.format("TID %d   SID objetivo: %s", bot.tid or 0, rng.targetSid and tostring(rng.targetSid) or "?"))
      if bot.st == "wait" and rng.pressAt then
        line(string.format("Pulsar A en %d frames   intento %d", math.max(rng.pressAt - (rng.adv or 0), 0), rng.tries or 0))
      elseif bot.st == "ngsearch" then line(bot.msg) end
    end
  elseif m <= 4 then
    local label = (m == 1) and "Encuentros" or "Resets"
    local t = string.format("%s: %d", label, bot.encounters)
    if filt.shiny then t = t .. string.format("   Prob: %.1f%%", (1 - (8191 / 8192) ^ bot.encounters) * 100) end
    line(t)
  else
    if rng.target then
      local sp = (m == 8) and slotSpecies(rng.targetSlot) or nil
      local star = (rng.targetSv and rng.targetSv < 8) and " *" or ""
      line(string.format("Objetivo: %s%s%s  avance %d", sp and (speciesName(sp) .. " ") or "",
           natureOf(rng.targetPid), star, rng.target), "green")
      if bot.st == "tv_run" or bot.st == "tv_open" then
        local left = math.max(rng.pressAt - teachyMargin() - rng.adv, 0)
        line(string.format("Tele: faltan %d avances (~%d frames)", left, floor(left / 313)))
      elseif bot.st == "wait" and rng.pressAt then
        line(string.format("%s en %d frames", (m == 8) and "Caminar" or "Pulsar A",
             math.max(rng.pressAt - (rng.adv or 0), 0)))
      elseif bot.st == "walking" and rng.stepsToEnc then
        line(string.format("Paso %d de %d   intento %d", rng.walkSteps or 0, rng.stepsToEnc, rng.tries or 0))
      elseif bot.st == "pressed" then
        line(string.format("Intento %d", rng.tries or 0))
      end
    elseif bot.st == "far" or bot.st == "wbuild" or bot.st == "wbuild2" or bot.st == "prep" then
      line(bot.msg)
    end
  end
  if bot.found and bot.last and m ~= 9 then
    local l = bot.last
    line(string.format("%s %s  IVs %s", speciesName(l.species), natureOf(l.pid), table.concat(l.ivs, "/")), "green")
  end
  -- avisos importantes abajo (errores, encontrado)
  if bot.msg ~= "" and (bot.found or not bot.running) then gui.text(1, 150, bot.msg, "orange") end
end

local function draw()
  if bot.panel == 0 then return end
  if bot.panel == 1 then drawCompact(); return end
  local y = 1
  local function line(text, color) gui.text(1, y, text, color); y = y + 9 end
  local status = bot.found and "ENCONTRADO" or (bot.running and "ON" or "OFF")
  line(string.format("#%d %s [%s]  7 on/off 8 modo 9 panel 0 config", INSTANCE, MODES[bot.mode], status),
       bot.found and "green" or nil)
  line("Busca: " .. filterSummary())
  if bot.tid then line(string.format("TID %d  SID %d", bot.tid, bot.sid)) end
  -- Semilla inicial (la que fija el titulo; misma direccion que FRLG_RNG_2.0) y semilla actual
  local seedLine = string.format("Semilla inicial: %04X   Actual: %08X", read16(0x02020000), read32(A.currSeed))
  if (bot.mode >= 5) and rng.seed0 then seedLine = seedLine .. string.format("   Base: %08X", rng.seed0) end
  line(seedLine)
  local frameText
  if ft.frame then frameText = tostring(ft.frame)
  elseif ft.sSeed then frameText = string.format("calculando... (%d)", ft.sK)
  else frameText = "?" end
  line(string.format("Frame: %s   (frame del emulador: %d)", frameText, emu.framecount()))

  local m = bot.mode
  if m <= 4 then
    -- Caza a ciegas: lo util es cuantos intentos van y la probabilidad acumulada
    local frames = emu.framecount() - bot.startFrame
    local perHour = 0
    if bot.encounters > 0 and frames > 0 then perHour = floor(bot.encounters * 216000 / frames) end
    local label = (m == 1) and "Encuentros" or "Resets"
    line(string.format("%s: %d   (%d por hora de juego)", label, bot.encounters, perHour))
    if filt.shiny then
      line(string.format("Prob. de haber visto un shiny: %.1f%%", (1 - (8191 / 8192) ^ bot.encounters) * 100))
    end
    if m == 1 then
      line(string.format("Combate:%s Cursor:%d Res:%d%s", inBattle() and "1" or "0",
           band(read8(A.actionCursor), 3), read8(A.battleOutcome), gMainVerified and "" or " (?)"))
    elseif bot.timeouts > 0 then
      line("Timeouts: " .. bot.timeouts)
    end
  else
    -- RNG: lo util es el objetivo y cuanto falta
    local phase = ({ prep = "Preparando", settle = "Preparando", wbuild = "Calculando", search = "Buscando",
      wsearch = "Buscando", wait = rng.delay and "Esperando el frame" or "Calibrando",
      pressed = "Comprobando", walking = "Caminando", flee = "Huyendo", idle = "Detenido",
      found = "Encontrado", rboot = "Nueva semilla (reset)", rquest = "Nueva semilla (cargando)",
      rsettle = "Nueva semilla (cargando)", far = "Buscando objetivo", wbuild2 = "Calculando",
      tv_open = "Abriendo la Tele", tv_run = "Tele Pokemon (avance rapido)", tv_exit = "Cerrando la Tele",
      tv_settle = "Cerrando la Tele", sb_reset = "Reiniciando", sb_find = "Buscando el titulo",
      sb_title = "Preparando titulo", sb_try = "Probando semilla", approach = "Acercandose a un paso" })[bot.st] or bot.st
    line(string.format("Fase: %s   Intento: %d   Semilla #%d", phase, rng.tries or 0, bot.seedsTried or 1))
    if m == 8 then
      if bot.st == "prep" or bot.st == "settle" then
        line(string.format("Contador de pasos: %d   pasos sin cambio: %d/2", read8(A.wildData + 8), bot.prepSteps or 0))
      elseif wr.water ~= nil then
        line(string.format("Zona: %s%s", wr.water and "agua" or "hierba/cueva",
             wr.info and string.format("  (tasa %d)", wr.info.rate) or ""))
      end
    end
    if rng.seed0 then
      line(string.format("Avance: %d   Retraso: %s", rng.adv or 0, rng.delay and tostring(rng.delay) or "?"))
    end
    if m == 8 and rng.stepsToEnc then
      local now = (bot.st == "walking") and string.format("   (paso %d)", rng.walkSteps or 0) or ""
      line(string.format("Pasos hasta el encuentro: %d%s", rng.stepsToEnc, now))
    end
    if m == 10 then
      line(string.format("Arranque %d   semillas probadas %d   ultima %s", sb.w or 0, sb.tries or 0,
           sb.last and string.format("%04X", sb.last) or "-"))
    end
    if rng.target and m == 9 then
      line(string.format("TID %d  SID objetivo %d  en el avance %d", bot.tid or 0, rng.targetSid or 0, rng.target), "green")
    elseif rng.target then
      local sp = nil
      if m == 8 then sp = slotSpecies(rng.targetSlot) end
      monLines(y, "Objetivo:", sp, rng.targetPid, rng.targetSv, rng.targetIvs, "green"); y = y + 18
      local absF = rng.baseFrame and (rng.baseFrame + rng.target) or nil
      line(string.format("   en el avance %d%s", rng.target,
           absF and string.format("  (frame %d desde la semilla inicial)", absF) or ""), "green")
      if bot.st == "tv_run" or bot.st == "tv_open" then
        local left = math.max(rng.pressAt - teachyMargin() - rng.adv, 0)
        line(string.format("Tele: faltan %d avances para cerrarla (~%d frames)", left, floor(left / 313)), "green")
      end
      if bot.st == "wait" and rng.pressAt then
        local left = math.max(rng.pressAt - (rng.adv or 0), 0)
        local verb = (m == 8) and "Empieza a caminar" or "Pulsa A"
        line(string.format("%s en: %d frames (~%d s a 60 fps)", verb, left, floor(left / 60)), "green")
      end
    end
  end

  local last = bot.last
  if last then
    local color = (last.sv and last.sv < 8) and "green" or nil
    monLines(y + 2, "Ultimo:", last.species, last.pid, last.sv, last.ivs, color); y = y + 20
  end
  if bot.msg ~= "" then gui.text(1, 150, bot.msg, "orange") end
end

-- ------------------------------- Inicio ------------------------------
print("FRLG Shiny Bot v4.3  (direcciones: Devon Studios x Real.96)")
if not gameName then
  print("Este ROM no es Rojo Fuego / Verde Hoja. El bot no se ejecutara.")
  return
end
print(string.format("Juego: %s  idioma 0x%02X  rev %s", gameName, gameLang, gameRev1 and "1.1" or "1.0"))
if not gMainVerified then
  print("Aviso: la bandera de combate no esta verificada para este idioma (revisa 'Combate' en el panel).")
end
print(string.format("Instancia %d   archivos generados en: %s", INSTANCE, LOGDIR ~= "" and LOGDIR or "(carpeta actual)"))
print("7 = iniciar/detener   8 = cambiar modo   9 = panel (compacto/completo/oculto)   0 = recargar " .. CONFIG_FILE)
applyModeFromConfig()
reportConfig(cfgOk, cfgMsg, cfgProblems)

-- Revisa cada ~2 s si otra instancia encontro un shiny
local function checkStopFlag()
  if not CONFIG.stopOthers or not bot.running then return end
  if emu.framecount() % 120 ~= 0 then return end
  local data = readFile("shiny_stop.flag")
  if not data then return end
  local t, tok, who, name = data:match("(%d+)%s+(%w+)%s+(%d+)%s*(.*)")
  t, who = tonumber(t), tonumber(who)
  if t and tok and tok ~= TOKEN and t >= (bot.startTime or 0) then
    stopBot()
    bot.msg = string.format("Detenido: la instancia %d encontro %s shiny", who, name or "?")
    print(bot.msg)
    emu.pause()
  end
end

-- Reinicio del juego al cargar el script
local bootResetFrames = CONFIG.resetOnLoad and 3 or 0

while true do
  if bootResetFrames > 0 then
    joypad.set(1, { A = true, B = true, select = true, start = true })
    bootResetFrames = bootResetFrames - 1
  end
  gFrame = gFrame + 1
  if pendingZero > 0 then zeroEnemy(); pendingZero = pendingZero - 1 end
  heartbeat()
  watchGameReset()
  if not (bot.running and bot.st:sub(1, 3) == "sb_") then updateFrameTracker() end
  handleHotkeys()
  checkStopFlag()
  if bot.running then
    if bot.mode == 1 then stepWild() elseif isWildRng() then stepWildRng() elseif bot.mode == 9 then stepNewGame()
    elseif bot.mode == 10 then stepSeedBot()
    elseif isRngMode() then stepRng() else stepReset() end
    runQueue()
  end
  draw()
  emu.frameadvance()
end
