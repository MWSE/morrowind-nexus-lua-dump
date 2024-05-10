local Async = {}

local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("Async")

function Async.execute(command, callback)
    logger:trace("Executing command: %s", command)
    local executor = os.createProcess{
        command = command,
        async = true
    }
    local function waitForExecutor(e)
        logger:trace("waiting for executor")
        if executor.errorCode and executor.errorCode ~= 0 then
            logger:error("Error executing command. Error Code: %s", executor.errorCode)
            logger:error("Output: %s", executor:getOutput())
            event.unregister("enterFrame", waitForExecutor)
        end
        local output = executor:getOutput()
        if output and output ~= "" then
            logger:info(output)
        end
        if executor.ready then
            logger:trace("Executor ready")
            event.unregister("enterFrame", waitForExecutor)
            if callback then
                logger:trace("Calling callback")
                callback()
            end
        end
    end
    event.register("enterFrame", waitForExecutor)
end

return Async