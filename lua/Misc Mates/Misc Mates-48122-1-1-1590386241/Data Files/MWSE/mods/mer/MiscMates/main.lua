local configPath = "MiscMates"
local config = mwse.loadConfig(configPath, {
    enabled = true,
    maxItemValue = 50,
})

local function getDispositionRequired(item)
    local defaultDisposition = 70
    local goldEffect = math.remap(item.object.value, 1, 100, 1.0, 4.0 )
    local personalityEffect = math.remap(math.log(tes3.mobilePlayer.personality.current), 0, 4.6, 1.0, 0.70)
    local dispositionRequired = defaultDisposition * goldEffect * personalityEffect
    return dispositionRequired
end

--True if has disposition to sleep
local function checkDisposition(owner, item)
    if not owner.disposition then
        --Not a mobile, so you'll never have permission
        return false
    end
    return math.min(owner.disposition, 100) > getDispositionRequired(item)
end

local function getOwner(itemRef)
    local ownerObject = tes3.getOwner(itemRef)
    if ownerObject then
        local ref = tes3.getReference(ownerObject.id)
        
        if ref then
            --If has mobile, return nil if dead
            if ref.mobile and ref.mobile.health.current <= 0 then 
                return
            end
            return ref
        end
    end
end

local classFields = {
    [tes3.objectType.armor] = "bartersArmor",
    [tes3.objectType.apparatus] = "bartersApparatus",
    [tes3.objectType.miscItem] = "bartersMiscItems",
    [tes3.objectType.book] = "bartersBooks",
    [tes3.objectType.clothing] = "bartersClothing",
    [tes3.objectType.ingredient] = "bartersIngredients",
    [tes3.objectType.alchemy] = "bartersAlchemy",
    [tes3.objectType.light] = "bartersLights",
    [tes3.objectType.lockpick] = "bartersLockpicks",
    [tes3.objectType.probe] = "bartersProbes",
    [tes3.objectType.repairItem] = "bartersRepairTools",
    [tes3.objectType.weapon] = "bartersWeapons",
}

local function onTooltip(e)
    if not config.enabled then return end
    local item = e.reference
    local validItem = (
        item and
        classFields[item.baseObject.objectType] and
        item.baseObject.value <= tonumber(config.maxItemValue) and
        not item.baseObject.script and
        not string.startswith(item.object.id, "key_") and 
        not string.startswith(item.object.id, "Gold_")
    )
    if validItem then
        local owner = getOwner(item)
        if owner then
            --Class isn't allowed to sell items
            if owner.object.class and owner.object.class[classFields[item.baseObject.objectType]] then
                return
            end
            --Doesn't matter if they're dead
            if owner.mobile and owner.mobile.health.current <= 0 then
                return
            end
            if checkDisposition(owner.object, item) then
                if item.itemData then
                    item.itemData.data.ownerPermitted = owner
                    item.itemData.owner = nil
                end
            end

        elseif item.itemData and item.itemData.data.ownerPermitted then
            if not checkDisposition(item.itemData.data.ownerPermitted.object, item) then
                tes3.setOwner{ reference = item, owner = item.itemData.data.ownerPermitted}
                item.itemData.data.ownerPermitted = nil
            end
        end
    end
end
event.register(tes3.event.uiObjectTooltip, onTooltip)


local function registerMcm()

    local template = mwse.mcm.createTemplate{ name = "Misc Mates"}
    template:register()
    template:saveOnClose(configPath, config)

    local page = template:createSideBarPage{ 
        description = "This mod makes it so that NPCs will allow you to take small inexpensive items if their disposition towards you is high enough. The disposition required is based on the gold value of the item and the player's personality."
    }

    page:createOnOffButton{
        label = "Mod Enabled",
        description = "Turn the mod on or off.",
        variable = mwse.mcm.createTableVariable{ id = "enabled", table = config }
    }

    page:createTextField{
        label = "Max Item Value",
        description = "Set the max value of an item that an NPC can let you take.",
        variable = mwse.mcm.createTableVariable{ id = "maxItemValue", table = config, numbersOnly = true },
    }
end

event.register("modConfigReady", registerMcm)