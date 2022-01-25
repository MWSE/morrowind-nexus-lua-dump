
local function onInitialise()
    if tes3.isModActive("TheMidnightOil.ESP") then
        require("mer.midnightOil.candle")
        require("mer.midnightOil.lantern")
        require("mer.midnightOil.oil")
        require("mer.midnightOil.merchant")
        require("mer.midnightOil.tooltips")
        require("mer.midnightOil.toggle")
        require("mer.midnightOil.nightDay")
    end
end

event.register("initialized", onInitialise)

require("mer.midnightOil.mcm")