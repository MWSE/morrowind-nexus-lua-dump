--[[

    This script handles nice-to-haves such as auto-teleporting and position fixing

]]
local animalController = require("mer.theGuarWhisperer.animalController")
local common = require("mer.theGuarWhisperer.common")

--Teleport to player when going back outside
local function checkCellChanged(e)
    if e.previousCell and e.previousCell.isInterior and not e.cell.isInterior then
        common.iterateRefType("companion", function(ref)
            local animal = animalController.getAnimal(ref)
            local doTeleport = (
                animal and 
                animal:getAI() == "following" and
                not animal:isDead() and
                animal.reference.position:distance(tes3.player.position) > common.getConfig().teleportDistance
            )
            if doTeleport then
                common.log:debug("Cell change teleport")
                animal:teleportToPlayer(500)
            end
        end)
    end
end

event.register("cellChanged", checkCellChanged )


--[[
    0 = stay still
    3 = attack
    7 = flee
]]

local function onDeterminedAction(e)
    local animal = animalController.getAnimal(e.session.mobile.reference)
    if animal then
        common.log:debug("Session action: %s", e.session.selectedAction)
        if e.session.selectedAlchemy ~= nil then
            --Block potions based on potion policy
            local policy = animal:getPotionPolicy()
            if policy == "none" or true then--block all potions until a better method
                common.log:debug("%s blocking potion %s", animal.refData.name, e.session.selectedAlchemy.object.id)
                e.session.selectedAction = 2
            end
        end
    end
end
event.register("determinedAction", onDeterminedAction)


local function onDetermineAction(e)
    local animal = animalController.getAnimal(e.session.mobile.reference)
    if animal then
        if e.session.selectedAlchemy ~= nil then
            --Block potions based on potion policy
            local policy = animal:getPotionPolicy()
            if policy == "healthOnly" then
                local potion = e.session.selectedAlchemy.object
                if potion.effects then
                    for _, effect in ipairs(potion.effects) do
                        if effect.id == tes3.effect.restoreHealth then
                            common.log:debug("Setting potion to healthy")
                            e.session:selectAlchemyWithEffect(tes3.effect.restoreHealth)
                            return
                        end
                    end
                end
            end
        end
    end
end

event.register("determineAction", onDetermineAction)


local function onSpellCast(e)
    common.log:trace("%s %s", e.source.name, e.caster.object.name )
end
event.register("spellCast", onSpellCast)


-- local function onAttack(e)
--     local animal = animalController.getAnimal(e.reference)
--     if animal then
--         common.log:debug("%s is attacking", animal:getName())
--     end
-- end

-- event.register("attack", onAttack)


-- --Allow exiting companion share menu like other menus
-- local function onMouseButtonDown(e)
--     if e.button == tes3.worldController.inputController.inputMaps[19].code then
--         local contentsMenu = tes3ui.findMenu(tes3ui.registerID("MenuContents"))
--         if contentsMenu then
--             local closeButton = contentsMenu:findChild(tes3ui.registerID("MenuContents_closebutton"))
--             if closeButton then
--                 tes3.worldController.menuClickSound:play()
--                 closeButton:triggerEvent("mouseClick")
--             end
--         end
--     end
-- end
-- event.register("mouseButtonDown", onMouseButtonDown)


local function onEquip(e)
    local animal = animalController.getAnimal(e.reference)
    if animal then  
        common.log:debug("no guar, don't equip anything please")
        return false
    end
end
event.register("equip", onEquip)