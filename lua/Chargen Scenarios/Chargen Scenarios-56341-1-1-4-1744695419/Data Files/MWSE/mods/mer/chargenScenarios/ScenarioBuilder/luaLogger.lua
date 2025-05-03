--[[
    Logs lua code templates to a custom file
]]

local luaLogger = {}


---@param params { outputFile: string }
function luaLogger.new(params)
    local self = {
        outputFile = io.open(params.outputFile, "w"),
    }

    function self:info(output)
        if self.outputFile then
            self.outputFile:write(output .. "\n")
            self.outputFile:flush()
        else
            print(output)
        end
    end

    return self
end

return luaLogger