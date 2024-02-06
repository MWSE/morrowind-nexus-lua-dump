local function weaponSwishOnPlayerAttack(e)
    -- Someone other than the player is attacking.
    if (e.reference ~= tes3.player) then
        return
    end
    -- The attack has no target.
    -- if e.targetReference == nil then
        -- return
    -- end
    tes3.findGlobal("fs_WeaponSwish").value = 1
    -- tes3.messageBox("Debug: Variable changed with MWSE.")
end

-- The function to call on the initialized event.
local function initialized()
    -- Register on attack MessageBox
    event.register(tes3.event.attack, weaponSwishOnPlayerAttack)

    -- Print a "Ready!" statement to the MWSE.log file.
    print("[A Familiar Song: INFO] A Familiar Song Initialized")
end

-- Register initialized function to the initialized event.
event.register(tes3.event.initialized, initialized)