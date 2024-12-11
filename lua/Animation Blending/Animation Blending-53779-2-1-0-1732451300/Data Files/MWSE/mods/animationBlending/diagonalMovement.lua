local config = require("animationBlending.config")

local function editSneakMoveAnims()
    local thirdPersonAnim = tes3.player.attachments.animation
    local baseAnim = thirdPersonAnim.keyframeLayers[3].lower
    local indexMRT = table.find(baseAnim.boneNames, "MRT")
    local data = baseAnim.controllers[indexMRT].data
    local positionKeys = data.positionKeys

    local fix = function(group)
        local g = thirdPersonAnim.animationGroups[group + 1]
        local t1 = g.actionTimings[1] -- Start key
        local t2 = g.actionTimings[2] -- End key

        local startIndex = data:getPositionKeyIndex(t1)
        local endIndex = data:getPositionKeyIndex(t2)
        if not startIndex then return end
        if not endIndex then return end

        -- Reduce excessive velocity in the first four keys
        local startPos = positionKeys[startIndex].value
        local key2Pos = positionKeys[startIndex + 1].value
        local key3Pos = positionKeys[startIndex + 2].value
        local key4Pos = positionKeys[startIndex + 3].value

        local startMovement = key3Pos - startPos
        if math.abs(startMovement.x) > 8 or math.abs(startMovement.y) > 8 then
            local dampen = -0.9
            local adjust = (key2Pos - startPos) * dampen
            positionKeys[startIndex + 1].value = positionKeys[startIndex + 1].value + adjust
            adjust = (key3Pos - startPos) * dampen
            positionKeys[startIndex + 2].value = positionKeys[startIndex + 2].value + adjust
            adjust = (key4Pos - startPos) * dampen
            for i = startIndex + 3, endIndex do
                positionKeys[i].value = positionKeys[i].value + adjust
            end

            -- mwse.log("Diagonal move: corrected anim %s", table.find(tes3.animationGroup, group))
        end
    end

    local fixThese = {
        tes3.animationGroup.sneakBack,
        tes3.animationGroup.sneakBackHandToHand,
        tes3.animationGroup.sneakBack1h,
        tes3.animationGroup.sneakBack2c,
        tes3.animationGroup.sneakBack2w,
    }
    for _, fixThisGroup in ipairs(fixThese) do
        fix(fixThisGroup)     -- SneakBack
        fix(fixThisGroup + 1) -- SneakLeft
        fix(fixThisGroup + 2) -- SneakRight
    end
end
event.register("loaded", function()
    if config.enabled == false then
        return
    end
    if config.diagonalMovement then
        editSneakMoveAnims()
    end
end)


local turn = {
    adjustAngle = 0,
    targetAngle = 0,
    speed = 8,
    diagonal = 3.141592 / 4,
    pelvis = tes3matrix33.new(),
    head = tes3matrix33.new(),
    neck = tes3matrix33.new(),
    spine1 = tes3matrix33.new(),
}

local function diagonalController()
    -- Diagonal move code
    local m = tes3.mobilePlayer
    if (m.isMovingForward and m.isMovingLeft) or (m.isMovingBack and m.isMovingRight) then
        turn.targetAngle = -turn.diagonal
    elseif (m.isMovingForward and m.isMovingRight) or (m.isMovingBack and m.isMovingLeft) then
        turn.targetAngle = turn.diagonal
    else
        turn.targetAngle = 0
    end

    local dt = tes3.worldController.deltaTime
    local diff = turn.targetAngle - turn.adjustAngle
    if math.abs(diff) > 0.005 then
        turn.adjustAngle = turn.adjustAngle + turn.speed * dt * diff
    else
        turn.adjustAngle = turn.targetAngle
    end

    if math.isclose(turn.adjustAngle, 0) then
        return
    end

    if tes3.is3rdPerson() then
        local ref = tes3.player
        local attachNodes = ref.bodyPartManager.attachNodes
        local pelvis = attachNodes[tes3.bodyPartAttachment.pelvis + 1].node
        local neck = attachNodes[tes3.bodyPartAttachment.neck + 1].node
        local head = attachNodes[tes3.bodyPartAttachment.head + 1].node

        -- Third person diagonal move
        if config.diagonalMovement then
            turn.pelvis:toRotationX(turn.adjustAngle)
            turn.head:toRotationX(turn.adjustAngle * -0.7)
            turn.neck:toRotationX(turn.adjustAngle * -0.1)

            pelvis.rotation = pelvis.rotation * turn.pelvis
            head.rotation = head.rotation * turn.head
            neck.rotation = head.parent.rotation * turn.neck

            ref.sceneNode:update()
        end
    else
        local ref = tes3.player1stPerson
        local attachNodes = ref.bodyPartManager.attachNodes
        local pelvis = attachNodes[tes3.bodyPartAttachment.pelvis + 1].node
        local spine1 = attachNodes[tes3.bodyPartAttachment.spine + 1].node

        -- First person spine flex for attacks + diagonal move
        if config.diagonalMovement1stPerson then
            turn.pelvis:toRotationX(turn.adjustAngle)
            turn.spine1:toRotationX(turn.adjustAngle * -0.9)

            pelvis.rotation = pelvis.rotation * turn.pelvis
            spine1.rotation = spine1.rotation * turn.spine1

            ref.sceneNode:update()
        end
    end
end
event.register("simulated", function()
    if config.enabled == false then
        return
    end
    if config.diagonalMovement or config.diagonalMovement1stPerson then
        diagonalController()
    end
end, { priority = 10000 })
