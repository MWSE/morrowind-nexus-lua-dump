local common = require("mer.darkShard.common")
local logger = common.createLogger("ControlPanel")
local ReferenceManager = require("CraftingFramework").ReferenceManager
local Telescope = require("mer.darkShard.components.Telescope")

---@class DarkShard.ControlPanel.newParams
---@field reference tes3reference

---@class DarkShard.ControlPanel.refData
---@field isOpen boolean

---@class DarkShard.ControlPanel.tempData
---@field animating boolean

---@class DarkShard.ControlPanel : DarkShard.ControlPanel.newParams
---@field data DarkShard.ControlPanel.refData
---@field tempData DarkShard.ControlPanel.tempData
local ControlPanel = {
    objectId = "afq_panel",
    animations = {
        closed = {
            group = tes3.animationGroup.idle,
            startFlag = tes3.animationStartFlag.immediate,
        },
        open = {
            group = tes3.animationGroup.idle2,
            duration = 1.5,
            callback = function(self)
                logger:debug("Setting panel to open")
                self.reference.data.isOpen = true
            end,
        },
        opened = {
            group = tes3.animationGroup.idle3,
            startFlag = tes3.animationStartFlag.immediate,
        },
        close = {
            group = tes3.animationGroup.idle4,
            duration = 1.5,
            callback = function(self)
                logger:debug("Setting panel to closed")
                self.reference.data.isOpen = false
            end
        }
    }
}

ControlPanel.panelManager = ReferenceManager:new{
    id = "DarkShard:ControlPanel",
    onActivated = function(self, reference)
        logger:debug("Setting initial animation")
        ControlPanel:new({ reference = reference }):setInitialAnimation()
    end,
    requirements = function(self, reference)
        return reference.object.id:lower() == ControlPanel.objectId
    end
}

---@param e DarkShard.ControlPanel.newParams
---@return DarkShard.ControlPanel?
function ControlPanel:new(e)
    if not e.reference.supportsLuaData then return nil end
    if not ControlPanel.isControlPanel(e.reference) then return nil end
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
    setmetatable(self, { __index = ControlPanel })
    return self
end

function ControlPanel:isAnimating()
    return self.tempData.animating
end

function ControlPanel:isOpen()
    return self.reference.data.isOpen
end

function ControlPanel:setInitialAnimation()
    if self:isOpen() then
        self:animate(self.animations.opened)
    else
        self:animate(self.animations.closed)
    end
end

---@param anim DarkShard.animation
function ControlPanel:animate(anim)
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


function ControlPanel:open()
    self:animate(self.animations.open)
end

function ControlPanel:close()
    self:animate(self.animations.close)
end


function ControlPanel:activate()
    if self:isAnimating() or not self:isOpen() then
        tes3.messageBox("Панель управления не реагирует.")
        return
    end
    --Find nearest telescope and activate it
    local telescope = Telescope.getNearbyTelescope()
    if not telescope then
        logger:error("No telescope found")
        tes3.messageBox("Здесь нет телескопа, который можно было бы активировать.")
        return
    end
    logger:debug("Activating telescope")
    Telescope.activate{
        isObservatory = true,
        telescopeRef = telescope,
     }
end

function ControlPanel.spawn(supportRef)
    if not supportRef.supportsLuaData then
        logger:error("Reference does not support Lua data")
        return
    end
    if supportRef.data.afq_hasPanel then
        logger:debug("Panel already spawned")
        return
    end
    local ref = tes3.createReference{
        object = ControlPanel.objectId,
        position = supportRef.position:copy(),
        orientation = supportRef.orientation:copy(),
        cell = supportRef.cell
    }
    ControlPanel.panelManager:addReference(ref)
    ControlPanel:new{ reference = ref }:setInitialAnimation()
    supportRef.data.afq_hasPanel = true
    supportRef.modified = true
end

function ControlPanel.isControlPanel(reference)
    return reference.object.id:lower() == ControlPanel.objectId
end

---@param e { position: tes3vector3 }
---@return DarkShard.ControlPanel?
function ControlPanel.getNearbyPanel(e)
    logger:debug("Finding nearby panel")
    local position = e.position or tes3.player.position
    local closestPanel
    local closestDistance
    ControlPanel.panelManager:iterateReferences(function(ref)
        logger:debug("Checking panel %s", ref)
        local distance = ref.position:distance(position)
        if ref.cell ~= tes3.player.cell then return end
        if (closestDistance == nil) or (distance < closestDistance) then
            closestPanel = ref
            closestDistance = distance
        end
    end)
    logger:debug("Closest panel is %s", closestPanel)
    return ControlPanel:new{ reference = closestPanel }
end

return ControlPanel