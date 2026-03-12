local self    = require('openmw.self')
local types   = require('openmw.types')
local core    = require('openmw.core')
local ui      = require('openmw.ui')
local ambient = require('openmw.ambient')
local storage = require('openmw.storage')
local async   = require('openmw.async')

local shared          = require("scripts.nshared")
local section         = storage.playerSection("SettingsNMEH")
local sectionCE       = storage.playerSection("SettingsNMEH_CE")
local sectionWisdom   = storage.playerSection("SettingsNMEH_Wisdom")
local sectionRecovery = storage.playerSection("SettingsNMEH_Recovery")
local DEFAULTS        = shared.DEFAULTS
local penaltyMessages  = shared.PENALTY_MESSAGES
local recoveryMessages = shared.RECOVERY_MESSAGES
local attrMessages     = shared.ATTR_MESSAGES
local wisdomMessages   = shared.WISDOM_MESSAGES
local foodList         = shared.FOOD

local CHECK_INTERVAL = DEFAULTS.CHECK_INTERVAL

local GAME_SECONDS_PER_DAY = 24 * 3600

local function get(key)
    local val = section:get(key)
    if val == nil then val = sectionCE:get(key) end
    if val == nil then val = sectionWisdom:get(key) end
    if val == nil then val = sectionRecovery:get(key) end
    if val == nil then return DEFAULTS[key] end
    return val
end

local cachedSettings = {
    HEAL_THRESHOLD      = get("HEAL_THRESHOLD"),
    HP_PENALTY          = get("HP_PENALTY"),
    MIN_BASE_HP         = get("MIN_BASE_HP"),
    DAMAGE_THRESHOLD    = get("DAMAGE_THRESHOLD"),
    ATTR_PENALTY        = get("ATTR_PENALTY"),
    PERSONALITY_PENALTY = get("PERSONALITY_PENALTY"),
    HP_RESTORE          = get("HP_RESTORE"),
    MOD_ENABLED         = get("MOD_ENABLED"),
    CE_IGNORE           = get("CE_IGNORE"),
    CE_INTERVAL         = get("CE_INTERVAL"),
    WISDOM_ENABLED      = get("WISDOM_ENABLED"),
    WISDOM_CHANCE       = get("WISDOM_CHANCE"),
    WISDOM_GAIN         = get("WISDOM_GAIN"),
    RECOVERY_ENABLED    = get("RECOVERY_ENABLED"),
    RECOVERY_DAYS       = get("RECOVERY_DAYS"),
    RECOVERY_PARTIAL    = get("RECOVERY_PARTIAL"),
}

local function onSettingsChanged(_, key)
    if key then
        cachedSettings[key] = get(key)
    else
        for k in pairs(cachedSettings) do
            cachedSettings[k] = get(k)
        end
    end
end

section:subscribe(async:callback(onSettingsChanged))
sectionCE:subscribe(async:callback(onSettingsChanged))
sectionWisdom:subscribe(async:callback(onSettingsChanged))
sectionRecovery:subscribe(async:callback(onSettingsChanged))

local accumulatedHpLost  = 0
local pendingHpRestore   = 0
local lastCheckTime      = 0
local lastHealth         = nil
local lastMaxHealth      = nil
local lastFortifyMag     = 0
local isCurrentlyHealing = false
local healCount          = 0
local ceTimer            = 0

local hpPenaltyLog   = {}
local attrPenaltyLog = {}
local recoveryTimer  = 0

local PENALIZABLE_ATTRS = { "strength", "agility", "speed", "endurance", "personality" }
local WISDOM_ATTRS      = { "willpower", "intelligence" }

local function getMagicStats()
    local effects = types.Actor.activeEffects(self)
    local fortify = effects:getEffect(core.magic.EFFECT_TYPE.FortifyHealth)
    return fortify.magnitude
end

local function getHealSource()
    local idRestore = core.magic.EFFECT_TYPE.RestoreHealth
    local hasSpell  = false
    local hasCE     = false

    for _, params in pairs(types.Actor.activeSpells(self)) do
        if params.effects and params.name then
            for _, effect in pairs(params.effects) do
                if effect.id == idRestore then
                    local isConstant = (effect.duration == 0 or effect.duration == nil)
                    local isFood     = false
                    for i = 1, #foodList do
                        if params.name == foodList[i] then
                            isFood = true
                            break
                        end
                    end

                    if isConstant then
                        hasCE = true
                    elseif not isFood then
                        hasSpell = true
                    end
                end
            end
        end
    end

    return { hasSpell = hasSpell, hasCE = hasCE }
end

local function getAttributeBase(attr)
    return types.Actor.stats.attributes[attr](self).base
end

local function setAttributeBase(attr, value)
    local stats = types.Actor.stats.attributes[attr](self)
    stats.base = value
end

local function applyWisdom()
    local attr     = WISDOM_ATTRS[math.random(#WISDOM_ATTRS)]
    local gain     = cachedSettings.WISDOM_GAIN
    setAttributeBase(attr, getAttributeBase(attr) + gain)
    local attrName = attr:sub(1,1):upper() .. attr:sub(2)
    return wisdomMessages[math.random(#wisdomMessages)] .. " +" .. gain .. " " .. attrName .. "."
end

local function applyRecovery()
    local now       = core.getGameTime()
    local threshold = now - cachedSettings.RECOVERY_DAYS * GAME_SECONDS_PER_DAY

    local restoredHp    = 0
    local restoredAttrs = {}  

    local newHpLog = {}
    for _, entry in ipairs(hpPenaltyLog) do
        if entry.gameTime <= threshold then
            restoredHp = restoredHp + entry.amount
        else
            newHpLog[#newHpLog + 1] = entry
        end
    end
    hpPenaltyLog = newHpLog

    local newAttrLog = {}
    for _, entry in ipairs(attrPenaltyLog) do
        if entry.gameTime <= threshold then
            restoredAttrs[entry.attr] = (restoredAttrs[entry.attr] or 0) + entry.amount
        else
            newAttrLog[#newAttrLog + 1] = entry
        end
    end
    attrPenaltyLog = newAttrLog

    local anyRestored = false
    local partial     = cachedSettings.RECOVERY_PARTIAL

    local function calcRestored(amount)
        if partial then
            return math.ceil(amount / 2)
        end
        return amount
    end

    if restoredHp > 0 then
        local restored = calcRestored(restoredHp)
        local healthStats = types.Actor.stats.dynamic.health(self)
        healthStats.base = healthStats.base + restored
        restoredHp = restored
        anyRestored = true
    end

    for attr, amount in pairs(restoredAttrs) do
        local restored = calcRestored(amount)
        setAttributeBase(attr, getAttributeBase(attr) + restored)
        restoredAttrs[attr] = restored
        anyRestored = true
    end

    if anyRestored then
        local msg = recoveryMessages[math.random(#recoveryMessages)]
        local parts = {}
        if restoredHp > 0 then
            parts[#parts + 1] = "+" .. restoredHp .. " Health"
        end
        for attr, amount in pairs(restoredAttrs) do
            local attrName = attr:sub(1,1):upper() .. attr:sub(2)
            parts[#parts + 1] = "+" .. amount .. " " .. attrName
        end
        if #parts > 0 then
            msg = msg .. " (" .. table.concat(parts, ", ") .. ")"
        end
        ui.showMessage(msg)
    end
end

local function applyAttributePenalty()
    local ATTR_PENALTY        = cachedSettings.ATTR_PENALTY
    local PERSONALITY_PENALTY = cachedSettings.PERSONALITY_PENALTY
    local DAMAGE_THRESHOLD    = cachedSettings.DAMAGE_THRESHOLD
    local HP_RESTORE          = cachedSettings.HP_RESTORE

    local attr    = PENALIZABLE_ATTRS[math.random(#PENALIZABLE_ATTRS)]
    local penalty = (attr == "personality") and PERSONALITY_PENALTY or ATTR_PENALTY
    local current = getAttributeBase(attr)
    local actual  = math.min(penalty, math.max(0, current - 1))
    setAttributeBase(attr, math.max(1, current - penalty))

    if cachedSettings.RECOVERY_ENABLED and actual > 0 then
        attrPenaltyLog[#attrPenaltyLog + 1] = {
            attr     = attr,
            amount   = actual,
            gameTime = core.getGameTime(),
        }
    end

    local attrName = attr:sub(1,1):upper() .. attr:sub(2)
    local msg      = attrMessages[attr][math.random(#attrMessages[attr])] .. " -" .. penalty .. " " .. attrName .. "."

    if cachedSettings.WISDOM_ENABLED then
        if math.random(100) <= cachedSettings.WISDOM_CHANCE then
            msg = msg .. " " .. applyWisdom()
        end
    end

    ui.showMessage(msg)

    if HP_RESTORE then
        pendingHpRestore = pendingHpRestore + DAMAGE_THRESHOLD * cachedSettings.HP_PENALTY
    end
end

local function applyHealPenalty(healthStats)
    local MIN_BASE_HP      = cachedSettings.MIN_BASE_HP
    local DAMAGE_THRESHOLD = cachedSettings.DAMAGE_THRESHOLD

    if healthStats.base > MIN_BASE_HP then
        local oldBase = healthStats.base
        healthStats.base = math.max(MIN_BASE_HP, healthStats.base - cachedSettings.HP_PENALTY)
        local actual = oldBase - healthStats.base

        ui.showMessage(penaltyMessages[math.random(#penaltyMessages)])
        ambient.playSound("Pack", { volume = 0.6 })

        if cachedSettings.RECOVERY_ENABLED and actual > 0 and not cachedSettings.HP_RESTORE then
            hpPenaltyLog[#hpPenaltyLog + 1] = {
                amount   = actual,
                gameTime = core.getGameTime(),
            }
        end

        accumulatedHpLost = accumulatedHpLost + 1
        if accumulatedHpLost >= DAMAGE_THRESHOLD then
            accumulatedHpLost = accumulatedHpLost - DAMAGE_THRESHOLD
            applyAttributePenalty()
        end
    end
end

return {
    engineHandlers = {
        onSave = function()
            return {
                healCount         = healCount,
                accumulatedHpLost = accumulatedHpLost,
                ceTimer           = ceTimer,
                hpPenaltyLog      = hpPenaltyLog,
                attrPenaltyLog    = attrPenaltyLog,
                recoveryTimer     = recoveryTimer,
            }
        end,

        onLoad = function(data)
            if data then
                healCount         = data.healCount or 0
                accumulatedHpLost = data.accumulatedHpLost or 0
                ceTimer           = data.ceTimer or 0
                hpPenaltyLog      = data.hpPenaltyLog or {}
                attrPenaltyLog    = data.attrPenaltyLog or {}
                recoveryTimer     = data.recoveryTimer or 0
            end
            lastHealth         = nil
            lastMaxHealth      = nil
            lastFortifyMag     = 0
            isCurrentlyHealing = false
        end,

        onUpdate = function(dt)
            if cachedSettings.MOD_ENABLED == false then return end

            if cachedSettings.RECOVERY_ENABLED then
                recoveryTimer = recoveryTimer + dt
                if recoveryTimer >= 1.0 then
                    recoveryTimer = recoveryTimer - 1.0
                    applyRecovery()
                    lastMaxHealth = nil
                end
            end

            if not cachedSettings.CE_IGNORE then
                ceTimer = ceTimer + dt
                if ceTimer >= cachedSettings.CE_INTERVAL then
                    ceTimer = ceTimer - cachedSettings.CE_INTERVAL
                    local source = getHealSource()
                    if source.hasCE then
                        local healthStats = types.Actor.stats.dynamic.health(self)
                        local maxHp       = healthStats.base + healthStats.modifier
                        if healthStats.current < (maxHp - 0.1) then
                            applyHealPenalty(healthStats)
                        end
                    end
                end
            end

            lastCheckTime = lastCheckTime + dt
            if lastCheckTime < CHECK_INTERVAL then return end
            lastCheckTime = 0

            local healthStats = types.Actor.stats.dynamic.health(self)
            local currentHp   = healthStats.current
            local maxHp       = healthStats.base + healthStats.modifier

            if pendingHpRestore > 0 then
                healthStats.base    = healthStats.base + pendingHpRestore
                maxHp               = healthStats.base + healthStats.modifier
                currentHp           = math.min(currentHp, maxHp)
                healthStats.current = currentHp
                lastHealth          = currentHp
                pendingHpRestore    = 0
            end

            local currentFortifyMag = getMagicStats()

            local fortifyChanged = math.abs(currentFortifyMag - lastFortifyMag) > 0.1
            local maxHpChanged   = lastMaxHealth and math.abs(maxHp - lastMaxHealth) > 0.1

            if fortifyChanged or maxHpChanged then
                lastHealth         = currentHp
                lastMaxHealth      = maxHp
                lastFortifyMag     = currentFortifyMag
                isCurrentlyHealing = false
                healCount          = 0
                return
            end

            if lastHealth ~= nil then
                local hpGained = currentHp - lastHealth
                local source   = getHealSource()

                if hpGained > 0.1 and currentHp < (maxHp - 0.1) then
                    if source.hasSpell and not isCurrentlyHealing then
                        isCurrentlyHealing = true
                        healCount = healCount + 1
                        if healCount >= cachedSettings.HEAL_THRESHOLD then
                            healCount = healCount - cachedSettings.HEAL_THRESHOLD
                            applyHealPenalty(healthStats)
                        end
                    end
                end

                if not source.hasSpell then
                    isCurrentlyHealing = false
                end
            end

            lastHealth     = currentHp
            lastMaxHealth  = maxHp
            lastFortifyMag = currentFortifyMag
        end,
    }
}