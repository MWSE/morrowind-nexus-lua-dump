-- Load configuration.
return mwse.loadConfig("Realistic-Movement-Speeds") or {
    -- Initialize formula values
    backwardsMovementMultiplier = 60,
    strafingMovementMultiplier = 80
}