return {
    -- Encumbrance formula only:
    -- penalty = (encumbrance / capacity) * (swimSpeedMultiplier * 3)
    swimSpeedMultiplier = 100,

    -- #1 Swim speed penalty settings.
    minSwimSpeedScale = 0.15,

    -- #2 Fatigue drain settings.
    -- Drain is: penalty * fatigueDrainPerPenaltyPerSecond * dt
    fatigueDrainPerPenaltyPerSecond = 0.02,
    drainOnlyWhenMoving = true,

    -- Athletics tie-in:
    -- At 100 Athletics, up to 40% of penalty is removed.
    athleticsPenaltyReductionCap = 0.40,
}
