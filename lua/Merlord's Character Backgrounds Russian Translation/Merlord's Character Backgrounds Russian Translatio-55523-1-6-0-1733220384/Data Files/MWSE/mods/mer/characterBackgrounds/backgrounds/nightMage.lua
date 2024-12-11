return {
    id = "nightMage",
    name = "Ночной маг",
    description = (
        "Вы родились с магическим даром, который усиливается в ночное время. " ..
        "Ночью (с 6 вечера до 6 утра), вы получаете +20% к интеллекту, " ..
        "но в дневное время ваш интеллект снижается на 20%."
    ),
    callback = function()

        local getData = function()
            local data = tes3.player.data.merBackgrounds
            data.nightMage = data.nightMage or {}
            return data
        end

        local function nightMageCheckTime()
            if tes3.menuMode() then return end

            local data = getData()
            if not data.currentBackground == "nightMage" then return end

            local hour = tes3.worldController.hour.value
            local pINT = tes3.mobilePlayer.intelligence

            if hour >= 18 or hour < 6 then
                if data.nightMage.nightBuff ~= true then
                    data.nightMage.nightActive = true


                    --Remove debuff
                    if data.nightMage.multiplier then
                        tes3.modStatistic({
                            reference = tes3.player,
                            attribute = tes3.attribute.intelligence,
                            value = -(data.nightMage.multiplier)
                        })
                    end

                    --add buff
                    data.nightMage.multiplier = pINT.base * 0.2
                    tes3.modStatistic({
                        reference = tes3.player,
                        attribute = tes3.attribute.intelligence,
                        value = data.nightMage.multiplier
                    })
                end
            else
                if data.nightMage.nightActive ~= false then

                    data.nightMage.nightActive = false

                    --Remove buff

                    if data.nightMage.multiplier then
                        tes3.modStatistic({
                            reference = tes3.player,
                            attribute = tes3.attribute.intelligence,
                            value = -(data.nightMage.multiplier)
                        })
                    end

                    --add debuff
                    data.nightMage.multiplier = -(pINT.base * 0.2)
                    tes3.modStatistic({
                        reference = tes3.player,
                        attribute = tes3.attribute.intelligence,
                        value = data.nightMage.multiplier
                    })
                end
            end
        end
        timer.start{type = timer.real, iterations = -1, duration = 1, callback = nightMageCheckTime }
    end
}