local common = require("OperatorJack.MagickaExpanded.common")
local log = require("OperatorJack.MagickaExpanded.utils.logger")

--- A model describing a distribution setting. For the given spell to be distributed, all filter values must be true. To ignore a filter, do not set a value for it.
---@class MagickaExpanded.Distribution.DistributionModel
---@field spell tes3spell | string The spell or spell ID that should be distributed.
---@field filterRaceId string? The race ID to filter for.
---@field filterClassId string? The class ID to filter for.
---@field filterActorId string? The npc or creature ID to filter for.
---@field filterFunction (fun(reference: tes3reference): boolean) | nil Using the reference being calculated for, determine your own filter criteria. Return true to consider the filter passed.
---@field source string The source of the configuration. Your mod name or other identifier. Used for logging purposes.

--- Distribution module for configuring spell distribution mechanics.
---@class MagickaExpanded.Distribution
local this = {}

---@type MagickaExpanded.Distribution.DistributionModel[]
this.distributionConfigurations = {}

--[[ Registers one or more distribution configurations to be distributed throughout the game. Configurations contain filters for determining distribution, which are processed as each NPC/creature reference is loaded in game.]]
---@param items MagickaExpanded.Distribution.DistributionModel[]
this.registerDistributions = function(items)
    for _, config in ipairs(items) do table.insert(this.distributionConfigurations, config) end
end

---@param e referenceActivatedEventData
local function onReferenceActivatedForConfigDistribution(e)
    if (not e.reference.mobile) then return end
    if (not e.reference.object.objectType ~= tes3.objectType.npc and
        not e.reference.object.objectType ~= tes3.objectType.creature) then return end

    local baseObject = e.reference.baseObject;

    for _, config in ipairs(this.distributionConfigurations) do
        if (config.filterRaceId and not baseObject.race.id == config.filterRaceId) then
            return
        end
        if (config.filterClassId and not baseObject.class.id == config.filterClassId) then
            return
        end
        if (config.filterActorId and not baseObject.id == config.filterActorId) then return end
        if (config.filterFunction and config.filterFunction(e.reference) ~= true) then return end

        if (e.reference.object.spells:contains(config.spell) == false) then
            tes3.addSpell({reference = e.reference, spell = config.spell, updateGUI = false})
            log:debug("Adding spell {0} on {1} from source {2}", config.spell,
                      e.reference.object.id, config.source)

        end
    end
end

---@param e referenceActivatedEventData
local function onReferenceActivatedForVendorDistribution(e)
    if (not e.reference.mobile) then return end
    if (e.reference.object.aiConfig.offersSpells ~= true) then return end

    e.reference.data.OJ_ME = e.reference.data.OJ_ME or {}
    e.reference.data.OJ_ME.distribution = e.reference.data.OJ_ME.distribution or {}

    for i = 1, #common.distribution do
        ---@type tes3spell
        local spell = common.distribution[i]

        if (e.reference.data.OJ_ME.distribution[spell.id] == true and
            e.reference.object.spells:contains(spell) == false) then
            e.reference.data.OJ_ME.distribution[spell.id] = nil
            log:debug("Expected spell {0} on {1} but found none, so resetting.", spell.id,
                      e.reference.object.id)
        end

        if (e.reference.data.OJ_ME.distribution[spell.id] == nil) then
            if (math.random(0, 100) < 4) then
                e.reference.data.OJ_ME.distribution[spell.id] = true
                tes3.addSpell({reference = e.reference, spell = spell, updateGUI = false})
                log:debug("Added spell {0} to {1}.", spell.id, e.reference.object.id)

            else
                e.reference.data.OJ_ME.distribution[spell.id] = false
            end

        end
    end
end

--[[
	Registers the distribution events. Configures events such that spells are distributed based on the provided distribution configurations.
]]
this.registerEvent = function()
    event.register(tes3.event.referenceActivated, onReferenceActivatedForVendorDistribution)
    event.register(tes3.event.referenceActivated, onReferenceActivatedForConfigDistribution)
end

return this
