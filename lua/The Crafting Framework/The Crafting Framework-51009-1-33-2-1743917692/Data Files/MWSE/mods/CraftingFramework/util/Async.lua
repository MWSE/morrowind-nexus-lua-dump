local Async = {}

---@param object any The object to build
function Async:new(object)
    object = object or {}
    local commands = {}
    return setmetatable({
        object = object,
        commands = commands,
    }, self)
end

function Async.__index(tbl, key)
    local object = rawget(tbl, "object")
    local commands = rawget(tbl, "commands")
    local command = object[key]
    if command then
        --logger:debug("Adding step '%s' to commands queue", key)
        return function(self)
            table.insert(commands, {
                name = key,
                command = function(next)
                    command(object, next)
                end
            })
            return self
        end
    else
        return getmetatable(tbl)[key]
    end
end

--[[
    Define a custom step. Takes the next step as a parameter,
    so it can be called manually. If this custom step does
    call the next step, it should return true.
]]
function Async:step(name, customCallback)
    if not customCallback then return self end
    --logger:debug("Adding custom step '%s' to commands queue", name)
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
    Register a custom build step that can be added to the queue in a builder pattern
]]
---@param name string The name of the custom step
---@param command function The function to execute for this step
function Async:registerStep(name, command)
    if self[name] then
        --logger:error("Cannot register step '%s', it already exists", name)
        return self
    end
    --logger:debug("Registering step '%s'", name)
    self[name] = function(self)
        self:step(name, command)
        return self
    end
    return self
end

---@param e { type: integer, duration: number }
function Async:wait(e)
    local timerType = e.type
    local duration = e.duration
    if not duration then
        --logger:error("No duration provided for wait command")
        return self
    end
    --logger:debug("Adding wait command for %s seconds", duration)
    table.insert(self.commands, {
        name = "wait",
        command = function(next)
            timer.start{
                duration = duration,
                type = timerType,
                callback = next
            }
        end
    })
end

function Async:start(buildCallback)
    --logger:debug("Building object")
    local commands = self.commands
    local object = self.object
    local function executeCommands()
        local command = table.remove(commands, 1)
        if command then
            --logger:debug("Executing command: %s", command.name)
            command.command(executeCommands)
        else
            if object.finish then
                object:finish(function()
                    if buildCallback then
                        --logger:debug("Calling buildCallback")
                        buildCallback(object)
                    end
                    --logger:debug("Object built")
                end)
            elseif buildCallback then
                buildCallback(object)
                --logger:debug("Object built")
            end
        end
    end
    executeCommands()
    return object
end

return Async