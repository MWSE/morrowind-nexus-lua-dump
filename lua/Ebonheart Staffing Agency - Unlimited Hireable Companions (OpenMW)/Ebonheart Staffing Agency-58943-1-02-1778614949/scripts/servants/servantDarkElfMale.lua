local world = require("openmw.world")
local types = require("openmw.types")
local APPEARANCE_POOLS = require("scripts.servants.appearancePools")

local LABEL = "Dark Elf Male"
local NAME_KEY = "dark_elf_male"
local IS_MALE = true
local NAME_STYLE = "full"

local SOURCE_NPCS = {
  "SM-DARK-ELF-MALE-1",
}

local FIRST_NAMES = { "Aanthis", "Adavos", "Banus", "Bilotan", "Dulmon", "Sendet", "Talso", "Tatennil", "Adol", "Adon", "Adras", "Adren", "Adrerel", "Adril", "Aeren", "Alarel", "Alberic", "Aldam", "Aldryn", "Alexadrin", "Alienist", "Almas", "Almerel", "Alonas", "Alvon", "Alvos", "Alvur", "Ambarys", "Analyst", "Anderin", "Andilo", "Andril", "Angaril", "Anral", "Anylos", "Anyn", "Arayni", "Archcanon", "Thalas", "Arelvam", "Arendil", "Arethan", "Arethil", "Arilen", "Arith", "Armiger", "Aronel", "Aroni", "Aroth", "Artificer", "Arven", "Arver", "Arverus", "Arvys", "Aryo", "Ash", "Ashkhan", "Ashlander", "Ashu-Awa", "Ashulerib", "Ashur", "Aspirant", "Bolvus", "Methas", "Associate", "Athal", "Athanas", "Athanden", "Athando", "Athis", "Athyn", "Avo", "Avos", "Avron", "Aymar", "Azaron", "Baem", "Baladar", "Baladas", "Baldan", "Balen", "Balnar", "Balras", "Balver", "Balves", "Balvos", "Balyn", "Balynor", "Bando", "Barayin", "Baren", "Barilzar", "Baros", "Barusil", "Barvyn", "Barys", "Battlemaster", "Beckoner", "Bedal", "Beldun", "Belos", "Belronen", "Belvin", "Belvo", "Belyn", "Benar", "Benus", "Berel", "Beron", "Bertis", "Bervon", "Bethes", "Biiril", "Bildren", "Bilos", "Birer", "Bivale", "Blighttooth", "Bodsa", "Bolay" }
local LAST_NAMES = { "Fadas", "Dren", "Flan", "Bethendas", "Furari", "Sarethi", "Teryon", "Daryon", "Uveleth", "Gilvayn", "Drenim", "Urvyn", "Fadras", "Llandras", "Drim", "Dralen", "Drelen", "Orain", "Baren", "Teran", "Othralas", "Merobar", "Barus", "Urvon", "Tenim", "Selvilo", "Dorvayn", "Indavel", "Varo", "Tarvus", "Llenim", "Indrano", "Maralvel", "Sendrul", "Eithyna", "Ferasi", "Gethan", "Tharys", "Fanim", "Dreloth", "Sadri", "Dalomar", "Savel", "Falos", "Avani", "Savage", "Wildling", "Ginasa", "Dunhaki", "Exile", "Faven", "Zanon", "Andas", "Samori", "Drivam", "Telendas", "Menas", "Rotheran", "Elarven", "Llaren", "Nilem", "Uvayn", "Farelas", "Jerenise", "Arenim", "Sarvani", "Mothril", "Rothalen", "Sedrethi", "Oldrethi", "Maloren", "Othran", "Rendo", "Rivyn", "Morvayn", "Adrys", "Raviro", "Rethan", "Girith", "Nelvani", "Benethran", "Romavel", "Saren", "Raram", "Dreleth", "Sethri", "Uvani", "Andalor", "Tedalen", "Thirandus", "Bels", "Balvel", "Vidron", "Orelu", "Drelas", "Andrilo", "Dalas", "Giralvel", "Andrano", "Romalen", "Delms", "Thimalvel", "Elendis", "Selvayn", "Ramothran", "Drothro", "Releth", "Hlaalo", "Daram", "Felder" }

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
