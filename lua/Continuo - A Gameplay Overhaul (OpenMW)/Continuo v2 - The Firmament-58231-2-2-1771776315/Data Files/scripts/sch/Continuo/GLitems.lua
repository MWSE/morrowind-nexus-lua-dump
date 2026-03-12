local world = require("openmw.world")
local types = require("openmw.types")

local Actor     = types.Actor
local NPC       = types.NPC
local Container = types.Container

-- =========================================================
-- CAMPING SUPPLIES
-- =========================================================

-- ----- camS IDs / Config -----

local camS_refId = ("sch_continuo_mi_campsup"):lower()

local camS_nPC_whiteList = {
  ["trader service"] = true,
  ["pawnbroker"]     = true,
}

-- ----- camS_nPC_inv -----

local function camS_nPC_invSeed(obj, inv, npcRec)
  local cls = npcRec and npcRec.class

  -- Trader class gate
  if type(cls) == "string" and camS_nPC_whiteList[cls:lower()] then
    if not inv:find(camS_refId) then
      world.createObject(camS_refId, 5):moveInto(inv)
    end
    return
  end

  -- Hostile archetype gate
  local fight = Actor.stats.ai.fight(obj).base
  if fight <= 85 then return end

  if inv:find(camS_refId) then return end
  if math.random(12) ~= 1 then return end

  world.createObject(camS_refId, 1):moveInto(inv)
end


-- =========================================================
-- MEMORY SCROLLS
-- =========================================================

-- ----- memS IDs / Config -----

local memS_sOK_refId = ("sch_mems_bo_sok"):lower()
local memS_sOW_refId = ("sch_mems_bo_sow"):lower()

local memS_nPC_whiteList = {
  ["sorcerer"]          = true,
  ["sorcerer service"]  = true,
  ["enchanter"]         = true,
  ["enchanter service"] = true,
  ["mage"]              = true,
  ["mage service"]      = true,
  ["warlock"]           = true,
}

local memS_cont_whiteList = {
  "chest",
  "corpse",
  "skeleton",
  "nordictomb",
  "wiz",
}

-- ----- memS_cont_whiteList -----

local function memS_cont_whiteListCheck(recordIdLower)
  for i = 1, #memS_cont_whiteList do
    if recordIdLower:find(memS_cont_whiteList[i], 1, true) then
      return true
    end
  end
  return false
end

-- ----- memS_nPC_inv -----

local function memS_nPC_invSeed(obj, inv, npcRec)
  local cls = npcRec and npcRec.class
  if type(cls) ~= "string" then return end

  local classLower = cls:lower()
  if not memS_nPC_whiteList[classLower] then return end

  if inv:find(memS_sOK_refId) or inv:find(memS_sOW_refId) then return end
  if math.random(20) ~= 1 then return end

  if math.random(3) == 1 then
    world.createObject(memS_sOW_refId, 1):moveInto(inv)
  else
    world.createObject(memS_sOK_refId, 1):moveInto(inv)
  end
end

-- ----- memS_cont_inv -----

local function memS_cont_invSeed(obj)
  local cell = obj.cell
  if cell and cell.hasTag and cell:hasTag("NoSleep") then
    return
  end

  local rid = obj.recordId
  if type(rid) ~= "string" then return end

  local idLower = rid:lower()
  if idLower == "" then return end
  if not memS_cont_whiteListCheck(idLower) then return end

  local inv = Container.content(obj)
  if not inv then return end

  if (inv:countOf(memS_sOK_refId) or 0) > 0 then return end
  if (inv:countOf(memS_sOW_refId) or 0) > 0 then return end

  if math.random(15) ~= 1 then return end

  if math.random(3) == 1 then
    world.createObject(memS_sOW_refId, 1):moveInto(obj)
  else
    world.createObject(memS_sOK_refId, 1):moveInto(obj)
  end
end


-- =========================================================
-- SHARED HANDLERS
-- =========================================================

local function onObjectActive(obj)
  if not obj then return end
  if world.players and world.players[1] == obj then return end

  -- nPC path
  if NPC.objectIsInstance(obj) then
    local inv = Actor.inventory(obj)
    if not inv then return end

    local npcRec = NPC.record(obj)

    camS_nPC_invSeed(obj, inv, npcRec)
    memS_nPC_invSeed(obj, inv, npcRec)
    return
  end

  -- cont path
  if Container.objectIsInstance(obj) then
    memS_cont_invSeed(obj)
    return
  end
end

return {
  engineHandlers = { onObjectActive = onObjectActive }
}