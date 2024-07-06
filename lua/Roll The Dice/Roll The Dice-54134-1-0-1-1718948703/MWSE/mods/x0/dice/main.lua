local messageBox = require("x0.dice.util.messageBox")

local function rollOneDie()
    local result = math.random(1, 6)
    tes3.messageBox("You rolled a " .. result)
	tes3.playSound{
        reference = tes3.player,
        soundPath = 'x0\\rolldie.wav'
    }
end

local function rollTwoDice()
    local result1 = math.random(1, 6)
    local result2 = math.random(1, 6)
    tes3.messageBox("You rolled a " .. result1 .. " & " .. result2)
	tes3.playSound{
        reference = tes3.player,
        soundPath = 'x0\\rolldice.wav'
    }	
end

local function showSingleRollMenu()
    local buttons = {
        {
            text = "Roll 1 die",
            callback = rollOneDie
        },
        {
            text = "Cancel",
            callback = function()
                tes3ui.leaveMenuMode()
            end
        }
    }

    messageBox{
        message = "Choose an option:",
        buttons = buttons,
        doesCancel = true -- Enable cancel button
    }
end

local function showRollMenu()
    local buttons = {
        {
            text = "Roll 1 die",
            callback = rollOneDie
        },
        {
            text = "Roll 2 dice",
            callback = rollTwoDice
        }
    }

    messageBox{
        message = "Choose an option:",
        buttons = buttons,
        doesCancel = true -- Enable cancel button
    }
end

local function onEquip(e)
    if e.item.id == "T_Com_Dice_01" or e.item.id == "AB_Misc_Dice" or e.item.id == "TR_m3_q_OE_Ulka_dice" then
        showRollMenu()
        return false
    elseif e.item.id == "AB_Misc_DiceSingle" then
        showSingleRollMenu()
        return false
    end
end

event.register("equip", onEquip)