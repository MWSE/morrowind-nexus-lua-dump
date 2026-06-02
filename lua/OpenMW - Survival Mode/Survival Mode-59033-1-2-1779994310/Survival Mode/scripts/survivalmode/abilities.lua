local M = {}

function M.create(deps)
    local core = deps.core
    local self = deps.self
    local types = deps.types
    local state = deps.state
    local now = deps.now
    local round = deps.round
    local trim = deps.trim
    local normalizeKey = deps.normalizeKey
    local hungerContentModule = deps.hungerContentModule
    local thirstContentModule = deps.thirstContentModule
    local temperatureContentModule = deps.temperatureContentModule
    local temperature = deps.temperature
    local temperatureDebug = deps.temperatureDebug
    local isTemperatureSystemEnabled = deps.isTemperatureSystemEnabled
    local isTemperatureBasedHealthPenaltiesEnabled = deps.isTemperatureBasedHealthPenaltiesEnabled
    local isHbfsDisableConjurationDrainEnabled = deps.isHbfsDisableConjurationDrainEnabled
    local getThirstMagicSkillIds = deps.getThirstMagicSkillIds
    local wellFedStageId = deps.wellFedStageId
    local wellHydratedStageId = deps.wellHydratedStageId
    local wellRestedStageId = deps.wellRestedStageId
    local wellFedLearningFallbackEffectId = deps.wellFedLearningFallbackEffectId
    local wellRestedArmorSkillGainBonusPct = deps.wellRestedArmorSkillGainBonusPct
    local wellRestedStaminiaRegenBonusPct = deps.wellRestedStaminiaRegenBonusPct
    local wellRestedStaminaRegenDisplayEffectId = deps.wellRestedStaminaRegenDisplayEffectId
    local weaponSkillIds = deps.weaponSkillIds
    local armorAndUnarmoredSkillIds = deps.armorAndUnarmoredSkillIds
    local hungerStages = deps.hungerStages
    local thirstStages = deps.thirstStages
    local sleepStages = deps.sleepStages
    local needsDebuffSpellIdPrefix = deps.needsDebuffSpellIdPrefix
    local needsDynamicSpellRequestEvent = deps.needsDynamicSpellRequestEvent

    local function getSkillBaseValue(skillId)
        if not types.NPC.objectIsInstance(self) then
            return 0
        end

        local skillGetter = types.NPC.stats.skills[skillId]
        if type(skillGetter) ~= 'function' then
            return 0
        end

        local skillStat = skillGetter(self)
        if skillStat ~= nil and type(skillStat.base) == 'number' then
            return math.max(0, skillStat.base)
        end
        return 0
    end

    local function getStrengthBaseValue()
        if not types.NPC.objectIsInstance(self) then
            return 0
        end

        local strengthStat = types.NPC.stats.attributes.strength(self)
        if strengthStat ~= nil and type(strengthStat.base) == 'number' then
            return math.max(0, strengthStat.base)
        end
        return 0
    end

    local function percentSnapshotPoints(currentValue, percent)
        local baseValue = tonumber(currentValue) or 0
        local pct = tonumber(percent) or 0
        if baseValue <= 0 or pct <= 0 then
            return 0
        end
        return math.max(0, round(baseValue * pct))
    end

    local function appendDrainSkillEffects(effectList, skillIds, percent)
        local pct = tonumber(percent) or 0
        if pct <= 0 then
            return
        end

        for _, skillId in ipairs(skillIds) do
            local currentValue = getSkillBaseValue(skillId)
            local points = percentSnapshotPoints(currentValue, pct)
            if points > 0 then
                effectList[#effectList + 1] = {
                    id = 'drainskill',
                    affectedSkill = skillId,
                    magnitudeMin = points,
                    magnitudeMax = points,
                    duration = 0,
                    range = 'self',
                }
            end
        end
    end

    local function buildStageSpellNameSet(stages)
        local names = {}
        if type(stages) ~= 'table' then
            return names
        end

        for _, stage in ipairs(stages) do
            if type(stage) == 'table' then
                local stageSpellName = normalizeKey(stage.spellName)
                if stageSpellName ~= '' then
                    names[stageSpellName] = true
                end

                local weaknessSpellName = normalizeKey(stage.weaknessSpellName)
                if weaknessSpellName ~= '' then
                    names[weaknessSpellName] = true
                end

                if type(stage.spellNames) == 'table' then
                    for _, variantName in pairs(stage.spellNames) do
                        local normalizedVariantName = normalizeKey(variantName)
                        if normalizedVariantName ~= '' then
                            names[normalizedVariantName] = true
                        end
                    end
                end
            end
        end

        return names
    end

    local needsStageSpellNamesByCategory = {
        hunger = buildStageSpellNameSet(hungerStages),
        thirst = buildStageSpellNameSet(thirstStages),
        sleep = buildStageSpellNameSet(sleepStages),
        temperature = buildStageSpellNameSet(type(temperature.system) == 'table' and temperature.system.STAGES or nil),
    }

    local needsStageSpellNamesAll = {}
    for _, stageNameSet in pairs(needsStageSpellNamesByCategory) do
        for spellName, _ in pairs(stageNameSet) do
            needsStageSpellNamesAll[spellName] = true
        end
    end

    local function isLikelyNeedsDebuffSpellRecord(spell, category)
        if type(spell) ~= 'table' then
            return false
        end

        local spellId = normalizeKey(spell.id)
        if spellId ~= '' and string.sub(spellId, 1, #needsDebuffSpellIdPrefix) == needsDebuffSpellIdPrefix then
            return true
        end

        if spell.type ~= nil and spell.type ~= core.magic.SPELL_TYPE.Ability then
            return false
        end

        local spellName = normalizeKey(spell.name)
        if spellName == '' then
            return false
        end

        local allowedNameSet = needsStageSpellNamesAll
        if type(category) == 'string' and needsStageSpellNamesByCategory[category] ~= nil then
            allowedNameSet = needsStageSpellNamesByCategory[category]
        end
        if allowedNameSet[spellName] ~= true then
            return false
        end

        local cost = tonumber(spell.cost)
        if cost ~= nil and cost ~= 0 then
            return false
        end

        if spell.alwaysSucceedFlag ~= nil and spell.alwaysSucceedFlag ~= true then
            return false
        end

        return true
    end

    local function buildDynamicEffectsForStage(category, stage)
        local effects = {}

        if category == 'hunger' then
            hungerContentModule.appendDynamicEffectsForStage(effects, stage, {
                appendDrainSkillEffects = appendDrainSkillEffects,
                weaponSkillIds = weaponSkillIds,
                normalizeKey = normalizeKey,
                core = core,
                wellFedStageId = wellFedStageId,
                learningFallbackEffectId = wellFedLearningFallbackEffectId,
                isTemperatureSystemEnabled = isTemperatureSystemEnabled,
                temperature = temperature,
                state = state,
            })
        elseif category == 'thirst' then
            thirstContentModule.appendDynamicEffectsForStage(effects, stage, {
                appendDrainSkillEffects = appendDrainSkillEffects,
                magicSkillIds = getThirstMagicSkillIds(),
                normalizeKey = normalizeKey,
                core = core,
                wellHydratedStageId = wellHydratedStageId,
                learningFallbackEffectId = wellFedLearningFallbackEffectId,
            })
        elseif category == 'sleep' then
            appendDrainSkillEffects(effects, armorAndUnarmoredSkillIds, stage.armorSkillDrainPct)
            appendDrainSkillEffects(effects, { 'block', 'sneak' }, stage.blockSneakDrainPct)

            local burdenPct = tonumber(stage.sleepBurdenPct) or 0
            local carryWeight = getStrengthBaseValue() * 5
            local burdenPoints = percentSnapshotPoints(carryWeight, burdenPct)
            if burdenPoints > 0 then
                effects[#effects + 1] = {
                    id = 'burden',
                    magnitudeMin = burdenPoints,
                    magnitudeMax = burdenPoints,
                    duration = 0,
                    range = 'self',
                }
            end

            local stageId = normalizeKey(stage.id)
            local armorBonusPct = tonumber(stage.armorSkillGainBonusPct) or 0
            local staminiaBonusPct = tonumber(stage.staminiaRegenBonusPct) or 0
            local learningEffectId = normalizeKey(stage.learningEffectId)
            if learningEffectId ~= '' and core.magic.effects.records[learningEffectId] == nil then
                local fallbackEffectId = normalizeKey(wellFedLearningFallbackEffectId)
                if fallbackEffectId ~= '' and core.magic.effects.records[fallbackEffectId] ~= nil then
                    learningEffectId = fallbackEffectId
                else
                    learningEffectId = ''
                end
            end
            local learningEffectMagnitude = math.max(0, tonumber(stage.learningEffectMagnitude) or 0)
            if stageId == wellRestedStageId
                and state.sleepWellRestedBonusEligible == true
                and armorBonusPct > 0
                and learningEffectId ~= '' then
                effects[#effects + 1] = {
                    id = learningEffectId,
                    magnitudeMin = learningEffectMagnitude,
                    magnitudeMax = learningEffectMagnitude,
                    duration = 0,
                    range = 'self',
                }
            end
            if stageId == wellRestedStageId
                and state.sleepWellRestedBonusEligible == true
                and staminiaBonusPct > 0 then
                effects[#effects + 1] = {
                    id = wellRestedStaminaRegenDisplayEffectId,
                    magnitudeMin = 0,
                    magnitudeMax = 0,
                    duration = 0,
                    range = 'self',
                }
            end
        elseif category == 'temperature' then
            temperatureContentModule.appendDynamicEffectsForStage(effects, stage, {
                getHealthLossPct = function()
                    return temperatureDebug.getTemperatureHealthLossPct(tonumber(state.temperature) or 0)
                end,
                isTemperatureBasedHealthPenaltiesEnabled = isTemperatureBasedHealthPenaltiesEnabled,
            })
        end

        return effects
    end

    local function buildDynamicSpellSignature(spellName, effects)
        return temperatureContentModule.buildDynamicSpellSignature(spellName, effects, {
            trim = trim,
            normalizeKey = normalizeKey,
        })
    end

    local function removeAppliedDynamicSpell(category)
        if types.Actor.objectIsInstance(self) then
            local actorSpells = types.Actor.spells(self)
            local removeSpellIds = {}
            local currentSpellId = state.appliedNeedsDynamicSpellByCategory[category]
            if type(currentSpellId) == 'string' and currentSpellId ~= '' then
                removeSpellIds[currentSpellId] = true
            end

            local trackedByCategory = state.trackedNeedsDynamicSpellIdsByCategory[category]
            if type(trackedByCategory) == 'table' then
                for spellId, enabled in pairs(trackedByCategory) do
                    if enabled == true and type(spellId) == 'string' and spellId ~= '' then
                        removeSpellIds[spellId] = true
                    end
                end
            end

            for _, spell in pairs(actorSpells) do
                if isLikelyNeedsDebuffSpellRecord(spell, category) and type(spell.id) == 'string' and spell.id ~= '' then
                    removeSpellIds[spell.id] = true
                end
            end

            for spellId, _ in pairs(removeSpellIds) do
                pcall(function()
                    actorSpells:remove(spellId)
                end)
                state.knownNeedsDynamicSpellIds[spellId] = nil
            end
        end

        state.trackedNeedsDynamicSpellIdsByCategory[category] = {}
        state.appliedNeedsDynamicSpellByCategory[category] = nil
    end

    local function clearNeedDynamicCategories(categories)
        if type(categories) ~= 'table' then
            return
        end

        for _, category in ipairs(categories) do
            if type(category) == 'string' and category ~= '' then
                state.pendingNeedsDynamicRequestByCategory[category] = nil
                state.appliedNeedsDynamicStageByCategory[category] = nil
                removeAppliedDynamicSpell(category)
            end
        end
    end

    local function processDebuffConfigChanges()
        local currentValue = isHbfsDisableConjurationDrainEnabled()
        local previousValue = state.lastHbfsDisableConjurationDrain
        state.lastHbfsDisableConjurationDrain = currentValue

        if previousValue == nil or previousValue == currentValue then
            return
        end

        state.appliedNeedsDynamicStageByCategory.thirst_skill = nil
        state.pendingNeedsDynamicRequestByCategory.thirst_skill = nil
        removeAppliedDynamicSpell('thirst_skill')
    end

    local function ensureLegacyNeedsSpellsCleaned()
        if state.legacyNeedsSpellCleanupDone == true or not types.Actor.objectIsInstance(self) then
            return
        end

        local actorSpells = types.Actor.spells(self)
        local removeSpellIds = {}
        for _, spell in pairs(actorSpells) do
            if spell ~= nil and type(spell.id) == 'string' and spell.id ~= '' then
                local spellId = spell.id
                local knownId = state.knownNeedsDynamicSpellIds[spellId] == true
                if knownId or isLikelyNeedsDebuffSpellRecord(spell) then
                    removeSpellIds[#removeSpellIds + 1] = spellId
                end
            end
        end

        for _, spellId in ipairs(removeSpellIds) do
            pcall(function()
                actorSpells:remove(spellId)
            end)
            state.knownNeedsDynamicSpellIds[spellId] = nil
        end

        state.trackedNeedsDynamicSpellIdsByCategory.hunger = {}
        state.trackedNeedsDynamicSpellIdsByCategory.thirst = {}
        state.trackedNeedsDynamicSpellIdsByCategory.sleep = {}
        state.trackedNeedsDynamicSpellIdsByCategory.hunger_learning = {}
        state.trackedNeedsDynamicSpellIdsByCategory.thirst_learning = {}
        state.trackedNeedsDynamicSpellIdsByCategory.sleep_learning = {}
        state.trackedNeedsDynamicSpellIdsByCategory.temperature_hunger_misc = {}
        state.trackedNeedsDynamicSpellIdsByCategory.temperature_thirst_misc = {}
        state.trackedNeedsDynamicSpellIdsByCategory.temperature_slowness_misc = {}
        state.trackedNeedsDynamicSpellIdsByCategory.temperature_health_misc = {}
        state.trackedNeedsDynamicSpellIdsByCategory.temperature_weakness = {}
        state.appliedNeedsDynamicSpellByCategory.hunger = nil
        state.appliedNeedsDynamicSpellByCategory.thirst = nil
        state.appliedNeedsDynamicSpellByCategory.sleep = nil
        state.appliedNeedsDynamicSpellByCategory.hunger_learning = nil
        state.appliedNeedsDynamicSpellByCategory.thirst_learning = nil
        state.appliedNeedsDynamicSpellByCategory.sleep_learning = nil
        state.appliedNeedsDynamicSpellByCategory.temperature_hunger_misc = nil
        state.appliedNeedsDynamicSpellByCategory.temperature_thirst_misc = nil
        state.appliedNeedsDynamicSpellByCategory.temperature_slowness_misc = nil
        state.appliedNeedsDynamicSpellByCategory.temperature_health_misc = nil
        state.appliedNeedsDynamicSpellByCategory.temperature_weakness = nil
        state.pendingNeedsDynamicRequestByCategory.hunger = nil
        state.pendingNeedsDynamicRequestByCategory.thirst = nil
        state.pendingNeedsDynamicRequestByCategory.sleep = nil
        state.pendingNeedsDynamicRequestByCategory.hunger_learning = nil
        state.pendingNeedsDynamicRequestByCategory.thirst_learning = nil
        state.pendingNeedsDynamicRequestByCategory.sleep_learning = nil
        state.pendingNeedsDynamicRequestByCategory.temperature_hunger_misc = nil
        state.pendingNeedsDynamicRequestByCategory.temperature_thirst_misc = nil
        state.pendingNeedsDynamicRequestByCategory.temperature_slowness_misc = nil
        state.pendingNeedsDynamicRequestByCategory.temperature_health_misc = nil
        state.pendingNeedsDynamicRequestByCategory.temperature_weakness = nil
        state.legacyNeedsSpellCleanupDone = true
    end

    local function requestDynamicDebuffSpell(category, stage)
        if not types.Actor.objectIsInstance(self) then
            return
        end

        local normalizedCategory = normalizeKey(category)
        local baseCategory = normalizedCategory
        local includeSkillEffects = true
        local includeNonSkillEffects = true
        local includeLearningEffects = false
        local temperatureMiscVariant = nil
        if string.sub(normalizedCategory, -6) == '_skill' then
            baseCategory = string.sub(normalizedCategory, 1, -7)
            includeNonSkillEffects = false
        elseif string.sub(normalizedCategory, -5) == '_misc' then
            baseCategory = string.sub(normalizedCategory, 1, -6)
            includeSkillEffects = false
        elseif string.sub(normalizedCategory, -9) == '_learning' then
            baseCategory = string.sub(normalizedCategory, 1, -10)
            includeSkillEffects = false
            includeNonSkillEffects = false
            includeLearningEffects = true
        elseif string.sub(normalizedCategory, -9) == '_weakness' then
            baseCategory = string.sub(normalizedCategory, 1, -10)
        end
        if string.sub(normalizedCategory, 1, 12) == 'temperature_' and string.sub(normalizedCategory, -5) == '_misc' then
            baseCategory = 'temperature'
            includeSkillEffects = false
            local variantText = string.sub(normalizedCategory, 13, -6)
            if variantText == nil or variantText == '' or variantText == 'stamina' then
                return
            end
            temperatureMiscVariant = variantText
        end

        if baseCategory ~= 'hunger' and baseCategory ~= 'thirst' and baseCategory ~= 'sleep' and baseCategory ~= 'temperature' then
            return
        end

        local stageVariantId = normalizedCategory
        local stageId = stage ~= nil and stage.id or nil
        local spellName = stage ~= nil and stage.spellName or nil
        if temperatureMiscVariant ~= nil then
            spellName = ''
        end
        if baseCategory == 'hunger' and normalizedCategory == 'hunger_misc' and type(stage) == 'table' then
            local resolvedHungerMiscSpellName = hungerContentModule.resolveHungerMiscSpellName(stage, {
                core = core,
                isTemperatureSystemEnabled = isTemperatureSystemEnabled,
                temperature = temperature,
                state = state,
            })
            if type(resolvedHungerMiscSpellName) == 'string' and resolvedHungerMiscSpellName ~= '' then
                spellName = resolvedHungerMiscSpellName
            end
        elseif baseCategory == 'thirst' and normalizedCategory == 'thirst_misc' and type(stage) == 'table' then
            local resolvedThirstMiscSpellName = thirstContentModule.resolveThirstMiscSpellName(stage, { core = core })
            if type(resolvedThirstMiscSpellName) == 'string' and resolvedThirstMiscSpellName ~= '' then
                spellName = resolvedThirstMiscSpellName
            end
        elseif baseCategory == 'sleep' and normalizedCategory == 'sleep_learning' and type(stage) == 'table' then
            if normalizeKey(stage.id) == wellRestedStageId then
                local bonusMultiplier = math.max(1.0, tonumber(state.sleepWellRestedBonusMultiplier) or 1.0)
                local armorBonusPct = tonumber(stage.armorSkillGainBonusPct)
                if armorBonusPct == nil then
                    armorBonusPct = wellRestedArmorSkillGainBonusPct
                end
                if armorBonusPct > 0 then
                    spellName = string.format(
                        'Well Rested (Armor Skills): %d%%',
                        math.floor((armorBonusPct * bonusMultiplier * 100) + 0.5)
                    )
                end
            end
        elseif baseCategory == 'sleep' and normalizedCategory == 'sleep_misc' and type(stage) == 'table' then
            if normalizeKey(stage.id) == wellRestedStageId then
                local bonusMultiplier = math.max(1.0, tonumber(state.sleepWellRestedBonusMultiplier) or 1.0)
                local staminiaBonusPct = tonumber(stage.staminiaRegenBonusPct)
                if staminiaBonusPct == nil then
                    staminiaBonusPct = wellRestedStaminiaRegenBonusPct
                end
                if staminiaBonusPct > 0 then
                    spellName = string.format(
                        'Well Rested: %d%%',
                        math.floor((staminiaBonusPct * bonusMultiplier * 100) + 0.5)
                    )
                end
            end
        elseif baseCategory == 'temperature' and type(stage) == 'table' then
            local resolvedSpellName, resolvedStageVariantId = temperatureContentModule.resolveSpellName(
                stage,
                normalizedCategory,
                temperatureMiscVariant,
                {
                    core = core,
                    healthLossPct = temperatureDebug.getTemperatureHealthLossPct(state.temperature),
                    isTemperatureBasedHealthPenaltiesEnabled = isTemperatureBasedHealthPenaltiesEnabled,
                }
            )
            if type(resolvedSpellName) == 'string' and resolvedSpellName ~= '' then
                spellName = resolvedSpellName
            end
            if type(resolvedStageVariantId) == 'string' and resolvedStageVariantId ~= '' then
                stageVariantId = resolvedStageVariantId
            end
        end
        if type(stageId) == 'string' and stageId ~= '' then
            stageVariantId = string.format('%s_%s', stageId, normalizedCategory)
        end

        if type(spellName) ~= 'string' or spellName == '' or type(stageVariantId) ~= 'string' or stageVariantId == '' then
            state.appliedNeedsDynamicStageByCategory[normalizedCategory] = nil
            state.pendingNeedsDynamicRequestByCategory[normalizedCategory] = nil
            removeAppliedDynamicSpell(normalizedCategory)
            return
        end

        local baseEffects = buildDynamicEffectsForStage(baseCategory, stage)
        if #baseEffects == 0 then
            state.appliedNeedsDynamicStageByCategory[normalizedCategory] = nil
            state.pendingNeedsDynamicRequestByCategory[normalizedCategory] = nil
            removeAppliedDynamicSpell(normalizedCategory)
            return
        end

        local effects = {}
        local stageLearningEffectId = ''
        if type(stage) == 'table' then
            stageLearningEffectId = normalizeKey(stage.learningEffectId)
            if stageLearningEffectId ~= '' and core.magic.effects.records[stageLearningEffectId] == nil then
                local fallbackEffectId = normalizeKey(wellFedLearningFallbackEffectId)
                if fallbackEffectId ~= '' and core.magic.effects.records[fallbackEffectId] ~= nil then
                    stageLearningEffectId = fallbackEffectId
                else
                    stageLearningEffectId = ''
                end
            end
        end
        local includeTemperatureWeaknessEffects = normalizedCategory == 'temperature_weakness'
        local includeTemperatureMiscEffects = temperatureMiscVariant ~= nil
        for _, effect in ipairs(baseEffects) do
            if type(effect) == 'table' then
                local effectId = normalizeKey(effect.id)
                if baseCategory == 'temperature' then
                    if temperatureContentModule.shouldIncludeEffect(
                        effectId,
                        includeTemperatureWeaknessEffects,
                        includeTemperatureMiscEffects and temperatureMiscVariant or nil
                    ) then
                        effects[#effects + 1] = effect
                    end
                else
                    local isSkillEffect = effectId == 'drainskill'
                    local isLearningEffect = stageLearningEffectId ~= '' and effectId == stageLearningEffectId
                    if (includeLearningEffects and isLearningEffect)
                        or (includeSkillEffects and isSkillEffect)
                        or (includeNonSkillEffects and not isSkillEffect and not isLearningEffect) then
                        effects[#effects + 1] = effect
                    end
                end
            end
        end
        if #effects == 0 then
            state.appliedNeedsDynamicStageByCategory[normalizedCategory] = nil
            state.pendingNeedsDynamicRequestByCategory[normalizedCategory] = nil
            removeAppliedDynamicSpell(normalizedCategory)
            return
        end

        stageVariantId = string.format('%s_sig%s', stageVariantId, buildDynamicSpellSignature(spellName, effects))

        local targetStageId = state.appliedNeedsDynamicStageByCategory[normalizedCategory]
        local appliedSpellId = state.appliedNeedsDynamicSpellByCategory[normalizedCategory]
        local pending = state.pendingNeedsDynamicRequestByCategory[normalizedCategory]
        local currentTime = now()

        if targetStageId == stageVariantId then
            if type(appliedSpellId) == 'string' and appliedSpellId ~= '' then
                return
            end
            if type(pending) == 'table' then
                local sentAt = tonumber(pending.sentAt) or 0
                if currentTime - sentAt < 1.0 then
                    return
                end
                state.pendingNeedsDynamicRequestByCategory[normalizedCategory] = nil
            end
        else
            state.appliedNeedsDynamicStageByCategory[normalizedCategory] = stageVariantId
            state.pendingNeedsDynamicRequestByCategory[normalizedCategory] = nil
            removeAppliedDynamicSpell(normalizedCategory)
        end

        state.needsDynamicRequestCounter = (tonumber(state.needsDynamicRequestCounter) or 0) + 1
        local requestId = state.needsDynamicRequestCounter
        state.pendingNeedsDynamicRequestByCategory[normalizedCategory] = {
            requestId = requestId,
            stageId = stageVariantId,
            sentAt = currentTime,
        }

        local playerObject = self.object or self
        local ok, err = pcall(function()
            core.sendGlobalEvent(needsDynamicSpellRequestEvent, {
                player = playerObject,
                category = normalizedCategory,
                stageId = stageVariantId,
                spellName = spellName,
                requestId = requestId,
                effects = effects,
            })
        end)
        if not ok then
            state.pendingNeedsDynamicRequestByCategory[normalizedCategory] = nil
            print(string.format(
                '[SurvivalMode] Failed to request dynamic debuff spell for %s/%s: %s',
                normalizedCategory,
                stageVariantId,
                tostring(err)
            ))
        end
    end

    local function syncNeedsDebuffSpells(hungerStage, thirstStage, sleepStage, temperatureStage, suppressSkillDebuffs)
        local suppressSkills = suppressSkillDebuffs == true
        ensureLegacyNeedsSpellsCleaned()
        if type(hungerStage) == 'table' then
            if not suppressSkills then
                requestDynamicDebuffSpell('hunger_skill', hungerStage)
            end
            requestDynamicDebuffSpell('hunger_misc', hungerStage)
            requestDynamicDebuffSpell('hunger_learning', hungerStage)
        end
        if type(thirstStage) == 'table' then
            if not suppressSkills then
                requestDynamicDebuffSpell('thirst_skill', thirstStage)
            end
            requestDynamicDebuffSpell('thirst_misc', thirstStage)
            requestDynamicDebuffSpell('thirst_learning', thirstStage)
        end
        if type(sleepStage) == 'table' then
            if not suppressSkills then
                requestDynamicDebuffSpell('sleep_skill', sleepStage)
            end
            requestDynamicDebuffSpell('sleep_misc', sleepStage)
            requestDynamicDebuffSpell('sleep_learning', sleepStage)
        end
        if type(temperatureStage) == 'table' then
            requestDynamicDebuffSpell('temperature_hunger_misc', temperatureStage)
            requestDynamicDebuffSpell('temperature_thirst_misc', temperatureStage)
            requestDynamicDebuffSpell('temperature_slowness_misc', temperatureStage)
            requestDynamicDebuffSpell('temperature_health_misc', temperatureStage)
            requestDynamicDebuffSpell('temperature_weakness', temperatureStage)
        end
    end

    local function onDynamicDebuffSpellReady(data)
        if type(data) ~= 'table' or not types.Actor.objectIsInstance(self) then
            return
        end

        local category = normalizeKey(data.category)
        if category == '' then
            return
        end

        local pending = state.pendingNeedsDynamicRequestByCategory[category]
        if type(pending) ~= 'table' then
            return
        end

        local requestId = tonumber(data.requestId)
        if requestId == nil or requestId ~= pending.requestId then
            return
        end

        state.pendingNeedsDynamicRequestByCategory[category] = nil
        if state.appliedNeedsDynamicStageByCategory[category] ~= pending.stageId then
            return
        end

        local spellId = ''
        if type(data.spellId) == 'string' then
            spellId = trim(data.spellId)
        elseif data.spellId ~= nil then
            spellId = tostring(data.spellId)
        end
        if spellId == '' then
            return
        end

        removeAppliedDynamicSpell(category)
        local actorSpells = types.Actor.spells(self)
        local appliedSpellId = nil

        local function tryAddById(idValue)
            local idString = type(idValue) == 'string' and trim(idValue) or ''
            if idString == '' then
                return false, 'empty id'
            end

            local ok, err = pcall(function()
                actorSpells:add(idString)
            end)
            if ok then
                return true, idString
            end
            return false, err
        end

        local ok, valueOrError = tryAddById(spellId)
        if ok then
            appliedSpellId = valueOrError
        else
            local record = core.magic.spells.records[spellId]
            if record ~= nil then
                local okRecord = pcall(function()
                    actorSpells:add(record)
                end)
                if okRecord then
                    appliedSpellId = tostring(record.id or spellId)
                end
            end

            if appliedSpellId == nil then
                local lowerId = string.lower(spellId)
                if lowerId ~= spellId then
                    local okLower, lowerValueOrError = tryAddById(lowerId)
                    if okLower then
                        appliedSpellId = lowerValueOrError
                    else
                        local lowerRecord = core.magic.spells.records[lowerId]
                        if lowerRecord ~= nil then
                            local okLowerRecord = pcall(function()
                                actorSpells:add(lowerRecord)
                            end)
                            if okLowerRecord then
                                appliedSpellId = tostring(lowerRecord.id or lowerId)
                            end
                        end
                    end
                end
            end
        end

        if appliedSpellId ~= nil and appliedSpellId ~= '' then
            state.appliedNeedsDynamicSpellByCategory[category] = appliedSpellId
            state.needsDebuffSpellApplyFailures[spellId] = nil
            state.knownNeedsDynamicSpellIds[appliedSpellId] = true
            if type(state.trackedNeedsDynamicSpellIdsByCategory[category]) ~= 'table' then
                state.trackedNeedsDynamicSpellIdsByCategory[category] = {}
            end
            state.trackedNeedsDynamicSpellIdsByCategory[category][appliedSpellId] = true
        elseif state.needsDebuffSpellApplyFailures[spellId] ~= true then
            state.needsDebuffSpellApplyFailures[spellId] = true
            print(string.format('[SurvivalMode] Failed to apply dynamic needs debuff spell "%s": %s', spellId, tostring(valueOrError)))
        end
    end

    local function resetLearningAndTemperatureCategories()
        clearNeedDynamicCategories({
            'hunger_learning',
            'thirst_learning',
            'sleep_learning',
            'temperature_hunger_misc',
            'temperature_thirst_misc',
            'temperature_slowness_misc',
            'temperature_health_misc',
            'temperature_weakness',
        })
    end

    local function clearSkillDynamicCategories()
        clearNeedDynamicCategories({ 'hunger_skill', 'thirst_skill', 'sleep_skill' })
    end

    local function resetSkillCategoryRequestState()
        local categories = { 'hunger_skill', 'thirst_skill', 'sleep_skill' }
        for _, category in ipairs(categories) do
            state.pendingNeedsDynamicRequestByCategory[category] = nil
            state.appliedNeedsDynamicStageByCategory[category] = nil
            state.appliedNeedsDynamicSpellByCategory[category] = nil
        end
    end

    return {
        clearNeedDynamicCategories = clearNeedDynamicCategories,
        removeAppliedDynamicSpell = removeAppliedDynamicSpell,
        processDebuffConfigChanges = processDebuffConfigChanges,
        syncNeedsDebuffSpells = syncNeedsDebuffSpells,
        onDynamicDebuffSpellReady = onDynamicDebuffSpellReady,
        resetLearningAndTemperatureCategories = resetLearningAndTemperatureCategories,
        clearSkillDynamicCategories = clearSkillDynamicCategories,
        resetSkillCategoryRequestState = resetSkillCategoryRequestState,
    }
end

return M
