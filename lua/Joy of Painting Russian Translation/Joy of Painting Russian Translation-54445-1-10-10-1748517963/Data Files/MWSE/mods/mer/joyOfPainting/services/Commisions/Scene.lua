--[[
    Object for holding information about what scene is going to be painted
    - Subject
    - Setting
]]

---@class JOP.Scene
local Scene = {}

function Scene.new()
    local self = setmetatable({}, { __index = Scene })
    self:initialize()
    return self
end

function Scene:initialize()
    self.type = nil
    self.name = nil
    self.description = nil
end

