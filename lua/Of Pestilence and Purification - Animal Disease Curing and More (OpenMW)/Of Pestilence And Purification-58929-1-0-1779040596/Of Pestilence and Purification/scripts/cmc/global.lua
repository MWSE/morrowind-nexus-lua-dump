local core = require('openmw.core')
local types = require('openmw.types')
local world = require('openmw.world')
local async = require('openmw.async')
local I = require('openmw.interfaces')
local cfg = require('scripts.cmc.config')

local queuedByObjectId = {}
local lastNoticeAt = {}
local recentDamageApplications = {}

local DAMAGE_APPLICATION_COOLDOWN = 1.10

local activeSettings = {}
for k, v in pairs(cfg.settingsDefaults) do activeSettings[k] = v end

local state = {
    counters = {
        diseasedCreaturesCured = 0,
        blightedCreaturesCured = 0,
        diseasesSpread = 0,
        blightsSpread = 0,
    },
    speciesCures = {},
    friendlyFamilies = {},
    unlockedRewards = {},
    pathState = { committed = nil },
    blightMarkedActors = {},
    variantOrigins = {},
    creatureAfflictions = {},
    scriptlessCureOrigins = {},
    scriptlessCureRecords = {},
}

local notices = {
    curedCommon = 'The disease leaves this animal. It seems calmer.',
    curedBlight = 'The blight leaves this animal. It seems calmer.',
    spreadCommon = 'The animal sickens.',
    spreadBlight = 'Blight takes hold of this new host.',
    noDiseaseVariant = 'This species has no known diseased form.',
    noBlightVariant = 'This species has no known blighted form.',
    antiBlightNoEffect = 'The cleansing force finds no blight in this target.',
}

local actorName
local targetLabel

local function mergeSettings(newSettings)
    if not newSettings then return end
    for k, v in pairs(newSettings) do
        if activeSettings[k] ~= nil then activeSettings[k] = v end
    end
end

local function setting(key)
    if activeSettings[key] == nil then return cfg.settingsDefaults[key] end
    return activeSettings[key]
end

local function playerRecipient(actor)
    if actor and actor:isValid() and actor.type == types.Player then return actor end
    return world.players and world.players[1]
end

local function notify(actor, text, opts)
    opts = opts or {}
    if not text or text == '' then return end
    if not setting('showMessages') and not opts.force then return end
    local now = core.getSimulationTime()
    if lastNoticeAt[text] and now - lastNoticeAt[text] < 0.75 then return end
    lastNoticeAt[text] = now

    local recipient = playerRecipient(actor)
    if recipient and recipient:isValid() then
        recipient:sendEvent('cmcShowMessage', { message = text })
    end
end

local function debug(actor, text)
    if not setting('debugMessages') then return end
    local msg = '[Of Pestilence and Purification] ' .. tostring(text)
    print(msg)
end

local function audit(actor, text)
    local msg = '[Of Pestilence and Purification] ' .. tostring(text)
    print(msg)
    notify(actor, msg, { force = true })
end

local function actorDescriptor(actor)
    local parts = {}
    if actor and actor.recordId then parts[#parts + 1] = tostring(actor.recordId) end
    local ok, rec = pcall(function() return actor.type.record(actor) end)
    if ok and rec then
        if rec.name then parts[#parts + 1] = tostring(rec.name) end
        if rec.class then parts[#parts + 1] = tostring(rec.class) end
        if rec.faction then parts[#parts + 1] = tostring(rec.faction) end
    end
    return table.concat(parts, ' '):lower()
end

local function classifyVendor(npc)
    local text = actorDescriptor(npc)
    local profane = text:find('sixth house', 1, true)
        or text:find('dagoth', 1, true)
        or text:find('dreamer', 1, true)
        or text:find('ash slave', 1, true)
        or text:find('ash zombie', 1, true)
        or text:find('ash ghoul', 1, true)
        or text:find('necromancer', 1, true)
        or text:find('witch', 1, true)
        or text:find('warlock', 1, true)
        or text:find('sorcerer', 1, true)
        or text:find('telvanni', 1, true)
    if profane then return 'profane' end

    local healer = text:find('temple', 1, true)
        or text:find('imperial cult', 1, true)
        or text:find('healer', 1, true)
        or text:find('priest', 1, true)
        or text:find('restoration', 1, true)
    if healer then return 'healer' end

    return 'general'
end

local function npcHasSpell(npc, spellId)
    local ok, spells = pcall(function() return types.NPC.spells(npc) end)
    if not ok or not spells then return false end
    for _, spell in pairs(spells) do
        if cfg.lowerId(spell.id) == cfg.lowerId(spellId) then return true end
    end
    return false
end

local function addNpcSpell(npc, spellId)
    if not spellId then return false, 'missing spell id' end
    if npcHasSpell(npc, spellId) then return false, 'already has spell' end
    local ok, err = pcall(function() types.NPC.spells(npc):add(spellId) end)
    if ok then return true end
    return false, tostring(err)
end

local function tomeRecordExists(recordId)
    if not recordId then return false end
    local ok, record = pcall(function() return types.Book.records[cfg.lowerId(recordId)] end)
    return ok and record ~= nil
end

local function resolveTomeRecordId(tomeId)
    tomeId = cfg.lowerId(tomeId)
    if tomeRecordExists(tomeId) then return tomeId end
    return nil
end

local function ensureTomeRecord(tomeId)
    tomeId = cfg.lowerId(tomeId)
    if not tomeId then return false, 'missing tome id' end
    if resolveTomeRecordId(tomeId) then return true, tomeId end
    return false, tostring(tomeId) .. ' is not a loaded Book record; enable OfPestilenceAndPurification.omwaddon'
end

local function addNpcTome(npc, tomeId)
    if not tomeId then return false, 'missing tome id' end
    tomeId = cfg.lowerId(tomeId)
    local recordOk, recordIdOrErr = ensureTomeRecord(tomeId)
    if not recordOk then return false, recordIdOrErr end
    local recordId = recordIdOrErr

    local ok, resultOrErr = pcall(function()
        local inv = types.Actor.inventory(npc)
        if not inv then error('NPC has no inventory object') end
        if inv:find(recordId) then return false end
        world.createObject(recordId, 1):moveInto(inv)
        return true
    end)
    if ok then
        if resultOrErr then return true end
        return false, 'already has tome'
    end
    return false, tostring(resultOrErr)
end
local function spellEnabledForWorld(spellId)
    local tag = cfg.spellTags[cfg.lowerId(spellId)]
    if tag == 'antiBlight' then return setting('enableAntiBlightDamage') end
    if tag == 'areaSpread' then return setting('enableAreaSpreadRewards') end
    return true
end

local function tomeEnabledForWorld(tomeId)
    local def = cfg.tomeById[cfg.lowerId(tomeId)]
    if not def then return true end
    for _, spellId in ipairs(def.spells or {}) do
        if spellEnabledForWorld(spellId) then return true end
    end
    return false
end

local function addListToNpc(npc, list, mode, failures)
    local added = {}
    for _, id in ipairs(list or {}) do
        if mode == 'spell' then
            if spellEnabledForWorld(id) then
                local ok, err = addNpcSpell(npc, id)
                if ok then added[#added + 1] = id elseif err and err ~= 'already has spell' then failures[#failures + 1] = id .. ': ' .. err end
            end
        else
            if tomeEnabledForWorld(id) then
                local ok, err = addNpcTome(npc, id)
                if ok then added[#added + 1] = id elseif err and err ~= 'already has tome' then failures[#failures + 1] = id .. ': ' .. err end
            end
        end
    end
    return added
end

local function npcHasItem(npc, itemId)
    local wantedId = resolveTomeRecordId(itemId) or cfg.lowerId(itemId) or itemId
    local ok, result = pcall(function()
        local inv = types.Actor.inventory(npc)
        return inv and inv:find(wantedId) ~= nil
    end)
    return ok and result or false
end

local function enabledVendorList(category, source, mode)
    local out = {}
    local function addFrom(list)
        for _, id in ipairs(list or {}) do
            if mode == 'spell' then
                if spellEnabledForWorld(id) then out[#out + 1] = id end
            else
                if tomeEnabledForWorld(id) then out[#out + 1] = id end
            end
        end
    end
    addFrom(source.general)
    if category ~= 'general' then addFrom(source[category]) end
    return out
end

local function countPresent(npc, list, mode)
    local count = 0
    for _, id in ipairs(list or {}) do
        if mode == 'spell' then
            if npcHasSpell(npc, id) then count = count + 1 end
        else
            if npcHasItem(npc, id) then count = count + 1 end
        end
    end
    return count
end

local function serviceSummary(services)
    local out = {}
    if services.Spells then out[#out + 1] = 'Spells' end
    if services.Books then out[#out + 1] = 'Books' end
    if services.MagicItems then out[#out + 1] = 'MagicItems' end
    if #out == 0 then return 'none relevant' end
    return table.concat(out, ',')
end

local function integrateVendor(npc, opts)
    opts = opts or {}
    if not npc or not npc:isValid() or npc.type ~= types.NPC then return end
    local ok, rec = pcall(function() return npc.type.record(npc) end)
    if not ok or not rec or not rec.servicesOffered then return end
    local services = rec.servicesOffered
    local category = classifyVendor(npc)
    local actor = opts.actor
    local addedSpells, addedTomes, failures = {}, {}, {}

    if setting('integrateSpellMerchants') and services.Spells then
        for _, id in ipairs(addListToNpc(npc, cfg.vendorSpellLists.general, 'spell', failures)) do addedSpells[#addedSpells + 1] = id end
        if category ~= 'general' then
            for _, id in ipairs(addListToNpc(npc, cfg.vendorSpellLists[category], 'spell', failures)) do addedSpells[#addedSpells + 1] = id end
        end
    end

    if setting('integrateSpellTomes') and (services.Books or services.MagicItems or services.Spells) then
        for _, id in ipairs(addListToNpc(npc, cfg.vendorTomes.general, 'tome', failures)) do addedTomes[#addedTomes + 1] = id end
        if category ~= 'general' then
            for _, id in ipairs(addListToNpc(npc, cfg.vendorTomes[category], 'tome', failures)) do addedTomes[#addedTomes + 1] = id end
        end
    end

    if opts.forceLog or setting('debugMessages') then
        local label = tostring(npc.recordId or 'unknown npc')
        local expectedSpells = {}
        local expectedTomes = {}
        if setting('integrateSpellMerchants') and services.Spells then
            expectedSpells = enabledVendorList(category, cfg.vendorSpellLists, 'spell')
        end
        if setting('integrateSpellTomes') and (services.Books or services.MagicItems or services.Spells) then
            expectedTomes = enabledVendorList(category, cfg.vendorTomes, 'tome')
        end
        local presentSpells = countPresent(npc, expectedSpells, 'spell')
        local presentTomes = countPresent(npc, expectedTomes, 'tome')
        local summary = string.format(
            'Vendor audit for %s: category=%s services=%s spells=%d/%d tomes=%d/%d newlyAddedSpells=%d newlyAddedTomes=%d',
            label, category, serviceSummary(services), presentSpells, #expectedSpells, presentTomes, #expectedTomes, #addedSpells, #addedTomes
        )
        if #addedTomes > 0 then summary = summary .. ' addedTomes=[' .. table.concat(addedTomes, ', ') .. ']' end
        if #addedSpells > 0 then summary = summary .. ' addedSpells=[' .. table.concat(addedSpells, ', ') .. ']' end
        if #failures > 0 then summary = summary .. ' failures=[' .. table.concat(failures, '; ') .. ']' end
        if opts.forceLog then audit(actor, summary) else debug(actor, summary) end
    end
end

local function registerWorldIntegration()
    if I.Activation and I.Activation.addHandlerForType then
        I.Activation.addHandlerForType(types.NPC, function(npc, player)
            integrateVendor(npc)
        end)
    end
end

local function sendEnumeratioCounter(actor, counter)
    if not counter or counter == '' then return end
    local recipient = playerRecipient(actor)
    if recipient and recipient:isValid() then
        recipient:sendEvent('CMC_EnumeratioCounter', { counter = counter })
    end
end

local function sendPlayerEvent(actor, eventName, payload)
    local recipient = playerRecipient(actor)
    if recipient and recipient:isValid() then
        recipient:sendEvent(eventName, payload or {})
    end
end

local function chooseExistingVariant(candidates)
    if not candidates then return nil end
    for _, recordId in ipairs(candidates) do
        recordId = cfg.lowerId(recordId)
        if recordId and types.Creature.records[recordId] then return recordId end
    end
    return nil
end

local function variantForHealthy(healthyId, kind)
    healthyId = cfg.lowerId(healthyId)
    if not healthyId then return nil end
    if kind == 'common' then
        return chooseExistingVariant(cfg.healthyToCommon[healthyId]) or chooseExistingVariant(cfg.heuristicVariantCandidates(kind, healthyId))
    elseif kind == 'blight' then
        return chooseExistingVariant(cfg.healthyToBlight[healthyId]) or chooseExistingVariant(cfg.heuristicVariantCandidates(kind, healthyId))
    end
    return nil
end

local function healthyForVariant(variantId, kind)
    variantId = cfg.lowerId(variantId)
    if not variantId then return nil end
    local healthyId
    if kind == 'common' then
        healthyId = cfg.commonToHealthy[variantId]
    elseif kind == 'blight' then
        healthyId = cfg.blightToHealthy[variantId]
    end
    if healthyId and types.Creature.records[healthyId] then return healthyId end
    return chooseExistingVariant(cfg.heuristicHealthyCandidates(kind, variantId))
end

local SCRIPTLESS_CURE_PREFIX = 'cmc_cured_scriptless_'

local function scriptlessCloneId(recordId)
    recordId = cfg.lowerId(recordId)
    if not recordId then return nil end
    local safe = tostring(recordId):gsub('[^%w_%-]+', '_')
    return SCRIPTLESS_CURE_PREFIX .. safe
end

local function originalForScriptlessCureRecord(recordId)
    recordId = cfg.lowerId(recordId)
    if not recordId then return nil end
    local origins = state.scriptlessCureOrigins or {}
    return origins[recordId] or recordId
end

local function cureReplacementRecordFor(healthyId)
    healthyId = cfg.lowerId(healthyId)
    if not healthyId then return nil end

    local template = types.Creature.records[healthyId]
    if not template then return nil end

    local scriptId = cfg.lowerId(template.mwscript)
    if not scriptId or not (cfg.cureSpawnScriptIds and cfg.cureSpawnScriptIds[scriptId]) then
        return healthyId
    end

    state.scriptlessCureOrigins = state.scriptlessCureOrigins or {}
    state.scriptlessCureRecords = state.scriptlessCureRecords or {}

    local cachedId = cfg.lowerId(state.scriptlessCureRecords[healthyId])
    if cachedId and types.Creature.records[cachedId] then
        state.scriptlessCureOrigins[cachedId] = healthyId
        return cachedId
    end

    if not types.Creature.createRecordDraft or not world.createRecord then return healthyId end

    local ok, newRecord = pcall(function()
        local draft = types.Creature.createRecordDraft({
            id = scriptlessCloneId(healthyId),
            template = template,
            mwscript = '',
        })
        return world.createRecord(draft)
    end)

    if ok and newRecord and newRecord.id then
        local newId = cfg.lowerId(newRecord.id)
        if newId and types.Creature.records[newId] then
            state.scriptlessCureRecords[healthyId] = newId
            state.scriptlessCureOrigins[newId] = healthyId
            debug(nil, string.format('Created scriptless cure replacement %s from %s to avoid replaying %s.', newId, healthyId, scriptId))
            return newId
        end
    end

    debug(nil, string.format('Could not create scriptless cure replacement for %s; falling back to original record.', healthyId))
    return healthyId
end

local function rewardCounterValue(reward)
    if reward.path == cfg.rewardPaths.mercy then
        return (state.counters.diseasedCreaturesCured or 0) + (state.counters.blightedCreaturesCured or 0)
    elseif reward.path == cfg.rewardPaths.disease then
        return state.counters.diseasesSpread or 0
    elseif reward.path == cfg.rewardPaths.blight then
        return state.counters.blightsSpread or 0
    end
    return 0
end

local function mercyCount()
    return (state.counters.diseasedCreaturesCured or 0) + (state.counters.blightedCreaturesCured or 0)
end

local function contagionCount()
    return (state.counters.diseasesSpread or 0) + (state.counters.blightsSpread or 0)
end

local function rewardMatchesCommitment(reward, commitment)
    if not commitment then return true end
    if commitment == 'mercy' then
        return reward.path == cfg.rewardPaths.mercy
    elseif commitment == 'contagion' then
        return reward.path == cfg.rewardPaths.disease or reward.path == cfg.rewardPaths.blight
    end
    return true
end

local function rewardMatchesGroup(reward, group)
    return rewardMatchesCommitment(reward, group)
end

local function syncPlayer(actor)
    sendPlayerEvent(actor, 'cmcSyncRewards', {
        unlockedRewards = state.unlockedRewards,
        settings = activeSettings,
    })
end

local function revokeRewardsByGroup(group)
    local revoked = {}
    for _, reward in ipairs(cfg.rewardDefs) do
        if state.unlockedRewards[reward.id] and rewardMatchesGroup(reward, group) then
            state.unlockedRewards[reward.id] = nil
            revoked[#revoked + 1] = reward
        end
    end
    return revoked
end

local function handlePathCommitment(actor, newCommitment)
    if not setting('enablePathConflict') then return end
    state.pathState = state.pathState or { committed = nil }
    local oldCommitment = state.pathState.committed
    if oldCommitment == newCommitment then return end

    local switched = oldCommitment ~= nil and oldCommitment ~= newCommitment
    state.pathState.committed = newCommitment

    if switched then
        local revoked = revokeRewardsByGroup(oldCommitment)
        if #revoked > 0 then
            syncPlayer(actor)
        end
        if newCommitment == 'mercy' then
            notify(actor, 'Your acts of mercy break faith with the ordered nature of pestilence and disease. The blessings of contagion fade from you.', { force = true })
            if setting('enableDreamMessages') then
                sendPlayerEvent(actor, 'cmcQueueDream', {
                    rewardId = 'path_conflict_mercy',
                    message = 'You dream of healthy animals no longer afflicted by disease. An immense presence turns its attention on you in disgust, as you awake in a cold sweat.',
                })
            end
        else
            notify(actor, 'You embrace the purity of contagion. Incompatible mercy rewards are cast aside.', { force = true })
            if setting('enableDreamMessages') then
                sendPlayerEvent(actor, 'cmcQueueDream', {
                    rewardId = 'path_conflict_contagion',
                    message = 'You dream of a great green dragon spreading its wings wider over the creatures of this land. Disease is only part of the natural order of things after all...',
                })
            end
        end
    end
end

local function updatePathCommitmentFromCounter(actor, key)
    if not setting('enablePathConflict') then return end
    local _, threshold = cfg.sanitizeRewardThresholds(activeSettings)
    if key == 'diseasedCreaturesCured' or key == 'blightedCreaturesCured' then
        if mercyCount() >= threshold then
            handlePathCommitment(actor, 'mercy')
        end
    elseif key == 'diseasesSpread' or key == 'blightsSpread' then
        if contagionCount() >= threshold then
            handlePathCommitment(actor, 'contagion')
        end
    end
end

local function checkRewards(actor)
    if not setting('enableRewardUnlocks') then return end
    local commitment = setting('enablePathConflict') and state.pathState and state.pathState.committed or nil
    for _, reward in ipairs(cfg.rewardDefs) do
        if rewardMatchesCommitment(reward, commitment) then
            if not state.unlockedRewards[reward.id] and rewardCounterValue(reward) >= cfg.rewardThreshold(reward, activeSettings) then
                state.unlockedRewards[reward.id] = true
                sendPlayerEvent(actor, 'cmcRewardUnlocked', { rewardId = reward.id, reward = reward, settings = activeSettings })
                notify(actor, reward.message, { force = true })
                if setting('enableDreamMessages') and reward.dream then
                    sendPlayerEvent(actor, 'cmcQueueDream', { rewardId = reward.id, message = reward.dream })
                end
            end
        end
    end
end

local sendStatus

local function incrementCounter(actor, key)
    if not key then return end
    state.counters[key] = (state.counters[key] or 0) + 1
    sendEnumeratioCounter(actor, key)
    updatePathCommitmentFromCounter(actor, key)
    checkRewards(actor)
end


local function resolveAdminCounterKey(value)
    value = tostring(value or ''):lower():gsub('[%s_-]+', '')
    local aliases = {
        diseasedcreaturescured = 'diseasedCreaturesCured',
        diseasedcured = 'diseasedCreaturesCured',
        commoncured = 'diseasedCreaturesCured',
        commoncures = 'diseasedCreaturesCured',
        diseasecures = 'diseasedCreaturesCured',
        diseasecured = 'diseasedCreaturesCured',
        cures = 'diseasedCreaturesCured',
        cure = 'diseasedCreaturesCured',
        mercy = 'diseasedCreaturesCured',

        blightedcreaturescured = 'blightedCreaturesCured',
        blightedcured = 'blightedCreaturesCured',
        blightcured = 'blightedCreaturesCured',
        blightcures = 'blightedCreaturesCured',

        diseasesspread = 'diseasesSpread',
        diseasespread = 'diseasesSpread',
        commonspread = 'diseasesSpread',
        commonspreads = 'diseasesSpread',
        diseases = 'diseasesSpread',
        disease = 'diseasesSpread',
        peryite = 'diseasesSpread',

        blightsspread = 'blightsSpread',
        blightspread = 'blightsSpread',
        blightspreads = 'blightsSpread',
        blights = 'blightsSpread',
        blight = 'blightsSpread',
        ash = 'blightsSpread',
    }
    return aliases[value]
end

local function adminCounterPathName(key)
    if key == 'diseasedCreaturesCured' or key == 'blightedCreaturesCured' then return 'mercy' end
    if key == 'diseasesSpread' then return 'disease' end
    if key == 'blightsSpread' then return 'blight' end
    return 'unknown'
end

local function adminSendEnumeratioDelta(actor, key, oldValue, newValue)
    local delta = math.max(0, (newValue or 0) - (oldValue or 0))
    for _ = 1, delta do sendEnumeratioCounter(actor, key) end
end

local function adminRaiseCounter(actor, key, targetValue)
    if not key then return nil, 'Unknown counter.' end
    targetValue = math.floor(tonumber(targetValue or 0) or 0)
    targetValue = math.max(0, math.min(9999, targetValue))
    state.counters = state.counters or {}
    local oldValue = state.counters[key] or 0
    local newValue = math.max(oldValue, targetValue)
    state.counters[key] = newValue
    adminSendEnumeratioDelta(actor, key, oldValue, newValue)
    updatePathCommitmentFromCounter(actor, key)
    checkRewards(actor)
    syncPlayer(actor)
    return newValue, nil
end

local function handleAdminCounter(data)
    local actor = data and data.player
    local action = tostring(data and data.action or ''):lower()
    local key = resolveAdminCounterKey(data and data.counter)
    local value = tonumber(data and data.value)

    if action == 'add' then
        if not key then
            notify(actor, 'OPP admin: unknown counter. Use mercy, disease, blight, commonCures, or blightCures.', { force = true })
            return
        end
        local current = state.counters[key] or 0
        local added = math.max(0, math.floor(value or 0))
        local newValue, err = adminRaiseCounter(actor, key, current + added)
        if err then notify(actor, 'OPP admin: ' .. err, { force = true }); return end
        notify(actor, string.format('OPP admin: %s raised by %d to %d.', key, added, newValue or 0), { force = true })
        return
    end

    if action == 'set' then
        if not key then
            notify(actor, 'OPP admin: unknown counter. Use mercy, disease, blight, commonCures, or blightCures.', { force = true })
            return
        end
        local newValue, err = adminRaiseCounter(actor, key, value or 0)
        if err then notify(actor, 'OPP admin: ' .. err, { force = true }); return end
        notify(actor, string.format('OPP admin: %s is now at least %d.', key, newValue or 0), { force = true })
        return
    end

    if action == 'tier' then
        local path = tostring(data and data.counter or ''):lower()
        local t1, t2, t3 = cfg.sanitizeRewardThresholds(activeSettings)
        local tier = math.max(1, math.min(3, math.floor(value or 1)))
        local target = ({ t1, t2, t3 })[tier]
        if path == 'all' then
            local keys = { 'diseasedCreaturesCured', 'diseasesSpread', 'blightsSpread' }
            for _, k in ipairs(keys) do adminRaiseCounter(actor, k, target) end
            notify(actor, string.format('OPP admin: mercy, disease, and blight counters raised to tier %d threshold (%d).', tier, target), { force = true })
            return
        end
        key = resolveAdminCounterKey(path)
        if not key then
            notify(actor, 'OPP admin: unknown path. Use mercy, disease, blight, or all.', { force = true })
            return
        end
        local newValue = adminRaiseCounter(actor, key, target)
        notify(actor, string.format('OPP admin: %s path raised to tier %d threshold (%d).', adminCounterPathName(key), tier, newValue or target), { force = true })
        return
    end

    notify(actor, 'OPP admin: unknown action. Use lua oppadd <counter> <n>, lua oppset <counter> <n>, or lua opptier <path> <1-3>.', { force = true })
end

local function noteSpeciesCure(actor, healthyId)
    if not setting('enableSpeciesFriendship') then return end
    local family = cfg.familyOf(healthyId)
    if not family or family == '' then return end
    state.speciesCures[family] = (state.speciesCures[family] or 0) + 1

    if not state.friendlyFamilies[family] and state.speciesCures[family] >= cfg.thresholds.speciesFriendship then
        state.friendlyFamilies[family] = true
        notify(actor, string.format('%s now trust you. Healthy members of this species will see in you a friend.', cfg.displayFamily(family)), { force = true })
    end
end


local function animalAlliesEnabled()
    return setting('enableAnimalAllies')
end

local function hasReward(rewardId)
    return state.unlockedRewards and state.unlockedRewards[rewardId] == true
end

local function rollPercent(chance)
    chance = tonumber(chance or 0) or 0
    if chance <= 0 then return false end
    return math.random(1, 100) <= chance
end

local function makeCreatureAlly(creature, actor, message)
    if not animalAlliesEnabled() then return false end
    if not creature or not creature:isValid() or creature.type ~= types.Creature then return false end
    creature:sendEvent('cmcMakeAlly', { owner = playerRecipient(actor) })
    if message then notify(actor, message, { force = true }) end
    return true
end

local function allyEligibleForSpread(kind)
    if kind == 'common' then return hasReward('disease_1') end
    if kind == 'blight' then return hasReward('blight_1') end
    return false
end

local function maybeAllyAfterSpread(creature, actor, kind)
    if not allyEligibleForSpread(kind) then return false end
    local chance = kind == 'blight' and cfg.thresholds.blightAllyChance or cfg.thresholds.contagionAllyChance
    if rollPercent(chance) then
        makeCreatureAlly(creature, actor, 'The empowered animal accepts you as its ally.')
        return true
    end
    return false
end

local resistLabels = {
    resistcommondisease = 'Resist Common Disease',
    resistblightdisease = 'Resist Blight Disease',
    resistmagicka = 'Resist Magicka',
}

local resistEffectKeys = {
    common = {
        label = 'Resist Common Disease',
        constants = { 'ResistCommonDisease', 'ResistDisease' },
        statKeys = { 'resistcommondisease', 'resistCommonDisease', 'ResistCommonDisease', 'resistdisease', 'resistDisease', 'ResistDisease' },
    },
    blight = {
        label = 'Resist Blight Disease',
        constants = { 'ResistBlightDisease' },
        statKeys = { 'resistblightdisease', 'resistBlightDisease', 'ResistBlightDisease' },
    },
    magicka = {
        label = 'Resist Magicka',
        constants = { 'ResistMagicka' },
        statKeys = { 'resistmagicka', 'resistMagicka', 'ResistMagicka' },
    },
}

local function numericStatValue(v)
    if tonumber(v) then return tonumber(v) end
    if type(v) ~= 'table' then return nil end
    return tonumber(v.current or v.modified or v.value or v.base or v.magnitude)
end

local function effectTypeConstant(names)
    if not core.magic or not core.magic.EFFECT_TYPE then return nil end
    for _, name in ipairs(names or {}) do
        local id = core.magic.EFFECT_TYPE[name]
        if id ~= nil then return id end
    end
    return nil
end

local function readMagicEffectPercent(actor, def)
    if not actor or not def then return nil end

    local effectType = effectTypeConstant(def.constants)
    if effectType ~= nil then
        local ok, value = pcall(function()
            local stat = types.Actor.stats.magicEffects and types.Actor.stats.magicEffects[effectType]
            if stat then return numericStatValue(stat(actor)) end
        end)
        if ok and tonumber(value) and tonumber(value) ~= 0 then return tonumber(value) end

        ok, value = pcall(function()
            local effects = types.Actor.activeEffects and types.Actor.activeEffects(actor)
            local effect = effects and effects.getEffect and effects:getEffect(effectType)
            return numericStatValue(effect)
        end)
        if ok and tonumber(value) and tonumber(value) ~= 0 then return tonumber(value) end
    end

    for _, key in ipairs(def.statKeys or {}) do
        local ok, value = pcall(function()
            local stat = types.Actor.stats.magicEffects and types.Actor.stats.magicEffects[key]
            if stat then return numericStatValue(stat(actor)) end
        end)
        if ok and tonumber(value) and tonumber(value) ~= 0 then return tonumber(value) end
    end

    return nil
end

local function npcRecord(actor)
    if not actor or actor.type ~= types.NPC then return nil end
    local ok, rec = pcall(function() return types.NPC.record(actor) end)
    if ok and rec then return rec end
    ok, rec = pcall(function() return actor.type.record(actor) end)
    if ok and rec then return rec end
    local rid = cfg.lowerId(actor.recordId)
    if rid and types.NPC.records then
        return types.NPC.records[rid] or types.NPC.records[actor.recordId]
    end
    return nil
end

local function raceDiseaseResistance(actor, kind)
    if kind ~= 'common' or not actor or actor.type ~= types.NPC then return nil end
    local rec = npcRecord(actor)
    local raceId = rec and (rec.race or rec.raceId or rec.raceID) or nil
    raceId = cfg.lowerId(raceId or '')

    -- Vanilla disease-resistant races. OpenMW does not always expose racial
    -- abilities through stats.magicEffects for NPCs, so preserve these as a
    -- fallback after explicit magic effect checks.
    if raceId == 'argonian' or raceId == 'wood elf' or raceId == 'woodelf' or raceId == 'bosmer' then
        return 75, 'racial Resist Common Disease'
    end
    return nil
end

local function readResistPercent(actor, kind)
    local primaryDef = kind == 'blight' and resistEffectKeys.blight or resistEffectKeys.common
    local primaryValue = readMagicEffectPercent(actor, primaryDef)
    if tonumber(primaryValue) and tonumber(primaryValue) ~= 0 then
        return math.max(0, math.min(100, tonumber(primaryValue))), primaryDef.label
    end

    local racial, racialLabel = raceDiseaseResistance(actor, kind)
    if racial then return math.max(0, math.min(100, racial)), racialLabel end

    local magickaValue = readMagicEffectPercent(actor, resistEffectKeys.magicka)
    if tonumber(magickaValue) and tonumber(magickaValue) ~= 0 then
        return math.max(0, math.min(100, tonumber(magickaValue))), resistEffectKeys.magicka.label
    end

    return 0, 'no resistance'
end

targetLabel = function(target)
    if not target then return 'unknown target' end
    local name = nil
    local ok, rec = pcall(function() return target.type.record(target) end)
    if ok and rec and rec.name and rec.name ~= '' then name = rec.name end
    if name and target.recordId then return string.format('%s [%s]', name, tostring(target.recordId)) end
    return tostring(target.recordId or 'unknown target')
end

local function damageKindLabel(kind)
    if kind == 'blight' then return 'Blight Damage' end
    if kind == 'common' then return 'Disease Damage' end
    if kind == 'antiBlight' then return 'Scourge Blight' end
    return tostring(kind or 'Damage')
end

local function damageDebug(actor, text)
    if not setting('debugDamageMessages') then return end
    notify(actor, '[OPP damage test] ' .. tostring(text), { force = true })
end

local function queueTransform(oldCreature, newRecordId, makeFriendly, message, actor, statCounter, onSuccess, originRecordId)
    if not oldCreature or not oldCreature:isValid() then return end
    if not newRecordId or not types.Creature.records[newRecordId] then return end
    if types.Actor.isDead(oldCreature) then return end

    local queueKey = oldCreature.id .. '>' .. newRecordId
    if queuedByObjectId[queueKey] then return end
    queuedByObjectId[queueKey] = true

    local callback = async:registerTimerCallback('cmc_transform_' .. oldCreature.id .. '_' .. tostring(math.random(1, 1000000)), function()
        queuedByObjectId[queueKey] = nil
        if not oldCreature or not oldCreature:isValid() then return end
        if types.Actor.isDead(oldCreature) then return end

        local cell = oldCreature.cell
        if not cell then return end

        local pos = oldCreature.position
        local rot = oldCreature.rotation
        local scale = oldCreature.scale

        local okRemove = pcall(function() oldCreature:remove() end)
        if not okRemove then return end

        local okCreate, newCreature = pcall(function()
            return world.createObject(newRecordId, 1)
        end)
        if not okCreate or not newCreature then return end

        newCreature:teleport(cell, pos, { rotation = rot })
        pcall(function() newCreature:setScale(scale) end)

        if originRecordId then
            state.variantOrigins = state.variantOrigins or {}
            state.variantOrigins[tostring(newCreature.id)] = cfg.lowerId(originRecordId)
        end

        if makeFriendly then
            local calmCallback = async:registerTimerCallback('cmc_calm_' .. newCreature.id .. '_' .. tostring(math.random(1, 1000000)), function()
                if newCreature and newCreature:isValid() then
                    if makeFriendly == 'ally' then
                        newCreature:sendEvent('cmcMakeAlly', { owner = playerRecipient(actor) })
                    else
                        newCreature:sendEvent('cmcMakeFriendly')
                    end
                end
            end)
            async:newSimulationTimer(0.10, calmCallback)
        end

        notify(actor, message)
        incrementCounter(actor, statCounter)
        if onSuccess then onSuccess(newCreature) end
    end)

    -- Let OpenMW finish the native spell/effect application before replacing the actor.
    async:newSimulationTimer(0.05, callback)
end

local function targetCreature(data)
    if not data or not data.target or not data.target:isValid() then return nil end
    if data.target.type ~= types.Creature then return nil end
    if types.Actor.isDead(data.target) then return nil end
    return data.target
end

local function targetActor(data)
    if not data or not data.target or not data.target:isValid() then return nil end
    local t = data.target
    if t.type ~= types.Creature and t.type ~= types.NPC then return nil end
    if types.Actor.isDead(t) then return nil end
    return t
end

local function creatureMarkerKey(creature)
    if not creature then return nil end
    return tostring(creature.id or creature.recordId or creature)
end

local function scriptedAfflictionEntry(creature)
    local key = creatureMarkerKey(creature)
    if not key or not state.creatureAfflictions then return nil, key end
    return state.creatureAfflictions[key], key
end

local function isScriptedCreatureAfflicted(creature, kind)
    local entry = scriptedAfflictionEntry(creature)
    if not entry then return false end
    return kind == nil or entry.kind == kind
end

local function clearScriptedCreatureAffliction(creature, kind)
    local entry, key = scriptedAfflictionEntry(creature)
    if not entry or not key then return nil end
    if kind and entry.kind ~= kind then return nil end
    state.creatureAfflictions[key] = nil
    return entry
end

local function creatureHasMatchingAffliction(creature, kind)
    if not creature or creature.type ~= types.Creature then return false end
    if isScriptedCreatureAfflicted(creature, kind) then return true end

    local rid = cfg.lowerId(creature.recordId)
    local name = cfg.lowerId(actorName(creature) or '')
    if not rid then return false end

    if kind == 'common' then
        if cfg.commonToHealthy[rid] then return true end
        if healthyForVariant(rid, 'common') then return true end
        if rid:find('diseased', 1, true) or name:find('diseased', 1, true) then return true end
        if rid:sub(-3) == '_ds' then return true end
        return false
    end

    if kind == 'blight' then
        if cfg.blightToHealthy[rid] then return true end
        if healthyForVariant(rid, 'blight') then return true end
        if rid:find('blighted', 1, true) or name:find('blighted', 1, true) then return true end
        if rid:sub(-7) == '_blight' or rid:sub(-7) == ' blight' then return true end
        return false
    end

    return false
end

local function markScriptedCreatureAffliction(actor, target, kind, spellId)
    if not target or not target:isValid() or target.type ~= types.Creature then return false end
    if types.Actor.isDead(target) then return false end
    if isScriptedCreatureAfflicted(target) then return false end

    state.creatureAfflictions = state.creatureAfflictions or {}
    local key = creatureMarkerKey(target)
    if not key then return false end

    state.creatureAfflictions[key] = {
        kind = kind,
        recordId = cfg.lowerId(target.recordId),
        name = actorName(target),
        spellId = cfg.lowerId(spellId),
        time = core.getSimulationTime(),
    }

    if kind == 'blight' then
        incrementCounter(actor, 'blightsSpread')
        notify(actor, notices.spreadBlight)
    else
        incrementCounter(actor, 'diseasesSpread')
        notify(actor, notices.spreadCommon)
    end
    return true
end

local function cureScriptedCreatureAffliction(target, actor, kind)
    local entry = clearScriptedCreatureAffliction(target, kind)
    if not entry then return false end

    local statCounter = kind == 'blight' and 'blightedCreaturesCured' or 'diseasedCreaturesCured'
    local notice = kind == 'blight' and notices.curedBlight or notices.curedCommon
    incrementCounter(actor, statCounter)
    noteSpeciesCure(actor, entry.recordId or target.recordId)

    if rollPercent(cfg.thresholds.cureAllyChance) then
        makeCreatureAlly(target, actor, 'The animal bonds with you and will fight at your side.')
    else
        target:sendEvent('cmcMakeFriendly')
    end
    notify(actor, notice)
    return true
end

local function handleCure(data)
    local target = targetCreature(data)
    if not target then return end
    local targetId = originalForScriptlessCureRecord(cfg.lowerId(target.recordId))
    local kind = data.kind

    -- A cure should only have scripted side effects if the target is actually
    -- carrying the matching affliction: a known diseased/blighted record, a
    -- heuristic diseased/blighted record, or one of OPP's no-record fallback marks.
    -- This prevents healthy base creatures from rolling into allies when hit by
    -- Purify Beast or a native cure carrier.
    if not creatureHasMatchingAffliction(target, kind) then return end

    if cureScriptedCreatureAffliction(target, data.actor, kind) then return end

    local originId = state.variantOrigins and state.variantOrigins[tostring(target.id)] or nil
    originId = originalForScriptlessCureRecord(originId)

    if kind == 'common' then
        local healthyId = (originId and types.Creature.records[originId] and originId) or healthyForVariant(targetId, 'common')
        if healthyId and types.Creature.records[healthyId] then
            local replacementId = cureReplacementRecordFor(healthyId)
            local allyFlag = rollPercent(cfg.thresholds.cureAllyChance) and 'ally' or true
            if state.variantOrigins then state.variantOrigins[tostring(target.id)] = nil end
            queueTransform(target, replacementId, allyFlag, notices.curedCommon, data.actor, 'diseasedCreaturesCured', function(newCreature)
                noteSpeciesCure(data.actor, healthyId)
                if allyFlag == 'ally' then notify(data.actor, 'The animal bonds with you and will fight at your side.', { force = true }) end
            end)
        end
    elseif kind == 'blight' then
        local healthyId = (originId and types.Creature.records[originId] and originId) or healthyForVariant(targetId, 'blight')
        if healthyId and types.Creature.records[healthyId] then
            local replacementId = cureReplacementRecordFor(healthyId)
            local allyFlag = rollPercent(cfg.thresholds.cureAllyChance) and 'ally' or true
            if state.variantOrigins then state.variantOrigins[tostring(target.id)] = nil end
            queueTransform(target, replacementId, allyFlag, notices.curedBlight, data.actor, 'blightedCreaturesCured', function(newCreature)
                noteSpeciesCure(data.actor, healthyId)
                if allyFlag == 'ally' then notify(data.actor, 'The animal bonds with you and will fight at your side.', { force = true }) end
            end)
        end
    end
end

local function actorMarkerKey(actor)
    if not actor then return nil end
    return tostring(actor.id or actor.recordId or actor)
end

local function isNpcBlightMarked(actor)
    local key = actorMarkerKey(actor)
    return key ~= nil and state.blightMarkedActors and state.blightMarkedActors[key] ~= nil
end

local function clearNpcBlightMark(target)
    local key = actorMarkerKey(target)
    if not key or not state.blightMarkedActors then return false end
    if state.blightMarkedActors[key] then
        state.blightMarkedActors[key] = nil
        return true
    end
    return false
end

local function markNpcWithBlight(actor, target, spellId)
    if not target or not target:isValid() or target.type ~= types.NPC then return false end
    if types.Actor.isDead(target) then return false end
    state.blightMarkedActors = state.blightMarkedActors or {}
    local key = actorMarkerKey(target)
    if not key then return false end
    if state.blightMarkedActors[key] then return false end

    state.blightMarkedActors[key] = {
        recordId = target.recordId,
        name = actorName(target),
        spellId = cfg.lowerId(spellId),
        time = core.getSimulationTime(),
    }
    incrementCounter(actor, 'blightsSpread')
    notify(actor, 'Blight takes hold of ' .. tostring(actorName(target) or target.recordId or 'the target') .. '.', { force = true })
    damageDebug(actor, string.format('Blight mark applied to %s. Scourge Blight can now affect this NPC.', targetLabel(target)))
    return true
end

local function handleSpread(data)
    local target = targetActor(data)
    if not target then return end
    if cfg.spellTags[cfg.lowerId(data.spellId)] == 'areaSpread' and not setting('enableAreaSpreadRewards') then return end
    local kind = data.kind

    -- NPCs do not have animal variant records to swap. A blight-spread hit
    -- instead applies an OPP blight mark that makes the NPC vulnerable to
    -- Scourge Blight until death or explicit debug clearing. The mark is
    -- applied once and counts once as blight-spread progress. Common disease
    -- spread remains animal-only.
    if target.type == types.NPC then
        if kind == 'blight' then markNpcWithBlight(data.actor, target, data.spellId) end
        return
    end

    if target.type ~= types.Creature then return end
    local targetId = originalForScriptlessCureRecord(cfg.lowerId(target.recordId))

    if cfg.isInfectedRecord(targetId) or isScriptedCreatureAfflicted(target) then return end

    if kind == 'common' then
        local variant = variantForHealthy(targetId, 'common')
        if variant then
            local allyFlag = allyEligibleForSpread('common') and rollPercent(cfg.thresholds.contagionAllyChance) and 'ally' or false
            queueTransform(target, variant, allyFlag, notices.spreadCommon, data.actor, 'diseasesSpread', function(newCreature)
                if allyFlag == 'ally' then notify(data.actor, 'The empowered animal accepts you as its ally.', { force = true }) end
            end, targetId)
        else
            if markScriptedCreatureAffliction(data.actor, target, 'common', data.spellId) then
                maybeAllyAfterSpread(target, data.actor, 'common')
            else
                notify(data.actor, notices.noDiseaseVariant)
            end
        end
    elseif kind == 'blight' then
        local variant = variantForHealthy(targetId, 'blight')
        if variant then
            local allyFlag = allyEligibleForSpread('blight') and rollPercent(cfg.thresholds.blightAllyChance) and 'ally' or false
            queueTransform(target, variant, allyFlag, notices.spreadBlight, data.actor, 'blightsSpread', function(newCreature)
                if allyFlag == 'ally' then notify(data.actor, 'The empowered animal accepts you as its ally.', { force = true }) end
            end, targetId)
        else
            if markScriptedCreatureAffliction(data.actor, target, 'blight', data.spellId) then
                maybeAllyAfterSpread(target, data.actor, 'blight')
            else
                notify(data.actor, notices.noBlightVariant)
            end
        end
    end
end

actorName = function(actor)
    if actor and actor.type and actor.type.record then
        local ok, rec = pcall(function() return actor.type.record(actor) end)
        if ok and rec and rec.name then return rec.name end
    end
    return actor and actor.recordId or ''
end

local function isBlightVulnerable(creature)
    local rid = cfg.lowerId(creature.recordId)
    local name = actorName(creature)
    if cfg.isExcludedDagothOrAshVampire(rid, name) then return false end
    if isNpcBlightMarked(creature) then return true end
    if isScriptedCreatureAfflicted(creature, 'blight') then return true end
    if cfg.blightToHealthy[rid] then return true end
    if healthyForVariant(rid, 'blight') then return true end
    if tostring(rid or ''):find('blighted', 1, true) then return true end
    return cfg.isSixthHouseLike(rid, name)
end


local function configuredDamageAmount(tableRef, spellId)
    if not tableRef or not spellId then return nil end
    return tableRef[cfg.lowerId(spellId)]
end


local function actorObjectId(obj)
    if not obj then return 'none' end
    return tostring(obj.id or obj.recordId or obj)
end

local function damageApplicationKey(target, spellId, kind)
    return table.concat({
        actorObjectId(target),
        cfg.lowerId(spellId or ''),
        tostring(kind or ''),
    }, '|')
end

local function shouldApplyDamageNow(target, actor, spellId, kind)
    -- Do not include caster in the key. On some OpenMW paths the same cast is
    -- seen once with a caster and once without, which caused duplicate damage.
    local key = damageApplicationKey(target, spellId, kind)
    local now = core.getSimulationTime()
    local previous = recentDamageApplications[key]
    if previous and now - previous < DAMAGE_APPLICATION_COOLDOWN then
        return false, now - previous
    end
    recentDamageApplications[key] = now

    -- Cheap opportunistic cleanup so the table does not grow forever in long sessions.
    for k, t in pairs(recentDamageApplications) do
        if now - t > 8.0 then recentDamageApplications[k] = nil end
    end
    return true, nil
end

local function applyActorDamage(target, amount, actor, label)
    amount = math.floor(tonumber(amount or 0) or 0)
    if amount <= 0 or not target or not target:isValid() then return false end

    -- Apply damage in the target actor's local Lua context. This follows the
    -- pattern used by recent OpenMW spell packs: global scripts resolve world
    -- logic, while actor scripts mutate actor stats. NPCs in particular may log
    -- a global health write without visibly losing health.
    if target.type == types.NPC then
        pcall(function()
            target:sendEvent('cmcTakeActorDamage', {
                amount = amount,
                actor = actor,
                label = label,
                report = setting('debugDamageMessages'),
            })
        end)
        return true
    end

    local ok = pcall(function()
        local health = types.Actor.stats.dynamic.health(target)
        health.current = math.max(0, health.current - amount)
    end)
    if ok then return true end

    -- Fallback for actors whose health stat is not writable here.
    pcall(function()
        target:sendEvent('cmcTakeBlightDamage', { amount = amount, actor = actor, label = label, report = setting('debugDamageMessages') })
    end)
    return false
end

local function handleAntiBlightDamage(data)
    if not setting('enableAntiBlightDamage') then return end
    local target = targetActor(data)
    if not target then return end
    local baseAmount = tonumber(data.magnitude or data.damage or 0) or 0
    if baseAmount <= 0 then baseAmount = configuredDamageAmount(cfg.antiBlightDamage, data.spellId) or 25 end
    if not isBlightVulnerable(target) then
        notify(data.actor, notices.antiBlightNoEffect)
        damageDebug(data.actor, string.format('%s vs %s: base %d, target not blight-vulnerable, final 0.', damageKindLabel('antiBlight'), targetLabel(target), baseAmount))
        return
    end
    local amount = baseAmount
    local okToApply = shouldApplyDamageNow(target, data.actor, data.spellId, 'antiBlight')
    if not okToApply then return end
    applyActorDamage(target, amount, data.actor, damageKindLabel('antiBlight'))
    debug(data.actor, 'Applied ' .. tostring(amount) .. ' anti-blight damage to ' .. tostring(target.recordId))
    damageDebug(data.actor, string.format('%s vs %s: base %d, final %d.', damageKindLabel('antiBlight'), targetLabel(target), baseAmount, amount))
end

local function handleResistScaledDamage(data)
    local target = targetActor(data)
    if not target then return end
    local baseAmount = tonumber(data.magnitude or data.damage or 0) or 0
    if baseAmount <= 0 then baseAmount = configuredDamageAmount(cfg.resistScaledDamage, data.spellId) or (data.kind == 'blight' and 70 or 35) end

    -- Disease-aligned direct damage should not punish animals already carrying
    -- that same affliction. A diseased animal ignores Disease Damage; a
    -- blighted animal ignores Blight Damage. NPCs and uninfected creatures keep
    -- using the normal resistance-scaled damage path.
    if creatureHasMatchingAffliction(target, data.kind) then
        debug(data.actor, string.format('Suppressed %s against already-afflicted animal %s', damageKindLabel(data.kind), tostring(target.recordId)))
        damageDebug(data.actor, string.format('%s vs %s: target already carries matching affliction, final 0.', damageKindLabel(data.kind), targetLabel(target)))
        return
    end

    local resist, resistLabel = readResistPercent(target, data.kind)
    local amount = math.max(1, math.floor(baseAmount * (100 - resist) / 100 + 0.5))
    local resisted = math.max(0, baseAmount - amount)
    local okToApply = shouldApplyDamageNow(target, data.actor, data.spellId, data.kind)
    if not okToApply then return end
    applyActorDamage(target, amount, data.actor, damageKindLabel(data.kind))
    debug(data.actor, string.format('Applied %d resist-scaled %s damage to %s at %d%% resistance', amount, tostring(data.kind), tostring(target.recordId), resist))
    damageDebug(data.actor, string.format('%s vs %s: base %d, %s %d%%, resisted %d, final %d.', damageKindLabel(data.kind), targetLabel(target), baseAmount, tostring(resistLabel or 'Resistance'), resist, resisted, amount))
end

local function giveAllTomes(data)
    local player = data and data.player
    if not player or not player:isValid() then player = world.players and world.players[1] end
    if not player or not player:isValid() then return end
    local failures = {}
    pcall(function()
        local inv = types.Actor.inventory(player)
        for _, tomeId in ipairs(cfg.tomeOrder or {}) do
            tomeId = cfg.lowerId(tomeId)
            local recordOk, recordIdOrErr = ensureTomeRecord(tomeId)
            if recordOk then
                local recordId = recordIdOrErr
                if not inv:find(recordId) then
                    world.createObject(recordId, 1):moveInto(inv)
                end
            else
                failures[#failures + 1] = tostring(tomeId) .. ': ' .. tostring(recordIdOrErr)
            end
        end
    end)
    if #failures > 0 then
        audit(player, 'Could not create some spell tome records: ' .. table.concat(failures, '; '))
    end
end


local function sortedUnlockedRewardTitles()
    local titles = {}
    for _, reward in ipairs(cfg.rewardDefs) do
        if state.unlockedRewards and state.unlockedRewards[reward.id] then
            titles[#titles + 1] = reward.title or reward.id
        end
    end
    return titles
end

sendStatus = function(actor)
    if actor and actor:isValid() then checkRewards(actor) end
    local c = state.counters or {}
    sendPlayerEvent(actor, 'cmcShowStatus', {
        counters = {
            diseasedCreaturesCured = c.diseasedCreaturesCured or 0,
            blightedCreaturesCured = c.blightedCreaturesCured or 0,
            diseasesSpread = c.diseasesSpread or 0,
            blightsSpread = c.blightsSpread or 0,
            mercyTotal = (c.diseasedCreaturesCured or 0) + (c.blightedCreaturesCured or 0),
            contagionTotal = (c.diseasesSpread or 0) + (c.blightsSpread or 0),
        },
        unlockedRewards = state.unlockedRewards or {},
        unlockedRewardTitles = sortedUnlockedRewardTitles(),
        pathCommitted = state.pathState and state.pathState.committed or nil,
        settings = activeSettings,
    })
end

local function handleFriendlySpeciesRequest(data)
    if not setting('enableSpeciesFriendship') then return end
    local target = targetCreature(data)
    if not target then return end
    local rid = originalForScriptlessCureRecord(cfg.lowerId(target.recordId))
    if cfg.isInfectedRecord(rid) or isScriptedCreatureAfflicted(target) then return end
    local family = cfg.familyOf(rid)
    if family and state.friendlyFamilies[family] then
        target:sendEvent('cmcMakeFriendly')
    end
end

local function sortedBlightMarks()
    local marks = {}
    for key, mark in pairs(state.blightMarkedActors or {}) do
        marks[#marks + 1] = {
            key = key,
            name = mark.name or mark.recordId or key,
            recordId = mark.recordId or '',
            spellId = mark.spellId or '',
            time = tonumber(mark.time or 0) or 0,
        }
    end
    table.sort(marks, function(a, b)
        local an = tostring(a.name or a.recordId or a.key or '')
        local bn = tostring(b.name or b.recordId or b.key or '')
        if an == bn then return tostring(a.key or '') < tostring(b.key or '') end
        return an < bn
    end)
    return marks
end

local function sendBlightMarks(actor)
    sendPlayerEvent(actor, 'cmcShowBlightMarks', { marks = sortedBlightMarks() })
end

local function clearBlightMarks(actor)
    local count = 0
    for key in pairs(state.blightMarkedActors or {}) do
        state.blightMarkedActors[key] = nil
        count = count + 1
    end
    notify(actor, string.format('OPP blight marks cleared: %d.', count), { force = true })
    sendBlightMarks(actor)
end

local function handleSettings(data)
    mergeSettings(data)
    if data and data.player then checkRewards(data.player) end
    syncPlayer(data and data.player)
end

local NPC_DAMAGE_SCRIPT = 'scripts/cmc/npc.lua'

local function onActorActive(object)
    if not object or not object:isValid() then return end
    if object.type ~= types.NPC then return end
    if types.Actor.isDead(object) then
        clearNpcBlightMark(object)
        return
    end
    pcall(function() object:addScript(NPC_DAMAGE_SCRIPT) end)
end

registerWorldIntegration()

return {
    engineHandlers = {
        onActorActive = onActorActive,
        onSave = function()
            return {
                state = state,
                activeSettings = activeSettings,
            }
        end,
        onLoad = function(saved)
            if saved and saved.state then
                state = saved.state
                state.counters = state.counters or {}
                state.speciesCures = state.speciesCures or {}
                state.friendlyFamilies = state.friendlyFamilies or {}
                state.unlockedRewards = state.unlockedRewards or {}
                state.pathState = state.pathState or { committed = nil }
                state.blightMarkedActors = state.blightMarkedActors or {}
                state.variantOrigins = state.variantOrigins or {}
                state.creatureAfflictions = state.creatureAfflictions or {}
                state.scriptlessCureOrigins = state.scriptlessCureOrigins or {}
                state.scriptlessCureRecords = state.scriptlessCureRecords or {}
            end
            if saved and saved.activeSettings then mergeSettings(saved.activeSettings) end
        end,
    },
    eventHandlers = {
        cmcApplyCure = handleCure,
        cmcApplySpread = handleSpread,
        cmcApplyAntiBlightDamage = handleAntiBlightDamage,
        cmcApplyResistScaledDamage = handleResistScaledDamage,
        cmcGiveAllTomes = giveAllTomes,
        cmcRequestFriendlySpecies = handleFriendlySpeciesRequest,
        cmcRequestAllyOwner = function(data)
            local target = data and data.target
            if target and target:isValid() then
                target:sendEvent('cmcSetAllyOwner', { owner = playerRecipient(nil) })
            end
        end,
        cmcUpdateSettings = handleSettings,
        cmcDebugVendor = function(data)
            if data and data.target then
                integrateVendor(data.target, { forceLog = true, actor = data.player })
            else
                audit(data and data.player, 'Vendor audit failed: no NPC target was supplied.')
            end
        end,
        cmcRequestSync = function(data) syncPlayer(data and data.player) end,
        cmcRequestStatus = function(data) sendStatus(data and data.player) end,
        cmcRequestBlightMarks = function(data) sendBlightMarks(data and data.player) end,
        cmcClearBlightMarks = function(data) clearBlightMarks(data and data.player) end,
        cmcClearNpcBlightMark = function(data) if data and data.target then clearNpcBlightMark(data.target) end end,
        cmcAdminCounter = handleAdminCounter,
        cmcLocalDamageApplied = function(data)
            if not data then return end
            damageDebug(data.actor, string.format('%s actual health: %s -> %s.', tostring(data.label or 'Damage'), tostring(data.before or '?'), tostring(data.after or '?')))
        end,
    },
}
