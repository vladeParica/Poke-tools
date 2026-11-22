-- Party / START menu automation and the escape rules, shared by the Train Bot and the Farm Bot
-- (ADR-0015). Every menu step is checked in memory. Included where the bot already defines:
-- A, read8/read16/read32, band, rshift, bot, queue, tap, halt, logLine, notify, stopBot,
-- zeroEnemy, inOverworld, partyCount, readPartyMon, lead, speciesName, battleMon,
-- TT_ITEMNAME, TT_ABILNAME, TX, Game (shared/lua/game.lua) and Rules (shared/lua/rules.lua).
local Menus = (function()
  local M = {
    OPT_ITEM = 3, OPT_TAKE = 5, OPT_SHIFT = 10, OPT_SEND_OUT = 11,   -- CURSOR_OPTION_* (party_menu.h)
    STARTMENU_POKEMON = 1, CMD_CHOOSEPOKEMON = 22,                    -- CONTROLLER_CHOOSEPOKEMON
  }
  M.MENU = Game.menu

  function M.itemName(id) return TT_ITEMNAME[id] or ("#" .. id) end
  function M.mon(i) return readPartyMon(A.party + i * 0x64) end
  function M.taskActive(fnAddr)
    for i = 0, 15 do
      local t = M.MENU.tasks + i * 40
      if read8(t + 4) ~= 0 and read32(t) == fnAddr then return true end
    end
    return false
  end
  function M.s8(v) if v >= 0x80 then return v - 0x100 end return v end
  -- the action list of the selected Pokemon (SUMMARY, SWITCH, ITEM...)
  function M.actions()
    local p = read32(M.MENU.partyInternal)
    if p < 0x02000000 or p >= 0x02040000 then return {} end
    local n, t = read8(p + 0x17), {}
    if n > 8 then return {} end
    for k = 0, n - 1 do t[#t + 1] = read8(p + 0x0F + k) end
    return t
  end
  function M.indexOf(list, v) for k, x in ipairs(list) do if x == v then return k - 1 end end return nil end
  function M.cursorTo(cur, want) if want > cur then tap("down", 8) else tap("up", 8) end end

  -- In a wild battle the game asks for another Pokemon: the lead fainted and "Use next Pokemon?
  -- NO" could not run away. That party screen can't be closed with B, and its cursor starts on
  -- the fainted lead. Send out the healthy Pokemon with the highest level (never an egg) and
  -- run (bot.forceRun). After the battle the party is back in field order
  -- (UpdatePartyToFieldOrder), so the fainted lead is still first and goes to heal.
  function M.sendOut()
    local MENU = M.MENU
    if not MENU then
      halt(TX"Tu Pokemon se debilito y el juego pide otro: eligelo tu, huye y pulsa 7")
      return
    end
    bot.fight, bot.forceRun, bot.lastWhy = false, true, TX"debilitado: huir"
    if not bot.sendSlot then
      local best, lv
      for i = 1, partyCount() - 1 do
        local m = M.mon(i)
        if m and m.hp > 0 and band(rshift(m.ivWord, 30), 1) == 0 and (not lv or m.level > lv) then best, lv = i, m.level end
      end
      if not best then halt(TX"Tu Pokemon se debilito y no queda otro sano: eligelo tu y pulsa 7"); return end
      bot.sendSlot, bot.sendT = best, 0
      local l, s = lead(), M.mon(best)
      logLine(string.format(TX"%s se debilito: saco a %s (Nv.%d) para huir", l and speciesName(l.species) or "?",
        speciesName(s.species), s.level))
    end
    bot.sendT = bot.sendT + 1
    if bot.sendT > 1800 then halt(TX"No pude sacar otro Pokemon: eligelo tu, huye y pulsa 7"); return end
    if M.taskActive(MENU.taskSelection) then
      -- SHIFT / SUMMARY / CANCEL: pick SHIFT (or SEND OUT)
      local acts = M.actions()
      local want = M.indexOf(acts, M.OPT_SHIFT) or M.indexOf(acts, M.OPT_SEND_OUT)
      if not want then tap("B", 10); return end
      local cur = M.s8(read8(MENU.menuCursor))
      if cur == want then tap("A", 20) else M.cursorTo(cur, want) end
      return
    end
    if not M.taskActive(MENU.taskChooseMon) then
      if bot.sendT % 40 == 0 then tap("B", 10) end      -- a message over the party screen
      return
    end
    local cur = M.s8(read8(MENU.partyMenu + 9))
    if cur == bot.sendSlot then tap("A", 20)
    elseif cur < bot.sendSlot or cur > 5 then tap("down", 8) else tap("up", 8) end
  end

  -- Why this wild battle can't be run from (text for the log), or nil. Reads gBattleMons
  -- (0 = yours, 1 = the wild one; 0x58 bytes each) and asks Rules.trappedBy.
  function M.trapped()
    local b0, b1 = A.battleMons, A.battleMons + 0x58
    local why = Rules.trappedBy(
      { item = read16(b0 + 0x2E), ability = read8(b0 + 0x20), type1 = read8(b0 + 0x21), type2 = read8(b0 + 0x22),
        trappedBits = band(read32(b0 + 0x50), Rules.STATUS2_TRAPPED) },
      { ability = read8(b1 + 0x20) })
    if why == "move" then return TX"atrapado por un ataque" end
    return why and (TT_ABILNAME[why] or "?") or nil
  end
  -- Any move with PP left (when it has to fight but no move is "useful")
  function M.anyMove(blocked)
    local me = battleMon(0)
    for k = 1, 4 do
      if me.moves[k] ~= 0 and me.pp[k] > 0 and not (blocked and blocked[k]) then return k end
    end
    return nil
  end

  -- Take held items: START > POKEMON > (Pokemon) > ITEM > TAKE, checking every step in memory.
  -- held = { {slot, item}, ... }; pause = pause and tell the player instead (or no verified menus);
  -- resume = what to do once the menus are closed again.
  function M.beginTake(held, pause, resume)
    local names = {}
    for _, h in ipairs(held) do names[#names + 1] = M.itemName(h.item) end
    if pause or not M.MENU then
      stopBot()
      bot.msg = TX"Quita los objetos (START > POKEMON > OBJETO > QUITAR): " .. table.concat(names, ", ") .. TX". Luego pulsa 7"
      logLine(bot.msg)
      notify(TX"Quita los objetos del equipo: " .. table.concat(names, ", "))
      Game.pauseSoon()
      return
    end
    logLine(TX"Guardando en la mochila: " .. table.concat(names, ", "))
    queue = {}
    zeroEnemy()
    bot.take = { list = held, i = 1, phase = "settle", tries = 0, resume = resume }
    bot.st, bot.t = "take", 0
  end
  function M.stepTake()
    bot.t = bot.t + 1
    if #queue > 0 then return end
    local T, MENU = bot.take, M.MENU
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
      if not M.taskActive(MENU.taskStartMenu) then
        if bot.t > 90 then
          T.tries = T.tries + 1
          if T.tries > 3 then fail(TX"el menu START no se abre") return end
          go("settle")
        end
        return
      end
      local n = read8(MENU.startCount)
      local want
      for k = 0, math.min(n, 9) - 1 do if read8(MENU.startOrder + k) == M.STARTMENU_POKEMON then want = k end end
      if not want then fail(TX"no hay opcion POKEMON en el menu START") return end
      local cur = read8(MENU.startCursor)
      if cur == want then tap("A", 30); go("party")
      elseif bot.t > 300 then fail(TX"el cursor del menu START no llega a POKEMON")
      else M.cursorTo(cur, want) end
    elseif T.phase == "party" then
      if read32(A.callback2) == MENU.cbParty and M.taskActive(MENU.taskChooseMon) then
        T.ready = (T.ready or 0) + 1
        if T.ready > 20 then T.ready = nil; go("pick") end
      elseif bot.t > 600 then fail(TX"no se abrio la pantalla del equipo") end
    elseif T.phase == "pick" then
      local e = T.list[T.i]
      if not e then go("exit") return end
      local m = M.mon(e.slot)
      if not m or m.item == 0 then T.i = T.i + 1 return end
      if not M.taskActive(MENU.taskChooseMon) then
        if bot.t > 300 then fail(TX"la pantalla del equipo no responde") end
        if bot.t % 30 == 0 then tap("B", 10) end
        return
      end
      local cur = M.s8(read8(MENU.partyMenu + 9))
      if cur == e.slot then tap("A", 20); go("actions")
      elseif bot.t > 300 then fail(TX"no llego al Pokemon " .. (e.slot + 1))
      elseif cur < e.slot or cur > 5 then tap("down", 8) else tap("up", 8) end
    elseif T.phase == "actions" or T.phase == "itemmenu" then
      local opt = (T.phase == "actions") and M.OPT_ITEM or M.OPT_TAKE
      local acts = M.actions()
      local want = M.taskActive(MENU.taskSelection) and M.indexOf(acts, opt) or nil
      if not want then
        if bot.t > 240 then fail(T.phase == "actions" and TX"no aparece OBJETO" or TX"no aparece QUITAR") end
        return
      end
      local cur = M.s8(read8(MENU.menuCursor))
      if cur == want then
        tap("A", 20)
        if T.phase == "actions" then go("itemmenu") else go("taking") end
      elseif bot.t > 240 then fail(TX"el cursor no llega a la opcion")
      else M.cursorTo(cur, want) end
    elseif T.phase == "taking" then
      local e = T.list[T.i]
      local m = M.mon(e.slot)
      if m and m.item == 0 then
        -- "Received X": close the message and go back to the party list
        if M.taskActive(MENU.taskChooseMon) and bot.t > 30 then T.i = T.i + 1; go("pick") return end
        if bot.t % 12 == 0 then tap("B", 8) end
      elseif bot.t > 240 then
        fail(TX"la mochila no tiene espacio para " .. M.itemName(e.item))
      end
    elseif T.phase == "exit" then
      -- leave the party and close the START menu (B until on the map with no menu)
      local onMap = inOverworld() and not M.taskActive(MENU.taskStartMenu)
      if onMap then T.ow = (T.ow or 0) + 1 else T.ow = 0 end
      if T.ow >= 40 then
        local resume = T.resume
        bot.take = nil
        bot.st, bot.t = "after", 0
        resume()
        return
      end
      if not onMap and bot.t % 20 == 0 then tap("B", 10) end
      if bot.t > 1200 then fail(TX"no pude cerrar los menus") end
    end
  end
  -- pret BattleScript_AskToLearnMove: "Delete a move to make room for X?" and "Stop learning X?" need
  -- no button; the script waits for them (waitstate 0x3A, setbyte 0x2E) and then shows the YES/NO
  -- box (0x5A / 0x5B). A B pressed for "the text" can land on the box's first frame: NO, and NO on
  -- "Stop learning?" asks the whole question again, the same way every time (an endless loop).
  -- True while the battle script is in that wait, so the bots press nothing.
  function M.learnBoxAhead(sp)
    if sp < 0x08000000 or sp >= 0x0A000000 then return false end
    local p = sp
    for _ = 1, 4 do
      local op = read8(p)
      if op == 0x5A or op == 0x5B then return p ~= sp end
      if op == 0x3A then p = p + 1 elseif op == 0x2E then p = p + 6 else return false end
    end
    return false
  end
  return M
end)()
