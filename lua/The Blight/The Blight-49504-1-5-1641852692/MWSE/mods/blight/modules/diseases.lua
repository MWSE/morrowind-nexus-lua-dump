local common = require("blight.common")

local function getRandomDisease()
    return tes3.getObject(table.choice(common.diseases).id)
end

event.register("blight:TriggerDisease", function(e)
    local disease = e.diseaseId and tes3.getObject(e.diseaseId) or getRandomDisease()
    common.addBlight(e.reference, disease.id)

    if e.displayMessage == true then
        local diseaseName = disease.name
        tes3.messageBox(e.message, diseaseName)
    end

    if (e.callback) then
        e.callback(disease)
    end
end)

event.register("blight:TriggerBlight", function(e)
    -- roll for chance of actually getting blight.
    local chance = common.calculateBlightChance(e.reference)
    local contracted, roll = common.calculateChanceResult(chance)
    if e.overrideCheck or (contracted == false) then
        common.debug("'%s' resisted blight disease (rolled %s vs %s).", e.reference, roll, chance)
        return
    end

    common.debug("'%s' contracted blight disease (rolled %s vs %s).", e.reference, roll, chance)
    event.trigger("blight:TriggerDisease", {
        reference = e.reference,
        diseaseId = e.diseaseId,
        displayMessage = e.displayMessage,
        message = e.message or "You have contracted %s.",
        callback = e.callback
    })
end)
