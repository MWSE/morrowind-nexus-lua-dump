local mod = {
    name = "Bleeding Injuries",
    ver = "1.5",
    cf = { magic = tes3.isLuaModActive("Elemental Effects"), fall = false, shield = true, blocked = {}}
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

local creatureDecals = {
    [0] = "textures\\tr\\tr_decal_blood_04.dds"
}

if tes3.isLuaModActive("Blood Diversity") then
    creatureDecals = {
        [0] = "textures\\Anu\\Blood\\tx_blood.dds",
        [5] = "textures\\Anu\\Blood\\tx_blood_blue.dds",
        [1] = "textures\\Anu\\Blood\\tx_blood_dust.dds",
        [4] = "textures\\Anu\\Blood\\tx_blood_ecto.dds",
        [7] = "textures\\Anu\\Blood\\tx_blood_energy.dds",
        [3] = "textures\\Anu\\Blood\\tx_blood_ichor.dds",
        [6] = "textures\\Anu\\Blood\\tx_blood_insect.dds",
        [2] = "textures\\Anu\\Blood\\tx_blood_sparks.dds",
    }
end

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


---@param ref tes3reference
---@param index number A value from [`tes3.activeBodyPart`](https://mwse.github.io/MWSE/references/active-body-parts/) namespace.
---@param sceneNode niNode
local function addDecal(ref, index, sceneNode)
    if not ref.data then return end
    if not ref.data.spa_bloodydontrandom then
        ref.data.spa_bloodydontrandom = {}
    end
    local choice = table.getset(ref.data.spa_bloodydontrandom, index, table.choice(decalTextures))
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
    if ref == tes3.player then
        tes3ui.updateInventoryCharacterImage()
    end
end

---@param index number
---@param sceneNode niNode
local function addCritDecal(index, sceneNode)
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
                    texturingProperty:addDecalMap(creatureDecals[index])
                    node:attachProperty(texturingProperty)
                    node:updateProperties()
            end
        end
    end
end

---@param texturingProperty niTexturingProperty
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

---@param ref tes3reference
---@param sceneNode niNode
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
    if ref == tes3.player then
        tes3ui.updateInventoryCharacterImage()
    end
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
        if  e.target.data.spa_bloodyinjury and table.size(e.target.data.spa_bloodyinjury) >= 1 then
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


local blacklistWeapons = {
    [tes3.weaponType.marksmanBow] = true,
    [tes3.weaponType.arrow] = true,
    [tes3.weaponType.marksmanCrossbow] = true,
    [tes3.weaponType.marksmanThrown] = true
}
---@param e damagedEventData
event.register("damaged", function(e)

if (e.source == "suffocation") or (e.source == "script") then
    return
elseif ((cf.fall) and (e.source == "fall")) then
    return
elseif ((cf.magic) and (e.source == "magic" or e.source == "shield")) then
    return
end

if ((cf.shield) and (tes3.isAffectedBy({reference = e.reference, effect = tes3.effect.shield}))) then
    return
end

local injuries = getInjuries(e.reference)
local ratio = e.mobile.health.normalized
if ((ratio >= 0.8)
or (ratio >= 0.6 and table.size(injuries) >= 1)
or (ratio >= 0.4 and table.size(injuries) >= 2)
or (ratio >= 0.3 and table.size(injuries) >= 3)
or (ratio >= 0.2 and table.size(injuries) >= 4))
then
    return
end

if (e.reference.object.objectType == tes3.objectType.creature)
and not cf.blocked[e.reference.baseObject.id]
and not cf.blocked[e.reference.object.id]
then
    local crit = e.reference.object
    if creatureDecals[crit.blood] then
        addCritDecal(crit.blood, e.reference.sceneNode)
    end

    if e.attacker
    and e.attackerReference.bodyPartManager
    and e.attacker.weaponDrawn
    and not blacklistWeapons[e.attacker.readiedWeapon.object.type] then
        for _,layer in pairs(tes3.activeBodyPartLayer) do
            local activpart = e.attackerReference.bodyPartManager:getActiveBodyPart(layer, tes3.activeBodyPart.weapon)
            if activpart and activpart.node then
                addCritDecal(e.reference.object.blood, activpart.node)
                if e.attacker == tes3.mobilePlayer then
                    local activpart2 = e.attacker.firstPersonReference.bodyPartManager:getActiveBodyPart(layer, tes3.activeBodyPart.weapon)
                    addCritDecal(e.reference.object.blood, activpart2.node)
                end
            end
        end
    end
end

if e.reference.object.objectType ~= tes3.objectType.npc then
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

if table.size(unprotected) == 0 then return end


if e.attacker
and e.attackerReference.bodyPartManager
and e.attacker.weaponDrawn
and not blacklistWeapons[e.attacker.readiedWeapon.object.type] then
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

local choice = table.choice(unprotected)
if table.find(injuries, bodyParts[choice]) == nil then
    e.reference.data.spa_bloodyinjury[choice] = bodyParts[choice]
end
    for _,part in pairs(bodyParts[choice]) do
        for _,layer in pairs(tes3.activeBodyPartLayer) do
            local activpart = e.reference.bodyPartManager:getActiveBodyPart(layer, part)
            if activpart and activpart.node then
                addDecal(e.reference, part, activpart.node)
            end
        end
    end
end)

---@param e bodyPartAssignedEventData
event.register("bodyPartAssigned", function(e)
    if not e.reference then return end
    if not e.reference.data then return end
    if not e.reference.data.spa_bloodyinjury then return end
    if e.reference.mobile and e.reference.mobile.health.normalized > 0.75 then
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
    local list = {}
    for crit in tes3.iterateObjects(tes3.objectType.creature) do
        if not (table.find(list, crit.id)) then
            table.insert(list, crit.id)
        end
        if string.find(crit.id:lower(), "dagoth")
        or string.find(crit.id:lower(), "ash_") then
            cf.blocked[crit.id] = true
        end
    end
    table.sort(list)
    return list
end

local function registerModConfig()
    local template = mwse.mcm.createTemplate(mod.name)
    template:saveOnClose(mod.name, cf)
    template:register()

    local page = template:createSideBarPage({label="\""..mod.name.."\" Settings"})
    page.sidebar:createInfo{ text = "Welcome to \""..mod.name.."\" Configuration Menu. \n \n \n A mod by Spammer."}
    page.sidebar:createHyperLink{ text = "Spammer's Nexus Profile", url = "https://www.nexusmods.com/users/140139148?tab=user+files" }

    local category0 = page:createCategory("Ignore fall damage?")
    category0:createYesNoButton{label = " ", variable = mwse.mcm.createTableVariable{id = "fall", table = cf}}

    local category1 = page:createCategory("Ignore magic damage?")
    category1:createYesNoButton{label = " ", variable = mwse.mcm.createTableVariable{id = "magic", table = cf}}

    local category2 = page:createCategory("\"Shield\" magic effect protects you from bleeding?")
    category2:createYesNoButton{label = " ", variable = mwse.mcm.createTableVariable{id = "shield", table = cf}}

    template:createExclusionsPage{label = "Creatures Blacklist", description = "Adding blood declas to some creatures seem to crash the game. Since there are too many for me to find out exactly which ones do cause crashes, I added this blacklist.", variable = mwse.mcm.createTableVariable{id = "blocked", table = cf}, filters = {{label = " ", callback = getExclusionList}}}

end event.register("modConfigReady", registerModConfig)

event.register("initialized", function()
event.register("menuEnter", onMenuEnterExit)
event.register("menuExit", onMenuEnterExit)
print("["..mod.name..", by Spammer] "..mod.ver.." Initialized!")
    for k in pairs(decalTextures) do
        decalTextures[k] = niSourceTexture.createFromPath(k)
        decalTextures[k].name = " Bleeding Injuries, by Spammer, path : ["..k.."]"
    end

    for k,v in pairs(creatureDecals) do
        creatureDecals[k] = niSourceTexture.createFromPath(v)
        creatureDecals[k].name = " Bleeding Injuries, by Spammer, path: ["..v.."]"
    end
end, {priority = -1000})