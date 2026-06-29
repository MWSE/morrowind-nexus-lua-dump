local world = require("openmw.world")
local types = require("openmw.types")
local APPEARANCE_POOLS = require("scripts.servants.appearancePools")

local LABEL = "Breton Female"
local NAME_KEY = "breton_female"
local IS_MALE = false
local NAME_STYLE = "full"

local SOURCE_NPCS = {
  "SM-BRETON-FEMALE-1",
}

local FIRST_NAMES = { "Iraldine", "Abelle", "Adelais", "Adele", "Adelie", "Adelle", "Adiel", "Adrienne", "Agarthe", "Agathe", "Ahetotis", "Ajac", "Alainne", "Alana", "Alarice", "Alexandra", "Alexia", "Alice", "Alison", "Alix", "Allene", "Allice", "Allysin", "Aloin", "Alonisea", "Alverine", "Alyenore", "Alyze", "Ama", "Amber", "Ambre", "Ambrelie", "Amelie", "Amora", "Anabelle", "Anabeth", "Anais", "Anastasie", "Andeleine", "Andree", "Andrya", "Angier", "Aniele", "Aniette", "Annabelle", "Annaline", "Annalise", "Annalysse", "Annarique", "Anne", "Anne-Marie", "Annese", "Annyce", "Antys", "Anya", "Marian", "Muriel", "Arabelle", "Agathie", "Arcineaux", "Ardeline", "Ardile", "Ardine", "Arelette", "Aren", "Ariane", "Arianna", "Arie", "Arielle", "Arienne", "Arlettie", "Arlie", "Armelle", "Arnaude", "Artura", "Aryette", "Aspirant", "Aspiring", "Astrid", "Attendant", "Aubrey", "Audrine", "Augustelle", "Augustina", "Augustine", "Aurelia", "Aurelie", "Aurore", "Aurorelle", "Aveberl", "Axelle", "Babineaux", "Beddi", "Belene", "Beliene", "Beline", "Bellarette", "Belle", "Bellucia", "Belya", "Berengere", "Bergi", "Bernadette", "Bernetta", "Bernice", "Bernique", "Berrice", "Bethany", "Biene", "Bienena", "Blynnie", "Brea", "Brela", "Brena", "Breywenne", "Brigibeth", "Brunile", "Brunwyn", "Calesse", "Callice" }
local LAST_NAMES = { "Gernand", "Tanier", "Barbe", "Metivier", "Montagne", "Charnis", "Panitte", "Dantien", "Germarc", "Monstrose", "Varrid", "Viliane", "Babiloine", "Relin", "Bienne", "Conele", "Dencent", "Malene", "Jurard", "Courcelles", "Edette", "Pellingare", "Mondorie", "Cartier", "Canne", "Derre", "Astier", "Emarie", "Metayer", "Loche", "Bossard", "Leraud", "Celd", "Fransoric", "Crowe", "Lemonds", "Malanie", "Lydelle", "Etanne", "Jegnole", "Manis", "Justal", "Davaux", "Vanne", "Velmont", "Vrouarde", "Cadiou", "Vervins", "Stower", "Urquine", "Lemaitre", "Maguadin", "Brigette", "Dailland", "Pamarc", "Rusone", "Jerick", "Harbert", "Favraud", "Bienena", "Branck", "Lateur", "Serene", "Sourt", "Benel", "Amedee", "Benele", "Dubeau", "Belaine", "Stende", "Kerbol", "Mathierry", "Tardif", "Edrald", "Berri", "Renault", "Voirol", "Landreau", "Brelennal", "Malvina", "Victoire", "Vivine", "Model", "Esmery", "Brunna", "Konia", "Dathieu", "Hermant", "Foucher", "Voriol", "Derone", "Jourvel", "Malarelie", "Maul", "Varin", "Tremouille", "Thelin", "Redain", "Alielle", "Ancois", "Marck", "Dutil", "Luric", "Surges", "Valtieri", "Stelanie", "Hastien", "Laffoon", "Notte", "Frernele" }

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
