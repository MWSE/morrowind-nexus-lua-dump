local cf = mwse.loadConfig("Real Fire Damage", {rad = 40, dmg = 4, blocked = {}, npcs = {}, onOff = true})

local function getFireSources()
    local list = {}
    for light in tes3.iterateObjects(tes3.objectType.light) do
            if (light.isFire and not light.canCarry and not (string.find(light.id, "lantern"))) then
            table.insert(list, light.id:lower())
            end
    end
    table.sort(list)
    return list
end

local function validateObject(object)
    local file = object.sourceMod
    if file and cf.blocked[file:lower()] then
        return false
    elseif cf.blocked[object.id:lower()] then
        return false
    end
    return true
end

local function validateObjectNPCs(object)
    local file = object.sourceMod
    if file and cf.npcs[file:lower()] then
        return false
    elseif cf.npcs[object.object.id:lower()] then
        return false
    end
    return true
end

local function npcFireDamage()
    local playerCell = tes3.getPlayerCell()
    for light in playerCell:iterateReferences(tes3.objectType.light) do
        if (light.object.isFire and not light.object.canCarry and not (string.find(light.object.id, "lantern")) and validateObject(light)) then
        local mobileList = tes3.findActorsInProximity{
          reference = light, range = cf.rad}
            for _, mobile in ipairs(mobileList) do
                if ((mobile.object.objectType == tes3.objectType.npc) and validateObjectNPCs(mobile)) then
                    mobile:applyDamage({ damage = (cf.dmg)/2, applyArmor = false, resistAttribute = 3 })
                    tes3.playAnimation({reference = mobile, lower = 0x3B, loopCount = 5})
                    if cf.onOff then
                        tes3.messageBox("%s is getting burned!", mobile.object.name)
                    end
                end
            end
        end
    end
end

local function onLoaded()
    timer.start({iterations = -1, duration = .5, callback = npcFireDamage, type = timer.simulate })
end

local function registerModConfig()
    local template = mwse.mcm.createTemplate("Real Fire Damage")

    template:saveOnClose("Real Fire Damage", cf) template:register()

    local page = template:createSideBarPage({label = "Settings"})

    local category = page:createCategory("MessageBox")

    category:createOnOffButton({label = "On/Off", description = "Toggles whether the message '[Name] is getting burned.' will display or not. [Default: On]", variable = mwse.mcm.createTableVariable{id = "onOff", table = cf}})

    local category1 = page:createCategory("Radius:")

    category1:createSlider{label = "Distance", description = "How close you need to be (in game units) for the fire to hurt you. [Default: 40]", min = 0, max = 1000, step = 1, jump = 10, variable = mwse.mcm.createTableVariable{id = "rad", table = cf}}

    local category2 = page:createCategory("DpS")

    category2:createSlider{label = "Damage", description = "Damage per second applied by the fire (for a value of 0% Fire Resistance). [Default: 4]", min = 0, max = 50, step = 1, jump = 10, variable = mwse.mcm.createTableVariable{id = "dmg", table = cf}}


    template:createExclusionsPage{label = "Fire Sources Blacklist", description = "Here you can manually configure which light sources can hurt you. Find their id with the game console and blacklist them.", variable = mwse.mcm.createTableVariable{id = "blocked", table = cf}, filters = {{label = "Fire sources", callback = getFireSources}}}

    template:createExclusionsPage{label = "NPCs Blacklist", description = "Here you can manually configure which NPC can get hurt by fire sources. Find their id with the game console and blacklist them.", variable = mwse.mcm.createTableVariable{id = "npcs", table = cf}, filters = {{label = "NPCs", type = "Object", objectType = tes3.objectType.npc}}}
end

event.register("modConfigReady", registerModConfig)

local function initialized()
    event.register(tes3.event.loaded, onLoaded)
    print("[Real Fire Damage] RFD 2.0 initialized!")
end

event.register("initialized", initialized)
