local config = require("mer.characterBackgrounds.config")
local interop = require("mer.characterBackgrounds.interop")

local function calcCrimeInterval()
    return math.random(config.mcm.framed_minInterval, config.mcm.framed_maxInterval)
end
local function calcCrimeValue()
    return math.random(config.mcm.framed_minBounty, config.mcm.framed_maxBounty)
end

---@class CharacterBackgrounds.FramedData
---@field timeToNextCrime? number #Time until next bounty is placed on your head

---@class CharacterBackgrounds.Config.mcm
local mcmDefault = {
    framed_minBounty = 20,
    framed_maxBounty = 120,
    framed_minInterval = 24,
    framed_maxInterval = ( 24 * 4 ),
}
table.copymissing(config.mcm, mcmDefault)

interop.addBackground{
    id = "framed",
    name = "Жертва клеветы",
    description = (
        "Вы перешли дорогу очень влиятельным людям. " ..
        "Время от времени за вашу голову назначают награду по обвинению в преступлении, которое вы не совершали. " ..
        "Жизнь в бегах научила вас хитрости и скрытности (+10 ко всем воровским навыкам)."
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
    onLoad = function(self)
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
            ---@type CharacterBackgrounds.FramedData
            if not tes3.mobilePlayer.inCombat then
                if not self.data.timeToNextCrime then
                    self.data.timeToNextCrime = calcCrimeInterval()
                end
                if self.data.timeToNextCrime <= 0 and tes3.mobilePlayer.bounty <= 300 then
                    --Add bounty
                    local crimeVal = calcCrimeValue()
                    tes3.mobilePlayer.bounty = (tes3.mobilePlayer.bounty or 0) + crimeVal
                    tes3.messageBox("За вашу голову назначена награда в %s золотых.", crimeVal)

                    --Set time to next bounty
                    local newInterval = calcCrimeInterval()
                    self.data.timeToNextCrime = newInterval
                    return
                end
            end
            self.data.timeToNextCrime = self.data.timeToNextCrime - timerInterval
        end
        startTimer()
    end,
    createMcm = function(self, template)
        ---Add MCM page
        local page = template:createSideBarPage("Жертва клеветы")
        page.description = self:getDescription()
        local bountyCategory = page:createCategory("Награда за голову")
        bountyCategory:createSlider{
            label = "Минимум: %s золота",
            description = "Минимальная награда за вашу голову.",
            min = 10,
            max = 10000,
            step = 1,
            jump = 10,
            variable = mwse.mcm.createTableVariable{
                id = "framed_minBounty",
                table = config.mcm,
            },
        }
        bountyCategory:createSlider{
            label = "Максимум: %s золота",
            description = "Максимальная награда за вашу голову.",
            min = 10,
            max = 10000,
            step = 1,
            jump = 10,
            variable = mwse.mcm.createTableVariable{
                id = "framed_maxBounty",
                table = config.mcm,
            },
        }

        local intervalCategory = page:createCategory("Интервал")
        intervalCategory:createSlider{
            label = "Минимум: %s Часов",
            description = "Минимальное время между наградами.",
            min = 1,
            max = 100,
            step = 1,
            jump = 1,
            variable = mwse.mcm.createTableVariable{
                id = "framed_minInterval",
                table = config.mcm,
            },
        }
        intervalCategory:createSlider{
            label = "Максимум: %s Часов",
            description = "Максимальное время между наградами.",
            min = 1,
            max = 100,
            step = 1,
            jump = 1,
            variable = mwse.mcm.createTableVariable{
                id = "framed_maxInterval",
                table = config.mcm,
            },
        }
    end
}
