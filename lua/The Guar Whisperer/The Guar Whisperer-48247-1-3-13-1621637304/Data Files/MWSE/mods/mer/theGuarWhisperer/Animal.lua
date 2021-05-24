local Animal = {}
local animalConfig = require("mer.theGuarWhisperer.animalConfig")
local harvest = require("mer.theGuarWhisperer.harvest")
local moodConfig = require("mer.theGuarWhisperer.moodConfig")
local common = require("mer.theGuarWhisperer.common")
local ui = require("mer.theGuarWhisperer.ui")
local ashfallInterop = include("mer.ashfall.interop")

Animal.pickableObjects = {
    [tes3.objectType.alchemy] = true, 
    [tes3.objectType.ammunition] = true,
    [tes3.objectType.apparatus] = true,
    [tes3.objectType.armor] = true,
    [tes3.objectType.book] = true,
    [tes3.objectType.clothing] = true,
    [tes3.objectType.ingredient] = true, 
    [tes3.objectType.light] = true,
    [tes3.objectType.lockpick] = true,
    [tes3.objectType.miscItem] = true, 
    [tes3.objectType.probe] = true,
    [tes3.objectType.repairItem] = true,   
    [tes3.objectType.weapon] = true,
}

Animal.pickableRotations = {
    [tes3.objectType.ammunition] = {x=math.rad(270) },
    [tes3.objectType.armor] = {x=math.rad(270) },
    [tes3.objectType.book] = {x=math.rad(270) },
    [tes3.objectType.clothing] = {x=math.rad(270) },
    [tes3.objectType.ingredient] = {x=math.rad(270) }, 
    [tes3.objectType.lockpick] = {x=math.rad(90) },
    [tes3.objectType.miscItem] = {x=math.rad(270) }, 
    [tes3.objectType.probe] = {x=math.rad(90) },
    [tes3.objectType.repairItem] = {x=math.rad(90) },
    [tes3.objectType.weapon] = {x=math.rad(90) },
}
---------------------
--Internal methods
---------------------
local function initialiseRefData(reference)

    if reference.data.tgw then return reference.data.tgw end

    math.randomseed(os.time())
    reference.data.tgw = {
        name = "Tamed Guar",
        gender = math.random() < 0.55 and "male" or "female",
        birthTime = common.getHoursPassed(),
        trust = moodConfig.defaultTrust,
        affection = moodConfig.defaultAffection,
        play = moodConfig.defaultPlay,
        happiness = 0,
        hunger = 50,
        level = 1.0,
        attackPolicy = "defend",
    }
    return reference.data.tgw
end 

---------------------
--Class methods
---------------------

function Animal:new(reference)
    if not reference then 
        common.log:debug("No reference")
        return false 
    end
    local refObj = reference.baseObject or reference.object
    if not refObj then
        common.log:debug("ref doesn't have an object")
        return false
    end
    local isAGuar = (
        (refObj.id == animalConfig.guarMapper.standard) or 
        (refObj.id == animalConfig.guarMapper.white) 
    )
    if not isAGuar then
        common.log:trace("Not a guar")
        return false 
    end
    local animalData = animalConfig.animals.guar
    if not animalData then
        common.log:debug("No animalConfig found")
        return false 
    end
    
    local newAnimal = {
        reference = reference,
        object = reference.object,
        mobile = reference.mobile,
        animalData = animalData,
        refData = initialiseRefData(reference)
    }

    setmetatable(newAnimal, self)
    self.__index = self

    event.trigger("GuarWhisperer:registerReference", { reference = reference })
    return newAnimal
end

function Animal:__index(key)
    return self[key]
end




-----------------------------------------------
------- 
-------           Instance methods
-----------------------------------------------






---------------------------
-- Formatted text functions
------------------------------

function Animal:getHeShe(lower)
    local map = {
        male = "He",
        female = "She"
    }
    local name =  map[self.refData.gender] or 'It'
    if lower then name = string.lower(name) end
    return name
end
function Animal:getHimHer(lower)
    local map = {
        male = "Him",
        female = "Her"
    }
    local name =  map[self.refData.gender] or 'It'
    if lower then name = string.lower(name) end
    return name
end
function Animal:getHisHer(lower)
    local map = {
        male = "His",
        female = "Her"
    }
    local name =  map[self.refData.gender] or 'It'
    if lower then name = string.lower(name) end
    return name
end

function Animal:getName()
    return self.refData.name
end

function Animal:getContextName(prefix)
    if self.refData.named then return self.refData.name end
    return prefix and prefix .. " " .. self.animalData.type or self.animalData.type
end


-------------------
-- Level functions

function Animal:updateAttackSpell()
    local lvl = self:getLevel()
    local spellId = string.format("%s_attk", self.reference.id)
    local spell = tes3.getObject(spellId) or tes3spell.create(spellId, "Attack Bonus")
    spell.castType = tes3.spellType.ability
    local effect = spell.effects[1]
    effect.id = tes3.effect.fortifyAttack
    effect.rangeType = tes3.effectRange.self
    effect.min = lvl
    effect.max = lvl
    mwscript.removeSpell{ reference = self.reference, spell = spell }
    timer.delayOneFrame(function()
        mwscript.addSpell{ reference = self.reference, spell = spell }
    end)
    
end

function Animal:getLevel()
    return math.floor(self.refData.level)
end

function Animal:levelUp()
    tes3.modStatistic{
        reference = self.reference.mobile,
        name = "strength",
        value = 5,
    }
    tes3.modStatistic{
        reference = self.reference.mobile,
        name = "health",
        value = 5,
    }
    self:updateAttackSpell()
    self:playAnimation("pet")
end

function Animal:progressLevel(progress)
    if self.refData.isBaby then return end
    local prevLevel = self:getLevel()
    local progressNeeded = ( 100 * math.log(prevLevel + 2))
    progress = progress * ( 1 / progressNeeded)
    self.refData.level = self.refData.level + progress
    local newLevel = self:getLevel()
    if newLevel > prevLevel then
        self:levelUp()
        tes3.messageBox{
            message = string.format("%s is now Level %s", self.refData.name, newLevel),
            buttons = { "Okay" }
        }
    end
end


---------------------
--Movement functions
-----------------------

function Animal:playAnimation(emotionType, wait)
    local groupId = animalConfig.idles[emotionType]
    if tes3.animationGroup[groupId] ~= nil then
        common.log:debug("playing %s, wait: %s", groupId, wait)
        tes3.playAnimation{
            reference = self.reference,
            group = tes3.animationGroup[groupId],
            loopCount = 0,
            startFlag = wait and tes3.animationStartFlag.normal or tes3.animationStartFlag.immediate
        }
    end
end



function Animal:setAI(aiState)
    aiState = aiState or "waiting"
    self.refData.aiState = aiState
    local states = {
        following = self.returnTo,
        waiting = self.wait,
        wandering = self.wander,
        moving = self.wait,
    }
    local command = states[aiState]
    command(self)
   
end


function Animal:getAI()
    return self.refData.aiState or "waiting"
end

function Animal:restorePreviousAI()
    if self.refData.previousAiState then
        common.log:debug("Restoring AI state to %s", self.refData.previousAiState)
        self.refData.aiState = self.refData.previousAiState
    end
    self.refData.previousAiState = nil
end




function Animal:closeTheDistanceTeleport()

    if self.reference.mobile.inCombat then
        return 
    elseif tes3.player.cell.isInterior then
        return
    elseif self:getAI() ~= "following" then
        return
    elseif self:isDead() then
        return
    end
    local followRef = self.refData.followingRef or "player"
    if followRef == "player" then 
        followRef = tes3.player 
    else
        followRef = tes3.getReference(followRef)
    end
    

        
    local doTeleportBehind = (
        followRef.mobile.isMovingForward or
        followRef.mobile.isMovingLeft or
        followRef.mobile.isMovingRight
    )
    local distance = doTeleportBehind and -400 or 400
    common.log:debug("Closing the distance teleport")
    self:teleportToPlayer(distance, followRef)
end


function Animal:teleportToPlayer(distance)
    distance = distance or 0
    local isForward = distance >= 0
    common.log:debug("teleportToPlayer(): Distance: %s", distance)
    local target = tes3.player
    
    --do a raytest to avoid teleporting into stuff
    local oldCulledValue = target.sceneNode.appCulled
    target.sceneNode.appCulled = true
    local rayResult = tes3.rayTest{
        position = target.position,
        direction = target.sceneNode.rotation:transpose().y * (isForward and 1 or -1),
        maxDistance = math.abs(distance),
        ignore = {target, self.reference}
    }
    target.sceneNode.appCulled = oldCulledValue

    local wasFollowing
    if self:getAI() == "following" then
        wasFollowing = true
        self:wait()
    end

    if rayResult and rayResult.intersection then
        common.log:debug(
            "Teleport blocked by %s, new distance: %s",  
            rayResult.object.name,
            rayResult.intersection:distance(target.position)
        )
        local intersectionDistance = tes3.player.position:distance(rayResult.intersection)
        distance = math.max(0, intersectionDistance - 50) * (isForward and 1 or -1)
    end

    local newPosition = tes3vector3.new(
        target.position.x + ( distance * math.sin(target.orientation.z)),
        target.position.y + ( distance * math.cos(target.orientation.z)),
        target.position.z
    )
    tes3.positionCell{
        reference = self.reference,
        position = newPosition,
        cell = target.cell
    }
    self.reference.sceneNode:update()
    self.reference.sceneNode:updateNodeEffects()
    if wasFollowing then
        self:follow(target)
    end
end


function Animal:wait(idles)
    if not self.reference.mobile then return end
    self.refData.aiState = "waiting"
    common.log:debug("Waiting")
    timer.delayOneFrame(function()
        tes3.setAIWander{ 
            reference = self.reference.id, 
            range = 0, 
            idles = idles or { 
                0, --sit
                0, --eat
                0, --look
                0, --wiggle
                0, --n/a
                0, --n/a
                0, --n/a
                0  
            },
            duration = 2
        }
    end)
end

function Animal:wander(range)
    if not self.reference.mobile then return end
    common.log:debug("Wandering")
    self.refData.aiState = "wandering"
    timer.delayOneFrame(function()
        range = range or 500
        tes3.setAIWander{ 
            reference = self.reference, 
            range = range, 
            idles = { 
                40, --sit
                10, --eat
                50, --look
                0, --wiggle
                0, --n/a
                0, --n/a
                0, --n/a
                0  
            }  
        }
        
    end)
end


function Animal:follow(followRef)
    common.log:debug("Following")
    self.refData.aiState = "following"
    timer.delayOneFrame(function()
        
        self.refData.followingRef = followRef and followRef.id or "player"
        followRef = followRef or tes3.player
        tes3.setAIFollow{ reference = self.reference, target = followRef }
    end)
end


function Animal:attack(target, blockMessage)
    --self:wander()
        tes3.messageBox("%s attacking %s", self.refData.name, target.object.name)
    self.refData.previousAiState = self:getAI()
    self:follow()
    local ref = self.reference
    timer.start{
        duration = 0.5,
        callback = function()
            mwscript.startCombat({ reference = ref, target = target })
            self.refData.aiState = "attacking"
        end
    }
end

function Animal:setAttackPolicy(policy)
    self.refData.attackPolicy = policy
end

function Animal:getAttackPolicy()
    return self.refData.attackPolicy
end

function Animal:setPotionPolicy(policy)
    self.refData.potionPolicy = policy
end

function Animal:getPotionPolicy()
    return self.refData.potionPolicy
end

function Animal:moveTo(position)
    timer.delayOneFrame(function()
        
        tes3.setAITravel{ reference = self.reference, destination = position }
        self.reference.mobile.isRunning = true
        self.refData.aiState = "moving"
    end)
end

function Animal:returnTo(followRef) 
    followRef = followRef or tes3.player
    self:follow(followRef)
    timer.delayOneFrame(function()
        timer.delayOneFrame(function()
            if self.reference.position:distance(followRef.position) > 500 then
                local lastKnownPosition = self.reference.position:copy()
                local lastKnownCell = self.reference.cell

                local lanternOn = self.refData.lanternOn
                if lanternOn then
                    self:turnLanternOff()
                end
                self.reference.sceneNode.appCulled = true
                tes3.positionCell{ 
                    cell = followRef.cell,
                    orientation = self.reference.orientation, 
                    position = followRef.position,
                    reference = self.reference, 
                }
                timer.delayOneFrame(function()

                    tes3.positionCell{ 
                        cell = lastKnownCell,
                        orientation = self.reference.orientation, 
                        position = lastKnownPosition,
                        reference = self.reference, 
                    }
                    self.reference.sceneNode.appCulled = false
                    if lanternOn then
                        self:turnLanternOn()
                    end
                end)
            end
        end)
    end)
end

local cellWidth = 8192
local hoursPerCell = 0.5
function Animal:getTravelTime()
    local homePos = tes3vector3.new( 
        self.refData.home.position[1],
        self.refData.home.position[2],
        self.refData.home.position[3]
    )
    local distance = self.reference.position:distance(homePos)
    common.log:debug("travel distance: %s", distance)
    local travelTime =  hoursPerCell * (distance/cellWidth)
    common.log:debug("travel time: %s", travelTime)
    return travelTime
end

function Animal:getTravelTimeText(hours)
    hours = hours or self:getTravelTime()
    return string.format("%dh%2.0fm", hours, 60*( hours - math.floor(hours)))
end

function Animal:goHome(e)
    e = e or {}
    local hoursPassed = ( e.takeMe and self:getTravelTime() or 0 )
    local secondsTaken = ( e.takeMe and math.min(hoursPassed, 3) or 1)
    if not self.refData.home then
        tes3.messageBox("No home set")
        return
    else
        if e.takeMe then
            if ashfallInterop then ashfallInterop.blockSleepLoss() end
        else
            self:wait()
            timer.delayOneFrame(function() 
                self:wander()
            end)
        end
        

        common.fadeTimeOut(hoursPassed, secondsTaken, function()
            tes3.positionCell{
                reference = self.reference,
                position = self.refData.home.position,
                --cell = self.refData.home.cell
            }
            if e.takeMe then
                tes3.positionCell{
                    reference = tes3.player, 
                    position = self.refData.home.position,
                }
                if ashfallInterop then ashfallInterop.unblockSleepLoss() end
            else
                tes3.messageBox("%s has gone home to %s", self.refData.name, tes3.getCell{ id = self.refData.home.cell })
            end
        end)
    end
end


function Animal:hasHome()
    return self.refData.home ~= nil
end

--[[
    position must be tes3vector3, cell must be tes3cell
    converts position to table and cell to id for serialisation
]]
function Animal:setHome(position, cell)
    local newPosition = { position.x, position.y, position.z}
    self.refData.home = { position = newPosition, cell = cell.id }
    tes3.messageBox("Set %s's new home in %s", self.refData.name, cell.id)
end



function Animal:isDead()
    return self.refData.dead or common.getIsDead(self.reference)
end

--------------------------------
-- Fetch Functions
--------------------------------

function Animal:canBeSummoned()
    return (
        self:isDead() ~= true and
        self:hasSkillReqs("follow")
    )
end


function Animal:canEquipPack()
    return (
        self.refData.hasPack ~= true and
        --self.refData.isBaby ~= true and
        tes3.player.object.inventory:contains(common.packId) and     
        self:hasSkillReqs("pack")
    )
end

function Animal:canEat(ref)
    if ref.isEmpty then 
        return false 
    end
    return self.animalData.foodList[string.lower(ref.object.id)]
end

function Animal:canHarvest(reference)
    return (
        self:isDead() ~= true and
        reference and
        not reference.isEmpty and
        harvest.isHerb(reference)
    )
end

function Animal:canFetch(reference)
    return (
        reference and
        reference.object.canCarry ~= false and --nil or true is fine
        self.pickableObjects[reference.object.objectType]
    )
end

function Animal:hasSkillReqs(skill)
    return self.refData.trust > moodConfig.skillRequirements[skill]
end

function Animal:addToCarriedItems(name, id, count)
    self.refData.carriedItems = self.refData.carriedItems or {}
    if not self.refData.carriedItems[id] then
        self.refData.carriedItems[id] = {
            name = name, 
            id = id, 
            count = count,
        } 
    else
        self.refData.carriedItems[id].count = self.refData.carriedItems[id].count + count
    end
end

function Animal:removeItemsFromMouth()
    local node = self.reference.sceneNode:getObjectByName("ATTACH_MOUTH")

    for _, item in pairs(self.refData.carriedItems) do
        --detach once per item held
        node:detachChild(node:getObjectByName("Picked_Up_Item"), true)
        --For ball, equip if unarmed
        if item.name == common.ballId then
            if tes3.player.mobile.readiedWeapon == nil then
                timer.delayOneFrame(function()
                    common.log:debug("Re-equipping ball")
                    tes3.player.mobile:equip{ item = item }
                    tes3.player.mobile.weaponReady = true
                end)
            end
        end
    end
end


function Animal:putItemInMouth(object)
    --attach nif
    -- local objNode = tes3.loadMesh(object.mesh):clone()
    -- local itemNode = niNode.new()
    -- itemNode:attachChild(objNode)
    local itemNode = tes3.loadMesh(object.mesh):clone()

    
    itemNode:clearTransforms()
    itemNode.name = "Picked_Up_Item"
    local node = self.reference.sceneNode:getObjectByName("ATTACH_MOUTH")
    

    --determine rotation
    --Due to orientation of ponytail bone, item is already rotated 90 degrees
    Animal.removeLight(itemNode)
    --remove collision
    for node in table.traverse{itemNode} do
        if node:isInstanceOfType(tes3.niType.RootCollisionNode) then
            node.appCulled = true
        end
    end
    itemNode:update()
    node:attachChild(itemNode, true)
    
    local bb = itemNode:createBoundingBox()
    
    -- --Center position to middle of bounding box
    -- do 
    --     local offsetX = (bb.max.x + bb.min.x) / 2
    --     local offsetY = (bb.max.y + bb.min.y) / 2
    --     local offsetZ = (bb.max.z + bb.min.z) / 2
    --    -- itemNode.translation.x = itemNode.translation.x - offsetX
    --    -- itemNode.translation.y = itemNode.translation.y - offsetY
    --     itemNode.translation.z = itemNode.translation.z + offsetZ

        
    -- end

    do
        --rotation
        local x = bb.max.x - bb.min.x
        local y = bb.max.y - bb.min.y
        local z = bb.max.z - bb.min.z
        local rotation
        if x > y and x > z then --x is longest
            common.log:debug("X is longest, rotate z = 90")
            rotation = { z = math.rad(90) }
        elseif y > x and y > z then --y is longest
            common.log:debug("Y is longest, no rotation")
            --no rotation
        elseif z > x and z > y then --z is longest
            common.log:debug("Z is longest, rotate x = 90")
            rotation = { x = math.rad(90) }
        end
        --local rotation = Animal.pickableRotations[object.objectType]
        if rotation then
            common.log:debug("Rotating mouth item")
            local zRot90 = tes3matrix33.new()
            zRot90:fromEulerXYZ(rotation.x or 0, rotation.y or 0, rotation.z or 0)
            itemNode.rotation = itemNode.rotation * zRot90
        end
    end
    itemNode.appCulled = false
end

function Animal:pickUpItem(reference)
    local itemData = reference.itemData
    local itemCount = reference.itemData and reference.itemData.count or 1

    if itemCount > 1 then
        tes3.addItem{
            reference = self.reference,
            item = reference.object,
            updateGUI = true,
            count = itemCount
        }
    else
        local isBoots = (
            reference.object.objectType == tes3.objectType.armor and 
            reference.object.slot == tes3.armorSlot.boots
        )


        tes3.addItem{
            reference = self.reference,
            item = reference.object,
            updateGUI = true,
            itemData = itemData,
            count =  1
        }
        if isBoots then
            common.log:debug("Ruining boots")
            if not itemData then
                itemData = tes3.addItemData{
                    to = self.reference,
                    item = reference.object,
                    updateGUI = false
                }
                itemData.condition = 0
            end
        end
    end
    reference.itemData = nil
    reference:disable()
    mwscript.setDelete{ reference = reference, delete = true }

    tes3.playSound({reference=self.reference , sound="Item Misc Up"})
    self:addToCarriedItems(reference.object.name, reference.object.id, itemCount)
    self:putItemInMouth(reference.object)

    if not tes3.hasOwnershipAccess{target=reference} then
        tes3.triggerCrime{type=tes3.crimeType.theft, victim=tes3.getOwner(reference), value=reference.object.value * itemCount}
    end

end


function Animal:processFood(amount)
    self:modHunger(amount)

    --Eating restores health as a % of base health
    local healthCurrent = self.mobile.health.current
    local healthMax = self.mobile.health.base
    local difference = healthMax - healthCurrent
    local healthFromFood = math.remap(
        amount,
        0, 100,
        0, healthMax
    )
    healthFromFood = math.min(difference, healthFromFood)
    tes3.modStatistic{
        reference = self.reference, 
        name = "health",
        current = healthFromFood
    }

    if self.refData.trust < moodConfig.skillRequirements.follow then
        self:modTrust(3)
    end
end

function Animal:eatFromWorld(target)
    if target.object.objectType == tes3.objectType.container then

        self:harvestItem(target)
        if not self.refData.carriedItems then 
            tes3.messageBox("%s wasn't unable to get any nutrition from the %s", self.refData.name, target.object.name)
            return
        end
        for _, item in pairs(self.refData.carriedItems) do
            tes3.removeItem{
                reference = self.reference,
                item = item.id,
                count = item.count,
                playSound = false
            }
            local foodAmount = self.animalData.foodList[string.lower(item.id)]
            self:processFood(foodAmount)
        end

        
        tes3.playSound{ reference = self.reference, sound = "Item Ingredient Up" }
        tes3.messageBox("%s eats the %s", self.refData.name, target.object.name)
    elseif target.object.objectType == tes3.objectType.ingredient then

        self:pickUpItem(target) 
        local foodAmount = self.animalData.foodList[string.lower(target.object.id)]
        self:processFood(foodAmount)
        tes3.removeItem{
            reference = self.reference,
            item = target.object,
            playSound = false
        }
        tes3.messageBox("%s eats the %s", self.refData.name, target.object.name)
    end

    local itemId = target.baseObject.id
    timer.start{
        type = timer.simulate,
        duration = 1,
        callback = function()
            event.trigger("GuarWhisperer:AteFood", { reference = self.reference, itemId = itemId } )
            self:removeItemsFromMouth()
            self.refData.carriedItems = nil
        end
    }
end


function Animal:eatFromInventory(item, itemData)
    event.trigger("GuarWhisperer:EatFromInventory", { item = item, itemData = itemData })
    --remove food from player
    tes3.player.object.inventory:removeItem{
        mobile = tes3.mobilePlayer,
        item = item,
        itemData = itemData or nil
    }
    tes3ui.forcePlayerInventoryUpdate()

    self:processFood(self.animalData.foodList[string.lower(item.id)])

    --visuals/sound
    self:playAnimation("eat")
    self:takeAction(2)
    local itemId = item.id
    timer.start{
        duration = 1,
        callback = function()
            event.trigger("GuarWhisperer:AteFood", { reference = self.reference, itemId = itemId }  )
            tes3.playSound{ reference = self.reference, sound = "Swallow" } 
            tes3.messageBox(
                "%s gobbles up the %s.",
                self.refData.name, string.lower(item.name)
            )
        end
    }
end

function Animal:harvestItem(target)
    local items = harvest.harvest(self.reference, target)
    if not items then return end
    for _, item in ipairs(items) do
        local object = tes3.getObject(item.id)
        self:addToCarriedItems(item.name, item.id, item.count)
        self:putItemInMouth(object)

        if not tes3.hasOwnershipAccess{target=target} then
            tes3.triggerCrime{type=tes3.crimeType.theft, victim=tes3.getOwner(item), value = object.value * item.count }
        end
    end
end



function Animal:handOverItems()
    local carriedItems = self.refData.carriedItems
    if not carriedItems then return end


    for _, item in pairs(carriedItems) do
        local count = item.count
        tes3.transferItem{
            from = self.reference,
            to = tes3.player, 
            item = item.id,
            itemData = item.itemData,
            count = count,
            playSound=false,
        }
        --For ball, equip if unarmed
        if string.lower(item.id) == common.ballId then
            if tes3.player.mobile.readiedWeapon == nil then
                timer.delayOneFrame(function()
                    common.log:debug("Re-equipping ball")
                    tes3.player.mobile:equip{ item = item.id }
                    tes3.player.mobile.weaponReady = true
                end)
            end
        end
    end

    tes3.playSound{reference=self.reference, sound="Item Ingredient Up", pitch=1.0}

    if #carriedItems == 1 then
        tes3.messageBox("%s brings you %s x%d.", self.refData.name, carriedItems[1].name, carriedItems[1].count)
    else
        local message = string.format("%s brings you the following:\n", self.refData.name)
        for _, item in pairs(carriedItems) do
            message = message .. string.format("%s x%d,\n", item.name, item.count)
        end
        message = string.sub(message, 1, -3)
        tes3.messageBox(message)
    end

    self:removeItemsFromMouth()
    self.refData.carriedItems = nil

    --make happier
    self:modPlay(self.animalData.play.fetchValue)
    timer.delayOneFrame(function()
        self:playAnimation("happy")
    end)
end 

function Animal:getCharmModifier()
    local personality = self.reference.mobile.attributes[tes3.attribute.personality + 1].current
    return math.log10(personality) * 20
end

function Animal:charm(ref)
    if tes3.persuade{ actor = ref, self:getCharmModifier() } then
        tes3.messageBox("%s successfully charmed %s.", self.refData.name, ref.object.name)
    else
        tes3.messageBox("%s failed to charm %s.", self.refData.name, ref.object.name)
    end
end

function Animal:moveToAction(reference, command, noMessage)
    self.refData.previousAiState = self:getAI()
    common.fetchItems[reference] = true
    self.reference.mobile.isRunning = true
    self:moveTo(reference.position)

    --Start simulate event to check if close enough to the reference
    local previousPosition
    local distanceTimer
    local function checkRefDistance()
        self.reference.mobile.isRunning = true
        local distances = {
            fetch = 100,
            harvest = 400,
            greet = 500,
            eat = 200
        }
        local distance = distances[command] or 100
        --for first frames during loading
        if not self:isActive() then return end

        local currentPosition = self.reference.position
        local currentDist = currentPosition:distance(reference.position)
        local stillFetching = (
            currentDist > distance and
            ( previousPosition == nil or 
            currentPosition:distance(previousPosition) > 5 )
        )
        previousPosition = self.reference.position:copy()
        if not stillFetching then
            
            --check reference hasn't been picked up
            if not common.fetchItems[reference] == true then
                self:returnTo()
            --Check if guar got all the way there
            elseif currentDist > 500 then
                if noMessage ~= true then
                    tes3.messageBox("Couldn't reach.")
                end
                self:restorePreviousAI()
            else
                
                timer.delayOneFrame(function()
                    self.reference.mobile.isRunning = false
                    if command == "eat" then
                        self:playAnimation("eat")
                    elseif command == "greet" then
                        self:modPlay(self.animalData.play.greetValue)
                        self:playAnimation("pet")
                        tes3.playAnimation{
                            reference = reference,
                            group = tes3.animationGroup.idle,
                            loopCount = 1,
                            startFlag = tes3.animationStartFlag.normal
                        }
                    elseif command == "charm" then
                        self:playAnimation("pet")
                    else
                        self:playAnimation("fetch")
                    end
                end)
                
                --Wait until fetch animation completes, then pick up reference and follow player again
                timer.start{ 
                    type = timer.simulate, 
                    duration = 1,
                    callback = function()
                        if common.fetchItems[reference] == true then
                            local duration
                            if command == "harvest" then
                                self:harvestItem(reference)
                                duration = 1
                            elseif command == "eat" then
                                self:eatFromWorld(reference)
                                self:playAnimation("happy", true)
                                timer.start{ 
                                    type = timer.simulate, 
                                    duration = 1, 
                                    callback = function()
                                        tes3.playSound{ reference = self.reference, sound = "Swallow" }
                                    end
                                }
                                duration = 2.5
                            elseif command == "greet" then
                                duration = 3
                            elseif command == "charm" then
                                duration = 2
                                self:charm(reference)
                            else
                                self:pickUpItem(reference)
                                duration = 1
                            end
                            timer.start{ 
                                type = timer.simulate, 
                                duration = duration, 
                                callback = function()
                                    if command == "fetch" or command == "harvest" then
                                        self:progressLevel(self.animalData.lvl.fetchProgress)
                                        self:returnTo()
                                    else
                                        common.log:debug("Previous AI: %s", self.refData.previousAiState)
                                        self:restorePreviousAI()
                                    end
                                end
                            }
                        end
                    end
                }
            end
            distanceTimer:cancel()
        end
    end
    distanceTimer = timer.start{ 
        type = timer.simulate, 
        iterations = -1,
        duration = 0.5,
        callback = checkRefDistance
    }
end




-----------------------------------------
--Mood mechanics
-----------------------------------------


function Animal:modTrust(amount)
    local previousTrust = self.refData.trust
    self.refData.trust = math.clamp(self.refData.trust + amount, 0, 100)
    self.reference.mobile.fight = 50 - (self.refData.trust / 2 )
    

    local afterTrust = self.refData.trust
    for _, trustData in ipairs(moodConfig.trust) do
        if previousTrust < trustData.minValue and afterTrust > trustData.minValue then
            local message = string.format("%s %s. ", 
                self.refData.name, trustData.description)
            if trustData.skillDescription then
                message = message .. string.format("%s %s",
                    self:getHeShe(), trustData.skillDescription)
            end
            timer.delayOneFrame(function()
                tes3.messageBox{ message = message, buttons = {"Okay"} }
            end)
        end
    end
    tes3ui.refreshTooltip()
    return self.refData.trust
end

function Animal:modPlay(amount)
    self.refData.play = math.clamp(self.refData.play + amount, 0, 100)
    tes3ui.refreshTooltip()
    return self.refData.play
end

function Animal:modAffection(amount)
    --As he gains affection, his fight level decreases
    if amount > 0 then
        self.mobile.fight = self.mobile.fight - math.min(amount, 100 - self.refData.affection)
    end
    self.refData.affection = math.clamp(self.refData.affection + amount, 0, 100)
    return self.refData.affection
end

function Animal:modHunger(amount)
    local previousMood = self:getMood("hunger")
    self.refData.hunger = math.clamp(self.refData.hunger + amount, 0, 100)
    local newMood = self:getMood("hunger")
    if newMood ~= previousMood then
        tes3.messageBox("%s is %s.", self.refData.name, newMood.description)
    end

    tes3ui.refreshTooltip()
end

function Animal:getMood(moodType)
    for _, mood in ipairs(moodConfig[moodType]) do
        if self.refData[moodType] <= mood.maxValue then
            return mood
        end
    end
end

function Animal:updatePlay(timeSinceUpdate)
    local changeAmount = self.animalData.play.changePerHour * timeSinceUpdate
    self:modPlay(changeAmount)
end

function Animal:updateAffection(timeSinceUpdate)
    local changeAmount = self.animalData.affection.changePerHour * timeSinceUpdate
    self:modAffection(changeAmount)
end

function Animal:updateHunger(timeSinceUpdate)
    local changeAmount = self.animalData.hunger.changePerHour * timeSinceUpdate
    self:modHunger(changeAmount)
end

function Animal:updateTrust(timeSinceUpdate)
    --No trust from sleeping/waiting because that's lame
    if tes3ui.menuMode() or tes3.player.mobile.restHoursRemaining > 0 then return end
    --Trust changes if nearby
    local happinessMulti = math.remap(self.refData.happiness, 0, 100, -1.0, 1.0)
    local trustChangeAmount = (
        self.animalData.trust.changePerHour * 
        happinessMulti * 
        timeSinceUpdate
    )
    self:modTrust(trustChangeAmount)
end


function Animal:updateHappiness()
    local healthRatio = self.reference.mobile.health.current / self.reference.mobile.health.base
    local hunger = math.remap(self.refData.hunger, 0, 100, 0, 15)
    local comfort = math.remap(healthRatio, 0, 1.0, 0, 25 )
    local affection = math.remap(self.refData.affection, 0, 100, 0, 25)
    local play = math.remap(self.refData.play, 0, 100, 0, 15)
    local trust = math.remap(self.refData.trust, 0, 100, 0, 15)
    self.reference.mobile.flee = 50 - (self.refData.happiness / 2)

    local newHappiness = hunger + comfort + affection + play + trust 
    self.refData.happiness = newHappiness
    tes3ui.refreshTooltip()
end


function Animal:updateMood()

    --get the time since last updated
    local now = common.getHoursPassed()
    if not self:isActive() then
        --not active, reset time

        self.refData.lastUpdated = now
        return
    end
    local lastUpdated = self.refData.lastUpdated or now
    local timeSinceUpdate = now - lastUpdated
    
    self:updatePlay(timeSinceUpdate)
    self:updateAffection(timeSinceUpdate)
    self:updateHappiness()
    self:updateHunger(timeSinceUpdate)
    self:updateTrust(timeSinceUpdate)
    self.refData.lastUpdated = now
end

function Animal:isActive()
    return ( 
        self.reference and
        self.reference.mobile and
        table.find(tes3.getActiveCells(), self.reference.cell) and
        not self:isDead() and
        self.reference.position:distance(tes3.player.position) < 5000
    )
end


function Animal:getIsStuck()
    local strikesNeeded = 5
    
    local maxDistance = 10
    -- if self.reference.mobile.isRunning then
    --     maxDistance = 10
    -- end

    self.refData.stuckStrikes = self.refData.stuckStrikes or 0
    --self.refData.stuckStrikes: we check x times before deciding he's stuck
    if self.refData.stuckStrikes < strikesNeeded then
        --Check if he's trying to move forward
        if self.reference.mobile.isMovingForward then
            --Get the distance from last position and check if it's too small
            if self.refData.lastPosition then
                local lastPosition = tes3vector3.new(
                    self.refData.lastPosition.x,
                    self.refData.lastPosition.y,
                    self.refData.lastPosition.z
                )
                local distance = self.reference.position:distance(lastPosition)
                if distance < maxDistance then
                    self.refData.stuckStrikes = self.refData.stuckStrikes + 1
                    
                else
                    self.refData.stuckStrikes = 0
                end
            end
        end
    end
    local position = self.reference.position
    self.refData.lastPosition = { x = position.x, y = position.y, z = position.z}

    if self.refData.stuckStrikes >= strikesNeeded then
        self.refData.stuckStrikes = 0
        return true
    else
        return false
    end
end


function Animal:updateCloseDistance()
    if self:getAI() == "following" and tes3.player.cell.isInterior ~= true then
        local distance = self.reference.position:distance(tes3.player.position)
        local teleportDist = common.getConfig().teleportDistance
        --teleport if too far away
        if distance > teleportDist then
            --dont' teleport if fetching (unless stuck)
            if not self.refData.carriedItems or #self.refData.carriedItems > 0 then
                self:closeTheDistanceTeleport()
            end
        end
        --teleport if stuck and kinda far away
        local isStuck = self:getIsStuck()
        if isStuck then
            if distance > teleportDist / 2 then
                common.log:debug("%s Stuck while following: teleport", self:getName())
                self:closeTheDistanceTeleport()
            end
        end
    end
end

--keep ai in sync
function Animal:updateAI()
    local aiState = self:getAI()
    
    local packageId = tostring(tes3.getCurrentAIPackageId{ reference = self.reference.mobile })
    common.log:trace(packageId)
    local brokenLimit = 2
    self.refData.aiBroken = self.refData.aiBroken or 0
    if  self.refData.aiBroken <= brokenLimit and self.reference.sceneNode and packageId == "-1" then
        common.log:debug("AI Fix: Detected broken AI package")
        self.refData.aiBroken = self.refData.aiBroken + 1
    end

    if self.refData.aiBroken and self.refData.aiBroken > brokenLimit then
        if tes3.getCurrentAIPackageId(self.reference.mobile) == tes3.aiPackage.follow then
            common.log:debug("AI Fix: AI has been fixed")
            self:moveToAction(tes3.player, "greet", true)
            tes3.messageBox("%s looks like %s really missed you.", self:getName(), self:getHeShe(true))
            self.refData.aiBroken = nil
        else
            common.log:debug("AI Fix: still broken, attempting to fix by starting combat")
            local mobile = self.reference.mobile
            mwse.memory.writeByte({
            address = mwse.memory.convertFrom.tes3mobileObject(mobile) + 0xC0,
            byte = 0x00,
            })
            self:follow()
        end
    end

    --set correct ai package
    if aiState == "following" then
        if tes3.getCurrentAIPackageId(self.reference.mobile) ~= tes3.aiPackage.follow then
            self:returnTo()
        end

    elseif aiState == "waiting" or aiState == "wandering" then
        if tes3.getCurrentAIPackageId(self.reference.mobile) ~= tes3.aiPackage.wander then

            common.log:debug("%s Restoring %s AI", self:getName(), aiState)
            self:setAI(aiState)
        end
    elseif aiState == "attacking" then
        if self.reference.mobile.inCombat ~= true then

            self:restorePreviousAI()
        end
    end
    --Check if stuck on something while wandering
    if aiState == "wandering" then
        local isStuck = self:getIsStuck()
        if isStuck then
            common.log:debug("Stuck, resetting wander")
            self:wait()
            --set back to wandering in case of save/load
            self.refData.aiState = "wandering"
            timer.start{
                duration = 0.5,
                callback = function() 
                    if self.refData.aiState == "wandering" then
                        common.log:debug("Still need to wander, setting now")
                        self:wander() 
                    end
                end
            }
        end
    end

    --[[
        We don't want to edit the hostileActors list while 
        we are iterating it, so we store the hotiles in a local
        table then stopCombat afterwards
    ]]
    local hostileStopList = {}
    for hostile in tes3.iterate(self.reference.mobile.hostileActors) do
        if hostile.health.current <= 1 then
            common.log:debug("%s is dead, stopping combat", hostile.object.name)
            table.insert(hostileStopList, hostile)
        end
    end
    
    for _, hostile in ipairs(hostileStopList) do 
        self.reference.mobile:stopCombat(hostile)
    end

    --Make sure the lanterns are working properly
    self.reference.sceneNode:update()
    self.reference.sceneNode:updateNodeEffects()
end

function Animal:fixSoundBug()

    local bugged = (
        tes3.getSoundPlaying{ sound = "SwishL", reference = self.reference } or
        tes3.getSoundPlaying{ sound = "SwishM", reference = self.reference } or
        tes3.getSoundPlaying{ sound = "SwishS", reference = self.reference } or
        tes3.getSoundPlaying{ sound = "guar roar", reference = self.reference }
    ) and not self.reference.mobile.inCombat
    if bugged then
        common.log:debug("restoring lantern to on after combat")
        tes3.removeSound{ reference = self.reference, "SwishL"}
        tes3.removeSound{ reference = self.reference, "SwishM"}
        tes3.removeSound{ reference = self.reference, "SwishS"}
        tes3.removeSound{ reference = self.reference, "guar roar"}
        --increase strength for a frame to avoid encumbrance issues
        tes3.modStatistic {
            reference = tes3.player,
            name = "strength",
            current = 50
        }
        local lightsMoved = {}
        --Transfer all lights, preserving item data, from guar to player
        for stack in tes3.iterate(self.reference.object.inventory.iterator) do
            if stack.object.objectType == tes3.objectType.light then
                lightsMoved[stack.object.id] = {}
                local leftOver = stack.count or 1
                if stack.variables  then
                    leftOver = leftOver - #stack.variables
                    lightsMoved[stack.object.id].itemData = {}
                    for i = 1, #stack.variables do
                        lightsMoved[stack.object.id].itemData[i] = stack.variables[i]
                        tes3.transferItem{
                            from = self.reference,
                            to = tes3.player,
                            item = stack.object,
                            itemData = stack.variables[i],
                            playSound = false,
                        }
                    end
                end
                --might be no more object at this point
                if stack.object then
                    --transfer whatever's left
                    lightsMoved[stack.object.id].leftOver = leftOver
                    if leftOver > 0 then
                        tes3.transferItem{
                            from = self.reference,
                            to = tes3.player,
                            item = stack.object,
                            count = leftOver,
                            playSound = false,
                        }
                    end
                end
                
            end
        end
        --now transfer them all back after a frame
        timer.delayOneFrame(function()
            for objectId, data in pairs(lightsMoved) do
                if data.itemData then
                    for _, itemData in ipairs(data.itemData) do
                        tes3.transferItem{
                            from = tes3.player,
                            to = self.reference,
                            item = objectId,
                            itemData = itemData,
                            playSound = false,
                        }
                    end
                end
                if data.leftOver and data.leftOver > 0 then
                    tes3.transferItem{
                        from = tes3.player,
                        to = self.reference,
                        item = objectId,
                        count = data.leftOver,
                        playSound = false,
                    }
                end
                
            end
            --restore player strength to previous value
            tes3.modStatistic {
                reference = tes3.player,
                name = "strength",
                current = -50
            }

            --toggle lights to update scene effects etc
            if self.refData.lanternOn then
                self:turnLanternOff()
                self:turnLanternOn()
            end
        end)
    end
end


function Animal:updateTravelSpells()
    local effects = {
        [tes3.effect.levitate] = "mer_tgw_lev",
        [tes3.effect.waterWalking] = "mer_tgw_ww",
        --[tes3.effect.invisibility] = "mer_tgw_invs"
    }

    if not self:isActive() then return end
    for effect, spell in pairs(effects) do
        if tes3.isAffectedBy{ reference = tes3.player, effect = effect } then
            --not affected but player is
            if not tes3.isAffectedBy{ reference = self.reference, effect = effect } then
                if self:getAI() == "following" then
                    common.log:debug("Adding spell to %s", self.refData.name)
                    self.reference.object.spells:remove(spell)
                    mwscript.addSpell{reference = self.reference, spell = spell }
                end
            end

        else
            --effected but player isn't
            if tes3.isAffectedBy{ reference = self.reference, effect = effect } then
                common.log:debug("Removing spell from %s", self.refData.name)
                mwscript.removeSpell{reference = self.reference, spell = spell }
            end
        end
        --affected no longer following
        if tes3.isAffectedBy{ reference = self.reference, effect = effect } then
            if self:getAI() ~= "following" then
                common.log:debug("Removing spell from %s", self.refData.name)
                mwscript.removeSpell{reference = self.reference, spell = spell }
            end
        end
    end
end

-----------------------------------------
-- UI stuff
------------------------------------------

function Animal:getMenuTitle()
    local name = self.refData.named and self.refData.name or "This"
    return string.format(
        "%s is a %s%s %s. %s %s.",
        name, self.refData.isBaby and "baby " or "", self.refData.gender, self.animalData.type,
        self:getHeShe(), self:getMood("happiness").description
    )
end

function Animal:getStatusMenu()
    ui.showStatusMenu(self)
end

----------------------------------------
--Commands
----------------------------------------


function Animal:takeAction(time)
    self.refData.takingAction = true
    timer.start{
        duration = time,
        callback = function() self.refData.takingAction = false end
    }
end

function Animal:canTakeAction()
    return not self.refData.takingAction
end





function Animal:pet()
    common.log:debug("Petting")
    self:modAffection(30)
    tes3.messageBox(self:getMood("affection").pettingResult(self) )
    self:playAnimation("pet")
    self:takeAction(2)
    if self.refData.trust < moodConfig.skillRequirements.follow then
        self:modTrust(2)
    end
end


function Animal:feed()
    timer.delayOneFrame(function()
        tes3ui.showInventorySelectMenu{
            reference = tes3.player,
            title = string.format("Feed %s", self.refData.name),
            noResultsText = string.format("You do not have any appropriate food."),
            filter = function(e)
                common.log:trace("Filter: checking: %s", e.item.id)

                for id, value in pairs(self.animalData.foodList) do
                    common.log:trace("%s: %s", id, value)
                end
                return (
                    e.item.objectType == tes3.objectType.ingredient and 
                    self.animalData.foodList[string.lower(e.item.id)] ~= nil
                )
            end,
            callback = function(e)
                if e.item then
                    self:eatFromInventory(e.item, e.itemData) 
                end
            end
        }
    end)
end

function Animal:rename(isBaby)
    local label = isBaby and string.format("Name your new baby %s %s", self.refData.gender, self.animalData.type) or 
        string.format("Enter the new name of your %s %s:",self.refData.gender, self.animalData.type)
    local renameMenuId = tes3ui.registerID("TheGuarWhisperer_Rename")
    local function nameChosen()

        self.refData.name = common.upperFirst(self.refData.name)
        tes3ui.leaveMenuMode(renameMenuId)
        tes3ui.findMenu(renameMenuId):destroy()
        tes3.messageBox("%s has been renamed to %s", common.upperFirst(self.animalData.type), self.refData.name)
        self.refData.named = true
        self:playAnimation("happy")
    end

        local menu = tes3ui.createMenu{ id = renameMenuId, fixedFrame = true }
        menu.minWidth = 400
        menu.alignX = 0.5
        menu.alignY = 0
        menu.autoHeight = true
        mwse.mcm.createTextField(
            menu,
            {
                label = label,
                variable = mwse.mcm.createTableVariable{
                    id = "name", 
                    table = self.refData
                },
                callback = nameChosen
            }
        )
        tes3ui.enterMenuMode(renameMenuId)
end




-------------------------------------
-- Genetics Funcitons
--------------------------------------

function Animal:updateGrowth()
    local age = common.getHoursPassed() - self.refData.birthTime
    if self.refData.isBaby then
        if age > self.animalData.hoursToMature then
            --No longer a baby, turn into an adult
            self.refData.isBaby = false
            if not self.refData.named then
                self.refData.name = self.reference.object.name
            end
            self.reference.scale = 1
        else
            --map scale to age
            local newScale = math.remap(age, 0,  self.animalData.hoursToMature, self.animalData.babyScale, 1)
            self.reference.scale = newScale
        end    
        self:scaleAttributes()
    end
end


--Scales attributes based on physical scale
--at 0.5 scale, attributes are half of adult ones etc
function Animal:scaleAttributes()
    if not self.refData.attributes then self:randomiseGenes() end
    local scale = self.reference.scale
    for attrName, attribute in pairs(tes3.attribute) do
        local newValue = self.refData.attributes[attribute + 1]
        --Speed is actually faster for babies
        if attrName ~= "speed" then
            newValue = newValue * scale
        else
            newValue = newValue * ( 1 / scale )
        end
        newValue = math.floor(newValue)
        tes3.setStatistic{
            reference = self.reference,
            name = attrName,
            value = newValue
        }
    end
    tes3.setStatistic{
        reference = self.reference,
        name = "health",
        base = 100 * scale
    }
    if self.reference.mobile.health.current > self.reference.mobile.health.base then
        tes3.setStatistic{
            reference = self.reference,
            name = "health",
            current = 100 * scale
        }
    end
end

--Averages the attributes of mom and dad and adds some random mutation
--Stores them on refData so they can be scaled down during adolescence
function Animal:inheritGenes(mom, dad)
    self.refData.attributes = {}
    for _, attribute in pairs(tes3.attribute) do
        --get base values of parents
        local momVal = mom.mobile.attributes[attribute + 1].base
        local dadVal = dad.mobile.attributes[attribute + 1].base
        --find the average between them
        local average = (momVal + dadVal) / 2
        --mutation range is 1/10th of average, so higher values = more mutation
        local mutationRange = math.clamp(average * 0.1, 5, 50)
        local mutation = math.random(-mutationRange, mutationRange)
        local finalValue = math.floor(average + mutation)
        finalValue = math.max(finalValue, 0)
        
        self.refData.attributes[attribute + 1] = finalValue
    end
end

function Animal:randomiseGenes()
    --For converting guars, we get its genetics by treating itself as its parents
    --Which randomises its attributes, then updateGrowth should apply to the object
    self:inheritGenes(self.reference, self.reference)
end

function Animal.getWhiteBabyChance()
    local chanceOutOf = 50
    local merlordESPs = {
        "Ashfall.esp",
        "BardicInspiration.esp",
        "Character Backgrounds.esp",
        "DemonOfKnowledge.esp",
        "Go Fletch.esp",
        "Love_Pillow_Hunt.esp",
        "theMidnightOil.ESP"
    }
    local merlordMWSEs = {
        "backstab",
        "BedBuddies",
        "BookWorm",
        "class-description",
        "KillCommand",
        "MarksmanRebalanced",
        "Mining",
        "MiscMates",
        "NoCombatMenu",
        "QuickLoadouts",
        "RealisticRepair",
        "StartingEquipment",
        "lessAggressiveCreatures",
        "accidentalTheftProtection"
    }
    for _, esp in ipairs(merlordESPs) do
        if tes3.isModActive(esp) then
            chanceOutOf = chanceOutOf - 1
        end
    end
    for _, mod in ipairs(merlordMWSEs) do
        if tes3.getFileExists(string.format("MWSE\\mods\\mer\\%s\\main.lua", mod)) then
            chanceOutOf = chanceOutOf - 1
        end
    end
    local roll = math.random(chanceOutOf)
    return roll == 1
end

function Animal:getCanConceive()
    if not self.animalData.breedable then return false end
    if not ( self.refData.gender == "female" ) then return false end
    if self.refData.isBaby then return false end
    if not self.mobile.hasFreeAction then return false end
    if self.refData.trust < moodConfig.skillRequirements.breed then return false end
    if self.refData.lastBirthed then
        local now = common.getHoursPassed()
        local hoursSinceLastBirth = now - self.refData.lastBirthed
        local enoughTimePassed = hoursSinceLastBirth > self.animalData.birthIntervalHours
        if not enoughTimePassed then return false end
    end
    return true
end

function Animal:canBeImpregnatedBy(animal)
    if not animal.animalData.breedable then return false end
    if not (animal.refData.gender == "male" ) then return false end
    if animal.refData.isBaby then return false end
    if not animal.mobile.hasFreeAction then return false end
    if self.refData.trust < moodConfig.skillRequirements.breed then return false end
    local distance = animal.mobile.position:distance(self.mobile.position)
    if distance > 1000 then
        return false
    end
    return true
end



function Animal:breed()
    --Find nearby animal
    local partnerList = {}

    common.iterateRefType("companion", function(ref)
        local animal = Animal:new(ref)
        if self:canBeImpregnatedBy(animal) then
            table.insert(partnerList, animal)
        end
    end)

    if #partnerList > 0 then
        local function doBreed(partner)
            partner:playAnimation("pet")
            local baby
            timer.start{ type = timer.real, duration = 1, callback = function()
                local color = self:getWhiteBabyChance() and "white" or "standard"
                self.refData.lastBirthed  = common.getHoursPassed()
                local babyRef = tes3.createReference{
                    object = animalConfig.guarMapper[color],
                    position = self.reference.position,
                    orientation =  {
                        self.reference.orientation.x,
                        self.reference.orientation.y,
                        self.reference.orientation.z,
                    },
                    cell = self.reference.cell,
                    scale = self.animalData.babyScale
                }
                babyRef.mobile.fight = 0
                babyRef.mobile.flee = 0

                baby = Animal:new(babyRef)
                baby.refData.isBaby = true
                baby.refData.trust = self.animalData.trust.babyLevel
                --baby:inheritGenes(self, partner)
                baby:updateGrowth()
                baby:setHome(baby.reference.position, baby.reference.cell)
                baby:setAttackPolicy("defend")

                baby:wander()
                timer.delayOneFrame(function()
                    baby:returnTo(self.reference)
                end)

            end}
            
            common.fadeTimeOut(0.5, 2, function()
                timer.delayOneFrame(function()
                    baby:rename(true)
                end)
            end)
        end
        local buttons = {}
        local i = 1
        for _, partner in ipairs(partnerList) do
            table.insert(buttons, 
                { 
                    text = string.format("%d. %s", i, partner.refData.name ),
                    callback = function()
                        doBreed(partner)
                    end
                }
            )
        end
        table.insert( buttons, { text = "Cancel"})

        common.messageBox{
            message = string.format("Which partner would you like to breed %s with?", self.refData.name ),
            buttons = buttons
        }
    else
        tes3.messageBox("There are no valid partners nearby.")
    end
end



------------------------------------------
-- Switch node pack functions
--------------------------------------------


function Animal:hasPackItem(packItem) 
    local isDead = self:isDead()
    local itemEquipped
    --No items associated, base off pack
    if not packItem.items or #packItem.items == 0 then
        packItem = common.packItems.pack
    end
    --While alive, no pack in inventory, base off hasPack
    if packItem == common.packItems.pack then
        if not isDead then
            itemEquipped = self.refData.hasPack
        end
    end
    --iterate over items
    for _, item in ipairs(packItem.items) do
        if self.reference.object.inventory:contains(item) then
            if self.refData.carriedItems and self.refData.carriedItems[item] then
                --Oh god we need to check the inventory count is higher than the carried Item count
            end
            itemEquipped = true
        end
    end

    if itemEquipped then
        --If item equipped, we also need to check the pack is equipped
        if packItem == common.packItems.pack then
            return true
        end
        return self:hasPackItem(common.packItems.pack)
    else
        return false
    end

end



function Animal.removeLight(lightNode) 

    for node in table.traverse{lightNode} do
        --Kill particles
        if node.RTTI.name == "NiBSParticleNode" then
            --node.appCulled = true
            node.parent:detachChild(node)
        end
        --Kill Melchior's Lantern glow effect
        if node.name == "LightEffectSwitch" or node.name == "Glow" then
            --node.appCulled = true
            node.parent:detachChild(node)
        end
        if node.name == "AttachLight" then
            --node.appCulled = true
            node.parent:detachChild(node)
        end
        
        -- Kill materialProperty 
        local materialProperty = node:getProperty(0x2)
        if materialProperty then
            if (materialProperty.emissive.r > 1e-5 or materialProperty.emissive.g > 1e-5 or materialProperty.emissive.b > 1e-5 or materialProperty.controller) then
                materialProperty = node:detachProperty(0x2):clone()
                node:attachProperty(materialProperty)
        
                -- Kill controllers
                materialProperty:removeAllControllers()
                
                -- Kill emissives
                local emissive = materialProperty.emissive
                emissive.r, emissive.g, emissive.b = 0,0,0
                materialProperty.emissive = emissive
        
                node:updateProperties()
            end
        end
     -- Kill glowmaps
        local texturingProperty = node:getProperty(0x4)
        local newTextureFilepath = "Textures\\tx_black_01.dds"
        if (texturingProperty and texturingProperty.maps[4]) then
        texturingProperty.maps[4].texture = niSourceTexture.createFromPath(newTextureFilepath)
        end
        if (texturingProperty and texturingProperty.maps[5]) then
            texturingProperty.maps[5].texture = niSourceTexture.createFromPath(newTextureFilepath)
        end 
    end
    lightNode:update()
    lightNode:updateNodeEffects()

end

function Animal:getHeldItem(packItem)
    for _, item in ipairs(packItem.items) do
        if self.reference.object.inventory:contains(item) then
            return tes3.getObject(item)
        end
    end
end


function Animal:attachLantern(lanternObj)
    local lanternParent = self.reference.sceneNode:getObjectByName("LANTERN")
    --get lantern mesh and attach
    local itemNode = tes3.loadMesh(lanternObj.mesh):clone()
    --local attachLight = itemNode:getObjectByName("AttachLight")
    --attachLight.parent:detachChild(attachLight)
    itemNode:clearTransforms()
    itemNode.name = lanternObj.id
    lanternParent:attachChild(itemNode, true)
end    

function Animal:detachLantern()
    local lanternParent = self.reference.sceneNode:getObjectByName("LANTERN")
    lanternParent:detachChildAt(1)
end


function Animal:turnLanternOn(e)
    e = e or {}
    if not self.reference.sceneNode then return end
    --First we gotta delete the old one and clone again, to get our material properties back
    local lanternParent = self.reference.sceneNode:getObjectByName("LANTERN")
    if lanternParent and lanternParent.children and #lanternParent.children > 0 then
        local lanternId = lanternParent.children[1].name
        self:detachLantern()
        self:attachLantern(tes3.getObject(lanternId))

        local lightParent = self.reference.sceneNode:getObjectByName("LIGHT")
        lightParent.translation.z = 0

        local lightNode = self.reference.sceneNode:getObjectByName("LanternLight")
        lightNode:setAttenuationForRadius(256)

        self.reference.sceneNode:update()
        self.reference.sceneNode:updateNodeEffects()
        
        self.reference:getOrCreateAttachedDynamicLight(lightNode, 1.0)

        self.refData.lanternOn = true

        if e.playSound == true then
            tes3.playSound{ reference = tes3.player, sound = "mer_tgw_alight", pitch = 1.0}
        end
    end
end


function Animal:turnLanternOff(e)
    e = e or {}
    if not self.reference.sceneNode then return end
    local lanternParent = self.reference.sceneNode:getObjectByName("LANTERN")
    self.removeLight(lanternParent)
    local lightParent = self.reference.sceneNode:getObjectByName("LIGHT")
    lightParent.translation.z = 1000
    local lightNode = self.reference.sceneNode:getObjectByName("LanternLight")
    if lightNode then
        lightNode:setAttenuationForRadius(0)
        self.reference.sceneNode:update()
        self.reference.sceneNode:updateNodeEffects()
        self.refData.lanternOn = false
        if e.playSound == true then
            tes3.playSound{ reference = tes3.player, sound = "mer_tgw_alight", pitch = 1.0}
        end
    end
end


function Animal:setSwitch()
    if not self.reference.sceneNode then return end
    if not self.reference.mobile then return end
    local animState = self.reference.mobile.actionData.animationAttackState

    --don't update nodes during dying animation
    --if health <= 0 and animState ~= tes3.animationState.dead then return end
    if animState == tes3.animationState.dying then return end

    for _, packItem in pairs(common.packItems) do
        local node = self.reference.sceneNode:getObjectByName(packItem.id)
        
        if node then
            node.switchIndex = self:hasPackItem(packItem) and 1 or 0
            if self.refData.hasPack and common.getConfig().displayAllGear and packItem.dispAll then
                node.switchIndex =  1
            end

            --switch has changed, add or remove item meshes
            if packItem.attach then
                if packItem.light then
                    if self.refData.ignoreLantern then
                        node.switchIndex = 0
                        break
                    end
                    --attach item
                    local onNode = node.children[2]
                    local lightParent = onNode:getObjectByName("LIGHT")
                    local lanternParent = self.reference.sceneNode:getObjectByName("LANTERN")

                    if node.switchIndex == 1 then       
                        local itemHeld = self:getHeldItem(packItem)

                         --Add actual light
                    
                        --Check if its a different light, remove old one
                        local sameLantern
                        if lanternParent.children and lanternParent.children[1] ~= nil then
                            local currentLanternId = lanternParent.children[1].name
                            if itemHeld.id == currentLanternId then
                                sameLantern = true
                            end
                        end

                        if sameLantern ~= true then
                            common.log:debug("Changing lantern")
                            self:detachLantern()
                            self:attachLantern(itemHeld)

                            --set up light properties
                            local lightNode = onNode:getObjectByName("LanternLight") or niPointLight.new()
                            lightNode.name = "LanternLight"
                            lightNode.ambient = tes3vector3.new(0,0,0)
                            lightNode.diffuse = tes3vector3.new(
                                itemHeld.color[1] / 255,
                                itemHeld.color[2] / 255,
                                itemHeld.color[3] / 255
                            )
                            lightParent:attachChild(lightNode, true)
                            --Attach the light
                            if self.refData.lanternOn then
                                self:turnLanternOn()
                            else
                                self:turnLanternOff()
                            end
                        end
                    else
                        --detach item and light
                        if onNode:getObjectByName("LanternLight") then
                            self:detachLantern()
                            self:turnLanternOff()
                        end
                    end
                end
            end
        end
    end
end

function Animal:equipPack()
    if not self.reference.context or not self.reference.context.Companion then
        mwse.error("[Guar Whisperer] Attempting to give pack to guar with no Companion var")
    end
    self.reference.context.companion = 1
    tes3.removeItem{
        reference = tes3.player,
        item = common.packId,
        playSound = true
    }
    self.refData.hasPack = true
    self:setSwitch()
end

function Animal:unequipPack()
    if self.reference.context and self.reference.context.Companion then
        self.reference.context.companion = 0
    end

    for stack in tes3.iterate(self.reference.object.inventory.iterator) do
        tes3.transferItem{
            from = self.reference,
            to = tes3.player, 
            item = stack.object,
            itemData = stack.itemData,
            count = stack.count or 1,
            playSound=false
        }
        tes3.removeItem{
            reference = self.reference,
            item = common.packId,
            playSound = false
        }
    
    end

    tes3.addItem{
        reference = tes3.player, 
        item = common.packId,
        playSound = true
    }

    self.refData.hasPack = false
    self:setSwitch()
end


function Animal:activate()
    if not self:isActive() then 
        common.log:trace("not active")
        return 
    end
    if self:isDead() then 
        common.log:trace("guar is dead")
        return 
    end
    if not self.reference.mobile.hasFreeAction then 
        common.log:trace("no free action")
        return 
    end
    --Allow regular activation for dialog/companion share
    if self.refData.triggerDialog == true then
        common.log:debug("triggerDialog true, entering companion share")
        self.refData.triggerDialog = nil
        return
    --Block activation if issuing a command
    elseif common.data.skipActivate then
        common.log:trace("skipActivate")
        common.data.skipActivate = false
        return false
    --Otherwise trigger custom activation
    else
        if self.refData.carriedItems ~= nil then
            self.refData.commandActive = false
            self:handOverItems()
            self:restorePreviousAI()
        elseif self.refData.commandActive then
            common.log:trace("command is active")
            self.refData.commandActive = false
        else
            if self:canTakeAction() then
                common.log:trace("showing command menu")
                event.trigger("TheGuarWhisperer:showCommandMenu", { animal = self })
            else
                common.log:trace("can't take action")
            end
        end
        return false
    end
end

return Animal