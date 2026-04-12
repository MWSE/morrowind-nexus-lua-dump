local world = require("openmw.world")
local types = require("openmw.types")
local util  = require("openmw.util")
local core  = require("openmw.core")
local time  = require("openmw_aux.time")

local TRIGGER_GLOBAL = "spawnSlaveFemaleArgonian"

local FIXED_CELL_NAME = "Tel Aruhn, Underground"
local FIXED_SPAWN_POS = util.vector3(1017, -3165, 2595)
local FIXED_SPAWN_ROT = util.vector3(0, 0, 180)

local SOURCE_NPCS = {
  "ah-meesei","ahaht","akish","am-ra","Banalz","beekatan",
  "breech-star","cheesh-meeus","deesh-meeus","el-lurasha","eutei",
  "gih-ja","gish","jeed-ei","kal_ma",
  "kasa","meeh-mei","meen-sa","milah","mim-jeen","muz-ra",
  "nakuma","nam-la","neesha","nuralg","nush","olank-neeus","on-wazei",
  "On_Wan","seen-rei","shatalg","tasha","tern-feather","wusha"
}

local SLAVE_CLASS_ID    = "slave"
local LOCAL_MWSCRIPT_ID = "GennedSlaveScript"

math.randomseed(os.time())

local function log(msg)
  print("RAS: " .. tostring(msg))
end

local function pick(list)
  return list[math.random(1, #list)]
end

local function getPlayer()
  local players = world.players
  if not players or #players == 0 then return nil end
  return players[1]
end

local function spawnPosNearPlayer(_player)
  return FIXED_SPAWN_POS
end

local function getNpcRecord(id)
  if types.NPC.record then
    return types.NPC.record(id)
  elseif types.NPC.records then
    return types.NPC.records(id)
  end
  return nil
end

local function getCellByName(name)
  if world.getCellByName then
    return world.getCellByName(name)
  end
  if world.getCell then
    return world.getCell(name)
  end
  return nil
end

local function buildUniqueList(target, genFunc)
  local out, seen = {}, {}
  local safety = 0
  while #out < target do
    safety = safety + 1
    if safety > target * 4000 then break end
    local v = genFunc()
    if v and not seen[v] then
      seen[v] = true
      out[#out + 1] = v
    end
  end
  local i = 1
  while #out < target do
    local v = "Name" .. tostring(i)
    if not seen[v] then
      seen[v] = true
      out[#out + 1] = v
    end
    i = i + 1
  end
  return out
end

local function genFemaleSingle(maxLen)
  local starts = { "Ee","Ei","Ae","Ia","Iil","Eel","Sii","Sei","Zee","Zei","Nee","Nii","Kee","Kai","Hei","Hai","Lei","Lii","Rii","Ree" }
  local mids   = { "s","ss","sh","z","zh","k","kh","l","ll","n","nn","m","r","t","v","h" }
  local ends   = { "a","ia","ei","ee","i","ri","li","ni","mi","ssi","sha","zzi","la","na","ra" }
  local a = pick(starts)
  local name = a .. pick(mids) .. pick(ends)
  name = a .. name:sub(#a + 1)
  if #name > maxLen then return nil end
  return name
end

local NAME_POOL_SINGLE = buildUniqueList(250, function() return genFemaleSingle(10) end)

local SYL_F = { "Ee","Ei","Eel","Iil","Sii","Sei","Zee","Zei","Nee","Nii","Kee","Kai","Hei","Lei","Rii","Ree","Haa","Laa","Naa","Saa","Zaa","Kii","Shi","Zhi","Vee","Vei","Mee","Mei" }

local function genSyllableHyphen()
  local a = pick(SYL_F)
  local b = pick(SYL_F)
  if a == b then return nil end
  local tail = pick({ "la","na","ra","ri","ni","li","sha","ssi","zzi","mei","sei","nee" })
  return a .. tail .. "-" .. b .. tail
end

local NAME_POOL_SYLLABLE = buildUniqueList(250, genSyllableHyphen)

local TITLE_VERB_F = { "Sees","Listens","Sings","Walks","Drifts","Dreams","Waits","Watches","Carries","Follows","Finds","Keeps","Hears","Holds","Returns","Crosses","Gathers","Remembers","Touches","Shelters" }
local TITLE_MID_F  = { "The","In","At","On","Under","Between","Beyond","Before","After","With","Through","Across","Along","Beneath" }
local TITLE_OBJ_F  = { "Reeds","Marsh","Fog","Dawn","Roots","Rain","Tides","Shore","Moon","Night","Water","Mud","Silence","Lilies","Mist","Pools","Banks","Swamp","River","Shells","Stars","Ash","Wind" }

local function genTitle()
  if math.random() < 0.5 then
    return pick(TITLE_VERB_F) .. "-" .. pick(TITLE_OBJ_F)
  else
    return pick(TITLE_VERB_F) .. "-" .. pick(TITLE_MID_F) .. "-" .. pick(TITLE_OBJ_F)
  end
end

local NAME_POOL_TITLE = buildUniqueList(250, genTitle)

local DESC_A_F = { "Quiet","Soft","Bright","Green","Silver","Gentle","Still","Warm","Swift","Silent","Dewy","Moonlit","River","Fog","Reed","Willow","Dawn","Pearl","Mist","Singing","Shimmer","Calm","Deep","Hidden","Tender","Lucky","Wild","Hollow","Grace","Patient" }
local DESC_B_F = { "Scale","Tail","Eye","Fin","Claw","Step","Hand","Reed","Water","Tide","Mud","Stone","Root","Pool","Bank","Marsh","Path","Shell","Breath","Shadow","Mist","Voice","Song","Lily","Star" }

local function genDescriptive()
  return pick(DESC_A_F) .. "-" .. pick(DESC_B_F)
end

local NAME_POOL_DESCRIPTIVE = buildUniqueList(250, genDescriptive)

local RANDOM_NAMES = {}
for _, pool in ipairs({
  NAME_POOL_SINGLE,
  NAME_POOL_SYLLABLE,
  NAME_POOL_TITLE,
  NAME_POOL_DESCRIPTIVE
}) do
  for _, n in ipairs(pool) do
    RANDOM_NAMES[#RANDOM_NAMES + 1] = n
  end
end

local function spawnClonedSlave()
  local player = getPlayer()
  if not player then return end
  local sourceId = pick(SOURCE_NPCS)
  local source = getNpcRecord(sourceId)
  if not source then
    log("ERROR: Failed to resolve source NPC record: " .. tostring(sourceId))
    return
  end
  print(string.format("RAS: Using template NPC -> id='%s'", tostring(sourceId)))
  local draft = types.NPC.createRecordDraft({
    template = source,
    name     = pick(RANDOM_NAMES),
    class    = SLAVE_CLASS_ID,
    isMale   = false,
    mwscript = LOCAL_MWSCRIPT_ID,
  })
  local rec = world.createRecord(draft)
  if not rec or not rec.id then return end
  local obj = world.createObject(rec.id, 1)
  if not obj then return end
  local cell = getCellByName(FIXED_CELL_NAME)
  if not cell then
    log("ERROR: Cell not found: " .. tostring(FIXED_CELL_NAME))
    return
  end
  obj:teleport(cell, spawnPosNearPlayer(player))
  obj.rotation = FIXED_SPAWN_ROT
  log("Spawned female argonian slave: " .. tostring(rec.id))
end

local function pollSpawnGlobal()
  local player = getPlayer()
  if not player then return end
  local g = world.mwscript.getGlobalVariables(player)
  local n = g[TRIGGER_GLOBAL] or 0
  if n > 0 then
    g[TRIGGER_GLOBAL] = n - 1
    spawnClonedSlave()
  end
end

local function safeOnUpdate(dt)
  local ok, err = pcall(pollSpawnGlobal)
  if not ok then log("Lua error: " .. tostring(err)) end
end

return {
  engineHandlers = {
    onUpdate = safeOnUpdate
  }
}
