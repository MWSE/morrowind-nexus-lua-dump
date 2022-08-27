local getData = function()
    local data = tes3.player.data.merBackgrounds or {}
    data.agoraphobic = data.agoraphobic or {
        buffed = false,
        debuffed = false
    }
    return data
end

return {
    id = "agoraphobic",
    name = "Agoraphobia",
    description = (
        "You are terrified of open spaces. When outdoors, you suffer a " ..
        "-5 penalty to all skills. When inside, you get +5 to all skills. "
    ),
    callback = function()


        local function modSkills(value)
            for _, skill in pairs(tes3.skill) do
                tes3.modStatistic({
                    reference = tes3.player,
                    skill = skill,
                    value = value
                })
            end
        end

        local function cellChanged(e)
            local data = getData()
            if data.currentBackground == "agoraphobic" then
                --Indoors
                if not e.cell.isInterior then
                    --remove buff
                    if data.agoraphobic.buffed then
                        data.agoraphobic.buffed = false
                        modSkills(-5)
                    end
                    --add debuff
                    if not data.agoraphobic.debuffed then
                        data.agoraphobic.debuffed = true
                        modSkills(-5)
                    end
                else
                    --remove debuff
                    if data.agoraphobic.debuffed then
                        data.agoraphobic.debuffed = false
                        modSkills(5)
                    end
                    --add buff
                    if not data.agoraphobic.buffed then
                        data.agoraphobic.buffed = true
                        modSkills(5)
                    end
                end
            else
            --Background not selected, remove any effects
                --remove debuff
                if data.agoraphobic.debuffed then
                    data.agoraphobic.debuffed = false
                    modSkills(5)
                end
                --remove buff
                if data.agoraphobic.buffed then
                    data.agoraphobic.buffed = false
                    modSkills(-5)
                end
            end
        end
        cellChanged({ cell = tes3.getPlayerCell() })

        event.register("cellChanged", cellChanged)
        event.unregister("cellChanged", cellChanged)
    end
}