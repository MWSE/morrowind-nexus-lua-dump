---@omw-context player
---@diagnostic disable: assign-type-mismatch
---@diagnostic disable: undefined-field
local I = require("openmw.interfaces")
local self = require("openmw.self")
local time = require("openmw_aux.time")
local ambient = require("openmw.ambient")

local period = 1
local visitedNamedCells = {
    [""] = true,
}
local cellsPerBonus = 3
local cellCount = 0

I.CharacterTraits.addTrait {
    id = "BaB_cartographer",
    type = "background",
    name = "Cartographer",
    description = (
        "You were never built for the road. You went anyway. " ..
        "Unseen coastlines, passes without names, places that existed on no map you had ever found - " ..
        "these were enough to keep you moving long after common sense said to stop. " ..
        "Every new horizon taught you something; every illness you picked up along the way " ..
        "was simply the cost of the lesson. You have caught a great many things out there. You always do.\n" ..
        "\n" ..
        "+10 Athletics\n" ..
        "-10 Strength\n" ..
        "+50% Common and Blight Disease Weakness\n" ..
        "> For every " .. tostring(cellsPerBonus) .. " visited unqiue locations you get +1 to intelligence"
    ),
    doOnce = function()
        local str = self.type.stats.attributes.strength(self)
        str.base = str.base - 10
        local athletics = self.type.stats.skills.athletics(self)
        athletics.base = athletics.base + 10
        ---@diagnostic disable-next-line: param-type-mismatch
        self.type.spells(self):add("bab_cartographer")
    end,
    onLoad = function()
        time.runRepeatedly(
            function()
                if not self.cell
                    or not self.cell.isExterior
                    or self.cell.name == ""
                    or visitedNamedCells[self.cell.name]
                then
                    return
                end

                visitedNamedCells[self.cell.name] = true
                cellCount = cellCount + 1
                ambient.playSound("item book up")

                local cellsUntilBonus = cellCount % cellsPerBonus
                if cellsUntilBonus == 0 then
                    local int = self.type.stats.attributes.intelligence(self)
                    int.base = int.base + 1
                    ambient.playSound("skillraise")
                    self:sendEvent("ShowMessage", {
                        message = "The map in your head grows clearer.\n" ..
                            "Your Intelligence increased to " .. tostring(int.base) .. "."
                    })
                else
                    self:sendEvent("ShowMessage", {
                        message = ("A new place worth remembering.\n" ..
                            "Your mind feels sharper for it. " ..
                            "(%d/%d)"):format(cellsUntilBonus, cellsPerBonus)
                    })
                end
            end,
            period
        )
    end
}

local function onLoad(data)
    if not data then return end
    visitedNamedCells = data.visitedNamedCells or visitedNamedCells
    cellCount = data.cellCount or cellCount
end

local function onSave()
    return {
        visitedNamedCells = visitedNamedCells,
        cellCount = cellCount,
    }
end

return {
    engineHandlers = {
        onLoad = onLoad,
        onSave = onSave,
    },
}
