local ui, I = require("openmw.ui"), require("openmw.interfaces")
local v2, util, cam, core, self, nearby, types, Camera, input, storage =
    require("openmw.util").vector2, require("openmw.util"),
    require("openmw.interfaces").Camera, require("openmw.core"),
    require("openmw.self"), require("openmw.nearby"),
    require("openmw.types"), require("openmw.camera"),
    require("openmw.input"), require("openmw.storage")

local zu
local interfaceModifier = ""
local function addItem(actor, itemId, count)
    --Adds an item to the player-s inventory.
    if (count == nil) then count = 1 end
    core.sendGlobalEvent("ZackUtilsAddItem",
        { actor = actor, itemId = itemId, count = count })
end
local function removeItem(actor, itemId, count)
    if (count == nil) then count = 1 end
    core.sendGlobalEvent("removeItemCount",
        { actor = actor, itemId = itemId, count = count })
end


local function findPosByOnNavMesh(toPosition, startPosition)
    --Finds the last position on a path generated by nearby.findPath.
    local ret = nil
    local result, table = nearby.findPath(startPosition, toPosition)
    for _, staticEntry in ipairs(table) do ret = staticEntry end
    return ret
end
local function getPositionBehind(obj)
    local distance = 164
    local currentRotation = -obj.rotation.z
    currentRotation = currentRotation - math.rad(-90)
    local obj_x_offset = distance * math.cos(currentRotation + math.pi)
    local obj_y_offset = distance * math.sin(currentRotation + math.pi)
    local obj_x_position = obj.position.x + obj_x_offset
    local obj_y_position = obj.position.y + obj_y_offset
    return util.vector3(obj_x_position, obj_y_position, obj.position.z)
end


local function getInventory(object)
    --Gets the inventory of an object, actor or container.
    if (object.type == types.NPC or object.type == types.Creature or object.type ==
            types.Player) then
        return types.Actor.inventory(object)
    elseif (object.type == types.Container) then
        return types.Container.content(object)
    end
end
local function getFatigueTerm(actor)
    --Used for getBarterOffer, which attempts to replicate the vanilla calculation for barter offering.
    local max = types.Actor.stats.dynamic.fatigue(actor).base +
        types.Actor.stats.dynamic.fatigue(actor).modifier
    local current = types.Actor.stats.dynamic.fatigue(actor).current

    local normalised = math.floor(max) == 0 and 1 or math.max(0, current / max)

    local fFatigueBase = core.getGMST("fFatigueBase")
    local fFatigueMult = core.getGMST("fFatigueMult")

    return fFatigueBase - fFatigueMult * (1 - normalised)
end

local function getBarterOffer(npc, basePrice, disposition, buying)
    local disposition = 50

    local player = self
    local playerMerc = types.NPC.stats.skills.mercantile(self).modified

    local playerLuck = types.Actor.stats.attributes.luck(self).modified
    local playerPers = types.Actor.stats.attributes.personality(self).modified

    local playerFatigueTerm = getFatigueTerm(self)
    local npcFatigueTerm = getFatigueTerm(npc)

    -- Calculate the remaining parts of the function using the provided variables/methods
    local clampedDisposition = disposition
    local a = math.min(playerMerc, 100)
    local b = math.min(0.1 * playerLuck, 10)
    local c = math.min(0.2 * playerPers, 10)
    local d = math.min(types.NPC.stats.skills.mercantile(npc).modified, 100)
    local e =
        math.min(0.1 * types.Actor.stats.attributes.luck(npc).modified, 10)
    local f = math.min(0.2 *
        types.Actor.stats.attributes.personality(npc)
        .modified, 10)
    local pcTerm = (clampedDisposition - 50 + a + b + c) * playerFatigueTerm
    local npcTerm = (d + e + f) * npcFatigueTerm
    local buyTerm = 0.01 * (100 - 0.5 * (pcTerm - npcTerm))
    local sellTerm = 0.01 * (50 - 0.5 * (npcTerm - pcTerm))
    local offerPrice = math.floor(basePrice * (buying and buyTerm or sellTerm))
    return math.max(1, offerPrice)
end
local function teleportItem(item, position, rotation)
    --Teleports the specified gameobject to the specified position, in the same cell/worldspace.
    core.sendGlobalEvent("ZackUtilsTeleport", {
        item = item,
        position = position,
        rotation = rotation
    })
end
local function teleportItemToCell(item, cellname, position, rotation)
    --Teleports the specified gameobject to the specified position.
    core.sendGlobalEvent("ZackUtilsTeleportToCell", {
        cellname = cellname,
        item = item,
        position = position,
        rotation = rotation
    })
end
local returnRef = nil
local function createItem(itemid, cell, position, rotation)
    --Spawns an item at the sepecified position.
    returnRef = nil
    core.sendGlobalEvent("ZackUtilsCreate", {
        itemid = itemid,
        cell = cell.id,
        position = position,
        rotation = rotation,
        player = self
    })
end
local function createItemResult()
    --Allows a player script to get the created item.
    if (returnRef == nil) then return end

    local refRet = returnRef
    returnRef = nil
    return refRet
end
local ctrl = input.CONTROLLER_BUTTON
local controllerButtonData = { --Maps controller buttons to text
    { id = ctrl.A,    text = "A" }, { id = ctrl.B, text = "B" },
    { id = ctrl.Back, text = "Back" }, { id = ctrl.DPadDown, text = "DPadDown" },
    { id = ctrl.DPadLeft,  text = "DPadLeft" },
    { id = ctrl.DPadRight, text = "DPadRight" },
    { id = ctrl.DPadUp,    text = "DPadUp" }, { id = ctrl.Guide, text = "Guide" },
    { id = ctrl.LeftShoulder,  text = "Left Shoulder" },
    { id = ctrl.LeftStick,     text = "Left Stick Press" },
    { id = ctrl.RightShoulder, text = "Right Shoulder" },
    { id = ctrl.RightStick,    text = "Right Stick Press" },
    { id = ctrl.Start,         text = "Start" }, { id = ctrl.Y, text = "Y" },
    { id = ctrl.X, text = "X" }
}

--Buttons that generally shouldn't be used, since they can't be rebound.
local ignoreButtons = {
    { id = ctrl.DPadDown,  text = "DPadDown" },
    { id = ctrl.DPadLeft,  text = "DPadLeft" },
    { id = ctrl.DPadRight, text = "DPadRight" },
    { id = ctrl.DPadUp,    text = "DPadUp" }, { id = ctrl.Guide, text = "Guide" }

}
local function getAllCtrlButtons() --Gets the controllerButtonData table, minus the entries in ignoreButtons.
    local ret = {}
    for i, button in ipairs(controllerButtonData) do
        local ignore = false
        for i, igbutton in ipairs(ignoreButtons) do
            if (igbutton == button) then ignore = true end
        end
        if (ignore == false) then table.insert(ret, button.text) end
    end

    return ret
end
local function controllerButtonToText(button) end --Unimplemented
local function addSpell(SpellId)                  --Adds the specified spell to the player's spellbook.
    local valid = false
    local spellToAdd = nil
    for index, value in ipairs(core.magic.spells.records) do
        if (value.id == SpellId) then
            valid = true
            spellToAdd = value
        end
    end
    if (valid) then
        types.Actor.spells(self):add(SpellId)
        return "Added spell " .. spellToAdd.name
    end
    return "Spell " .. SpellId .. " not found."
end
local function removeSpell(spellName) --Removes the specified spell from the player' spellbook.
    for index, value in ipairs(types.Actor.spells(self)) do
        if (value.id == spellName) then
            types.Actor.spells(self):remove(spellName)
            return "Removed spell " .. value.name
        end
    end
    return "Spell " .. spellName .. " not found."
end
local function hasSpell(spellName) --Checks if the player's spellbook contains the specified spell.
    if (spellName.id ~= nil) then spellName = spellName.id end
    for index, value in ipairs(types.Actor.spells(self)) do
        if (value.id == spellName) then return true end
    end
    return false
end
local function createItemReturn(data) returnRef = data end                        --Event for setting the created item above.
local function deleteItem(item) core.sendGlobalEvent("ZackUtilsDelete", item) end --Deletes the specified object permenently.
local itemTypes = {                                                               --All item types, with text.
    { name = "Apparatus", type = types.Apparatus },
    { name = "Armor",     type = types.Armor }, { name = "Book", type = types.Book },
    { name = "Clothing",   type = types.Clothing },
    { name = "Ingredient", type = types.Ingredient },
    { name = "Light",      type = types.Light },
    { name = "Lockpick",   type = types.Lockpick },
    { name = "misc",       type = types.Miscellaneous },
    { name = "Potion",     type = types.Potion },
    { name = "Probe",      type = types.Probe },
    { name = "Repair",     type = types.Repair },
    { name = "Weapon",     type = types.Weapon }, { name = "item", type = types.Item }
}

local function findItemRecord(recordId) --FInds a record for any item.
    for index, typ in ipairs(itemTypes) do
        for x, record in ipairs(typ.type.records) do
            if (record.id == recordId) then return record end
        end
    end
    return nil
end
local function findItemType(recordId) --Finds an item's type.
    for index, typ in ipairs(itemTypes) do
        for x, record in ipairs(typ.type.records) do
            if (record.id == recordId) then return typ end
        end
    end
    return nil
end
local function FindGameObjectName(item)
    if (item == nil or item.type == nil or item.type.records[item.recordId] == nil) then
        return nil
    end
    return item.type.records[item.recordId].name
end

local function FindEnchant(item)
    if (item == nil or item.type == nil or item.type.records[item.recordId] == nil or item.type.records[item.recordId].enchant == nil) then
        return nil
    end
    return item.type.records[item.recordId].enchant
end
local function findItemIcon(item)
    if (item == nil or item.type == nil or item.type.records[item.recordId] == nil or item.type.records[item.recordId].icon == nil) then
        return nil
    end
    return item.type.records[item.recordId].icon
end
local function findItemWeight(item)
    if (item == nil or item.type == nil or item.type.records[item.recordId] == nil or item.type.records[item.recordId].weight == nil) then
        return nil
    end
    return item.type.records[item.recordId].weight
end
local renderresult = nil
local function returnHighestPoint(result) -- called by the findHighestPoint function
    print("Returned")
    renderresult = result
end
local function waitForRenderResult() -- returns result asked for before
    if (renderresult ~= nil) then
        local ret = renderresult
        renderresult = nil
        return ret
    end
    return nil
end
local function findHighestPoint(worldpoint) -- called from outside
    local targetPoint = util.vector3(worldpoint.x, worldpoint.y, 0)
    nearby.asyncCastRenderingRay(returnHighestPoint, worldpoint, targetPoint)
end
local recordsCache = {}
local function CheckitemsToAddForRecord(recordId, type)
    recordId = string.lower(recordId)
    local records = recordsCache[type]
    if not records then
        records = {}
        for i, record in ipairs(type.records) do
            records[string.lower(record.id)] = true
        end
        recordsCache[type] = records
    end
    return records[recordId] ~= nil
end
local function itemIsEquipped(item, actor)
    --Checks if item record is equipped on the specified actor
    if (actor == nil) then actor = self end
    if (actor.type ~= types.NPC and actor.type ~= types.Creature and actor.type ~=
            types.Player) then
        print("invalid type")
        return false
    end
    for slot = 1, 17 do
        if (types.Actor.equipment(actor, slot)) then
            if (item.id == types.Actor.equipment(actor, slot).id) then
                return true
            end
        end
    end
    return false
end
local function findSlot(item)
    if (item == nil) then
        return
    end
    --Finds a equipment slot for an inventory item, if it has one,
    if item.type == types.Armor then
        if (types.Armor.records[item.recordId].type == types.ArmorTYPE.RGauntlet) then
            return types.Actor.EQUIPMENT_SLOT.RightGauntlet
        elseif (types.Armor.records[item.recordId].type == types.ArmorTYPE.LGauntlet) then
            return types.Actor.EQUIPMENT_SLOT.LeftGauntlet
        elseif (types.Armor.records[item.recordId].type == types.ArmorTYPE.Boots) then
            return types.Actor.EQUIPMENT_SLOT.Boots
        elseif (types.Armor.records[item.recordId].type == types.ArmorTYPE.Cuirass) then
            return types.Actor.EQUIPMENT_SLOT.Cuirass
        elseif (types.Armor.records[item.recordId].type == types.ArmorTYPE.Greaves) then
            return types.Actor.EQUIPMENT_SLOT.Greaves
        elseif (types.Armor.records[item.recordId].type == types.ArmorTYPE.LBracer) then
            return types.Actor.EQUIPMENT_SLOT.RightGauntlet
        elseif (types.Armor.records[item.recordId].type == types.ArmorTYPE.RBracer) then
            return types.Actor.EQUIPMENT_SLOT.LeftGauntlet
        elseif (types.Armor.records[item.recordId].type == types.ArmorTYPE.RPauldron) then
            return types.Actor.EQUIPMENT_SLOT.LeftGauntlet
        elseif (types.Armor.records[item.recordId].type == types.ArmorTYPE.LPauldron) then
            return types.Actor.EQUIPMENT_SLOT.LeftPauldron
        elseif (types.Armor.records[item.recordId].type == types.ArmorTYPE.RPauldron) then
            return types.Actor.EQUIPMENT_SLOT.RightPauldron
        end
    elseif item.type == types.Clothing then
        if (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Amulet) then
            return types.Actor.EQUIPMENT_SLOT.Amulet
        elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Belt) then
            return types.Actor.EQUIPMENT_SLOT.Belt
        elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.LGlove) then
            return types.Actor.EQUIPMENT_SLOT.LeftGauntlet
        elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.RGlove) then
            return types.Actor.EQUIPMENT_SLOT.RightGauntlet
        elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Ring) then
            return types.Actor.EQUIPMENT_SLOT.RightRing
        elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Skirt) then
            return types.Actor.EQUIPMENT_SLOT.Skirt
        elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Shirt) then
            return types.Actor.EQUIPMENT_SLOT.Shirt
        elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Shoes) then
            return types.Actor.EQUIPMENT_SLOT.Boots
        elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Robe) then
            return types.Actor.EQUIPMENT_SLOT.Robe
        elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Pants) then
            return types.Actor.EQUIPMENT_SLOT.Pants
        end
    elseif item.type == types.Weapon then
        if (item.type.records[item.recordId].type == types.Weapon.TYPE.Arrow or item.type.records[item.recordId].type == types.Weapon.TYPE.Bolt) then
            return types.Actor.EQUIPMENT_SLOT.Ammunition
        end
        return types.Actor.EQUIPMENT_SLOT.CarriedRight
    end
    -- print("Couldn't find slot for " .. item.recordId)
    return nil
end
local function getEquippedInSlot(slot, actor)
    local equip = types.Actor.getEquipment(actor)
    for index, itemId in pairs(equip) do
        if (index == slot) then return itemId end
    end
end

local function equipItem(itemId)
    if (itemId.recordId ~= nil) then
        itemId = itemId.recordId
    end
    if (itemId == nil) then return nil end
    if (itemId.recordId ~= nil) then itemId = itemId.recordId end
    local inv = types.Actor.inventory(self)
    local item = inv:find(itemId)
    local slot = findSlot(item)
    if (slot) then
        local equip = types.Actor.getEquipment(self)
        equip[slot] = item
        types.Actor.setEquipment(self, equip)
    end
end
local function equipItems(itemTable)
    local inv = types.Actor.inventory(self)

    local equip = types.Actor.getEquipment(self)
    for index, itemId in ipairs(itemTable) do
        local item = inv:find(itemId)
        local slot = findSlot(item)
        if (slot) then equip[slot] = item end
    end

    types.Actor.setEquipment(self, equip)
end
local function addItemEquip(actor, itemId)
    local count = 1

    core.sendGlobalEvent("ZackUtilsAddItem", {
        actor = actor,
        itemId = itemId,
        count = count,
        equip = true
    })
end


local function addItemEquipReturn(data) equipItem(data.recordId) end
local function addItemsEquip(actor, itemIds)
    --adds items to a actor, then equips them. Requires the target actor have a valid script to recieve the equip event.
    local count = 1

    core.sendGlobalEvent("ZackUtilsAddItems", {
        actor = actor,
        itemIds = itemIds,
        count = count,
        equip = true
    })
end

local function addItemsEquipReturn(data) equipItems(data.table) end
local function unequipItem(itemId)
    local inv = types.Actor.inventory(self)
    local item = inv:find(itemId)
    local slot = findSlot(item)
    if (slot) then
        local equip = types.Actor.getEquipment(self)
        equip[slot] = nil
        types.Actor.setEquipment(self, equip)
    end
end
local function PauseWorld(doPause)
    core.sendGlobalEvent("ZackUtilsPauseWorld", doPause)
end
local function startsWith(str, prefix) --Checks if a string starts with another string
    return string.sub(str, 1, string.len(prefix)) == prefix
end
local function anglesToV(pitch, yaw)
    local xzLen = math.cos(pitch)
    return util.vector3(xzLen * math.sin(yaw), -- x
        xzLen * math.cos(yaw),                 -- y
        math.sin(pitch)                        -- z
    )
end
local function getCameraDirData(sourcePos)
    local pos = sourcePos
    local pitch, yaw

    pitch = -(Camera.getPitch() + Camera.getExtraPitch())
    yaw = (Camera.getYaw() + Camera.getExtraYaw())

    return pos, anglesToV(pitch, yaw)
end
local function getObjInCrosshairs(ignoreOb, mdist, alwaysPost, sourcePos) --Gets the object the player is looking at. Does not work in third person.
    if not sourcePos then
        sourcePos = Camera.getPosition()
    end
    local pos, v = getCameraDirData(sourcePos)

    local dist = 500
    if (mdist ~= nil) then dist = mdist end

    if (ignoreOb) then
        local ret = nearby.castRay(pos, pos + v * dist, { ignore = ignoreOb })
        return ret
    else
        local ret = nearby.castRenderingRay(pos, pos + v * dist)
        local destPos = (pos + v * dist)
        if (alwaysPost and ret.hitPos == nil) then
            return { hitPos = destPos }
        end
        return ret, destPos
    end
end

local function printToConsole(message, color) --Prints to the console.
    if (color == nil) then color = ui.CONSOLE_COLOR.Default end
    if (message == nil) then
        print("Message is nil!")
        return
    end
    ui.printToConsole(message, color)
end
local function setSimulationTimeScale(scale)
    core.sendGlobalEvent("setSimulationTimeScale", scale)
end
local function printToConsoleEvent(data)
    local message = data.message

    local color
    if (data.color ~= nil) then
        color = data.color:lower()
    end
    print("print time")
    if (color == nil) then
        color = ui.CONSOLE_COLOR.Info
    elseif color == "info" then
        color = ui.CONSOLE_COLOR.Info
    elseif color == "error" then
        color = ui.CONSOLE_COLOR.Error
    elseif color == "default" then
        color = ui.CONSOLE_COLOR.Default
    elseif color == "success" then
        color = ui.CONSOLE_COLOR.Success
    else
        color = ui.CONSOLE_COLOR.Info
    end
    if (message == nil) then
        print("Message is nil!")
        return
    end
    ui.printToConsole(message, color)
end
local function getPosInCrosshairs(mdist)
    local pos, v = getCameraDirData()

    local dist = 500
    if (mdist ~= nil) then dist = mdist end

    return pos + v * dist
end
local function isSelf(t) return t == self.object end
local function tpToPoint(actor)
    local highPoint = nearby.castRay(util.vector3(actor.position.x,
            actor.position.y,
            actor.position.z + 10000),
        actor.position)
    local point = nearby.findRandomPointAroundCircle(highPoint.hitPos, 100)

    teleportItem(actor, point)
end
local function drawPath(toPosition, startPosition)
    local ret = nil
    local result, table = nearby.findPath(startPosition, toPosition)
    for _, staticEntry in ipairs(table) do
        createItem("misc_soulgem_grand", self.cell, staticEntry)
    end
    return ret
end
local function showMessageEvent(message)
    ui.showMessage(message)
end
local allTypes = {
    { name = "Apparatus", type = types.Apparatus },
    { name = "Armor",     type = types.Armor }, { name = "Book", type = types.Book },
    { name = "Clothing",   type = types.Clothing },
    { name = "Ingredient", type = types.Ingredient },
    { name = "Light",      type = types.Light },
    { name = "Lockpick",   type = types.Lockpick },
    { name = "misc",       type = types.Miscellaneous },
    { name = "Potion",     type = types.Potion },
    { name = "Probe",      type = types.Probe },
    { name = "Repair",     type = types.Repair },
    { name = "Weapon",     type = types.Weapon },
    { name = "Creature",   type = types.Creature },
    { name = "Door",       type = types.Door }, { name = "NPC", type = types.NPC },
    { name = "Player", type = types.Player },
    { name = "Static", type = types.Static }
}

local function getLinePoints(startPos, endPos, numPointsPerUnitDistance)
    local distance = math.sqrt((endPos.x - startPos.x) ^ 2 +
        (endPos.y - startPos.y) ^ 2 +
        (endPos.z - startPos.z) ^ 2)
    local numPoints = math.max(2,
        math.floor(numPointsPerUnitDistance * distance))

    local linePoints = {}
    for i = 1, numPoints do
        local t = (i - 1) / (numPoints - 1)
        local x = startPos.x + (endPos.x - startPos.x) * t
        local y = startPos.y + (endPos.y - startPos.y) * t
        local z = startPos.z + (endPos.z - startPos.z) * t
        table.insert(linePoints, util.vector3(x, y, z))
    end

    -- sangle = math.atan2(endPos.y - startPos.y, endPos.x - startPos.x)

    return linePoints
end
local function hasItemIDEquipped(itemID)
    local item = types.Actor.inventory(self):find(itemID)
    if not item then return false end

    if types.Actor.getEquipped(self, item) then return true end
    return false
end
local function distanceBetweenPos(vector1, vector2)
    --Quick way to find out the distance between two vectors.
    --Very similar to getdistance in mwscript
    local dx = vector2.x - vector1.x
    local dy = vector2.y - vector1.y
    local dz = vector2.z - vector1.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end
local function onInit()
    zu = I.ZackUtils
    print("Loaded ZU")
end

return {
    interfaceName = "ZackUtils",
    interface = {
        version = 1,
        addItem = addItem,
        removeItem = removeItem,
        getInventory = getInventory,
        findSlot = findSlot,
        getEquippedInSlot = getEquippedInSlot,
        findItemIcon = findItemIcon,
        FindEnchant = FindEnchant,
        waitForRenderResult = waitForRenderResult,
        FindGameObjectName = FindGameObjectName,
        findHighestPoint = findHighestPoint,
        PauseWorld = PauseWorld,
        hasItemIDEquipped = hasItemIDEquipped,
        CheckForRecord = CheckForRecord,
        itemIsEquipped = itemIsEquipped,
        drawPath = drawPath,
        distanceBetweenPos = distanceBetweenPos,
        tpToPoint = tpToPoint,
        findItemWeight = findItemWeight,
        equipItem = equipItem,
        returnHighestPoint = returnHighestPoint,
        getObjInCrosshairs = getObjInCrosshairs,
        teleportItem = teleportItem,
        teleportItemToCell = teleportItemToCell,
        getPosInCrosshairs = getPosInCrosshairs,
        getLinePoints = getLinePoints,
        deleteItem = deleteItem,
        createItem = createItem,
        findPosByOnNavMesh = findPosByOnNavMesh,
        unequipItem = unequipItem,
        createItemResult = createItemResult,
        invTest = invTest,
        printToConsole = printToConsole,
        printToConsoleEvent = printToConsoleEvent,
        getBarterOffer = getBarterOffer,
        addItemEquip = addItemEquip,
        addItemsEquip = addItemsEquip,
        getAllCtrlButtons = getAllCtrlButtons,
        startsWith = startsWith,
        equipItems = equipItems,
        hasSpell = hasSpell,
        addSpell = addSpell,
        removeSpell = removeSpell,
        findItemRecord = findItemRecord,
        findItemType = findItemType,
        getPositionBehind = getPositionBehind,
        setSimulationTimeScale = setSimulationTimeScale,
    },
    eventHandlers = {
        createItemReturn = createItemReturn,
        printToConsoleEvent = printToConsoleEvent,
        addItemEquipReturn = addItemEquipReturn,
        addItemsEquipReturn = addItemsEquipReturn,
        equipItems = equipItems,
        showMessageEvent = showMessageEvent,
    },
    engineHandlers = { onInit = onInit, onLoad = onInit }
}
