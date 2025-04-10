local common = require("mer.theGuarWhisperer.common")
local logger = common.createLogger("AI")
local guarConfig = require("mer.theGuarWhisperer.guarConfig")
Rider = require("mer.theGuarWhisperer.components.Rider")
local Charm = require("mer.theGuarWhisperer.abilities.charm")

---@class GuarWhisperer.AI.GuarCompanion.refData
---@field aiState GuarWhisperer.GuarCompanion.AIState @Current AI state
---@field previousAiState GuarWhisperer.GuarCompanion.AIState @Previous AI state
---@field aiBroken number @Number of times the AI has broken
---@field stuckStrikes number @Number of times the AI has been stuck
---@field lastStuckPosition {x:number, y:number, z:number} @Position where the AI got stuck
---@field isRiding boolean @True while the player is riding this guar


---@class GuarWhisperer.AI.GuarCompanion : GuarWhisperer.GuarCompanion
---@field refData GuarWhisperer.AI.GuarCompanion.refData

---@class GuarWhisperer.AI
---@field guar GuarWhisperer.AI.GuarCompanion
local AI = {}

---@param guar GuarWhisperer.AI.GuarCompanion
function AI.new(guar)
    local self = setmetatable({}, { __index = AI })
    self.guar = guar
    return self
end

--- Play an animation
---@param emotionType GuarWhisperer.Emotion
---@param doWait any
function AI:playAnimation(emotionType, doWait)
    local groupId = guarConfig.idles[emotionType]
    if tes3.animationGroup[groupId] ~= nil then
        logger:debug("playing %s, wait: %s", groupId, doWait)
        tes3.playAnimation{
            reference = self.guar.reference,
            group = tes3.animationGroup[groupId],
            loopCount = 0,
            startFlag = doWait and tes3.animationStartFlag.normal or tes3.animationStartFlag.immediate
        }
    end
end

--- Set the AI State
---@param aiState GuarWhisperer.GuarCompanion.AIState
function AI:setAI(aiState)
    logger:debug("Setting AI to %s", aiState)
    aiState = aiState or "waiting"
    self.guar.refData.aiState = aiState
    local states ={
        following = self.returnTo,
        waiting = self.wait,
        wandering = self.wander,
        moving = self.wait,
    }
    local callback = states[aiState]
    if callback then callback(self) end
end

--- Get the current AI state
---@return GuarWhisperer.GuarCompanion.AIState
function AI:getAI()
    return self.guar.refData.aiState or "waiting"
end

--- Restore the previous AI state
function AI:restorePreviousAI()
    if self.guar.refData.previousAiState then
        logger:debug("Restoring AI state to %s", self.guar.refData.previousAiState)
        self:setAI(self.guar.refData.previousAiState)
    end
    self.guar.refData.previousAiState = nil
end

---@param state? GuarWhisperer.GuarCompanion.AIState
function AI:setPreviousAIState(state)
    self.guar.refData.previousAiState = state or self:getAI()
end

--- Teleport if too far away while following
function AI:closeTheDistanceTeleport()
    if self.guar:isOverEncumbered() then
        tes3.messageBox(self.guar:format("{Name} перегружен."))
        self:wait()
        return
    end

    if tes3.player.cell.isInterior then
        logger:debug("No teleport: player is in interior")
        return
    elseif self:getAI() ~= "following" then
        return
    elseif self.guar:isDead() then
        return
    end
    local doTeleportBehind
    if Rider.getRefBeingRidden() then
        doTeleportBehind = true
    else
        doTeleportBehind = (
            tes3.mobilePlayer.isMovingForward or
            tes3.mobilePlayer.isMovingLeft or
            tes3.mobilePlayer.isMovingRight
        )
    end
    local distance = doTeleportBehind and -400 or 400
    logger:debug("Closing the distance teleport")
    self:teleportToPlayer(distance)
end

--- Teleport to the player
---@param distance number? @Distance in front (positive) or behind (negative) the player
function AI:teleportToPlayer(distance)
    if tes3.player.cell.isInterior then
        logger:debug("No teleport: player is in interior")
        return
    end

    distance = distance or 400

    local ridingRef = Rider.getRefBeingRidden()
    local eyeVec
    if ridingRef then
        logger:debug("Teleporting to player while riding using riding ref orientation of %s", ridingRef.orientation.z)
        eyeVec = ridingRef.forwardDirection
    else
        logger:debug("Teleporting to player while not riding using player orientation of %s", tes3.player.orientation.z)
        eyeVec = tes3.player.forwardDirection
    end

    local position = tes3.getPlayerEyePosition()
    local isForward = distance >= 0
    local direction = eyeVec * (isForward and 1 or -1)

    logger:debug("teleportToPlayer(): Distance: %s", distance)
    --do a raytest to avoid teleporting into stuff
    ---@type niPickRecord
    local rayResult = tes3.rayTest{
        position = position,
        direction = direction,
        maxDistance = math.abs(distance),
        ignore = {tes3.player, self.guar.reference, self.guar.rider:getRefBeingRidden()}
    }
    if rayResult and rayResult.intersection then
        distance = math.min(distance, rayResult.distance)
        logger:debug("Hit %s, new distance: %s",
            rayResult.reference or rayResult.object,
            distance)
    end

    local ref = ridingRef or tes3.player
    local newPosition = tes3vector3.new(
        tes3.player.position.x + ( distance * math.sin(ref.orientation.z)),
        tes3.player.position.y + ( distance * math.cos(ref.orientation.z)),
        tes3.player.position.z
    )

    --Drop to ground
    if not tes3.isAffectedBy{ reference = self.guar.reference, effect = tes3.effect.levitate } then
        local upDownResult = tes3.rayTest{
            position = newPosition,
            direction = tes3vector3.new(0, 0, -1),
            maxDistance = 10000,
            ignore = {tes3.player, self.guar.reference}
        }
        --no down result, try up result
        if not (upDownResult and upDownResult.intersection) then
            upDownResult = tes3.rayTest{
                position = newPosition,
                direction = tes3vector3.new(0, 0, 1),
                maxDistance = 10000,
                ignore = {tes3.player, self.guar.reference},
                useBackTriangles = true
            }
        end

        if upDownResult and upDownResult.intersection then
            local newZ

            local oldPosition = upDownResult.intersection

            --check we crossed the water level if passed 0 z
            local crossedWaterLevel = oldPosition.z > 0 and newPosition.z < 0
                or oldPosition.z < 0 and newPosition.z > 0
            if crossedWaterLevel then
                newZ = 0
            else
                local vertDist = upDownResult.intersection.z - newPosition.z
                newZ = newPosition.z + vertDist
            end
            logger:debug("Setting Z position from %s to %s", newPosition.z, newZ)
            newPosition = tes3vector3.new(newPosition.x, newPosition.y, newZ)
        else
            logger:warn("failed to find ground below player")
        end
    end

    local wasFollowing
    if self:getAI() == "following" then
        wasFollowing = true
        self:wait()
    end
    tes3.positionCell{
        reference = self.guar.reference,
        position = newPosition,
        cell = tes3.player.cell
    }
    self.guar.reference.sceneNode:update()
    self.guar.reference.sceneNode:updateEffects()
    if wasFollowing then
        self:follow()
    end
end

--- Stay still
function AI:wait(idles)
    if not self.guar.reference.mobile then return end
    self.guar.refData.aiState = "waiting"
    logger:debug("Waiting")
    tes3.setAIWander{
        reference = self.guar.reference,
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
        duration = 2,
    }
end

--- Wander around
---@param range number? Default: 500
function AI:wander(range)
    if not self.guar.reference.mobile then return end
    logger:debug("Wandering")
    self.guar.refData.aiState = "wandering"
    range = range or 500
    tes3.setAIWander{
        reference = self.guar.reference,
        range = range,
        idles = {
            42, --sit
            05, --eat
            52, --look
            01, --wiggle
            0, --n/a
            0, --n/a
            0, --n/a
            0
        }
    }
end


--- Follow the player
---@param target tes3reference?
function AI:follow(target)
    target = target or tes3.player
    logger:debug("Setting AI Follow")
    self:playAnimation("idle")
    self.guar.refData.aiState = "following"
    tes3.setAIFollow{ reference = self.guar.reference, target = target }
end

--- Attack the target
function AI:attack(target, blockMessage)
    logger:debug("Attacking %s", target.object.name)

    if blockMessage ~= true then
        tes3.messageBox(self.guar:format("{Name} атакует %s",  target.object.name))
    end
    self.guar.refData.previousAiState = self:getAI()
    self:follow()
    local safeTargetRef = tes3.makeSafeObjectHandle(target)
    timer.start{
        duration = 0.5,
        callback = function()
            if not (safeTargetRef and safeTargetRef:valid()) then return end
            if not self.guar:isValid() then return end
            if not target.mobile then return end
            self.guar.reference.mobile:startCombat(target.mobile)
            self.guar.refData.aiState = "attacking"
        end
    }
end


--- Move to the given position
function AI:moveTo(position)
    logger:debug("Moving to %s", position)
    tes3.playAnimation({
        reference = self.guar.reference,
        group = tes3.animationGroup.wait,
        startFlag = tes3.animationStartFlag.immediate,
    })
    tes3.setAITravel{ reference = self.guar.reference, destination = position }
    self.guar.refData.aiState = "moving"
end

--- Return to the player
function AI:returnTo()
    self:follow()
    self.guar.aiFixer:resetFollow()
end

function AI:disableCollision()
    self.guar.reference.mobile.mobToMobCollision = false
    self.guar.reference.mobile.movementCollision = false
end

function AI:enableCollision()
    self.guar.reference.mobile.mobToMobCollision = true
    self.guar.reference.mobile.movementCollision = true
end


function AI:collisionFix()
    self:disableCollision()
    timer.start{
        duration = 0.5,
        callback = function()
            if not self.guar:isValid() then return end
            self:enableCollision()
        end
    }
end

--keep ai in sync
function AI:updateAI()
    if not self.guar:isActive() then return end

    local aiState = self:getAI()
    local packageId = tes3.getCurrentAIPackageId{ reference = self.guar.reference }
    local brokenLimit = 2
    self.guar.refData.aiBroken = self.guar.refData.aiBroken or 0

    local exceededBrokenLimit = self.guar.refData.aiBroken > brokenLimit
    local hasSceneNode = self.guar.reference.sceneNode ~= nil
    local invalidPackageId = packageId == nil or packageId == -1
    if (not exceededBrokenLimit) and hasSceneNode and invalidPackageId then
        logger:debug("AI Fix: Detected broken AI package")
        self.guar.refData.aiBroken = self.guar.refData.aiBroken + 1
    end

    if exceededBrokenLimit then
        logger:warn("AI Fix: still broken, using mwse.memory fix")
        --Magic mwse.memory call to fix guars wandering off
        ---@diagnostic disable: undefined-field
        mwse.memory.writeByte({
            address = mwse.memory.convertFrom.tes3mobileObject(self.guar.reference.mobile) + 0xC0,
            byte = 0x00,
        })
        ---@diagnostic enable: undefined-field
        self.guar.refData.aiBroken = 0
    end

    --set correct ai package
    if aiState == "following" then
        if packageId ~= tes3.aiPackage.follow then
            logger:debug("Current AI package: %s", table.find(tes3.aiPackage, packageId) or packageId)
            logger:debug("%s Restoring following AI", self.guar:getName())
            self:returnTo()
        end
    elseif aiState == "waiting" or aiState == "wandering" then
        if packageId ~= tes3.aiPackage.wander then
            logger:debug("Current AI package: %s", table.find(tes3.aiPackage, packageId) or packageId)
            logger:debug("%s Restoring %s AI", self.guar:getName(), aiState)
            self:setAI(aiState)
        end
        if aiState == "waiting" and self.guar.rider:isRiding() then
            self:follow()
        end
    elseif aiState == "attacking" then
        if self.guar.reference.mobile.inCombat ~= true then
            logger:debug("Current AI package: %s", table.find(tes3.aiPackage, packageId) or packageId)
            logger:debug("restoring previous AI after combat")
            self:restorePreviousAI()
        end
    elseif aiState == "moving" then
        if self.guar.reference.mobile.actionData.aiBehaviorState == -1 then
            logger:debug("Current AI package: %s", table.find(tes3.aiPackage, packageId) or packageId)
            logger:debug("Setting to wait after moving")
            self:collisionFix()
            self:wait()
        end
        if self:getIsStuck() then
            logger:debug("Stuck while moving, disable collision for a second")
            self:disableCollision()

            timer.start{
                duration = 1,
                callback = function()
                    if not self.guar:isValid() then return end
                    logger:debug("Re-enabling collision")
                    self:enableCollision()
                end
            }
        end
    --Check if stuck on something while wandering
    elseif aiState == "wandering" then
        local isStuck = self:getIsStuck()
        if isStuck then
            logger:debug("Stuck, resetting wander")
            self:wait()
            --set back to wandering in case of save/load
            self.guar.refData.aiState = "wandering"
            timer.start{
                duration = 0.5,
                callback = function()
                    if not self.guar:isValid() then return end
                    if self.guar.refData.aiState == "wandering" then
                        logger:debug("Still need to wander, setting now")
                        self:wander()
                    end
                end
            }
        end
    else
        logger:warn("No AI state detected")
        self:wait()
    end

    --[[
        We don't want to edit the hostileActors list while
        we are iterating it, so we store the hotiles in a local
        table then stopCombat afterwards
    ]]
    local hostileStopList = {}
    ---@param hostile tes3mobileActor
    for hostile in tes3.iterate(self.guar.reference.mobile.hostileActors) do
        if hostile.health.current <= 1 then
            logger:debug("%s is dead, stopping combat", hostile.reference.object.name)
            table.insert(hostileStopList, hostile)
        end
    end

    for _, hostile in ipairs(hostileStopList) do
        self.guar.reference.mobile:stopCombat(hostile)
    end

    --Make sure the lanterns are working properly
    self.guar.reference.sceneNode:update()
    self.guar.reference.sceneNode:updateEffects()
end




function AI:getIsStuck()
    local strikesNeeded = 5

    local maxDistance = 10

    self.guar.refData.stuckStrikes = self.guar.refData.stuckStrikes or 0
    --self.guar.refData.stuckStrikes: we check x times before deciding he's stuck
    if self.guar.refData.stuckStrikes < strikesNeeded then
        --Check if he's trying to move forward
        if self.guar.reference.mobile.isMovingForward then
            --Get the distance from last position and check if it's too small
            if self.guar.refData.lastStuckPosition then
                local lastStuckPosition = tes3vector3.new(
                    self.guar.refData.lastStuckPosition.x,
                    self.guar.refData.lastStuckPosition.y,
                    self.guar.refData.lastStuckPosition.z
                )
                local distance = self.guar.reference.position:distance(lastStuckPosition)
                if distance < maxDistance then
                    self.guar.refData.stuckStrikes = self.guar.refData.stuckStrikes + 1
                else
                    self.guar.refData.stuckStrikes = 0
                end
            end
        end
    end
    local position = self.guar.reference.position
    self.guar.refData.lastStuckPosition = { x = position.x, y = position.y, z = position.z}

    if self.guar.refData.stuckStrikes >= strikesNeeded then
        self.guar.refData.stuckStrikes = 0
        logger:debug("Guar is stuck")
        return true
    else
        return false
    end
end


function AI:updateCloseDistance()
    if self:getAI() == "following" and tes3.player.cell.isInterior ~= true then
        local distance = self.guar:distanceFrom(tes3.player)
        local teleportDist = common.config.mcm.teleportDistance
        --teleport if too far away

        if distance > teleportDist and not self.guar.reference.mobile.inCombat then
            --dont' teleport if fetching (unless stuck)
            if not self.guar.mouth:hasCarriedItems() then
                self:closeTheDistanceTeleport()
            end
        end
        --teleport if stuck and kinda far away
        local isStuck = self:getIsStuck()
        if isStuck and (distance > teleportDist / 2) then
            logger:debug("%s Stuck while following: teleport", self.guar:getName())
            self:closeTheDistanceTeleport()
        end
    end
end

function AI:updateTravelSpells()
    local effects = {
        [tes3.effect.levitate] = "mer_tgw_lev",
        [tes3.effect.waterWalking] = "mer_tgw_ww",
        --[tes3.effect.invisibility] = "mer_tgw_invs"
    }

    local isFollowing = self:getAI() == "following"
        or Rider.getRefBeingRidden() == self.guar.reference

    if not self.guar:isActive() then return end
    for effect, spell in pairs(effects) do
        if tes3.isAffectedBy{ reference = tes3.player, effect = effect } then
            --not affected but player is
            if not tes3.isAffectedBy{ reference = self.guar.reference, effect = effect } then
                if isFollowing then
                    logger:debug("Adding spell to %s", self.guar:getName())
                    self.guar.object.spells:remove(spell)
                    tes3.addSpell{reference = self.guar.reference, spell = spell }
                end
            end
        else
            --effected but player isn't
            if tes3.isAffectedBy{ reference = self.guar.reference, effect = effect } then
                logger:debug("Removing spell from %s", self.guar:getName())
                tes3.removeSpell{reference = self.guar.reference, spell = spell }
            end
        end
        --affected no longer following
        if tes3.isAffectedBy{ reference = self.guar.reference, effect = effect } then
            if not isFollowing then
                logger:debug("Removing spell from %s", self.guar:getName())
                tes3.removeSpell{reference = self.guar.reference, spell = spell }
            end
        end
    end
end


--- Attempt a command. If this fails, a random message
--- will display and the guar will wander instead
---@param min number The minimum value the required happiness will be randomly chosen from
---@param max number the maximum value the required happiness will be randomly chosen from
---@return boolean whether the command was successful. If false, the guar will wander
function AI:attemptCommand(min, max)
    local happinessRequired = math.random(min, max)
    if self.guar.needs:getHappiness() < happinessRequired then
        tes3.messageBox(self.guar:getRefusalMessage())
        self:wander()
        return false
    end
    return true
end


return AI