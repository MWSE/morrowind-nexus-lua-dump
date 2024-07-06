local logger = require("logging.logger")
local log = logger.getLogger("Friendly Intervention")
local config = require("friendlyIntervention.config")


local this = {}

----Companion Check-------------------------------------------------------------------------------------------------------------
function this.validCompanionCheck(mobileActor)
    log = logger.getLogger("Friendly Intervention")
    local name = mobileActor.object.name
    log:trace("Checking " .. name .. "...")
    if (mobileActor == tes3.mobilePlayer) then
        return false
    end
    if (tes3.getCurrentAIPackageId(mobileActor) ~= tes3.aiPackage.follow) then
        return false
    end
    local animState = mobileActor.actionData.animationAttackState
    if (
        mobileActor.health.current <= 0 or animState == tes3.animationState.dying or
            animState == tes3.animationState.dead) then
        return false
    end
    local fishCheck = string.endswith(name, "Slaughterfish")
    if fishCheck == true then
        log:debug("" .. name .. " ends with Slaughterfish, invalid companion!")
        return false
    end
    return true
end

----Mod Data------------------------------------------------------------------------------------------------------------------
function this.getModData(npcRef)
    log = logger.getLogger("Friendly Intervention")
    log:trace("Checking saved Mod Data.")
    if not npcRef.data.friendlyIntervention then
        npcRef.data.friendlyIntervention = { ["cell"] = "", ["position"] = {} }
        npcRef.modified = true
    else
        log:trace("Saved Mod Data found.")
    end
    return npcRef.data.friendlyIntervention
end

----Calculate Magicka Cost------------------------------------------------------------------------------------------------------------------
function this.calculateCost(currentMyst)
    log = logger.getLogger("Friendly Intervention")
    log:trace("Calculating Magicka Cost.")
    if currentMyst == nil then
        log:warn("Mysticism skill returned nil. Changed to 1.")
        currentMyst = 1
    end
    local mystMod = (currentMyst / 200)
    local cost = (config.magickaMod * (1 - mystMod))
    local costRound = math.round(cost)
    if costRound < 1 then
        log:warn("Magicka cost below 1. Changed to 1.")
        costRound = 1
    end
    return costRound
end

----Calculate Pitch Variation-------------------------------------------------------------------------------------------------------------------
function this.calculatePitch()
    local pitchMod = math.random()
    local pitchMod2 = math.random()
    local pitchMod3 = (pitchMod + pitchMod2)
    if pitchMod3 < 0.80 then
        pitchMod3 = 0.80
    end
    if pitchMod3 > 1.20 then
        pitchMod3 = 1.20
    end
    return pitchMod3
end

return this
