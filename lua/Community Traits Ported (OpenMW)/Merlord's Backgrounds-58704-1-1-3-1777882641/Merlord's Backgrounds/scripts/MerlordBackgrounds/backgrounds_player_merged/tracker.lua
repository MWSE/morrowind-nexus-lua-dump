local I = require("openmw.interfaces")
local self = require("openmw.self")
local time = require("openmw_aux.time")

local traitType = require("scripts.MerlordBackgrounds.utils.traitTypes").background

local period = 1
local inWild = self.cell
    and not self.cell:hasTag("NoSleep")
    and (self.cell.isExterior or self.cell.isQuasiExterior)

local function updateBuffs(amount)
    local speed = self.type.stats.attributes.speed(self)
    local direction = inWild and 1 or -1
    speed.base = speed.base + amount * direction

    local spells = self.type.spells(self)
    if inWild then
        spells:add("mer_bg_tracker_a")
    else
        spells:remove("mer_bg_tracker_a")
    end
end

local function checkCell()
    local currCellStatus = self.cell
        and not self.cell:hasTag("NoSleep")
        and (self.cell.isExterior or self.cell.isQuasiExterior)

    if currCellStatus == inWild then return end

    inWild = not inWild
    updateBuffs(10)
end

I.CharacterTraits.addTrait {
    id = "tracker",
    type = traitType,
    name = "Tracker",
    description = (
        "As a seasoned tracker, you can read signs and disturbances left by animals to find their location. "..
        "You also know the lay of the land, and can move quickly through uneven terrain.\n" ..
        "\n" ..
        "> When outside in wilderness:\n" ..
        "+10 Speed\n" ..
        "+100 pts Detect Animal ability"
    ),
    doOnce = function()
        if inWild then
            updateBuffs(10)
        end
    end,
    onLoad = function()
        time.runRepeatedly(checkCell, period)
    end
}
