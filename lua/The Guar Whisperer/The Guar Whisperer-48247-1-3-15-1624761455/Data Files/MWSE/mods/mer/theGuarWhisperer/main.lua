--[[

    The Guar Whisperer
        by Merlord

    This mod allows you to tame and breed guars. 

    Author: Merlord (https://www.nexusmods.com/morrowind/users/3040468)
    Original script from Feed the animals mod by OperatorJack and RedFurryDemon
    https://www.nexusmods.com/morrowind/mods/47894

]]
require("mer.theGuarWhisperer.MCM")
require("mer.theGuarWhisperer.quickkeys")

local animalController = require("mer.theGuarWhisperer.animalController")
local commandMenu = require("mer.theGuarWhisperer.CommandMenu.CommandMenuModel")
local ui = require("mer.theGuarWhisperer.ui")
local animalConfig = require("mer.theGuarWhisperer.animalConfig")
local common = require("mer.theGuarWhisperer.common")
require("mer.theGuarWhisperer.interop")

local function getAnimalData(reference)
    if not reference then return false end
    if not reference.mobile then return false end
    if not (reference.object.objectType == tes3.objectType.creature) then return false end
    local crMesh = reference.object.mesh:lower()
    common.log:trace("getAnimalData(): Mesh path: %s", crMesh)
    local typeData = animalConfig.meshes[crMesh]
    if typeData then
        return typeData
    else
        return false
    end
end

local function activateAnimal(e)
    common.log:trace("activateAnimal(): Activating %s", e.target.object.id)
    if not common.getModEnabled() then 
        common.log:trace("activateAnimal(): mod is disabled")
        return 
    end
    if e.activator ~= tes3.player then 
        common.log:trace("activateAnimal(): Player is not activating")
        return 
    end
    --check if companion
    local animal = animalController.getAnimal(e.target)
    if animal then
        common.log:trace("activateAnimal(): %s is a guar", e.target.object.id)
        return animal:activate()
    else
        if e.target.object.script then 
            local obj = e.target.baseObject or e.target.object
            if common.getConfig().exclusions[obj.id:lower()] then
                common.log:trace("Scripted but whitelisted")
            else
                common.log:trace("activateAnimal(): %s is blacklisted", e.target.object.id)
                return
            end 
        end
        if not e.target.mobile then 
            common.log:trace("activateAnimal(): %s does not have an associated mobile", e.target.object.id)
            return 
        end
        if common.getIsDead(e.target) then 
            common.log:trace("activateAnimal(): %s is dead", e.target.object.id)
            return 
        end
        local animalData = getAnimalData(e.target)
        if not animalData then
            common.log:trace("activateAnimal(): Failed to get animal data for %s", e.target.object.id)
        else
            local foodId
            for ingredient, _ in pairs(animalConfig.animals.guar.foodList) do
                if tes3.player.object.inventory:contains(ingredient) then
                    foodId = ingredient
                    break
                end
            end
            if not foodId then
                common.log:trace("activateAnimal(): No valid guar food found on player")
            else
                common.log:trace("activateAnimal(): Food (%s) found, triggering messageBox to tame guar", foodId)
                local food = tes3.getObject(foodId)
                common.messageBox{
                    message = string.format("The %s sniffs around your pack. He seems to be eyeing up your %s.", e.target.object.name, food.name),
                    buttons = {
                        {
                            text = string.format("Give the %s some %s", e.target.object.name, food.name),
                            callback = function()
                                local newAnimal = animalController.convertToTamedGuar(e.target, animalData)
                                newAnimal:eatFromInventory(food)
                                timer.start{
                                    duration = 1.5,
                                    callback = function()
                                        newAnimal:rename()
                                        timer.delayOneFrame(function()
                                            local name = newAnimal.refData.name
                                            local heShe = newAnimal:getHeShe(true)
                                            local himHer = newAnimal:getHimHer(true)
                                            local hisHer = newAnimal:getHisHer(true)
                                            tes3.messageBox{
                                                message = string.format(
                                                    "%s doesn't trust you enough to accompany you. Try petting %s and giving %s some treats. As %s trust builds up over time, %s will learn new skills like fetching items and wearing a pack.",
                                                    name, himHer, himHer, hisHer, heShe
                                                ),
                                                buttons = { "Okay" }
                                            }
                                        end)
                                    end
                                }
                            end
                        },
                        { 
                            text = "Do nothing",
                            callback = function() 
                                local sadAnim = animalConfig.idles.sad
                                tes3.playAnimation{
                                    reference = e.target,
                                    group = tes3.animationGroup[sadAnim],
                                    loopCount = 1,
                                    startFlag = tes3.animationStartFlag.immediate
                                }
                                tes3.messageBox("%s gives out a sad whine.", e.target.object.name)
                            end
                        }
                    }
                }
                return false
            end
        end
    end
end
local function onEquipWhistle(e)
    if not common.getModEnabled() then 
        common.log:trace("activateWhistle(): Mod disabled")
        return 
    end
    if not ( e.item.id == common.fluteId ) then
        common.log:trace("activateWhistle(): Activated item not a whistle: %s", e.item.id)
    else
        common.log:trace("activateWhistle(): Found a whistle. Leaving menu mode: %s", e.item.id)
        tes3ui.leaveMenuMode()
        timer.delayOneFrame(function()
            local buttons = {}
            if tes3.player.cell.isInterior ~= true then
                common.iterateRefType("companion", function(ref)
                    local animal = animalController.getAnimal(ref)
                    if animal and animal:canBeSummoned() then
                        common.log:trace("activateWhistle(): %s can be summoned, adding to list", animal.refData.name)
                        table.insert(buttons, {
                            text = animal.refData.name,
                            callback = function()
                                timer.delayOneFrame(function()
                                    tes3.playSound{ reference = tes3.player, sound = common.fluteSound, }
                                    animal:wait()
                                    timer.start{
                                        duration = 1,
                                        callback = function() animal:teleportToPlayer(400) end
                                    }
                                    common.fadeTimeOut( 0, 2, function()
                                        animal:playAnimation("pet")
                                        animal:follow()
                                    end)
                                end)
                            end
                        })
                    end
                end)
            else
                common.log:trace("In interior, whistle won't work")
            end

            if #buttons > 0 then
                common.log:trace("activateWhistle(): Found at least one companion, calling messageBox")
                table.insert(buttons, { text = "Cancel"})
                common.messageBox{
                    message = "Which guar do you want to call?",
                    buttons = buttons
                }
            else
                common.log:trace("activateWhistle(): No companions found, playing whistle sound")
                tes3.playSound{ reference = tes3.player, sound = common.fluteSound, }
            end
        end)
    end
end

local function isAffectedBySpellType(mobile, spellType)
    for _, activeEffect in pairs(mobile.activeMagicEffectList) do
        local instance = activeEffect.instance
        if instance then
            if instance.source.castType == spellType then
                common.log:trace("Is affected by spell type")
                return true
            end
        end
    end
end

local function onTooltip(e)
    if not common.getModEnabled() then return end
    if not e.reference then return end
    local animal = animalController.getAnimal(e.reference)
    if animal then
        --Rename
        local label = e.tooltip:findChild(tes3ui.registerID("HelpMenu_name"))
        if animal.refData.name then
            local prefix = animal.refData.isBaby and not animal.refData.named and "Baby " or ""
            label.text = prefix .. animal.refData.name
        end

        if isAffectedBySpellType(animal.reference.mobile, tes3.spellType.blight) then
            label.text = label.text .. (" (Blighted)")
        elseif isAffectedBySpellType(animal.reference.mobile, tes3.spellType.disease) then
            label.text = label.text .. (" (Diseased)")
        end

        --Add stats
        ui.createStatsBlock(e.tooltip, animal)
    end
end

local function guarTimer()
    if not common.getModEnabled() then return end
    common.iterateRefType("companion", function(ref)
        local animal = animalController.getAnimal(ref)
        if animal then
            animal:setSwitch()
            if animal:isActive() then
                animal:updateGrowth()
                
                animal:updateAI()
                animal:updateTravelSpells()
                animal:fixSoundBug()
            end
            animal:updateMood()
            animal:updateCloseDistance()
        end
    end)
end

local function findFood(animal)
    for ref in animal.reference.cell:iterateReferences(tes3.objectType.container) do
        if animal:canEat(ref) then 
            if animal.reference.position:distance(ref.position) < 1000 then
                return ref
            end
        end
    end
    for ref in animal.reference.cell:iterateReferences(tes3.objectType.ingredient) do
        if animal:canEat(ref) then 
            if animal.reference.position:distance(ref.position) < 1000 then
                return ref
            end
        end
    end
end

local function findGreetable(animal)
    for ref in animal.reference.cell:iterateReferences(tes3.objectType.creature) do
        local isHappyGuar = (
            ref ~= animal.reference and
            animalConfig.greetableGuars[ref.object.mesh:lower()] and
            ref.mobile and ref.mobile.health.current > 5 and
            not ref.mobile.inCombat
        )

        if isHappyGuar then
            if ref.position:distance(animal.reference.position) < 1000 then
                common.log:debug("Found Guar '%s' to greet", ref.object.name)
                return ref
            end
        end
    end 
    for ref in animal.reference.cell:iterateReferences(tes3.objectType.npc) do
        local isHappyNPC = (
            ref.mobile and 
            not ref.mobile.isDead and
            not ref.mobile.inCombat and
            ref.mobile.fight < 70
        )
        if isHappyNPC then
            if ref.position:distance(animal.reference.position) < 1000 then
                common.log:debug("Found NPC '%s' to greet", ref.object.name)
                return ref
            end
        end
    end
end


local lastRef
local function randomActTimer()
    if not common.getModEnabled() then return end
    common.log:debug("Random Act Timer")
    local actingRef
    common.iterateRefType("companion", function(ref)
        local animal = animalController.getAnimal(ref)
        if animal and animal.mobile then
            if animal:isActive() then
                if  animal:getAI() == "wandering" then
                    common.log:debug("%s is wandering, deciding action", animal:getName())
                    if ref.id ~= lastRef then
                        actingRef = ref.id
                        --check for food to eat
                        if animal.refData.hunger > 40 then
                            local food = findFood(animal)
                            if food then
                                common.log:debug("randomActTimer: Guar eating")
                                animal:moveToAction(food, "eat", true)
                                return false
                            end
                        end
                        --check for other guar
                        local guar = findGreetable(animal)
                        if guar then 
                            common.log:debug("randomActTimer: Guar greeting")
                            animal:moveToAction(guar, "greet", true)
                            return false
                        end
                        if math.random(100) < 20 then
                            common.log:debug("randomActTimer: Guar running")
                            animal.reference.mobile.isRunning = true
                        end
                    end
                elseif animal:getAI() == "waiting" then
                    local rand = math.random(100)
                    common.log:debug("rand: %s", rand)
                    for _, data in ipairs(common.idleChances) do
                        if rand < data.maxChance then
                            common.log:debug("playing random animation %s",data.group)
                            tes3.playAnimation{
                                reference = animal.reference,
                                group = tes3.animationGroup[data.group],
                                loopCount = 1,
                                startFlag = tes3.animationStartFlag.normal
                            }
                            break
                        end
                    end
                end
            end
        end
    end)
    --only one guar, let him act again
    if actingRef == lastRef then 
        lastRef = nil
    else
        --otherwise block him so others can go 
        lastRef = actingRef
    end

    timer.start{
        type = timer.simulate, 
        iterations = 1,
        duration = math.random(20, 40),
        callback = randomActTimer
    }

end

local function initialiseVisuals()
    common.iterateRefType("companion", function(ref)
        local animal = animalController.getAnimal(ref)
        if animal and not animal:isDead() then
            animal:playAnimation("idle")
            if animal.refData.carriedItems then
                for _, item in pairs(animal.refData.carriedItems) do
                    animal:putItemInMouth(tes3.getObject(item.id))
                end
            end
        end
    end)
end

local function startTimers()
    timer.start{
        type = timer.simulate, 
        iterations = -1,
        duration = 0.2,
        callback = guarTimer
    }
    timer.start{
        type = timer.simulate, 
        iterations = 1,
        duration = math.random(5, 10),
        callback = randomActTimer
    }
end

--Iterate over active animals
local function onDataLoaded()
    commandMenu:destroy()
    initialiseVisuals()
    startTimers()
    --mwscript.addTopic{ topic = "raising guars" }
end

--Keep track of active references
local function onObjectInvalidated(e)
    local ref = e.object
    if ( not not common.fetchItems[ref] ) then
        common.fetchItems[ref] = nil
    end
end



local function onDeath(e)
    local animal = animalController.getAnimal(e.reference)
    if animal then
        animal.refData.dead = true
        animal.refData.aiState = nil
        if animal.refData.hasPack == true then
            tes3.addItem{
                reference = animal.reference, 
                item = common.packId,
                playSound = false
            }
        end
    end
end

-- local doSkip
-- local function checkDoorTeleport(e)
--     if true then return end
--     if not common.getModEnabled() then return end
--     if doSkip then 
--         doSkip = false
--         return 
--     end
--     if e.target.object.objectType == tes3.objectType.door then
--         if e.target.destination then
--             if e.target.destination.cell.isInterior then
--                  common.iterateRefType("companion", function(ref)
--                     if animal:getAI() == "following" then
                        
--                         --start waiting
--                         animal:wait()
--                         --don't activate the door until following has stopped
--                         local function checkFollowing()
--                             if animal:getAI() ~= "following" then
--                                 doSkip = true
--                                 animal:follow()
--                                 if e.target then
--                                     tes3.player:activate(e.target)
--                                 end
--                                 event.unregister("simulate", checkFollowing)
--                             end
--                         end
--                         event.register("simulate", checkFollowing)
--                         --block this activation
--                         return false
--                     end
--                 end)
--             end
--         end
--     end
-- end

local function onCombatStart(e)
    if not common.getModEnabled() then return end
    if not common.data then return end
    local ref = e.actor.reference
    local target = e.target.reference

    --Prevent guars from fighting back against player
    if animal then
        if animal.refData.aiBroken then
            return 
        end
        local blockCombat = (
            target == tes3.player or --attacking player
            animalController.getAnimal(target) or --attacking other guar
            animal.refData.attackPolicy == "passive" --set to passive
            
        )
        if blockCombat then
            common.log:debug("Blocking combat")
            return false
        else
            common.log:debug("letting combat happen")
        end

        --turn off lantern
        if animal.refData.lanternOn == true then
            common.log:debug("Turning off lantern for combat")
            -- animal.refData.ignoreLantern = true
            -- animal:setSwitch()
        end
    end
    
    --If the player has entered combat, set nearby wandering guars to attack
    common.iterateRefType("companion", function(animalRef)
        animal = animalController.getAnimal(animalRef)
        if animal:getAI() ~= "following" then
            if animal:isActive() and not animal:isDead() and animal.refData.attackPolicy ~= "passive" then
                if animal.reference.position:distance(tes3.player.position) < 1000 then
                    common.log:debug("%s sees player being attacked", animal:getName())
                    animal.refData.previousAiState = animal:getAI()
                    animal:follow()
                end 
            end
        end
    end)
end

--[[
    This ridiculous bit of code is a workaround for a Morrowind bug that
    loops attack sounds on creatures who have lights in their inventories.

    It fixes it by moving all lights to the player for a single frame when combat ends.
]]
local function onCombatEnd(e)
    local animal = animalController.getAnimal(e.actor.reference)
    if animal and animal.mobile then
        animal:fixSoundBug() 
    end
end

local function onGuarAttack(e)
    local animal = animalController.getAnimal(e.reference)
    if animal then
        local progress = animal.animalData.lvl.attackProgress
        animal:progressLevel(progress)
    end 
end

--[[
    For guars from an old update, transfer them to new data table
]]
local function convertOldGuar(e)
    if  tes3.player
        and tes3.player.data
        and tes3.player.data.theGuarWhisperer
        and tes3.player.data.theGuarWhisperer.companions
        and tes3.player.data.theGuarWhisperer.companions[e.reference.id]
    then
        e.reference.data.tgw = tes3.player.data.theGuarWhisperer.companions[e.reference.id]
        tes3.player.data.theGuarWhisperer.companions[e.reference.id] = nil
    end
end

local function clearActionData(e)
    if e.reference.data 
        and e.reference.data.tgw 
        and e.reference.data.tgw.takingAction
    then
        e.reference.data.tgw.takingAction = nil
    end
end

local function initGuar(e)
    convertOldGuar(e)
    clearActionData(e)
end

local function getVersion()
    local versionFile = io.open("Data Files/MWSE/mods/mer/theGuarWhisperer/version.txt", "r")
    local version = ""
    for line in versionFile:lines() do -- Loops over all the lines in an open text file
        version = line
    end
    return version
end

local function initialised()
    
    if tes3.isModActive("TheGuarWhisperer.ESP") then
        require("mer.theGuarWhisperer.AI")
        require("mer.theGuarWhisperer.fetch") 
        require("mer.theGuarWhisperer.merchantInventory")
        require("mer.theGuarWhisperer.CommandMenu.commandMenuController")
        require("mer.theGuarWhisperer.tooltips")
        event.register("activate", activateAnimal)
        event.register("equip", onEquipWhistle)
        event.register("uiObjectTooltip", onTooltip)
        event.register("GuarWhispererDataLoaded", onDataLoaded)
        event.register("objectInvalidated", onObjectInvalidated) 
        event.register("death", onDeath)
        --event.register("activate", checkDoorTeleport)
        event.register("combatStart", onCombatStart)
        event.register("combatStopped", onCombatEnd)
        event.register("attack", onGuarAttack)
        common.log:info("%s Initialised", getVersion())
        event.register("mobileActivated", initGuar)
        event.register("loaded", function()
            for i, cell in ipairs(tes3.getActiveCells()) do
                for ref in cell:iterateReferences(tes3.objectType.creature) do
                    initGuar({ reference = ref})
                end
            end
        end)
    end
end
event.register("initialized", initialised)
