local config = require("kindi.signpost fast travel.config")

local this = {}

local diseases = {
    "ataxia",
    "helljoint",
    "rattles",
    "rockjoint",
    "rust chancre",
    "droops",
    "collywobbles",
    "chills",
    "swamp fever",
    "yellow tick"
}

this.penalties = function(ref, curPos, tar, travelType)
    --ref = activator
    --tar = target activation
    --curPos = target position before travelling
    local cellsTravelled = (curPos:distance(ref.position:copy()) / 8196)
    if not ref.cell.isInterior then
        tes3.runLegacyScript {reference = ref, command = "fixme"}
    end

    local goldCount = tes3.getItemCount {reference = ref, item = "gold_001"}
    local reckless = (travelType == "reckless")
    local cautious = (travelType == "cautious")
    if travelType == nil then
        reckless = nil
        cautious = nil
    end

    if config.penalty and not cautious then
        tes3.modStatistic {
            reference = ref.mobile,
            name = "health",
            current = math.max((-1 * (ref.mobile.health.current - 1)), (-3 * cellsTravelled)),
            limit = true
        }
        tes3.modStatistic {reference = ref.mobile, name = "fatigue", current = -30 * cellsTravelled, limit = true}
    end

    if config.timeAdvance then
        local travelTime =
            tes3.findGMST("fTravelTimeMult").value / math.max(1, (cellsTravelled - ref.mobile.speed.current / 5))
        travelTime = (curPos:distance(ref.position:copy()) / travelTime)

        if reckless then
            travelTime = travelTime * 0.5
        elseif cautious then
            travelTime = travelTime * 2
        end

        tes3.advanceTime {hours = travelTime, resting = cautious or false}
    end

    if reckless then
        ref.mobile:exerciseSkill(tes3.skill.athletics, cellsTravelled)
        if math.random(100) <= cellsTravelled * 3 then
            tes3.addSpell {reference = ref, spell = diseases[math.random(#diseases)]}
        end
        if math.random(100) <= cellsTravelled * 5 then
            tes3.removeItem {reference = ref, item = "gold_001", count = goldCount * 0.05, playSound = false}
            tes3.messageBox("You lost some gold on your way here..")
        end
    elseif cautious then
        ref.mobile:exerciseSkill(tes3.skill.sneak, cellsTravelled)
        if math.random(100) <= cellsTravelled * 5 then
            tes3.addSpell {reference = ref, spell = diseases[math.random(#diseases)]}
        end
        if math.random(100) <= cellsTravelled * 3 then
            tes3.removeItem {reference = ref, item = "gold_001", count = goldCount * 0.05, playSound = false}
            tes3.messageBox("You lost some gold on your way here..")
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
end

return this
