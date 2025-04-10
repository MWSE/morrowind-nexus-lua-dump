--[[

    The Guar Whisperer
        by Merlord

    This mod allows you to tame and breed guars.

    Author: Merlord (https://www.nexusmods.com/morrowind/users/3040468)
    Original script from Feed the guars mod by OperatorJack and RedFurryDemon
    https://www.nexusmods.com/morrowind/mods/47894

]]
require("mer.theGuarWhisperer.MCM")
require("mer.theGuarWhisperer.quickkeys")
require("mer.theGuarWhisperer.integrations")

local GuarCompanion = require("mer.theGuarWhisperer.GuarCompanion")
local GuarConverter = require("mer.theGuarWhisperer.services.GuarConverter")
local Syntax = require("mer.theGuarWhisperer.components.Syntax")
local Rider = require("mer.theGuarWhisperer.components.Rider")
local commandMenu = require("mer.theGuarWhisperer.CommandMenu.CommandMenu")
local StatsBlock = require("mer.theGuarWhisperer.ui.components.StatsBlock")
local guarConfig = require("mer.theGuarWhisperer.guarConfig")
local Action = require("mer.theGuarWhisperer.abilities.Action")
local common = require("mer.theGuarWhisperer.common")
local logger = common.createLogger("main")
require("mer.theGuarWhisperer.interop")


---@param e { foodId: string, convertConfig: GuarWhisperer.ConvertConfig, target: tes3reference }
local function showTameGuarMenu(e)
    local food = tes3.getObject(e.foodId)
    tes3ui.showMessageMenu{
        message = string.format("%s обнюхивает ваш рюкзак. Кажется, он присматривается к %s.", e.target.object.name, food.name),
        buttons = {
            {
                text = string.format("Дайте %s немного %s", e.target.object.name, food.name),
                callback = function()
                    local newAnimal = GuarConverter.convert(e.target, e.convertConfig)
                    if not newAnimal then
                        logger:error("Failed to convert guar")
                        return
                    end
                    --Remove everything from its inventory
                    local items = {}
                    for _, stack in pairs(newAnimal.object.inventory) do
                        table.insert(items, {
                            item = stack.object,
                            count = stack.count or 1
                        })
                    end
                    for _, data in ipairs(items) do
                        tes3.removeItem{
                            reference = newAnimal.reference,
                            item = data.item,
                            count = data.count,
                            playSound = false
                        }
                    end

                    newAnimal.mouth:eatFromInventory(food)
                    timer.start{
                        duration = 1.5,
                        callback = function()
                            if not newAnimal:isValid() then return end
                            newAnimal:rename()
                            timer.delayOneFrame(function()
                                tes3.messageBox{
                                    message = newAnimal:format("{Name} не доверяет вам настолько, чтобы следовать за вами. Попробуйте погладить {his} и дать {him} угощение. \n" ..
                                        "Со временем {his} доверие возрастет и {he} освоит новые навыки, такие как поиск предметов и ношение седельной сумки. \n" ..
                                        "Вы можете управлять своим гуаром на расстоянии, нажав на {Command Key} глядя на н{his}."
                                    ),
                                    buttons = { "Ок" }
                                }
                            end)
                        end
                    }
                end
            },
            {
                text = "Ничего не делать",
                callback = function()
                    local sadAnim = guarConfig.idles.sad
                    tes3.playAnimation{
                        reference = e.target,
                        group = tes3.animationGroup[sadAnim],
                        loopCount = 1,
                        startFlag = tes3.animationStartFlag.immediate
                    }
                    tes3.messageBox("%s издает печальный вой.", e.target.object.name)
                end
            }
        }
    }
end

---@param e { target: tes3reference, activator: tes3reference }
---@return boolean|nil doBlockActivate
local function tryConvert(e)
    if e.target.object.script then
        local obj = e.target.baseObject or e.target.object
        if common.config.mcm.exclusions[obj.id:lower()] then
            logger:trace("Scripted but whitelisted")
        else
            logger:trace("tryConvert(): %s is blacklisted", e.target.object.id)
            return
        end
    end

    if not e.target.mobile then
        logger:trace("tryConvert(): %s does not have an associated mobile", e.target.object.id)
        return
    end

    if common.getIsDead(e.target) then
        logger:trace("tryConvert(): %s is dead", e.target.object.id)
        return
    end

    local convertConfig = GuarConverter.getConvertConfig(e.target)
    if not convertConfig then
        logger:trace("tryConvert(): Failed to get guar data for %s", e.target.object.id)
        return
    end

    local foodId
    local guarType = GuarConverter.getTypeFromConfig(convertConfig)
    for ingredient, _ in pairs(guarType.foodList) do
        if tes3.player.object.inventory:contains(ingredient) then
            foodId = ingredient
            break
        end
    end
    if not foodId then
        logger:trace("tryConvert(): No valid guar food found on player")
        return
    end

    logger:trace("tryConvert(): Food (%s) found, triggering messageBox to tame guar", foodId)
    showTameGuarMenu{
        foodId = foodId,
        convertConfig = convertConfig,
        target = e.target
    }
    return true
end

local function onActivate(e)
    logger:trace("onActivate(): Activating %s", e.target.object.id)
    if not common.getModEnabled() then
        logger:trace("onActivate(): mod is disabled")
        return
    end
    if e.activator ~= tes3.player then
        logger:trace("onActivate(): Player is not activating")
        return
    end
    --check if companion
    local guar = GuarCompanion.get(e.target)
    if guar then
        logger:trace("onActivate(): %s is a guar", e.target.object.id)
        if guar:activate() then return false end
    end

    --Otherwise, checking for a vanilla guar to convert into a companion
    if tryConvert{ target = e.target, activator = e.activator } then return false end
end


local function isAffectedBySpellType(mobile, spellType)
    for _, activeEffect in pairs(mobile.activeMagicEffectList) do
        local instance = activeEffect.instance
        if instance then
            if instance.source.castType == spellType then
                logger:trace("Is affected by spell type")
                return true
            end
        end
    end
end



---@param e uiObjectTooltipEventData
local function onTooltip(e)
    if not common.getModEnabled() then return end
    local guar = GuarCompanion.get(e.reference)
    if guar then
        --Rename
        local label = e.tooltip:findChild(tes3ui.registerID("HelpMenu_name"))
        if guar:getName() then
            local unNamedBaby = (guar.genetics:isBaby() and not guar:getName())
            local prefix = unNamedBaby and "Baby " or ""
            label.text = prefix .. guar:getName()
        end

        if isAffectedBySpellType(guar.reference.mobile, tes3.spellType.blight) then
            label.text = label.text .. (" (Моровый)")
        elseif isAffectedBySpellType(guar.reference.mobile, tes3.spellType.disease) then
            label.text = label.text .. (" (Зараженный)")
        end
        --Add stats
        StatsBlock.new{ parent = e.tooltip, guar = guar, inMenu = false}

        --Add instructions for accessing inventory
        if guar.pack:hasPack() then
            local block = e.tooltip:createBlock{ id = tes3ui.registerID("GuarWhisperer:PackBlock") }
            block.widthProportional = 1.0
            block.autoHeight = true
            block.paddingAllSides = 4
            block.flowDirection = "top_to_bottom"
            block.childAlignX = 0.5
            block.minHeight = 43 --tooltip menu sucks with wrapped text so we hardcode the height here

            --activate keybind
            local activateCode = tes3.getInputBinding(tes3.keybind.activate).code
            local activateKey = common.util.getLetter(activateCode)
            local label = block:createLabel{ id = tes3ui.registerID("GuarWhisperer:PackLabel"),
                text = "Нажмите SHIFT+P чтобы открыть сумку"
            }
            label.text = string.format("Нажмите SHIFT+%s чтобы открыть инвентарь", activateKey)
            label.widthProportional = 1.0
            label.wrapText = true
            label.justifyText = "center"
        end

        --Add overencumbered note
        if guar:isOverEncumbered() then
            local block = e.tooltip:createBlock{ id = tes3ui.registerID("GuarWhisperer:OverEncumberedBlock") }
            block.widthProportional = 1.0
            block.autoHeight = true
            block.paddingAllSides = 4
            block.flowDirection = "top_to_bottom"
            block.childAlignX = 0.5
            local label = block:createLabel{ id = tes3ui.registerID("GuarWhisperer:OverEncumberedLabel") }
            label.text = "Избыточное количество"
            label.color = tes3ui.getPalette("negative_color")
        end
        e.tooltip:updateLayout()
    end
end

local function guarTimer()
    if not common.getModEnabled() then return end
    GuarCompanion.referenceManager:iterateReferences(function(_, guar)
        if guar:isActive() then
            guar.genetics:updateGrowth()
            guar.ai:updateAI()
            guar.ai:updateTravelSpells()
        end
        guar.needs:updateNeeds()
        guar.ai:updateCloseDistance()
    end)
end

---@param guar GuarWhisperer.GuarCompanion
local function findFood(guar)
    ---@param ref tes3reference
    for ref in guar.reference.cell:iterateReferences(tes3.objectType.container) do
        if guar:canEat(ref) then
            if guar:distanceFrom(ref) < 1000 then
                return ref
            end
        end
    end
    ---@param ref tes3reference
    for ref in guar.reference.cell:iterateReferences(tes3.objectType.ingredient) do
        if guar:canEat(ref) then
            if guar:distanceFrom(ref) < 1000 then
                return ref
            end
        end
    end
end

---@param guar GuarWhisperer.GuarCompanion
local function findGreetable(guar)
    ---@param ref tes3reference
    for ref in guar.reference.cell:iterateReferences(tes3.objectType.creature) do
        local isHappyGuar = (
            ref ~= guar.reference and
            guarConfig.greetableGuars[ref.object.mesh:lower()] and
            ref.mobile and ref.mobile.health.current > 5 and
            not ref.mobile.inCombat
        )

        if isHappyGuar then
            if guar:distanceFrom(ref) < 1000 then
                logger:debug("Found Guar '%s' to greet", ref.object.name)
                return ref
            end
        end
    end
    ---@param ref tes3reference
    for ref in guar.reference.cell:iterateReferences(tes3.objectType.npc) do
        local isHappyNPC = (
            ref.mobile and
            not ref.mobile.isDead and
            not ref.mobile.inCombat and
            ref.mobile.fight < 70
        )
        if isHappyNPC then
            if guar:distanceFrom(ref) < 1000 then
                logger:debug("Found NPC '%s' to greet", ref.object.name)
                return ref
            end
        end
    end
end

local lastRef
local function randomActTimer()
    if not common.getModEnabled() then return end
    logger:debug("Random Act Timer")
    local actingRef
    GuarCompanion.referenceManager:iterateReferences(function(_, guar)
        if guar.mobile then
            if guar:isActive() then
                if guar.ai:getAI() == "wandering" then
                    logger:debug("randomActTimer: %s is wandering, deciding action", guar:getName())
                    if guar.reference.id ~= lastRef then
                        actingRef = guar.reference.id
                        --check for food to eat
                        if guar.needs:getHunger() > 20 then
                            logger:debug("randomActTimer: Hunger: %s", guar.needs:getHunger())
                            local food = findFood(guar)
                            if food then
                                logger:debug("randomActTimer: Guar eating")
                                guar.abilities.eat.command{
                                    activeCompanion = guar,
                                    inMenu = false,
                                    targetData = { reference = food }
                                }
                                return false
                            end
                        end
                        --check for other guar
                        local guarRef = findGreetable(guar)
                        if guarRef and math.random(100) < 50 then
                            logger:debug("randomActTimer: Guar greeting")
                            Action.moveToAction{
                                guar = guar,
                                playGroup = "idle6",
                                target = guarRef,
                                activationDistance = 500,
                                actionDuration = 3,
                                afterAction = function()
                                    guar.needs:modPlay(guar.animalType.play.greetValue)
                                    guar.ai:restorePreviousAI()
                                end
                            }
                            return false
                        end
                        if math.random(100) < 20 then
                            logger:debug("randomActTimer: Guar running")
                            guar.reference.mobile.isRunning = true
                        end
                    end
                elseif guar.ai:getAI() == "waiting" then
                    local rand = math.random(100)
                    logger:debug("randomActTimer: rand: %s", rand)
                    for _, data in ipairs(common.config.properties.WAITING_IDLE_CHANCES) do
                        if rand < data.maxChance then
                            logger:debug("randomActTimer: playing random animation %s",data.group)
                            tes3.playAnimation{
                                reference = guar.reference,
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
    --only one guarRef, let him act again
    if actingRef == lastRef then
        lastRef = nil
    else
        --otherwise block him so others can go
        lastRef = actingRef
    end
    timer.start{
        type = timer.simulate,
        iterations = 1,
        duration = math.random(5, 20),
        callback = randomActTimer
    }
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
        duration = math.random(5, 20),
        callback = randomActTimer
    }
end


--Iterate over active guars
local function onDataLoaded()
    commandMenu:destroy()
    --initialiseVisuals()
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
    local guar = GuarCompanion.get(e.reference)
    if guar then
        guar.refData.dead = true
        guar.ai.guar.refData.aiState = nil
        if guar.pack:hasPack() then
            tes3.addItem{
                reference = guar.reference,
                item = common.packId,
                playSound = false
            }
        end
    end
end

--[[
    For guars from an old update, transfer them to new data table
]]
---@param e { reference: tes3reference}
local function convertOldGuar(e)
    if tes3.player
        and tes3.player.data
        and tes3.player.data.theGuarWhisperer
        and tes3.player.data.theGuarWhisperer.companions
        and tes3.player.data.theGuarWhisperer.companions[e.reference.id]
    then
        local data = tes3.player.data.theGuarWhisperer.companions[e.reference.id]
        e.reference.data.tgw = data
        tes3.player.data.theGuarWhisperer.companions[e.reference.id] = nil
    end
    local objectId = e.reference.baseObject.id:lower()
    local legacyConvertConfig = guarConfig.legacyGuarToConvertConfig[objectId]
    if legacyConvertConfig then
        logger:info("Converting legacy %s into new guar object", objectId)
        ---@type GuarWhisperer.ConvertConfig
        legacyConvertConfig = table.copy(legacyConvertConfig)
        legacyConvertConfig.transferInventory = true
        GuarConverter.convert(e.reference, legacyConvertConfig)
    end
end

---@return string
local function getVersion()
    local versionFile = io.open("Data Files/MWSE/mods/mer/theGuarWhisperer/version.txt", "r")
    if not versionFile then return "[VERSION_NOT_FOUND]" end
    local version = ""
    for line in versionFile:lines() do -- Loops over all the lines in an open text file
        version = line
    end
    return version
end

local function initialised()
    if tes3.isModActive("TheGuarWhisperer.ESP") then
        require("mer.theGuarWhisperer.services.AI")
        require("mer.theGuarWhisperer.abilities.fetch")
        require("mer.theGuarWhisperer.merchant")
        require("mer.theGuarWhisperer.CommandMenu.commandMenuController")
        require("mer.theGuarWhisperer.services.Flute")
        event.register("activate", onActivate)
        event.register("uiObjectTooltip", onTooltip)
        event.register("GuarWhispererDataLoaded", onDataLoaded)
        event.register("objectInvalidated", onObjectInvalidated)
        event.register("death", onDeath)
        --event.register("activate", checkDoorTeleport)
        logger:info("%s Initialised", getVersion())
        event.register("loaded", function()
            -- local refs = {}
            -- for _, cell in ipairs(tes3.getActiveCells()) do
            --     for ref in cell:iterateReferences(tes3.objectType.creature) do
            --         table.insert(refs, ref)
            --     end
            -- end
            -- for _, ref in ipairs(refs) do
            --     convertOldGuar{ reference = ref }
            -- end
            for _, guar in ipairs(GuarCompanion.getAll()) do
                common.addToEasyEscortBlacklist(guar.reference.baseObject)
                if guar.reference and guar.reference.mobile then
                    guar.ai:enableCollision()
                end
            end
        end, { priority = 10} )

        event.unregister("mobileActivated", convertOldGuar)
        event.register("mobileActivated", convertOldGuar)
    end
end
event.register("initialized", initialised)
