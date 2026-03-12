local M = {}

-- =========================
-- Tables (as requested)
-- =========================

local POSITIVE_ABILITIES = {
  ap = { "sch_continuo_sp_apa01", "sch_continuo_sp_apa02" },
  at = { "sch_continuo_sp_ata01", "sch_continuo_sp_ata02" },
  la = { "sch_continuo_sp_laa01", "sch_continuo_sp_laa02" },
  lor= { "sch_continuo_sp_lora01","sch_continuo_sp_lora02" },
  lo = { "sch_continuo_sp_loa01", "sch_continuo_sp_loa02" },
  ma = { "sch_continuo_sp_maa01", "sch_continuo_sp_maa02" },
  ri = { "sch_continuo_sp_ria01", "sch_continuo_sp_ria02" },
  se = { "sch_continuo_sp_sea01", "sch_continuo_sp_sea02" },
  sh = { "sch_continuo_sp_sha01", "sch_continuo_sp_sha02" },
  st = { "sch_continuo_sp_sta01", "sch_continuo_sp_sta02" },
  th = { "sch_continuo_sp_tha01", "sch_continuo_sp_tha02" },
  to = { "sch_continuo_sp_toa01", "sch_continuo_sp_toa02" },
  wa = { "sch_continuo_sp_waa01", "sch_continuo_sp_waa02" },
}

local NEGATIVE_ABILITIES = {
  ap  = "sch_continuo_sp_apa03",
  at  = "sch_continuo_sp_ata03",
  la  = "sch_continuo_sp_laa03",
  lor = "sch_continuo_sp_lora03",
  lo  = "sch_continuo_sp_loa03",
  ma  = "sch_continuo_sp_maa03",
  ri  = "sch_continuo_sp_ria03",
  se  = "sch_continuo_sp_sea03",
  sh  = "sch_continuo_sp_sha03",
  st  = "sch_continuo_sp_sta03",
  th  = "sch_continuo_sp_tha03",
  to  = "sch_continuo_sp_toa03",
  wa  = "sch_continuo_sp_waa03",
}

local POWER_TABLE = {
  ap  = "sch_continuo_sp_app01",
  at  = "sch_continuo_sp_atp01",
  la  = "sch_continuo_sp_lap01",
  lor = "sch_continuo_sp_lorp01",
  lo  = "sch_continuo_sp_lop01",
  ma  = "sch_continuo_sp_map01",
  ri  = "sch_continuo_sp_rip01",
  se  = "sch_continuo_sp_sep01",
  sh  = "sch_continuo_sp_shp01",
  st  = "sch_continuo_sp_stp01",
  th  = "sch_continuo_sp_thp01",
  to  = "sch_continuo_sp_top01",
  wa  = "sch_continuo_sp_wap01",
}

-- =========================
-- RNG helpers
-- =========================

local random = math.random

local function shuffle3(a, b, c)
  -- returns a permuted {a,b,c} uniformly-ish using Fisher-Yates
  local t = { a, b, c }
  for i = 3, 2, -1 do
    local j = random(i)
    t[i], t[j] = t[j], t[i]
  end
  return t
end

local function pickOne(list)
  return list[random(#list)]
end

-- =========================
-- Parse fragment -> signKey
-- =========================

local function parseSignKeyFromFragmentId(fragmentId)
  -- expected: "sch_contfirm_mi_star" .. <signKey> ...
  -- signKey may be 2 letters, except "lor" is 3 letters.
  if type(fragmentId) ~= "string" then return nil end
  local id = fragmentId:lower()

  local prefix = "sch_contfirm_mi_star"
  if id:sub(1, #prefix) ~= prefix then return nil end

  local rest = id:sub(#prefix + 1) -- starts with sign key
  -- check lor first to avoid 'lo' collision
  if rest:sub(1, 3) == "lor" then return "lor" end

  local two = rest:sub(1, 2)
  if POSITIVE_ABILITIES[two] or NEGATIVE_ABILITIES[two] then
    return two
  end

  return nil
end

-- =========================
-- Core roll logic
-- =========================

local function choosePosSlots()
  -- exactly 2 true, 1 false, randomized
  -- we shuffle then map to boolean: first 2 are positive
  local order = shuffle3(1, 2, 3)
  local pos = { false, false, false }
  pos[order[1]] = true
  pos[order[2]] = true
  return pos
end

local function buildSignsFromFragments(fragments)
  local signs = {}
  for i = 1, 3 do
    local f = fragments[i]
    local id = f and f.id or ""
    local k = parseSignKeyFromFragmentId(id)
    signs[i] = k
  end
  return signs
end

local function rollPower(signs)
  -- weighted by fragments: pick one of the 3 signs uniformly (by slot)
  local idx = random(3)
  local k = signs[idx]
  return k and POWER_TABLE[k] or nil, idx, k
end

local function rollAbilities(signs, posSlots)
  -- returns 3 ability ids aligned to slots 1..3
  -- with uniqueness per sign.

  -- count occurrences per sign + collect which slots use the sign
  local slotsBySign = {}
  for i = 1, 3 do
    local k = signs[i]
    if k then
      local t = slotsBySign[k]
      if not t then t = {}; slotsBySign[k] = t end
      t[#t + 1] = i
    end
  end

  local abilitiesBySlot = { nil, nil, nil }
  local usedBySign = {} -- sign -> set of abilityId used

  local function markUsed(sign, abilityId)
    local s = usedBySign[sign]
    if not s then s = {}; usedBySign[sign] = s end
    s[abilityId] = true
  end

  local function isUsed(sign, abilityId)
    local s = usedBySign[sign]
    return s and s[abilityId] or false
  end

  -- Special deterministic case: 3x same sign => all three abilities, no duplicates.
  for sign, slots in pairs(slotsBySign) do
    if #slots == 3 then
      -- Assign two positives and one negative according to posSlots
      local posList = POSITIVE_ABILITIES[sign]
      local negId = NEGATIVE_ABILITIES[sign]

      -- Positives are exactly a01/a02, so deterministic too (order depends on slot mapping)
      local posA, posB = posList[1], posList[2]
      for _, slot in ipairs(slots) do
        if posSlots[slot] then
          if not abilitiesBySlot[slot] then
            -- assign first available positive not yet used (should be clean)
            if not isUsed(sign, posA) then
              abilitiesBySlot[slot] = posA
              markUsed(sign, posA)
            else
              abilitiesBySlot[slot] = posB
              markUsed(sign, posB)
            end
          end
        else
          abilitiesBySlot[slot] = negId
          markUsed(sign, negId)
        end
      end

      return abilitiesBySlot
    end
  end

  -- General case: fill slot-by-slot, enforcing uniqueness per sign.
  for slot = 1, 3 do
    local sign = signs[slot]
    if sign then
      if posSlots[slot] then
        local candidates = POSITIVE_ABILITIES[sign]
        if candidates then
          local a = candidates[1]
          local b = candidates[2]
          -- choose randomly among available (not used)
          local avail = {}
          if not isUsed(sign, a) then avail[#avail + 1] = a end
          if not isUsed(sign, b) then avail[#avail + 1] = b end
          -- If both positives already used (can only happen if sign appears 3x but handled above),
          -- fall back to any positive.
          if #avail == 0 then
            avail = { a, b }
          end
          local pick = avail[random(#avail)]
          abilitiesBySlot[slot] = pick
          markUsed(sign, pick)
        end
      else
        local neg = NEGATIVE_ABILITIES[sign]
        abilitiesBySlot[slot] = neg
        markUsed(sign, neg)
      end
    end
  end

  return abilitiesBySlot
end

-- =========================
-- Public API
-- =========================

-- roll(fragments) -> result table (no player applying here)
function M.roll(fragments)
  if type(fragments) ~= "table" or #fragments ~= 3 then
    return nil
  end

  local signs = buildSignsFromFragments(fragments)
  -- basic validation
  for i = 1, 3 do
    if not signs[i] then
      return nil
    end
  end

  local posSlots = choosePosSlots()
  local abilitiesBySlot = rollAbilities(signs, posSlots)

  -- flatten to ability list (3 total)
  local abilities = { abilitiesBySlot[1], abilitiesBySlot[2], abilitiesBySlot[3] }

  local powerId, powerSlot, powerSign = rollPower(signs)

  return {
    signs = signs,
    abilities = abilities,
    power = powerId,
    meta = {
      posSlots = posSlots,       -- boolean[1..3]
      powerSlot = powerSlot,     -- 1..3
      powerSign = powerSign,     -- sign key
    }
  }
end

-- Expose tables (useful for debugging / future UI)
M.POSITIVE_ABILITIES = POSITIVE_ABILITIES
M.NEGATIVE_ABILITIES = NEGATIVE_ABILITIES
M.POWER_TABLE = POWER_TABLE
M.parseSignKeyFromFragmentId = parseSignKeyFromFragmentId

return M