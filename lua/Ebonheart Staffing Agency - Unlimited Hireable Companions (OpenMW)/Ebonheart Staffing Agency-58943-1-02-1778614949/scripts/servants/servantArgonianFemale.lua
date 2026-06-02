local world = require("openmw.world")
local types = require("openmw.types")
local APPEARANCE_POOLS = require("scripts.servants.appearancePools")
local BEAST_NAMES = require("scripts.servants.beastNameGenerator")

local LABEL = "Argonian Female"
local NAME_KEY = "argonian_female"
local IS_MALE = false

local SOURCE_NPCS = {
  "SM-ARGONIAN-FEMALE-1",
}


local SERVANT_CLASS_ID = "Servant"
local SERVANT_MWSCRIPT_ID = "gennedServantScript"
local MAGE_SERVANT_CLASS_ID = "Mage-Servant"
local MAGE_SERVANT_MWSCRIPT_ID = "gennedServantMageScript"
local MERCENARY_SERVANT_CLASS_ID = "Mercenary-Servant"
local MERCENARY_SERVANT_MWSCRIPT_ID = "gennedServantMercenaryScript"

local function pick(list)
  return list[math.random(1, #list)]
end

local function getNpcRecord(id)
  if types.NPC.record then
    return types.NPC.record(id)
  elseif types.NPC.records then
    return types.NPC.records(id)
  end
  return nil
end

local function pickAppearance(source)
  local pool = APPEARANCE_POOLS[NAME_KEY]

  if not pool then
    return source.head, source.hair
  end

  local headId = (pool.heads and #pool.heads > 0) and pick(pool.heads) or source.head
  local hairId = (pool.hairs and #pool.hairs > 0) and pick(pool.hairs) or source.hair

  return headId, hairId
end

local RANDOM_NAMES = BEAST_NAMES.buildNamePool(NAME_KEY, 900)

local function createRecord(servantType)
  local sourceId = SOURCE_NPCS[1]
  local source = getNpcRecord(sourceId)

  if not source then
    return nil, "Missing source NPC record: " .. tostring(sourceId)
  end

  local headId, hairId = pickAppearance(source)

  if servantType == true then
    servantType = "mage"
  elseif servantType == false or servantType == nil then
    servantType = "servant"
  end

  local classId = SERVANT_CLASS_ID
  local mwscriptId = SERVANT_MWSCRIPT_ID

  if servantType == "mage" then
    classId = MAGE_SERVANT_CLASS_ID
    mwscriptId = MAGE_SERVANT_MWSCRIPT_ID
  elseif servantType == "mercenary" then
    classId = MERCENARY_SERVANT_CLASS_ID
    mwscriptId = MERCENARY_SERVANT_MWSCRIPT_ID
  end

  local draft = types.NPC.createRecordDraft({
    template = source,
    name = pick(RANDOM_NAMES),
    class = classId,
    mwscript = mwscriptId,
    isMale = IS_MALE,
    head = headId,
    hair = hairId,
  })

  local rec = world.createRecord(draft)

  if not rec or not rec.id then
    return nil, "createRecord failed for source " .. tostring(sourceId)
  end

  return rec
end

return {
  label = LABEL,
  nameKey = NAME_KEY,
  isMale = IS_MALE,
  templateIds = SOURCE_NPCS,
  createRecord = createRecord,
}
