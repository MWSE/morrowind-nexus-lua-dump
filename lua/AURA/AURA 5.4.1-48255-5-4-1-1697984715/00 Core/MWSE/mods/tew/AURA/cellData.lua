local this = {}
local common = require("tew.AURA.common")

this.cell = nil
this.playerUnderwater = false
this.windoors = {}
this.rainType = {
    [4] = nil,
    [5] = nil
}

local function update(e)
    this.cell = e.cell or tes3.getPlayerCell()
    if not table.empty(this.windoors) then this.windoors = {} end
    if common.cellIsInterior(this.cell) and (common.getInteriorType(this.cell) == "big") then
        this.windoors = common.getWindoors(this.cell)
    end
end

-- Prevent an unwanted splash_sml sound from playing when loading a game
-- from underwater to a non-underwater location.
local function resetPlayerUnderwater(e)
    this.playerUnderwater = false
    update(e)
end

event.register("load", resetPlayerUnderwater)
event.register("loaded", update)
event.register("cellChanged", update)
event.register("weatherChangedImmediate", update)

return this