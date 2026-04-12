local world = require("openmw.world")
local types = require("openmw.types")
local util  = require("openmw.util")
local core  = require("openmw.core")

local TRIGGER_GLOBAL = "spawnSlaveMaleKhajiit"

local FIXED_CELL_NAME = "Tel Aruhn, Underground"
local FIXED_SPAWN_POS = util.vector3(1017, -3165, 2595)
local FIXED_SPAWN_ROT = util.vector3(0, 0, 180)

local SOURCE_NPCS = {
  "Baadargo","dro'qanar","dro'zah","j'dato","j'jarsha","j'jazha","j'kara",
  "j'oren_dar","j'raksa","j'zamha","khajit slave male","m'shan","ma'dara",
  "ma'jidarr","ma'khar","ma'zahn","ra'karim","ra'mhirr","ra'sava","ra'zahr",
  "ri'darsha","ri'dumiwa","ri'vassa","ri'zaadha","s'bakha","s'rava",
  "s'raverr","s'renji","s'vandra","sholani"
}

local SLAVE_CLASS_ID    = "slave"
local LOCAL_MWSCRIPT_ID = "GennedSlaveScript"

math.randomseed(os.time())

local function log(msg)
  print("RAS: " .. tostring(msg))
end

local function pick(t)
  return t[math.random(1, #t)]
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

local function cap(s)
  return s:sub(1,1):upper() .. s:sub(2)
end

local PREFIXES = {
  "J","S","Ra","Ri","Ma","M","Qa","Dro","Jo",
  "Ka","Kha","Dar","Do","R","Z","Za","Sha","Sa"
}

local ROOT_ONSET = {
  "d","dh","j","k","kh","m","n","q","r","s","sh","t","z","zh","dr"
}

local ROOT_VOWEL = { "a","i","o","u" }

local ROOT_MID = {
  "", "", "r", "rr", "sh", "kh", "z", "zh", "d"
}

local ROOT_END = {
  "a","i","o","u",
  "ar","ir","im","an","en",
  "ah","ur","ra","ri"
}

local function genRootShort(maxLen)
  for _ = 1, 12 do
    local onset = pick(ROOT_ONSET)
    local v1    = pick(ROOT_VOWEL)
    local mid   = pick(ROOT_MID)
    local core
    if math.random() < 0.55 then
      core = onset .. v1 .. mid
    else
      core = onset .. v1 .. mid .. pick(ROOT_VOWEL)
    end
    local root = core .. pick(ROOT_END)
    if #root <= maxLen then
      return cap(root)
    end
  end
  return cap(pick(ROOT_ONSET) .. pick(ROOT_VOWEL) .. pick(ROOT_END))
end

local function genApostropheName()
  local prefix = pick(PREFIXES)
  local root   = genRootShort(7)
  local name   = prefix .. "'" .. root
  if math.random() < 0.06 then
    name = name .. "-Dar"
  end
  return name
end

local TRIBAL_A = {
  "baa","sho","the","wad","ur","ra","ma","do","za","kha","jen","qar","dro"
}

local TRIBAL_B = {
  "dar","dhu","gil","lani","argo","rhu","rgo","mhir","zahr","shan","bakh","vass","rerr"
}

local TRIBAL_END = { "o","i","u","a","" }

local function genTribalName()
  local name = pick(TRIBAL_A) .. pick(TRIBAL_B) .. pick(TRIBAL_END)
  if #name > 9 then
    name = name:sub(1,9)
  end
  return cap(name)
end

local function genKhajiitMaleName()
  if math.random() < 0.8 then
    return genApostropheName()
  else
    return genTribalName()
  end
end

local function buildUniqueList(target)
  local out, seen = {}, {}
  local safety = 0
  while #out < target do
    safety = safety + 1
    if safety > target * 9000 then break end
    local n = genKhajiitMaleName()
    if n and not seen[n] then
      seen[n] = true
      out[#out + 1] = n
    end
  end
  local i = 1
  while #out < target do
    local n = "Name" .. i
    if not seen[n] then
      seen[n] = true
      out[#out + 1] = n
    end
    i = i + 1
  end
  return out
end

local RANDOM_NAMES = buildUniqueList(1000)

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
  local rec = world.createRecord(draft)
  if not rec or not rec.id then
    log("ERROR: createRecord failed")
    return
  end
  local obj = world.createObject(rec.id, 1)
  if not obj then
    log("ERROR: createObject failed for " .. tostring(rec.id))
    return
  end
  obj:teleport(FIXED_CELL_NAME, FIXED_SPAWN_POS, FIXED_SPAWN_ROT)
  log("Spawned male khajiit slave: " .. tostring(rec.id))
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
