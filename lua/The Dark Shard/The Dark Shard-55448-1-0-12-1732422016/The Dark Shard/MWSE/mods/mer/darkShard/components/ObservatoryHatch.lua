local common = require("mer.darkShard.common")
local logger = common.createLogger("ObservatoryHatch")
local Resonator = require("mer.darkShard.components.Resonator")
local ReferenceManager = require("CraftingFramework").ReferenceManager

---@class DarkShard.animation
---@field group number
---@field startFlag? number
---@field sound? string
---@field duration? number
---@field callback? fun(self: DarkShard.ObservatoryHatch)

---@class DarkShard.ObservatoryHatch.refData
---@field openMessageShown boolean
---@field isOpen boolean
---@field calibration? { red: number, blue: number, green: number }

---@class DarkShard.ObservatoryHatch.tempData
---@field animating boolean

---@class DarkShard.ObservatoryHatch.newParams
---@field reference tes3reference

---@class DarkShard.ObservatoryHatch : DarkShard.ObservatoryHatch.newParams
---@field data DarkShard.ObservatoryHatch.refData
---@field tempData DarkShard.ObservatoryHatch.tempData
local ObservatoryHatch = {
    attachNodeName = "ATTACH_RESONATOR",
    ---@type table<string, DarkShard.animation>
    animations = {
        closed = {
            group = tes3.animationGroup.idle,
            startFlag = tes3.animationStartFlag.immediate,
        },
        open = {
            group = tes3.animationGroup.idle2,
            sound = "Door Stone Open",
            duration = 1.5,
            callback = function(self)
                logger:debug("Setting hatch to open")
                self.reference.data.isOpen = true
            end,
        },
        opened = {
            group = tes3.animationGroup.idle3,
            startFlag = tes3.animationStartFlag.immediate,
        },
        close = {
            group = tes3.animationGroup.idle4,
            sound = "Door Stone Close",
            duration = 1.5,
            callback = function(self)
                logger:debug("Setting hatch to closed")
                self.reference.data.isOpen = false
            end
        }
    }
}

--Hatch Ref Manager
ObservatoryHatch.hatchManager = ReferenceManager:new{
    id = "DarkShard:ObservatoryHatch",
    onActivated = function(self, reference)
        logger:debug("Hatch onActivated - setting initial animation")
        ObservatoryHatch:new({ reference = reference }):setInitialAnimation()
    end,
    requirements = function(self, reference)
        return reference.object.id:lower() == common.config.static.observatory_hatch_id
    end
}


---@param e DarkShard.ObservatoryHatch.newParams
---@return DarkShard.ObservatoryHatch?
function ObservatoryHatch:new(e)
    if not e.reference.supportsLuaData then return nil end
    local self = table.copy(e)
    self.data = setmetatable({}, {
        __index = function(t, key)
            return self.reference.data[key]
        end,
        __newindex = function(t, key, value)
            self.reference.data[key] = value
        end
    })
    self.tempData = setmetatable({}, {
        __index = function(t, key)
            return self.reference.tempData[key]
        end,
        __newindex = function(t, key, value)
            self.reference.tempData[key] = value
        end
    })
    setmetatable(self, { __index = ObservatoryHatch })
    return self
end

function ObservatoryHatch:isAnimating()
    return self.tempData.animating
end

function ObservatoryHatch:isOpen()
    return self.reference.data.isOpen
end

function ObservatoryHatch:showOpenMessage()
    if self.data.openMessageShown then return end
    tes3.messageBox("The hatch responds to the Chromatic Resonator.")
    self.data.openMessageShown = true
end

function ObservatoryHatch:setInitialAnimation()
    if self:isOpen() then
        self:animate(self.animations.opened)
    else
        self:animate(self.animations.closed)
    end
end

---@param anim DarkShard.animation
function ObservatoryHatch:animate(anim)
    logger:debug("Animating hatch")
    tes3.playAnimation{
        reference = self.reference,
        group = anim.group,
        loopCount = 0,
        startFlag = anim.startFlag
    }
    logger:debug("Played animation")
    if anim.sound then
        tes3.playSound{
            sound = anim.sound
        }
        logger:debug("Played sound")
    end
    if anim.duration then
        self.tempData.animating = true
        logger:debug("Set animating to true")
        timer.start{
            duration = anim.duration,
            callback = function()
                self.tempData.animating = false
                if anim.callback then
                    logger:debug("Running animation callback")
                    anim.callback(self)
                end
            end
        }
    end
end

function ObservatoryHatch:open()
    self:animate(self.animations.open)
end

function ObservatoryHatch:close()
    self:animate(self.animations.close)
end

function ObservatoryHatch:getAttachNode()
    return self.reference.sceneNode:getObjectByName(self.attachNodeName)
end

function ObservatoryHatch:getAttachPosition()
    local attachNode = self:getAttachNode()
    if not attachNode then
        logger:error("Failed to find attach node %s on %s", self.attachNodeName, self.reference)
        return self.reference.position:copy()
    end
    return attachNode.worldTransform.translation:copy()
end

function ObservatoryHatch:attachResonator()
    local attachNode = self:getAttachNode()
    if not attachNode then
        logger:error("Failed to find attach node %s on %s", self.attachNodeName, self.reference)
        return
    end
    Resonator.attachResonator(attachNode, self.reference)
end

function ObservatoryHatch:hasResonator()
    return Resonator.findNearbyResonator{
        distance = 10,
        position = self:getAttachPosition(),
        cell = self.reference.cell
    }
end


function ObservatoryHatch:activate()
    if not self:isOpen() then
        return
    end
    if self.tempData.animating then
        logger:debug("Hatch is animating")
        return
    end
    local showMenu = function()
        return self:isOpen()
        and (not self:hasResonator())
    end
    if not showMenu() then
        return
    end

    local message = "Mysterious Hatch"
    tes3ui.showMessageMenu{
        message = message,
        buttons = {
            {
                text = "Place Chromatic Resonator",
                enableRequirements = function()
                    return ObservatoryHatch.playerHasResonator()
                end,
                tooltipDisabled = "You do not have a Chromatic Resonator.",
                callback = function()
                    logger:debug("Placing resonator")
                    self:attachResonator()
                end
            },
        },
        cancels = true
    }
end

function ObservatoryHatch.playerHasResonator()
    return tes3.player.object.inventory:contains(common.config.static.resonator_misc_id)
end

return ObservatoryHatch