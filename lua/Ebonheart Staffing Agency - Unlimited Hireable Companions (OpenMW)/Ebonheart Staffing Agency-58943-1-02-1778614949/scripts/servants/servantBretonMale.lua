local world = require("openmw.world")
local types = require("openmw.types")
local APPEARANCE_POOLS = require("scripts.servants.appearancePools")

local LABEL = "Breton Male"
local NAME_KEY = "breton_male"
local IS_MALE = true
local NAME_STYLE = "full"

local SOURCE_NPCS = {
  "SM-BRETON-MALE-1",
}

local FIRST_NAMES = { "Abel", "Absolard", "Absolet", "Achane", "Achene", "Achibert", "Achille", "Adair", "Adalard", "Adam", "Adeber", "Adistair", "Adjunct", "Adnot", "Adric", "Adrone", "Adwig", "Aelwin", "Aillard", "Aime", "Aimeric", "Ajac", "Alabane", "Alain", "Alaird", "Alard", "Albec", "Albense", "Aleron", "Alessiac", "Alessio", "Alexain", "Alexis", "Alfred", "Allan", "Aloin", "Alois", "Alouis", "Altus", "Alvaren", "Alvuin", "Amable", "Amadour", "Amaury", "Amberic", "Amelus", "Anatole", "Ancus", "Andbert", "Andre", "Andrec", "Androche", "Androne", "Annibal", "Anton", "Antonin", "Aphaurin", "Arbert", "Arbitrator", "Arcady", "Archimbert", "Archimbide", "Ardvar", "Aribert", "Armel", "Armin", "Arnand", "Arnaud", "Arniel", "Arnitole", "Arno", "Arnousten", "Arphevic", "Arthur", "Aspirant", "Athanin", "Athel", "Atroque", "Aubaud", "Auberic", "Aude", "Audremard", "Audric", "Auglard", "Auguste", "Aveberl", "Avent", "Averio", "Avrippe", "Axel", "Baelborne", "Balin", "Banyrick", "Baralyn", "Bard", "Barjot", "Barnabe", "Bartram", "Baryctor", "Basile", "Basilien", "Bastibien", "Bastien", "Beaubel", "Beaucourt", "Beaunois", "Bedastair", "Beggar", "Begnaud", "Beletin", "Bendais", "Benjamin", "Benjamund", "Benjamyn", "Benoit", "Benry", "Beran", "Beric", "Berjac" }
local LAST_NAMES = { "Mathis", "Lemal", "Elbert", "Douare", "Stental", "Claverie", "Lan", "Catreau", "Charnis", "Loumont", "Geric", "Daro", "Dantien", "Labouche", "Beriel", "Larocque", "Macien", "Racicot", "Favraud", "Canis", "Helena", "Falbert", "Caria", "Dailland", "Dutil", "Cerone", "Dutheil", "Varin", "Sylbenitte", "Bargeron", "Barthel", "Guillon", "Ervine", "Zulin", "Edrald", "Detelle", "Bielle", "Metivier", "Landreau", "Barthele", "Beauchamp", "Garoutte", "Onis", "Marville", "Conele", "Daigre", "Benichou", "Thenitte", "Mastersly", "Badouin", "Georick", "Dugot", "Lanie", "Sorick", "Jerenise", "Dufont", "Jenole", "Lielleve", "Spenard", "Douar", "Delric", "Dantaine", "Plourde", "Remly", "Demalle", "Lavedan", "Relippe", "Arbogasque", "Gilbeau", "Branck", "Derre", "Gevette", "Boulat", "Montieu", "Garick", "Langley", "Mortens", "Baelborne", "Santerre", "Barbe", "Petit", "Giroux", "Volcy", "Geornis", "Stentor", "Bossard", "Brassac", "Jegnole", "Malveaux", "Hand", "Frinck", "Brigette", "Gemane", "Virane", "Benoit", "Cariveau", "Malyne", "Marolles", "Ales", "Fenandre", "Arnese", "Dencent", "Frernis", "Renaudin", "Etanne", "Augier", "Dubosc", "Genin", "Madach", "Edette" }

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
