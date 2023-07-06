local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("ActivatorController")
local Activator = require("mer.joyOfPainting.services.AnimatedActivator")
local ReferenceManager = require("mer.joyOfPainting.services.ReferenceManager")

---@param e activateEventData
local function onActivate(e)
    e.object = e.target.object
    e.dataHolder = e.target

    if e.activator ~= tes3.player then
        return
    end
    for _, activator in pairs(Activator.activators) do
        if activator.isActivatorItem(e) then
            if common.isShiftDown() then
                if activator.onPickup then
                    activator.onPickup(e)
                end
                return
            elseif activator.blockStackActivate and common.isStack(e.target) then
                logger:debug("%s is stack, skip", e.target.object.id)
                return
            else
                logger:debug("%s is activator item, activating", e.target.object.id)
                activator.onActivate(e)
                return true
            end
        end
    end
    logger:debug("No activators found for %s", e.target.object.id)
end
event.register("activate", onActivate)

---@param e equipEventData
local function onEquip(e)
    e.object = e.item
    e.dataHolder = e.itemData
    for _, activator in pairs(Activator.activators) do
        if activator.isActivatorItem(e) then
            activator.onActivate(e)
            return
        end
    end
end
event.register("equip", onEquip)

ReferenceManager.registerReferenceController{
    id = "AnimationActivators",
    requirements = function(_, reference)
        for _, activator in pairs(Activator.activators) do
            if activator.getAnimationGroup ~= nil and activator.isActivatorItem{ target = reference } then
                return true
            end
        end
        return false
    end
}

local function setAnimationStates(e)
    logger:debug("Setting animation states")
    ReferenceManager.iterateReferences("AnimationActivators", function(reference)
        logger:debug("Reference: %s", reference.object.id)
        for _, activator in pairs(Activator.activators) do
            if activator.getAnimationGroup ~= nil and activator.isActivatorItem{ target = reference } then
                logger:debug("is activator: %s", activator.id)
                local animationState = activator.getAnimationGroup(reference)
                if animationState then
                    logger:debug("Setting animation %s for %s", animationState, reference.object.id)
                    tes3.playAnimation{
                        reference = reference,
                        group = animationState,
                        startFlag = tes3.animationStartFlag.immediate,
                        loopCount = 0,
                    }
                    return
                end
            end
        end
    end)
end
event.register("loaded", setAnimationStates)
