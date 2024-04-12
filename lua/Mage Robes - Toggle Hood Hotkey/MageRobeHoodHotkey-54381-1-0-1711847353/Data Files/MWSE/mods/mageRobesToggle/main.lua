local MODNAME = "mageRobesHoodToggle"

local mcmData = require("mageRobesToggle.magerobestoggle_mcm")
local config = mwse.loadConfig(MODNAME, mcmData.defaults) --[[@as ModConfig]]


local scripts = {
    "mg_script_alc",
    "mg_script_alcmas",
    "mg_script_alt",
    "mg_script_altmas",
    "mg_script_arch",
    "mg_script_con",
    "mg_script_conmas",
    "mg_script_des",
    "mg_script_desmas",
    "mg_script_enc",
    "mg_script_encmas",
    "mg_script_ill",
    "mg_script_illmas",
    "mg_script_mys",
    "mg_script_mysmas",
    "mg_script_nov",
    "mg_script_res",
    "mg_script_resmas",
}

---@param e vfxCreatedEventData
local function suppressEquipVisualFX(e)
    if e.vfx.effectObject.id ~= "VFX_RestorationHit" then
        return
    end
    e.vfx.expired = true
    timer.start({
        duration = 1,
        iterations = 1,
        callback = function()
            event.unregister(tes3.event.vfxCreated, suppressEquipVisualFX)
        end
    })
end

---@param e playItemSoundEventData
local function suppressEquipItemSoundFX(e)
    if not string.startswith(e.item.id, "mg_c_robe_") then
        return
    end
    e.block = true
    timer.delayOneFrame(function()
        event.unregister(tes3.event.playItemSound, suppressEquipItemSoundFX)
    end)
end


---@param e addSoundEventData
local function suppressEquipSoundFX(e)
    if e.sound.id ~= "restoration hit" then
        return
    end
    e.block = true
    timer.delayOneFrame(function()
        event.unregister(tes3.event.addSound, suppressEquipSoundFX)
    end)
end

local function getAlternateVersionId(itemId)
    if string.endswith(itemId, "hood") then
        return string.sub(itemId, 0, #itemId - 5)
    else
        return itemId .. "_hood"
    end
end

local function tryRegisterHandlers()
    local eventCallbackPairs = {
        { tes3.event.playItemSound, suppressEquipItemSoundFX },
        { tes3.event.addSound,      suppressEquipSoundFX },
        { tes3.event.vfxCreated,    suppressEquipVisualFX },
    }

    for _, v in pairs(eventCallbackPairs) do
        if not event.isRegistered(v[1], v[2]) then
            event.register(v[1], v[2])
        end
    end
end

---@param e keyUpEventData
local function hotkeyPressed(e)
    if tes3.menuMode() then
        return
    end

    if not tes3.isKeyEqual({ actual = e, expected = config.keybind }) then
        return
    end


    local player = tes3.mobilePlayer

    local equippedRobe = tes3.getEquippedItem({
        actor = player,
        objectType = tes3.objectType.clothing,
        slot = tes3.clothingSlot.robe
    })

    if equippedRobe == nil then
        return
    end

    if string.startswith(equippedRobe.object.id, "mg_c_robe_") then

        local newId = getAlternateVersionId(equippedRobe.object.id)
        local newRobe = tes3.getObject(newId) --[[@as tes3clothing]]
        if newRobe == nil then
            return
        end

        if config.suppressEffects then
            tryRegisterHandlers()
        end


        tes3.removeItem({
            reference = player,
            item = equippedRobe.object,
        })


        tes3.addItem({
            item = newRobe,
            reference = player,
        })
        player:equip({ item = newRobe })
    end
end

event.register(tes3.event.initialized, function()


    event.register(tes3.event.keyUp, hotkeyPressed, { filter = config.keybind.keyCode })

    if config.suppressPickupScript then
        for _, v in pairs(scripts) do
            mwse.overrideScript(v, function(e)
                e.script.blocked = true
            end)
        end
    end
end)

event.register(tes3.event.modConfigReady, function()
    mcmData.registerMCM(MODNAME, config)
end)
