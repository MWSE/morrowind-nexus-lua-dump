local modName = "Скрытые доспехи"
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
    --template.onClose = function()
        --manualUpdate()
		--mwse.saveConfig(configPath, config)
	--end
    template:saveOnClose(configPath, config)
	template:register()

    local page = template:createSideBarPage{
        label = "Настройки",
        description = "Этот мод позволяет вам настроить видимость наплечников и наручей, когда вы носите мантию. За эту идею надо отдать должное Tizzo."
    }

    page:createYesNoButton{
        label = "Включить мод",
        description = "Включить \\Выключить мод",
        variable = mwse.mcm.createTableVariable{ id = "enabled", table = config }
    }

    page:createYesNoButton{
        label = "Скрыть наплечники при экпировке мантии",
        variable = mwse.mcm.createTableVariable{ id = "hidePauldrons", table = config },
        callback = manualUpdate
    }
    page:createYesNoButton{
        label = "Скрыть наручи при экипировке мантии",
        variable = mwse.mcm.createTableVariable{ id = "hideBracers", table = config },
        callback = manualUpdate
    }

    template:createExclusionsPage{
        label = "Черный список доспехов\\одежды",
        description = "Переместите предметы в левый список, чтобы заблокировать на них влияние этого мода: мантии из черного списка не скроют никакую броню, а броня из черного списка никогда не будет скрыта.",
        variable = mwse.mcm.createTableVariable{ id = "blacklist", table = config},
        leftListLabel = "Заблокированно",
        rightListLabel = "Доступно",
        filters = {
            {
                label = "Мантии",
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
                    --manualUpdate()
                    return robeList
                end
            },
            {
                label = "Наплечники",
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
                    --manualUpdate()
                    return pauldronList
                end
            },
            {
                label = "Наручи",
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
                    --manualUpdate()
                    return bracerList
                end
            },
        }
    }
end
event.register("modConfigReady", registerMCM)