local mcm = require("sb_smith.mcm")
local interop = require("sb_smith.interop")
require("sb_smith.weapons")
require("sb_smith.weapons_tr")
require("sb_smith.weapons_bm")
local crafting = require("CraftingFramework.components.MenuActivator")
local recipe = require("CraftingFramework.components.Recipe")
local recipeList = require("sb_smith.recipes")

mcm.init()

local partData = {
    [tes3.weaponType.axeOneHand] = "a",
    [tes3.weaponType.axeTwoHand] = "a",
    [tes3.weaponType.bluntOneHand] = "b",
    [tes3.weaponType.bluntTwoClose] = "b",
    [tes3.weaponType.bluntTwoWide] = "b",
    [tes3.weaponType.shortBladeOneHand] = "sh",
    [tes3.weaponType.longBladeOneHand] = "l",
    [tes3.weaponType.longBladeTwoClose] = "l",
    [tes3.weaponType.spearTwoWide] = "sp"
}

---@type CraftingFramework.MenuActivator
local weaponSmith

local function repairToolRules(val)
    tes3.mobilePlayer:exerciseSkill(tes3.skill.armorer, val)
    if (mcm.config.faithfulEnabled == 1) then
        local check = tes3.random() <= (tes3.mobilePlayer.armorer.current + (tes3.mobilePlayer.strength.current / 10) + (tes3.mobilePlayer.luck.current / 10)) / (0.75 + (0.5 * tes3.mobilePlayer.fatigue.normalized))
        tes3.playSound{ reference = tes3.player, sound = check and "Repair" or "repair fail" }
        return check
    else
        tes3.playSound{ reference = tes3.player, sound = "Repair" }
        return true
    end
end

---@param sceneNode niNode
local function meshUpdate(sceneNode, mainWeapon, subWeapon, originalHandleParts, originalBladeParts)
    if (sceneNode:getObjectByName(originalHandleParts.handles[1]) == nil or subWeapon:getObjectByName(originalBladeParts.handles[1]) == nil) then return end
    ---@param value niNode
    for value in table.traverse(sceneNode.children) do
        if (value:isOfType(ni.type.NiTriShape)) then
            local delete = true
            for _, node in pairs(originalHandleParts.handles) do
                if (value.name == node) then
                    delete = false
                    break
                end
            end
            if (delete) then
                value.parent:detachChild(value)
            end
        end
    end
    local handleRoot = mainWeapon:getObjectByName(originalHandleParts.handles[originalHandleParts.rootIndexes[1]])
    local bladeRoot = subWeapon:getObjectByName(originalBladeParts.blades[originalBladeParts.rootIndexes[2]])
    local handleHigh = 0
    local bladeLow = 0
    if (handleRoot.controller) then
        for _, key in pairs(handleRoot.controller.data.positionKeys) do
            if (key.value.y > handleHigh) then
                handleHigh = key.value.y
            end
        end
        mwse.log("handleHigh = " .. handleHigh)
    end
    if (bladeRoot.controller) then
        bladeLow = 10000
        for _, key in pairs(bladeRoot.controller.data.positionKeys) do
            if (key.value.y < bladeLow) then
                bladeLow = key.value.y
            end
        end
        mwse.log("bladeLow = " .. bladeLow)
    end
    local handleRootBoundingBox = handleRoot:createBoundingBox()
    local bladeRootBoundingBox = bladeRoot:createBoundingBox()
    local diff = (bladeRootBoundingBox.min.y + bladeLow) - (handleRootBoundingBox.max.y + handleHigh)
    local handleOffset = originalHandleParts.rootOffset or {0, 0, 0}
    local bladeOffset = originalBladeParts.rootOffset or {0, 0, 0}
    local offsetDiff = {
        handleOffset[1] + bladeOffset[1],
        handleOffset[2] + bladeOffset[2],
        handleOffset[3] + bladeOffset[3]
    }
    for _, node in pairs(originalBladeParts.blades) do
        local newNode = subWeapon:getObjectByName(node):clone()
        newNode.data = newNode.data:copy()
        for _, vert in ipairs(newNode.vertices) do
            vert.x = vert.x + offsetDiff[1]
            vert.y = (vert.y - diff) + offsetDiff[2]
            vert.z = vert.z + offsetDiff[3]
        end
        newNode.translation.y = mainWeapon:getObjectByName(originalHandleParts.blades[originalHandleParts.rootIndexes[2]]).translation.y
        if (newNode.controller) then
            for _, key in pairs(newNode.controller.data.positionKeys) do
                mwse.log("---\ny: " .. key.value.y)
                key.value.x = key.value.x + offsetDiff[1]
                key.value.y = (key.value.y - diff) + offsetDiff[2]
                key.value.z = key.value.z + offsetDiff[3]
                mwse.log("new y: " .. key.value.y)
            end
            newNode.controller.data:updateDerivedValues()
        end
        sceneNode:getObjectByName(originalHandleParts.handles[originalHandleParts.rootIndexes[1]]).parent:attachChild(newNode)
    end
    sceneNode:update()
end

---@param weaponId string
local function splitWeapon(weaponId)
    local weaponObj = tes3.getObject(weaponId)
    local partRecipe = recipe:new{
        id = "sb_" .. weaponId .. "_break",
        craftableId = weaponId .. "_break",
        name = "Disassemble " .. weaponObj.name,
        persist = false,
        noResult = true,
        craftCallback = function(self, e)
            if (repairToolRules(0.4) == false) then
                tes3.messageBox{
                    message = "The weapon broke."
                }
                return
            end
            local weaponObj = tes3.getObject(weaponId)
            local materialData = {
                [(weaponObj.type == tes3.weaponType.bluntOneHand or weaponObj.type == tes3.weaponType.bluntTwoHand or weaponObj.type == tes3.weaponType.bluntTwoHanded) and "Head" or "Blade"] = weaponObj.id .. "_blade",
                ["Handle"] = weaponObj.id .. "_handle"
            }
            for name, data in pairs(materialData) do
                if (tes3.getObject(data) == nil) then
                    local partPrefix = "sb_smith/" .. (name == "Handle" and "h_" or "b_") .. partData[weaponObj.type]
                    tes3.createObject{
                        id = data,
                        objectType = tes3.objectType.miscItem,
                        name = name .. " (" .. weaponObj.name .. ")",
                        icon = partPrefix .. ".tga",
                        mesh = partPrefix .. ".nif",
                        value = weaponObj.value / (name == "Handle" and 3.0 or 1.5),
                        weight = weaponObj.weight / (name == "Handle" and 1.5 or 3.0),
                    }
                    if (tes3.player.data.sb_smith.weapons[weaponId] == nil) then
                        tes3.player.data.sb_smith.weapons[weaponId] = {}
                    end
                    table.insert(tes3.player.data.sb_smith.weapons[weaponId], data)
                end
                tes3.addItem{ reference = tes3.player, item = data, count = 1 }
            end
        end,
        materials = {
            {
                material = weaponId,
                count = 1
            }
        },
        category = "Disassemble Original",
        knowledgeRequirement = function (self)
            return tes3.player.object.inventory:getItemCount(weaponId) > 0
        end,
        keepMenuOpen = false
    }
    weaponSmith:addRecipe(partRecipe)
end

---@param weaponId string
---@param materialList string[]
local function splitNewWeapon(weaponId, materialList)
    local weaponObj = tes3.getObject(weaponId)
    local partRecipe = recipe:new{
        id = "sb_" .. weaponId .. "_break",
        craftableId = weaponId .. "_break",
        name = "Disassemble " .. weaponObj.name,
        persist = false,
        noResult = true,
        craftCallback = function(self, e)
            if (repairToolRules(0.4) == false) then
                tes3.messageBox{
                    message = "The weapon broke."
                }
                return
            end
            for _, part in ipairs(materialList) do
                tes3.addItem{ reference = tes3.player, item = part, count = 1 }
            end
        end,
        materials = {
            {
                material = weaponId,
                count = 1
            }
        },
        category = "Disassemble Crafted",
        knowledgeRequirement = function (self)
            return tes3.player.object.inventory:getItemCount(weaponId) > 0
        end,
        keepMenuOpen = false
    }
    weaponSmith:addRecipe(partRecipe)
end

---@param weaponId string
---@param handleId string
---@param bladeId string
local function fuseWeapon(weaponId, handleId, bladeId)
    local weapon = tes3.getObject(weaponId)
    local partRecipe = recipe:new{
        id = "sb_" .. weaponId .. "_fuse",
        craftableId = weaponId,
        name = "Assemble " .. weapon.name,
        persist = false,
        noResult = true,
        craftCallback = function(self, e)
            if (repairToolRules(0.8) == false) then
                tes3.messageBox{
                    message = "The weapon parts broke."
                }
                return
            end
            tes3.addItem{ reference = tes3.player, item = weaponId, count = 1 }
        end,
        materials = {
            {
                material = handleId,
                count = 1
            },
            {
                material = bladeId,
                count = 1
            }
        },
        category = "Assemble Original",
        knowledgeRequirement = function (self)
            return tes3.player.object.inventory:getItemCount(handleId) > 0 and tes3.player.object.inventory:getItemCount(bladeId) > 0
        end,
        keepMenuOpen = false
    }
    weaponSmith:addRecipe(partRecipe)
end

---@param handleId string
---@param bladeId string
---@param handlePartId string
---@param bladePartId string
local function fuseNewWeapon(handleId, bladeId, handlePartId, bladePartId)
    local handle = tes3.getObject(handleId)
    local blade = tes3.getObject(bladeId)
    local handlePart = tes3.getObject(handlePartId)
    local bladePart = tes3.getObject(bladePartId)
    local partRecipe = recipe:new{
        id = "sb_" .. handlePart.id .. "_" .. bladePart.id .. "_fuse",
        craftableId = handlePart.id .. "_" .. bladePart.id .. "_fuse",
        name = "Assemble " .. handlePart.name .. " and " .. bladePart.name,
        persist = false,
        noResult = true,
        craftCallback = function(self, e)
            if (repairToolRules(0.8) == false) then
                tes3.messageBox{
                    message = "The weapon parts broke."
                }
                return
            end
            local newWeaponId = "0_sb"
            for weaponId, originalParts in pairs(tes3.player.data.sb_smith.weapons) do
                mwse.log("smith:")
                mwse.log("  " .. weaponId .. " = " .. json.encode(originalParts))
                mwse.log("  " .. newWeaponId .. " = " .. json.encode(e.materialsUsed))
                mwse.log("  " .. tostring(e.materialsUsed[originalParts[1]]))
                mwse.log("  " .. tostring(e.materialsUsed[originalParts[2]]))
                local tempId = weaponId:gsub("_sb", "")
                local tempNewId = newWeaponId:gsub("_sb", "")
                if (weaponId == newWeaponId or (e.materialsUsed[originalParts[1]] and e.materialsUsed[originalParts[2]])) then
                    tes3.addItem{ reference = tes3.player, item = weaponId, count = 1 }
                    return
                elseif ((tonumber(tempId) ~= nil) and (tonumber(tempId) > tonumber(tempNewId))) then
                    newWeaponId = (tonumber(tempId) + 1) .. "_sb"
                elseif ((tonumber(tempId) == nil) and (tonumber(tempId) == tonumber(tempNewId))) then
                    newWeaponId = (tonumber(tempNewId) + 1) .. "_sb"
                end
                mwse.log("  tempId = " .. tempId)
                mwse.log("  newWeaponId = " .. newWeaponId)
            end
            local window = tes3ui.createMenu{
                id = "sb_smith_name",
                fixedFrame = true,
                keepMenuOpen = false
            }
            window.minWidth = 256
            local title = window:createLabel{
                text = "New Weapon Name",
            }
            title.absolutePosAlignX = 0.5
            local textInput = window:createTextInput{
                createBorder = true
            }
            tes3ui.acquireTextInput(textInput)
            local button = window:createButton{
                text = "Confirm"
            }
            button.absolutePosAlignX = 0.5
            button:register(tes3.uiEvent.mouseClick, function (e)
                if (textInput.text:trim() == "") then
                    tes3.messageBox{
                        message = "Your new weapon needs a name."
                    }
                else
                    mwse.log("newWeaponId = " .. newWeaponId)
                    mwse.log("  " .. json.encode({handlePartId, bladePartId}))
                    tes3.createObject{
                        id = newWeaponId;
                        objectType = tes3.objectType.weapon,
                        name = textInput.text:trim(),
                        icon = handle.icon,
                        mesh = handle.mesh,
                        value = (handle.value / 3.0) + (blade.value / 1.5),
                        weight = (handle.weight / 1.5) + (blade.weight / 3.0),
                        type = handle.type,
                        maxCondition = (handle.maxCondition / 2.0) + (blade.maxCondition / 2.0),
                        chopMin = (handle.chopMin / 3.0) + (blade.chopMin / 1.5),
                        chopMax = (handle.chopMax / 3.0) + (blade.chopMax / 1.5),
                        slashMin = (handle.slashMin / 3.0) + (blade.slashMin / 1.5),
                        slashMax = (handle.slashMax / 3.0) + (blade.slashMax / 1.5),
                        thrustMin = (handle.thrustMin / 1.5) + (blade.thrustMin / 3.0),
                        thrustMax = (handle.thrustMax / 1.5) + (blade.thrustMax / 3.0),
                        reach = (handle.reach / 2.0) + (blade.reach / 2.0),
                        speed = (handle.speed / 2.0) + (blade.speed / 2.0),
                    }
                    tes3.addItem{ reference = tes3.player, item = newWeaponId, count = 1 }
                    tes3.player.data.sb_smith.weapons[newWeaponId] = { handlePartId, bladePartId }
                    window:destroy()
                    tes3ui.leaveMenuMode()
                end
            end)
        end,
        materials = {
            {
                material = handlePartId,
                count = 1
            },
            {
                material = bladePartId,
                count = 1
            }
        },
        category = "Assemble Crafted",
        knowledgeRequirement = function (self)
            return tes3.player.object.inventory:getItemCount(handlePartId) > 0 and tes3.player.object.inventory:getItemCount(bladePartId) > 0
        end,
        keepMenuOpen = false
    }
    weaponSmith:addRecipe(partRecipe)
end

--- @param e activateEventData
local function activateCallback(e)
    if (e.activator == tes3.player and e.target.baseObject.id == "sb_smith") then
        for weaponId, weaponData in pairs(interop.weaponList) do
            if (tes3.player.object.inventory:findItemStack(weaponId) and weaponSmith:hasRecipe("sb_" .. weaponId .. "_break") == false) then
                splitWeapon(weaponId)
            end
        end
        for newWeaponId, originalParts in pairs(tes3.player.data.sb_smith.weapons) do
            local numCheck = newWeaponId:gsub("_sb", "")
            if (tes3.player.object.inventory:findItemStack(newWeaponId) and weaponSmith:hasRecipe("sb_" .. newWeaponId .. "_break") == false) then
                splitNewWeapon(newWeaponId, originalParts)
            end
            for newWeaponId2, originalParts2 in pairs(tes3.player.data.sb_smith.weapons) do
                local numCheck2 = newWeaponId2:gsub("_sb", "")
                if (tonumber(numCheck) == nil and tonumber(numCheck2) == nil and tes3.player.object.inventory:findItemStack(originalParts[1]) and tes3.player.object.inventory:findItemStack(originalParts2[2])) then
                    if (newWeaponId == newWeaponId2 and interop.weaponList[newWeaponId] and weaponSmith:hasRecipe("sb_" .. newWeaponId .. "_fuse") == false) then
                            fuseWeapon(newWeaponId, originalParts[1], originalParts2[2])
                    elseif (newWeaponId ~= newWeaponId2 and weaponSmith:hasRecipe("sb_" .. originalParts[1] .. "_" .. originalParts2[2] .. "_fuse") == false) then
                        fuseNewWeapon(newWeaponId, newWeaponId2, originalParts[1], originalParts2[2])
                    end
                end
            end
        end
        event.trigger("sb_smith")
    end
end
event.register(tes3.event.activate, activateCallback)

--- @param e referenceSceneNodeCreatedEventData
local function referenceSceneNodeCreatedCallback(e)
    if (e.reference.baseObject.id:match("_handle") == nil and e.reference.baseObject.id:match("_blade") == nil and e.reference.baseObject.id:match("_sb") == nil) then return end
    local originalId = e.reference.baseObject.id:gsub("_handle", ""):gsub("_blade", "")
    local numCheck = originalId:gsub("_sb", "")
    if (tonumber(numCheck) and tes3.player.data.sb_smith.weapons[originalId]) then
        local handleId = tes3.player.data.sb_smith.weapons[originalId][1]
        local bladeId = tes3.player.data.sb_smith.weapons[originalId][2]
        local originalHandleParts = interop.weaponList[handleId:gsub("_handle", "")]
        local originalBladeParts = interop.weaponList[bladeId:gsub("_blade", "")]
        local mainWeapon = e.reference.sceneNode:clone()
        local subWeapon = tes3.loadMesh(tes3.getObject(bladeId:gsub("_blade", "")).mesh)
        meshUpdate(e.reference.sceneNode, mainWeapon, subWeapon, originalHandleParts, originalBladeParts)
        e.reference.sceneNode:update()
    end
end
event.register(tes3.event.referenceSceneNodeCreated, referenceSceneNodeCreatedCallback)

--- @param e weaponReadiedEventData
local function weaponReadiedCallback(e)
    if (e.weaponStack == nil or
        (
            (interop.weaponList[e.weaponStack.object.id] == nil or tes3.player.data.sb_smith.weapons[e.weaponStack.object.id] == nil)
            and e.weaponStack.object.id:match("_handle") == nil and e.weaponStack.object.id:match("_blade") == nil and e.weaponStack.object.id:match("_sb") == nil)
        ) then return end
    local originalId = e.weaponStack.object.id:gsub("_handle", ""):gsub("_blade", "")
    local numCheck = originalId:gsub("_sb", "")
    if (tonumber(numCheck) and tes3.player.data.sb_smith.weapons[originalId]) then
        local handleId = tes3.player.data.sb_smith.weapons[originalId][1]
        local bladeId = tes3.player.data.sb_smith.weapons[originalId][2]
        local originalHandleParts = interop.weaponList[handleId:gsub("_handle", "")]
        local originalBladeParts = interop.weaponList[bladeId:gsub("_blade", "")]
        local mainWeapon = e.reference.bodyPartManager.attachNodes[tes3.bodyPartAttachment.weapon + 1].node:clone()
        local subWeapon = tes3.loadMesh(tes3.getObject(bladeId:gsub("_blade", "")).mesh)
        meshUpdate(e.reference.bodyPartManager.attachNodes[tes3.bodyPartAttachment.weapon + 1].node, mainWeapon, subWeapon, originalHandleParts, originalBladeParts)
        if (e.reference == tes3.player) then
            meshUpdate(tes3.player1stPerson.bodyPartManager.attachNodes[tes3.bodyPartAttachment.weapon + 1].node, mainWeapon, subWeapon, originalHandleParts, originalBladeParts) 
        end
        tes3ui.updateInventoryCharacterImage()
    end
end
event.register(tes3.event.weaponReadied, weaponReadiedCallback)

--- @param e bodyPartsUpdatedEventData
local function bodyPartsUpdatedCallback(e)
    local equippedWeapon = tes3.getEquippedItem{actor = tes3.player, objectType = tes3.objectType.weapon}
    if (equippedWeapon == nil or
        (
            (interop.weaponList[equippedWeapon.object.id] == nil or tes3.player.data.sb_smith.weapons[equippedWeapon.object.id] == nil)
            and equippedWeapon.object.id:match("_handle") == nil and equippedWeapon.object.id:match("_blade") == nil and equippedWeapon.object.id:match("_sb") == nil)
        ) then return end
    local originalId = equippedWeapon.object.id:gsub("_handle", ""):gsub("_blade", "")
    local numCheck = originalId:gsub("_sb", "")
    if (tonumber(numCheck) and tes3.player.data.sb_smith.weapons[originalId]) then
        local handleId = tes3.player.data.sb_smith.weapons[originalId][1]
        local bladeId = tes3.player.data.sb_smith.weapons[originalId][2]
        local originalHandleParts = interop.weaponList[handleId:gsub("_handle", "")]
        local originalBladeParts = interop.weaponList[bladeId:gsub("_blade", "")]
        local mainWeapon = e.reference.bodyPartManager.attachNodes[tes3.bodyPartAttachment.weapon + 1].node:clone()
        local subWeapon = tes3.loadMesh(tes3.getObject(bladeId:gsub("_blade", "")).mesh)
        meshUpdate(e.reference.bodyPartManager.attachNodes[tes3.bodyPartAttachment.weapon + 1].node, mainWeapon, subWeapon, originalHandleParts, originalBladeParts)
        if (e.reference == tes3.player) then
            meshUpdate(tes3.player1stPerson.bodyPartManager.attachNodes[tes3.bodyPartAttachment.weapon + 1].node, mainWeapon, subWeapon, originalHandleParts, originalBladeParts) 
        end
        tes3ui.updateInventoryCharacterImage()
    end
end
event.register(tes3.event.bodyPartsUpdated, bodyPartsUpdatedCallback)

--- @param e loadedEventData
local function loadedCallback(e)
    if (tes3.player.data.sb_smith == nil) then
        tes3.player.data.sb_smith = {}
        tes3.player.data.sb_smith.weapons = {}
    end
end
event.register(tes3.event.loaded, loadedCallback)

local function onInitialized()
    weaponSmith = crafting:new(
    ---@type CraftingFramework.MenuActivator.data
        {
            id = "sb_smith",
            name = "Weapon Assembly Anvil",
            type = "event",
            recipes = recipeList,
            craftButtonText = "Confirm",
            recipeHeaderText = "Blueprints",
            materialsHeaderText = "Parts",
            menuHeight = math.min(800, tes3.worldController.viewHeight * 0.66),
            menuWidth = math.min(720 * 1.5, tes3.worldController.viewWidth * 0.66),
            previewHeight = 0,
            previewWidth = 0
        }
    )
end
event.register("initialized", onInitialized)