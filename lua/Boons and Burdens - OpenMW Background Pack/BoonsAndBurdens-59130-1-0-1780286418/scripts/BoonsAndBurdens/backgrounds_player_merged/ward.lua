---@omw-context player
---@diagnostic disable: undefined-field
---@diagnostic disable: assign-type-mismatch
local I = require("openmw.interfaces")
local self = require("openmw.self")
local core = require("openmw.core")
local time = require("openmw_aux.time")

local period = 5

I.CharacterTraits.addTrait {
    id = "BaB_ward",
    type = "background",
    name = "Ward",
    description = (
        "You were never much of a fighter, and the faint ancestor spirit that " ..
        "has followed you since childhood was never much of one either. " ..
        "But it was always there, and that counted for something. " ..
        "While others trained their bodies or learned to hurl fire, " ..
        "you poured yourself into conjuration - the one craft that felt like home. " ..
        "You and the spirit have looked after each other for as long as you can remember. " ..
        "Old habits are hard to break.\n" ..
        "\n" ..
        "+15 Conjuration\n" ..
        "+2x Max Magicka\n" ..
        "-15 Endurance\n" ..
        "> All weapon skills and destruction are capped at 25\n" ..
        "> You start with a warding glove"
    ),
    doOnce = function()
        local endurance = self.type.stats.attributes.endurance(self)
        endurance.base = endurance.base - 15

        self.type.spells(self):add("bab_ward")
        core.sendGlobalEvent(
            "BoonsAndBurdens_addItems",
            { {
                player = self,
                itemId = "bab_helpinghand",
                count = 1,
                autoEquip = true,
            } }
        )
    end,
    onLoad = function()
        local skills = self.type.stats.skills
        local offensiveSkills = {
            skills.destruction(self),
            skills.axe(self),
            skills.bluntweapon(self),
            skills.handtohand(self),
            skills.longblade(self),
            skills.marksman(self),
            skills.shortblade(self),
            skills.spear(self),
        }
        time.runRepeatedly(
            function()
                for _, skill in ipairs(offensiveSkills) do
                    if skill.base > 25 then
                        skill.base = 25
                    end
                end
            end,
            period
        )
    end
}
