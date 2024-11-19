local diceID = {
    ["T_Com_Die_01"] = true,
    ["AB_Misc_DiceSingle"] = true,
}

---@param ref tes3reference
local function isDice(ref)
    if diceID[ref.id] then
        return true
    end
    if string.match(ref.id, "Die") or string.match(ref.id, "die") then
        return true
    end
    return false
end

--- @class onDieDroppedTable
--- @field reference tes3reference

--- @param e onDieDroppedTable
local function onDieDropped(e)
    local ref = e.reference
    -- Can early-out if we aren't dealing with a dice.
    if not isDice(ref) then
        return
    end

    local diceRoll = math.random(6)
    local newOrientation = ref.orientation:copy()

    -- Numbers correspond to the actual value on the die; based on TR's die model with 5 on top.
    if diceRoll == 1 then
        newOrientation.y = newOrientation.y + math.pi
    elseif diceRoll == 2 then
        newOrientation.y = newOrientation.y + math.pi / 2
    elseif diceRoll == 3 then
        newOrientation.x = newOrientation.x + 3 * math.pi / 2
        newOrientation.y = newOrientation.y + math.pi / 2
    elseif diceRoll == 4 then
        newOrientation.x = newOrientation.x + math.pi
        newOrientation.y = newOrientation.y + math.pi / 2
    elseif diceRoll == 5 then
        -- Nothing to do here
    elseif diceRoll == 6 then
        newOrientation.x = newOrientation.x + math.pi / 2
    end

    -- Note: tes3.player.facing is the same as tes3.player.orientation.z
    newOrientation.z = newOrientation.z - tes3.player.facing

    ref.orientation = newOrientation
    --tes3.messageBox("You rolled a %s", diceRoll)
	tes3.removeSound{ reference = tes3.player, sound = "Item Misc Down"}
	tes3.playSound{ reference = tes3.player, volume = 5.0, soundPath = "Fx\\endo\\dice.wav"}
end
-- Low priority so the die toss will be applied after any adjustments made by another mod such as Just Drop It!(TM) by Merlord
event.register("itemDropped", onDieDropped, { priority = -10})