local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("ImageBuilder")
local Image = require("mer.joyOfPainting.services.Image.Image")

local ImageBuilder = {}

---@param data JOP.Image
function ImageBuilder:new(data)
    local image = Image:new(data)
    local commands = {}
    return setmetatable({
        image = image,
        commands = commands,
    }, self)
end

function ImageBuilder.__index(tbl, key)
    local image = rawget(tbl, "image")
    local commands = rawget(tbl, "commands")
    local command = image[key]
    if command then
        logger:debug("Adding step '%s' to commands queue", key)
        return function(self)
            table.insert(commands, {
                name = key,
                command = function(next)
                    command(image, next)
                end
            })
            return self
        end
    else
        return getmetatable(tbl)[key]
    end
end

--[[
    Defome a custom step. Takes the next step as a parameter,
        so it can be called manually. if this custom step does
        call the next step, it should return true.
]]
function ImageBuilder:step(name, customCallback)
    if not customCallback then return self end
    logger:debug("adding custom step '%s' to commands queue", name)
    table.insert(self.commands, {
        name = name,
        command = function(next)
            local didCallNext = false
            if customCallback then
                didCallNext = customCallback(next)
            end
            if not didCallNext then
                next()
            end
        end
    })
    return self
end

--[[
    Register a custom build step.
]]
---@param name string The name of the custom step
---@param command function The function to execute for this step
function ImageBuilder:registerStep(name, command)
    if self[name] then
        logger:error("Cannot register step '%s', it already exists", name)
        return self
    end
    logger:debug("Registering step '%s'", name)
    self[name] = function(self)
        self:step(name, command)
        return self
    end
    return self
end


function ImageBuilder:build(buildCallback)
    logger:debug("Building image")
    local commands = self.commands
    local image = self.image
    local function executeCommands()
        local command = table.remove(commands, 1)
        if command then
            logger:debug("Executing command: %s", command.name)
            command.command(executeCommands)
        else
            image:finish(function()
                if buildCallback then
                    logger:debug("Calling buildCallback")
                    buildCallback(image)
                end
                logger:debug("Image built")
            end)
        end
    end
    executeCommands()
    return image
end

return ImageBuilder