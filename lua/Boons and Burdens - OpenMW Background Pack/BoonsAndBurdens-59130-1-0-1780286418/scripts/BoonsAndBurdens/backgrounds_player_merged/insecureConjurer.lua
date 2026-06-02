---@omw-context player
---@diagnostic disable: assign-type-mismatch
---@diagnostic disable: undefined-field
local I = require("openmw.interfaces")
local self = require("openmw.self")
local core = require("openmw.core")

I.CharacterTraits.addTrait {
    id = "BaB_insecureConjurer",
    type = "background",
    name = "Insecure Conjurer",
    description = (
        "The talent was there from the start - tutors said as much, and for once they were right. " ..
        "You could pull things from the other side before most students had learned the first binding words. " ..
        "Keeping them there was another matter. Bound creatures sense weakness in their master, " ..
        "and yours always found it quickly. Somewhere along the way the failures began to outweigh the reassurances, " ..
        "and they have never quite balanced out since.\n" ..
        "\n" ..
        "+20 Conjuration\n" ..
        "-15 Willpower\n" ..
        "-5 Luck\n" ..
        "> Your summons have a chance to turn against you"
    ),
    doOnce = function()
        local conj = self.type.stats.skills.conjuration(self)
        conj.base = conj.base + 20
        local will = self.type.stats.attributes.willpower(self)
        will.base = will.base - 15
        local luck = self.type.stats.attributes.luck(self)
        luck.base = luck.base - 5
    end,
    onLoad = function()
        core.sendGlobalEvent("BoonsAndBurdens_registerInsecureConjurer", self)
    end
}
