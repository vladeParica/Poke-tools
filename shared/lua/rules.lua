-- Pure decision rules (ADR-0015): they take data and never read memory, so they are unit
-- tested without the emulator (shared/tests/test_rules.py). The bots read the game and ask.
local Rules = (function()
  local R = {
    -- pret battle_main.c IsRunningFromBattleImpossible and constants/*.h
    ITEM_SMOKE_BALL = 194, AB_RUN_AWAY = 50, AB_SHADOW_TAG = 23, AB_ARENA_TRAP = 71, AB_MAGNET_PULL = 42,
    AB_LEVITATE = 26, TYPE_FLYING = 2, TYPE_STEEL = 8,
    STATUS2_TRAPPED = 0x0400E000,              -- STATUS2_ESCAPE_PREVENTION | STATUS2_WRAPPED
  }

  -- Can't run from this wild battle? me = {item, ability, type1, type2, trappedBits} (yours),
  -- foe = {ability}. Returns the trapping ability id, "move" (Mean Look, Wrap...) or nil.
  function R.trappedBy(me, foe)
    if me.item == R.ITEM_SMOKE_BALL or me.ability == R.AB_RUN_AWAY then return nil end
    local a = foe.ability
    if a == R.AB_SHADOW_TAG then return a end
    if a == R.AB_ARENA_TRAP and me.ability ~= R.AB_LEVITATE and me.type1 ~= R.TYPE_FLYING
       and me.type2 ~= R.TYPE_FLYING then return a end
    if a == R.AB_MAGNET_PULL and (me.type1 == R.TYPE_STEEL or me.type2 == R.TYPE_STEEL) then return a end
    if me.trappedBits and me.trappedBits ~= 0 then return "move" end
    return nil
  end

  -- What beating a Pokemon that gives `gain` EVs does to `evs` (6 stats, memory order) with the
  -- goal `target`. Returns over, useful: `over` is the first stat index pushed past the goal
  -- (allowOvershoot only allows it for stats that are part of the goal), `useful` whether any
  -- missing stat grows. Caps: 255 per stat, 510 in total.
  function R.evStep(evs, gain, target, allowOvershoot)
    local total = 0
    for i = 1, 6 do total = total + evs[i] end
    local room, useful = 510 - total, false
    for i = 1, 6 do
      if gain[i] > 0 and room > 0 and evs[i] < 255 then
        local after = evs[i] + math.min(gain[i], 255 - evs[i], room)
        if after > target[i] and not (allowOvershoot and target[i] > 0) then return i, useful end
        if evs[i] < target[i] then useful = true end
      end
    end
    return nil, useful
  end
  return R
end)()
