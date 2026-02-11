local self = require("openmw.self")

function DoSoultrap(attack)
    local activeSpells = self.type.activeSpells(self)
    activeSpells:add({
        -- "soul trap" instead of "umbra's hunger" for foolproofing
        -- in case someone decides to edit base enchantment for some reason
        id = "soul trap",
        ---@diagnostic disable-next-line: assign-type-mismatch
        effects = { 0 },
        caster = attack.attacker,
    })

    Log("Umbra Sword debug message!\n" ..
        "Victim: " .. self.recordId)
end
