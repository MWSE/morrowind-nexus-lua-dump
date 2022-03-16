--- @param mobile tes3mobileActor
local function calcEncumbrance(mobile)
    local encumbranceRatio = ((mobile.encumbrance.current > mobile.encumbrance.base) and 1)
            or ((mobile.encumbrance.base > 0) and ((mobile.encumbrance.current / mobile.encumbrance.base) ^ 2))
            or 0
    return math.sqrt(1 - encumbranceRatio)
end

--- @param e calcMoveSpeedEventData
local function calcMoveSpeedCallback(e)
    local encumbrance = calcEncumbrance(e.mobile)
    e.speed = e.speed * encumbrance
end
event.register(tes3.event.calcMoveSpeed, calcMoveSpeedCallback)

--- @param e exerciseSkillEventData
local function exerciseSkillCallback(e)
    local encumbranceRatio = ((tes3.mobilePlayer.encumbrance.current > tes3.mobilePlayer.encumbrance.base) and 1)
            or ((tes3.mobilePlayer.encumbrance.base > 0) and ((tes3.mobilePlayer.encumbrance.current / tes3.mobilePlayer.encumbrance.base) ^ 2))
            or 0
    local encumbrance = math.sqrt(1 + encumbranceRatio)
    if (e.skill == tes3.skill.acrobatics) then
        e.progress = e.progress * encumbrance
    elseif (e.skill == tes3.skill.heavyArmor) then
        e.progress = e.progress * encumbrance
    elseif (e.skill == tes3.skill.mediumArmor) then
        e.progress = e.progress * encumbrance
    end
end
event.register(tes3.event.exerciseSkill, exerciseSkillCallback)

--- @param e calcRestInterruptEventData
local function calcRestInterruptCallback(e)
    tes3.findGMST(tes3.gmst.fFatigueReturnBase).value = tes3.findGMST(tes3.gmst.fFatigueReturnBase).defaultValue
    tes3.findGMST(tes3.gmst.fFatigueReturnMult).value = tes3.findGMST(tes3.gmst.fFatigueReturnBase).defaultValue * calcEncumbrance(tes3.mobilePlayer)
end
event.register(tes3.event.calcRestInterrupt, calcRestInterruptCallback)

--- @param e restInterruptEventData
local function restInterruptCallback(e)
    tes3.findGMST(tes3.gmst.fFatigueReturnBase).value = 0
    tes3.findGMST(tes3.gmst.fFatigueReturnMult).value = 0
end
event.register(tes3.event.restInterrupt, restInterruptCallback)

--- @param e enterFrameEventData
local function enterFrameCallback(e)
    if (e.menuMode == false) then
        local gmst = 0

        if (tes3.mobilePlayer.fatigue.normalized < 1 and not (tes3.mobilePlayer.isMovingForward or tes3.mobilePlayer.isMovingBack or tes3.mobilePlayer.isMovingLeft or tes3.mobilePlayer.isMovingRight)) then
            gmst = tes3.findGMST(tes3.gmst.fFatigueReturnBase).defaultValue + tes3.findGMST(tes3.gmst.fFatigueReturnMult).defaultValue * calcEncumbrance(tes3.mobilePlayer)
            tes3.mobilePlayer.fatigue.current = tes3.mobilePlayer.fatigue.current + gmst * e.delta
        end

        ---@param cell tes3cell
        for _, cell in ipairs(tes3.getActiveCells()) do
            ---@param mobile tes3mobileActor
            for mobile in cell:iterateReferences(tes3.objectType.mobileActor) do
                if (mobile.fatigue and mobile.encumbrance and mobile.fatigue.normalized < 1 and not (mobile.isMovingForward or mobile.isMovingBack or mobile.isMovingLeft or mobile.isMovingRight)) then
                    gmst = tes3.findGMST(tes3.gmst.fFatigueReturnBase).defaultValue + tes3.findGMST(tes3.gmst.fFatigueReturnMult).defaultValue * calcEncumbrance(mobile)
                    mobile.fatigue.current = mobile.fatigue.current + gmst * e.delta
                end
            end
        end
    end
end
event.register(tes3.event.enterFrame, enterFrameCallback)

--- @param e loadedEventData
local function loadedCallback(e)
    tes3.findGMST(tes3.gmst.fFatigueReturnBase).value = 0
    tes3.findGMST(tes3.gmst.fFatigueReturnMult).value = 0
end
event.register(tes3.event.loaded, loadedCallback)
