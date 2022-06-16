local function getData()
    local data = tes3.player.data.merBackgrounds
    data.greyOne = data.greyOne or {
        nightBuff = false,
        dayBuff = false
    }
    return data
end

return {
    id = "greyOne",
    name = "Grey Child",
    description = (
        "You were born with a pale complexion and strangely sharp teeth. " ..
        "Animals are uneasy around you, and sunlight makes your skin tingle. " ..
        "Were you cursed? Perhaps your mother or father was a vampire? " ..
        "Regardless, you feel most at home in the cold and dark. During the night (between the hours of 6pm and 6am), " ..
        "the following skills increase by 5: Sneak, Athletics, Acrobatics,  Mysticism, " ..
        "Illusion, and Destruction. However, during the day, your Endurance and Willpower are reduced by 10. "
    ),
    callback = function()
        local function toggleNightBuff(data)

            local val = data.greyOne.nightBuff and -5 or 5
            data.greyOne.nightBuff = not data.greyOne.nightBuff
            local vampSkills = {
                tes3.skill.sneak,
                tes3.skill.athletics,
                tes3.skill.acrobatics,
                tes3.skill.mysticism,
                tes3.skill.illusion,
                tes3.skill.destruction
            }
            for _, skill in ipairs(vampSkills) do
                tes3.modStatistic({
                    reference = tes3.player,
                    skill = skill,
                    value = val
                })
            end
        end

        local function toggleDayBuff(data)
            local val = data.greyOne.dayBuff and 10 or -10
            data.greyOne.dayBuff = not data.greyOne.dayBuff
            local vampStats = {
                tes3.attribute.endurance,
                tes3.attribute.willpower
            }
            for _, attribute in ipairs(vampStats) do
                tes3.modStatistic({
                    reference = tes3.player,
                    attribute = attribute,
                    value = val
                })
            end
        end
        local function greyOneCheckTime()
            local data = getData()
            if not data.currentBackground == "greyOne" then return end

            local hour = tes3.worldController.hour.value

            if hour >= 18 or hour < 6 then

                --add buff
                if not data.greyOne.nightBuff then
                    toggleNightBuff(data)
                end

                --remove debuff
                if data.greyOne.dayBuff then
                    toggleDayBuff(data)
                end

            else
                if data.greyOne.nightBuff then
                    toggleNightBuff(data)
                end

                if not data.greyOne.dayBuff then
                    toggleDayBuff(data)
                end
            end
        end
        timer.start{type = timer.real, iterations = -1, duration = 1, callback = greyOneCheckTime }
    end
}