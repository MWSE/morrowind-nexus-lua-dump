local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local realTimer = require("scripts.proximityTool.realTimer")


local this = {}

---@type table<string, proximityTool.elementSafeContainer>
this.containers = {}


---@class proximityTool.elementSafeContainer
local containerStruct = {}

containerStruct.__index = containerStruct

containerStruct.element = nil
containerStruct.id = nil

---@type {type : integer, data : any}[] 1 - create, 2 - update, 3 - destroy()
containerStruct.commandQueue = nil

containerStruct.valid = true


function containerStruct:create(layout)
    if not layout then return end
    if self.element then
        self:forceDestroy()
    end
    self.element = ui.create(layout)
end


function containerStruct:update()
    if self.element then
        self.element:update()
    end
end


function containerStruct:destroy()
    realTimer.newTimer(0, function ()
        self:forceDestroy()
    end)
end


function containerStruct:forceDestroy()
    if not self.valid then return end
    self.valid = false
    if self.element then
        self.element:destroy()
        self.element = nil
    end
end

function containerStruct:addCommand(commandType, data)
    table.insert(self.commandQueue, {type = commandType, data = data})
end





---@param id string
---@return proximityTool.elementSafeContainer
function this.new(id)
    local container = this.containers[id]
    if container then
        container:destroy()
    end

    container = setmetatable({}, containerStruct)
    container.id = id
    container.valid = true
    container.commandQueue = {}

    this.containers[id] = container

    return container
end


return this