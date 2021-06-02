local states = {
    withdraw_mild = {
        name = "Skooma Withdrawal",
        min = 0,
        max = 1,
        spellEffects = {
            {
                id = tes3.effect.drainAttribute,
                attribute = tes3.attribute.agility,
                range = tes3.effectRange.self,
                min = 20,
                max = 20
            },
            {
                id = tes3.effect.drainAttribute,
                attribute = tes3.attribute.intelligence,
                range = tes3.effectRange.self,
                min = 20,
                max = 20
            },
        },
    }
}
for id, tbl in pairs(states) do
    tbl.id = id
end

return states