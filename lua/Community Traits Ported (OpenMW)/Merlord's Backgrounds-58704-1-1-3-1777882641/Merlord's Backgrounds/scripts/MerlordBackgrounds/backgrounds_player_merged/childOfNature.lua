local I = require("openmw.interfaces")
local self = require("openmw.self")
local time = require("openmw_aux.time")

local traitType = require("scripts.MerlordBackgrounds.utils.traitTypes").background

local period = 1
local inWild = self.cell
    and not self.cell:hasTag("NoSleep")
    and (self.cell.isExterior or self.cell.isQuasiExterior)

local function updateAllStats(amount)
    local skills = self.type.stats.skills
    local direction = inWild and 1 or -1
    for _, skill in pairs(skills) do
        skill(self).base = skill(self).base + amount * direction
    end
end

local function checkCell()
    local currCellStatus = self.cell
        and not self.cell:hasTag("NoSleep")
        and (self.cell.isExterior or self.cell.isQuasiExterior)

    if currCellStatus == inWild then return end

    inWild = not inWild
    updateAllStats(10)
end

I.CharacterTraits.addTrait {
    id = "childofnature",
    type = traitType,
    name = "Child of Nature",
    description = (
        "You feel most at home out in the wilderness, as far from other people as possible.\n" ..
        "\n" ..
        "+5 to all skills while outdoors in the wild\n" ..
        "-5 to all skills while in civilization or indoors"
    ),
    doOnce = function()
        updateAllStats(5)
    end,
    onLoad = function()
        time.runRepeatedly(checkCell, period)
    end
}
