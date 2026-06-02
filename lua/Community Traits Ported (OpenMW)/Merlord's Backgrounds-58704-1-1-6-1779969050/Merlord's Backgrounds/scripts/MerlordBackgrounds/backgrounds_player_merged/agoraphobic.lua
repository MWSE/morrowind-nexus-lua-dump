local I = require("openmw.interfaces")
local self = require("openmw.self")
local time = require("openmw_aux.time")

local traitType = require("scripts.MerlordBackgrounds.utils.traitTypes").background

local period = 1
local inExterior = self.cell and (self.cell.isExterior or self.cell.isQuasiExterior)

local function updateStats(amount)
    local skills = self.type.stats.skills
    local direction = inExterior and -1 or 1
    for _, skill in pairs(skills) do
        skill(self).base = skill(self).base + amount * direction
    end
end

local function checkCell()
    local currCellStatus = self.cell
        and (self.cell.isExterior or self.cell.isQuasiExterior)

    if currCellStatus == inExterior then return end

    inExterior = not inExterior
    updateStats(10)
end

I.CharacterTraits.addTrait {
    id = "agoraphobic",
    type = traitType,
    name = "Agoraphobic",
    description = (
        "You are terrified of open spaces. You feel helpless when outdoors, but gain confidence back when indoors.\n" ..
        "\n" ..
        "+5 to all skills while indoors\n" ..
        "-5 to all skills while outdoors"
    ),
    doOnce = function()
        updateStats(5)
    end,
    onLoad = function()
        time.runRepeatedly(checkCell, period)
    end
}
