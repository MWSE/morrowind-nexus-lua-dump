local mod = {
    name = "Bleeding Injuries",
    ver = "1.0",
    cf = {onOff = true, key = {keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false}, dropDown = 0, slider = 5, sliderpercent = 50, blocked = {}, npcs = {}, textfield = "hello", switch = false}
            }
local cf = mwse.loadConfig(mod.name, mod.cf)

local decalTextures = {
    ["textures\\tr\\tr_decal_blood_04.dds"] = true,
    ["textures\\tr\\tr_decal_blood_05.dds"] = true,
    ["textures\\tr\\tr_decal_blood_06.dds"] = true,
    ["textures\\tr\\tr_decal_blood_03.dds"] = true,
    ["textures\\tr\\tr_decal_blood_07.dds"] = true,
    ["textures\\tr\\tr_decal_blood_08.dds"] = true,
    ["textures\\tr\\tr_decal_blood_12.dds"] = true,
    ["textures\\tr\\tr_decal_blood_10.dds"] = true,
    ["textures\\tr\\tr_decal_blood_11.dds"] = true,
}

local bodyParts = {
[0] = {0},
[1] = {3},
[4] = {21, 22, 19, 20},
[6] = {7},
[7] = {6},
[9] = {12},
[10] = {11}
}

local validArmor = {
    ["helmet"] = 0,
    ["cuirass"] = 1,
    ["greaves"] = 4,
    ["leftHand"] = 6,
    ["rightHand"] = 7,
    ["leftArm"] = 9,
    ["rightArm"] = 10
}

local function addDecal(ref, index, sceneNode)
    if not ref.data then return end
    if not ref.data.spa_bloodydontrandom then
        ref.data.spa_bloodydontrandom = {}
    end
    ---@diagnostic disable-next-line: undefined-field
    local choice = table.get(ref.data.spa_bloodydontrandom, index, table.choice(decalTextures))
    ref.data.spa_bloodydontrandom[index] = choice
    for node in table.traverse{sceneNode} do
        if node:isInstanceOfType(tes3.niType.NiTriShape) then
            local alphaProperty = node:getProperty(0x0)
            local texturingProperty = node:getProperty(0x4)
            if (alphaProperty == nil
                and texturingProperty ~= nil
                and texturingProperty.canAddDecal == true)
            then
                -- we have to detach/clone the property
                -- because it could have multiple users
                    texturingProperty = node:detachProperty(0x4):clone()
                    texturingProperty:addDecalMap(choice)
                    node:attachProperty(texturingProperty)
                    node:updateProperties()
            end
        end
    end
    tes3ui.updateInventoryCharacterImage()
end


local function iterEffectDecals(texturingProperty)
    return coroutine.wrap(function()
        for i, map in ipairs(texturingProperty.maps) do
            local texture = map and map.texture
            local fileName = texture and texture.fileName
            for _, v in pairs(decalTextures) do
                if v.fileName == fileName then
                    coroutine.yield(i, map)
                    break
                end
            end
        end
    end)
end

local function removeDecal(ref, sceneNode)
    if ref.mobile.health.normalized < 0.75 then return end
    for node in table.traverse{sceneNode} do
        if node:isInstanceOfType(tes3.niType.NiTriShape) then
            local texturingProperty = node:getProperty(0x4)
            if texturingProperty then
                for i in iterEffectDecals(texturingProperty) do
                    texturingProperty:removeDecalMap(i)
                end
            end
        end
    end
    ref.data.spa_bloodydontrandom = {}
    ref.data.spa_bloodyinjury = {}
    tes3ui.updateInventoryCharacterImage()
end
-----------------------------------------------------------------------
--[[for _,layer in pairs(tes3.activeBodyPartLayer) do
    for _,part in pairs(tes3.activeBodyPart) do
        local activpart = tes3.player.bodyPartManager:getActiveBodyPart(layer, part)
        if activpart then
            addDecal(activpart.node)
        end
    end
end--]]
--------------------------------------------------------------------------------------------
event.register("loaded", function()
    tes3.player.data.spa_bloodyinjury = tes3.player.data.spa_bloodyinjury or {}
end)

---@param e spellResistEventData
event.register("spellResist", function(e)
    if e.effect.id == tes3.effect.restoreHealth or e.effect.id == tes3.effect.absorbHealth then
        if  table.size(e.target.data.spa_bloodyinjury) >= 1 then
            timer.start({duration = e.effect.duration, callback =
                function()
                    removeDecal(e.target, e.target.sceneNode)
                end})
            if e.target == tes3.player then
            timer.start({duration = e.effect.duration, callback =
                function()
                    removeDecal(tes3.player, tes3.mobilePlayer.firstPersonReference.sceneNode)
                end})
            end
        end
    end
end)

local menuTimestamp
---@param e menuEnterEventData
local function onMenuEnterExit(e)
    if (e.menuMode) then
        menuTimestamp = tes3.getSimulationTimestamp()
    else
        if (menuTimestamp ~= tes3.getSimulationTimestamp()) then
            removeDecal(tes3.player, tes3.player.sceneNode)
            removeDecal(tes3.player, tes3.mobilePlayer.firstPersonReference.sceneNode)
        end
    end
end

local function getInjuries(ref)
    if ref and ref.data and not ref.data.spa_bloodyinjury then
        ref.data.spa_bloodyinjury = {}
    end
    return ref.data.spa_bloodyinjury
end

---@param e damagedEventData
event.register("damaged", function(e)
if e.reference.object.objectType ~= tes3.objectType.npc then
    return
end

local injuries = getInjuries(e.reference)

local ratio = e.mobile.health.normalized
debug.log(ratio)
debug.log(#injuries)
debug.log(table.size(injuries))
if ((ratio >= 0.8)
or (ratio >= 0.6 and table.size(injuries) >= 1)
or (ratio >= 0.4 and table.size(injuries) >= 2)
or (ratio >= 0.3 and table.size(injuries) >= 3)
or (ratio >= 0.2 and table.size(injuries) >= 4))
then
    return
end

local unprotected = {}
for k,v in pairs(validArmor) do
    local equipped = tes3.getEquippedItem({actor = e.reference, objectType = tes3.objectType.armor, slot = v})
    if not equipped then
        unprotected[k] = v
    end
end
for i,v in pairs(unprotected) do
    if table.find(injuries, bodyParts[v]) then
        unprotected[i] = nil
    end
end
debug.log(#unprotected)
if table.size(unprotected) == 0 then return end


if e.attacker.weaponDrawn then
    for _,layer in pairs(tes3.activeBodyPartLayer) do
        local activpart = e.attackerReference.bodyPartManager:getActiveBodyPart(layer, tes3.activeBodyPart.weapon)
        if activpart and activpart.node then
            addDecal(e.attackerReference, tes3.activeBodyPart.weapon, activpart.node)
            if e.attacker == tes3.mobilePlayer then
                local activpart2 = e.attacker.firstPersonReference.bodyPartManager:getActiveBodyPart(layer, tes3.activeBodyPart.weapon)
                addDecal(e.attacker.firstPersonReference, tes3.activeBodyPart.weapon, activpart2.node)
            end
        end
    end
end
debug.log("what")
local choice = table.choice(unprotected)
if table.find(injuries, bodyParts[choice]) == nil then
    e.reference.data.spa_bloodyinjury[choice] = bodyParts[choice]
end
    for _,part in pairs(bodyParts[choice]) do
        for _,layer in pairs(tes3.activeBodyPartLayer) do
            local activpart = e.reference.bodyPartManager:getActiveBodyPart(layer, part)
            if activpart and activpart.node then
                debug.log(e.mobile.health.normalized)
                addDecal(e.reference, part, activpart.node)
            end
        end
    end
end)

---@param e bodyPartsUpdatedEventData
event.register("bodyPartAssigned", function(e)
    if not e.reference then return end
    if not e.reference.data then return end
    if not e.reference.data.spa_bloodyinjury then return end
    if e.reference.mobile.health.normalized > 0.75 then
        e.reference.data.spa_bloodyinjury = {}
        e.reference.data.spa_bloodydontrandom = {}
        return
    end
    for _,subtable in pairs(e.reference.data.spa_bloodyinjury) do
        if table.find(subtable, e.index) then
            for _,layer in pairs(tes3.activeBodyPartLayer) do
                ---@diagnostic disable-next-line: undefined-field
                timer.frame.delayOneFrame(function()
                local activpart = e.manager:getActiveBodyPart(layer, e.index)
                    if activpart and activpart.node then
                        addDecal(e.reference, e.index, activpart.node)
                    end
                end)
            end
        end
    end
end)




local function getExclusionList()
    local fullbooklist = {}
    for book in tes3.iterateObjects(tes3.objectType.book) do
        if not (string.find(book.id:lower(), "skill")) then
            table.insert(fullbooklist, book.id)
        end
    end
    table.sort(fullbooklist)
    return fullbooklist
end

local function registerModConfig()
    local template = mwse.mcm.createTemplate(mod.name)
    template:saveOnClose(mod.name, cf)
    template:register()

    local page = template:createSideBarPage({label="\""..mod.name.."\" Settings"})
    page.sidebar:createInfo{ text = "Welcome to \""..mod.name.."\" Configuration Menu. \n \n \n A mod by Spammer."}
    page.sidebar:createHyperLink{ text = "Spammer's Nexus Profile", url = "https://www.nexusmods.com/users/140139148?tab=user+files" }

    local category0 = page:createCategory(" ")
    category0:createOnOffButton{label = " ", description = " ", variable = mwse.mcm.createTableVariable{id = "onOff", table = cf}}

    category0:createKeyBinder{label = " ", description = " ", allowCombinations = false, variable = mwse.mcm.createTableVariable{id = "key", table = cf, restartRequired = true, defaultSetting = {keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false}}}

    local category1 = page:createCategory(" ")
    local elementGroup = category1:createCategory("")

    elementGroup:createDropdown { description = " ",
        options  = {
            { label = " ", value = 0 },
            { label = " ", value = 1 },
            { label = " ", value = 2 },
            { label = " ", value = 3 },
            { label = " ", value = 4 },
            { label = " ", value = -1}
        },
        variable = mwse.mcm:createTableVariable {
            id    = "dropDown",
            table = cf
        }
    }

    elementGroup:createTextField{
        label = " ",
        variable = mwse.mcm.createTableVariable{
            id = "textfield",
            table = cf,
            numbersOnly = false,
        }
    }

    local category2 = page:createCategory(" ")
    local subcat = category2:createCategory(" ")

    subcat:createSlider{label = " ", description = " ", min = 0, max = 10, step = 1, jump = 1, variable = mwse.mcm.createTableVariable{id = "slider", table = cf}}

    subcat:createSlider{label = " ".."%s%%", description = " ", min = 0, max = 100, step = 1, jump = 10, variable = mwse.mcm.createTableVariable{id = "sliderpercent", table = cf}}

    template:createExclusionsPage{label = " ", description = " ", variable = mwse.mcm.createTableVariable{id = "blocked", table = cf}, filters = {{label = " ", callback = getExclusionList}}}

    template:createExclusionsPage{label = " ", description = " ", variable = mwse.mcm.createTableVariable{id = "npcs", table = cf}, filters = {{label = "NPCs", type = "Object", objectType = tes3.objectType.npc}}}

    local page2 = template:createSideBarPage({label = "Extermination list"})
    page2:createButton{
        buttonText = "Switch",
        callback = function()
            cf.switch = not cf.switch
            local pageBlock = template.elements.pageBlock
            pageBlock:destroyChildren()
            page2:create(pageBlock)
            template.currentPage = page2
            pageBlock:getTopLevelParent():updateLayout()
        end,
        inGameOnly = false}
    local category = page2:createCategory("")
    category:createInfo{
        text = "",
        inGameOnly = false,
        postCreate = function(self)
        if cf.switch then
            self.elements.info.text = "Creatures gone extinct:"
            self.elements.info.color = tes3ui.getPalette("journal_finished_quest_pressed_color")
        else
            self.elements.info.text = "Creatures you've killed:"
            self.elements.info.color = tes3ui.getPalette("journal_finished_quest_pressed_color")
        end
    end}
    category:createInfo{
        text = "Load a saved game to see this.",
        inGameOnly = true,
        postCreate = function(self)
        if cf.switch then
            if tes3.player then
                local list = ""
                for actor,value in pairs(tes3.getKillCounts()) do
                    if (actor.objectType == tes3.objectType.creature) and (value >= tonumber(cf.slider)) then
                        list = actor.name.."s (RIP)".."\n" .. list
                    end
                end
                if list == "" then
                    list = "None."
                end
                self.elements.info.text = list
            end
        else
            if tes3.player then
                local list = ""
                for actor,value in pairs(tes3.getKillCounts()) do
                    if (actor.objectType == tes3.objectType.creature) and actor.cloneCount > 1 then
                        list = actor.name.."s: "..value.."\n" .. list
                    end
                end
                if list == "" then
                    list = "None."
                end
                self.elements.info.text = list
            end
        end
    end}
end --event.register("modConfigReady", registerModConfig)

event.register("initialized", function()
event.register("menuEnter", onMenuEnterExit)
event.register("menuExit", onMenuEnterExit)
print("["..mod.name..", by Spammer] "..mod.ver.." Initialized!")
    for k in pairs(decalTextures) do
        decalTextures[k] = niSourceTexture.createFromPath(k)
    end
end)

