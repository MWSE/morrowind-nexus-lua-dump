local world = require("openmw.world")
local types = require("openmw.types")
local util  = require("openmw.util")
local core  = require("openmw.core")

local TRIGGER_GLOBAL = "spawnSlaveFemaleKhajiit"

local FIXED_CELL_NAME = "Tel Aruhn, Underground"
local FIXED_SPAWN_POS = util.vector3(1030, -2819, 170)
local FIXED_SPAWN_ROT = util.vector3(0, 0, 180)

local SOURCE_NPCS = {
  "dahnara","shivani","ahdahni","ahnarra","habasi","idhassi","kisisa","kisisa",
  "dahleena","inorra","kiseena","khazura","Arabhi","affri","tsalani","unjara",
  "abanji","khamuzi","inerri","ubaasi","udarra","ahdni","kaasha","bahdahna",
  "aravi","kishni","shaba","ahjara","harassa","ahdri","ahndahra","ahnisa",
  "bahdrashi","anjari","ekapi","tsabhi","zahraji","adharanji","tsajadhi",
  "ashidasha","bhusari","tsani","aina"
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

local function cap(s)
  return s:sub(1,1):upper() .. s:sub(2)
end

local FEMALE_PREFIXES = {
  "Ra","Ri","Sa","Si","Za","Zi","Jo","Ja","Ma","Mi","Na","Ne","Sha","Kha","Ki","La","Le","Va","Ve",
  "S","J","M","R","Z","Ka","Dar","Do"
}

local ROOT_ONSET = { "r","s","z","sh","zh","j","k","kh","m","n","l","v","d","dh","t" }
local ROOT_VOWEL = { "a","e","i","o","u" }
local ROOT_MID   = { "", "", "r","rr","sh","zh","s","ss","z","n","nn","m","mm","l","ll","v","h","kh" }

local ROOT_END = {
  "a","i","e","ia","ei","ee",
  "ra","ri","la","li","na","ni","sa","si","sha","zha",
  "mi","me","ma","va","ve"
}

local TAIL = { "", "", "", "ra","ri","na","ni","sa","si","sha","zha","mi","ma","la","va" }

local function genRootShort(maxLen)
  for _ = 1, 14 do
    local onset = pick(ROOT_ONSET)
    local v1    = pick(ROOT_VOWEL)
    local mid   = pick(ROOT_MID)
    local core
    if math.random() < 0.55 then
      core = onset .. v1 .. mid
    else
      core = onset .. v1 .. mid .. pick(ROOT_VOWEL)
    end
    local root = core .. pick(TAIL) .. pick(ROOT_END)
    root = root:gsub("eee", "ee"):gsub("iii", "ii")
    if #root <= maxLen then
      return cap(root)
    end
  end
  return cap(pick(ROOT_ONSET) .. pick(ROOT_VOWEL) .. pick(ROOT_END))
end

local function genAposName()
  local prefix = pick(FEMALE_PREFIXES)
  local root   = genRootShort(8)
  local name   = prefix .. "'" .. root
  if math.random() < 0.05 then
    name = name .. "-Dar"
  end
  return name
end

local function genSingleName()
  return genRootShort(8)
end

local function genHyphenName()
  local left  = genRootShort(6)
  local right = pick({ "Ra","Ri","Sa","Si","Za","Zi","Ma","Mi","Na","Sha","Kha","Ki","La","Va","Jo","Dar" })
  return left .. "-" .. right
end

local function genKhajiitFemaleName()
  local r = math.random()
  if r < 0.82 then
    return genAposName()
  elseif r < 0.97 then
    return genSingleName()
  else
    return genHyphenName()
  end
end

local function buildUniqueList(target, genFunc)
  local out, seen = {}, {}
  local safety = 0
  while #out < target do
    safety = safety + 1
    if safety > target * 9000 then break end
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

local RANDOM_NAMES = buildUniqueList(1000, genKhajiitFemaleName)

local function spawnClonedSlave()
  local player = getPlayer()
  if not player then return end
  local source = getNpcRecord(pick(SOURCE_NPCS))
  if not source then return end
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
  obj:teleport(FIXED_CELL_NAME, FIXED_SPAWN_POS, FIXED_SPAWN_ROT)
  log("Spawned female khajiit slave: " .. tostring(rec.id))
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
