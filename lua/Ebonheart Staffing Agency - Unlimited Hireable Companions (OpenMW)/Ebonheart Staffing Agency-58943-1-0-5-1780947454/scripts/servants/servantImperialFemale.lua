local world = require("openmw.world")
local types = require("openmw.types")
local APPEARANCE_POOLS = require("scripts.servants.appearancePools")

local LABEL = "Imperial Female"
local NAME_KEY = "imperial_female"
local IS_MALE = false
local NAME_STYLE = "full"

local SOURCE_NPCS = {
  "SM-IMPERIAL-FEMALE-1",
}

local FIRST_NAMES = { "Accalia", "Aconia", "Aemilia", "Aia", "Alcedonia", "Alessandra", "Alexia", "Alma", "Amalia", "Amanda", "Amandia", "Annia", "Anodia", "Antonia", "Apphia", "Aquilia", "Poneria", "Arria", "Arriana", "Astara", "Atia", "Audania", "Augustina", "Aurelia", "Aventina", "Aviera", "Avita", "Bellona", "Britta", "Brittia", "Caecilia", "Caelia", "Caesina", "Caesonia", "Caldana", "Caledonia", "Calia", "Candria", "Cania", "Canodia", "Cedus", "Drusus", "Furia", "Gemelle", "Geminus", "Helenus", "Hostia", "Jena", "Saulinia", "Virgilus", "Volso", "Cardea", "Cardia", "Caretaker", "Carlotta", "Cassia", "Catina", "Caula", "Celina", "Chanter", "Ciirta", "Cinia", "Clivia", "Cloelia", "Comilla", "Concordia", "Tacita", "Constance", "Caro", "Clairene", "Viatrix", "Coventina", "Dame", "Damyra", "Darvala", "Denisa", "Diabolist", "Diana", "Dinia", "Dino", "Domitia", "Domitiana", "Drusilla", "Dryantilla", "Astella", "Dulcilla", "Dumania", "Duras", "Edana", "Edwina", "Egeria", "Eliana", "Elianna", "Elianne", "Enganna", "Engannas", "Eponis", "Erina", "Etienne", "Etira", "Euraxia", "Eutropia", "Exarch", "Fabia", "Faltonia", "Famia", "Farida", "Fausta", "Faustina", "Felicitas", "Felixa", "Felra", "Finia", "Flacassia", "Flavia", "Flora", "Florentia", "Fortis", "Fralvia", "Fruscia" }
local LAST_NAMES = { "Celatus", "Gallus", "Getha", "Hadrianus", "Orania", "Delitian", "Faustus", "Floria", "Desticus", "Lollia", "Vasatoln", "Bruttia", "Sisenna", "Oclatinus", "Gratas", "Matias", "Matia", "Andus", "Sintav", "Scinia", "Caerellius", "Tucca", "Decanius", "Salvius", "Barbula", "Famula", "Plebo", "Pitio", "Novatian", "Silanus", "Imbrex", "Palenix", "Attius", "Merulin", "Fontius", "Albarnian", "Rulician", "Lentinus", "Rullus", "Varian", "Castorius", "Blasio", "Apinia", "Ministe", "Censorinus", "Varo", "Garrana", "Salutio", "Sestius", "Gedanis", "Amia", "Vergilus", "Moslin", "Vinipter", "Juncus", "Caeparia", "Callonus", "Mercius", "Quarra", "Auzin", "Celata", "Falto", "Pundus", "Trieve", "Atrius", "Rufus", "Volcatia", "Flaccus", "Gravius", "Calogerus", "Catullus", "Nasica", "Vitellius", "Vedia", "Galenus", "Iullus", "Varus", "Jemane", "Clodianus", "Barbatus", "Pevengius", "Alfena", "Caro", "Muspidius", "Sabinus", "Axius", "Glaucia", "Venator", "Dorso", "Senyan", "Sanctus", "Vem", "Viria", "Lerus", "Rato", "Censoria", "Arius", "Curio", "Papus", "Lactucinus", "Catius", "Sele", "Albinus", "Russus", "Scaeva", "Raman", "Candidius", "Duronius", "Tiragrius", "Numida" }

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
