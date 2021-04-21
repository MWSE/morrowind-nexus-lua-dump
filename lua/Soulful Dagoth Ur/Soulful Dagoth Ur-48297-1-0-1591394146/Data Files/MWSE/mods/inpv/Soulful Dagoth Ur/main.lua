--[[ 
-- Soulful Dagoth Ur
-- by inpv, 2020
]]

local tooltipsComplete = include("Tooltips Complete.interop")

local tooltipData = {
    { id = "dagoth_ur_2", description = "The soul of Voryn Dagoth, leader of the Sixth House, keeper of the Tools of Kagrenac and friend to Indoril Nerevar." },
}

local function initialized()
    local obj = tes3.getObject("dagoth_ur_2")
    if (obj) then 
       obj.soul = 1000 
    end

    if tooltipsComplete then
        for _, data in ipairs(tooltipData) do
            tooltipsComplete.addTooltip(data.id, data.description, data.itemType)
        end
    end
end

event.register("initialized", initialized)