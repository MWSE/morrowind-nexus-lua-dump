local self = require("openmw.self")
local storage = require("openmw.storage")
local core = require("openmw.core")

local settings = storage.playerSection("SettingsSneakFatigueDrain")

local encStrMult = core.getGMST("fEncumbranceStrMult")

local function onUpdate(dt)
    if not self.controls.sneak then return end

    local notMoving = self.type.getCurrentSpeed(self) == 0
    if notMoving and not settings:get("drainWhileNotMoving") then return end

    local baseDrain = settings:get("baseDrain")

    local sneak = self.type.stats.skills.sneak(self)
    local sneakDrain = sneak.modified * settings:get("sneakMod")

    local enc  = self.type.getEncumbrance(self)
    local strength = self.type.stats.attributes.strength(self)
    local carryweight = strength.modified * encStrMult
    local encDrain = enc / carryweight * settings:get("encumbranceMod")

    local drain = (baseDrain + sneakDrain + encDrain) * dt
    if settings:get("logging") then
        print(
            "==========\n" ..
            "Base drain:  " .. tostring(baseDrain) .. "\n" ..
            "Sneak drain: " .. tostring(sneakDrain) .. "\n" ..
            "Enc drain:   " .. tostring(encDrain) .. "\n" ..
            "Drain/sec:   " .. tostring(baseDrain + sneakDrain + encDrain) .. "\n" ..
            "Drain/frame: " .. tostring(drain)
        )
    end
    if drain < 0 then return end

    local fatigue = self.type.stats.dynamic.fatigue(self)
    fatigue.current = math.max(0, fatigue.current - drain)
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    }
}
