local function whenLevitating(e)
    --Filter out cretures
    if e.mobile.actorType ~= 0 then
        --Load GMSTs
        local minFlySpeedGMST = tes3.findGMST("fMinFlySpeed").value
        local maxFlySpeedGMST = tes3.findGMST("fMaxFlySpeed").value
        local encumberedMoveEffectGMST = tes3.findGMST("fEncumberedMoveEffect").value

        --Get actor info
        local levitateMagnitude = e.mobile.levitate
        local willpower = e.mobile.willpower.current
        local encumbrance = e.mobile.encumbrance.current / e.mobile.encumbrance.base

        --Calculate new speed
        local differenceFlySpeedGMST = maxFlySpeedGMST - minFlySpeedGMST
        local speedCalc = willpower + levitateMagnitude
        speedCalc = 0.01 * speedCalc
        speedCalc = minFlySpeedGMST + speedCalc * differenceFlySpeedGMST
        speedCalc = speedCalc - speedCalc * encumberedMoveEffectGMST * encumbrance
        e.speed = speedCalc
    end
end

local function initialized()
    print("[Wings of Will] Initialized")
    event.register("calcFlySpeed", whenLevitating)
end
event.register("initialized", initialized)
