local lib = require("Flin.lib")

local EValue = lib.EValue
local log = lib.log


---@class FlinInterop
---@field strategies table<EStrategyPhase,AiStrategyPhase[]>
local this = {}

-- constructor
function this:new()
    ---@type FlinInterop
    local newObj = {
        strategies = {}
    }
    self.__index = self
    setmetatable(newObj, self)

    -- add default strategies
    -- phase 1 first
    newObj:registerStrategy(require("Flin.ai.phase1first").balanced())
    newObj:registerStrategy(require("Flin.ai.phase1first").defensive())
    newObj:registerStrategy(require("Flin.ai.phase1first").aggressive())

    -- phase 1 second
    newObj:registerStrategy(require("Flin.ai.phase1second").balanced())
    newObj:registerStrategy(require("Flin.ai.phase1second").aggressive())

    -- phase 2 first
    newObj:registerStrategy(require("Flin.ai.phase2first").random())
    newObj:registerStrategy(require("Flin.ai.phase2first").aggressive())
    newObj:registerStrategy(require("Flin.ai.phase2first").defensive())

    -- phase 2 second
    newObj:registerStrategy(require("Flin.ai.phase2second").minmax())

    return newObj
end

-- singleton
---@type FlinInterop
local instance = nil
---@return FlinInterop
function this.getInstance()
    if instance == nil then
        instance = this:new()
    end
    return instance
end

-- register strategies
---@param strategy AiStrategyPhase
function this:registerStrategy(strategy)
    -- get phase
    local phase = strategy.phase
    -- insert into map
    if not self.strategies[phase] then
        self.strategies[phase] = {}
    end
    table.insert(self.strategies[phase], strategy)

    log:debug("Registered strategy %s for phase %s", strategy.name, phase)
end

-- choose a strategy
---@param phase EStrategyPhase
---@param handle mwseSafeObjectHandle
---@return AiStrategyPhase
function this.chooseStrategy(phase, handle)
    local interop = this.getInstance()

    local strategies = interop.strategies[phase]
    assert(strategies, "No strategies found for phase " .. phase)

    -- go through all strategies and call evaluate, store the results in a map
    local results = {}
    for i, strategy in ipairs(strategies) do
        results[strategy] = strategy.evaluate(handle)
    end

    -- normalize probabilities
    local sum = 0
    for i, strategy in ipairs(strategies) do
        sum = sum + results[strategy]
    end
    -- normalize
    for i, strategy in ipairs(strategies) do
        results[strategy] = results[strategy] / sum

        log:trace("Strategy %s: probability: %s", strategy.name, results[strategy])
    end

    -- choose a strategy based on cumulative probabilities
    local r = math.random()
    local cumulative = 0
    for i, strategy in ipairs(strategies) do
        cumulative = cumulative + results[strategy]
        if r <= cumulative then
            log:debug("+ Chose strategy %s for phase %s", strategy.name, phase)
            return strategy
        end
    end

    -- should never happen
    assert(false, "No strategy chosen")
    ---@diagnostic disable-next-line: return-type-mismatch
    return nil
end

return this
