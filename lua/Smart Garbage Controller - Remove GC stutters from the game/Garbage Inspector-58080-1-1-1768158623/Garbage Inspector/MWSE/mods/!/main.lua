local garbageSources = {}

local _register = event.register

event.register = function(eventType, callback, options)
    local info = debug.getinfo(2, "Sl")
    local source = (info.source .. ":" .. info.currentline):lower()
    source = source:gsub("^%.\\data files\\mwse\\", "")
    local function wrapped(e)
        collectgarbage("stop")
        local count = collectgarbage("count")
        callback(e)
        local newCount = collectgarbage("count")
        local diff = math.max(newCount - count,0)
        garbageSources[source] = (garbageSources[source] or 0) + diff
        collectgarbage("restart")
    end
    _register(eventType, wrapped, options)
end

local time = 0
local msgTimer = 0

---@param e simulateEventData
local function controller(e)
    time = time + e.delta
    msgTimer = msgTimer + e.delta

    if msgTimer >= 1.0 then
        msgTimer = msgTimer - 1.0
        tes3.messageBox(("Remaining test time: %d"):format(math.max(0, math.ceil(120 - time))))
    end

    if time > 120 then
        -- Helper functions to sort the table
            local rows = {}
            for source, amount in pairs(garbageSources) do
                rows[#rows + 1] = { source = source, amount = amount }
            end

        table.sort(rows, function(a, b)
            return a.amount > b.amount -- largest -> smallest
        end)

        mwse.log("Garbage Sources (largest -> smallest)")
        mwse.log(string.format("%8s | %s", "KB", "source"))
        mwse.log(string.rep("-", 80))

        for _, row in ipairs(rows) do
            mwse.log(string.format("%8.2f | %s", row.amount, row.source))
        end

        event.unregister("simulate", controller)
        --[[table.sort(garbageSources,)
        local inspect = require("inspect")
        mwse.log("Garbage Sources")
        mwse.log(inspect(garbageSources))]]
        -- Try to stop Morrowind
        os.createProcess({ command = [[taskkill /IM "Morrowind.exe" /F]] })
        -- If that did not work:
        tes3.messageBox({
            message = "Test is now complete. Please exit Morrowind and find the report in the MWSE log file",
            buttons = {"Ok"}
        }

        )
    end
end
event.register("simulate", controller)
