local config = require("celediel.ASinkingFeeling.config")
local common = require("celediel.ASinkingFeeling.common")

-- Helper Functions
local function getTotalArmourClass(actor)
    local armourClass = 0

    -- get armour level for each equipped piece of armour
    -- light = 0, medium = 1, heavy = 2, plus one so light armour is affected
    if actor and actor.equipment then
        for stack in tes3.iterate(actor.equipment) do
            local item = stack.object
            if item.objectType == tes3.objectType.armor then
                armourClass = armourClass + item.weightClass + 1
            end
        end
    end

    return armourClass
end

local function getTotalEquipmentWeight(actor)
    local weight = 0

    if actor and actor.equipment then
        for stack in tes3.iterate(actor.equipment) do
            local item = stack.object
            weight = weight + item.weight
        end
    end

    return weight
end

-- Event functions
local function sinkInWater(e)
    -- shortcut refs
    local mobile = e.mobile
    local ref = e.reference
    local actor = ref.object
    local waterLevel = mobile.cell.waterLevel
    local headHeight = mobile.position.z + mobile.height * 0.8

    -- no creatures
    if mobile.actorType == tes3.actorType.creature then return end

    -- if configured to be player only, bail if not player
    if config.playerOnly and mobile.actorType ~= tes3.actorType.player then return end

    local downPull = 0
    local debugStr = ""

    -- calculate the down-pull with the configured formula
    if config.mode == common.modes.equippedArmour then
        local armourClass = getTotalArmourClass(actor)
        downPull = (config.downPullMultiplier / 10) * armourClass
        debugStr = string.format("Pulling %s down by %s using equipped armour mode (%s total armour class)",
            ref.id, downPull, armourClass)

    elseif config.mode == common.modes.allEquipment then
        local totalWeight = getTotalEquipmentWeight(actor)
        -- doubling this keeps this formula somewhat uniform with armour class @ multiplier 100
        downPull = ((config.downPullMultiplier / 100) * totalWeight) * 2
        debugStr = string.format("Pulling %s down by %s using equipment weight mode (%s total equipment weight)",
            ref.id, downPull, totalWeight)

    elseif config.mode == common.modes.encumbrancePercentage then
        local encumbrance = mobile.encumbrance
        -- tripling this keeps this formula somewhat uniform with armour class @ multiplier 100
        downPull = (config.downPullMultiplier * encumbrance.normalized) * 3
        debugStr = string.format("Pulling %s down by %s using encumbrance mode (%s/%s = %s encumbrance)",
            ref.id, downPull, encumbrance.current, encumbrance.base, encumbrance.normalized)
    end

    -- reset if levitating or mod disabled
    if mobile.levitate > 0 or not config.enabled then downPull = 0 end

    -- only if mostly underwater to stop pseudo-waterwalking when jumping into water
    if headHeight <= waterLevel then
        if downPull ~= 0 then
            -- finally add down-pull from configured formula to tes3.mobilePlayer.velocity.z to simulate being pulled down
            mobile.velocity.z = -downPull
            if config.debug then
                common.log(debugStr)
            end
        elseif mobile.velocity.z <= 0 then
            -- reset velocity removing of armour in water is accounted for
            mobile.velocity.z = 0
        end
    end
end

local function onInitialized()
    event.register("calcSwimSpeed", sinkInWater)
    common.log("Successfully initialized!")
end

event.register("initialized", onInitialized)
event.register("modConfigReady", function() mwse.mcm.register(require("celediel.ASinkingFeeling.mcm")) end)