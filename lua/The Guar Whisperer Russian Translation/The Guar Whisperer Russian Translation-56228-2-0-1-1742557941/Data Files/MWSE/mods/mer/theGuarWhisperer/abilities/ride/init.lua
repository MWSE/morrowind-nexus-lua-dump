local Ability = require("mer.theGuarWhisperer.abilities.Ability")
local GuarCompanion = require("mer.theGuarWhisperer.GuarCompanion")
local Rider = require("mer.theGuarWhisperer.components.Rider")
local common = require("mer.theGuarWhisperer.common")
local logger = common.createLogger("Ride")

local function getCurrentRiddenGuar()
    local ref = Rider.getRefBeingRidden() and tes3.getReference(tes3.player.data.tgw_guarBeingRidden)
    if ref then
        local guar = GuarCompanion.get(ref)
        if guar then
            return guar.rider
        end
    end
end

Ability.register{
    id = "mount",
    label = function(e)
        return "Оседлать"
    end,
    description = "Забраться в седло.",
    command = function(e)
        ---@type GuarWhisperer.GuarCompanion
        local guar = e.activeCompanion
        if guar.ai:attemptCommand(50, 80) then
            guar.rider:mount()
        end
    end,
    requirements = function(e)
        return e.inMenu == true
        and not Rider.getRefBeingRidden()
        and e.activeCompanion.pack:hasPack()
        and e.activeCompanion.needs:hasTrustLevel("Trusting")
        and (not e.activeCompanion.genetics:isBaby())
    end,
}

Ability.register{
    id = "dismount",
    label = function(e)
        return "Спешиться"
    end,
    description = "Спешиться с Гуара",
    command = function(e)
        e.activeCompanion.rider:dismount()
    end,
    requirements = function(e)
        return Rider.getRefBeingRidden() == e.activeCompanion.reference
    end,
}

Ability.register{
    id = "showRidingInstructions",
    label = function() return "Инструктаж по верховой езде" end,
    description = "Показать инструкцию по верховой езде.",
    command = Rider.showMountInstructions,
    requirements = function(e)
        return Rider.getRefBeingRidden() == e.activeCompanion.reference
    end
}

local function isKeybindPressed(keybind)
    --Get inputs and move guar
    local inputController = tes3.worldController.inputController
    local code = tes3.getInputBinding(keybind).code
    return inputController:isKeyDown(code)
end



event.register("simulated", function(e)
    if tes3ui.menuMode() then return end
    if not tes3.player then return end
    local rider = getCurrentRiddenGuar()
    if not rider then return end
    rider:updatePlayerPosition()
end)

event.register("simulate", function(e)
    local rider = getCurrentRiddenGuar()
    if not rider then return end
    if not rider.guar:isValid() then
        rider:cancel()
        return
    end

    --Teleport the guar to the player after the player teleports to an exterior cell
    local inDifferentCells = rider.guar.reference.cell ~= tes3.player.cell
    if inDifferentCells and not tes3.player.cell.isInterior then
        local tooFar = rider.guar.reference.position:distance(tes3.player.position) > 1000
        if tooFar then
            logger:debug("Player has teleported too far away, teleporting to player")
            rider.guar.ai:teleportToPlayer(400)
            return
        end
    end
    rider:updateIsRunning()
    local forwardPressed = isKeybindPressed(tes3.keybind.forward)
    if forwardPressed and not rider:isMovingForward() then
        logger:debug("move forward")
        rider:moveForward()
    end

    local leftPressed = isKeybindPressed(tes3.keybind.left)
    if leftPressed then
        logger:debug("Rotating left")
        rider:turnLeft()
    end

    local rightPressed = isKeybindPressed(tes3.keybind.right)
    if rightPressed then
        logger:debug("Rotating right")
        rider:turnRight()
    end
end)

---@param e activateEventData
event.register("activate", function(e)
    if e.target.baseObject.objectType == tes3.objectType.door then
        local rider = getCurrentRiddenGuar()
        if not rider then return end
        rider:cancel()
    end
end)

event.register("keyDown", function(e)
    if tes3ui.menuMode() then return end
    if not tes3.player then return end
    local rider = getCurrentRiddenGuar()
    if not rider then return end

    local forwardPressed = e.keyCode == tes3.getInputBinding(tes3.keybind.forward).code
    if forwardPressed then
        logger:debug("Starting to move forward")
        rider:moveForward()
    end

    local backwardPressed = e.keyCode == tes3.getInputBinding(tes3.keybind.back).code
    if backwardPressed then
        --only when guar and player are out of combat
        local playerInCombat = tes3.mobilePlayer.inCombat
        local guarInCombat = rider.guar.reference.mobile.inCombat
        if not (playerInCombat or guarInCombat) then
            logger:debug("Stopping forward movement")
            rider:halt()
        end
    end

end)

---@param e keybindTestedEventData
event.register("keybindTested", function(e)
    if tes3ui.menuMode() then return end
    if e.keybind == tes3.keybind.sneak and e.result == true then
        local rider = getCurrentRiddenGuar()
        if rider then
            logger:debug("Sneak button pressed dismounting")
            --rider:dismount()
            rider:crouch(0)
            return false
        end
    end
end)

---@param e damageEventData
event.register("damage", function(e)
    local fromPlayer = e.attacker == tes3.mobilePlayer
    local hitRidingGUuar = e.reference == Rider.getRefBeingRidden()
    ---prevent hitting guar when riding
    if fromPlayer and hitRidingGUuar then
        logger:debug("Hit guar while riding, preventing damage")
        e.damage = 0
    end
end)

event.register("loaded", function()
    if Rider.getRefBeingRidden() then
        Rider.lockPlayer()
    end
end)