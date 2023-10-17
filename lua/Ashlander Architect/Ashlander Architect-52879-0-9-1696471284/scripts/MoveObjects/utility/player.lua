local ui = require("openmw.ui")
local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local cam = require("openmw.interfaces").Camera
local core = require("openmw.core")
local self = require("openmw.self")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local Camera = require("openmw.camera")
local input = require("openmw.input")
local storage = require("openmw.storage")


local function addItem(actor, itemId, count)
    if (count == nil) then
        count = 1
    end
    core.sendGlobalEvent("ZackUtilsAddItem_AA", { actor = actor, itemId = itemId, count = count })
end

local function invTest()
    local light = types.Light.records
    for _, lightParent in ipairs(light) do
        local foundMatch = false

        -- search for a matching entry in statics
        if string.sub(lightParent.id, 1, 4) == "dhf_" then
            for _, lightChild in ipairs(light) do
                if lightChild.model:lower() == lightParent.model:lower() then
                    -- if a match is found, output the desired fields
                    print(lightChild.id .. "," .. lightParent.name .. ",light")
                    foundMatch = true
                    break
                end
            end
        end
    end
end

local function findPosByOnNavMesh(toPosition, startPosition)
    local ret = nil
    local result, table = nearby.findPath(startPosition, toPosition)
    for _, staticEntry in ipairs(table) do
        ret = staticEntry
    end
    return ret
end
local function getFatigueTerm(actor)
    local max = types.Actor.stats.dynamic.fatigue(actor).base + types.Actor.stats.dynamic.fatigue(actor).modifier
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
    local e = math.min(0.1 * types.Actor.stats.attributes.luck(npc).modified, 10)
    local f = math.min(0.2 * types.Actor.stats.attributes.personality(npc).modified, 10)
    local pcTerm = (clampedDisposition - 50 + a + b + c) * playerFatigueTerm
    local npcTerm = (d + e + f) * npcFatigueTerm
    local buyTerm = 0.01 * (100 - 0.5 * (pcTerm - npcTerm))
    local sellTerm = 0.01 * (50 - 0.5 * (npcTerm - pcTerm))
    local offerPrice = math.floor(basePrice * (buying and buyTerm or sellTerm))
    return math.max(1, offerPrice)
end
local function teleportItem(item, position, rotation)
    core.sendGlobalEvent("ZackUtilsTeleport_AA", { item = item, position = position, rotation = rotation })
end
local function teleportItemToCell(item, cellname, position, rotation)
    core.sendGlobalEvent("ZackUtilsTeleportToCell_AA",
        { cellname = cellname, item = item, position = position, rotation = rotation })
end
local returnRef = nil
local function createItem(itemid, cell, position, rotation)
    returnRef = nil
    core.sendGlobalEvent("ZackUtilsCreate_AA",
        { itemid = itemid, cell = cell.name, position = position, rotation = rotation, player = self })
end
local function createItemResult()
    if (returnRef == nil) then
        return
    end

    local refRet = returnRef
    returnRef = nil
    return refRet
end
local ctrl = input.CONTROLLER_BUTTON
local controllerButtonData = {
    { id = ctrl.A,             text = "A" },
    { id = ctrl.B,             text = "B" },
    { id = ctrl.Back,          text = "Back" },
    { id = ctrl.DPadDown,      text = "DPadDown" },
    { id = ctrl.DPadLeft,      text = "DPadLeft" },
    { id = ctrl.DPadRight,     text = "DPadRight" },
    { id = ctrl.DPadUp,        text = "DPadUp" },
    { id = ctrl.Guide,         text = "Guide" },
    { id = ctrl.LeftShoulder,  text = "Left Shoulder" },
    { id = ctrl.LeftStick,     text = "Left Stick Press" },
    { id = ctrl.RightShoulder, text = "Right Shoulder" },
    { id = ctrl.RightStick,    text = "Right Stick Press" },
    { id = ctrl.Start,         text = "Start" },
    { id = ctrl.Y,             text = "Y" },
    { id = ctrl.X,             text = "X" },
}
local ignoreButtons = {
    { id = ctrl.DPadDown,  text = "DPadDown" },
    { id = ctrl.DPadLeft,  text = "DPadLeft" },
    { id = ctrl.DPadRight, text = "DPadRight" },
    { id = ctrl.DPadUp,    text = "DPadUp" },
    { id = ctrl.Guide,     text = "Guide" },

}
local function getAllCtrlButtons()
    local ret = {}
    for i, button in ipairs(controllerButtonData) do
        local ignore = false
        for i, igbutton in ipairs(ignoreButtons) do
            if (igbutton == button) then
                ignore = true
            end
        end
        if (ignore == false) then
            table.insert(ret, button.text)
        end
    end

    return ret
end
local function controllerButtonToText(button)

end

local function createItemReturn(data)
    --  print("Got item back aa")
    --returnRef = data
end
local function deleteItem(item)
    core.sendGlobalEvent("ZackUtilsDelete_AA", item)
end

local function FindGameObjectName(item)
    if (item == nil) then
        return nil
    end
    if item.type == types.Apparatus then
        return types.Apparatus.record(item).name
    elseif item.type == types.Armor then
        return types.Armor.record(item).name
    elseif item.type == types.Book then
        return types.Book.record(item).name
    elseif item.type == types.Clothing then
        return types.Clothing.record(item).name
    elseif item.type == types.Ingredient then
        return types.Ingredient.record(item).name
    elseif item.type == types.Light then
        return types.Light.record(item).name
    elseif item.type == types.Lockpick then
        return types.Lockpick.record(item).name
    elseif item.type == types.Miscellaneous then
        return types.Miscellaneous.record(item).name
    elseif item.type == types.Potion then
        return types.Potion.record(item).name
    elseif item.type == types.Probe then
        return types.Probe.record(item).name
    elseif item.type == types.Repair then
        return types.Repair.record(item).name
    elseif item.type == types.Weapon then
        return types.Weapon.record(item).name
    elseif item.type == types.Activator then
        return types.Activator.record(item).name
    elseif item.type == types.Container then
        return types.Container.record(item).name
    elseif item.type == types.Door then
        return types.Door.record(item).name
    elseif item.type == types.NPC then
        return types.NPC.record(item).name
    elseif item.type == types.Creature then
        return types.Creature.record(item).name
    end
    return nil
end


local function FindEnchant(item)
    if (item == nil) then
        return false
    end
    if item.type == types.Armor then
        return types.Armor.record(item).enchant
    elseif item.type == types.Book then
        return types.Book.record(item).enchant
    elseif item.type == types.Clothing then
        return types.Clothing.record(item).enchant
    elseif item.type == types.Weapon then
        return types.Weapon.record(item).enchant
    end
    return false
end
local function findItemIcon(item)
    if item.type == types.Apparatus then
        return types.Apparatus.record(item).icon
    elseif item.type == types.Armor then
        return types.Armor.record(item).icon
    elseif item.type == types.Book then
        return types.Book.record(item).icon
    elseif item.type == types.Clothing then
        return types.Clothing.record(item).icon
    elseif item.type == types.Ingredient then
        return types.Ingredient.record(item).icon
    elseif item.type == types.Light then
        return types.Light.record(item).icon
    elseif item.type == types.Lockpick then
        return types.Lockpick.record(item).icon
    elseif item.type == types.Miscellaneous then
        return types.Miscellaneous.record(item).icon
    elseif item.type == types.Potion then
        return types.Potion.record(item).icon
    elseif item.type == types.Probe then
        return types.Probe.record(item).icon
    elseif item.type == types.Repair then
        return types.Repair.record(item).icon
    elseif item.type == types.Weapon then
        return types.Weapon.record(item).icon
    end
end
local function findItemWeight(item)
    if item.type == types.Apparatus then
        return types.Apparatus.record(item).weight
    elseif item.type == types.Armor then
        return types.Armor.record(item).weight
    elseif item.type == types.Book then
        return types.Book.record(item).weight
    elseif item.type == types.Clothing then
        return types.Clothing.record(item).weight
    elseif item.type == types.Ingredient then
        return types.Ingredient.record(item).weight
    elseif item.type == types.Light then
        return types.Light.record(item).weight
    elseif item.type == types.Lockpick then
        return types.Lockpick.record(item).weight
    elseif item.type == types.Miscellaneous then
        return types.Miscellaneous.record(item).weight
    elseif item.type == types.Potion then
        return types.Potion.record(item).weight
    elseif item.type == types.Probe then
        return types.Probe.record(item).weight
    elseif item.type == types.Repair then
        return types.Repair.record(item).weight
    elseif item.type == types.Weapon then
        return types.Weapon.record(item).weight
    end
end
local renderresult = nil
local function returnHighestPoint(result) --called by the findHighestPoint function
    print("Returned")
    renderresult = result
end
local function waitForRenderResult() --returns result asked for before
    if (renderresult ~= nil) then
        local ret = renderresult
        renderresult = nil
        return ret
    end
    return nil
end
local function findHighestPoint(worldpoint) --called from outside
    local targetPoint = util.vector3(worldpoint.x, worldpoint.y, 0)
    nearby.asyncCastRenderingRay(returnHighestPoint, worldpoint, targetPoint)
end
local recordsCache = {}
local function CheckForRecord(recordId, type)
    if (type == types.ESM4Static) then
        return true
    end
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
    for slot = 1, 17 do
        if (types.Actor.equipment(actor, slot)) then
            if (item.id == types.Actor.equipment(self, slot).id) then
                return true
            end
        end
    end
    return false
end
local function findSlot(item)
    if item.type == types.Armor then
        return types.Armor.record(item).enchant
    elseif item.type == types.Book then
        return types.Book.record(item).enchant
    elseif item.type == types.Clothing then
        if (types.Clothing.record(item).type == types.Clothing.TYPE.Amulet) then
            return types.Actor.EQUIPMENT_SLOT.Amulet
        elseif (types.Clothing.record(item).type == types.Clothing.TYPE.Skirt) then
            return types.Actor.EQUIPMENT_SLOT.Skirt
        elseif (types.Clothing.record(item).type == types.Clothing.TYPE.Shirt) then
            return types.Actor.EQUIPMENT_SLOT.Shirt
        elseif (types.Clothing.record(item).type == types.Clothing.TYPE.Shoes) then
            return types.Actor.EQUIPMENT_SLOT.Boots
        end
    elseif item.type == types.Weapon then
        return types.Actor.EQUIPMENT_SLOT.CarriedRight
    end
    print("Couldn't find slot for " .. item.recordId)
    return false
end
local function equipItem(itemId)
    local inv = types.Actor.inventory(self)
    local item = inv:find(itemId)
    local slot = findSlot(item)
    if (slot) then
        local equip = types.Actor.getEquipment(self)
        equip[slot] = item
        types.Actor.setEquipment(self, equip)
    end
end

local function addItemEquip(actor, itemId)
    local count = 1

    core.sendGlobalEvent("ZackUtilsAddItem_AA", { actor = actor, itemId = itemId, count = count, equip = true })
end

local function addItemEquipReturn(data)
    equipItem(data.recordId)
end
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
    core.sendGlobalEvent("ZackUtilsPauseWorld_AA", doPause)
end
local function anglesToV(pitch, yaw)
    local xzLen = math.cos(pitch)
    return util.vector3(
        xzLen * math.sin(yaw), -- x
        xzLen * math.cos(yaw), -- y
        math.sin(pitch)        -- z
    )
end
local function getCameraDirData()
    local pos = Camera.getPosition()
    local pitch, yaw

    pitch = -(Camera.getPitch() + Camera.getExtraPitch())
    yaw = (Camera.getYaw() + Camera.getExtraYaw())

    return pos, anglesToV(pitch, yaw)
end
local function startsWith(str, prefix)
    return string.sub(str, 1, string.len(prefix)) == prefix
end

local function getPosInCrosshairs(mdist)
    local pos, v = getCameraDirData()

    local dist = 500
    if (mdist ~= nil) then
        dist = mdist
    end

    return pos + v * dist
end
local function isObjectInTable(obj, table)
    for i, value in ipairs(table) do
        if value == obj then
            return true
        end
    end
    return false
end
local useRenderingRay = false
local function getObjInCrosshairs(ignoreOb, mdist, force)
    --ignoreOb is the object we are ignoring
    --mdist is the maximum distance we will search for
    if ignoreOb and type(ignoreOb) ~= "table" then
        ignoreOb = { ignoreOb }
    end
    local pos, v = getCameraDirData() --this function gets the position of the camera, and the angle of the camera

    local dist = 500
    if (mdist ~= nil) then
        dist = mdist
    end

    if (ignoreOb and not force) then --current functionality, have to do normal cast ray. This isn't great for placing items, since it will hit the hitbox of a bookshelf, not the shelf.
        return nearby.castRay(pos, pos + v * dist, { ignore = ignoreOb[1]

        })
    else
        if (ignoreOb) then
            if useRenderingRay then
                local ret = nearby.castRenderingRay(getPosInCrosshairs(20), pos + v * dist)
                local hpos = ret.hitPos
                if (ret.hitPos == nil) then
                    hpos = pos + v * dist
                end
                local previousXdist = I.ZackUtilsAA.distanceBetweenPos(getPosInCrosshairs(20), hpos)
                while true do
                    local res = nearby.castRenderingRay(pos, pos + v * dist)
                    if not res.hit or not isObjectInTable(res.hitObject, ignoreOb) then
                        return res
                    end
                    step = 128
                    for i = 1, 4 do
                        local backwardRay = nearby.castRenderingRay(pos + v * step, pos)
                        if not backwardRay.hit or isObjectInTable(backwardRay.hitObject, ignoreOb) then
                            break -- no other objects between `pos` and `pos + step * v`
                        else
                            step = step / 2
                        end
                    end
                    pos = pos + v * step
                    dist = dist - step
                end
                return ret
            else
               -- local ret = nearby.castRay(getPosInCrosshairs(20), pos + v * dist,{ignore = ignoreOb})
                return nearby.castRay(pos, pos + v * dist, { ignore = ignoreOb[1]

            })
            end
        end
        return nearby.castRenderingRay(pos, pos + v * dist)
    end
end

local function printToConsole(message, color)
    if (color == nil) then
        color = ui.CONSOLE_COLOR.Default
    end
    ui.printToConsole(message, color)
end
local function printToConsoleEvent(message)
    local color
    if (color == nil) then
        color = ui.CONSOLE_COLOR.Default
    end
    ui.printToConsole(message, color)
end
local function isSelf(t)
    return t == self.object
end

local function distanceBetweenPos(vector1, vector2)
    --Quick way to find out the distance between two vectors.
    --Very similar to getdistance in mwscript
    if (vector1 == nil or vector2 == nil) then
        error("Invalid position data provided")
    end
    local dx = vector2.x - vector1.x
    local dy = vector2.y - vector1.y
    local dz = vector2.z - vector1.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end
local function getLinePoints(startPos, endPos, numPointsPerUnitDistance)
    local distance = math.sqrt((endPos.x - startPos.x) ^ 2 + (endPos.y - startPos.y) ^ 2 + (endPos.z - startPos.z) ^ 2)
    local numPoints = math.max(2, math.floor(numPointsPerUnitDistance * distance))

    local linePoints = {}
    for i = 1, numPoints do
        local t = (i - 1) / (numPoints - 1)
        local x = startPos.x + (endPos.x - startPos.x) * t
        local y = startPos.y + (endPos.y - startPos.y) * t
        local z = startPos.z + (endPos.z - startPos.z) * t
        table.insert(linePoints, util.vector3(x, y, z))
    end

    --sangle = math.atan2(endPos.y - startPos.y, endPos.x - startPos.x)

    return linePoints
end

local function getObjectAngle(obj)
    local z, y, x = obj.rotation:getAnglesZYX()
    return { z = z, x = x, y = y }
end
return {
    interfaceName = "ZackUtilsAA",
    interface = {
        version = 1,
        addItem = addItem,
        findSlot = findSlot,
        findItemIcon = findItemIcon,
        FindEnchant = FindEnchant,
        getObjectAngle = getObjectAngle,
        waitForRenderResult = waitForRenderResult,
        FindGameObjectName = FindGameObjectName,
        findHighestPoint = findHighestPoint,
        PauseWorld = PauseWorld,
        CheckForRecord = CheckForRecord,
        itemIsEquipped = itemIsEquipped,
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
        printToConsoleEvent = printToConsoleEvent,
        getBarterOffer = getBarterOffer,
        addItemEquip = addItemEquip,
        getAllCtrlButtons = getAllCtrlButtons,
        startsWith = startsWith,
        distanceBetweenPos = distanceBetweenPos,
    },
    eventHandlers = {
        -- createItemReturn_AA = createItemReturn,
        printToConsoleEvent_AA = printToConsoleEvent,
        addItemEquipReturn_AA = addItemEquipReturn,
    },
}
