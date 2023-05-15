---@class Test
local Test = {}

---@return Test
function Test.new()
    local test = {}
    setmetatable(test, { __index = Test })
    return test
end

---@class MyUnitWind: UnitWind
---@field approxExpect fun(self: UnitWind, result: any, epsilon: number?) : UnitWind.expects

---@param shutdown boolean?
function Test.Run(shutdown)
    local combat = require("longod.DPSTooltips.combat")
    local logger = require("longod.DPSTooltips.logger")

    local unitwind = require("unitwind").new {
        enabled = true,
    } ---@cast unitwind MyUnitWind

    -- add equality for floating point error
    ---@param result any #The result to check
    ---@param epsilon number?
    ---@return UnitWind.expects #An object with functions to perform expectations on the result
    function unitwind.approxExpect(self, result, epsilon)
        local expectTypes = {
            toBe = function(expectedResult, isNot)
                if not self.enabled then return false end
                if (type(result) == "number") then
                    if (combat.NearyEqual(result, expectedResult, epsilon)) == isNot then
                        error(string.format("Expected value to %sbe %s, got: %s.", isNot and "not " or "", expectedResult,
                            result))
                    end
                else
                    -- fallback
                    return self:expect(result).toBe(expectedResult, isNot)
                end
                return true
            end,
        }
        ---@type UnitWind.expects
        local expects = {}
        ---@type UnitWind.expects.NOT
        expects.NOT = {}
        for expectType, func in pairs(expectTypes) do
            expects[expectType] = function(...)
                return func(..., false)
            end
            expects.NOT[expectType] = function(...)
                return func(..., true)
            end
        end
        return expects
    end

    require("longod.DPSTooltips.combat"):RunTest(unitwind)
    require("longod.DPSTooltips.effect"):RunTest(unitwind)
    require("longod.DPSTooltips.dps"):RunTest(unitwind)

    if shutdown then
        logger:debug("Shutdown")
        os.exit()
    end
end

return Test
