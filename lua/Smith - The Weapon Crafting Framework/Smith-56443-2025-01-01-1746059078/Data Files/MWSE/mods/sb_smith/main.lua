local mcm = require("sb_smith.mcm")
local interop = require("sb_smith.interop")
require("sb_smith.weapons")
require("sb_smith.weapons_tr")
require("sb_smith.weapons_bm")
local crafting = require("CraftingFramework.components.MenuActivator")
local recipe = require("CraftingFramework.components.Recipe")
local recipeList = require("sb_smith.recipes")

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

---@param ref tes3reference
local function splitFuse(ref, handleId, bladeId, mainWeapon, subWeapon, originalHandleParts, originalBladeParts)
    mwse.log("parts check: " .. tostring(ref.bodyPartManager.attachNodes[tes3.bodyPartAttachment.weapon + 1].node.name))
    for node in table.traverse(ref.bodyPartManager.attachNodes[tes3.bodyPartAttachment.weapon + 1].node.children) do
        mwse.log("\t\t" .. node.name)
    end
    mwse.log("parts check: " .. tostring(ref.bodyPartManager.attachNodes[tes3.bodyPartAttachment.weapon + 1].node:getObjectByName(originalHandleParts.handles[1])))
    mwse.log("parts check: " .. tostring(subWeapon:getObjectByName(originalBladeParts.handles[1])))
    if (ref.bodyPartManager.attachNodes[tes3.bodyPartAttachment.weapon + 1].node:getObjectByName(originalHandleParts.handles[1]) == nil or subWeapon:getObjectByName(originalBladeParts.handles[1]) == nil) then return end
    mwse.log("tes3.player.data.sb_smith.weapons[originalId] - " .. json.encode(tes3.player.data.sb_smith.weapons[originalId]))
    mwse.log("interop.weaponList[handleId:gsub(\"_handle\", \"\")]: " .. json.encode(interop.weaponList[handleId:gsub("_handle", "")]))
    mwse.log("Scene node: " .. ref.bodyPartManager.attachNodes[tes3.bodyPartAttachment.weapon + 1].node.name)
    mwse.log("Sub: " .. subWeapon.name)
    ---@param value niNode
    for value in table.traverse(ref.bodyPartManager.attachNodes[tes3.bodyPartAttachment.weapon + 1].node.children) do
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
    local handleRootBoundingBox = ref.bodyPartManager.attachNodes[tes3.bodyPartAttachment.weapon + 1].node:getObjectByName(originalHandleParts.handles[originalHandleParts.rootIndexes[1]]):createBoundingBox()
    local bladeRootBoundingBox = subWeapon:getObjectByName(originalBladeParts.blades[originalBladeParts.rootIndexes[2]]):createBoundingBox()
    local diff = bladeRootBoundingBox.min.y - handleRootBoundingBox.max.y
    for _, node in pairs(originalBladeParts.blades) do
        local newNode = subWeapon:getObjectByName(node):clone()
        newNode.data = newNode.data:copy()
        -- for v = 1, newNode.data.vertexCount, 1 do
        --     newNode.data.vertices[v] = tes3vector3.new(newNode.data.vertices[v].x, newNode.data.vertices[v].y - diff, newNode.data.vertices[v].z)
        -- end
        for _, vert in ipairs(newNode.vertices) do
            vert.y = vert.y - diff
        end
        mwse.log(mainWeapon:getObjectByName(originalHandleParts.blades[originalHandleParts.rootIndexes[2]]))
        newNode.translation.y = mainWeapon:getObjectByName(originalHandleParts.blades[originalHandleParts.rootIndexes[2]]).translation.y
        ref.bodyPartManager.attachNodes[tes3.bodyPartAttachment.weapon + 1].node:attachChild(newNode)
    end
    ref.bodyPartManager.attachNodes[tes3.bodyPartAttachment.weapon + 1].node:update()
end

local function onInitialized()
    -- for _, tattoo in pairs(weaponList) do
    --     interop:register(tattoo)
    -- end
    -- interop:registerAll()
    weaponSmith = crafting:new(
    ---@type CraftingFramework.MenuActivator.data
        {
            id = "sb_smith",
            name = "Anvil",
            type = "event",
            recipes = recipeList,
            craftButtonText = "Confirm",
            recipeHeaderText = "Blueprints",
            -- customRequirementsHeaderText = "b",
            materialsHeaderText = "Parts",
            menuHeight = math.min(800, tes3.worldController.viewHeight * 0.66),
            menuWidth = math.min(720 * 1.5, tes3.worldController.viewWidth * 0.66),
            previewHeight = 0,
            previewWidth = 0
        }
    )
end
event.register("initialized", onInitialized)

---@param weaponId string
local function splitWeapon(weaponId)
    tes3.player.data.sb_smith = {}
    tes3.player.data.sb_smith.weapons = {}
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
            for name, data in pairs(materialData) do
                if (tes3.getObject(data) == nil) then
                    tes3.createObject{
                        id = data,
                        objectType = tes3.objectType.miscItem,
                        name = name .. " (" .. weaponObj.name .. ")",
                        icon = "sb_smith/" .. (name == "Handle" and "h_" or "b_") .. partData[weaponObj.type] .. ".dds",
                        mesh = "sb_smith/" .. (name == "Handle" and "h_" or "b_") .. partData[weaponObj.type] .. ".nif",
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
            mwse.log(json.encode(tes3.player.data.sb_smith.weapons))
            -- tes3.removeItem{ reference = tes3.player, item = weaponObj.id }
        end,
        materials = {
            {
                material = weaponId,
                count = 1
            }
        },
        category = "Disassemble",
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
        category = "Disassemble",
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
    mwse.log("Weap: " .. weaponId)
    local weapon = tes3.getObject(weaponId)
    mwse.log("Exists? " .. (weapon == nil and "false" or "true"))
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
        category = "Assemble",
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
    mwse.log("H and B: " .. handle.name .. " and " .. blade.name)
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
                if (e.materialsUsed[originalParts[1]] and e.materialsUsed[originalParts[2]]) then
                    tes3.addItem{ reference = tes3.player, item = weaponId, count = 1 }
                    return
                end
                local tempId = weaponId:gsub("_sb", "")
                if (tonumber(tempId)) then
                    newWeaponId = (tonumber(tempId) + 1) .. "_sb"
                end
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
        category = "Assemble",
        knowledgeRequirement = function (self)
            return tes3.player.object.inventory:getItemCount(handlePartId) > 0 and tes3.player.object.inventory:getItemCount(bladePartId) > 0
        end,
        keepMenuOpen = false
    }
    mwse.log("Completed?")
    weaponSmith:addRecipe(partRecipe)
end

--- @param e activateEventData
local function activateCallback(e)
    mwse.log("Try to activate smith...")
    if (e.activator == tes3.player and e.target.baseObject.id == "sb_smith") then
        for weaponId, weaponData in pairs(interop.weaponList) do
            mwse.log("Does player have " .. weaponId .. " from interop.weaponList?")
            if (tes3.player.object.inventory:findItemStack(weaponId) and weaponSmith:hasRecipe("sb_" .. weaponId .. "_break") == false) then
                mwse.log("\tPlayer has " .. weaponId .. ", preparing split...")
                splitWeapon(weaponId)
            end
        end
        for newWeaponId, originalParts in pairs(tes3.player.data.sb_smith.weapons) do
            local numCheck = newWeaponId:gsub("_sb", "")
            mwse.log("Does player have " .. newWeaponId .. " from tes3.player.data.sb_smith.weapons?")
            if (tes3.player.object.inventory:findItemStack(newWeaponId) and weaponSmith:hasRecipe("sb_" .. newWeaponId .. "_break") == false) then
                mwse.log("\tPlayer has " .. newWeaponId .. ", preparing split...")
                splitNewWeapon(newWeaponId, originalParts)
            end
            for newWeaponId2, originalParts2 in pairs(tes3.player.data.sb_smith.weapons) do
                local numCheck2 = newWeaponId2:gsub("_sb", "")
                if (tonumber(numCheck) == nil and tonumber(numCheck2) == nil and tes3.player.object.inventory:findItemStack(originalParts[1]) and tes3.player.object.inventory:findItemStack(originalParts2[2])) then
                    if (newWeaponId == newWeaponId2 and interop.weaponList[newWeaponId] and weaponSmith:hasRecipe("sb_" .. newWeaponId .. "_fuse") == false) then
                            mwse.log("\tPlayer has both parts of " .. newWeaponId .. ", preparing fuse...")
                            fuseWeapon(newWeaponId, originalParts[1], originalParts2[2])
                    elseif (newWeaponId ~= newWeaponId2 and weaponSmith:hasRecipe("sb_" .. originalParts[1] .. "_" .. originalParts2[2] .. "_fuse") == false) then
                        mwse.log("\tPlayer has " .. originalParts[1] .. " and " .. originalParts2[2] .. ", preparing fuse...")
                        fuseNewWeapon(newWeaponId, newWeaponId2, originalParts[1], originalParts2[2])
                    end
                end
            end
        end
        mwse.log("Try to open smithing menu")
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
        local mainWeapon = e.reference.sceneNode:clone()
        local subWeapon = tes3.loadMesh(tes3.getObject(bladeId).mesh)
        local originalHandleParts = interop.weaponList[handleId:gsub("_handle", "")]
        local originalBladeParts = interop.weaponList[bladeId:gsub("_blade", "")]
        if (e.reference.baseObject.sceneNode:getObjectByName(originalHandleParts.handles[1]) == nil or subWeapon:getObjectByName(originalBladeParts.handles[1]) == nil) then return end
        mwse.log("tes3.player.data.sb_smith.weapons[originalId] - " .. json.encode(tes3.player.data.sb_smith.weapons[originalId]))
        mwse.log("interop.weaponList[handleId:gsub(\"_handle\", \"\")]: " .. json.encode(interop.weaponList[handleId:gsub("_handle", "")]))
        mwse.log("Scene node: " .. e.reference.baseObject.sceneNode.name)
        mwse.log("Sub: " .. subWeapon.name)
        ---@param value niNode
        for value in table.traverse(e.reference.sceneNode.children) do
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
        local handleRootBoundingBox = e.reference.sceneNode:getObjectByName(originalHandleParts.handles[originalHandleParts.rootIndexes[1]]):createBoundingBox()
        local bladeRootBoundingBox = subWeapon:getObjectByName(originalBladeParts.blades[originalBladeParts.rootIndexes[2]]):createBoundingBox()
        local diff = bladeRootBoundingBox.min.y - handleRootBoundingBox.max.y
        for _, node in pairs(originalBladeParts.blades) do
            local newNode = subWeapon:getObjectByName(node):clone()
            newNode.data = newNode.data:copy()
            -- for v = 1, newNode.data.vertexCount, 1 do
            --     newNode.data.vertices[v] = tes3vector3.new(newNode.data.vertices[v].x, newNode.data.vertices[v].y - diff, newNode.data.vertices[v].z)
            -- end
            for _, vert in ipairs(newNode.vertices) do
                vert.y = vert.y - diff
            end
            mwse.log(mainWeapon:getObjectByName(originalHandleParts.blades[originalHandleParts.rootIndexes[2]]))
            newNode.translation.y = mainWeapon:getObjectByName(originalHandleParts.blades[originalHandleParts.rootIndexes[2]]).translation.y
            e.reference.sceneNode:attachChild(newNode)
        end
        e.reference.sceneNode:update()
        -- e.reference.sceneNode = mainWeapon
    -- elseif (interop.weaponList[originalId]) then
    --     ---@param value niNode
    --     for value in table.traverse(e.reference.sceneNode.children) do
    --         if (value:isOfType(ni.type.NiTriShape)) then
    --             local delete = true
    --             for _, node in pairs(interop.weaponList[originalId][e.reference.baseObject.name:match("Handle %(") and "handles" or "blades"]) do
    --                 if (value.name == node) then
    --                     delete = false
    --                     break
    --                 end
    --             end
    --             if (delete) then
    --                 value.parent:detachChild(value)
    --             end
    --         end
    --     end
    -- end
    end
end
event.register(tes3.event.referenceSceneNodeCreated, referenceSceneNodeCreatedCallback)

--- @param e weaponReadiedEventData
local function weaponReadiedCallback(e)
    mwse.log("Ref: " .. e.reference.object.id .. " - " .. e.reference.object.name)
    mwse.log("\t" .. (json.encode(interop.weaponList[e.weaponStack.object.id]) or "nil"))
    mwse.log("\t" .. (json.encode(tes3.player.data.sb_smith.weapons[e.weaponStack.object.id]) or "nil"))
    mwse.log("\t" .. tostring(e.reference))
    mwse.log("\t" .. tostring(tes3.player))
    mwse.log("\t" .. tostring(e.reference == tes3.player and tes3.player.data.sb_smith.weapons[e.weaponStack.object.id] == nil))
    mwse.log("\t" .. tostring((e.weaponStack.object.id:match("_handle") == nil and e.weaponStack.object.id:match("_blade") == nil and e.weaponStack.object.id:match("_sb") == nil)) )
    if (
        (interop.weaponList[e.weaponStack.object.id] == nil or tes3.player.data.sb_smith.weapons[e.weaponStack.object.id] == nil)
        and e.weaponStack.object.id:match("_handle") == nil and e.weaponStack.object.id:match("_blade") == nil and e.weaponStack.object.id:match("_sb") == nil) then return end
    local originalId = e.weaponStack.object.id:gsub("_handle", ""):gsub("_blade", "")
    local numCheck = originalId:gsub("_sb", "")
    mwse.log("numCheck: " .. tostring(numCheck))
    mwse.log("tes3.player.data.sb_smith.weapons[originalId]: " .. json.encode(tes3.player.data.sb_smith.weapons[originalId]))
    if (tonumber(numCheck) and tes3.player.data.sb_smith.weapons[originalId]) then
        local handleId = tes3.player.data.sb_smith.weapons[originalId][1]
        local bladeId = tes3.player.data.sb_smith.weapons[originalId][2]
        local mainWeapon = e.reference.bodyPartManager.attachNodes[tes3.bodyPartAttachment.weapon + 1].node:clone()
        local subWeapon = tes3.loadMesh(tes3.getObject(bladeId).mesh)
        local originalHandleParts = interop.weaponList[handleId:gsub("_handle", "")]
        local originalBladeParts = interop.weaponList[bladeId:gsub("_blade", "")]
        splitFuse(e.reference, handleId, bladeId, mainWeapon, subWeapon, originalHandleParts, originalBladeParts)
        if (e.reference == tes3.player) then
            splitFuse(tes3.player1stPerson, handleId, bladeId, mainWeapon, subWeapon, originalHandleParts, originalBladeParts) 
        end
        tes3ui.updateInventoryCharacterImage()
    end
end
event.register(tes3.event.weaponReadied, weaponReadiedCallback)