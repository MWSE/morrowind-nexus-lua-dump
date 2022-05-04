local doUnitTests = false
local UnitWind = include("unitwind")
if not UnitWind then return end
UnitWind = UnitWind.new{
    enabled = doUnitTests,
    highlight = true,
    exitAfter = false
}
UnitWind:start("Crafting Framework: On Initialised Tests")
UnitWind:test("Canary", function()
    UnitWind:expect(true).toBe(true)
end)

UnitWind:finish()
