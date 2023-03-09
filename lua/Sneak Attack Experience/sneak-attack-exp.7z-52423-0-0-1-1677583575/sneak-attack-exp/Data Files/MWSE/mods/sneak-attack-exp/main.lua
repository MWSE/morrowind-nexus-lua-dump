local modName = "sneak-attack-exp"

local logger = require("logging.logger")
local log = logger.new{
    name = modName,
    logLevel = "INFO",
    logToConsole = true,
    includeTimestamp = true,
}

local function checkAndAddSneakExperience(e)
    if (e.reference ~= tes3.player or
        e.targetMobile == nil or
        not tes3.mobilePlayer.isSneaking) then
        return
    end

    -- https://en.uesp.net/wiki/Morrowind:Sneak
    -- Elusiveness = (Sneak + Agility/5 + Luck/10) *
    --               (0.5 + Distance to Target/500) *
    --               (0.75 + 0.5 * Current Fatigue/Maximum Fatigue) + Chameleon Magnitude
    -- Spot Chance = (Sneak + Agility/5 + Luck/10 - Blind Magnitude) *
    --               (0.75 + 0.5 * Current Fatigue/Maximum Fatigue) * Direction Multiplier
    -- Direction Multiplier = 0.5 is player behind target, otherwise 1.5
    -- Hidden chance = Elusiveness - Spot Chance

    local playerSneak = tes3.mobilePlayer:getSkillValue(tes3.skill.sneak)
    local playerAgility = tes3.mobilePlayer.agility.current
    local playerLuck = tes3.mobilePlayer.luck.current
    local distance = e.targetMobile.playerDistance
    local playerFatigueTerm = tes3.mobilePlayer:getFatigueTerm()
    local playerChameleon = tes3.mobilePlayer.chameleon
    local targetSneak = e.targetMobile:getSkillValue(tes3.skill.sneak)
    local targetAgility = e.targetMobile.agility.current
    local targetLuck = e.targetMobile.luck.current
    local targetBlind = e.targetMobile.blind
    local targetFatigueTerm = e.targetMobile:getFatigueTerm()
    local directionMultiplayer = 1 -- todo

    local elusiveness = (playerSneak + playerAgility/5 + playerLuck/10) *
                        (0.5 + distance/500) *
                        (0.75 + 0.5 * playerFatigueTerm) + playerChameleon
    local spotChance = (targetSneak + targetAgility/5 + targetLuck/10 - targetBlind) *
                    (0.75 + 0.5 * targetFatigueTerm) * directionMultiplayer
    local successChance = elusiveness - spotChance
    local r = math.random() * 100;

    if (log.logLevel == "DEBUG" or log.logLevel == "TRACE") then
        log:debug("[sneak-attack-exp] playerSneak: "..tostring(playerSneak))
        log:debug("[sneak-attack-exp] playerAgility: "..tostring(playerAgility).." /5: "..tostring(playerAgility/5))
        log:debug("[sneak-attack-exp] playerLuck: "..tostring(playerLuck).." /10: "..tostring(playerLuck/10))
        log:debug("[sneak-attack-exp] distance: "..tostring(distance).." /500: "..tostring(distance/500))
        log:debug("[sneak-attack-exp] playerFatigueTerm: "..tostring(playerFatigueTerm).. " *0.5: "..tostring(0.5 * playerFatigueTerm))
        log:debug("[sneak-attack-exp] playerChameleon: "..tostring(playerChameleon))
        log:debug("[sneak-attack-exp] elusiveness: "..tostring(elusiveness))
        log:debug("[sneak-attack-exp] targetSneak: "..tostring(targetSneak))
        log:debug("[sneak-attack-exp] targetAgility: "..tostring(targetAgility))
        log:debug("[sneak-attack-exp] targetLuck: "..tostring(targetLuck))
        log:debug("[sneak-attack-exp] targetBlind: "..tostring(targetBlind))
        log:debug("[sneak-attack-exp] targetFatigueTerm: "..tostring(targetFatigueTerm).." *0.5: "..tostring(0.5 * targetFatigueTerm))
        log:debug("[sneak-attack-exp] spotChance: "..tostring(spotChance))
        log:debug("[sneak-attack-exp] successChance: "..tostring(successChance))
        log:debug("[sneak-attack-exp] random: "..tostring(r))
    end

    if (r > successChance) then
        return
    end

    log:debug("[sneak-attack-exp] adding sneak exp 1")
    tes3.mobilePlayer:exerciseSkill(tes3.skill.sneak, 1)
end

local function initialized()

    event.register(tes3.event.attackHit, checkAndAddSneakExperience)

    log:info("[sneak-attack-exp] Initialized")
end

event.register(tes3.event.initialized, initialized)