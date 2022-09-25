local modName = "Hidden Armor Robes"
local configPath = "hiddenArmorRobes"
local config = mwse.loadConfig(configPath, {
    enabled = true,
    hidePauldrons = true,
    hideBracers = true,
    blacklist = {}
})

local configMapper = {
    [tes3.armorSlot.leftPauldron] = "hidePauldrons",
    [tes3.armorSlot.rightPauldron] = "hidePauldrons",
    [tes3.armorSlot.leftBracer] = "hideBracers",
    [tes3.armorSlot.rightBracer] = "hideBracers",
}

local partMapper = {
    [tes3.activeBodyPart.leftPauldron] = true,
    [tes3.activeBodyPart.rightPauldron] = true,
    [tes3.activeBodyPart.leftWrist] = true,
    [tes3.activeBodyPart.rightWrist] = true,

}

local function getIsBlocked(obj)
    if config.blacklist[obj.id:lower()] then
        return true
    end
    if config[configMapper[obj.slot]] == false then
        return true
    end
    return false
end


local function manualUpdate(e)
    if tes3.player == e.reference then
        tes3.player:updateEquipment()
    end
end
event.register("loaded", manualUpdate)

local function onBodyPartAssigned(e)
    if config.enabled ~= true then return end
    if (e.reference ~= tes3.player) then return end
    if partMapper[e.index] and e.object then
        local robe = tes3.getEquippedItem{
            actor = tes3.player,
            objectType = tes3.objectType.clothing,
            slot = tes3.clothingSlot.robe
        }
        if robe and config.blacklist[robe.object.id:lower()] ~= true then
            if not getIsBlocked(e.object) then
                return false
            end
        end
    end
end
event.register("bodyPartAssigned", onBodyPartAssigned)



local function registerMCM()
    local template = mwse.mcm.createTemplate(modName)
    template.onClose = function()
        manualUpdate()
		mwse.saveConfig(configPath, config)
	end
    template:register()

    local page = template:createSideBarPage{
        label = "Settings",
        description = "This mod lets you toggle whether pauldrons, gauntlets and bracers are visible when you are wearing a robe. Credit goes to Tizzo for the idea."
    }

    page:createYesNoButton{
        label = "Enable mod",
        description = "Turn this mod on or off.",
        variable = mwse.mcm.createTableVariable{ id = "enabled", table = config }
    }

    page:createYesNoButton{
        label = "Hide Pauldrons when wearing robe",
        variable = mwse.mcm.createTableVariable{ id = "hidePauldrons", table = config },
        callback = manualUpdate
    }
    page:createYesNoButton{
        label = "Hide Bracers when wearing robe",
        variable = mwse.mcm.createTableVariable{ id = "hideBracers", table = config },
        callback = manualUpdate
    }

    template:createExclusionsPage{
        label = "Armor/Clothing Blacklist",
        description = "Move items to the left hand list to block them from being affected by this mod: Blacklisted robes will not hide any armor, and blacklisted armor will never be hidden.",
        variable = mwse.mcm.createTableVariable{ id = "blacklist", table = config},
        leftListLabel = "Blocked",
        rightListLabel = "Allowed",
        filters = {
            {
                label = "Robes",
                callback = function()
                    local robeList = {}
                    for obj in tes3.iterateObjects(tes3.objectType.clothing) do
                        if not (obj.baseObject and obj.baseObject.id ~= obj.id ) then
                            if obj.slot == tes3.clothingSlot.robe then
                                robeList[#robeList+1] = (obj.baseObject or obj).id:lower()
                            end
                        end
                    end
                    table.sort(robeList)
                    manualUpdate()
                    return robeList
                end
            },
            {
                label = "Pauldrons",
                callback = function()
                    local pauldronList = {}
                    for obj in tes3.iterateObjects(tes3.objectType.armor) do
                        if not (obj.baseObject and obj.baseObject.id ~= obj.id ) then
                            if obj.slot == tes3.armorSlot.leftPauldron or obj.slot == tes3.armorSlot.rightPauldron then
                                pauldronList[#pauldronList+1] = (obj.baseObject or obj).id:lower()
                            end
                        end
                    end
                    table.sort(pauldronList)
                    manualUpdate()
                    return pauldronList
                end
            },
            {
                label = "Bracers",
                callback = function()
                    local bracerList = {}
                    for obj in tes3.iterateObjects(tes3.objectType.armor) do
                        if not (obj.baseObject and obj.baseObject.id ~= obj.id ) then
                            if obj.slot == tes3.armorSlot.leftBracer or obj.slot == tes3.armorSlot.rightBracer then
                                bracerList[#bracerList+1] = (obj.baseObject or obj).id:lower()
                            end
                        end
                    end
                    table.sort(bracerList)
                    manualUpdate()
                    return bracerList
                end
            },
        }
    }
end
event.register("modConfigReady", registerMCM)