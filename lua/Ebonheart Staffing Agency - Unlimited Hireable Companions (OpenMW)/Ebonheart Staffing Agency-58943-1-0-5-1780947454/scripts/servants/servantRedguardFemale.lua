local world = require("openmw.world")
local types = require("openmw.types")
local APPEARANCE_POOLS = require("scripts.servants.appearancePools")

local LABEL = "Redguard Female"
local NAME_KEY = "redguard_female"
local IS_MALE = false
local NAME_STYLE = "full"

local SOURCE_NPCS = {
  "SM-REDGUARD-FEMALE-1",
}

local FIRST_NAMES = { "Abadai", "Abadi", "Abannah", "Abante", "Abia", "Abradih", "Abrar", "Adara", "Adeena", "Adelizza", "Adifa", "Adinda", "Adjunct", "Aeedika", "Afadi", "Afareen", "Afinah", "Afineh", "Afzoon", "Ahknara", "Ahriah", "Ahya", "Aideh", "Aira", "Airena", "Aishah", "Aishie", "Akhita", "Aleen", "Alesah", "Alida", "Alinya", "Althah", "Althineh", "Alzabeh", "Amjad", "Angeira", "Anireh", "Annique", "Ansei", "Arbella", "Arbiter", "Areshu", "Ariana", "Aribah", "Ariya", "Arjen", "Armiger", "Ashiyana", "Ashuna", "Ashwina", "Asiah", "Assaf", "Atazha", "Atefah", "Ati", "Atin", "Atusa", "Aubatha", "Aureylah", "Aydrah", "Ayma", "Azara", "Azazh", "Azeeda", "Azita", "Azoufah", "Badri", "Bahara", "Bahrar", "Bahree", "Baileet", "Bailiff", "Bailiyya", "Baimora", "Balaith", "Balqi", "Banefshah", "Bani", "Barashana", "Basila", "Benizir", "Berea", "Berfendeh", "Beriana", "Berwareh", "Bezhefah", "Bezhneh", "Bilaira", "Bitter", "Blandine", "Bloody", "Boussa", "Braithabeh", "Braithayidra", "Bramula", "Branwadai", "Brazamah", "Brazzia", "Brazzideh", "Brihana", "Bruscilla", "Buhata", "Burahaira", "Burwa", "Ahnu", "At-Mardeen", "Basrush", "Durida", "Fadahal", "Gilame", "Josajeh", "Kaleen", "Tuvacca", "Carmara", "Casmen", "Cattrice", "Chanas", "Chanisa", "Clavina" }
local LAST_NAMES = { "Dunestrider", "Diwa", "Rizma", "Al-Satakalaam", "Longtemps", "Halelah", "Maja", "Al-Natedan", "At-Fara", "Rhina", "Sorayeh", "Al-Bergama", "Af-Ozalan", "At-Wardiya", "Af-Ashora", "Layla", "Mayra", "At-Rusa", "Berri", "Af-Dometri", "Dariah", "Sahar", "Dursaadia", "Narine", "Fadanah", "At-Makela", "At-Gamati", "Bereha", "Derre", "At-Aswala", "Darima", "Neshtat", "Stictal", "Ghiardelli", "At-Glina", "Af-Armin", "Finaha", "Jawna", "Al-Glessa", "Af-Guyeline", "Alielle", "Tourima", "At-Morad", "Morel", "Fithia", "Mirva", "Nuwarrah", "Tenvi", "At-Tarin", "Af-Ghada", "Af-Jahannif", "Af-Ebdoh", "Ra'Lala", "At-Renazh", "Al-Hallin'S", "Al-Ragath", "Al-Azif", "At-Amil", "Lienne", "At-Elett", "Cedmain", "Af-Jahi", "Al-Tahud", "Af-Perah", "Af-Whyrdh", "At-Hollus", "Al-Kozanset", "Florelle", "At-Tura", "At-Dorcolm", "At-Lehiel", "At-Shadal", "Laurel", "Al-Tava", "Lemaitre", "Jerine", "Sulma", "Falorah", "Leki", "Al-Hllins", "At-Housel", "Af-Abadiran", "Al-Ojwambu", "At-Fada", "Al-Rihad", "At-Khorajah", "At-Ariya", "At-Pykel", "Af-Karra", "Morwha", "Oiarah", "Af-Dushana", "At-Toura", "At-Nimr", "Zhileh", "Bowman", "At-Ginal", "Hafsa", "Al-Morwha", "Al-Masri" }

local SERVANT_CLASS_ID = "Servant"
local SERVANT_MWSCRIPT_ID = "gennedServantScript"
local MAGE_SERVANT_CLASS_ID = "Mage-Servant"
local MAGE_SERVANT_MWSCRIPT_ID = "gennedServantMageScript"
local MERCENARY_SERVANT_CLASS_ID = "Mercenary-Servant"
local MERCENARY_SERVANT_MWSCRIPT_ID = "gennedServantMercenaryScript"

local function pick(list)
  return list[math.random(1, #list)]
end

local function cap(s)
  if not s or #s == 0 then
    return s
  end
  return s:sub(1, 1):upper() .. s:sub(2)
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

local function generateName()
  if NAME_STYLE == "hyphen" then
    return cap(pick(FIRST_NAMES)) .. "-" .. cap(pick(LAST_NAMES))
  end

  if NAME_STYLE == "apostrophe" then
    local prefix = cap(pick(FIRST_NAMES))
    local root = cap(pick(LAST_NAMES))
    local name = prefix .. "'" .. root

    if math.random(1, 5) == 1 then
      name = name .. "-Dar"
    end

    return name
  end

  return cap(pick(FIRST_NAMES)) .. " " .. cap(pick(LAST_NAMES))
end

local function buildUniqueNames(target)
  local names = {}
  local seen = {}
  local guard = 0

  while #names < target and guard < target * 40 do
    guard = guard + 1
    local candidate = generateName()

    if candidate and candidate ~= "" and not seen[candidate] then
      seen[candidate] = true
      names[#names + 1] = candidate
    end
  end

  if #names == 0 then
    names[1] = "Servant"
  end

  return names
end

local RANDOM_NAMES = buildUniqueNames(900)

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
