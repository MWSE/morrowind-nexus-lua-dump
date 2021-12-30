local configPath = "WMD"
local config = mwse.loadConfig(configPath, {
    enabled = true,
})

local tempId
local newId

local function equipItem()
    tes3.addItem{reference = tes3.mobilePlayer, item = newId, count = 1}
    mwscript.equip{reference = tes3.mobilePlayer, item = newId, count = 1}
    mwscript.removeItem{reference = tes3.mobilePlayer, item = tempId, count = 1}
end

local function onEquip(e)
    if config.enabled == false then
        return
    end
    if not e.reference == tes3.mobilePlayer then
        return
    end
    if e.item.objectType == tes3.objectType.miscItem then
        if e.item.isKey or e.item.isGold or e.item.isSoulGem or e.item.script then
            return
        end
        tempId = e.item.id
        newId = e.item.id
        if #newId == 32 then
            newId = newId:sub(2)
        end
        newId = tostring("9" .. newId)

        --the attempt to prevent bug of marksman objects ghost stacking
        local result = mwscript.hasItemEquipped{reference = tes3.mobilePlayer, item = newId}
        if result then
            return
        end

        local newItem = tes3.createObject({
            objectType = tes3.objectType.weapon,
            type = 11,
            id = newId,
            getIfExists = true,
            name = e.item.name,
            mesh = e.item.mesh,
            icon = e.item.icon,
            value = e.item.value,
            weight = e.item.weight,
            chopMin = 1,
            chopMax = 1,
            slashMin = 1,
            slashMax = 1,
            thrustMin = 1,
            thrustMax = 1,
            speed = 1,
            maxCondition = 10,
            enchantCapacity = 10,
        })

        local timer = timer.delayOneFrame(equipItem, timer.real)
        return false
    end
end

event.register("equip", onEquip)

local function registerMCM()
    local template = mwse.mcm.createTemplate("WMD")
    template:saveOnClose(configPath, config)
    template:register()
    local page = template:createSideBarPage{
        label = "Settings",
        description = "Equip misc items to throw them"
    }
    page:createYesNoButton{
        label = "Enable Mod",
        description = "Toggle mod on or off.",
        variable = mwse.mcm.createTableVariable{ id = "enabled", table = config }
    }

end

event.register("modConfigReady", registerMCM)