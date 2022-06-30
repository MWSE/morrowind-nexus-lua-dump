local function addBlockedSound(ref, soundId)
    local blockedSounds = table.getset(ref.tempData, "OAAB_blockedSounds", {})
    local previousCount = table.getset(blockedSounds, soundId, 0)
    blockedSounds[soundId] = previousCount + 1
end

local function preventBlockedSounds(e)
    local ref = e.reference or tes3.player
    if not ref.supportsLuaData then return end

    local blockedSounds = ref.tempData.OAAB_blockedSounds
    if not blockedSounds then return end

    local id = e.sound.id:lower()
    local count = blockedSounds[id]
    if count == nil then return end

    if count > 1 then
        blockedSounds[id] = count - 1
    else
        blockedSounds[id] = nil
    end

    return false
end
event.register("addSound", preventBlockedSounds, {priority = 1000})


-- Prevent drink sounds
local function stopDrinkSounds(e)
    if not e.item.id:find("^AB_alc_") then return end

    addBlockedSound(e.reference, "drink")
    event.trigger("OAAB:equip", e)
end
event.register("equip", stopDrinkSounds, {priority = 1000})


-- Prevent item pick/drop sounds
local function stopItemSounds(e)
    if not e.item.id:find("^AB_alc_") then return end

    if e.state == 0 then -- UP
        tes3.playSound({reference = e.reference, sound = "Item Misc Up"})
    elseif e.state == 1 then -- DOWN
        tes3.playSound({reference = e.reference, sound = "Item Misc Down"})
    end

    return false
end
event.register("playItemSound", stopItemSounds, {priority = 1000})
