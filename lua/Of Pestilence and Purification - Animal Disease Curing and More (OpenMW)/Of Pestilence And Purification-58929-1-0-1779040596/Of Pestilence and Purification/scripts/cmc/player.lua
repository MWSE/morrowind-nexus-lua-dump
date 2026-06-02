local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local ui = require('openmw.ui')
local I = require('openmw.interfaces')
local cfg = require('scripts.cmc.config')
local settings = require('scripts.cmc.settings')

local pendingActions = {}
local playerSettings = settings.snapshot()
local unlockedRewards = {}
local pendingDreams = {}
local subscribedToSettings = false
local activeAfflictionBoosts = {}
local neutralizedAfflictions = {}
local afflictionMaintenanceTimer = 0
local legacyAfflictionBoostsRemoved = false

local function playerKnowsSpell(spellId)
    for _, spell in pairs(types.Player.spells(self)) do
        if cfg.lowerId(spell.id) == cfg.lowerId(spellId) then return true end
    end
    return false
end

local function learnSpell(spellId)
    if not spellId or playerKnowsSpell(spellId) then return end
    pcall(function()
        types.Player.spells(self):add(spellId)
    end)
end

local function learnSpellList(list)
    for _, spellId in ipairs(list or {}) do learnSpell(spellId) end
end

local function removeSpell(spellId)
    if not spellId or not playerKnowsSpell(spellId) then return end
    pcall(function()
        types.Player.spells(self):remove(spellId)
    end)
end

local function removeSpellRaw(spellId)
    if not spellId then return end
    pcall(function()
        types.Player.spells(self):remove(spellId)
    end)
    pcall(function()
        local active = types.Actor.activeSpells(self)
        if active and active.remove then active:remove(spellId) end
    end)
end

local function learnModSpells()
    if not playerSettings.autoLearnBaseSpells then return end
    learnSpell(cfg.spells.purifyBeast)
    learnSpell(cfg.spells.spreadCommon)
    learnSpell(cfg.spells.spreadBlight)
end

local function spellAllowedBySettings(spellId)
    local tag = cfg.spellTags[cfg.lowerId(spellId)]
    if tag == 'carrier' then return playerSettings.enableCarrierTraits end
    if tag == 'antiBlight' then return playerSettings.enableAntiBlightDamage end
    if tag == 'areaSpread' then return playerSettings.enableAreaSpreadRewards end
    return true
end

local updateAfflictionBoosts

local function highestUnlockedRewardForPath(path)
    local best = nil
    for rewardId in pairs(unlockedRewards) do
        local reward = cfg.rewardById[rewardId]
        if reward and reward.path == path then
            if not best or cfg.rewardThreshold(reward, playerSettings) > cfg.rewardThreshold(best, playerSettings) then
                best = reward
            end
        end
    end
    return best
end

local function applyAllRewards()
    local desired = {}
    local bestByPath = {
        mercy = highestUnlockedRewardForPath(cfg.rewardPaths.mercy),
        disease = highestUnlockedRewardForPath(cfg.rewardPaths.disease),
        blight = highestUnlockedRewardForPath(cfg.rewardPaths.blight),
    }

    -- Reward tier abilities are mutually exclusive within a path. The save may
    -- remember all unlocked tiers for titles, ledgers, and rechecks, but only
    -- the highest unlocked tier should be active on the player.
    for _, reward in pairs(bestByPath) do
        if reward and reward.spells then
            for _, spellId in ipairs(reward.spells) do
                if spellAllowedBySettings(spellId) then
                    desired[cfg.lowerId(spellId)] = spellId
                end
            end
        end
    end

    -- Remove reward-granted spells that should no longer be present because a
    -- reward was revoked or a category was disabled.
    for _, reward in ipairs(cfg.rewardDefs) do
        if reward.spells then
            for _, spellId in ipairs(reward.spells) do
                if not desired[cfg.lowerId(spellId)] then
                    removeSpell(spellId)
                end
            end
        end
    end

    for _, spellId in pairs(desired) do
        learnSpell(spellId)
    end
    updateAfflictionBoosts()
end


local function rewardTier(prefix)
    local tier = 0
    if unlockedRewards[prefix .. '_1'] then tier = math.max(tier, 1) end
    if unlockedRewards[prefix .. '_2'] then tier = math.max(tier, 2) end
    if unlockedRewards[prefix .. '_3'] then tier = math.max(tier, 3) end
    return tier
end

local function activeRewardTierFor(kind)
    local tier = rewardTier('mercy')
    if kind == 'common' then
        tier = math.max(tier, rewardTier('disease'))
    elseif kind == 'blight' then
        tier = math.max(tier, rewardTier('blight'))
    end
    return tier
end

local function adaptationCapForTier(tier)
    tier = tonumber(tier) or 0
    if tier >= 3 then return nil end -- nil means uncapped
    if tier >= 2 then return 4 end
    if tier >= 1 then return 2 end
    return 0
end

local function adaptedCountForKind(kind)
    local count = 0
    for diseaseId in pairs(neutralizedAfflictions or {}) do
        local def = cfg.playerAfflictionBoostByDiseaseId[diseaseId]
        if def and def.kind == kind then count = count + 1 end
    end
    return count
end

local function canAdaptMoreOfKind(kind)
    local tier = activeRewardTierFor(kind)
    local cap = adaptationCapForTier(tier)
    if cap == nil then return true end
    return adaptedCountForKind(kind) < cap
end


local function activeSpellId(activeSpell)
    if not activeSpell then return nil end
    local rec = activeSpell.spell or activeSpell.record
    return cfg.lowerId(activeSpell.id or activeSpell.spellId or activeSpell.recordId or (rec and rec.id))
end

local function currentlyActiveDiseaseIds()
    local found = {}
    local ok, activeSpells = pcall(function() return types.Actor.activeSpells(self) end)
    if not ok or not activeSpells then return found end

    -- Set semantics are deliberate: each unique whitelisted disease can grant
    -- at most one inverse adaptation spell, even if active-effects iteration
    -- exposes duplicate instances.
    for _, activeSpell in pairs(activeSpells) do
        local id = activeSpellId(activeSpell)
        if id and cfg.playerAfflictionBoostByDiseaseId[id] then
            found[id] = true
        end
    end
    return found
end

local function canAdaptAffliction(def)
    if not def then return false end
    if not playerSettings.enableCarrierTraits then return false end
    local tier = activeRewardTierFor(def.kind)
    return tier and tier > 0
end

local function suppressAdaptedAfflictions(activeIds)
    local ordered = {}
    for diseaseId in pairs(activeIds or {}) do ordered[#ordered + 1] = diseaseId end
    table.sort(ordered)

    for _, diseaseId in ipairs(ordered) do
        local def = cfg.playerAfflictionBoostByDiseaseId[diseaseId]
        if def and canAdaptAffliction(def) then
            if neutralizedAfflictions[diseaseId] then
                -- Re-infection with an already adapted disease can re-add the raw
                -- disease spell. Strip it again so the player never receives both
                -- the vanilla drain and the OPP fortify adaptation.
                removeSpellRaw(def.diseaseId or diseaseId)
            elseif canAdaptMoreOfKind(def.kind) then
                neutralizedAfflictions[diseaseId] = true
                -- Once the adaptation is earned, remove the underlying disease spell
                -- so the vanilla attribute/skill values no longer appear red. The
                -- remembered disease ID keeps the adaptation and ledger entry alive.
                removeSpellRaw(def.diseaseId or diseaseId)
            end
        end
    end
end

local function stripRememberedRawAfflictions()
    for diseaseId in pairs(neutralizedAfflictions or {}) do
        local def = cfg.playerAfflictionBoostByDiseaseId[diseaseId]
        if def and canAdaptAffliction(def) then
            removeSpellRaw(def.diseaseId or diseaseId)
        end
    end
end

local function activeDiseaseIds()
    local found = currentlyActiveDiseaseIds()
    suppressAdaptedAfflictions(found)
    stripRememberedRawAfflictions()
    for diseaseId in pairs(neutralizedAfflictions or {}) do
        if cfg.playerAfflictionBoostByDiseaseId[diseaseId] then
            found[diseaseId] = true
        else
            neutralizedAfflictions[diseaseId] = nil
        end
    end
    return found
end

local function clearNeutralizedAfflictions()
    for _, spellId in ipairs(cfg.playerAfflictionBoostIds or {}) do
        removeSpell(spellId)
    end
    activeAfflictionBoosts = {}
    neutralizedAfflictions = {}
end

local function titleCase(value)
    value = tostring(value or '')
    return (value:gsub('_', ' '):gsub('%f[%a](%l)', string.upper))
end

local function describeAfflictionEffect(effect)
    if not effect then return nil end
    local amount = tostring(effect.min or 0)
    if tonumber(effect.max or effect.min) ~= tonumber(effect.min) then
        amount = tostring(effect.min or 0) .. '-' .. tostring(effect.max or effect.min)
    end
    if effect.kind == 'attribute' then
        return '+' .. amount .. ' ' .. titleCase(effect.name)
    elseif effect.kind == 'skill' then
        return '+' .. amount .. ' ' .. titleCase(effect.name)
    elseif effect.kind == 'fatigue' then
        return '+' .. amount .. ' Fatigue'
    elseif effect.kind == 'resistparalysis' then
        return '+' .. amount .. '% Resist Paralysis'
    end
    return nil
end

local function showAfflictionLedger()
    updateAfflictionBoosts()
    local activeIds = activeDiseaseIds()
    local lines = {}
    for diseaseId in pairs(activeIds) do
        local def = cfg.playerAfflictionBoostByDiseaseId[diseaseId]
        if def then
            local tier = activeRewardTierFor(def.kind)
            local parts = {}
            for _, effect in ipairs(def.effects or {}) do
                local text = describeAfflictionEffect(effect)
                if text then parts[#parts + 1] = text end
            end
            local state = 'locked'
            if neutralizedAfflictions[diseaseId] then
                state = 'active'
            elseif tier and tier > 0 then
                state = 'capped'
            end
            lines[#lines + 1] = string.format('%s: %s (%s)', def.title or titleCase(diseaseId), table.concat(parts, ', '), state)
        end
    end
    table.sort(lines)
    if #lines == 0 then
        ui.showMessage('OPP disease ledger: no whitelisted common diseases or blights detected.')
    else
        ui.showMessage('OPP disease ledger: ' .. table.concat(lines, '; '))
    end
end

local function getAfflictionLedger()
    local activeIds = activeDiseaseIds()
    local entries = {}
    for diseaseId in pairs(activeIds) do
        local def = cfg.playerAfflictionBoostByDiseaseId[diseaseId]
        if def then
            local tier = activeRewardTierFor(def.kind)
            local effects = {}
            for _, effect in ipairs(def.effects or {}) do
                effects[#effects + 1] = {
                    kind = effect.kind,
                    name = effect.name,
                    min = effect.min,
                    max = effect.max,
                    text = describeAfflictionEffect(effect),
                }
            end
            entries[#entries + 1] = {
                diseaseId = diseaseId,
                title = def.title or titleCase(diseaseId),
                kind = def.kind,
                active = neutralizedAfflictions[diseaseId] and true or false,
                capped = ((tier and tier > 0) and not neutralizedAfflictions[diseaseId]) and true or false,
                neutralized = neutralizedAfflictions[diseaseId] and true or false,
                tier = tier or 0,
                boostId = def.boostId,
                effects = effects,
            }
        end
    end
    table.sort(entries, function(a, b) return tostring(a.title) < tostring(b.title) end)
    return entries
end

local legacyAfflictionBoostIds = {
    cfg.spells.commonAfflictionBoost1, cfg.spells.commonAfflictionBoost2, cfg.spells.commonAfflictionBoost3,
    cfg.spells.blightAfflictionBoost1, cfg.spells.blightAfflictionBoost2, cfg.spells.blightAfflictionBoost3,
}

local function removeLegacyAfflictionBoosts()
    if legacyAfflictionBoostsRemoved then return end
    legacyAfflictionBoostsRemoved = true
    for _, spellId in ipairs(legacyAfflictionBoostIds) do
        removeSpell(spellId)
    end
end

function updateAfflictionBoosts()
    removeLegacyAfflictionBoosts()

    local desired = {}
    if playerSettings.enableCarrierTraits then
        local activeIds = activeDiseaseIds()
        for diseaseId in pairs(activeIds) do
            local def = cfg.playerAfflictionBoostByDiseaseId[diseaseId]
            if def then
                local tier = activeRewardTierFor(def.kind)
                if tier and tier > 0 and def.boostId and neutralizedAfflictions[diseaseId] then
                    desired[cfg.lowerId(def.boostId)] = def.boostId
                end
            end
        end
    end

    -- Do not remove/re-add adaptation abilities every frame. OpenMW applies
    -- ability effects as spell membership changes; thrashing the spell list can
    -- prevent active effects from settling and makes the UI unreliable. Keep a
    -- small local set and only change spells when the desired set changes.
    for _, spellId in ipairs(cfg.playerAfflictionBoostIds or {}) do
        local lowered = cfg.lowerId(spellId)
        if not desired[lowered] and (activeAfflictionBoosts[lowered] or playerKnowsSpell(spellId)) then
            removeSpell(spellId)
            activeAfflictionBoosts[lowered] = nil
        end
    end

    for lowered, spellId in pairs(desired) do
        if not activeAfflictionBoosts[lowered] or not playerKnowsSpell(spellId) then
            learnSpell(spellId)
        end
        activeAfflictionBoosts[lowered] = spellId
    end
end

local function sendSettingsToGlobal()
    local payload = {}
    for k, v in pairs(playerSettings) do payload[k] = v end
    payload.player = self.object
    core.sendGlobalEvent('cmcUpdateSettings', payload)
end

local function requestSync()
    core.sendGlobalEvent('cmcRequestSync', { player = self.object })
end

local function effectIsNonSelf(effect)
    return effect and effect.range ~= core.magic.RANGE.Self
end

local function spellEffectKind(spell)
    if not spell then return nil, nil end
    local spreadKind = cfg.isSpreadSpell(spell.id)
    if spreadKind then return 'spread', spreadKind end

    -- Script-resolved damage spells are handled by the hit actor's local
    -- active-effect scan. Do not also apply them through the player look-target
    -- fallback; that fallback fires on spell use rather than confirmed hit and
    -- can duplicate local damage, especially on NPC targets.

    -- Anti-blight reward spells are handled by actor-side active-effect
    -- scanning, not by the look-target fallback. That avoids double damage for
    -- area spells.
    if cfg.isAntiBlightSpell(spell.id) then return nil, nil end

    if not spell.effects then return nil, nil end
    for _, effect in ipairs(spell.effects) do
        local cureKind = cfg.isCureEffect(effect.id)
        if cureKind and effectIsNonSelf(effect) then
            return 'cure', cureKind
        end
    end
    return nil, nil
end

local function getSelectedSpellAction()
    local spell = types.Player.getSelectedSpell(self)
    local actionType, kind = spellEffectKind(spell)
    if actionType then
        return { actionType = actionType, kind = kind, spellId = spell.id }
    end
    return nil
end

local function getRayObject()
    if not I.SharedRay or not I.SharedRay.get then return nil end
    local ray = I.SharedRay.get()
    if not ray or not ray.hit or not ray.hitObject then return nil end
    local target = ray.hitObject
    if target and target:isValid() then return target end
    return nil
end

local function getRayActorTarget()
    local target = getRayObject()
    if target and (target.type == types.Creature or target.type == types.NPC) then return target end
    return nil
end

local function getRayCreatureTarget()
    local target = getRayObject()
    if target and target.type == types.Creature then return target end
    return nil
end

local function processPendingActions()
    if #pendingActions == 0 then return end
    local now = core.getSimulationTime()
    local remaining = {}

    for _, action in ipairs(pendingActions) do
        if now < action.runAt then
            remaining[#remaining + 1] = action
        else
            local target = (action.actionType == 'resistDamage') and getRayActorTarget() or getRayCreatureTarget()
            if target then
                if action.actionType == 'cure' then
                    core.sendGlobalEvent('cmcApplyCure', {
                        actor = self.object,
                        target = target,
                        kind = action.kind,
                        spellId = action.spellId,
                    })
                elseif action.actionType == 'spread' then
                    core.sendGlobalEvent('cmcApplySpread', {
                        actor = self.object,
                        target = target,
                        kind = action.kind,
                        spellId = action.spellId,
                    })
                elseif action.actionType == 'resistDamage' then
                    core.sendGlobalEvent('cmcApplyResistScaledDamage', {
                        actor = self.object,
                        target = target,
                        kind = action.kind,
                        spellId = action.spellId,
                    })
                end
            end
        end
    end

    pendingActions = remaining
end

local function onSkillUsed()
    local action = getSelectedSpellAction()
    if not action then return end
    action.runAt = core.getSimulationTime() + 0.05
    pendingActions[#pendingActions + 1] = action
end

local handlersRegistered = false
local function registerSkillHandler()
    if handlersRegistered then return end
    handlersRegistered = true

    -- Previous builds used SkillProgression.addSkillUsedHandler as a player-side
    -- raycast fallback for cure/spread spells. That hook is intentionally broad:
    -- weapon swings also report skill usage. If an OPP spell remained selected,
    -- hitting a creature with a mundane weapon could therefore apply the selected
    -- cure/spread action to the current look target and roll animal ally logic.
    --
    -- Creature/NPC local scripts now observe actual active magic effects on the
    -- struck actor, so this generic player fallback is no longer safe or needed.
    print('[Of Pestilence and Purification] Player skill-use raycast fallback disabled; OPP effects resolve from actual target active effects.')
end

local function queueDream(data)
    if not data or not data.message then return end
    if not playerSettings.enableDreamMessages then return end
    pendingDreams[#pendingDreams + 1] = { rewardId = data.rewardId, message = data.message }
end

local function showNextDream()
    if not playerSettings.enableDreamMessages then return end
    if #pendingDreams == 0 then return end
    local dream = table.remove(pendingDreams, 1)
    if dream and dream.message then
        ui.showMessage(dream.message, { showInDialogue = false })
    end
end

local function teachTome(def)
    if not def then return end
    local learnedAny = false
    for _, spellId in ipairs(def.spells or {}) do
        if not playerKnowsSpell(spellId) then
            learnSpell(spellId)
            learnedAny = true
        end
    end
    if learnedAny then
        ui.showMessage(def.message or 'You learn a spell.')
    else
        ui.showMessage('You already know what this tome holds.')
    end
end

local function onUiModeChanged(data)
    if data and data.oldMode == 'Rest' then
        showNextDream()
    end
    if data and data.newMode == 'Book' and data.arg and data.arg.recordId then
        local def = cfg.tomeById[cfg.lowerId(data.arg.recordId)]
        if not def and types.Book and types.Book.records then
            pcall(function()
                local rec = types.Book.records[data.arg.recordId]
                if rec and rec.name then def = cfg.tomeByName[tostring(rec.name):lower()] end
            end)
        end
        teachTome(def)
    end
end

local function onRewardUnlocked(data)
    if not data then return end
    local rewardId = data.rewardId or (data.reward and data.reward.id)
    if rewardId then unlockedRewards[rewardId] = true end
    local reward = cfg.rewardById[rewardId] or data.reward
    if reward then applyAllRewards() end
    updateAfflictionBoosts()
end

local function onSyncRewards(data)
    if data and data.settings then
        for k, v in pairs(data.settings) do
            if playerSettings[k] ~= nil then playerSettings[k] = v end
        end
    end
    if data and data.unlockedRewards then
        unlockedRewards = {}
        for k, v in pairs(data.unlockedRewards) do
            if v then unlockedRewards[k] = true end
        end
    end
    learnModSpells()
    applyAllRewards()
end

local function onSettingsChanged(newSettings)
    playerSettings = newSettings or settings.snapshot()
    learnModSpells()
    applyAllRewards()
    sendSettingsToGlobal()
end

local function subscribeSettings()
    if subscribedToSettings then return end
    subscribedToSettings = true
    settings.subscribe(onSettingsChanged)
end

local function onInit()
    settings.init()
    subscribeSettings()
    registerSkillHandler()
    learnModSpells()
    sendSettingsToGlobal()
    requestSync()
end

local function onLoad(saved)
    playerSettings = settings.snapshot()
    settings.init()
    subscribeSettings()
    registerSkillHandler()
    pendingActions = {}
    afflictionMaintenanceTimer = 0
    legacyAfflictionBoostsRemoved = false
    unlockedRewards = (saved and saved.unlockedRewards) or {}
    pendingDreams = (saved and saved.pendingDreams) or {}
    neutralizedAfflictions = (saved and saved.neutralizedAfflictions) or {}
    learnModSpells()
    applyAllRewards()
    sendSettingsToGlobal()
    requestSync()
end



local function showBlightMarks(data)
    local marks = data and data.marks or {}
    if #marks == 0 then
        ui.showMessage('OPP blight marks: none.')
        return
    end
    local lines = { 'OPP blight marks:' }
    local limit = math.min(#marks, 12)
    for i = 1, limit do
        local mark = marks[i]
        local label = tostring(mark.name or mark.recordId or mark.key or 'unknown target')
        if mark.recordId and mark.recordId ~= '' then label = label .. ' [' .. tostring(mark.recordId) .. ']' end
        lines[#lines + 1] = label
    end
    if #marks > limit then lines[#lines + 1] = string.format('...and %d more.', #marks - limit) end
    ui.showMessage(table.concat(lines, '\n'))
end

local function showStatus(data)
    local c = data and data.counters or {}
    local settings = data and data.settings or {}
    local unlocked = data and data.unlockedRewardTitles or {}
    local unlockedText = (#unlocked > 0) and table.concat(unlocked, ', ') or 'none'
    local path = data and data.pathCommitted or 'none'
    local msg = string.format(
        'OPP counters: cures=%d (%d common, %d blight); spreads=%d (%d common, %d blight); path=%s; thresholds=%s; reward unlocks=%s; path traits=%s; unlocked=%s',
        c.mercyTotal or 0,
        c.diseasedCreaturesCured or 0,
        c.blightedCreaturesCured or 0,
        c.contagionTotal or 0,
        c.diseasesSpread or 0,
        c.blightsSpread or 0,
        tostring(path),
        cfg.thresholdLabel(settings),
        tostring(settings.enableRewardUnlocks),
        tostring(settings.enableCarrierTraits),
        unlockedText
    )
    ui.showMessage(msg)
end


local function splitConsoleCommand(command)
    local parts = {}
    for part in tostring(command or ''):gmatch('%S+') do
        parts[#parts + 1] = part
    end
    return parts
end

local function sendAdminCounterCommand(action, counter, value)
    core.sendGlobalEvent('cmcAdminCounter', {
        player = self.object,
        action = action,
        counter = counter,
        value = tonumber(value),
    })
end

local function onConsoleCommand(mode, command)
    if command == 'lua oppspells' or command == 'lua pestilencespells' then
        learnSpellList(cfg.consoleSpellOrder)
        ui.showMessage('Of Pestilence and Purification spells added.')
    elseif command:match('^lua%s+oppspell%s+') then
        local parts = splitConsoleCommand(command)
        local alias = cfg.lowerId(parts[3] or '')
        alias = alias and alias:gsub("[%s_%-\\']", "") or alias
        local spellId = cfg.consoleSpellAliases and cfg.consoleSpellAliases[alias]
        if spellId then
            learnSpellList({ spellId })
            ui.showMessage('Of Pestilence and Purification spell added: ' .. tostring(spellId))
        else
            ui.showMessage('Unknown OPP spell alias. Try lua oppspells, or aliases such as purify, disease, gift, blight, compassion, feverbite, contagion, plagueburst, mercy, cleansing, storm, peryite, ashplume, ashstorm.')
        end
    elseif command == 'lua opptraits' then
        learnSpellList(cfg.rewardTraitSpellOrder)
        ui.showMessage('Of Pestilence and Purification reward traits added.')
    elseif command == 'lua opptomes' or command == 'lua pestilencetomes' then
        core.sendGlobalEvent('cmcGiveAllTomes', { player = self.object })
        ui.showMessage('Of Pestilence and Purification spell tomes added.')
    elseif command == 'lua oppvendorcheck' or command == 'lua oppauditvendor' then
        local target = getRayObject()
        if target and target.type == types.NPC then
            core.sendGlobalEvent('cmcDebugVendor', { player = self.object, target = target })
            ui.showMessage('Auditing Of Pestilence and Purification merchant integration for ' .. tostring(target.recordId) .. '.')
        else
            ui.showMessage('Look directly at an NPC or merchant, then run: lua oppvendorcheck')
        end
    elseif command == 'lua oppstatus' or command == 'lua opprecheck' then
        core.sendGlobalEvent('cmcRequestStatus', { player = self.object })
        ui.showMessage('Checking Of Pestilence and Purification counters.')
    elseif tostring(command or ''):match('^lua%s+oppadd%s+') then
        local parts = splitConsoleCommand(command)
        sendAdminCounterCommand('add', parts[3], parts[4] or 1)
    elseif tostring(command or ''):match('^lua%s+oppset%s+') then
        local parts = splitConsoleCommand(command)
        sendAdminCounterCommand('set', parts[3], parts[4] or 0)
    elseif tostring(command or ''):match('^lua%s+opptier%s+') then
        local parts = splitConsoleCommand(command)
        sendAdminCounterCommand('tier', parts[3], parts[4] or 1)
    elseif command == 'lua oppledger' or command == 'lua oppdiseases' then
        showAfflictionLedger()
    elseif command == 'lua oppmarks' then
        core.sendGlobalEvent('cmcRequestBlightMarks', { player = self.object })
    elseif command == 'lua oppclearmarks' then
        core.sendGlobalEvent('cmcClearBlightMarks', { player = self.object })
    elseif command == 'lua oppclearadaptations' then
        clearNeutralizedAfflictions()
        ui.showMessage('Of Pestilence and Purification disease adaptations cleared.')
    elseif command == 'lua oppdebugon' then
        playerSettings.debugMessages = true
        sendSettingsToGlobal()
        ui.showMessage('Of Pestilence and Purification debug logging enabled for this session.')
    elseif command == 'lua oppdebugoff' then
        playerSettings.debugMessages = false
        sendSettingsToGlobal()
        ui.showMessage('Of Pestilence and Purification debug logging disabled for this session.')
    elseif command == 'lua oppdamagetest on' or command == 'lua oppdamageon' then
        playerSettings.debugDamageMessages = true
        sendSettingsToGlobal()
        ui.showMessage('OPP damage test readouts enabled. Cast Disease Damage, Blight Damage, or Scourge Blight spells to see resistance calculations.')
    elseif command == 'lua oppdamagetest off' or command == 'lua oppdamageoff' then
        playerSettings.debugDamageMessages = false
        sendSettingsToGlobal()
        ui.showMessage('OPP damage test readouts disabled.')
    elseif command == 'lua oppdamagetest' then
        playerSettings.debugDamageMessages = not playerSettings.debugDamageMessages
        sendSettingsToGlobal()
        ui.showMessage('OPP damage test readouts ' .. (playerSettings.debugDamageMessages and 'enabled.' or 'disabled.'))
    elseif command == 'lua opphelp' then
        ui.showMessage('Commands: lua oppstatus, lua oppledger, lua oppmarks, lua oppclearmarks, lua oppadd <counter> <n>, lua oppset <counter> <n>, lua opptier <path> <1-3>, lua oppclearadaptations, lua oppspells, lua oppspell <alias>, lua opptraits, lua opptomes, lua oppvendorcheck, lua oppdamagetest on/off, lua oppdebugon/off.')
    end
end


local function getHighestRewardForPath(path)
    local best = nil
    for _, reward in ipairs(cfg.rewardDefs or {}) do
        if reward.path == path and unlockedRewards[reward.id] then
            if not best or cfg.rewardThreshold(reward, playerSettings) > cfg.rewardThreshold(best, playerSettings) then
                best = reward
            end
        end
    end
    return best
end

local function getDignitasTitles()
    local titles = {}
    local order = { 'mercy', 'disease', 'blight' }
    local descByPath = {
        mercy = 'Earned by cleansing diseased and blighted beasts.',
        disease = 'Earned by spreading common disease among beasts.',
        blight = 'Earned by spreading blight among beasts.',
    }
    for _, path in ipairs(order) do
        local reward = getHighestRewardForPath(path)
        if reward and reward.title then
            titles[#titles + 1] = {
                id = 'opp_' .. tostring(reward.id),
                name = reward.title,
                desc = descByPath[path] or 'Earned through Of Pestilence and Purification.',
                source = 'Of Pestilence and Purification',
                path = path,
                threshold = cfg.rewardThreshold(reward, playerSettings),
            }
        end
    end
    return titles
end

return {
    interfaceName = 'OfPestilenceAndPurification',
    interface = {
        getDignitasTitles = getDignitasTitles,
        getAfflictionLedger = getAfflictionLedger,
    },
    engineHandlers = {
        onInit = onInit,
        onLoad = onLoad,
        onSave = function()
            return {
                unlockedRewards = unlockedRewards,
                pendingDreams = pendingDreams,
                neutralizedAfflictions = neutralizedAfflictions,
            }
        end,
        onUpdate = function(dt)
            if #pendingActions > 0 then processPendingActions() end

            afflictionMaintenanceTimer = afflictionMaintenanceTimer + dt
            local interval = tonumber(cfg.thresholds.playerAfflictionScanInterval or 1.0) or 1.0
            if afflictionMaintenanceTimer >= interval then
                afflictionMaintenanceTimer = 0
                updateAfflictionBoosts()
            end
        end,
        onConsoleCommand = onConsoleCommand,
    },
    eventHandlers = {
        UiModeChanged = onUiModeChanged,
        cmcShowMessage = function(data)
            if data and data.message then ui.showMessage(data.message) end
        end,
        cmcRewardUnlocked = onRewardUnlocked,
        cmcSyncRewards = onSyncRewards,
        cmcShowStatus = showStatus,
        cmcShowBlightMarks = showBlightMarks,
        cmcQueueDream = queueDream,
    },
}
