local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("FieldEaselActivator")
local Easel = require("mer.joyOfPainting.items.Easel")
local Activator = require("mer.joyOfPainting.services.AnimatedActivator")

local function activateEasel(e)
    logger:debug("Activating Easel")
    local easel = Easel:new(e.target)
    if not easel then
        logger:error("Failed to create Easel")
        return
    end
    local buttons = Easel.getActivationButtons()
    logger:debug("Showing message menu")
    tes3ui.showMessageMenu{
        message = e.target.object.name,
        buttons = buttons,
        cancels = true,
        callbackParams = { reference = e.target}
    }
end

--Unpacked static version of field easel
Activator.registerActivator{
    id = "mer_joyOfPainting_fieldEasel",
    onActivate = activateEasel,
    isActivatorItem = function(e)
        return Easel:new(e.target) ~= nil
    end,
    blockStackActivate = true,
    getAnimationGroup = function(reference)
        local easel = Easel:new(reference)
        if easel then
            return easel:getCurrentAnimation()
        end
    end
}

---@param e activateEventData
local function activateMiscEasel(e)
    tes3ui.showMessageMenu{
        message = e.target.object.name,
        buttons = {
            {
                text = "Unpack",
                callback = function()
                    local id = e.target.object.id:lower()
                    local miscEaselConfig = config.miscEasels[id]
                    if miscEaselConfig then
                        logger:debug("replacing with activator")
                        local activatorEasel = tes3.createReference{
                            object = miscEaselConfig.id,
                            position = e.target.position,
                            orientation = e.target.orientation,
                            cell = e.target.cell
                        }
                        logger:debug("Unpacking easel")
                        Activator.playActivatorAnimation{
                            reference = activatorEasel,
                            group = Easel.animationGroups.unpacking,
                            nextAnimation = Easel.animationGroups.unpacked.group,
                            sound = "Wooden Door Open 1",
                            duration = 1.4
                        }
                        logger:debug("Deleting misc easel")
                        e.target:delete()
                    end
                end
            },
            {
                text = "Pick Up",
                callback = function()
                    logger:debug("Picking up misc easel")
                    common.pickUp(e.target)
                end
            }
        },
        cancels = true,
        callbackParams = { reference = e.target}
    }
end

--Packed misc version of field easel
Activator.registerActivator{
    onActivate = activateMiscEasel,
    isActivatorItem = function(e)
        if e.target and tes3ui.menuMode() then
            logger:debug("Menu mode, skip")
            return false
        end
        if not e.target then
            return false
        end

        ---@type JOP.Easel
        local easel = Easel.getEaselFromMiscId(e.target.object.id:lower())
        if easel and easel.doesPack then
            logger:debug("is Misc Field Easel: true")
            return true
        end
        logger:debug("is Misc Field Easel: false")
        return false
    end,
    blockStackActivate = true
}
