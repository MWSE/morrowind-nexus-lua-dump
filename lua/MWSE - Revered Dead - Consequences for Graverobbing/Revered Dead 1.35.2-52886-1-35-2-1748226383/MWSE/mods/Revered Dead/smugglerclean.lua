local common = require("Revered Dead.common")
local config = require("Revered Dead.config")
local strings = require("Revered Dead.strings")

-- Cleaning grave goods

common.log:debug("Successfully called grave goods cleansing file.")



local itemDatas = {}

for _, stack in pairs(tes3.player.object.inventory) do
    if stack.object.supportsLuaData == true and stack.variables then
        for _, vars in pairs(stack.variables) do
            if vars and vars.data and vars.data.reveredDead and (vars.data.reveredDead.isGraveGoods == true) then
                common.log:debug("Found a grave good, adding to cleaning menu: " .. stack.object.id)
                local vars = stack.variables or { false }
                itemDatas[stack.object] = vars[1]
            end
        end
    end
end

tes3ui.showInventorySelectMenu{
    title = strings.cleaningMenuText,
    leaveMenuMode = false,
    noResultsText = strings.nothingtoClean,
    filter = function(e)
        local data = e.itemData or false
        return itemDatas[e.item] == data
    end,
    callback = common.showCleaningMenu
}

