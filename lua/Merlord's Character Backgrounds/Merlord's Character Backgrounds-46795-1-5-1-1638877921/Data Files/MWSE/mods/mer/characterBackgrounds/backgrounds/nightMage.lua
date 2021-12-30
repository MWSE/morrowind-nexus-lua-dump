return {
    id = "nightMage",
    name = "Night Mage",
    description = (
        "You were born with a magickal aptitude that has affinity for the night. " ..
        "At night (between the hours of 6 PM and 6 AM), you possess a 20% bonus to your Intelligence, " ..
        "but during the day you suffer a 20% penalty to your Intelligence."
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