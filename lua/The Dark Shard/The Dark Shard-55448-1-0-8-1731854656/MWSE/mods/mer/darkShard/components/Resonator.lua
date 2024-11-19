local common = require("mer.darkShard.common")
local logger = common.createLogger("Resonator")
local StaticActivator = require("CraftingFramework").StaticActivator
local Telescope = require("mer.darkShard.components.Telescope")

---@class DarkShard.Resonator.Calibration
---@field red number
---@field green number
---@field blue number

---@class DarkShard.Resonator : DarkShard.Resonator.newParams
---@field data DarkShard.Resonator.refData
local Resonator = {
    object_id = 'afq_resonator_act',
    CALIBRATION_LEVELS = 4,
    CALIBRATION_TIME = 0.5,
}

---@class DarkShard.Resonator.refData
---@field calibration DarkShard.Resonator.Calibration
---@field targetCalibration DarkShard.Resonator.Calibration

---@class DarkShard.Resonator.newParams
---@field reference tes3reference

---@param e DarkShard.Resonator.newParams
---@return DarkShard.Resonator?
function Resonator:new(e)
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
    return setmetatable(self, { __index = Resonator })
end

---@param e { cell?: tes3cell, position?: tes3vector3, distance?: number }
function Resonator.findNearbyResonator(e)
    local resonatorRef = common.findInCell(Resonator.object_id)
    if not resonatorRef then
        logger:error("Failed to find resonator reference")
        return
    end
    if e.cell ~= nil and resonatorRef.cell ~= e.cell then
        logger:error("Resonator is in a different cell")
        return
    end
    if e.position ~= nil and e.distance ~= nil then
        local distance = e.position:distance(resonatorRef.position)
        if distance > e.distance then
            logger:error("Resonator is too far away")
            return
        end
    end
    return Resonator:new({ reference = resonatorRef })
end

function Resonator.getWheelColor(node)
    local wheels = {
        WHEEL1 = "blue",
        WHEEL2 = "green",
        WHEEL3 = "red",
        TUBE1 = "blue",
        TUBE2 = "green",
        TUBE3 = "red",
    }
    return wheels[node.parent.name]
end



function Resonator.doUpdateNodes(sceneNode, phases)
    logger:debug("Updating resonator nodes")
    local data = {
        red = "RED_CRYSTAL",
        green = "GREEN_CRYSTAL",
        blue = "BLUE_CRYSTAL"
    }

    for color, nodeName in pairs(data) do
        local phase = phases[color]
        if phase then
            local parent = sceneNode:getObjectByName(nodeName)
            if parent then
                ---@param node niNode
                for node in table.traverse{parent} do
                    ---@types niKeyframeController
                    local controller = node.controller
                    if controller then
                        logger:debug("Setting phase %s for %s", phase, node.name)
                        node:update{ time = phase, controllers = true }
                    end
                end
                parent:update()
            else
                logger:error("Failed to find node %s", nodeName)
            end
        end
    end
end

function Resonator.getRandomCalibration()
    return {
        red = math.random(2, Resonator.CALIBRATION_LEVELS),
        green = math.random(2, Resonator.CALIBRATION_LEVELS),
        blue = math.random(2, Resonator.CALIBRATION_LEVELS)
    }
end


function Resonator:init()
    self.data.calibration = self.data.calibration or { red = 1, green = 1, blue = 1 }
    self.data.targetCalibration = self.data.targetCalibration or Resonator.getRandomCalibration()
    logger:debug("Target Calibration: red %s, green %s, blue %s",
        self.data.targetCalibration.red, self.data.targetCalibration.green, self.data.targetCalibration.blue)
    self:updateNodes()
    Telescope.updateOffsetData(self:getOffsets())
end

function Resonator:getCalibration()
    return self.data.calibration
end


function Resonator:calibrate(calibration)
    logger:debug("Calibrating resonator")
    logger:debug(" - Previous calibration: red %s, green %s, blue %s",
        self.data.calibration.red, self.data.calibration.green, self.data.calibration.blue)
    local previousCalibration = table.copy(self.data.calibration)
    table.copy(calibration, self.data.calibration)
    logger:debug(" - New calibration: red %s, green %s, blue %s",
        self.data.calibration.red, self.data.calibration.green, self.data.calibration.blue)
    self:animateNodes(calibration, previousCalibration)
    Telescope.updateOffsetData(self:getOffsets())
end


--[[
    Gets the shader offsets based on the calibration.
    Compare the calibration to the target calibration.
    At maximum difference, set the offset to 1.0
    When the calibration is the same as the target, set the offset to 0.0
]]
---@return DarkShard.Resonator.Calibration
function Resonator:getOffsets()
    local calibration = self:getCalibration()
    local target = self.data.targetCalibration
    local offsets = {}
    for key, value in pairs(calibration) do
        local targetValue = target[key]
        local difference = math.abs(value - targetValue)
        local offset = difference / Resonator.CALIBRATION_LEVELS
        offsets[key] = offset
    end
    return offsets
end

--[[
    Get the animation phase for each crystal based on current calibration.
    At minimum calibration, the crystal is at 0.0 phase
    At maximum calibration, the crystal is at 1.0 phase
]]
---@return DarkShard.Resonator.Calibration
function Resonator:getPhases(calibration)
    calibration = calibration or self:getCalibration()
        or { red = 1, green = 1, blue = 1 }
    local phases = {}
    for key, value in pairs(calibration) do
        local phase = (value-1) / (Resonator.CALIBRATION_LEVELS-1)
        phases[key] = phase * 0.9
    end
    return phases
end

function Resonator:updateNodes()
    Resonator.doUpdateNodes(self.reference.sceneNode, self:getPhases())
end

function Resonator:animateNodes(newCalibration, previousCalibration)
    local phases = self:getPhases(newCalibration)
    local previousPhases = self:getPhases(previousCalibration)

    for key, phase in pairs(phases) do
        local previousPhase = previousPhases[key]
        if previousPhase ~= phase then
            local node = self.reference.sceneNode:getObjectByName(key.."_CRYSTAL")
            --get startingPhase from existing entry if it exists
            if common.config.tempData.resonatorAnimatingNodes[node] then
                previousPhase = common.config.tempData.resonatorAnimatingNodes[node].startingPhase
            end
            local interval = Resonator.CALIBRATION_TIME * math.abs(phase - previousPhase)
            common.config.tempData.resonatorAnimatingNodes[node] = {
                startingPhase = previousPhase,
                targetPhase = phase,
                duration = interval,
                timePassed = 0
            }
        end
    end
end

function Resonator:removeResonator()
    local resonatorRef = common.findInCell(Resonator.object_id)
    if not resonatorRef then
        logger:error("Failed to find resonator reference")
        return
    end
    resonatorRef:delete()
    tes3.messageBox("You remove the Chromatic Resonator.")
    tes3.addItem{
        reference = tes3.player,
        item = common.config.static.resonator_misc_id,
    }
end


function Resonator:activate()
    local result = StaticActivator.getLookingAt()
    if result and result.reference == self.reference then
        local node = result.object
        local wheelColor = Resonator.getWheelColor(node)
        if wheelColor then
            logger:debug("Activating resonator wheel")

            local currentValue = self.data.calibration[wheelColor]
            local newValue = currentValue + 1
            if newValue > Resonator.CALIBRATION_LEVELS then
                newValue = 1
            end

            self:calibrate{
                [wheelColor] = newValue
            }
            tes3.messageBox("You adjust the %s crystal on the Chromatic Resonator.", wheelColor)
            return
        end
    end

    tes3ui.showMessageMenu{
        message = "Chromatic Resonator",
        buttons = {
            {
                text = "Remove",
                callback = function()
                    logger:debug("Removing resonator")
                    self:removeResonator()
                end
            }
        },
        cancels = true
    }
end

return Resonator