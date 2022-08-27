local getData = function()
    local data = tes3.player.data.merBackgrounds or {}
    data.childOfNature = data.childOfNature or {
        buffed = false,
        debuffed = false
     }
    return data
end

local function modSkills(value)
    for _, skill in pairs(tes3.skill) do
        tes3.modStatistic({
            reference = tes3.player,
            skill = skill,
            value = value
        })
    end
end

return {
    id = "childOfNature",
    name = "Child of Nature",
    description = (
        "You feel most at home out in the wilderness, as far from other people as possible. " ..
        "You get +5 to all skills while outdoors in the wild, and -5 to all skills while " ..
        "in civilisation (towns, settlements etc). "
    ),
    callback = function()
        local function cellChanged(e)
            local data = getData()
            if data.currentBackground == "childOfNature" then
                --In town
                if e.cell.restingIsIllegal then
                    --remove buff
                    if data.childOfNature.buffed then
                        data.childOfNature.buffed = false
                        modSkills(-5)
                    end
                    --add debuff
                    if not data.childOfNature.debuffed then
                        data.childOfNature.debuffed = true
                        modSkills(-5)
                    end
                else
                --Not in town
                    --remove debuff
                    if data.childOfNature.debuffed then
                        data.childOfNature.debuffed = false
                        modSkills(5)
                    end

                    --outside
                    if not e.cell.isInterior then
                        --add buff
                        if not data.childOfNature.buffed then
                            data.childOfNature.buffed = true
                            modSkills(5)
                        end
                    else
                        if data.childOfNature.buffed then
                            data.childOfNature.buffed = false
                            modSkills(-5)
                        end
                    end
                end
            else
            --Background not selected, remove any effects
                --remove debuff
                if data.childOfNature.debuffed then
                    data.childOfNature.debuffed = false
                    modSkills(5)
                end
                --remove buff
                if data.childOfNature.buffed then
                    data.childOfNature.buffed = false
                    modSkills(-5)
                end
            end
        end

        cellChanged{ cell = tes3.getPlayerCell()}
        event.unregister("cellChanged", cellChanged)
        event.register("cellChanged", cellChanged)

    end
}