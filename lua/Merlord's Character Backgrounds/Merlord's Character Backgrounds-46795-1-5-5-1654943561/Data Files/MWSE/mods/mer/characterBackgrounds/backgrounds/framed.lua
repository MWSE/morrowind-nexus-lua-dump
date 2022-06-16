local minBounty = 20
local maxBounty = 120
local minInterval = 24
local maxInterval = ( 24 * 4 )


local function calcCrimeInterval()
    return math.random(minInterval, maxInterval)
end
local function calcCrimeValue()
    return math.random(minBounty, maxBounty)
end
local getData = function()
    local data = tes3.player.data.merBackgrounds or {}
    data.framed = data.framed or {
        timeToNextCrime = calcCrimeInterval()
    }
    return data
end

return  {
    id = "framed",
    name = "Framed",
    description = (
        "You got on the wrong side of some people in very powerful positions. " ..
        "Every once in a while, you will get a price on your head for a crime you did not commit. Your life on " ..
        "the run has given you a talent for guile and stealth (+10 to all Stealth Skills)."
    ),
    doOnce = function()
        local stealthSkills = {
            "acrobatics",
            "security",
            "sneak",
            "lightArmor",
            "marksman",
            "shortBlade",
            "handToHand",
            "mercantile",
            "speechcraft",
        }
        for _, skill in ipairs(stealthSkills) do
            tes3.modStatistic({
                reference = tes3.player,
                skill = tes3.skill[skill],
                value = 10
            })
        end

    end,
    callback = function()
        local checkCrime
        local timerInterval = 1
        local function startTimer()
            timer.start{
                type = timer.game,
                duration =  timerInterval,
                callback = checkCrime,
                iterations = -1
            }
        end


        checkCrime = function()
            local data = getData()
            if not tes3.mobilePlayer.inCombat then
                if data.framed.timeToNextCrime <= 0 and tes3.mobilePlayer.bounty <= 300 then
                    --Add bounty
                    local crimeVal = calcCrimeValue()
                    tes3.mobilePlayer.bounty = crimeVal
                    tes3.messageBox("A %s gold bounty has been placed on your head.", crimeVal)

                    --Set time to next bounty
                    local newInterval = calcCrimeInterval()
                    data.framed.timeToNextCrime = newInterval
                    return
                end
            end
            data.framed.timeToNextCrime = data.framed.timeToNextCrime - timerInterval
        end

        startTimer()
    end
}