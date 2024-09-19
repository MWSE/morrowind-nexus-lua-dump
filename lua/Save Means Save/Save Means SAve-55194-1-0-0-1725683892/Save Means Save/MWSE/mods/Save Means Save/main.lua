--[[
Save Means Save
Author : None
--]]

local config = require("Save Means Save.config")
dofile("Save Means Save.mcm")



local function initializeData(e)
    if tes3.player.data.saveMeansSave == nil then
        tes3.player.data.saveMeansSave = {}
    end
end
event.register(tes3.event.loaded, initializeData, {priority = 1})


local lockpickID = 1262702412
local probeID = 1112494672

local function savePlayerState(e)

    if not config.enabled then
        return
    end

    tes3.player.modified = true
    local save = tes3.player.data.saveMeansSave
    local player = tes3.mobilePlayer
    save.isSneaking = player.isSneaking
    save.alwaysRun = player.alwaysRun
    save.autoRun = player.autoRun

    if player.isJumping then
        save.isJumping = {}
        save.isJumping.x = player.velocity.x
        save.isJumping.y = player.velocity.y
        save.isJumping.z = player.velocity.z
    end

    if player.torchSlot then
        save.torchSlot = {}
        save.torchSlot[1] = player.torchSlot.object.id
        save.torchSlot[2] = player.torchSlot.itemData.timeLeft
        save.torchSlot[3] = "timeLeft"
    end

    if player.readiedWeapon then
        if player.readiedWeapon.object.objectType == lockpickID or probeID then
            save.tool = {}
            save.tool[1] = player.readiedWeapon.object.id
            save.tool[2] = player.readiedWeapon.itemData.condition
            save.tool[3] = "condition"
        end
    end
end
event.register(tes3.event.save, savePlayerState)

local function savedCallback(e)
    tes3.player.data.saveMeansSave = {}
end
event.register(tes3.event.saved, savedCallback)


local function findItem(item, reference)
    local property = item[3]
    local inventory = reference.inventory
    for i in ipairs(inventory) do
        if inventory[i].object.id == item[1] then
            local itemStack = inventory[i]
            for j in ipairs(itemStack.variables) do
                if math.floor(itemStack.variables[j][property]) == math.floor(item[2]) then
                    local itemData = itemStack.variables[j]
                    return itemData
                end
            end
        end
    end
end


local function addSoundCallback(e)
    e.volume = 0
end


local function setPlayerState(e)

    if not config.enabled then
        return
    end

    local save = tes3.player.data.saveMeansSave
    local player = tes3.mobilePlayer

    timer.frame.delayOneFrame(function() -- Autorun doesn't always stick without this
        player.isSneaking = save.isSneaking
        player.alwaysRun = save.alwaysRun
        player.autoRun = save.autoRun
    end
    )

    if save.isJumping then
        local jumpVector = tes3vector3.new(save.isJumping.x, save.isJumping.y, save.isJumping.z)
        player:doJump({velocity = jumpVector, applyFatigueCost = false, allowMidairJumping = true})
        save.isJumping = nil
    end

    if save.torchSlot then
        event.register(tes3.event.addSound, addSoundCallback, { filter = tes3.getSound("Item Misc Up") })
        player:equip({ item = save.torchSlot[1], itemData = findItem(save.torchSlot, player) })
        event.unregister(tes3.event.addSound, addSoundCallback, { filter = tes3.getSound("Item Misc Up") })
        save.torchSlot = nil
    end

    if save.tool then
        event.register(tes3.event.addSound, addSoundCallback, { filter = tes3.getSound("Item Lockpick Up") })
        event.register(tes3.event.addSound, addSoundCallback, { filter = tes3.getSound("Item Probe Up") })
        player:equip({ item = save.tool[1], itemData = findItem(save.tool, player) })
        event.unregister(tes3.event.addSound, addSoundCallback, { filter = tes3.getSound("Item Lockpick Up") })
        event.unregister(tes3.event.addSound, addSoundCallback, { filter = tes3.getSound("Item Probe Up") })
        save.tool = nil

    end
end
event.register(tes3.event.loaded, setPlayerState)