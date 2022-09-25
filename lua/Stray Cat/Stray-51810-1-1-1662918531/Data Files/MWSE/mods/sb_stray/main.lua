local interop = require("sb_stray/interop")
local mcm = require("sb_stray/mcm")

mcm.init()

--- @param e equippedEventData
local function equippedCallback(e)
    if (e.reference == tes3.player and e.item.id == interop.item) then
        tes3.player.scale = 0.25
        tes3.player1stPerson.scale = 0.25
        timer.delayOneFrame(function()
            for _, child in ipairs(tes3.player.sceneNode.children) do
                child.appCulled = true
            end
            for _, child in ipairs(tes3.player1stPerson.sceneNode.children) do
                child.appCulled = true
            end
        end)
        tes3.mobilePlayer.cameraHeight = tes3.mobilePlayer.cameraHeight * (0.25 * 0.75)
        tes3.findGMST(tes3.gmst.fSwimHeightScale).value = tes3.findGMST(tes3.gmst.fSwimHeightScale).defaultValue *
            (0.25 * 0.75)

        if (interop.cat) then
            interop.cat:enable()
        else
            interop.cat = tes3.createReference {
                object = interop.raceBreedAssociation[tes3.player.object.race.name] or
                    interop.raceBreedAssociation["Imperial"],
                position = tes3.player.position,
                orientation = tes3.player.orientation,
                cell = tes3.player.cell
            }

            local hatMesh = tes3.loadMesh("a\\a_helm_colovian.nif")
            if hatMesh then
                hatMesh = hatMesh:clone()
                hatMesh.name = "hatNode"

                hatMesh.translation = interop.cat.sceneNode:getObjectByName("Bone09").translation +
                    tes3vector3.new(-2, -2, 0)
                hatMesh.scale = interop.cat.sceneNode.scale * interop.cat.sceneNode:getObjectByName("Bone09").scale * 0.5

                hatMesh.rotation = tes3matrix33.new()
                hatMesh.rotation:fromEulerXYZ(-90 / 180 * 3.14, 35 / 180 * 3.14, 90 / 180 * 3.14)

                interop.cat.sceneNode:getObjectByName("Bone09"):attachChild(hatMesh, true)
            end
        end
        interop.cat:setNoCollisionFlag(true, true)
        interop.cat.mobile.mobToMobCollision = false
        interop.cat.mobile.movementCollision = false
        interop.cat.mobile.isAffectedByGravity = false
        tes3.dataHandler:updateCollisionGroupsForActiveCells { force = true, isResettingData = true,
            resetCollisionGroups = true }
    end
end

--- @param e unequippedEventData
local function unequippedCallback(e)
    if (e.reference == tes3.player and e.item.id == interop.item) then
        tes3.player.scale = 1.0
        tes3.player1stPerson.scale = 1.0
        timer.delayOneFrame(function()
            for _, child in ipairs(tes3.player.sceneNode.children) do
                child.appCulled = false
            end
            for _, child in ipairs(tes3.player1stPerson.sceneNode.children) do
                child.appCulled = false
            end
        end)
        tes3.mobilePlayer.cameraHeight = nil
        tes3.findGMST(tes3.gmst.fSwimHeightScale).value = tes3.findGMST(tes3.gmst.fSwimHeightScale).defaultValue

        if (interop.cat) then
            interop.cat:disable()
        end
    end
end

--- @param e calcWalkSpeedEventData
local function calcWalkSpeedCallback(e)
    if (e.reference == tes3.player) then
        if (interop.cat and interop.cat.disabled == false) then
            e.speed = e.speed / 0.25
        end
    end
end

--- @param e damageEventData
local function damageCallback(e)
    if (e.reference == tes3.player and e.source == tes3.damageSource.fall) then
        if (interop.cat and interop.cat.disabled == false) then
            e.damage = e.damage * 0.25
        end
    end
end

--- @param e jumpEventData
local function jumpCallback(e)
    if (e.reference == tes3.player) then
        if (interop.cat and interop.cat.disabled == false) then
            e.velocity.x = e.velocity.x / 0.75
            e.velocity.y = e.velocity.y / 0.75
            e.velocity.z = e.velocity.z / 0.75
        end
    end
end

--- @param e playGroupEventData
local function playGroupCallback(e)
    if (
        interop.cat and interop.cat.disabled == false and
            (e.reference == tes3.player or e.reference == tes3.player1stPerson)) then
        local catGroup = e.group
        if (e.group == tes3.animationGroup.idleSneak) then
            catGroup = tes3.animationGroup.idle8
        elseif (
            e.group == tes3.animationGroup.idle1h or e.group == tes3.animationGroup.idle2c or
                e.group == tes3.animationGroup.idle2w or e.group == tes3.animationGroup.idleCrossbow or
                e.group == tes3.animationGroup.idleHandToHand or e.group == tes3.animationGroup.idleSpell) then
            catGroup = tes3.animationGroup.idle2
        elseif (
            -- walk
            e.group == tes3.animationGroup.walkForward1h or e.group == tes3.animationGroup.walkForward2c or
                e.group == tes3.animationGroup.walkForward2w or e.group == tes3.animationGroup.walkForwardHandToHand or
                e.group == tes3.animationGroup.swimWalkForward or

                e.group == tes3.animationGroup.walkBack or
                e.group == tes3.animationGroup.walkBack1h or e.group == tes3.animationGroup.walkBack2c or
                e.group == tes3.animationGroup.walkBack2w or e.group == tes3.animationGroup.walkBackHandToHand or
                e.group == tes3.animationGroup.swimWalkBack or

                e.group == tes3.animationGroup.walkLeft or
                e.group == tes3.animationGroup.walkLeft1h or e.group == tes3.animationGroup.walkLeft2c or
                e.group == tes3.animationGroup.walkLeft2w or e.group == tes3.animationGroup.walkLeftHandToHand or
                e.group == tes3.animationGroup.swimWalkLeft or

                e.group == tes3.animationGroup.walkRight or
                e.group == tes3.animationGroup.walkRight1h or e.group == tes3.animationGroup.walkRight2c or
                e.group == tes3.animationGroup.walkRight2w or e.group == tes3.animationGroup.walkRightHandToHand or
                e.group == tes3.animationGroup.swimWalkRight or

                -- sneak
                e.group == tes3.animationGroup.sneakForward or e.group == tes3.animationGroup.sneakForward2c or
                e.group == tes3.animationGroup.sneakForward2w or e.group == tes3.animationGroup.sneakForwardHandToHand or
                e.group == tes3.animationGroup.swimSneakForward or

                e.group == tes3.animationGroup.sneakBack or
                e.group == tes3.animationGroup.sneakBack1h or e.group == tes3.animationGroup.sneakBack2c or
                e.group == tes3.animationGroup.sneakBack2w or e.group == tes3.animationGroup.sneakBackHandToHand or
                e.group == tes3.animationGroup.swimSneakBack or

                e.group == tes3.animationGroup.sneakLeft or
                e.group == tes3.animationGroup.sneakLeft1h or e.group == tes3.animationGroup.sneakLeft2c or
                e.group == tes3.animationGroup.sneakLeft2w or e.group == tes3.animationGroup.sneakLeftHandToHand or
                e.group == tes3.animationGroup.swimSneakLeft or

                e.group == tes3.animationGroup.sneakRight or
                e.group == tes3.animationGroup.sneakRight1h or e.group == tes3.animationGroup.sneakRight2c or
                e.group == tes3.animationGroup.sneakRight2w or e.group == tes3.animationGroup.sneakRightHandToHand or
                e.group == tes3.animationGroup.swimSneakRight) then
            catGroup = tes3.animationGroup.walkForward
        elseif (
            -- run
            e.group == tes3.animationGroup.runForward or e.group == tes3.animationGroup.runForward2c or
                e.group == tes3.animationGroup.runForward2w or e.group == tes3.animationGroup.runForwardHandToHand or
                e.group == tes3.animationGroup.swimRunForward or

                e.group == tes3.animationGroup.runBack or
                e.group == tes3.animationGroup.runBack1h or e.group == tes3.animationGroup.runBack2c or
                e.group == tes3.animationGroup.runBack2w or e.group == tes3.animationGroup.runBackHandToHand or
                e.group == tes3.animationGroup.swimRunBack or

                e.group == tes3.animationGroup.runLeft or
                e.group == tes3.animationGroup.runLeft1h or e.group == tes3.animationGroup.runLeft2c or
                e.group == tes3.animationGroup.runLeft2w or e.group == tes3.animationGroup.runLeftHandToHand or
                e.group == tes3.animationGroup.swimRunLeft or

                e.group == tes3.animationGroup.runRight or
                e.group == tes3.animationGroup.runRight1h or e.group == tes3.animationGroup.runRight2c or
                e.group == tes3.animationGroup.runRight2w or e.group == tes3.animationGroup.runRightHandToHand or
                e.group == tes3.animationGroup.swimRunRight) then
            catGroup = tes3.animationGroup.runForward
        elseif (e.group == tes3.animationGroup.swimAttack1 or e.group == tes3.animationGroup.weaponOneHand) then
            catGroup = tes3.animationGroup.attack1
        elseif (e.group == tes3.animationGroup.swimAttack2 or e.group == tes3.animationGroup.weaponTwoHand) then
            catGroup = tes3.animationGroup.attack2
        elseif (e.group == tes3.animationGroup.swimAttack3 or e.group == tes3.animationGroup.weaponTwoWide) then
            catGroup = tes3.animationGroup.attack3
        elseif (
            e.group == tes3.animationGroup.bowAndArrow or e.group == tes3.animationGroup.crossbow or
                e.group == tes3.animationGroup.weaponTwoHand or e.group == tes3.animationGroup.handToHand) then
            catGroup = tes3.animationGroup.attack1
        elseif (
            e.group == tes3.animationGroup.death2 or e.group == tes3.animationGroup.death3 or
                e.group == tes3.animationGroup.death4 or e.group == tes3.animationGroup.death5 or
                e.group == tes3.animationGroup.swimDeath or e.group == tes3.animationGroup.swimDeath2 or
                e.group == tes3.animationGroup.swimDeath3 or e.group == tes3.animationGroup.deathKnockOut or
                e.group == tes3.animationGroup.swimDeathKnockOut or e.group == tes3.animationGroup.knockOut or
                e.group == tes3.animationGroup.swimKnockOut) then
            catGroup = tes3.animationGroup.death1
        elseif (
            e.group == tes3.animationGroup.deathKnockDown or e.group == tes3.animationGroup.swimDeathKnockDown or
                e.group == tes3.animationGroup.knockDown or e.group == tes3.animationGroup.swimKnockDown) then
            catGroup = tes3.animationGroup.idle5
        elseif (
            e.group == tes3.animationGroup.hit2 or e.group == tes3.animationGroup.hit3 or
                e.group == tes3.animationGroup.hit4 or e.group == tes3.animationGroup.hit5 or
                e.group == tes3.animationGroup.swimHit1 or e.group == tes3.animationGroup.swimHit2 or
                e.group == tes3.animationGroup.swimHit3) then
            catGroup = tes3.animationGroup.hit1
        elseif (
            e.group == tes3.animationGroup.jump or e.group == tes3.animationGroup.jump1h or
                e.group == tes3.animationGroup.jump2c or e.group == tes3.animationGroup.jump2w or
                e.group == tes3.animationGroup.jumpHandToHand) then
            catGroup = tes3.animationGroup.runForward
        end

        tes3.playAnimation {
            reference = interop.cat,
            group = catGroup,
            startFlag = e.flags,
            loopCount = e.loopCount
        }
        -- interop.cat.mobile.animationController.speedMultiplier = 1.0 / (0.25 ^ 2.0)
        interop.cat.sceneNode:update {
            controllers = true
        }
    end
end

--- @param e uiObjectTooltipEventData
local function uiObjectTooltipCallback(e)
    if (interop.cat and e.tooltip:findChild("HelpMenu_name").text == interop.cat.id) then
        e.tooltip.maxWidth = 0
        e.tooltip.maxHeight = 0
    end
end

--- @param e magicCastedEventData
local function magicCastedCallback(e)
    if (e.caster == tes3.player and e.source.id == interop.spell) then
        tes3.playSound { reference = interop.cat, loop = true, sound = "catpurr" }
    end

    if (e.caster == tes3.player) then
        for _, effect in ipairs(e.source.effects) do
            if (effect.id == tes3.effect.blind) then
                local hatNode = interop.cat.sceneNode:getObjectByName("hatNode")

                hatNode.translation = interop.cat.sceneNode:getObjectByName("Bone09").translation +
                    tes3vector3.new(2, 0, 0)
                hatNode.rotation = tes3matrix33.new()
                hatNode.rotation:fromEulerXYZ(-90 / 180 * 3.14, -50 / 180 * 3.14, 90 / 180 * 3.14)
            end
        end
    end
end

--- @param e magicEffectRemovedEventData
local function magicEffectRemovedCallback(e)
    if (e.caster == tes3.player and e.source.id == interop.spell) then
        tes3.removeSound { reference = interop.cat, sound = "catpurr" }
    end

    if (e.caster == tes3.player and e.effect.id == tes3.effect.blind) then
        local hatNode = interop.cat.sceneNode:getObjectByName("hatNode")

        hatNode.translation = interop.cat.sceneNode:getObjectByName("Bone09").translation + tes3vector3.new(-2, -2, 0)
        hatNode.rotation = tes3matrix33.new()
        hatNode.rotation:fromEulerXYZ(-90 / 180 * 3.14, 35 / 180 * 3.14, 90 / 180 * 3.14)
    end
end

--- @param e addSoundEventData
local function addSoundCallback(e)
    if (e.reference == tes3.player and interop.cat and interop.cat.disabled == false) then
        return false
    end
end

--- @param e simulateEventData
local function simulateCallback(e)
    if (interop.cat) then
        if (interop.cat.disabled == false) then
            if (interop.cat.cell ~= tes3.player.cell) then
                tes3.positionCell {
                    reference = interop.cat,
                    cell = tes3.player.cell,
                    position = tes3.player.position,
                    orientation = tes3.player.orientation
                }
                interop.cat:setNoCollisionFlag(true, true)
                interop.cat.mobile.mobToMobCollision = false
                interop.cat.mobile.movementCollision = false
                interop.cat.mobile.isAffectedByGravity = false
                tes3.dataHandler:updateCollisionGroupsForActiveCells { force = true, isResettingData = true,
                    resetCollisionGroups = true }
            end
            interop.cat.position = tes3.player.position
            interop.cat.orientation = tes3.player.orientation

            if (tes3.is3rdPerson()) then
                interop.cat.sceneNode.appCulled = false
            else
                interop.cat.sceneNode.appCulled = true
            end

            timer.delayOneFrame(function()
                for _, child in ipairs(tes3.player.sceneNode.children) do
                    child.appCulled = true
                end
                for _, child in ipairs(tes3.player1stPerson.sceneNode.children) do
                    child.appCulled = true
                end
            end)
        end

        if (interop.cat.disabled == false and tes3.player.object.spells:contains(interop.spell) == false) then
            tes3.addSpell { reference = tes3.player, spell = interop.spell }
        elseif (interop.cat.disabled and tes3.player.object.spells:contains(interop.spell)) then
            tes3.removeSpell { reference = tes3.player, spell = interop.spell }
        end

        if (
            interop.cat.sceneNode:getObjectByName("hatNode").appCulled and
                tes3.player.object:hasItemEquipped("fur_colovian_helm")) then
            interop.cat.sceneNode:getObjectByName("hatNode").appCulled = false
        elseif (
            interop.cat.sceneNode:getObjectByName("hatNode").appCulled == false and
                tes3.player.object:hasItemEquipped("fur_colovian_helm") == false) then
            interop.cat.sceneNode:getObjectByName("hatNode").appCulled = true
        end
    end
end

--- @param e loadedEventData
local function loadedCallback(e)
    interop.cat = tes3.getReference(interop.raceBreedAssociation[tes3.player.object.race.name] or
        interop.raceBreedAssociation["Imperial"])
    if (interop.cat and interop.cat.disabled == false) then
        tes3.player.scale = 0.25
        tes3.player1stPerson.scale = 0.25
        timer.delayOneFrame(function()
            for _, child in ipairs(tes3.player.sceneNode.children) do
                child.appCulled = true
            end
            for _, child in ipairs(tes3.player1stPerson.sceneNode.children) do
                child.appCulled = true
            end
        end)
        tes3.mobilePlayer.cameraHeight = tes3.mobilePlayer.cameraHeight * (0.25 * 0.75)
        tes3.worldController.worldCamera.camera.translation.z = tes3.player.object.height * 0.25
        tes3.findGMST(tes3.gmst.fSwimHeightScale).value = tes3.findGMST(tes3.gmst.fSwimHeightScale).defaultValue *
            (0.25 * 0.75)

        interop.cat:setNoCollisionFlag(true, true)
        interop.cat.mobile.mobToMobCollision = false
        interop.cat.mobile.movementCollision = false
        interop.cat.mobile.isAffectedByGravity = false
        tes3.dataHandler:updateCollisionGroupsForActiveCells { force = true, isResettingData = true,
            resetCollisionGroups = true }
    end
end

--- @param e initializedEventData
local function initializedCallback(e)
    event.register(tes3.event.equipped, equippedCallback)
    event.register(tes3.event.unequipped, unequippedCallback)
    event.register(tes3.event.calcWalkSpeed, calcWalkSpeedCallback)
    event.register(tes3.event.damage, damageCallback)
    event.register(tes3.event.jump, jumpCallback)
    event.register(tes3.event.playGroup, playGroupCallback)
    event.register(tes3.event.uiObjectTooltip, uiObjectTooltipCallback)
    event.register(tes3.event.magicCasted, magicCastedCallback)
    event.register(tes3.event.magicEffectRemoved, magicEffectRemovedCallback)
    event.register(tes3.event.addSound, addSoundCallback)
    event.register(tes3.event.simulate, simulateCallback)
    event.register(tes3.event.loaded, loadedCallback)
end

event.register(tes3.event.initialized, initializedCallback)
