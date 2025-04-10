local common = require("mer.theGuarWhisperer.common")
local logger = common.createLogger("Mouth")
local harvest = require("mer.theGuarWhisperer.abilities.harvest")

---@class GuarWhisperer.Mouth.GuarCompanion.refData
---@field carriedItems table<string, {name:string, id:string, count:number, itemData:tes3itemData}>

---@class GuarWhisperer.Mouth.GuarCompanion : GuarWhisperer.GuarCompanion
---@field refData GuarWhisperer.Mouth.GuarCompanion.refData

---@class GuarWhisperer.Mouth
---@field guar GuarWhisperer.Mouth.GuarCompanion
local Mouth = {}

---@param guar GuarWhisperer.Mouth.GuarCompanion
---@return GuarWhisperer.Mouth
function Mouth.new(guar)
    local self = setmetatable({}, { __index = Mouth })
    self.guar = guar
    return self
end


---@param object tes3object|tes3misc
---@param node? niNode
function Mouth:putItemInMouth(object, node)
    logger:debug("Putting %s in %s's mouth", object.name, self.guar:getName())
    --Get item node and clear transforms
    local itemNode = (node or tes3.loadMesh(object.mesh)):clone()
    itemNode:clearTransforms()
    itemNode.scale = itemNode.scale * ( 1 / self.guar.reference.scale)
    itemNode.name = "Picked_Up_Item"
    itemNode:update()

    local bb
    if itemNode:getObjectByName("Bounding Box") then
        bb = object.boundingBox
    else
        bb = common.util.generateBoundingBox(itemNode)
    end

    local attachNode = self.guar.reference.sceneNode:getObjectByName("ATTACH_MOUTH")
    attachNode:attachChild(itemNode, true)
    do --determine rotation
        --rotation
        local x = bb.max.x - bb.min.x
        local y = bb.max.y - bb.min.y
        local z = bb.max.z - bb.min.z
        logger:debug("X: %s, Y: %s, Z: %s", x, y, z)
        local rotation
        ---@type string
        local longestAxis = (
            x > y and x > z and "x" or
            y > x and y > z and "y" or
            z > x and z > y and "z"
        )

        --[[
            The Y axis goes from the left side to the right side of the mouth
            The X axis goes from front to the back of the mouth

            We want to rotate the item so that the longest side is along the Y axis
        ]]
        if longestAxis == "x" then
            logger:debug("X is longest, rotate z = 90")
            rotation = { z = math.rad(90) }
        elseif longestAxis == "y" then
            logger:debug("Y is longest, no rotation")
        elseif longestAxis == "z" then
            logger:debug("Z is longest, rotate x = 90")
            rotation = { x = math.rad(90) }
        end
        if rotation then
            logger:debug("Rotating mouth item")
            local zRot90 = tes3matrix33.new()
            zRot90:fromEulerXYZ(rotation.x or 0, rotation.y or 0, rotation.z or 0)
            itemNode.rotation = itemNode.rotation * zRot90
        end

        --Position at center of bounding box along longest axis
        local yCenter = (bb.max[longestAxis] - bb.min[longestAxis]) / 2
        local yOffset = bb.min[longestAxis] + yCenter

        --Raise Z by min bb of new up
        --The original axis that is now pointing UP
        local newUpAxis = (
            longestAxis == "x" and "z" or
            longestAxis == "y" and "z" or
            longestAxis == "z" and "y"
        )
        local zOffset = bb.min[newUpAxis]
        ---For very thin items (paper etc), raise them up a bit
        local zHeight = bb.max[newUpAxis] - bb.min[newUpAxis]
        if zHeight < 1 then
            logger:debug("zHeight < 1, raising zOffset")
            zOffset = zOffset -2
        end

        local offset = tes3vector3.new(
            0,
            yOffset,
            zOffset
        )
        logger:debug("Current Y: %s, yOffset: %s", itemNode.translation.y, yOffset)
        itemNode.translation = itemNode.translation - offset
    end
    itemNode.appCulled = false
end


function Mouth:pickUpItem(reference)
    local itemData = reference.itemData
    local itemCount = reference.itemData and reference.itemData.count or 1

    if itemCount > 1 then
        tes3.addItem{
            reference = self.guar.reference,
            item = reference.object,
            updateGUI = true,
            count = itemCount,
            playSound = false
        }
    else
        local isBoots = (
            reference.object.objectType == tes3.objectType.armor and
            reference.object.slot == tes3.armorSlot.boots
        )
        tes3.addItem{
            reference = self.guar.reference,
            item = reference.object,
            updateGUI = true,
            itemData = itemData,
            count =  1,
            playSound = false
        }
        if isBoots then
            if not itemData then
                itemData = tes3.addItemData{
                    to = self.guar.reference,
                    item = reference.object,
                    updateGUI = false
                }
            end
            logger:debug("Ruining boots")
            itemData.condition = 0
        end
    end
    reference.itemData = nil
    reference:delete()
    tes3.playSound({reference=self.guar.reference , sound="Item Misc Up"})
    self:addToCarriedItems(reference.object.name, reference.object.id, itemCount)
    self:putItemInMouth(reference.object, reference.sceneNode)

    if not tes3.hasOwnershipAccess{target=reference} then
        tes3.triggerCrime{type=tes3.crimeType.theft, victim=tes3.getOwner(reference), value=reference.object.value * itemCount}
    end
end

---@private
function Mouth:eatFromContainer(target)
    local success = self:harvestItem(target, false)
    if not success then
        tes3.messageBox(self.guar:format("{Name} не смог получить питание от %s", target.object.name))
        return
    end
    for _, item in pairs(self:getCarriedItems()) do
        tes3.removeItem{
            reference = self.guar.reference,
            item = item.id,
            count = item.count,
            playSound = false
        }
        local foodAmount = self.guar.animalType.foodList[string.lower(item.id)]
        self.guar.hunger:processFood(foodAmount)
    end
    tes3.playSound{ reference = self.guar.reference, sound = "Swallow" }
    tes3.messageBox(self.guar:format("{Name} ats the %s", target.object.name))
    timer.start{
        type = timer.simulate,
        duration = 1,
        callback = function()
            if not self.guar:isValid() then return end
            self:swallow(target.object)
        end
    }
end

---@private
function Mouth:eatFromIngredient(target)
    self:pickUpItem(target)
    local foodAmount = self.guar.animalType.foodList[string.lower(target.object.id)]
    self.guar.hunger:processFood(foodAmount)
    tes3.removeItem{
        reference = self.guar.reference,
        item = target.object,
        playSound = false
    }
    tes3.playSound{ reference = self.guar.reference, sound = "Swallow" }
    tes3.messageBox(self.guar:format("{Name} ест %s", target.object.name))
    timer.start{
        type = timer.simulate,
        duration = 1,
        callback = function()
            if not self.guar:isValid() then return end
            self:swallow(target.object)
        end
    }
end

function Mouth:swallow(item)
    event.trigger("GuarWhisperer:AteFood", { reference = self.guar.reference, itemId = item.id } )
    self:removeItemsFromMouth()
    self.guar.refData.carriedItems = nil
end

---Eat an item from a target.
--- The target can be an individual ingredient or a plant container
function Mouth:eatFromWorld(target)
    if target.object.objectType == tes3.objectType.container then
        self:eatFromContainer(target)
    elseif target.object.objectType == tes3.objectType.ingredient then
        self:eatFromIngredient(target)
    else
        logger:warn("Unknown object type %s", target.object.objectType)
    end
end


function Mouth:eatFromInventory(item, itemData)
    event.trigger("GuarWhisperer:EatFromInventory", { item = item, itemData = itemData })
    --remove food from player
    tes3.player.object.inventory:removeItem{
        mobile = tes3.mobilePlayer,
        item = item,
        itemData = itemData or nil
    }
    tes3ui.forcePlayerInventoryUpdate()

    self.guar.hunger:processFood(self.guar.animalType.foodList[string.lower(item.id)])

    --visuals/sound
    self.guar.ai:playAnimation("eat")
    self.guar:takeAction(2)
    local itemId = item.id
    timer.start{
        duration = 1,
        callback = function()
            if not self.guar:isValid() then return end
            event.trigger("GuarWhisperer:AteFood", { reference = self.guar.reference, itemId = itemId }  )
            tes3.playSound{ reference = self.guar.reference, sound = "Swallow" }
            tes3.messageBox(self.guar:format("{Name} пожирает %s.", string.lower(item.name))
            )
        end
    }
end

---Harvest a container and put the items in the guar's mouth
---@param target tes3reference - the container to harvest
---@param playSound boolean? - play the harvest sound
---@return boolean success - true if items were harvested
function Mouth:harvestItem(target, playSound)
    local items = harvest.harvest(self.guar.reference, target, playSound)
    if not items then
        return false
    end
    for _, item in ipairs(items) do
        local object = tes3.getObject(item.id)
        self:addToCarriedItems(item.name, item.id, item.count)
        self:putItemInMouth(object)
        if not tes3.hasOwnershipAccess{target=target} then
            tes3.triggerCrime{type=tes3.crimeType.theft, victim=tes3.getOwner(item), value = object.value * item.count }
        end
    end
    return true
end


---Check if the guar has any items in its mouth
---@return boolean
function Mouth:hasCarriedItems()
    return table.size(self:getCarriedItems()) > 0
end

---Return the list of carried items
---@return table<string, {name:string, id:string, count:number, itemData:tes3itemData}>
function Mouth:getCarriedItems()
    return self.guar.refData.carriedItems or {}
end


function Mouth:handOverItems()
    local carriedItems = self:getCarriedItems()
    for _, item in pairs(carriedItems) do
        local count = item.count
        tes3.transferItem{
            from = self.guar.reference,
            to = tes3.player,
            item = item.id,
            itemData = item.itemData,
            count = count,
            playSound=false,
        }
        --For ball, equip if unarmed
        if common.balls[item.id:lower()] then
            if tes3.player.mobile.readiedWeapon == nil then
                timer.delayOneFrame(function()
                    if not self.guar:isValid() then return end
                    logger:debug("Re-equipping ball")
                    tes3.player.mobile:equip{ item = item.id }
                    tes3.player.mobile.weaponReady = true
                end)
            end
        end
    end

    tes3.playSound{
        reference = self.guar.reference,
        sound = "Item Ingredient Up",
        pitch = 1.0
    }

    if #carriedItems == 1 then
        tes3.messageBox(self.guar:format("{Name} принес вам %s x%d.", carriedItems[1].name, carriedItems[1].count))
    else
        local message = self.guar:format("{Name} принес вам следующее:\n")
        for _, item in pairs(carriedItems) do
            message = message .. string.format("%s x%d,\n", item.name, item.count)
        end
        message = string.sub(message, 1, -3)
        tes3.messageBox(message)
    end

    self:removeItemsFromMouth()
    self.guar.refData.carriedItems = nil

    --make happier
    self.guar.needs:modPlay(self.guar.animalType.play.fetchValue)
    timer.delayOneFrame(function()
        if not self.guar:isValid() then return end
        self.guar.ai:playAnimation("happy")
    end)
end

---@private
function Mouth:addToCarriedItems(name, id, count)
    self.guar.refData.carriedItems = self:getCarriedItems()
    if not self.guar.refData.carriedItems[id] then
        self.guar.refData.carriedItems[id] = {
            name = name,
            id = id,
            count = count,
        }
    else
        self.guar.refData.carriedItems[id].count = self.guar.refData.carriedItems[id].count + count
    end
end

---@private
function Mouth:removeItemsFromMouth()
    local node = self.guar.reference.sceneNode:getObjectByName("ATTACH_MOUTH")
    for _, item in pairs(self:getCarriedItems()) do
        local pickedItem = node:getObjectByName("Picked_Up_Item")
        while pickedItem do
            node:detachChild(node:getObjectByName("Picked_Up_Item"))
            pickedItem = node:getObjectByName("Picked_Up_Item")
        end
        --For ball, equip if unarmed
        if common.balls[item.id:lower()] then
            if tes3.player.mobile.readiedWeapon == nil then
                timer.delayOneFrame(function()
                    if not self.guar:isValid() then return end
                    logger:debug("Re-equipping ball")
                    tes3.player.mobile:equip{ item = item }
                    tes3.player.mobile.weaponReady = true
                end)
            end
        end
    end
end

function Mouth:feed()
    timer.delayOneFrame(function()
        if not self.guar:isValid() then return end
        tes3ui.showInventorySelectMenu{
            reference = tes3.player,
            title = self.guar:format("Корм {name}"),
            noResultsText = "У вас нет подходящей пищи.",
            filter = function(e)
                logger:trace("Filter: checking: %s", e.item.id)
                for id, value in pairs(self.guar.animalType.foodList) do
                    logger:trace("%s: %s", id, value)
                end
                return (
                    e.item.objectType == tes3.objectType.ingredient and
                    self.guar.animalType.foodList[string.lower(e.item.id)] ~= nil
                )
            end,
            callback = function(e)
                if e.item then
                    self.guar.mouth:eatFromInventory(e.item, e.itemData)
                end
            end
        }
    end)
end

return Mouth
