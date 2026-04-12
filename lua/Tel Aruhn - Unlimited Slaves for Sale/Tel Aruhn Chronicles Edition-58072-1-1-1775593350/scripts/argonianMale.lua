local world = require("openmw.world")
local types = require("openmw.types")
local util  = require("openmw.util")
local core  = require("openmw.core")
local time  = require("openmw_aux.time")

local TRIGGER_GLOBAL = "spawnSlaveMaleArgonian"

local FIXED_CELL_NAME = "Tel Aruhn, Underground"
local FIXED_SPAWN_POS = util.vector3(1017, -3165, 2595)
local FIXED_SPAWN_ROT = util.vector3(0, 0, 180)

local SOURCE_NPCS = {
  "argonian slave male","bun-teemeeta","bunish","chalureel","chiwish","dan_ru","dreaded_water",
  "eleedal_lei","gah_julan","grey_throat","han-tulm","haran","heedul","heir-zish","hides_his_foot",
  "high-heart","huzei","inee","j'ram-dar","jeelus-tei","jeer-maht","keerasa_tan","meer",
  "morning_clouds","Neetinei","Okaw","oleen-gei","olink-nur","peeradeeh","reeh_jah","reemukeeus",
  "reesa","seewul","servant arg male","smart_snake","stream-murk","tanan","teegla","tim-jush",
  "twice_bitten","ula","wanan_dum","weer","wih-eius","wud-neeus","wuleen-shei"
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

local function getNpcRecord(id)
  if types.NPC.record then
    return types.NPC.record(id)
  elseif types.NPC.records then
    return types.NPC.records(id)
  end
  return nil
end

local function buildUniqueList(target, genFunc)
  local out, seen = {}, {}
  local safety = 0
  while #out < target do
    safety = safety + 1
    if safety > target * 2000 then
      break
    end
    local v = genFunc()
    if v and not seen[v] then
      seen[v] = true
      table.insert(out, v)
    end
  end
  local i = 1
  while #out < target do
    local v = "Name" .. tostring(i)
    if not seen[v] then
      seen[v] = true
      table.insert(out, v)
    end
    i = i + 1
  end
  return out
end

local function genSingleWord(maxLen)
  local starts = { "ha","si","za","ke","te","ri","shu","ja","ka","ze","he","su","ru","sa","je","ni","sha","ra","ve","zu" }
  local mids   = { "s","ss","sh","z","k","r","n","m","l","t","h","v" }
  local ends   = { "u","i","a","e","s","k","r","n","l","z" }
  local function _pick(t) return t[math.random(1, #t)] end
  local name = _pick(starts) .. _pick(mids) .. _pick(ends)
  if #name > maxLen then return nil end
  return name:sub(1,1):upper() .. name:sub(2)
end

local NAME_POOL_SINGLE = buildUniqueList(250, function() return genSingleWord(8) end)

local SYL = {
  "Tei","Jeel","Sah","Ruul","Kass","Ei","Heem","Sul","Kei","Zul","Jei","Vees","Niss",
  "Kees","Raash","Hesh","Suun","Zass","Keel","Shal","Kess","Kraal","Sakka","Keiss","Riss","Shux","Zees"
}

local function genSyllableHyphen()
  local a = SYL[math.random(1, #SYL)]
  local b = SYL[math.random(1, #SYL)]
  if a == b then return nil end
  return a .. "-" .. b
end

local NAME_POOL_SYLLABLE = buildUniqueList(250, genSyllableHyphen)

local TITLE_VERB = {
  "Sees","Walks","Hides","Runs","Sleeps","Steps","Moves","Listens","Smells","Counts",
  "Watches","Follows","Waits","Knows","Keeps","Hears","Carries","Bends","Holds","Stands",
  "Speaks","Drifts","Creeps","Rises","Falls","Turns","Finds","Leaves","Returns","Crosses",
  "Guards","Tracks","Shields","Fears","Learns","Breaks","Endures","Remembers"
}

local TITLE_MID = { "The","In","At","On","Under","Between","Beyond","Before","After","Without","With","Through","Across","Along","Beneath" }

local TITLE_OBJ = {
  "Marsh","Reeds","Fog","Dawn","Roots","Wind","Rain","Tides","Shore","Moon","Night","Water","Mud","Silence",
  "Shadows","Chains","Steel","Ash","Stars","Paths","Pools","Banks","Swamp","River","Mist","Flame","Dust"
}

local function genTitle()
  local v = TITLE_VERB[math.random(1, #TITLE_VERB)]
  local o = TITLE_OBJ[math.random(1, #TITLE_OBJ)]
  if math.random() < 0.5 then
    return v .. "-" .. o
  else
    local m = TITLE_MID[math.random(1, #TITLE_MID)]
    return v .. "-" .. m .. "-" .. o
  end
end

local NAME_POOL_TITLE = buildUniqueList(250, genTitle)

local DESC_A = {
  "Quiet","Sharp","Long","Cold","Bright","Green","Red","Black","Soft","Quick",
  "Broken","Still","Low","High","Wet","Twisting","Silent","Dark","Deep","Sunken",
  "Scarred","Iron","Chain","Mud","River","Fog","Root","Salt","Storm","Ash",
  "Bone","Steel","Night","Dawn","Hollow","Hard","Wide","Narrow","Sly","Grim"
}

local DESC_B = {
  "Scale","Tongue","Tail","Eye","Spine","Fin","Claw","Step","Hand",
  "Reed","Water","Tide","Mud","Stone","Root","Pool","Bank","Marsh","Path",
  "Mark","Brace","Chain","Scar","Shell","Breath","Shadow","Mist","Hide","Track","Voice"
}

local function genDescriptive()
  local a = DESC_A[math.random(1, #DESC_A)]
  local b = DESC_B[math.random(1, #DESC_B)]
  return a .. "-" .. b
end

local NAME_POOL_DESCRIPTIVE = buildUniqueList(250, genDescriptive)

local RANDOM_NAMES = {}
for _, pool in ipairs({
  NAME_POOL_SINGLE,
  NAME_POOL_SYLLABLE,
  NAME_POOL_TITLE,
  NAME_POOL_DESCRIPTIVE
}) do
  for _, name in ipairs(pool) do
    table.insert(RANDOM_NAMES, name)
  end
end

local function spawnClonedSlave()
  local player = getPlayer()
  if not player then return end
  local sourceId = pick(SOURCE_NPCS)
  local source = getNpcRecord(sourceId)
  if not source then
    log("ERROR: couldn't resolve source NPC record: " .. tostring(sourceId))
    return
  end
  local draft = types.NPC.createRecordDraft({
    template = source,
    name     = pick(RANDOM_NAMES),
    class    = SLAVE_CLASS_ID,
    isMale   = true,
    mwscript = LOCAL_MWSCRIPT_ID,
  })
  local created = world.createRecord(draft)
  if not created or not created.id then
    log("ERROR: createRecord failed")
    return
  end
  local obj = world.createObject(created.id, 1)
  if not obj then
    log("ERROR: createObject failed for " .. tostring(created.id))
    return
  end
  obj:teleport(FIXED_CELL_NAME, FIXED_SPAWN_POS, FIXED_SPAWN_ROT)
  log("Spawned slave: " .. tostring(created.id))
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
  if not ok then
    log("Lua error in onUpdate: " .. tostring(err))
  end
end

return {
  engineHandlers = {
    onUpdate = safeOnUpdate
  }
}
