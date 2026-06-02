local world = require("openmw.world")
local types = require("openmw.types")
local APPEARANCE_POOLS = require("scripts.servants.appearancePools")

local LABEL = "Dark Elf Female"
local NAME_KEY = "dark_elf_female"
local IS_MALE = false
local NAME_STYLE = "full"

local SOURCE_NPCS = {
  "SM-DARK-ELF-FEMALE-1",
}

local FIRST_NAMES = { "Aamela", "Aarela", "Adansa", "Delatha", "Glistel", "Muvrulea", "Tendren", "Ureso", "Velanda", "Adosa", "Adosi", "Adrasi", "Adrullu", "Adryn", "Aerona", "Aeyne", "Ahnat-Suna", "Diina", "Resetta", "Alaburani", "Alalura", "Alaru", "Alarvyne", "Alavani", "Alavesa", "Aldyna", "Aldyne", "Alenus", "Aleri", "Alfe", "Alicon", "Alivusa", "Alli", "Alma", "Almise", "Almse", "Alsal", "Alurami", "Aluri", "Alveno", "Alves", "Alvila", "Alya", "Amila", "Amili", "Andilan", "Andilo", "Aneyda", "Angharal", "Ani", "Anila", "Anisa", "Aphia", "Arara", "Arela", "Areyne", "Arilu", "Arith-Enle", "Armiger", "Arns", "Arnsi", "Aroarise", "Artificer", "Arvelia", "Arvena", "Aryvena", "Ash", "Ashlander", "Ashur-Dissini", "Aspera", "Maren", "Raynila", "Athesa", "Aurona", "Avrusa", "Aymillo", "Babaeli", "Badami", "Badila", "Badilia", "Bala", "Balaru", "Balsia", "Banda", "Bareru", "Bedena", "Bedyna", "Bela", "Belderi", "Belera", "Beleru", "Belosi", "Belya", "Benae", "Bendyni", "Bera", "Berada", "Berari", "Berela", "Berrammai", "Betina", "Bevene", "Bevin", "Beyte", "Bidia", "Bidsa", "Biiri", "Bili", "Bilsa", "Binayne", "Birama", "Birila", "Bivala", "Bivale", "Bivessa", "Blivisi", "Boderi", "Boderia", "Bodsa", "Boethiah" }
local LAST_NAMES = { "Rethandus", "Vadryon", "Veralor", "Delvi", "Serano", "Hlor", "Berendas", "Balen", "Falas", "Arano", "Arethan", "Bemis", "Guls", "Barys", "Merys", "Llarys", "Dren", "Falvani", "Sadus", "Reloren", "Apo", "Droth", "Renim", "Lloryn", "Yahaz", "Ules", "Andrano", "Uvaril", "Suth", "Andas", "Arethi", "Madalas", "Salvani", "Faryon", "Davel", "Alvura", "Sydra", "Urnsi", "Tharam", "Lleryn", "Bereloth", "Hlana", "Mothril", "Arelas", "Doran", "Helothan", "Lathoril", "Arbalest", "Bonecaller", "Enchanter", "Outcast", "Arena-Friend", "Giant-Friend", "Areloth", "Duleri", "Alor", "Teryon", "Avani", "Dothan", "Ven", "Othrenim", "Mothryon", "Tenim", "Uveleth", "Girvu", "Llenim", "Fanim", "Omoril", "Andoril", "Lleran", "Nelvani", "Moorsmith", "Sadri", "Ralen", "Volek", "Damori", "Malrom", "Sarano", "Hlan", "Oran", "Avel", "Tobor", "Aralen", "Moren", "Rendo", "Drim", "Beleth", "Sedri", "Ienith", "Manas", "Devani", "Romavel", "Volyn", "Idroni", "Inlador", "Ilnith", "Dalothran", "Faren", "Lerano", "Tharvi", "Dulo", "Ofemalen", "Verano", "Hlen", "Drethan", "Valasa", "Morusu", "Thelama", "Athin", "Malas" }

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
