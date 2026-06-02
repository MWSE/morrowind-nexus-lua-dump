local M = {}

local function pick(list)
  return list[math.random(1, #list)]
end

local function cap(s)
  if not s or #s == 0 then
    return s
  end
  return s:sub(1, 1):upper() .. s:sub(2)
end

local function buildUniqueList(target, genFunc)
  local out, seen = {}, {}
  local safety = 0

  while #out < target do
    safety = safety + 1
    if safety > target * 9000 then
      break
    end
    local v = genFunc()
    if v and v ~= "" and not seen[v] then
      seen[v] = true
      out[#out + 1] = v
    end
  end

  if #out == 0 then
    out[1] = "Servant"
  end

  return out
end

local function argonianMaleGenerator()
  local starts = { "ha", "si", "za", "ke", "te", "ri", "shu", "ja", "ka", "ze", "he", "su", "ru", "sa", "je", "ni", "sha", "ra", "ve", "zu" }
  local mids = { "s", "ss", "sh", "z", "k", "r", "n", "m", "l", "t", "h", "v" }
  local ends = { "u", "i", "a", "e", "s", "k", "r", "n", "l", "z" }

  local name = pick(starts) .. pick(mids) .. pick(ends)
  if #name > 8 then
    return nil
  end
  return cap(name)
end

local function argonianFemaleGenerator()
  local starts = { "Ee", "Ei", "Ae", "Ia", "Iil", "Eel", "Sii", "Sei", "Zee", "Zei", "Nee", "Nii", "Kee", "Kai", "Hei", "Hai", "Lei", "Lii", "Rii", "Ree" }
  local mids = { "s", "ss", "sh", "z", "zh", "k", "kh", "l", "ll", "n", "nn", "m", "r", "t", "v", "h" }
  local ends = { "a", "ia", "ei", "ee", "i", "ri", "li", "ni", "mi", "ssi", "sha", "zzi", "la", "na", "ra" }

  local a = pick(starts)
  local name = a .. pick(mids) .. pick(ends)
  if #name > 10 then
    return nil
  end
  return name
end

local function khajiitMaleGenerator()
  local prefixes = {
    "J", "S", "Ra", "Ri", "Ma", "M", "Qa", "Dro", "Jo",
    "Ka", "Kha", "Dar", "Do", "R", "Z", "Za", "Sha", "Sa",
  }
  local rootOnset = { "d", "dh", "j", "k", "kh", "m", "n", "q", "r", "s", "sh", "t", "z", "zh", "dr" }
  local rootVowel = { "a", "i", "o", "u" }
  local rootMid = { "", "", "r", "rr", "sh", "kh", "z", "zh", "d" }
  local rootEnd = { "a", "i", "o", "u", "ar", "ir", "im", "an", "en", "ah", "ur", "ra", "ri" }
  local tribalA = { "baa", "sho", "the", "wad", "ur", "ra", "ma", "do", "za", "kha", "jen", "qar", "dro" }
  local tribalB = { "dar", "dhu", "gil", "lani", "argo", "rhu", "rgo", "mhir", "zahr", "shan", "bakh", "vass", "rerr" }
  local tribalEnd = { "o", "i", "u", "a", "" }

  local function genRootShort(maxLen)
    for _ = 1, 12 do
      local onset = pick(rootOnset)
      local v1 = pick(rootVowel)
      local mid = pick(rootMid)
      local core
      if math.random() < 0.55 then
        core = onset .. v1 .. mid
      else
        core = onset .. v1 .. mid .. pick(rootVowel)
      end
      local root = core .. pick(rootEnd)
      if #root <= maxLen then
        return cap(root)
      end
    end
    return cap(pick(rootOnset) .. pick(rootVowel) .. pick(rootEnd))
  end

  local function genApostropheName()
    local prefix = pick(prefixes)
    local root = genRootShort(7)
    local name = prefix .. "'" .. root
    if math.random() < 0.06 then
      name = name .. "-Dar"
    end
    return name
  end

  local function genTribalName()
    local name = pick(tribalA) .. pick(tribalB) .. pick(tribalEnd)
    if #name > 9 then
      name = name:sub(1, 9)
    end
    return cap(name)
  end

  if math.random() < 0.8 then
    return genApostropheName()
  end
  return genTribalName()
end

local function khajiitFemaleGenerator()
  local femalePrefixes = {
    "Ra", "Ri", "Sa", "Si", "Za", "Zi", "Jo", "Ja", "Ma", "Mi", "Na", "Ne", "Sha", "Kha", "Ki", "La", "Le", "Va", "Ve",
    "S", "J", "M", "R", "Z", "Ka", "Dar", "Do",
  }
  local rootOnset = { "r", "s", "z", "sh", "zh", "j", "k", "kh", "m", "n", "l", "v", "d", "dh", "t" }
  local rootVowel = { "a", "e", "i", "o", "u" }
  local rootMid = { "", "", "r", "rr", "sh", "zh", "s", "ss", "z", "n", "nn", "m", "mm", "l", "ll", "v", "h", "kh" }
  local rootEnd = {
    "a", "i", "e", "ia", "ei", "ee",
    "ra", "ri", "la", "li", "na", "ni", "sa", "si", "sha", "zha",
    "mi", "me", "ma", "va", "ve",
  }
  local tail = { "", "", "", "ra", "ri", "na", "ni", "sa", "si", "sha", "zha", "mi", "ma", "la", "va" }
  local hyphenTail = { "Ra", "Ri", "Sa", "Si", "Za", "Zi", "Ma", "Mi", "Na", "Sha", "Kha", "Ki", "La", "Va", "Jo", "Dar" }

  local function genRootShort(maxLen)
    for _ = 1, 14 do
      local onset = pick(rootOnset)
      local v1 = pick(rootVowel)
      local mid = pick(rootMid)
      local core
      if math.random() < 0.55 then
        core = onset .. v1 .. mid
      else
        core = onset .. v1 .. mid .. pick(rootVowel)
      end
      local root = core .. pick(tail) .. pick(rootEnd)
      root = root:gsub("eee", "ee"):gsub("iii", "ii")
      if #root <= maxLen then
        return cap(root)
      end
    end
    return cap(pick(rootOnset) .. pick(rootVowel) .. pick(rootEnd))
  end

  local function genAposName()
    local prefix = pick(femalePrefixes)
    local root = genRootShort(8)
    local name = prefix .. "'" .. root
    if math.random() < 0.05 then
      name = name .. "-Dar"
    end
    return name
  end

  local function genSingleName()
    return genRootShort(8)
  end

  local function genHyphenName()
    local left = genRootShort(6)
    local right = pick(hyphenTail)
    return left .. "-" .. right
  end

  local r = math.random()
  if r < 0.82 then
    return genAposName()
  elseif r < 0.97 then
    return genSingleName()
  end
  return genHyphenName()
end

function M.buildNamePool(key, target)
  local generator
  local size = target or 900

  if key == "argonian_male" then
    generator = argonianMaleGenerator
  elseif key == "argonian_female" then
    generator = argonianFemaleGenerator
  elseif key == "khajiit_male" then
    generator = khajiitMaleGenerator
    size = target or 1000
  elseif key == "khajiit_female" then
    generator = khajiitFemaleGenerator
    size = target or 1000
  else
    return { "Servant" }
  end

  return buildUniqueList(size, generator)
end

return M
