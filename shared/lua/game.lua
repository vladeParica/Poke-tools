-- Game profile (ADR-0015): what changes between FireRed / LeafGreen builds, in one place.
-- Included right after the bot reads the ROM header (gameLang, gameName, gameRev1).
local Game = (function()
  local G = {}
  local build = gameName and (gameName .. (gameRev1 and "1" or "0"))
  if gameLang == 0x45 and build then
    -- Field menus (pokefirered "symbols" branch). RAM is the same in the four USA builds
    -- (FireRed / LeafGreen 1.0 and 1.1); the functions differ. Other builds: no verified map,
    -- so taking items falls back to pausing.
    local fn = ({
      FireRed0   = { 0x0806F1F0, 0x0811EBA0, 0x0811FB28, 0x08122C5C, 0x0810C670 },
      FireRed1   = { 0x0806F204, 0x0811EC18, 0x0811FBA0, 0x08122CD4, 0x0810C6E8 },
      LeafGreen0 = { 0x0806F1F0, 0x0811EB78, 0x0811FB00, 0x08122C34, 0x0810C648 },
      LeafGreen1 = { 0x0806F204, 0x0811EBF0, 0x0811FB78, 0x08122CAC, 0x0810C6C0 },
    })[build]
    if fn then
      G.menu = {
        startCursor = 0x020370F4, startCount = 0x020370F5, startOrder = 0x020370F6,
        partyMenu = 0x0203B0A0, partyInternal = 0x0203B09C, menuCursor = 0x0203ADE6, tasks = 0x03005090,
        -- functions (+1: Thumb code)
        taskStartMenu = fn[1] + 1, cbParty = fn[2] + 1, taskChooseMon = fn[3] + 1, taskSelection = fn[4] + 1,
        taskVsSeeker = fn[5] + 1,
      }
    end
    -- gWildMonHeaders (pret symbols): in LeafGreen 1.1 the FireRed 1.0 address falls on the
    -- table's 18th header, so the right one per build matters
    G.wildHeaders = ({ FireRed0 = 0x083C9CB8, FireRed1 = 0x083C9D28,
                       LeafGreen0 = 0x083C9AF4, LeafGreen1 = 0x083C9B64 })[build]
    -- Task_Fishing (pret symbols, +1: Thumb code), to find the fishing task in gTasks
    local fishing = ({ FireRed0 = 0x0805D304, FireRed1 = 0x0805D318,
                       LeafGreen0 = 0x0805D304, LeafGreen1 = 0x0805D318 })[build]
    G.taskFishing = fishing and (fishing + 1)
    -- VMap (the loaded map: width, height, pointer to one u16 per tile, top 4 bits = elevation) and
    -- gPlayerAvatar (flags: 0x08 surfing); RAM, the same in the four USA builds
    G.vmap, G.avatar = 0x03005040, 0x02037078
  end
  -- Elevation of a tile of the loaded map, in object coordinates (MAP_OFFSET included), or nil
  function G.elevationAt(x, y)
    if not G.vmap then return nil end
    local w, h, map = read32(G.vmap), read32(G.vmap + 4), read32(G.vmap + 8)
    if x < 0 or y < 0 or x >= w or y >= h or map < 0x02000000 or map >= 0x02040000 then return nil end
    return math.floor(read16(map + 2 * (x + y * w)) / 4096)
  end
  -- On foot at (x, y) and the next tile (nx, ny) is water to surf on? As pret
  -- IsPlayerFacingSurfableFishableWater: the tile ahead has another elevation; water is elevation 1.
  function G.surfable(x, y, nx, ny)
    if not G.vmap or math.floor(read8(G.avatar) / 8) % 2 == 1 then return false end
    local here, ahead = G.elevationAt(x, y), G.elevationAt(nx, ny)
    return ahead == 1 and here ~= nil and here ~= 1
  end
  -- Pausing the emulator. In VBA-rr emu.pause() yields the script like emu.frameadvance(), and
  -- Lua 5.1 can't yield inside pcall: the yield fails, but VBA-rr has already marked a frame
  -- advance as pending, so the next emu.frameadvance() stops the script with "can't call
  -- vba.frameadvance() from here". So the bots only ask here and the main loop pauses.
  function G.pauseSoon() G.pausePending = true end
  return G
end)()
