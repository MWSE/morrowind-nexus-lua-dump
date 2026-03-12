local world = require("openmw.world")
local types = require("openmw.types")

local Actor     = types.Actor
local NPC       = types.NPC
local Creature  = types.Creature
local Container = types.Container

-- =========================================================
-- SERPENT BONUS: MEMORY SCROLL GRANT (PLAYER) - ONCE PER CAST
-- =========================================================

local MEM_SOK_ID = "sch_mems_bo_sok"
local MEM_SOW_ID = "sch_mems_bo_sow"
local SERPENT_POWER_ID = "sch_continuo_sp_sep01"

-- latch: grant once per active-window (cast)
local serpentWasActive = false
local serpentGranted   = false

-- throttle for the check (so it works even if player doesn't "activate" anything)
local serpentAcc = 0
local SERPENT_PERIOD = 0.5

local function checkSerpentGrant()
  local player = world.players and world.players[1]
  if not player then return end

  local active = Actor.activeSpells(player)
  if not active then return end

  local isActive = active:isSpellActive(SERPENT_POWER_ID)

  -- reset latch when power is not active
  if not isActive then
    serpentWasActive = false
    serpentGranted = false
    return
  end

  -- new activation window
  if isActive and not serpentWasActive then
    serpentWasActive = true
    serpentGranted = false
  end

  if serpentGranted then return end

  local inv = Actor.inventory(player)
  if not inv then return end

  world.createObject(MEM_SOK_ID, 1):moveInto(inv)
  world.createObject(MEM_SOW_ID, 1):moveInto(inv)

  serpentGranted = true
end

-- =========================================================
-- FIRMAMENT: STAR FRAGMENTS (SEEDING)
-- =========================================================

local STAR_FRAGMENT_IDS = {
  "sch_contfirm_mi_starappr",
  "sch_contfirm_mi_staratron",
  "sch_contfirm_mi_starlady",
  "sch_contfirm_mi_starlord",
  "sch_contfirm_mi_starlove",
  "sch_contfirm_mi_starmage",
  "sch_contfirm_mi_starritu",
  "sch_contfirm_mi_starserp",
  "sch_contfirm_mi_starshad",
  "sch_contfirm_mi_starstee",
  "sch_contfirm_mi_starthie",
  "sch_contfirm_mi_startowe",
  "sch_contfirm_mi_starwarr",
}

local function invHasAnyStar(inv)
  for i = 1, #STAR_FRAGMENT_IDS do
    if inv:find(STAR_FRAGMENT_IDS[i]) then
      return true
    end
  end
  return false
end

local function pickRandomStarId()
  return STAR_FRAGMENT_IDS[math.random(#STAR_FRAGMENT_IDS)]
end

-- NPC star seeding
local NPC_CLASS_WHITELIST = {
  ["sorcerer"]          = true,
  ["sorcerer service"]  = true,
  ["witch"]             = true,
  ["enchanter"]         = true,
  ["enchanter service"] = true,
  ["mage"]              = true,
  ["mage service"]      = true,
  ["warlock"]           = true,
  ["battlemage"]        = true,
  ["assassin"]          = true,
  ["trader service"]    = true,
  ["archer"]            = true,
  ["agent"]             = true,
  ["pawnbroker"]        = true,
}

local NPC_SEED_CHANCE = 13

local function seedStarIntoNPC(obj, inv, npcRec)
  local cls = npcRec and npcRec.class
  if type(cls) ~= "string" then return end

  local classLower = cls:lower()
  if not NPC_CLASS_WHITELIST[classLower] then return end

  if invHasAnyStar(inv) then return end
  if math.random(NPC_SEED_CHANCE) ~= 1 then return end

  world.createObject(pickRandomStarId(), 1):moveInto(inv)
end

-- Creature star seeding (any creature, 1/55)
local CREATURE_STAR_SEED_CHANCE = 55

local function seedStarIntoCreature(obj, inv)
  if invHasAnyStar(inv) then return end
  if math.random(CREATURE_STAR_SEED_CHANCE) ~= 1 then return end
  world.createObject(pickRandomStarId(), 1):moveInto(inv)
end

-- Container star seeding
local STAR_CONT_WHITELIST = {
  "chest",
  "corpse",
  "skeleton",
  "nordictomb",
  "wiz",
}

local function starContWhitelistCheck(recordIdLower)
  for i = 1, #STAR_CONT_WHITELIST do
    if recordIdLower:find(STAR_CONT_WHITELIST[i], 1, true) then
      return true
    end
  end
  return false
end

local STAR_CONT_SEED_CHANCE = 7

local function seedStarIntoContainer(obj)
  local cell = obj.cell
  if cell and cell.hasTag and cell:hasTag("NoSleep") then
    return
  end

  local rid = obj.recordId
  if type(rid) ~= "string" then return end

  local idLower = rid:lower()
  if idLower == "" then return end
  if not starContWhitelistCheck(idLower) then return end

  local inv = Container.content(obj)
  if not inv then return end

  if invHasAnyStar(inv) then return end
  if math.random(STAR_CONT_SEED_CHANCE) ~= 1 then return end

  world.createObject(pickRandomStarId(), 1):moveInto(obj)
end

-- =========================================================
-- FIRMAMENT: DWEMER RECEPTACLE (SEEDING)
-- =========================================================

local RECEPTACLE_ID = "sch_contfirm_cl_starring"

-- Creature whitelist: substring match on recordId
local RECEPTACLE_CREATURE_WHITELIST = {
  "centurion",
  "dwarven",
  "dwrv",
}

-- Container whitelist: substring match on recordId
local RECEPTACLE_CONT_WHITELIST = {
  "dwrv",
}

local function anySubstringMatch(idLower, list)
  for i = 1, #list do
    if idLower:find(list[i], 1, true) then
      return true
    end
  end
  return false
end

local function seedReceptacleIntoCreature(obj, inv)
  if inv:find(RECEPTACLE_ID) then return end

  local rid = obj.recordId
  if type(rid) ~= "string" then return end
  local idLower = rid:lower()
  if idLower == "" then return end

  if not anySubstringMatch(idLower, RECEPTACLE_CREATURE_WHITELIST) then return end

  local CREATURE_SEED_CHANCE = 10 -- 1/10
  if math.random(CREATURE_SEED_CHANCE) ~= 1 then return end

  world.createObject(RECEPTACLE_ID, 1):moveInto(inv)
end

local function seedReceptacleIntoContainer(obj)
  local rid = obj.recordId
  if type(rid) ~= "string" then return end
  local idLower = rid:lower()
  if idLower == "" then return end

  if not anySubstringMatch(idLower, RECEPTACLE_CONT_WHITELIST) then return end

  local inv = Container.content(obj)
  if not inv then return end
  if inv:find(RECEPTACLE_ID) then return end

  local CONT_SEED_CHANCE = 10 -- 1/10
  if math.random(CONT_SEED_CHANCE) ~= 1 then return end

  world.createObject(RECEPTACLE_ID, 1):moveInto(obj)
end

-- NPC receptacle seeding (whitelisted classes only, 1/30)
local RECEPTACLE_NPC_CLASS_WHITELIST = {
  ["enchanter service"] = true,
  ["pawnbroker"]        = true,
  ["scout"]             = true,
  ["savant service"]    = true,
  ["savant"]            = true,
}

local RECEPTACLE_NPC_SEED_CHANCE = 30

local function seedReceptacleIntoNPC(obj, inv, npcRec)
  if inv:find(RECEPTACLE_ID) then return end

  local cls = npcRec and npcRec.class
  if type(cls) ~= "string" then return end

  local classLower = cls:lower()
  if not RECEPTACLE_NPC_CLASS_WHITELIST[classLower] then return end

  if math.random(RECEPTACLE_NPC_SEED_CHANCE) ~= 1 then return end
  world.createObject(RECEPTACLE_ID, 1):moveInto(inv)
end

-- =========================================================
-- FIRMAMENT: BOOKS (SEEDING) + HOSTILE RECEPTACLE SEEDING
-- =========================================================

local BOOK_IDS = {
  "sch_contfirm_bo_bo01",
  "sch_contfirm_bo_bo02",
  "sch_contfirm_bo_bo03",
  "sch_contfirm_bo_bo04",
  "sch_contfirm_bo_bo05",
  "sch_contfirm_bo_boMS01",
  "sch_contfirm_bo_boMS02",
  "sch_contfirm_bo_boMS03",
  "sch_contfirm_bo_no01",
  "sch_contfirm_bo_no02",
}

local function pickRandomBookId()
  return BOOK_IDS[math.random(#BOOK_IDS)]
end

local function invHasAnyBook(inv)
  for i = 1, #BOOK_IDS do
    if inv:find(BOOK_IDS[i]) then
      return true
    end
  end
  return false
end

local function cellHasNoSleepTag(cell)
  if not cell or not cell.hasTag then return false end
  return cell:hasTag("NoSleep") or cell:hasTag("noSleep")
end

-- 1) Trader NPC classes with specific odds (1/N)
local TRADER_CLASS_CHANCE = {
  ["bookseller"]     = 5,   -- 1/5
  ["pawnbroker"]     = 20,  -- 1/20
  ["trader service"] = 20,  -- 1/20
  ["savant service"] = 8,   -- 1/8
}

local function seedBookIntoTraderNPC(inv, npcRec)
  local cls = npcRec and npcRec.class
  if type(cls) ~= "string" then return end

  local chanceN = TRADER_CLASS_CHANCE[cls:lower()]
  if not chanceN then return end

  if invHasAnyBook(inv) then return end
  if math.random(chanceN) ~= 1 then return end

  world.createObject(pickRandomBookId(), 1):moveInto(inv)
end

-- 2) Hostile NPC classes (1/30), must NOT be in NoSleep/noSleep-tagged cells
local HOSTILE_CLASS_WHITELIST = {
  ["sorcerer"]   = true,
  ["enchanter"]  = true,
  ["mage"]       = true,
  ["warlock"]    = true,
  ["agent"]      = true,
  ["nightblade"] = true,
  ["rogue"]      = true,
  ["thief"]      = true,
}

local HOSTILE_SEED_CHANCE = 30 -- 1/30

local function seedBookIntoHostileNPC(obj, inv, npcRec)
  local cls = npcRec and npcRec.class
  if type(cls) ~= "string" then return end
  if not HOSTILE_CLASS_WHITELIST[cls:lower()] then return end

  if cellHasNoSleepTag(obj.cell) then return end

  if invHasAnyBook(inv) then return end
  if math.random(HOSTILE_SEED_CHANCE) ~= 1 then return end

  world.createObject(pickRandomBookId(), 1):moveInto(inv)
end

-- Hostile NPC receptacle seeding (same hostile class list + chance + NoSleep gate as books)
local function seedReceptacleIntoHostileNPC(obj, inv, npcRec)
  if inv:find(RECEPTACLE_ID) then return end

  local cls = npcRec and npcRec.class
  if type(cls) ~= "string" then return end
  if not HOSTILE_CLASS_WHITELIST[cls:lower()] then return end

  if cellHasNoSleepTag(obj.cell) then return end
  if math.random(HOSTILE_SEED_CHANCE) ~= 1 then return end

  world.createObject(RECEPTACLE_ID, 1):moveInto(inv)
end

-- 3) Specific container recordIds (1/30) — NO NoSleep restriction
local CONTAINER_IDS = {
  "Com_Chest_11_k01",
  "de_r_chest_01_gold1",
  "com_chest_02_lev_gold",
  "de_p_chest_02_pos3",
  "com_chest_01_pos",
  "Wizard_chest_01_evil",
  "com_chest_Daed_ruin_01",
  "Com_Chest_11_pos",
  "de_p_chest_02_gold_25",
  "de_p_chest_02_gold_50",
  "com_chest_02_pos",
  "de_p_chest_02_pos4",
  "Wizard_chest_01_all",
  "com_chest_01_misc06",
  "T_MwDe_FurnM_Ch1Pos",
  "T_MwDe_FurnP_Ch2Pos",
}

local CONTAINER_SET = {}
for i = 1, #CONTAINER_IDS do
  CONTAINER_SET[CONTAINER_IDS[i]:lower()] = true
end

local CONTAINER_BOOK_SEED_CHANCE = 30 -- 1/30

local function seedBookIntoContainer(obj)
  local rid = obj.recordId
  if type(rid) ~= "string" then return end

  local idLower = rid:lower()
  if idLower == "" then return end
  if not CONTAINER_SET[idLower] then return end

  local inv = Container.content(obj)
  if not inv then return end

  if invHasAnyBook(inv) then return end
  if math.random(CONTAINER_BOOK_SEED_CHANCE) ~= 1 then return end

  world.createObject(pickRandomBookId(), 1):moveInto(obj)
end

-- =========================================================
-- CS BOOK SEEDING
-- =========================================================

local CS_BOOK_ID = "sch_contfirm_bo_boCS01"

local function invHasCSBook(inv)
  return inv and inv:find(CS_BOOK_ID) ~= nil
end

-- Any cell: (bookseller, pawnbroker, trader service) all 1/5
local CS_TRADER_CLASS_WHITELIST = {
  ["bookseller"]     = true,
  ["pawnbroker"]     = true,
  ["trader service"] = true,
}

local CS_TRADER_SEED_CHANCE = 5 -- 1/5

local function seedCSBookIntoTraderNPC(inv, npcRec)
  local cls = npcRec and npcRec.class
  if type(cls) ~= "string" then return end
  if not CS_TRADER_CLASS_WHITELIST[cls:lower()] then return end

  if invHasCSBook(inv) then return end
  if math.random(CS_TRADER_SEED_CHANCE) ~= 1 then return end

  world.createObject(CS_BOOK_ID, 1):moveInto(inv)
end

-- Hostile: (barbarian, scout, warrior, acrobat) all 1/20, NOT in NoSleep/noSleep cell
local CS_HOSTILE_CLASS_WHITELIST = {
  ["barbarian"] = true,
  ["scout"]     = true,
  ["warrior"]   = true,
  ["acrobat"]   = true,
}

local CS_HOSTILE_SEED_CHANCE = 20 -- 1/20

local function seedCSBookIntoHostileNPC(obj, inv, npcRec)
  local cls = npcRec and npcRec.class
  if type(cls) ~= "string" then return end
  if not CS_HOSTILE_CLASS_WHITELIST[cls:lower()] then return end

  if cellHasNoSleepTag(obj.cell) then return end

  if invHasCSBook(inv) then return end
  if math.random(CS_HOSTILE_SEED_CHANCE) ~= 1 then return end

  world.createObject(CS_BOOK_ID, 1):moveInto(inv)
end

-- =========================================================
-- SHARED HANDLER
-- =========================================================

local function onObjectActive(obj)
  if not obj then return end
  if world.players and world.players[1] == obj then return end

  -- NPC path (stars + receptacle + books)
  if NPC.objectIsInstance(obj) then
    local inv = Actor.inventory(obj)
    if not inv then return end
    local npcRec = NPC.record(obj)

    seedStarIntoNPC(obj, inv, npcRec)

    seedReceptacleIntoNPC(obj, inv, npcRec)
    seedReceptacleIntoHostileNPC(obj, inv, npcRec)

    -- Existing book systems
    seedBookIntoTraderNPC(inv, npcRec)
    seedBookIntoHostileNPC(obj, inv, npcRec)

    -- NEW CS book systems (independent)
    seedCSBookIntoTraderNPC(inv, npcRec)
    seedCSBookIntoHostileNPC(obj, inv, npcRec)

    return
  end

  -- Creature path (stars + receptacle)
  if Creature.objectIsInstance(obj) then
    local inv = Actor.inventory(obj)
    if not inv then return end

    seedStarIntoCreature(obj, inv)
    seedReceptacleIntoCreature(obj, inv)
    return
  end

  -- Container path (stars + receptacle + books)
  if Container.objectIsInstance(obj) then
    seedStarIntoContainer(obj)
    seedReceptacleIntoContainer(obj)

    seedBookIntoContainer(obj)
    return
  end
end

return {
  engineHandlers = {
    onUpdate = function(dt)
      serpentAcc = serpentAcc + dt
      if serpentAcc < SERPENT_PERIOD then return end
      serpentAcc = serpentAcc - SERPENT_PERIOD
      checkSerpentGrant()
    end,
    onObjectActive = onObjectActive,
  }
}