local config = require("kindi.signpost fast travel.config")
local i18n = mwse.loadTranslations("kindi.signpost fast travel")
local this = {}

local diseases = {"ataxia", "helljoint", "rattles", "rockjoint", "rust chancre", "droops", "collywobbles", "chills",
                  "swamp fever", "yellow tick"}

this.penalties = function(ref, curPos, tar, travelType, CELL)
    -- ref = activator
    -- tar = target activation
    -- curPos = target position before travelling
    local cellsTravelled = math.floor(curPos:distance(ref.position:copy()) / 8196)

    local goldCount = tes3.getItemCount {
        reference = ref,
        item = "gold_001"
    }

    local reckless = (travelType == "Reckless")
    local cautious = (travelType == "Cautious")

    local fatiguePen = 0
    local timePen = 0
    local goldPen = 0
    local healthPen = 0
    local skillIncrease = i18n("main.wordNone")
    local disease = i18n("main.wordNone")

    if config.timeAdvance then
        local travelTime = tes3.findGMST("fTravelTimeMult").value /
                               math.max(1, (cellsTravelled - ref.mobile.speed.current / 5))
        travelTime = (curPos:distance(ref.position:copy()) / travelTime)

        if reckless then
            travelTime = travelTime * 0.5
        elseif cautious then
            travelTime = travelTime * 6
        end

        tes3.advanceTime {
            hours = travelTime,
            resting = false
        }
        timePen = travelTime
    end

    if config.penalty then
        fatiguePen = -1 * math.random(28, 32) * cellsTravelled
        healthPen = math.max((-1 * (ref.mobile.health.current - 1)), (-3 * cellsTravelled))

        if cautious then
            fatiguePen = math.abs(fatiguePen)
            healthPen = math.abs(healthPen)
        end

        tes3.modStatistic {
            reference = ref.mobile,
            name = "health",
            current = healthPen,
            limit = true
        }
        tes3.modStatistic {
            reference = ref.mobile,
            name = "fatigue",
            current = fatiguePen,
            limit = true
        }
    end

    if reckless then
        ref.mobile:exerciseSkill(tes3.skill.athletics, cellsTravelled)
        skillIncrease = tes3.findGMST("sSkillAthletics").value

        if math.random(100) <= cellsTravelled * 3 then
            disease = diseases[math.random(#diseases)]
            tes3.addSpell {
                reference = ref,
                spell = disease
            }
        end
        if math.random(100) <= cellsTravelled * 10 then
            goldPen = goldCount * 0.05
            tes3.removeItem {
                reference = ref,
                item = "gold_001",
                count = goldPen,
                playSound = false
            }
        end
    elseif cautious then
        ref.mobile:exerciseSkill(tes3.skill.sneak, cellsTravelled)
        skillIncrease = tes3.findGMST("sSkillSneak").value

        if math.random(100) <= cellsTravelled * 10 then
            disease = diseases[math.random(#diseases)]
            tes3.addSpell {
                reference = ref,
                spell = disease
            }
        end
        if math.random(100) <= cellsTravelled * 3 then
            goldPen = goldCount * 0.05
            tes3.removeItem {
                reference = ref,
                item = "gold_001",
                count = goldPen,
                playSound = false
            }
        end
    end

    --[[check if pc is vampire, cannot be under sunlight otherwise you die (needs testing)
	if ref.baseObject.head.vampiric and (tes3.worldController.hour.value > 6 and tes3.worldController.hour.value < 20) then
        tes3.modStatistic {
            reference = ref.mobile,
            name = "health",
            current = -5 * ( travelTime * 3600),
        }
	end]]

    if config.showStats then
        local msg = tes3.messageBox {
            message = i18n("main.journeySummary", {CELL, travelType, timePen, healthPen, fatiguePen, goldPen,
                                                   disease:gsub("^%a", string.upper), skillIncrease}),
            buttons = {tes3.findGMST("sOK").value}
        }

        for child in table.traverse(msg.children) do
            child.wrapText = true
            child.justifyText = "center"
        end
        msg:updateLayout()
    end
end

return this
