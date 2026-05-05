local core = require('openmw.core')
local T = require('openmw.types')
local camera = require('openmw.camera')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local util = require('openmw.util')

local mDef = require("scripts.MRF.config.definition")
local mStore = require("scripts.MRF.config.store")
local mH = require("scripts.MRF.util.helpers")
local mUi = require("scripts.MRF.util.ui")

local L = core.l10n(mDef.MOD_NAME)
local lastCheckTime = 0
local lastCameraPosition = camera.getPosition()
local disabled = false
local fEffectCostMult = core.getGMST("fEffectCostMult")

local module = {}

local effectRanges = {}
for key, value in pairs(core.magic.RANGE) do
    effectRanges[value] = key
end

local function getFacedObject()
    local from = camera.getPosition()
    local to = from + self.rotation:apply(util.vector3(0, 1000, 0))
    local result = nearby.castRay(from, to, { ignore = self });
    return result.hitObject
end

local function getAutoCalcEffectCost(effect)
    local minMagnitude = 1
    local maxMagnitude = 1
    if effect.effect.hasMagnitude then
        minMagnitude = effect.magnitudeMin
        maxMagnitude = effect.magnitudeMax
    end
    local duration = 1
    if effect.effect.hasDuration then
        duration = effect.duration
    end
    if not effect.effect.isAppliedOnce then
        duration = math.max(1, effect.duration)
    end

    local cost = (0.5 * (math.max(1, minMagnitude) + math.max(1, maxMagnitude))
            * 0.1 * effect.effect.baseCost
            * duration
            + 0.05 * math.max(1, effect.area) * effect.effect.baseCost
    ) * fEffectCostMult

    if effect.range == core.magic.RANGE.Target then
        cost = cost * 1.5
    end
    return math.max(0, cost)
end

local function getSpellCost(spell)
    if not spell.autocalcFlag then
        return spell.cost
    end
    local cost = 0
    for _, effect in ipairs(spell.effects) do
        cost = cost + getAutoCalcEffectCost(effect)
    end
    return math.floor(0.5 + cost)
end

local function showActorSpells(actor, showSpellMode)
    if actor.type == T.Player then
        lastCameraPosition = camera.getPosition()
    end
    local lines = {}
    local spells = {}
    if showSpellMode == mStore.showSpellModes.Known then
        spells = T.Actor.spells(actor)
    else
        for id in pairs(T.Actor.activeSpells(actor)) do
            spells[id] = core.magic.spells.records[id]
        end
    end
    local sortedSpells = {}
    for _, spell in mH.spairs(spells, function(t, a, b) return t[a].name < t[b].name end) do
        table.insert(sortedSpells, spell)
    end
    for _, spell in pairs(sortedSpells) do
        if spell.type == core.magic.SPELL_TYPE.Spell then
            table.insert(lines, string.format("%s (%s): cost=%s, auto=%s", spell.name, spell.id, getSpellCost(spell), spell.autocalcFlag))
            for _, effect in ipairs(spell.effects) do
                local fields = {
                    effect.effect.name,
                    (effect.affectedAttribute and core.stats.Attribute.records[effect.affectedAttribute].name)
                            or (effect.affectedSkill and core.stats.Skill.records[effect.affectedSkill].name)
                            or nil
                }
                if effect.effect.hasMagnitude and effect.magnitudeMin and effect.magnitudeMin ~= 0 then
                    table.insert(fields, string.format("%s to %s pts", effect.magnitudeMin, effect.magnitudeMax))
                end
                if effect.effect.hasDuration and effect.duration and effect.duration ~= 0 then
                    table.insert(fields, string.format("for %s sec", effect.duration))
                end
                if effect.area and effect.area ~= 0 then
                    table.insert(fields, string.format("in %s ft", effect.area))
                end
                table.insert(fields, string.format("on %s", effectRanges[effect.range]))
                table.insert(lines, string.format("    %s", table.concat(fields, " ")))
            end
            table.insert(lines, "")
        end
    end
    if #lines == 0 then
        lines = { showSpellMode == mStore.showSpellModes.Known and L("noKnownSpells") or L("noActiveSpells") }
    else
        table.remove(lines, #lines)
    end
    mUi.createWindow(lines)
end

module.checkActorSpells = function(deltaTime, showSpellMode)
    if disabled then return end
    lastCheckTime = lastCheckTime + deltaTime
    if lastCheckTime < 0.1 then return end
    lastCheckTime = 0
    local object
    if self.type == T.Player and self.controls.sneak then
        object = self
    else
        local cameraPosition = camera.getPosition()
        object = getFacedObject()
        if not object or not T.Actor.objectIsInstance(object) then
            if (cameraPosition - lastCameraPosition):length() > 0.5 then
                mUi.clearWindow()
            end
            return
        end
        lastCameraPosition = cameraPosition
    end
    showActorSpells(object, showSpellMode)
end

module.uiModeChanged = function(data)
    if data.newMode == "Dialogue" then
        mUi.clearWindow()
        disabled = true
    elseif not data.newMode then
        disabled = false
    end
end

return module