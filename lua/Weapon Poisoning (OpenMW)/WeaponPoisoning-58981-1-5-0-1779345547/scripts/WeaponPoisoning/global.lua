local core = require('openmw.core')
local I = require('openmw.interfaces')
local types = require('openmw.types')
local world = require('openmw.world')
local constants = require('scripts.WeaponPoisoning.constants')

local l10n = core.l10n('WeaponPoisoning')

local NPC_AUTO_POISON_SCAN_INTERVAL = 1
local NPC_NO_USABLE_POISON_CACHE_TTL = 1
local NPC_PENDING_APPLICATION_TIMEOUT = 5
local NPC_POISON_RANDOM_VARIATION_MIN = -15
local NPC_POISON_RANDOM_VARIATION_MAX = 15
local NPC_POISON_QUALITY_MIN = -21
local NPC_POISON_QUALITY_MAX = 181
local NPC_POISON_LEVEL_CHANCE_MULTIPLIER = 1.0
local NPC_POISON_LEVEL_CHANCE_CAP = 25
local NPC_FACTION_RANK_MIN = 1
local NPC_FACTION_RANK_MAX = 10
local NPC_FACTION_RANK_MAX_MULTIPLIER = 3.0
local DEFAULT_NPC_REAPPLY_COOLDOWN_SECONDS = 10
local DEFAULT_NPC_GENERATED_POISON_MAX_COUNT = 3

local NPC_OWNED_POISON_RECORD_IDS = {
    'wp_poison_b',
    'wp_poison_c',
    'wp_poison_s',
    'wp_poison_q',
    'wp_poison_e',
}
local NPC_REFINED_POISON_RECORD_ID_PREFIXES = {
    'p_sap',
    'p_poison',
    'p_drain',
    'p_damage',
    'p_burden',
    'p_blind',
    'p_paralyze',
    'p_sound',
    'p_silence',
}
local NPC_POISON_TIERS = {
    { id = 'bargain', suffix = '_b', maxQuality = 30 },
    { id = 'cheap', suffix = '_c', maxQuality = 65 },
    { id = 'standard', suffix = '_s', maxQuality = 105 },
    { id = 'quality', suffix = '_q', maxQuality = 145 },
    { id = 'exclusive', suffix = '_e' },
}

local NPC_CLASS_BASE = {
    assassin = 35,
    nightblade = 28,
    alchemist = 25,
    apothecary = 24,
    agent = 22,
    rogue = 18,
    smuggler = 16,
    thief = 14,
    sharpshooter = 14,
    mabrigash = 12,
    witch = 12,
    enforcer = 12,
    archer = 12,
    warlock = 10,
    ['wise woman'] = 10,
    scout = 10,
    witchhunter = 10,
    hunter = 8,
    necromancer = 8,
    barbarian = 5,
    warrior = 3,
}
local NPC_CLASS_QUALITY = {
    assassin = 25,
    nightblade = 20,
    alchemist = 18,
    apothecary = 16,
    agent = 15,
    ['wise woman'] = 12,
    rogue = 10,
    mabrigash = 10,
    witch = 10,
    warlock = 8,
    necromancer = 8,
    smuggler = 8,
    thief = 8,
    witchhunter = 8,
    sharpshooter = 6,
    enforcer = 5,
    archer = 5,
    hunter = 4,
    scout = 3,
    barbarian = -5,
    warrior = -8,
}

local NPC_FACTION_VALUES = {
    -- Assassin faction identity.
    ['Dark Brotherhood'] = { bonus = 25, quality = 25 },
    -- Project Cyrodiil assassin faction identity.
    T_Cyr_DarkBrotherhood = { bonus = 25, quality = 25 },
    -- Skyrim Home of the Nords assassin faction identity.
    T_Sky_DarkBrotherhood = { bonus = 25, quality = 25 },
    -- Strong poison-user identity.
    ['Morag Tong'] = { bonus = 20, quality = 25 },
    -- Criminal faction bonus.
    ['Camonna Tong'] = { bonus = 12, quality = 12 },
    -- Criminal, drug, and Alchemy-adjacent faction.
    T_Mw_JaNattaSyndicate = { bonus = 12, quality = 14 },
    -- Stealth-coded vampire faction.
    ['Clan Berne'] = { bonus = 8, quality = 10 },
    -- Sneak/Illusion vampire faction.
    T_Mw_Clan_Baluath = { bonus = 8, quality = 10 },
    -- Criminal faction, lower than assassin factions.
    ['Thieves Guild'] = { bonus = 6, quality = 6 },
    -- Project Cyrodiil criminal faction.
    T_Cyr_ThievesGuild = { bonus = 6, quality = 6 },
    -- Skyrim Home of the Nords criminal faction.
    T_Sky_ThievesGuild = { bonus = 6, quality = 6 },
    -- Infiltration-oriented vampire faction.
    T_Cyr_VampirumOrder = { bonus = 6, quality = 8 },
    -- Vampire faction.
    T_Sky_ClanKhulari = { bonus = 6, quality = 8 },
    -- Applies only to skilled alchemists in this house.
    Telvanni = { bonus = 5, quality = 10, requiresAlchemyAbove = 40 },
    -- Alchemy, Security, and Short Blade favored skills; mostly merchant/swindler identity.
    TR_Fact_SyvvitTong = { bonus = 4, quality = 6 },
    -- Applies only to skilled alchemists in this guild.
    T_Cyr_NibenHierophants = { bonus = 4, quality = 8, requiresAlchemyAbove = 40 },
    -- Low practical poison access.
    Ashlanders = { bonus = 3, quality = 5 },
    -- Ashlander-like nomadic Dunmer culture signal.
    T_Mw_Shinathi = { bonus = 3, quality = 5 },
    -- Applies only to skilled alchemists in this guild.
    ['Mages Guild'] = { bonus = 3, quality = 8, requiresAlchemyAbove = 40 },
    -- Project Cyrodiil Mages Guild.
    T_Cyr_MagesGuild = { bonus = 3, quality = 8, requiresAlchemyAbove = 40 },
    -- Skyrim Home of the Nords Mages Guild.
    T_Sky_MagesGuild = { bonus = 3, quality = 8, requiresAlchemyAbove = 40 },
    -- Thirr River/Hammerfell Mages Guild.
    T_Ham_MagesGuild = { bonus = 3, quality = 8, requiresAlchemyAbove = 40 },
    -- Weak intrigue/crime-adjacent bonus.
    Hlaalu = { bonus = 3, quality = 3 },
    -- Weak ruthless-house bonus.
    T_Mw_HouseDres = { bonus = 3, quality = 4 },
}
local NPC_FACTION_VALUES_BY_LOWER_ID = {}
for factionId, entry in pairs(NPC_FACTION_VALUES) do
    if type(factionId) == 'string' then
        NPC_FACTION_VALUES_BY_LOWER_ID[factionId:lower()] = entry
    end
end

local npcAutoPoisonPoolCache = nil
local poisonedWeapons = {}
local poisonedWeaponOwners = {}
local checkedNpcPoisonActors = {}
local npcPoisonInventoryActors = {}
local pendingNpcPoisonApplications = {}
local npcPoisonCooldowns = {}
local npcNoUsablePoisonUntil = {}
local nextNpcPoisonScanTime = 0
local modEnabledByActor = {}
local suppressPoisonApplication = {}
local forcePoisonApplication = {}
local autoReapplyPoisonByActor = {}
local stackPoisonsOnTargetByActor = {}
local protectStrongerPoisonByActor = {}
local npcPoisoningByActor = {}
local npcPotionsRefinedIntegrationByActor = {}
local npcReapplyCooldownByActor = {}
local npcGeneratedPoisonMaxCountByActor = {}
local npcPoisonAnimationByActor = {}
local npcDebugLoggingEnabled = false
local poisonHitVfxEnabled = true
local poisonHitSoundEnabled = true
local poisonVfxFullDuration = true

local function player()
    return world.players and world.players[1] or nil
end

local function isPlayer(actor)
    local p = player()
    return p ~= nil and actor ~= nil and actor.id == p.id
end

local function isModEnabled(actor)
    if actor == nil or isPlayer(actor) then
        return actor == nil or modEnabledByActor[actor.id] ~= false
    end

    local p = player()
    return p == nil or modEnabledByActor[p.id] ~= false
end

local function autoReapplyPoison(actor)
    return actor ~= nil and autoReapplyPoisonByActor[actor.id] == true
end

local function stackPoisonsOnTarget(actor)
    return actor ~= nil and isPlayer(actor) and stackPoisonsOnTargetByActor[actor.id] == true
end

local function protectStrongerPoison(actor)
    return actor == nil or protectStrongerPoisonByActor[actor.id] ~= false
end

local function npcPoisoningEnabled(actor)
    if actor == nil or isPlayer(actor) then
        return actor == nil or npcPoisoningByActor[actor.id] ~= false
    end

    local p = player()
    return p == nil or npcPoisoningByActor[p.id] ~= false
end

local function npcPotionsRefinedIntegrationEnabled(actor)
    if actor == nil or isPlayer(actor) then
        return actor == nil or npcPotionsRefinedIntegrationByActor[actor.id] ~= false
    end

    local p = player()
    return p == nil or npcPotionsRefinedIntegrationByActor[p.id] ~= false
end

local function npcReapplyCooldownSeconds(actor)
    local p = isPlayer(actor) and actor or player()
    local value = p and npcReapplyCooldownByActor[p.id] or DEFAULT_NPC_REAPPLY_COOLDOWN_SECONDS
    if type(value) ~= 'number' then
        value = DEFAULT_NPC_REAPPLY_COOLDOWN_SECONDS
    end
    return math.max(0, math.min(60, value))
end

local function npcGeneratedPoisonMaxCount(actor)
    local p = isPlayer(actor) and actor or player()
    local value = p and npcGeneratedPoisonMaxCountByActor[p.id] or DEFAULT_NPC_GENERATED_POISON_MAX_COUNT
    if type(value) ~= 'number' then
        value = DEFAULT_NPC_GENERATED_POISON_MAX_COUNT
    end
    return math.max(1, math.min(10, math.floor(value)))
end

local function npcPoisonAnimationEnabled(actor)
    if actor == nil or isPlayer(actor) then
        return actor == nil or npcPoisonAnimationByActor[actor.id] ~= false
    end

    local p = player()
    return p == nil or npcPoisonAnimationByActor[p.id] ~= false
end

local function sendPlayer(eventName, data)
    local p = player()
    if p and p:isValid() then
        p:sendEvent(eventName, data)
    end
end

local function showMessage(actor, key, args)
    if actor and actor:isValid() then
        actor:sendEvent('WP_ShowMessage', {
            text = l10n(key, args or {}),
        })
    end
end

local function grantAlchemyProgress(actor)
    if actor and actor:isValid() then
        actor:sendEvent('WP_GrantAlchemyProgress')
    end
end

local function syncState()
    sendPlayer('WP_SyncPoisonedWeapons', { poisonedWeapons = poisonedWeapons })
end

local function debugLog(message)
    if not npcDebugLoggingEnabled then
        return
    end
    print('[WeaponPoisoning] ' .. tostring(message))
end

local function showNpcDebugMessage(message)
    if not npcDebugLoggingEnabled then
        return
    end

    sendPlayer('WP_ShowMessage', {
        text = tostring(message),
    })
end

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

local function formatPercent(value)
    return ('%.1f%%'):format(value)
end

local function getPotionRecord(recordId)
    return recordId and types.Potion.records[recordId] or nil
end

local function startsWith(value, prefix)
    return type(value) == 'string' and value:sub(1, #prefix) == prefix
end

local function endsWith(value, suffix)
    return type(value) == 'string' and value:sub(-#suffix) == suffix
end

local function getWeaponRecord(weapon)
    return weapon and types.Weapon.record(weapon) or nil
end

local function isSupportedWeapon(weapon)
    if not weapon or weapon.type ~= types.Weapon then
        return false
    end
    local record = getWeaponRecord(weapon)
    return record ~= nil and record.type ~= types.Weapon.TYPE.MarksmanThrown
end

local function weaponBonus(weapon)
    if not weapon or weapon.type ~= types.Weapon then
        return -20
    end
    local record = getWeaponRecord(weapon)
    if not record then
        return -20
    end

    local weaponType = record.type
    local weaponTypes = types.Weapon.TYPE
    if weaponType == weaponTypes.ShortBladeOneHand
        or weaponType == weaponTypes.MarksmanBow
        or weaponType == weaponTypes.MarksmanCrossbow
    then
        return 8
    elseif weaponType == weaponTypes.LongBladeOneHand
        or weaponType == weaponTypes.LongBladeTwoHand
        or weaponType == weaponTypes.AxeOneHand
        or weaponType == weaponTypes.AxeTwoHand
    then
        return 2
    elseif weaponType == weaponTypes.BluntOneHand
        or weaponType == weaponTypes.BluntTwoClose
        or weaponType == weaponTypes.BluntTwoWide
    then
        return -5
    end
    return 0
end

local function prunePoisonedWeapons(actor)
    if not actor or not actor:isValid() then
        return
    end

    local currentWeaponIds = {}
    for _, weapon in ipairs(types.Actor.inventory(actor):getAll(types.Weapon)) do
        currentWeaponIds[weapon.id] = true
    end

    local equippedWeapon = types.Actor.getEquipment(actor, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    if equippedWeapon and equippedWeapon.type == types.Weapon then
        currentWeaponIds[equippedWeapon.id] = true
    end

    for weaponId in pairs(poisonedWeapons) do
        local ownerId = poisonedWeaponOwners[weaponId]
        if (ownerId == nil or ownerId == actor.id) and not currentWeaponIds[weaponId] then
            poisonedWeapons[weaponId] = nil
            poisonedWeaponOwners[weaponId] = nil
        end
    end
end

local function clearNpcPoisonLifecycle(actor)
    if not actor then
        return
    end

    checkedNpcPoisonActors[actor.id] = nil
    npcPoisonInventoryActors[actor.id] = nil
    pendingNpcPoisonApplications[actor.id] = nil
    npcPoisonCooldowns[actor.id] = nil
    npcNoUsablePoisonUntil[actor.id] = nil
    prunePoisonedWeapons(actor)
end

local function hasOnlyHarmfulEffects(potionRecord)
    if not potionRecord or not potionRecord.effects or #potionRecord.effects == 0 then
        return false
    end
    for _, effect in ipairs(potionRecord.effects) do
        local magicEffect = core.magic.effects.records[effect.id]
        if not magicEffect or magicEffect.harmful ~= true then
            return false
        end
    end
    return true
end

local function hasHarmfulEffect(potionRecord)
    if not potionRecord or not potionRecord.effects or #potionRecord.effects == 0 then
        return false
    end
    for _, effect in ipairs(potionRecord.effects) do
        local magicEffect = core.magic.effects.records[effect.id]
        if magicEffect and magicEffect.harmful == true then
            return true
        end
    end
    return false
end

local function allEffectIndexes(record)
    local indexes = {}
    for i = 1, #record.effects do
        indexes[i] = i - 1
    end
    return indexes
end

local function poisonValue(record)
    return record and record.value or 0
end

local function sendPoisonAppliedToWeaponEvent(actor, weapon, poisonRecordId, previousPoisonRecordId)
    core.sendGlobalEvent(constants.EVENT_POISON_APPLIED_TO_WEAPON, {
        time = core.getSimulationTime(),
        actor = actor,
        weapon = weapon,
        poisonRecordId = poisonRecordId,
        weaponRecordId = weapon and weapon.recordId or nil,
        previousPoisonRecordId = previousPoisonRecordId,
        wasReplacement = previousPoisonRecordId ~= nil,
    })
end

local function setPoisonedWeapon(actor, weapon, poisonRecordId)
    poisonedWeapons[weapon.id] = poisonRecordId
    poisonedWeaponOwners[weapon.id] = actor and actor.id or nil
end

local function reapplyPoisonIfAvailable(actor, weapon, poisonRecordId)
    if not autoReapplyPoison(actor) then
        return false
    end
    if not actor or not actor:isValid() or not weapon or not poisonRecordId then
        return false
    end

    local potion = types.Actor.inventory(actor):find(poisonRecordId)
    if not potion or potion.type ~= types.Potion then
        return false
    end

    potion:remove(1)
    setPoisonedWeapon(actor, weapon, poisonRecordId)
    grantAlchemyProgress(actor)
    sendPoisonAppliedToWeaponEvent(actor, weapon, poisonRecordId, nil)
    return true
end

local function poisonWeapon(potion, actor)
    if not isPlayer(actor) then
        return nil
    end
    if not isModEnabled(actor) then
        return nil
    end

    local potionRecord = getPotionRecord(potion.recordId)
    if suppressPoisonApplication[actor.id] == true then
        return nil
    end
    if forcePoisonApplication[actor.id] == true then
        if not hasHarmfulEffect(potionRecord) then
            return nil
        end
    elseif not hasOnlyHarmfulEffects(potionRecord) then
        return nil
    end

    local weapon = types.Actor.getEquipment(actor, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    if not weapon then
        showMessage(actor, 'NoWeaponEquippedMessage')
        return false
    end
    if not isSupportedWeapon(weapon) then
        showMessage(actor, 'UnsupportedWeaponMessage')
        return false
    end

    prunePoisonedWeapons(actor)

    local existingPoisonRecordId = poisonedWeapons[weapon.id]
    local existingPoisonRecord = getPotionRecord(existingPoisonRecordId)
    local strongerPoisonProtected = existingPoisonRecord
        and protectStrongerPoison(actor)
        and poisonValue(existingPoisonRecord) >= poisonValue(potionRecord)
    if strongerPoisonProtected then
        showMessage(actor, 'WeaponPoisonProtectedMessage', {
            existingPoison = existingPoisonRecord.name,
            newPoison = potionRecord.name,
            existingValue = poisonValue(existingPoisonRecord),
            newValue = poisonValue(potionRecord),
        })
        return false
    elseif existingPoisonRecordId then
        poisonedWeapons[weapon.id] = nil
        poisonedWeaponOwners[weapon.id] = nil
    end

    local weaponRecord = getWeaponRecord(weapon)
    setPoisonedWeapon(actor, weapon, potion.recordId)
    potion:remove(1)
    grantAlchemyProgress(actor)
    sendPoisonAppliedToWeaponEvent(actor, weapon, potion.recordId, existingPoisonRecordId)
    syncState()
    showMessage(actor, 'AppliedPoisonMessage', {
        poison = potionRecord.name,
        weapon = weaponRecord and weaponRecord.name or weapon.recordId,
    })
    return false
end

local function npcClass(actor)
    if not actor or not actor:isValid() or actor.type ~= types.NPC then
        return nil
    end

    local record = types.NPC.record(actor)
    return record and record.class or nil
end

local function normalizedClassKey(class)
    if type(class) ~= 'string' then
        return nil
    end

    local normalized = class:lower()
    normalized = normalized:gsub('%s+', ' ')
    normalized = normalized:gsub('^%s+', ''):gsub('%s+$', '')
    if normalized == 'assasin' or startsWith(normalized, 'assasin ') then
        return 'assassin'
    end
    for classKey in pairs(NPC_CLASS_BASE) do
        if normalized == classKey or startsWith(normalized, classKey .. ' ') then
            return classKey
        end
    end
    return nil
end

local function actorDebugName(actor)
    local record = actor and actor:isValid() and actor.type == types.NPC and types.NPC.record(actor) or nil
    return record and record.name ~= '' and record.name or actor.recordId
end

local function npcAlchemySkill(actor)
    if not actor or not actor:isValid() or actor.type ~= types.NPC then
        return nil
    end

    local ok, stat = pcall(types.NPC.stats.skills.alchemy, actor)
    if not ok or not stat then
        return nil
    end
    return stat.modified or stat.base or 0
end

local function npcLevel(actor)
    if not actor or not actor:isValid() or actor.type ~= types.NPC then
        return 1
    end

    local record = types.NPC.record(actor)
    return record and record.level or 1
end

local function npcFactionInfo(actor)
    if not actor or not actor:isValid() or actor.type ~= types.NPC then
        return nil
    end

    local record = types.NPC.record(actor)
    local function nonEmpty(value)
        return type(value) == 'string' and value ~= ''
    end

    local factionIds = {}
    local ranksByFactionId = {}
    local seen = {}
    local ok, factions = pcall(types.NPC.getFactions, actor)
    if ok and factions then
        for _, id in pairs(factions) do
            if nonEmpty(id) and not seen[id] then
                factionIds[#factionIds + 1] = id
                seen[id] = true
                local rankOk, factionRank = pcall(types.NPC.getFactionRank, actor, id)
                if rankOk then
                    ranksByFactionId[id] = factionRank
                end
            end
        end
    end

    local primaryFaction = record and record.primaryFaction or nil
    if nonEmpty(primaryFaction) and not seen[primaryFaction] then
        factionIds[#factionIds + 1] = primaryFaction
        seen[primaryFaction] = true
        ranksByFactionId[primaryFaction] = record and record.primaryFactionRank or nil
    end

    local factionId = nonEmpty(primaryFaction) and primaryFaction or factionIds[1]
    if not factionId then
        return nil
    end

    local rank = nil
    local rankOk, factionRank = pcall(types.NPC.getFactionRank, actor, factionId)
    if rankOk then
        rank = factionRank
    elseif factionId == primaryFaction then
        rank = record and record.primaryFactionRank or nil
    end
    ranksByFactionId[factionId] = ranksByFactionId[factionId] or rank

    return {
        factionId = factionId,
        rank = rank,
        factionIds = factionIds,
        ranksByFactionId = ranksByFactionId,
        primaryFactionId = primaryFaction,
    }
end

local function factionEntryApplies(entry, alchemy)
    return entry ~= nil and (entry.requiresAlchemyAbove == nil or alchemy > entry.requiresAlchemyAbove)
end

local function npcFactionPoisonEntry(factionId)
    if type(factionId) ~= 'string' then
        return nil
    end
    return NPC_FACTION_VALUES[factionId] or NPC_FACTION_VALUES_BY_LOWER_ID[factionId:lower()]
end

local function factionRankMultiplier(rank)
    if type(rank) ~= 'number' or rank <= 0 then
        return 1
    end

    local clampedRank = clamp(rank, NPC_FACTION_RANK_MIN, NPC_FACTION_RANK_MAX)
    local rank01 = (clampedRank - NPC_FACTION_RANK_MIN) / (NPC_FACTION_RANK_MAX - NPC_FACTION_RANK_MIN)
    return 1 + rank01 * (NPC_FACTION_RANK_MAX_MULTIPLIER - 1)
end

local function scaledFactionValues(entry, rank)
    local multiplier = factionRankMultiplier(rank)
    return {
        bonus = (entry.bonus or 0) * multiplier,
        quality = (entry.quality or 0) * multiplier,
        baseBonus = entry.bonus or 0,
        baseQuality = entry.quality or 0,
        rank = rank,
        multiplier = multiplier,
    }
end

local function bestFactionPoisonValues(factionInfo, alchemy)
    if not factionInfo then
        return 0, 0, nil, nil
    end

    local primary = factionInfo.primaryFactionId
    local primaryEntry = npcFactionPoisonEntry(primary)
    if factionEntryApplies(primaryEntry, alchemy) then
        local scaled = scaledFactionValues(primaryEntry, factionInfo.ranksByFactionId[primary])
        return scaled.bonus, scaled.quality, primary, scaled
    end

    local bestBonus = 0
    local bestQuality = 0
    local bestId = nil
    local bestScaled = nil
    for _, factionId in ipairs(factionInfo.factionIds or {}) do
        local entry = npcFactionPoisonEntry(factionId)
        if factionEntryApplies(entry, alchemy) then
            local scaled = scaledFactionValues(entry, factionInfo.ranksByFactionId[factionId])
            local bonus = scaled.bonus
            local quality = scaled.quality
            if not bestId or bonus > bestBonus or (bonus == bestBonus and quality > bestQuality) then
                bestBonus = bonus
                bestQuality = quality
                bestId = factionId
                bestScaled = scaled
            end
        end
    end
    return bestBonus, bestQuality, bestId, bestScaled
end

local function npcFactionDebug(actor)
    local factionInfo = npcFactionInfo(actor)
    if not factionInfo then
        return 'unknown'
    end

    local text = factionInfo.factionId

    if factionInfo.rank ~= nil then
        return ('%s rank=%s'):format(tostring(text), tostring(factionInfo.rank))
    end
    return tostring(text)
end

local function randomVariation()
    return math.random(NPC_POISON_RANDOM_VARIATION_MIN, NPC_POISON_RANDOM_VARIATION_MAX)
end

local function npcPoisonChanceComponents(actor, classKey, alchemy, factionBonus)
    local weapon = types.Actor.getEquipment(actor, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    local level = npcLevel(actor)
    local components = {
        classBase = NPC_CLASS_BASE[classKey] or 0,
        factionBonus = factionBonus or 0,
        alchemyBonus = math.min(alchemy * 0.30, 20),
        levelBonus = math.min(level * NPC_POISON_LEVEL_CHANCE_MULTIPLIER, NPC_POISON_LEVEL_CHANCE_CAP),
        weaponBonus = weaponBonus(weapon),
        randomVariation = randomVariation(),
    }
    components.raw = components.classBase
        + components.factionBonus
        + components.alchemyBonus
        + components.levelBonus
        + components.weaponBonus
        + components.randomVariation
    components.chance = math.max(0, components.raw)
    components.level = level
    components.weaponRecordId = weapon and weapon.recordId or 'none'
    return components
end

local function npcPoisonQualityComponents(actor, classKey, alchemy, factionQuality)
    local level = npcLevel(actor)
    local components = {
        levelQuality = level * 2,
        alchemyQuality = alchemy * 0.8,
        classQuality = NPC_CLASS_QUALITY[classKey] or 0,
        factionQuality = factionQuality or 0,
        randomVariation = randomVariation(),
    }
    components.total = components.levelQuality
        + components.alchemyQuality
        + components.classQuality
        + components.factionQuality
        + components.randomVariation
    components.level = level
    return components
end

local function formatChanceComponents(components)
    return ((
        'chanceFormula=class %.1f + faction %.1f + alchemy %.1f + level %.1f '
        .. '+ weapon %.1f + random %.1f = %.1f -> floor[0] %.1f'
    ):format(
        components.classBase,
        components.factionBonus,
        components.alchemyBonus,
        components.levelBonus,
        components.weaponBonus,
        components.randomVariation,
        components.raw,
        components.chance
    ))
end

local function formatQualityComponents(components)
    return ((
        'qualityFormula=level %.1f + alchemy %.1f + class %.1f + faction %.1f '
        .. '+ random %.1f = %.1f'
    ):format(
        components.levelQuality,
        components.alchemyQuality,
        components.classQuality,
        components.factionQuality,
        components.randomVariation,
        components.total
    ))
end

local function formatFactionRankScaling(scaledFaction)
    if not scaledFaction then
        return 'factionRank=none'
    end

    return ('factionRank=%s, factionRankMultiplier=%.2f, factionBaseBonus=%.1f, factionBaseQuality=%.1f'):format(
        tostring(scaledFaction.rank or 'unknown'),
        scaledFaction.multiplier,
        scaledFaction.baseBonus,
        scaledFaction.baseQuality
    )
end

local function tierForQuality(quality)
    for _, tier in ipairs(NPC_POISON_TIERS) do
        if tier.maxQuality == nil or quality <= tier.maxQuality then
            return tier
        end
    end
    return NPC_POISON_TIERS[#NPC_POISON_TIERS]
end

local function generatedPoisonCount(actor, poisonQuality)
    local maxCount = npcGeneratedPoisonMaxCount(actor)
    if maxCount <= 1 then
        return 1
    end

    local quality01 = clamp(
        (poisonQuality - NPC_POISON_QUALITY_MIN) / (NPC_POISON_QUALITY_MAX - NPC_POISON_QUALITY_MIN),
        0,
        1
    )
    return clamp(1 + math.floor(quality01 * (maxCount - 1)), 1, maxCount)
end

local function matchesAnyPrefix(recordId, prefixes)
    for _, prefix in ipairs(prefixes) do
        if startsWith(recordId, prefix) then
            return true
        end
    end
    return false
end

local function isPotionsRefinedDetected()
    local foundPrefixes = {}
    for _, potionRecord in pairs(types.Potion.records) do
        local recordId = potionRecord and potionRecord.id or nil
        for _, prefix in ipairs(NPC_REFINED_POISON_RECORD_ID_PREFIXES) do
            if startsWith(recordId, prefix) then
                foundPrefixes[prefix] = true
            end
        end
    end
    for _, prefix in ipairs(NPC_REFINED_POISON_RECORD_ID_PREFIXES) do
        if not foundPrefixes[prefix] then
            return false
        end
    end
    return true
end

local function buildPotionsRefinedPoisonIds()
    local recordIds = {}
    for _, potionRecord in pairs(types.Potion.records) do
        local recordId = potionRecord and potionRecord.id or nil
        if recordId
            and matchesAnyPrefix(recordId, NPC_REFINED_POISON_RECORD_ID_PREFIXES)
            and not recordId:find('resistance', 1, true)
        then
            recordIds[#recordIds + 1] = potionRecord.id
        end
    end
    table.sort(recordIds)
    return recordIds
end

local function emptyTieredPool(poolName)
    local byTier = {}
    for _, tier in ipairs(NPC_POISON_TIERS) do
        byTier[tier.id] = {}
    end
    return {
        byTier = byTier,
        poolName = poolName,
        count = 0,
    }
end

local function addPoolCandidate(pool, poisonRecordId)
    local poisonRecord = getPotionRecord(poisonRecordId)
    if not poisonRecord or not hasOnlyHarmfulEffects(poisonRecord) then
        return
    end

    for _, tier in ipairs(NPC_POISON_TIERS) do
        if endsWith(poisonRecordId, tier.suffix) then
            local candidates = pool.byTier[tier.id]
            candidates[#candidates + 1] = {
                recordId = poisonRecordId,
                record = poisonRecord,
            }
            pool.count = pool.count + 1
            return
        end
    end
end

local function buildNpcAutoPoisonPool(useRefined)
    local pool = emptyTieredPool(useRefined and 'Potions Refined' or 'WeaponPoisoning')
    pool.cacheKey = useRefined and 'refined' or 'owned'
    local recordIds = useRefined and buildPotionsRefinedPoisonIds() or NPC_OWNED_POISON_RECORD_IDS
    for _, poisonRecordId in ipairs(recordIds) do
        addPoolCandidate(pool, poisonRecordId)
    end
    return pool
end

local function npcAutoPoisonPool(actor)
    local refinedIntegrationEnabled = npcPotionsRefinedIntegrationEnabled(actor)
    local refinedDetected = refinedIntegrationEnabled and isPotionsRefinedDetected()
    local useRefined = refinedIntegrationEnabled and refinedDetected
    local cacheKey = useRefined and 'refined' or 'owned'
    if npcAutoPoisonPoolCache and npcAutoPoisonPoolCache.cacheKey == cacheKey then
        return npcAutoPoisonPoolCache
    end

    local pool = buildNpcAutoPoisonPool(useRefined)
    if refinedIntegrationEnabled and not refinedDetected then
        debugLog(
            'NPC poison pool: Potions Refined integration enabled '
            .. 'but not all expected p_* poison prefixes were found; using WeaponPoisoning.'
        )
    end
    npcAutoPoisonPoolCache = pool
    debugLog(('NPC poison pool: using %s candidates=%d.'):format(pool.poolName, pool.count))
    return pool
end

local function resetNpcAutoPoisonPool()
    npcAutoPoisonPoolCache = nil
end

local function clearActivePoisonHitVfx()
    local sent = {}
    for _, actor in ipairs(world.activeActors) do
        if actor and actor:isValid() and sent[actor.id] ~= true then
            sent[actor.id] = true
            actor:sendEvent('WP_ClearPoisonHitVfx')
        end
    end
    for _, p in ipairs(world.players or {}) do
        if p and p:isValid() and sent[p.id] ~= true then
            sent[p.id] = true
            p:sendEvent('WP_ClearPoisonHitVfx')
        end
    end
end

local function chooseRandomCandidate(candidates)
    if not candidates or #candidates == 0 then
        return nil
    end
    return candidates[math.random(1, #candidates)]
end

local function replaceNpcInventoryPoison(actor, sourcePool, targetPool)
    if not actor or not actor:isValid() or isPlayer(actor) or actor.type ~= types.NPC then
        return false
    end
    if npcPoisonInventoryActors[actor.id] ~= true then
        return false
    end

    local inventory = types.Actor.inventory(actor)
    local replaced = false
    for _, tier in ipairs(NPC_POISON_TIERS) do
        local replacement = chooseRandomCandidate(targetPool.byTier[tier.id])
        if replacement then
            local replacementCount = 0
            for _, candidate in ipairs(sourcePool.byTier[tier.id]) do
                local item = inventory:find(candidate.recordId)
                if item and item.type == types.Potion then
                    replacementCount = replacementCount + item.count
                    item:remove(item.count)
                end
            end

            if replacementCount > 0 then
                world.createObject(replacement.recordId, replacementCount):moveInto(inventory)
                replaced = true
            end
        end
    end

    if replaced then
        pendingNpcPoisonApplications[actor.id] = nil
        npcNoUsablePoisonUntil[actor.id] = nil
        npcPoisonInventoryActors[actor.id] = true
        actor:sendEvent('WP_SetNpcPoisonCombatPolling', { enabled = true })
        debugLog(('NPC poison inventory migrated for %s: %s -> %s.'):format(
            actorDebugName(actor),
            sourcePool.poolName,
            targetPool.poolName
        ))
    end
    return replaced
end

local function migrateActiveNpcPoisonInventories(sourceUseRefined, targetUseRefined)
    if sourceUseRefined == targetUseRefined then
        return
    end

    local sourcePool = buildNpcAutoPoisonPool(sourceUseRefined)
    local targetPool = buildNpcAutoPoisonPool(targetUseRefined)
    if sourcePool.count == 0 or targetPool.count == 0 then
        return
    end

    local migratedCount = 0
    for _, actor in ipairs(world.activeActors) do
        if replaceNpcInventoryPoison(actor, sourcePool, targetPool) then
            migratedCount = migratedCount + 1
        end
    end
    if migratedCount > 0 then
        debugLog(('NPC poison inventory migration completed: %d actors, %s -> %s.'):format(
            migratedCount,
            sourcePool.poolName,
            targetPool.poolName
        ))
    end
end

local function migrateNpcPoisonInventoryToCurrentPool(actor)
    if not actor or not actor:isValid() or npcPoisonInventoryActors[actor.id] ~= true then
        return
    end

    local refinedIntegrationEnabled = npcPotionsRefinedIntegrationEnabled(actor)
    local targetUseRefined = refinedIntegrationEnabled and isPotionsRefinedDetected()
    local sourcePool = buildNpcAutoPoisonPool(not targetUseRefined)
    local targetPool = buildNpcAutoPoisonPool(targetUseRefined)
    if sourcePool.count == 0 or targetPool.count == 0 then
        return
    end
    replaceNpcInventoryPoison(actor, sourcePool, targetPool)
end

local function selectNpcGeneratedPoison(actor, poisonQuality)
    local tier = tierForQuality(poisonQuality)
    local pool = npcAutoPoisonPool(actor)
    return chooseRandomCandidate(pool.byTier[tier.id]), tier, pool
end

local function activeTargetHasPoison(target, poisonRecordId)
    if not target or not target:isValid() or type(poisonRecordId) ~= 'string' then
        return false
    end

    for _, spell in pairs(types.Actor.activeSpells(target)) do
        if spell.id == poisonRecordId then
            return true
        end
    end
    return false
end

local function selectInventoryPoison(actor, target)
    local pool = npcAutoPoisonPool(actor)
    local fallback = nil
    for _, tier in ipairs(NPC_POISON_TIERS) do
        for _, candidate in ipairs(pool.byTier[tier.id]) do
            local item = types.Actor.inventory(actor):find(candidate.recordId)
            if item and item.type == types.Potion then
                if not activeTargetHasPoison(target, candidate.recordId) then
                    return candidate
                end
                fallback = fallback or candidate
            end
        end
    end
    return nil, fallback
end

local function completeNpcPoisonApplication(actor)
    if not actor or not actor:isValid() then
        return
    end

    local pending = pendingNpcPoisonApplications[actor.id]
    if not pending then
        return
    end
    pendingNpcPoisonApplications[actor.id] = nil

    if types.Actor.isDead(actor) then
        debugLog(('NPC poison application skipped for %s (%s, faction=%s): actor died before completion.'):format(
            pending.actorName,
            pending.class,
            pending.faction
        ))
        return
    end

    local weapon = types.Actor.getEquipment(actor, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    if not weapon or weapon.id ~= pending.weaponId then
        debugLog(('NPC poison application skipped for %s (%s, faction=%s): weapon changed before completion.'):format(
            pending.actorName,
            pending.class,
            pending.faction
        ))
        return
    end
    if not isSupportedWeapon(weapon) then
        debugLog(('NPC poison application skipped for %s (%s, faction=%s): unsupported weapon %s.'):format(
            pending.actorName,
            pending.class,
            pending.faction,
            weapon.recordId
        ))
        return
    end

    local poisonItem = types.Actor.inventory(actor):find(pending.poisonRecordId)
    if not poisonItem or poisonItem.type ~= types.Potion then
        debugLog((
            'NPC poison application skipped for %s (%s, faction=%s): '
            .. 'poison %s is no longer in inventory.'
        ):format(
            pending.actorName,
            pending.class,
            pending.faction,
            pending.poisonRecordId
        ))
        return
    end

    poisonItem:remove(1)
    setPoisonedWeapon(actor, weapon, pending.poisonRecordId)
    npcPoisonCooldowns[actor.id] = core.getSimulationTime() + npcReapplyCooldownSeconds(actor)
    sendPoisonAppliedToWeaponEvent(actor, weapon, pending.poisonRecordId, pending.previousPoisonRecordId)
    debugLog(('NPC poison applied to %s (%s, faction=%s): %s on %s, target=%s, pool=%s.'):format(
        pending.actorName,
        pending.class,
        pending.faction,
        pending.poisonRecordId,
        weapon.recordId,
        pending.targetId or 'unknown',
        pending.poolName
    ))
end

local function expireStaleNpcPoisonApplication(actor)
    if not actor then
        return false
    end

    local pending = pendingNpcPoisonApplications[actor.id]
    if not pending or not pending.startedAt then
        return false
    end
    if core.getSimulationTime() - pending.startedAt < NPC_PENDING_APPLICATION_TIMEOUT then
        return false
    end

    pendingNpcPoisonApplications[actor.id] = nil
    debugLog(('NPC poison application expired for %s: no completion event was received.'):format(
        pending.actorName or actorDebugName(actor)
    ))
    return true
end

local function checkedNpcPoisonActorsForSave()
    local checked = {}
    for actorId, value in pairs(checkedNpcPoisonActors) do
        if pendingNpcPoisonApplications[actorId] == nil then
            checked[actorId] = value
        end
    end
    return checked
end

local function tryGenerateNpcPoison(actor)
    if not actor or not actor:isValid() or isPlayer(actor) then
        return
    end
    if actor.type ~= types.NPC then
        return
    end
    if types.Actor.isDead(actor) then
        clearNpcPoisonLifecycle(actor)
        actor:sendEvent('WP_SetNpcPoisonCombatPolling', { enabled = false })
        return
    end
    if not isModEnabled(actor) or not npcPoisoningEnabled(actor) then
        actor:sendEvent('WP_SetNpcPoisonCombatPolling', { enabled = false })
        return
    end
    expireStaleNpcPoisonApplication(actor)
    if checkedNpcPoisonActors[actor.id] then
        if npcPoisonInventoryActors[actor.id] == true then
            actor:sendEvent('WP_SetNpcPoisonCombatPolling', { enabled = true })
        end
        return
    end

    checkedNpcPoisonActors[actor.id] = true

    local class = npcClass(actor)
    local classKey = normalizedClassKey(class)
    if not classKey then
        debugLog(('NPC poison skipped for %s (%s): class is not eligible.'):format(
            actorDebugName(actor),
            tostring(class or 'unknown')
        ))
        return
    end

    local actorName = actorDebugName(actor)
    local factionDebug = npcFactionDebug(actor)
    local alchemy = npcAlchemySkill(actor)
    if not alchemy then
        debugLog(('NPC poison skipped for %s (%s, faction=%s): failed to read Alchemy skill.'):format(
            actorName,
            classKey,
            factionDebug
        ))
        return
    end

    local factionInfo = npcFactionInfo(actor)
    local factionBonus, factionQuality, matchedFactionId, scaledFaction =
        bestFactionPoisonValues(factionInfo, alchemy)
    local chanceComponents = npcPoisonChanceComponents(actor, classKey, alchemy, factionBonus)
    local chance = chanceComponents.chance
    local roll = math.random() * 100
    if roll >= chance then
        debugLog((
            'NPC poison skipped for %s (%s, faction=%s): '
            .. 'chance failed, level=%d, alchemy=%.1f, weapon=%s, matchedFaction=%s, %s, %s, roll=%s.'
        ):format(
            actorName,
            classKey,
            factionDebug,
            chanceComponents.level,
            alchemy,
            chanceComponents.weaponRecordId,
            matchedFactionId or 'none',
            formatFactionRankScaling(scaledFaction),
            formatChanceComponents(chanceComponents),
            formatPercent(roll)
        ))
        return
    end

    local qualityComponents = npcPoisonQualityComponents(actor, classKey, alchemy, factionQuality)
    local quality = qualityComponents.total
    local poisonCandidate, tier, pool = selectNpcGeneratedPoison(actor, quality)
    if not poisonCandidate then
        debugLog((
            'NPC poison skipped for %s (%s, faction=%s): '
            .. 'no valid poison candidates for tier=%s, pool=%s, matchedFaction=%s, %s, %s.'
        ):format(
            actorName,
            classKey,
            factionDebug,
            tier and tier.id or 'unknown',
            pool and pool.poolName or 'unknown',
            matchedFactionId or 'none',
            formatFactionRankScaling(scaledFaction),
            formatQualityComponents(qualityComponents)
        ))
        return
    end

    local poisonCount = generatedPoisonCount(actor, quality)
    world.createObject(poisonCandidate.recordId, poisonCount):moveInto(types.Actor.inventory(actor))
    npcPoisonInventoryActors[actor.id] = true
    actor:sendEvent('WP_SetNpcPoisonCombatPolling', { enabled = true })
    local poisonName = poisonCandidate.record and poisonCandidate.record.name or poisonCandidate.recordId
    showNpcDebugMessage(('NPC received poison: %s x%d (%s)'):format(
        actorName,
        poisonCount,
        poisonName
    ))
    debugLog((
        'NPC poison generated for %s (%s, faction=%s, matchedFaction=%s): '
        .. 'poison=%s count=%d tier=%s pool=%s level=%d alchemy=%.1f weapon=%s, %s, %s, %s, roll=%s.'
    ):format(
        actorName,
        classKey,
        factionDebug,
        matchedFactionId or 'none',
        poisonCandidate.recordId,
        poisonCount,
        tier.id,
        pool.poolName,
        chanceComponents.level,
        alchemy,
        chanceComponents.weaponRecordId,
        formatFactionRankScaling(scaledFaction),
        formatChanceComponents(chanceComponents),
        formatQualityComponents(qualityComponents),
        formatPercent(roll)
    ))
end

local function scanNpcAutoPoison()
    local now = core.getSimulationTime()
    if now < nextNpcPoisonScanTime then
        return
    end
    nextNpcPoisonScanTime = now + NPC_AUTO_POISON_SCAN_INTERVAL

    for _, actor in ipairs(world.activeActors) do
        tryGenerateNpcPoison(actor)
    end
end

local function startNpcCombatPoisonApplication(data)
    local actor = data and data.actor
    local target = data and data.target
    if not actor or not actor:isValid() or isPlayer(actor) or actor.type ~= types.NPC then
        return
    end
    if not isModEnabled(actor) or not npcPoisoningEnabled(actor) or types.Actor.isDead(actor) then
        return
    end
    if target and (not target:isValid() or types.Actor.isDead(target)) then
        target = nil
    end
    if pendingNpcPoisonApplications[actor.id] ~= nil then
        if not expireStaleNpcPoisonApplication(actor) then
            return
        end
    end

    local now = core.getSimulationTime()
    if npcPoisonCooldowns[actor.id] and now < npcPoisonCooldowns[actor.id] then
        return
    end
    if npcNoUsablePoisonUntil[actor.id] and now < npcNoUsablePoisonUntil[actor.id] then
        return
    end

    local weapon = types.Actor.getEquipment(actor, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    if not isSupportedWeapon(weapon) then
        return
    end
    if poisonedWeapons[weapon.id] ~= nil then
        return
    end

    prunePoisonedWeapons(actor)
    local poisonCandidate, duplicateCandidate = selectInventoryPoison(actor, target)
    if not poisonCandidate then
        npcNoUsablePoisonUntil[actor.id] = now + NPC_NO_USABLE_POISON_CACHE_TTL
        if duplicateCandidate then
            debugLog(('NPC poison skipped for %s: only duplicate active poison %s is available for target.'):format(
                actorDebugName(actor),
                duplicateCandidate.recordId
            ))
        end
        return
    end

    local class = normalizedClassKey(npcClass(actor)) or 'unknown'
    pendingNpcPoisonApplications[actor.id] = {
        actorName = actorDebugName(actor),
        class = class,
        faction = npcFactionDebug(actor),
        weaponId = weapon.id,
        poisonRecordId = poisonCandidate.recordId,
        previousPoisonRecordId = poisonedWeapons[weapon.id],
        targetId = target and target.id or nil,
        poolName = npcAutoPoisonPool(actor).poolName,
        startedAt = now,
    }

    if npcPoisonAnimationEnabled(actor) then
        actor:sendEvent('WP_PlayNpcPoisonAnimation', { poisonRecordId = poisonCandidate.recordId })
        return
    end

    completeNpcPoisonApplication(actor)
end

local function applyPoisonHit(data)
    local attacker = data and data.attacker
    if not isModEnabled(attacker) then
        return
    end

    local target = data and data.target
    local weapon = data and data.weapon
    if not attacker or not attacker:isValid() or not target or not target:isValid() or not weapon then
        return
    end
    if not isSupportedWeapon(weapon) then
        return
    end

    local poisonRecordId = poisonedWeapons[weapon.id]
    if not poisonRecordId then
        return
    end

    local poisonRecord = getPotionRecord(poisonRecordId)
    poisonedWeapons[weapon.id] = nil
    poisonedWeaponOwners[weapon.id] = nil

    if not poisonRecord or not poisonRecord.effects or #poisonRecord.effects == 0 then
        syncState()
        return
    end
    if types.Actor.isDead(target) then
        syncState()
        return
    end

    types.Actor.activeSpells(target):add({
        id = poisonRecord.id,
        effects = allEffectIndexes(poisonRecord),
        stackable = stackPoisonsOnTarget(attacker),
        caster = attacker,
        ignoreReflect = true,
        ignoreSpellAbsorption = true,
    })
    if poisonHitVfxEnabled or poisonHitSoundEnabled then
        target:sendEvent('WP_PlayPoisonHitVfx', {
            poisonRecordId = poisonRecordId,
            playVfx = poisonHitVfxEnabled,
            playSound = poisonHitSoundEnabled,
            fullDuration = poisonVfxFullDuration,
        })
    end
    local autoReapply = isPlayer(attacker) and autoReapplyPoison(attacker)
    local reapplied = reapplyPoisonIfAvailable(attacker, weapon, poisonRecordId)
    prunePoisonedWeapons(attacker)
    syncState()
    showMessage(attacker, 'PoisonDeliveredMessage', { poison = poisonRecord.name })
    if autoReapply and not reapplied then
        showMessage(attacker, 'PoisonDepletedMessage')
    end
end

I.ItemUsage.addHandlerForType(types.Potion, poisonWeapon)

return {
    eventHandlers = {
        WP_WeaponHit = applyPoisonHit,
        WP_NpcPoisonCombatCandidate = startNpcCombatPoisonApplication,
        WP_NpcPoisonAnimationComplete = function(data)
            completeNpcPoisonApplication(data and data.actor)
        end,
        WP_RequestSync = function()
            prunePoisonedWeapons(player())
            syncState()
        end,
        WP_SetModEnabled = function(data)
            local p = player()
            if p then
                modEnabledByActor[p.id] = data and data.enabled ~= false
            end
        end,
        WP_SetSuppressPoisonApplication = function(data)
            local p = player()
            if p then
                suppressPoisonApplication[p.id] = data and data.suppress == true
            end
        end,
        WP_SetForcePoisonApplication = function(data)
            local p = player()
            if p then
                forcePoisonApplication[p.id] = data and data.force == true
            end
        end,
        WP_SetAutoReapplyPoison = function(data)
            local p = player()
            if p then
                autoReapplyPoisonByActor[p.id] = data and data.autoReapply == true
            end
        end,
        WP_SetStackPoisonsOnTarget = function(data)
            local p = player()
            if p then
                stackPoisonsOnTargetByActor[p.id] = data and data.stackPoisons == true
            end
        end,
        WP_SetProtectStrongerPoison = function(data)
            local p = player()
            if p then
                protectStrongerPoisonByActor[p.id] = data and data.protect ~= false
            end
        end,
        WP_SetNpcPoisoning = function(data)
            local p = player()
            if p then
                npcPoisoningByActor[p.id] = data and data.enabled ~= false
            end
        end,
        WP_SetNpcPotionsRefinedIntegration = function(data)
            local p = player()
            if p then
                local oldEnabled = npcPotionsRefinedIntegrationByActor[p.id] ~= false
                local enabled = data == nil or data.enabled ~= false
                if npcPotionsRefinedIntegrationByActor[p.id] ~= enabled then
                    local refinedDetected = isPotionsRefinedDetected()
                    local oldUseRefined = oldEnabled and refinedDetected
                    local newUseRefined = enabled and refinedDetected
                    npcPotionsRefinedIntegrationByActor[p.id] = enabled
                    resetNpcAutoPoisonPool()
                    migrateActiveNpcPoisonInventories(oldUseRefined, newUseRefined)
                end
            end
        end,
        WP_SetNpcReapplyCooldown = function(data)
            local p = player()
            if p then
                npcReapplyCooldownByActor[p.id] = data and data.seconds or DEFAULT_NPC_REAPPLY_COOLDOWN_SECONDS
            end
        end,
        WP_SetNpcGeneratedPoisonMaxCount = function(data)
            local p = player()
            if p then
                npcGeneratedPoisonMaxCountByActor[p.id] = data and data.count or DEFAULT_NPC_GENERATED_POISON_MAX_COUNT
            end
        end,
        WP_SetNpcPoisonAnimation = function(data)
            local p = player()
            if p then
                npcPoisonAnimationByActor[p.id] = data and data.enabled ~= false
            end
        end,
        WP_SetNpcDebugLogging = function(data)
            npcDebugLoggingEnabled = data and data.enabled == true
        end,
        WP_SetPoisonHitVfxSettings = function(data)
            local oldVfxEnabled = poisonHitVfxEnabled
            local oldFullDuration = poisonVfxFullDuration
            poisonHitVfxEnabled = data == nil or data.vfxEnabled ~= false
            poisonHitSoundEnabled = data == nil or data.soundEnabled ~= false
            poisonVfxFullDuration = data == nil or data.fullDuration ~= false
            if (oldVfxEnabled and not poisonHitVfxEnabled)
                or (oldFullDuration and not poisonVfxFullDuration)
            then
                clearActivePoisonHitVfx()
            end
        end,
    },
    engineHandlers = {
        onSave = function()
            prunePoisonedWeapons(player())
            return {
                poisonedWeapons = poisonedWeapons,
                poisonedWeaponOwners = poisonedWeaponOwners,
                checkedNpcPoisonActors = checkedNpcPoisonActorsForSave(),
                npcPoisonInventoryActors = npcPoisonInventoryActors,
            }
        end,
        onLoad = function(data)
            poisonedWeapons = data and data.poisonedWeapons or {}
            poisonedWeaponOwners = data and data.poisonedWeaponOwners or {}
            checkedNpcPoisonActors = data and data.checkedNpcPoisonActors or {}
            npcPoisonInventoryActors = data and data.npcPoisonInventoryActors or {}
            pendingNpcPoisonApplications = {}
            npcPoisonCooldowns = {}
            npcNoUsablePoisonUntil = {}
            nextNpcPoisonScanTime = 0
            resetNpcAutoPoisonPool()
            prunePoisonedWeapons(player())
            syncState()
        end,
        onInit = function()
            pendingNpcPoisonApplications = {}
            npcPoisonCooldowns = {}
            npcNoUsablePoisonUntil = {}
            nextNpcPoisonScanTime = 0
            resetNpcAutoPoisonPool()
            prunePoisonedWeapons(player())
            syncState()
        end,
        onActorActive = function(actor)
            migrateNpcPoisonInventoryToCurrentPool(actor)
            tryGenerateNpcPoison(actor)
        end,
        onUpdate = scanNpcAutoPoison,
    },
}
