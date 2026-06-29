-- assignment/aiSuppression.lua
---@omw-context local
-- Small local-script helper for temporarily suppressing AI stats/say audio while
-- SDP owns an actor's pose. Kept out of interactionSeeker.lua so the local
-- seeker stays an event/flow orchestrator. Lives in assignment/ because it protects
-- SDP-owned actor assignments across sitting, sleeping, and station presentation.

local M = {}

local function statValue(stat)
    if not stat then return 0 end
    local value = tonumber(stat.modified or stat.base or 0)
    if value == nil then value = tonumber(stat.base or 0) end
    return value or 0
end

function M.create(env)
    ---@type fun(...: any)
    local rawDebugLog = env and env.debugLog or function() end
    local function debugLog(...)
        if rawDebugLog then
            local args = { ... }
            local parts = {}
            for i = 1, #args do
                local value = args[i]
                parts[i] = tostring(value == nil and "" or value)
            end
            rawDebugLog(table.concat(parts, " "))
        end
    end

    local state = {
        deltas = nil,
        mode = nil,
        core = env and env.core or nil,
        types = env and env.types or nil,
        selfModule = env and env.selfModule or nil,
        debugLog = debugLog,
    }

    function state:stopSayIfActive(label)
        local core = self.core
        local selfModule = self.selfModule
        if not (core and core.sound and core.sound.isSayActive and core.sound.stopSay and selfModule) then return end
        local ok, active = pcall(core.sound.isSayActive, selfModule)
        if ok and active then
            pcall(core.sound.stopSay, selfModule)
            self.debugLog(label or "interaction suppress say")
        end
    end

    function state:apply(mode)
        if self.deltas then return end
        local types = self.types
        local selfModule = self.selfModule
        if not (types and types.Actor and types.Actor.stats and types.Actor.stats.ai and selfModule) then return end

        local statNames
        if mode == "sleep" then
            statNames = { "hello", "fight", "alarm" }
        elseif mode == "station_presenter" then
            statNames = { "hello" }
        else
            return
        end

        local aiStats = types.Actor.stats.ai
        local penalty = 10000
        local deltas = {}

        for _, statName in ipairs(statNames) do
            local getter = aiStats[statName]
            if getter then
                local ok, stat = pcall(getter, selfModule)
                if ok and stat then
                    local current = statValue(stat)
                    local delta = -(math.max(penalty, current + penalty))
                    local okSet = pcall(function()
                        stat.modifier = (tonumber(stat.modifier) or 0) + delta
                    end)
                    if okSet then
                        deltas[statName] = delta
                    end
                end
            end
        end

        local count = 0
        for _ in pairs(deltas) do count = count + 1 end
        if count == 0 then
            self.debugLog("interaction suppress ai stats failed (mode=" .. tostring(mode) .. ")")
            return
        end

        self.deltas = deltas
        self.mode = mode
        self.debugLog(
            (mode == "sleep" and "sleep suppress ai stats" or "station suppress ai hello")
            .. " (count=" .. tostring(count) .. ", penalty=" .. tostring(penalty) .. ")"
        )
    end

    function state:clear(reason)
        if not self.deltas then return end
        local types = self.types
        local selfModule = self.selfModule
        if not (types and types.Actor and types.Actor.stats and types.Actor.stats.ai and selfModule) then
            self.deltas = nil
            self.mode = nil
            return
        end

        local aiStats = types.Actor.stats.ai
        local restored = 0
        for statName, delta in pairs(self.deltas) do
            local getter = aiStats[statName]
            if getter then
                local ok, stat = pcall(getter, selfModule)
                if ok and stat then
                    local okSet = pcall(function()
                        stat.modifier = (tonumber(stat.modifier) or 0) - delta
                    end)
                    if okSet then restored = restored + 1 end
                end
            end
        end

        local mode = self.mode
        self.deltas = nil
        self.mode = nil
        self.debugLog(
            (mode == "station_presenter" and "station restore ai hello" or "sleep restore ai stats")
            .. " (restored=" .. tostring(restored) .. ", reason=" .. tostring(reason or "clear") .. ")"
        )
    end

    return state
end

return M
