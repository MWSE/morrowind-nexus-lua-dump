local tooltipsComplete = include("Tooltips Complete.interop")
local common = require("mer.midnightOil.common")

local oilDescription = "A flask of oil used to refill oil lamps."
local candleDescription = "A fresh candle to replace in a lantern or candlestick."

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