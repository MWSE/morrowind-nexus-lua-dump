--[[
    Toxicology! — Global Script

    Responsibilities (global-only things):
      * Hook I.ItemUsage.addHandlerForType(types.Potion, ...) — intercept potion drags
      * Write persistent keyed coating state for weapons and thrown records
      * Resolve thrown-weapon poison state after the projectile leaves inventory
      * Apply poison effects to targets on hit (via activeSpells)
]]

local core     = require('openmw.core')
local I        = require('openmw.interfaces')
local storage  = require('openmw.storage')
local types    = require('openmw.types')
local world    = require('openmw.world')

local config  = require('scripts.toxicology.config')

local MODNAME = 'Toxicology'
local RANGED_ATTACK_SOURCE_TYPE = I.Combat and I.Combat.ATTACK_SOURCE_TYPES and I.Combat.ATTACK_SOURCE_TYPES.Ranged
-- Long enough for held bow draws plus projectile flight; overwritten or
-- cleared on the next ranged attack-start edge.
local PROJECTILE_CONTEXT_WINDOW = 300.0

-- ─── Settings access ───────────────────────────────────────────────────────
-- Global scripts cannot read storage.playerSection directly (that's player/menu
-- scope only). Instead, the player script mirrors its settings into a
-- globalSection named 'Runtime_Toxicology' on every onUpdate tick, and we
-- read from that here. Same pattern Throwing! uses.

local runtimeSection = storage.globalSection('Runtime_Toxicology')
local projectileRuntimeSection = storage.globalSection('Runtime_ToxicologyProjectile')

-- Per-weapon poison data. ItemData doesn't accept custom properties, so we
-- use our own globalSection keyed by weapon GameObject id; thrown weapons use
-- a record-keyed entry prefixed with "thrown:".
-- Shape: {
--     poisonId, charges, layer2PoisonId, layer2Charges, layer3PoisonId, layer3Charges,
--     snapshot = {            -- captured at apply-time, used post-reload
--         [poisonId] = { name, effects = { {id, magMin, magMax, duration, ...}, ... } },
--         ...
--     }
-- }
-- The snapshot is important for player-brewed alchemy potions because those
-- use dynamic record ids like "Generated:0x2e53" which don't survive save/
-- reload (the record itself is gone, even if the id string is stored). By
-- snapshotting the effect list at apply time we can still fire the hit logic
-- after reload even if types.Potion.records[poisonId] lookup fails.
local weaponPoisonSection = storage.globalSection('Runtime_ToxicologyWeaponPoison')
local THROWN_POISON_PREFIX = 'thrown:'

-- globalSection data can survive across manual save loads. Keep weapon coating
-- entries behind a load namespace so stale entries from a newer save cannot be
-- read after loading an older save. The saved payload stores raw weapon keys;
-- on every load we allocate a fresh live namespace and restore only that save's
-- payload into it.
local WEAPON_POISON_NAMESPACE_KEY = '__activeNamespace'
local WEAPON_POISON_COUNTER_KEY = '__namespaceCounter'
local weaponPoisonNamespace = nil

local function createWeaponPoisonNamespace()
    local rawCounter = weaponPoisonSection:get(WEAPON_POISON_COUNTER_KEY)
    local counter = tonumber(rawCounter) or 0
    counter = counter + 1
    weaponPoisonNamespace = 'load:' .. tostring(counter)
    weaponPoisonSection:set(WEAPON_POISON_COUNTER_KEY, counter)
    weaponPoisonSection:set(WEAPON_POISON_NAMESPACE_KEY, weaponPoisonNamespace)
    return weaponPoisonNamespace
end

local function ensureWeaponPoisonNamespace()
    if weaponPoisonNamespace then return weaponPoisonNamespace end
    local current = weaponPoisonSection:get(WEAPON_POISON_NAMESPACE_KEY)
    if current ~= nil then
        weaponPoisonNamespace = tostring(current)
        return weaponPoisonNamespace
    end
    return createWeaponPoisonNamespace()
end

local function liveWeaponPoisonStorageKey(key, createIfMissing)
    if not key then return nil end
    local ns = weaponPoisonNamespace
    if not ns and createIfMissing then
        ns = ensureWeaponPoisonNamespace()
    elseif not ns then
        local current = weaponPoisonSection:get(WEAPON_POISON_NAMESPACE_KEY)
        if current ~= nil then
            ns = tostring(current)
            weaponPoisonNamespace = ns
        end
    end
    if not ns then return nil end
    return ns .. '|' .. tostring(key)
end

-- Existing-record distribution mode does not generate custom poison records.
-- These maps are kept empty for backward compatibility with older interface
-- consumers that may ask Toxicology for a generated record id.
local poisonIdMap = {}
local specialtyIdMap = {}

local function objectIsAvailable(obj)
    if not obj then return false end
    local ok, valid = pcall(function()
        if obj.isValid then return obj:isValid() end
        return true
    end)
    return ok and valid ~= false
end

local function safeWeaponRecord(weapon)
    if not objectIsAvailable(weapon) then return nil end
    local ok, isWeapon = pcall(types.Weapon.objectIsInstance, weapon)
    if not ok or not isWeapon then return nil end
    local okRec, rec = pcall(types.Weapon.record, weapon)
    if not okRec then return nil end
    return rec
end

local function safeObjectField(obj, field)
    if not objectIsAvailable(obj) then return nil end
    local ok, value = pcall(function() return obj[field] end)
    if not ok then return nil end
    return value
end

local function isThrownWeaponObject(weapon)
    local rec = safeWeaponRecord(weapon)
    return rec and rec.type == types.Weapon.TYPE.MarksmanThrown
end

local function poisonStorageKey(weapon)
    local rec = safeWeaponRecord(weapon)
    if not rec then return nil end
    if rec.type == types.Weapon.TYPE.MarksmanThrown then
        local recordId = safeObjectField(weapon, 'recordId')
        if not recordId then return nil end
        return THROWN_POISON_PREFIX .. tostring(recordId)
    end
    return safeObjectField(weapon, 'id')
end

local function isProjectileWeaponType(weaponType)
    return weaponType == types.Weapon.TYPE.MarksmanThrown
        or weaponType == types.Weapon.TYPE.MarksmanBow
        or weaponType == types.Weapon.TYPE.MarksmanCrossbow
end

local function currentProjectileTokenForKey(weaponKey)
    if not weaponKey or not projectileRuntimeSection:get('active') then return nil end
    if projectileRuntimeSection:get('weaponKey') ~= weaponKey then return nil end
    local releasedAt = projectileRuntimeSection:get('releasedAt')
    if releasedAt == nil then return nil end
    local age = core.getSimulationTime() - releasedAt
    if age < 0 or age > PROJECTILE_CONTEXT_WINDOW then return nil end
    return projectileRuntimeSection:get('token')
end

local function markProjectileTokenConsumed(token, weaponKey)
    if token == nil then return end
    projectileRuntimeSection:set('lastConsumedToken', token)
    projectileRuntimeSection:set('lastConsumedWeaponKey', weaponKey)
end

-- Weapon coatings must be save-scoped, not profile-scoped. Do not mark
-- this section Persistent: persistent storage survives manual save loads and
-- can leak a coating from a newer save into an older one. We keep an in-memory
-- key index and serialize it through onSave/onLoad instead.
local weaponPoisonState = {}
local weaponPoisonKeys = {}

local function weaponPoisonDataIsActive(data)
    return data and (data.poisonId ~= nil or data.layer2PoisonId ~= nil or data.layer3PoisonId ~= nil)
end

-- Capture the current state of a potion record into a plain-Lua snapshot so
-- we can re-apply its effects even after reload/alchemy record churn.
local function snapshotPotion(potionRec)
    if not potionRec then return nil end
    local effs = {}
    if potionRec.effects then
        for i = 1, #potionRec.effects do
            local e = potionRec.effects[i]
            effs[#effs + 1] = {
                id                 = e.id,
                affectedAttribute  = e.affectedAttribute,
                affectedSkill      = e.affectedSkill,
                magnitudeMin       = e.magnitudeMin,
                magnitudeMax       = e.magnitudeMax,
                duration           = e.duration,
                range              = e.range,
                area               = e.area,
            }
        end
    end
    return {
        name    = potionRec.name or 'Poison',
        effects = effs,
    }
end

local function copyWeaponPoisonData(raw)
    if not raw then return nil end
    -- globalSection:get() returns a read-only userdata. Copy to a plain
    -- table so callers can mutate fields before writing back.
    -- Snapshots (nested table) are also copied via :asTable()-style iteration
    -- to keep the result fully mutable and save-safe.
    local function copySnapshot(s)
        if not s then return nil end
        local out = {}
        for pid, pr in pairs(s) do
            local effs = {}
            if pr.effects then
                for i = 1, #pr.effects do
                    local e = pr.effects[i]
                    effs[#effs + 1] = {
                        id                = e.id,
                        affectedAttribute = e.affectedAttribute,
                        affectedSkill     = e.affectedSkill,
                        magnitudeMin      = e.magnitudeMin,
                        magnitudeMax      = e.magnitudeMax,
                        duration          = e.duration,
                        range             = e.range,
                        area              = e.area,
                    }
                end
            end
            out[pid] = { name = pr.name, effects = effs }
        end
        return out
    end
    return {
        poisonId       = raw.poisonId,
        charges        = raw.charges,
        layer2PoisonId = raw.layer2PoisonId,
        layer2Charges  = raw.layer2Charges,
        layer3PoisonId = raw.layer3PoisonId,
        layer3Charges  = raw.layer3Charges,
        snapshot       = copySnapshot(raw.snapshot),
    }
end

local function getWeaponPoisonByKey(key)
    if not key then return nil end
    local data = weaponPoisonState[key]
    if not data then
        local liveKey = liveWeaponPoisonStorageKey(key, false)
        if liveKey then
            data = copyWeaponPoisonData(weaponPoisonSection:get(liveKey))
        end
        if weaponPoisonDataIsActive(data) then
            weaponPoisonState[key] = data
            weaponPoisonKeys[key] = true
        end
    end
    return copyWeaponPoisonData(data)
end

local function serializeWeaponPoisonState()
    local out = {}
    for key, _ in pairs(weaponPoisonKeys) do
        local data = weaponPoisonState[key]
        if weaponPoisonDataIsActive(data) then
            out[key] = copyWeaponPoisonData(data)
        end
    end
    return out
end

local function clearProjectileRuntimeState()
    projectileRuntimeSection:set('active', false)
    projectileRuntimeSection:set('token', nil)
    projectileRuntimeSection:set('releasedAt', nil)
    projectileRuntimeSection:set('weaponKey', nil)
    projectileRuntimeSection:set('recordId', nil)
    projectileRuntimeSection:set('weaponType', nil)
    projectileRuntimeSection:set('poisonData', nil)
    projectileRuntimeSection:set('lastConsumedToken', nil)
    projectileRuntimeSection:set('lastConsumedWeaponKey', nil)
end

local function clearWeaponPoisonState()
    -- Do not try to enumerate or clean old globalSection entries here. They may
    -- belong to an earlier load namespace and globalSection does not provide a
    -- safe complete key list. Namespace rotation makes those entries unreachable.
    weaponPoisonState = {}
    weaponPoisonKeys = {}
end

local function restoreWeaponPoisonState(savedState)
    createWeaponPoisonNamespace()
    clearWeaponPoisonState()
    if type(savedState) ~= 'table' then return end
    for key, data in pairs(savedState) do
        if type(key) == 'string' and weaponPoisonDataIsActive(data) then
            local copied = copyWeaponPoisonData(data)
            weaponPoisonState[key] = copied
            weaponPoisonKeys[key] = true
            local liveKey = liveWeaponPoisonStorageKey(key, true)
            if liveKey then
                weaponPoisonSection:set(liveKey, copied)
            end
        end
    end
end


local function projectilePoisonDataForToken(token)
    if token == nil then return nil end
    if projectileRuntimeSection:get('token') ~= token then return nil end
    return copyWeaponPoisonData(projectileRuntimeSection:get('poisonData'))
end

local function projectileContextMatchesHit(token, weaponKey, weaponType)
    if token ~= nil and projectileRuntimeSection:get('token') == token then
        return true
    end
    if weaponKey and projectileRuntimeSection:get('active')
       and projectileRuntimeSection:get('weaponKey') == weaponKey then
        local releasedAt = projectileRuntimeSection:get('releasedAt')
        local age = releasedAt and (core.getSimulationTime() - releasedAt) or math.huge
        if age >= 0 and age <= PROJECTILE_CONTEXT_WINDOW then
            return true
        end
    end
    return isProjectileWeaponType(weaponType)
end

local function getWeaponPoison(weapon)
    return getWeaponPoisonByKey(poisonStorageKey(weapon))
end

local function setWeaponPoisonByKey(key, data)
    if not key then return end
    local copied = weaponPoisonDataIsActive(data) and copyWeaponPoisonData(data) or nil
    local liveKey = liveWeaponPoisonStorageKey(key, true)
    if copied then
        weaponPoisonState[key] = copied
        weaponPoisonKeys[key] = true
        if liveKey then
            weaponPoisonSection:set(liveKey, copied)
        end
    else
        weaponPoisonState[key] = nil
        weaponPoisonKeys[key] = nil
        if liveKey then
            weaponPoisonSection:set(liveKey, nil)
        end
    end
end

local function setWeaponPoison(weapon, data)
    setWeaponPoisonByKey(poisonStorageKey(weapon), data)
end

local function clearWeaponPoisonByKey(key)
    setWeaponPoisonByKey(key, nil)
end

local function clearWeaponPoison(weapon)
    clearWeaponPoisonByKey(poisonStorageKey(weapon))
end

local function transferWeaponPoisonState(evt)
    if type(evt) ~= 'table' then return end
    local oldKey = evt.oldKey
    local newKey = evt.newKey
    if not oldKey or not newKey or oldKey == newKey then return end

    local data = getWeaponPoisonByKey(oldKey)
    if not weaponPoisonDataIsActive(data) then return end

    setWeaponPoisonByKey(newKey, data)
    clearWeaponPoisonByKey(oldKey)

    local actor = evt.actor
    if actor then
        actor:sendEvent('Toxicology_PoisonTransferComplete', {
            oldKey = oldKey,
            newKey = newKey,
            reason = evt.reason or 'weapon swap',
        })
    end
end

-- Maps the old "Settings_Toxicology_Poisons" style section keys to their
-- short form used inside the runtime section (settingKey only, not section).
-- We expect the player to sync each key by its raw name.
local function readPlayerSetting(section, key, default)
    local val = runtimeSection:get(key)
    if val == nil then return default end
    return val
end

local function toxicologyPerkEnabled(key)
    if not readPlayerSetting('Settings_' .. MODNAME .. '_Perks', 'enableAllPerks', true) then
        return false
    end
    return readPlayerSetting('Settings_' .. MODNAME .. '_Perks', key, true)
end

local function debugEnabled(category)
    if not readPlayerSetting('Settings_' .. MODNAME .. '_UI', 'debugMessages', false) then return false end
    if not category then return true end
    return readPlayerSetting('Settings_' .. MODNAME .. '_UI', category, false)
end

local function debugLog(msg, category)
    if debugEnabled(category) then
        print('[Toxicology!] ' .. tostring(msg))
    end
end

local function lower(s)
    if type(s) ~= 'string' then return '' end
    return s:lower()
end

local function alcoholTermMatches(hay, term)
    if type(term) ~= 'string' or term == '' then return false end
    term = lower(term)

    -- ID-style terms are expected to be matched literally.
    if term:find('_', 1, true) then
        return hay:find(term, 1, true) ~= nil
    end

    local start = 1
    while true do
        local i, j = hay:find(term, start, true)
        if not i then return false end
        local before = i > 1 and hay:sub(i - 1, i - 1) or ''
        local after = j < #hay and hay:sub(j + 1, j + 1) or ''
        local beforeWord = before ~= '' and before:match('%w') ~= nil
        local afterWord = after ~= '' and after:match('%w') ~= nil
        if not beforeWord and not afterWord then return true end
        start = j + 1
    end
end

local function alcoholRecordIdIsListed(id)
    local alcohol = config.alcohol or {}
    local recordIds = alcohol.recordIds or {}
    local key = lower(id)
    if key == '' then return false end

    -- Most entries are expected to be lower-case, but make the whitelist
    -- tolerant of mixed-case IDs added by users or other mod lists.
    if recordIds[key] or recordIds[tostring(id or '')] then return true end
    for recordId, enabled in pairs(recordIds) do
        if enabled and lower(recordId) == key then return true end
    end
    return false
end

local function recordLooksAlcoholic(id, record)
    if alcoholRecordIdIsListed(id) then return true end

    local alcohol = config.alcohol or {}
    local key = lower(id)
    local hay = key .. ' ' .. lower(record and record.name or '')
    for _, term in ipairs(alcohol.terms or {}) do
        if alcoholTermMatches(hay, term) then return true end
    end
    return false
end

local function shouldIgnoreAlcoholRecord(id, record)
    if not readPlayerSetting('Settings_' .. MODNAME, 'ignoreAlcoholPotions', true) then return false end
    return recordLooksAlcoholic(id, record)
end

local function alcoholIsDistributionBlacklisted(id, record)
    -- Distribution must never add configured alcohol records as Toxicology poison
    -- loot/stock. This uses the same alcohol list as the player-facing Ignore
    -- Alcohol feature, but is intentionally independent of that toggle so a
    -- player can choose to apply an alcoholic harmful potion without causing
    -- merchants or containers to be seeded with drink records as poisons.
    return recordLooksAlcoholic(id, record)
end

-- ─── Harm classifier ────────────────────────────────────────────────────────
local function isEffectHarmful(effect)
    local id = effect.id
    if not id then return false end
    id = id:lower()

    -- Always-harmful list (defensive against engine flag misreport)
    if config.alwaysHarmfulEffects[id] then return true end

    -- Engine flag fallback
    local rec = core.magic.effects.records[id]
    if rec and rec.harmful then return true end
    return false
end

local function potionIsHarmful(potion)
    local rec = types.Potion.records[potion.recordId]
    if not rec or not rec.effects then return false end
    if shouldIgnoreAlcoholRecord(potion.recordId, rec) then return false end
    for _, eff in ipairs(rec.effects) do
        if isEffectHarmful(eff) then return true end
    end
    return false
end

-- ─── Existing-record poison distribution ─────────────────────────────────────
local staticPoisonPool = {}
local staticPoisonPoolReady = false
-- Session-local cache of candidate poison ids discovered from live inventories.
-- Using a plain Lua table here avoids the read-only/persistence quirks that were
-- causing seeded ids to be logged but then dropped during pool rebuild.
local discoveredPoisonIdList = {}
local discoveredPoisonIdSet = {}
local cellDistributionState = storage.globalSection('ToxicologyDistributionState')
cellDistributionState:setLifeTime(storage.LIFE_TIME.Persistent)
local DISTRIBUTION_SCHEMA = 'existing_records_v7_ignore_alcohol'

local function effectLooksHarmful(effect)
    if not effect or not effect.id then return false end
    local id = lower(effect.id)
    if config.alwaysHarmfulEffects[id] then return true end
    local rec = core.magic.effects.records[id]
    if rec and rec.harmful then return true end
    return false
end

local function recordShouldNeverBePoisonCandidate(id, record)
    if alcoholIsDistributionBlacklisted(id, record) then return true end

    local hay = lower(id) .. ' ' .. lower(record and record.name or '')
    local rejectTerms = {
        'cure ', ' cure', 'resist', 'restore', 'fortify', 'regen', 'healing',
        'antidote', 'remedy', 'elixir'
    }
    for _, term in ipairs(rejectTerms) do
        if hay:find(term, 1, true) then return true end
    end
    return false
end

local function recordMatchesPoisonHeuristic(id, record)
    if recordShouldNeverBePoisonCandidate(id, record) then return false end
    local hay = lower(id) .. ' ' .. lower(record and record.name or '')
    local positiveTerms = {
        'poison', 'venom', 'toxin', 'toxic', 'bane', 'noxious'
    }
    for _, term in ipairs(positiveTerms) do
        if hay:find(term, 1, true) then return true end
    end
    return false
end

local function recordIsEligibleStaticPoison(id, record)
    if not record then return false end
    if lower(id):find('p_tox_', 1, true) then return false end
    if recordShouldNeverBePoisonCandidate(id, record) then return false end

    local hasHarmful = false
    local hasBeneficial = false
    if record.effects then
        for i = 1, #record.effects do
            local eff = record.effects[i]
            if effectLooksHarmful(eff) then
                hasHarmful = true
            else
                hasBeneficial = true
            end
        end
    end

    if hasHarmful then
        local allowMixed = readPlayerSetting('Settings_' .. MODNAME .. '_Distribution', 'allowMixedEffectPoisons', true)
        return allowMixed or not hasBeneficial
    end

    return recordMatchesPoisonHeuristic(id, record)
end

local function getDiscoveredPoisonList()
    return discoveredPoisonIdList
end

local function addDiscoveredPoisonId(recordId)
    if type(recordId) ~= 'string' or recordId == '' then return false end
    local key = lower(recordId)
    if discoveredPoisonIdSet[key] then return false end
    discoveredPoisonIdSet[key] = true
    discoveredPoisonIdList[#discoveredPoisonIdList + 1] = recordId
    debugLog('[Distribution] Discovered existing poison record: ' .. recordId, 'debugDistributionMessages')
    return true
end

local function considerPotionRecordId(recordId)
    if type(recordId) ~= 'string' or recordId == '' then return false end
    if lower(recordId):find('generated:', 1, true) then return false end
    local rec = types.Potion.records[recordId]
    if not rec then return false end
    if not recordIsEligibleStaticPoison(recordId, rec) then return false end
    return addDiscoveredPoisonId(recordId)
end

local function scanInventoryForPoisonIds(inventory)
    if not inventory then return 0 end
    local found = 0
    for _, item in pairs(inventory:getAll(types.Potion)) do
        if considerPotionRecordId(item.recordId) then
            found = found + 1
        end
    end
    return found
end

local function rebuildStaticPoisonPool()
    staticPoisonPool = {}
    staticPoisonPoolReady = true
    local seen = {}

    local function addCandidate(recordId)
        if type(recordId) ~= 'string' or recordId == '' then return end
        local key = lower(recordId)
        if seen[key] then return end
        local record = types.Potion.records[recordId]
        if not record then return end
        if not recordIsEligibleStaticPoison(recordId, record) then return end
        staticPoisonPool[#staticPoisonPool + 1] = recordId
        seen[key] = true
    end

    for id, record in pairs(types.Potion.records) do
        if type(id) == 'string' and recordIsEligibleStaticPoison(id, record) then
            addCandidate(id)
        end
    end

    if config.fallbackExistingPoisonIds then
        for _, recordId in ipairs(config.fallbackExistingPoisonIds) do
            addCandidate(recordId)
        end
    end

    for _, recordId in ipairs(getDiscoveredPoisonList()) do
        addCandidate(recordId)
    end

    table.sort(staticPoisonPool)
    debugLog(string.format('Built static poison pool: %d existing harmful potion records.', #staticPoisonPool), 'debugDistributionMessages')
    if #staticPoisonPool > 0 then
        local preview = {}
        for i = 1, math.min(12, #staticPoisonPool) do preview[#preview + 1] = staticPoisonPool[i] end
        debugLog('Static poison pool preview: ' .. table.concat(preview, ', '), 'debugDistributionMessages')
    else
        debugLog('Static poison pool is empty. Existing-poison distribution has nothing eligible to place after filtering.', 'debugDistributionMessages')
    end
end

local function ensureStaticPoisonPool()
    if staticPoisonPoolReady then return end
    rebuildStaticPoisonPool()
end

local function weightedRandomStaticPoison()
    ensureStaticPoisonPool()
    if #staticPoisonPool == 0 then return nil end
    return staticPoisonPool[math.random(#staticPoisonPool)]
end

local function shuffledStaticPoisonPool()
    ensureStaticPoisonPool()
    local pool = {}
    for i = 1, #staticPoisonPool do pool[i] = staticPoisonPool[i] end
    for i = #pool, 2, -1 do
        local j = math.random(i)
        pool[i], pool[j] = pool[j], pool[i]
    end
    return pool
end

local function buildMerchantSelection(count)
    ensureStaticPoisonPool()
    if #staticPoisonPool == 0 or count <= 0 then return {} end

    local picks = {}
    local forcedId = 'p_drain_intelligence_q'
    local forcedPresent = false
    for _, recordId in ipairs(staticPoisonPool) do
        if lower(recordId) == forcedId then
            forcedPresent = true
            break
        end
    end

    local pool = shuffledStaticPoisonPool()
    local used = {}

    if forcedPresent then
        picks[#picks + 1] = forcedId
        used[forcedId] = true
    end

    for _, recordId in ipairs(pool) do
        if #picks >= count then break end
        local key = lower(recordId)
        if not used[key] then
            picks[#picks + 1] = recordId
            used[key] = true
        end
    end

    while #picks < count do
        picks[#picks + 1] = weightedRandomStaticPoison()
    end

    return picks
end

local function cellStateKey(cell)
    if not cell then return nil end
    local name = cell.name or ''
    if name ~= '' then return name:lower() end
    return string.format('%s,%s', tostring(cell.gridX), tostring(cell.gridY))
end

local function inventoryHasStaticPoison(inventory)
    if not inventory then return false end
    for _, item in pairs(inventory:getAll(types.Potion)) do
        local rec = types.Potion.records[item.recordId]
        if rec and recordIsEligibleStaticPoison(item.recordId, rec) then
            return true
        end
    end
    return false
end

local function addPotionToInventory(inventory, recordId, count)
    if not inventory or not recordId then return false end

    -- Final safety gate: even if a stale pool/selection contains an old bad
    -- candidate, never inject alcohol or any now-ineligible potion into the
    -- world as Toxicology distribution stock.
    local record = types.Potion.records[recordId]
    if not record then
        debugLog('[Distribution] Refused to add missing potion record ' .. tostring(recordId), 'debugDistributionMessages')
        return false
    end
    if alcoholIsDistributionBlacklisted(recordId, record) then
        debugLog('[Distribution] Refused to add alcohol record as poison stock: ' .. tostring(recordId), 'debugDistributionMessages')
        return false
    end
    if not recordIsEligibleStaticPoison(recordId, record) then
        debugLog('[Distribution] Refused to add ineligible poison stock: ' .. tostring(recordId), 'debugDistributionMessages')
        return false
    end

    local ok, obj = pcall(world.createObject, recordId, count or 1)
    if not ok or not obj then
        debugLog('[Distribution] Failed to create object for ' .. tostring(recordId), 'debugDistributionMessages')
        return false
    end
    local moved, err = pcall(function() obj:moveInto(inventory) end)
    if not moved then
        debugLog('[Distribution] Failed to move ' .. tostring(recordId) .. ' into inventory: ' .. tostring(err), 'debugDistributionMessages')
        return false
    end
    return true
end

local function safeContainerRecord(container)
    if not container or not container:isValid() then return nil end
    local ok, rec = pcall(types.Container.record, container)
    if not ok then return nil end
    return rec
end

local function containerIsOrganic(container)
    local rec = safeContainerRecord(container)
    return rec and rec.isOrganic == true
end

local function shouldDistributeToContainer(container)
    local rec = safeContainerRecord(container)
    if not rec or rec.isOrganic then return false end
    local rid = lower(rec.id or '')
    local rname = lower(rec.name or '')
    local combined = rid .. ' ' .. rname
    local positives = { 'chest', 'crate', 'barrel', 'cabinet', 'closet', 'sack', 'basket', 'cupboard', 'apothe', 'alchemy', 'ingred', 'locker', 'supply' }
    local negatives = { 'corpse', 'remains', 'urn', 'coffin' }
    for _, n in ipairs(negatives) do
        if combined:find(n, 1, true) then return false end
    end
    for _, ptn in ipairs(positives) do
        if combined:find(ptn, 1, true) then return true end
    end
    return false
end

local function stockCellContainers(cell)
    if not readPlayerSetting('Settings_' .. MODNAME .. '_Distribution', 'distributeExistingPoisonsToContainers', true) then
        return 0
    end
    for _, container in ipairs(cell:getAll(types.Container)) do
        if not containerIsOrganic(container) then
            local inventory = types.Container.inventory(container)
            if inventory then scanInventoryForPoisonIds(inventory) end
        end
    end
    staticPoisonPoolReady = false
    local key = cellStateKey(cell)
    if not key then return 0 end
    local doneKey = DISTRIBUTION_SCHEMA .. ':containers:' .. key
    if cellDistributionState:get(doneKey) then return 0 end
    ensureStaticPoisonPool()
    if #staticPoisonPool == 0 then
        debugLog('[Distribution] Skipped cell ' .. key .. ': no eligible existing poison records found.', 'debugDistributionMessages')
        cellDistributionState:set(doneKey, true)
        return 0
    end
    local added = 0
    for _, container in ipairs(cell:getAll(types.Container)) do
        if shouldDistributeToContainer(container) then
            local inventory = types.Container.inventory(container)
            if inventory and not inventoryHasStaticPoison(inventory) then
                local roll = math.random()
                local chance = readPlayerSetting('Settings_' .. MODNAME .. '_Distribution', 'existingPoisonContainerChance', 0.10)
                if roll <= chance then
                    local recordId = weightedRandomStaticPoison()
                    if recordId and addPotionToInventory(inventory, recordId, 1) then
                        added = added + 1
                    end
                end
            end
        end
    end
    cellDistributionState:set(doneKey, true)
    debugLog(string.format('[Distribution] Processed containers in %s: added %d poison potions.', key, added), 'debugDistributionMessages')
    return added
end

local function npcOffersPotionService(npc)
    local ok, rec = pcall(types.NPC.record, npc)
    if not ok or not rec then return false end
    local services = rec.servicesOffered or {}
    if services.Potions or services.Spells then return true end
    local classId = lower(tostring(rec.class or ''))
    if classId:find('alchemist', 1, true) or classId:find('healer', 1, true) or classId:find('apothe', 1, true) then
        return true
    end
    local classRec = rec.class and types.NPC.classes and types.NPC.classes[rec.class] or nil
    local className = classRec and lower(tostring(classRec.name or '')) or ''
    if className:find('alchemist', 1, true) or className:find('healer', 1, true) or className:find('apothe', 1, true) then
        return true
    end
    local npcName = lower(tostring(rec.name or ''))
    if npcName:find('alchemist', 1, true) or npcName:find('apothecary', 1, true) then
        return true
    end
    return false
end

local function stockCellMerchants(cell)
    if not readPlayerSetting('Settings_' .. MODNAME .. '_Distribution', 'distributeExistingPoisonsToMerchants', true) then
        return 0
    end
    for _, npc in ipairs(cell:getAll(types.NPC)) do
        local inv = types.Actor.inventory(npc)
        if inv then scanInventoryForPoisonIds(inv) end
    end
    staticPoisonPoolReady = false
    local key = cellStateKey(cell)
    if not key then return 0 end
    local added = 0
    ensureStaticPoisonPool()
    if #staticPoisonPool == 0 then
        debugLog('[Distribution] Skipped merchants in ' .. key .. ': no eligible existing poison records found.', 'debugDistributionMessages')
        return 0
    end
    for _, npc in ipairs(cell:getAll(types.NPC)) do
        if npcOffersPotionService(npc) then
            local npcRecordId = tostring(npc.recordId or '<unknown>')
            local doneKey = DISTRIBUTION_SCHEMA .. ':npc:' .. tostring(npc.id)
            if cellDistributionState:get(doneKey) then
                debugLog(string.format('[Distribution] Merchant %s in %s already processed for schema %s.', npcRecordId, key, DISTRIBUTION_SCHEMA), 'debugDistributionMessages')
            else
                local inventory = types.NPC.inventory(npc)
                if not inventory then
                    debugLog(string.format('[Distribution] Merchant %s in %s has no NPC inventory handle.', npcRecordId, key), 'debugDistributionMessages')
                elseif inventoryHasStaticPoison(inventory) then
                    debugLog(string.format('[Distribution] Merchant %s in %s already has eligible poison stock; skipping add.', npcRecordId, key), 'debugDistributionMessages')
                    cellDistributionState:set(doneKey, true)
                else
                    local count = readPlayerSetting('Settings_' .. MODNAME .. '_Distribution', 'existingPoisonMerchantStock', 2)
                    local addedForNpc = 0
                    local selection = buildMerchantSelection(count)
                    for _, recordId in ipairs(selection) do
                        if recordId and addPotionToInventory(inventory, recordId, 1) then
                            added = added + 1
                            addedForNpc = addedForNpc + 1
                            debugLog(string.format('[Distribution] Added %s to merchant %s in %s.', recordId, npcRecordId, key), 'debugDistributionMessages')
                        end
                    end
                    if addedForNpc > 0 then
                        cellDistributionState:set(doneKey, true)
                        debugLog(string.format('[Distribution] Merchant %s in %s received %d poison potions.', npcRecordId, key, addedForNpc), 'debugDistributionMessages')
                    else
                        debugLog(string.format('[Distribution] Merchant %s in %s received 0 poison potions.', npcRecordId, key), 'debugDistributionMessages')
                    end
                end
            end
        end
    end
    if added > 0 then
        debugLog(string.format('[Distribution] Stocked merchants in %s with %d poison potions.', key, added), 'debugDistributionMessages')
    else
        debugLog(string.format('[Distribution] No merchant poison additions were made in %s.', key), 'debugDistributionMessages')
    end
    return added
end

local function distributeExistingPoisonsInCell(cell)
    if not cell then return end
    if not readPlayerSetting('Settings_' .. MODNAME .. '_Distribution', 'enableExistingPoisonDistribution', true) then
        return
    end
    debugLog('[Distribution] Running distribution for cell ' .. tostring(cellStateKey(cell)) .. '.', 'debugDistributionMessages')
    stockCellContainers(cell)
    stockCellMerchants(cell)
end

-- ─── Weapon equipped check ──────────────────────────────────────────────────
local function isSupportedWeaponObject(w)
    local rec = safeWeaponRecord(w)
    if not rec or not rec.type then return nil end
    for typeName, allowed in pairs(config.weapons.allowedTypes) do
        if allowed and types.Weapon.TYPE[typeName] == rec.type then
            return rec
        end
    end
    return nil
end

local function getEquippedWeapon(actor)
    local equipment = types.Actor.getEquipment(actor)
    if not equipment then return nil end
    local w = equipment[types.Actor.EQUIPMENT_SLOT.CarriedRight]
    local rec = isSupportedWeaponObject(w)
    if not rec then return nil end
    return w, rec
end

-- ─── Charge calculation ─────────────────────────────────────────────────────
local function calcMaxCharges(skill)
    local c = config.charges
    local charges = math.floor(skill / c.chargesPerTier) + 1
    return math.max(c.minCharges, math.min(c.maxCharges, charges))
end

local function getPlayerToxSkill(actor)
    local synced = runtimeSection:get('currentSkill')
    if type(synced) == 'number' and synced > 0 then
        return synced
    end
    return config.startLevel or 1
end


local function calcMaxLayers(skill)
    if skill >= config.perks.compoundBlendLevel
        and toxicologyPerkEnabled('enableCompoundBlend') then
        return config.perks.compoundBlendMaxLayers or 3
    end
    return 1
end

local LAYER_KEYS = {
    { poison = 'poisonId', charges = 'charges' },
    { poison = 'layer2PoisonId', charges = 'layer2Charges' },
    { poison = 'layer3PoisonId', charges = 'layer3Charges' },
}

local WEAKNESS_TO_POISON_EFFECT_ID = (core.magic.EFFECT_TYPE and core.magic.EFFECT_TYPE.WeaknessToPoison) or 'weaknesstopoison'
local TOXIC_PRECISION_RECORD_ID = 'toxicology_toxic_perfection_weakness'
local weaknessToPoisonRecordCache = nil

local function isWeaknessToPoisonEffect(effectId)
    if not effectId then return false end
    local id = tostring(effectId):lower()
    return id == 'weaknesstopoison'
        or id == tostring(WEAKNESS_TO_POISON_EFFECT_ID):lower()
end

local function recordStringId(recordId, record)
    if record and type(record.id) == 'string' and record.id ~= '' then
        return record.id
    end
    if type(recordId) == 'string' and recordId ~= '' then
        return recordId
    end
    return nil
end

local function createToxicPrecisionRecord()
    if core.magic.spells.records[TOXIC_PRECISION_RECORD_ID] then
        return core.magic.spells.records[TOXIC_PRECISION_RECORD_ID]
    end
    if not (core.magic.spells and core.magic.spells.createRecordDraft and world.createRecord) then
        return nil
    end

    local magnitude = tonumber(config.perks.toxicPrecisionMagnitude) or 25
    local duration = tonumber(config.perks.toxicPrecisionDuration) or 10

    local ok, recordOrErr = pcall(function()
        local draft = core.magic.spells.createRecordDraft({
            id = TOXIC_PRECISION_RECORD_ID,
            name = 'Toxic Perfection',
            type = core.magic.SPELL_TYPE.Spell,
            cost = 0,
            effects = {
                {
                    id = WEAKNESS_TO_POISON_EFFECT_ID,
                    range = core.magic.RANGE.Touch,
                    area = 0,
                    duration = duration,
                    magnitudeMin = magnitude,
                    magnitudeMax = magnitude,
                },
            },
        })
        return world.createRecord(draft)
    end)

    if ok and recordOrErr then
        debugLog('Toxic Perfection: created runtime Weakness to Poison record id=' .. tostring(recordOrErr.id), 'debugCombatMessages')
        return recordOrErr
    end

    debugLog('Toxic Perfection: could not create runtime Weakness to Poison record: ' .. tostring(recordOrErr), 'debugCombatMessages')
    return nil
end

local function findWeaknessToPoisonRecord()
    if weaknessToPoisonRecordCache ~= nil then
        return weaknessToPoisonRecordCache or nil
    end

    -- Prefer our own runtime record so the perk is deterministic: Weakness to
    -- Poison, fixed magnitude, fixed 10 second duration. Older OpenMW builds may
    -- not support runtime spell records, so the existing-record scan below is
    -- retained as a compatibility fallback.
    local customRecord = createToxicPrecisionRecord()
    if customRecord and customRecord.id then
        weaknessToPoisonRecordCache = {
            id = customRecord.id,
            name = customRecord.name or 'Toxic Perfection',
            effectIndex = 0,
            magnitudeMin = tonumber(config.perks.toxicPrecisionMagnitude) or 25,
            magnitudeMax = tonumber(config.perks.toxicPrecisionMagnitude) or 25,
            duration = tonumber(config.perks.toxicPrecisionDuration) or 10,
            generated = true,
        }
        return weaknessToPoisonRecordCache
    end

    local desiredMagnitude = tonumber(config.perks.toxicPrecisionMagnitude) or 25
    local desiredDuration = tonumber(config.perks.toxicPrecisionDuration) or 10
    local best = nil
    local bestScore = math.huge

    local function scoreRecord(recordId, recordName, effect, index, sourcePenalty)
        local id = recordStringId(recordId, recordName and { id = recordId } or nil)
        -- The iterable key can be a non-string userdata on some OpenMW builds;
        -- never pass that to activeSpells:add or it becomes Spell 'Empty{}'.
        if not id then return end

        local magMin = tonumber(effect.magnitudeMin) or 0
        local magMax = tonumber(effect.magnitudeMax) or magMin
        local duration = tonumber(effect.duration) or 0
        local avgMag = (magMin + magMax) * 0.5
        local score = (sourcePenalty or 0)
            + math.abs(duration - desiredDuration) * 10
            + math.abs(avgMag - desiredMagnitude) * 2
        if best == nil or score < bestScore then
            best = {
                id = id,
                name = recordName or id,
                effectIndex = index - 1,
                magnitudeMin = magMin,
                magnitudeMax = magMax,
                duration = duration,
                generated = false,
            }
            bestScore = score
        end
    end

    for recordId, record in pairs(core.magic.spells.records) do
        local id = recordStringId(recordId, record)
        if id then
            local effects = record.effects or {}
            for index, effect in ipairs(effects) do
                if isWeaknessToPoisonEffect(effect.id) then
                    scoreRecord(id, record.name, effect, index, 0)
                end
            end
        end
    end

    for recordId, record in pairs(types.Potion.records) do
        local id = recordStringId(recordId, record)
        if id then
            local effects = record.effects or {}
            for index, effect in ipairs(effects) do
                if isWeaknessToPoisonEffect(effect.id) then
                    scoreRecord(id, record.name, effect, index, 25)
                end
            end
        end
    end

    weaknessToPoisonRecordCache = best or false
    return best
end

local function activeLayerCount(data)
    local n = 0
    for _, k in ipairs(LAYER_KEYS) do
        if data[k.poison] then n = n + 1 end
    end
    return n
end

local function firstFreeLayerIndex(data, maxLayers)
    for i = 1, maxLayers do
        local k = LAYER_KEYS[i]
        if not data[k.poison] then return i end
    end
    return nil
end

local function findPoisonLayerIndex(data, poisonId)
    for i, k in ipairs(LAYER_KEYS) do
        if data[k.poison] == poisonId then return i end
    end
    return nil
end

-- ─── Apply poison to weapon ─────────────────────────────────────────────────
-- The heart of the mod. Called when the player confirms the dialog with "Apply".
-- For melee/ranged: keys coating state by weapon object id.
-- For thrown: keys coating state by thrown weapon record id so projectile hits
-- can still find the coating after the object leaves the player's inventory.
--
-- evt.potion    : the potion GameObject
-- evt.actor     : the player
-- evt.layer     : coating slot selected by the system; Compound Blend supports up to 3 total layers
local function applyPoisonToWeapon(evt)
    local actor = evt.actor
    local potion = evt.potion
    if not actor or not potion then return end

    local weapon = evt.weapon
    local weaponRec = isSupportedWeaponObject(weapon)
    if not weaponRec then
        weapon, weaponRec = getEquippedWeapon(actor)
    end
    if not weapon or not weaponRec then
        actor:sendEvent('Toxicology_Message', { text = 'No suitable weapon available to coat.' })
        return
    end

    local skill = getPlayerToxSkill(actor)
    local charges = calcMaxCharges(skill)
    local maxLayers = calcMaxLayers(skill)
    local data = getWeaponPoison(weapon) or {}
    local isThrown = isThrownWeaponObject(weapon)
    data.snapshot = data.snapshot or {}
    data.snapshot[potion.recordId] = snapshotPotion(types.Potion.record(potion))

    local sameLayer = findPoisonLayerIndex(data, potion.recordId)
    if sameLayer then
        if skill >= config.perks.masterCoatingLevel
           and toxicologyPerkEnabled('enableMasterCoating') then
            local key = LAYER_KEYS[sameLayer]
            local existing = data[key.charges] or 0
            local reinforcedMax = charges * 2
            data[key.charges] = math.min(reinforcedMax, existing + charges)
            setWeaponPoison(weapon, data)
            actor:sendEvent('Toxicology_Message', { text = string.format('Reinforced poison coating (%d charges).', data[key.charges]) })
            actor:sendEvent('Toxicology_PerkFired', { perk = 'masterCoating' })
            potion:remove(1)
            return
        else
            local key = LAYER_KEYS[sameLayer]
            data[key.charges] = charges
            setWeaponPoison(weapon, data)
            potion:remove(1)
            actor:sendEvent('Toxicology_Message', {
                text = string.format('Refreshed %s on %s (%d charges).', types.Potion.record(potion).name, weaponRec.name, charges),
            })
            return
        end
    end

    local slot = firstFreeLayerIndex(data, maxLayers)
    local addingLayer = true
    if not slot then
        if readPlayerSetting('Settings_' .. MODNAME, 'warnOverwrite', true) then
            actor:sendEvent('Toxicology_Message', {
                text = 'All coating slots are full. Disable overwrite protection in Toxicology settings to replace the last coating.',
            })
            return
        end
        slot = maxLayers
        addingLayer = false
    end
    local key = LAYER_KEYS[slot]
    data[key.poison] = potion.recordId
    data[key.charges] = charges
    setWeaponPoison(weapon, data)
    potion:remove(1)

    local msg
    if slot == 1 and activeLayerCount(data) == 1 then
        if isThrown then
            msg = string.format('Applied %s to your next %d %s throws.', types.Potion.record(potion).name, charges, weaponRec.name)
        else
            msg = string.format('Applied %s to %s (%d charges).', types.Potion.record(potion).name, weaponRec.name, charges)
        end
    elseif addingLayer then
        msg = string.format('Added %s as coating %d on %s (%d charges).', types.Potion.record(potion).name, slot, weaponRec.name, charges)
    else
        msg = string.format('Replaced coating %d with %s on %s (%d charges).', slot, types.Potion.record(potion).name, weaponRec.name, charges)
    end
    actor:sendEvent('Toxicology_Message', { text = msg })

    if readPlayerSetting('Settings_' .. MODNAME .. '_Skill', 'xpOnApply', true) then
        actor:sendEvent('Toxicology_GrantXp', { useType = 'apply', amount = config.xp.apply })
    end
end

-- ─── Refresh existing poison (Master Coating perk, skill 25+) ──────────────
-- Same poison ID = add charges (up to max). Different poison ID = overwrite
-- prompt handled by player script.
local function refreshPoisonCharges(evt)
    local actor = evt.actor
    local weapon = evt.weapon
    if not actor or not weapon then return end
    local data = getWeaponPoison(weapon)
    if not data then return end
    local skill = getPlayerToxSkill(actor)
    local maxCharges = calcMaxCharges(skill) * 2
    local addCharges = calcMaxCharges(skill)
    local slot = tonumber(evt.slot) or 1
    local key = LAYER_KEYS[slot]
    if not key or not data[key.poison] then return end
    local existing = data[key.charges] or 0
    data[key.charges] = math.min(maxCharges, existing + addCharges)
    setWeaponPoison(weapon, data)
    actor:sendEvent('Toxicology_Message', { text = string.format('Reinforced poison coating (%d charges).', data[key.charges]) })
end

-- ─── Clear poison (external compatibility event) ───────────────────────────
local function clearPoison(evt)
    local weapon = evt.weapon
    if not weapon then return end
    clearWeaponPoison(weapon)
end

local function consumePoisonChargesByKey(weaponKey, opts)
    if not weaponKey then return false end
    opts = opts or {}

    local data = getWeaponPoisonByKey(weaponKey)
    if not data then return false end

    local activeLayers = {}
    for _, key in ipairs(LAYER_KEYS) do
        if data[key.poison] and (data[key.charges] or 0) > 0 then
            activeLayers[#activeLayers + 1] = {
                poisonKey = key.poison,
                chargeKey = key.charges,
            }
        end
    end

    if #activeLayers == 0 then
        clearWeaponPoisonByKey(weaponKey)
        return false
    end

    for _, layer in ipairs(activeLayers) do
        local chargesLeft = (data[layer.chargeKey] or 0) - 1
        if chargesLeft <= 0 then
            data[layer.chargeKey] = nil
            data[layer.poisonKey] = nil
        else
            data[layer.chargeKey] = chargesLeft
        end
    end

    if not data.poisonId and not data.layer2PoisonId and not data.layer3PoisonId then
        clearWeaponPoisonByKey(weaponKey)
    else
        setWeaponPoisonByKey(weaponKey, data)
    end

    if opts.projectileToken ~= nil then
        markProjectileTokenConsumed(opts.projectileToken, weaponKey)
    end

    debugLog('Consumed poison charge(s) for ' .. tostring(opts.reason or 'unknown') .. ' key=' .. tostring(weaponKey), 'debugCombatMessages')
    return true
end

-- ─── Apply hit effects to victim ────────────────────────────────────────────
-- Called by the actor script when it detects a successful hit with a poisoned
-- weapon. We apply the poison's magic effects to the victim via activeSpells.
local function applyHitEffects(evt)
    local attacker = evt.attacker
    local victim = evt.victim
    local weapon = evt.weapon
    local weaponKey = evt.weaponKey or poisonStorageKey(weapon)
    if not attacker or not victim or not weaponKey then return end

    local projectileToken = evt.projectileToken
    local projectileData = nil
    local weaponType = evt.weaponType
    if weaponType == nil and weapon then
        local rec = safeWeaponRecord(weapon)
        weaponType = rec and rec.type
    end

    local isProjectileHit = projectileContextMatchesHit(projectileToken, weaponKey, weaponType)
    if isProjectileHit then
        projectileToken = projectileToken or currentProjectileTokenForKey(weaponKey)
        projectileData = projectilePoisonDataForToken(projectileToken)
    end

    -- getWeaponPoisonByKey returns a plain table copy (read-only userdata isn't
    -- mutable in place). Projectile charges are spent exclusively when the attack
    -- button starts a draw/throw; projectile Hit events only apply the pre-spend
    -- snapshot without consuming it again. Melee still reads and consumes the
    -- live coating on impact. This intentionally does not depend solely on
    -- attack.sourceType because bow hits can still arrive in a shape that would
    -- otherwise look like an ordinary weapon hit and double-spend the coating.
    local chargesAlreadySpent = isProjectileHit or projectileData ~= nil
    local data = projectileData or getWeaponPoisonByKey(weaponKey)
    if not data then return end

    local skill = getPlayerToxSkill(attacker)

    local function resolvePoison(poisonId)
        if not poisonId then return nil, nil end

        -- Primary lookup: live record from the potion system. For static
        -- potions and third-party mod potions this always works. For player-
        -- brewed (dynamic) potions it may return nil after reload.
        local potionRec = types.Potion.records[poisonId]
        if potionRec then
            return potionRec.effects, potionRec.name
        end

        if data.snapshot and data.snapshot[poisonId] then
            local snap = data.snapshot[poisonId]
            debugLog('applyLayer: using snapshot for dynamic poison id=' .. tostring(poisonId), 'debugCombatMessages')
            return snap.effects, snap.name
        end

        debugLog('applyLayer: potion record not found for id=' .. tostring(poisonId) .. ' (no snapshot either)', 'debugCombatMessages')
        return nil, nil
    end

    local function sendPoisonFx(target, effectsSource)
        if not target or not effectsSource then return end
        if not readPlayerSetting('Settings_' .. MODNAME .. '_UI', 'hitVfx', true)
           and not readPlayerSetting('Settings_' .. MODNAME .. '_UI', 'hitSound', true) then
            return
        end

        local effectIds = {}
        for i = 1, #effectsSource do
            local eff = effectsSource[i]
            if eff.id then effectIds[#effectIds + 1] = eff.id end
        end
        if #effectIds > 0 then
            target:sendEvent('Toxicology_PlayFx', { effectIds = effectIds })
        end
    end

    local function applyPoisonToTarget(target, poisonId)
        local effectsSource, displayName = resolvePoison(poisonId)
        if not effectsSource then return false end

        local effectIndices = {}
        for i = 1, #effectsSource do
            effectIndices[#effectIndices + 1] = i - 1 -- OpenMW uses 0-indexed effect indices
        end

        debugLog('applyLayer: applying ' .. tostring(poisonId) ..
              ' (' .. #effectIndices .. ' effects) to ' .. tostring(target), 'debugCombatMessages')

        local ok, err = pcall(function()
            types.Actor.activeSpells(target):add({
                id = poisonId,
                effects = effectIndices,
                caster = attacker,
                stackable = true,
                ignoreResistances = false,
                ignoreReflect = true,
                name = displayName,
            })
        end)
        if not ok then
            debugLog('applyLayer: activeSpells:add FAILED: ' .. tostring(err), 'debugCombatMessages')
            return false
        end

        -- activeSpells:add bypasses the normal cast VFX/SFX path, so actor.lua
        -- replays the effect feedback locally when those UI options are enabled.
        sendPoisonFx(target, effectsSource)
        return true
    end

    -- Capture the active layers before charge consumption. Efficient Coating
    -- uses this snapshot to preserve every layer from the same hit when its
    -- shared proc roll succeeds.
    local activeLayers = {}
    for _, key in ipairs(LAYER_KEYS) do
        if data[key.poison] and (data[key.charges] or 0) > 0 then
            activeLayers[#activeLayers + 1] = {
                poisonId = data[key.poison],
                chargeKey = key.charges,
                poisonKey = key.poison,
            }
        end
    end

    if #activeLayers == 0 then
        clearWeaponPoisonByKey(weaponKey)
        return
    end

    if projectileToken ~= nil
       and projectileRuntimeSection:get('lastAppliedToken') == projectileToken then
        debugLog('Skipping duplicate projectile poison hit token=' .. tostring(projectileToken), 'debugCombatMessages')
        return
    end

    local function maybeApplyToxicPrecision()
        if skill < config.perks.toxicPrecisionLevel
            or not toxicologyPerkEnabled('enableToxicPrecision') then
            return false
        end

        local chance = tonumber(config.perks.toxicPrecisionChance) or 35
        local roll = math.random() * 100
        if roll >= chance then
            return false
        end

        local match = findWeaknessToPoisonRecord()
        if not match then
            debugLog('Toxic Perfection: no Weakness to Poison spell or potion record found in load order', 'debugCombatMessages')
            return false
        end

        local ok, err = pcall(function()
            types.Actor.activeSpells(victim):add({
                id = match.id,
                effects = { match.effectIndex },
                name = 'Toxic Perfection',
                caster = attacker,
                stackable = true,
                ignoreReflect = true,
                ignoreSpellAbsorption = true,
                ignoreResistances = false,
            })
        end)
        if not ok then
            debugLog('Toxic Perfection: activeSpells:add FAILED: ' .. tostring(err), 'debugCombatMessages')
            return false
        end

        debugLog('Toxic Perfection: applied Weakness to Poison via ' .. tostring(match.id), 'debugCombatMessages')
        attacker:sendEvent('Toxicology_PerkFired', { perk = 'toxicPrecision' })
        return true
    end

    -- Toxic Perfection is applied before the poison payload so poison-effect
    -- layers can benefit from the Weakness to Poison debuff on the same strike.
    maybeApplyToxicPrecision()

    -- Efficient Coating perk (75+): one shared proc roll per poisoned hit. If it
    -- triggers, every currently active layer is preserved so Compound Blend layers
    -- stay synchronized instead of independently drifting by charge count.
    local preserveAllCharges = false
    if not chargesAlreadySpent
       and skill >= config.perks.efficientCoatingLevel
       and toxicologyPerkEnabled('enableEfficientCoating') then
        local preserveChance = tonumber(config.perks.efficientCoatingChance) or 15
        local roll = math.random() * 100
        if roll < preserveChance then
            preserveAllCharges = true
            debugLog('Efficient Coating preserved all active layers (rolled ' .. string.format('%.1f', roll)
                .. ' < ' .. string.format('%.1f', preserveChance) .. '%)', 'debugCombatMessages')
            attacker:sendEvent('Toxicology_PerkFired', { perk = 'efficientCoating' })
        end
    end

    local function consumeCharge(chargeKey, poisonKey)
        if chargesAlreadySpent or preserveAllCharges then return end
        local chargesLeft = data[chargeKey] or 0
        if chargesLeft <= 0 then return end

        chargesLeft = chargesLeft - 1
        if chargesLeft <= 0 then
            data[chargeKey] = nil
            data[poisonKey] = nil
        else
            data[chargeKey] = chargesLeft
        end
    end

    for _, layer in ipairs(activeLayers) do
        applyPoisonToTarget(victim, layer.poisonId)
        consumeCharge(layer.chargeKey, layer.poisonKey)
    end

    if projectileToken ~= nil then
        projectileRuntimeSection:set('lastAppliedToken', projectileToken)
    end

    if not chargesAlreadySpent then
        if not data.poisonId and not data.layer2PoisonId and not data.layer3PoisonId then
            clearWeaponPoisonByKey(weaponKey)
        else
            setWeaponPoisonByKey(weaponKey, data)
        end

        if projectileToken ~= nil then
            markProjectileTokenConsumed(projectileToken, weaponKey)
        end
    end
end

-- ─── Hook ItemUsage ────────────────────────────────────────────────────────
-- This fires when the player drags any potion onto the paperdoll (or activates
-- it from quick-keys / Inventory Extender — all go through the same path).
-- We inspect the potion: if harmful AND a weapon is equipped, we intercept
-- and show the confirmation dialog. Otherwise, we let the vanilla drink go
-- ahead by returning nothing (i.e. letting other handlers run).
I.ItemUsage.addHandlerForType(types.Potion, function(potion, actor, options)
    -- Respect force flag: if the player chose Drink in our dialog, we fire
    -- UseItem with force=true. That flag means "bypass handler decisions",
    -- so we let the potion drink through without re-prompting.
    if options and options.force then return end

    -- Global safety checks
    if not readPlayerSetting('Settings_' .. MODNAME, 'enabled', true) then return end
    if not actor or not types.Player.objectIsInstance(actor) then return end

    -- Is this a harmful potion?
    if not potionIsHarmful(potion) then return end

    -- Is a suitable weapon equipped?
    local weapon = getEquippedWeapon(actor)
    if not weapon then return end

    -- Block in combat?
    if readPlayerSetting('Settings_' .. MODNAME, 'blockInCombat', true) then
        -- TODO: robust combat detection. For now we check if any nearby
        -- actor has the player as a target. Deferred to player-side script.
        -- This flag is passed so the player can show a clearer error.
    end

    -- Defer the decision to the player. Send an event with the potion and
    -- weapon info; the player script shows the dialog and sends back the
    -- result.
    actor:sendEvent('Toxicology_PromptApply', {
        potionId = potion.id,
        potionRecord = potion.recordId,
        weaponId = weapon.id,
        weaponRecord = weapon.recordId,
    })

    -- Block vanilla drinking for now. The player's dialog choice will either:
    --   * "Apply"  — fires Toxicology_ConfirmApply back to global
    --   * "Drink"  — fires Toxicology_ForceDrink which calls UseItem with force
    --   * "Cancel" — does nothing; potion remains untouched
    return false
end)

-- ─── World init: scan existing harmful potion records when game starts ──────
-- The player script fires 'Toxicology_RequestInit' to us on first frame after
-- it's synced its settings into the runtime globalSection. We do the record
-- creation then, not in onPlayerAdded (which fires before player sync).
local function handleRequestInit(evt)
    local player = evt.player
    if player then
        local inv = types.Actor.inventory(player)
        if inv then scanInventoryForPoisonIds(inv) end
    end
    rebuildStaticPoisonPool()
    if player then
        player:sendEvent('Toxicology_PoisonIdMap', {
            idMap = poisonIdMap,
            specialtyIdMap = specialtyIdMap,
        })
        if player.cell then
            distributeExistingPoisonsInCell(player.cell)
        end
    end
end

local function onPlayerAdded(player)
    -- Leave distribution setup to the request-driven flow above. This is just a
    -- safety net: if the player never sends the init request (e.g. PLAYER
    -- script disabled by user), this hook remains harmless.
    -- In practice the request arrives on the player's first onUpdate tick.
end

local function onSave()
    return {
        weaponPoisonState = serializeWeaponPoisonState(),
    }
end

local function onLoad(data)
    restoreWeaponPoisonState(data and data.weaponPoisonState)
    clearProjectileRuntimeState()
end

-- Settings mirror: player script reads its playerSection and forwards the
-- values to us via Toxicology_UpdateRuntimeSettings. Only global scripts
-- can write to globalSection, hence this indirection.
local function handleUpdateRuntimeSettings(payload)
    if type(payload) ~= 'table' then return end
    for key, value in pairs(payload) do
        runtimeSection:set(key, value)
    end
    if payload.enableExistingPoisonDistribution ~= nil
       or payload.ignoreAlcoholPotions ~= nil
       or payload.allowMixedEffectPoisons ~= nil
       or payload.distributeExistingPoisonsToContainers ~= nil
       or payload.distributeExistingPoisonsToMerchants ~= nil
       or payload.existingPoisonMerchantStock ~= nil
       or payload.existingPoisonContainerChance ~= nil then
        staticPoisonPoolReady = false
    end
end

local function handleUpdateProjectileRuntime(evt)
    if type(evt) ~= 'table' then return end
    if not evt.token or not evt.weaponKey then return end
    if not isProjectileWeaponType(evt.weaponType) then return end

    projectileRuntimeSection:set('token', evt.token)
    projectileRuntimeSection:set('releasedAt', evt.releasedAt or core.getSimulationTime())
    projectileRuntimeSection:set('weaponKey', evt.weaponKey)
    projectileRuntimeSection:set('recordId', evt.recordId)
    projectileRuntimeSection:set('weaponType', evt.weaponType)
    projectileRuntimeSection:set('poisonData', copyWeaponPoisonData(evt.poisonData))
    projectileRuntimeSection:set('active', true)
end

local function handleClearProjectileRuntime(evt)
    local token = evt and evt.token
    if token ~= nil and projectileRuntimeSection:get('token') ~= token then return end
    projectileRuntimeSection:set('active', false)
end

local function handleConsumeRangedAttack(evt)
    if type(evt) ~= 'table' then return end
    if not evt.weaponKey or evt.token == nil then return end
    if not isProjectileWeaponType(evt.weaponType) then return end

    if projectileRuntimeSection:get('lastConsumedToken') == evt.token then
        return
    end

    if consumePoisonChargesByKey(evt.weaponKey, {
        reason = 'ranged attack',
        projectileToken = evt.token,
    }) then
        local actor = evt.actor
        if actor and types.Player.objectIsInstance(actor)
           and readPlayerSetting('Settings_' .. MODNAME .. '_UI', 'showRangedCoatingSpentMessage', false) then
            actor:sendEvent('Toxicology_Message', { text = 'Poison coating spent on shot.' })
        end
    end
end

local function handleDistributeCell(evt)
    if not evt then return end
    if evt.player then
        local inv = types.Actor.inventory(evt.player)
        if inv then scanInventoryForPoisonIds(inv) end
    end
    if evt.player and evt.player.cell then
        distributeExistingPoisonsInCell(evt.player.cell)
    elseif evt.cell then
        distributeExistingPoisonsInCell(evt.cell)
    end
end

return {
    interfaceName = 'Toxicology',
    interface = {
        version = 1,
        getPoisonRecordId = function(idBase) return poisonIdMap[idBase] end,
        isPoisonCandidate = potionIsHarmful,
    },
    engineHandlers = {
        onPlayerAdded = onPlayerAdded,
        onSave = onSave,
        onLoad = onLoad,
        onInit = onLoad,
    },
    eventHandlers = {
        Toxicology_ConfirmApply           = applyPoisonToWeapon,
        Toxicology_RefreshCharges         = refreshPoisonCharges,
        Toxicology_ClearPoison            = clearPoison,
        Toxicology_ApplyHit               = applyHitEffects,
        Toxicology_RequestInit            = handleRequestInit,
        Toxicology_UpdateRuntimeSettings  = handleUpdateRuntimeSettings,
        Toxicology_UpdateProjectileRuntime = handleUpdateProjectileRuntime,
        Toxicology_ClearProjectileRuntime = handleClearProjectileRuntime,
        Toxicology_ConsumeRangedAttack    = handleConsumeRangedAttack,
        Toxicology_TransferWeaponPoisonState = transferWeaponPoisonState,
        Toxicology_DistributeCell         = handleDistributeCell,
    },
}
