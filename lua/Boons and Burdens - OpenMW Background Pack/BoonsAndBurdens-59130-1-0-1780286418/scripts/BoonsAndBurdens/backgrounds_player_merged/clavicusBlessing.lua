---@omw-context player
---@diagnostic disable: assign-type-mismatch
---@diagnostic disable: undefined-field
local I = require("openmw.interfaces")
local self = require("openmw.self")
local time = require("openmw_aux.time")
local core = require("openmw.core")
local ambient = require("openmw.ambient")

local period = 1

I.CharacterTraits.addTrait {
    id = "BaB_clavicusBlessing",
    type = "background",
    name = "Blessed by Clavicus",
    description = (
        "You struck a bargain with Clavicus Vile and received exactly what you asked for - " ..
        "a silver tongue, a head for numbers, an instinct for value. " ..
        "You had neglected to specify that you wanted to keep any of it. " ..
        "The Prince found that very amusing.\n" ..
        "\n" ..
        "+15 Speechcraft\n" ..
        "+30 Mercantile\n" ..
        "> All your gold drops on the ground"
    ),
    doOnce = function()
        local merc = self.type.stats.skills.mercantile(self)
        merc.base = merc.base + 30
    end,
    onLoad = function()
        local inv = self.type.inventory(self)
        time.runRepeatedly(
            function()
                local gold = inv:find("gold_001")
                if gold then
                    ambient.playSound("item gold down")
                    core.sendGlobalEvent("BoonsAndBurdens_dropItems", {
                        cell = self.cell.id,
                        pos = self.position,
                        ---@diagnostic disable-next-line: assign-type-mismatch
                        items = { gold }
                    })
                end
            end,
            period
        )
    end
}
