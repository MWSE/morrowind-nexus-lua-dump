local tooltipsComplete = include("Tooltips Complete.interop")
local common = require("mer.midnightOil.common")

local oilDescription = "Фляга с маслом, используемая для заправки масляных ламп."
local candleDescription = "Свежая свеча для замены в фонаре или подсвечнике."

for id, _ in pairs(common.oil) do
    if tooltipsComplete then
        tooltipsComplete.addTooltip(id, oilDescription)
    end
end

for id, _ in pairs(common.candle) do
    if tooltipsComplete then
        tooltipsComplete.addTooltip(id, candleDescription)
    end
end