local common = require("mer.darkShard.common")
local logger = common.createLogger("lunarDecay")
local LunarDecay = require("mer.darkShard.components.LunarDecay")

---@param e magicCastedEventData
event.register("magicCastedEventData", function(e)
    if e.source and LunarDecay.isAntidote(e.source) then
        tes3.messageBox("Лунное Разложение ослабевает.")
    end
end)

event.register("simulate", LunarDecay.update)

