local config = require("cz.Dismember.config")

local BASEPATH  = "cz\\b\\nodemap.nif"
local GOREPATH  = "cz\\b\\gore.nif"
local BLOODPATH = "cz\\b\\bloodspurt.nif"

--- @class goreData
local defaults = {
    severedParts = {
        [tes3.activeBodyPart.head] = false,
        [tes3.activeBodyPart.hair] = false,
        [tes3.activeBodyPart.rightForearm] = false,
        [tes3.activeBodyPart.rightWrist] = false,
        [tes3.activeBodyPart.rightHand] = false,
        [tes3.activeBodyPart.leftForearm] = false,
        [tes3.activeBodyPart.leftWrist] = false,
        [tes3.activeBodyPart.leftHand] = false,
        [tes3.activeBodyPart.rightKnee] = false,
        [tes3.activeBodyPart.rightAnkle] = false,
        [tes3.activeBodyPart.rightFoot] = false,
        [tes3.activeBodyPart.leftKnee] = false,
        [tes3.activeBodyPart.leftAnkle] = false,
        [tes3.activeBodyPart.leftFoot] = false
    },
    partsList = {}
}

-- node names in the node mesh and their equivalent bodypart
local nodeMap = {
    [tes3.activeBodyPart.head] = "GORE Tri Neck",
    [tes3.activeBodyPart.chest] = "GORE Tri Chest",
    [tes3.activeBodyPart.rightUpperArm] = "GORE Tri Right Upper Arm",
    [tes3.activeBodyPart.rightForearm] = "GORE Tri Right Forearm",
    [tes3.activeBodyPart.rightWrist] = "GORE Tri Right Wrist",
    [tes3.activeBodyPart.rightHand] = "GORE Tri Right Hand",
    [tes3.activeBodyPart.leftUpperArm] = "GORE Tri Left Upper Arm",
    [tes3.activeBodyPart.leftForearm] = "GORE Tri Left Forearm",
    [tes3.activeBodyPart.leftWrist] = "GORE Tri Left Wrist",
    [tes3.activeBodyPart.leftHand] = "GORE Tri Left Hand",
    [tes3.activeBodyPart.rightUpperLeg] = "GORE Tri Right Upper Leg",
    [tes3.activeBodyPart.rightKnee] = "GORE Tri Right Knee",
    [tes3.activeBodyPart.rightAnkle] = "GORE Tri Right Ankle",
    [tes3.activeBodyPart.rightFoot] = "GORE Tri Right Foot",
    [tes3.activeBodyPart.leftUpperLeg] = "GORE Tri Left Upper Leg",
    [tes3.activeBodyPart.leftKnee] = "GORE Tri Left Knee",
    [tes3.activeBodyPart.leftAnkle] = "GORE Tri Left Ankle",
    [tes3.activeBodyPart.leftFoot] = "GORE Tri Left Foot"
}


-- list of all bodyparts for each limb to gib
local limbs = {
    ["head"] = {tes3.activeBodyPart.neck, tes3.activeBodyPart.head, tes3.activeBodyPart.hair},
    ["rightArm"] = {tes3.activeBodyPart.rightPauldron, tes3.activeBodyPart.rightUpperArm, tes3.activeBodyPart.rightForearm, tes3.activeBodyPart.rightWrist, tes3.activeBodyPart.rightHand},
    ["leftArm"]  = {tes3.activeBodyPart.leftPauldron,  tes3.activeBodyPart.leftUpperArm,  tes3.activeBodyPart.leftForearm,  tes3.activeBodyPart.leftWrist,  tes3.activeBodyPart.leftHand},
    ["rightLeg"] = {tes3.activeBodyPart.rightUpperLeg, tes3.activeBodyPart.rightKnee, tes3.activeBodyPart.rightAnkle, tes3.activeBodyPart.rightFoot},
    ["leftLeg"] = {tes3.activeBodyPart.leftUpperLeg,  tes3.activeBodyPart.leftKnee,  tes3.activeBodyPart.leftAnkle,  tes3.activeBodyPart.leftFoot}
}

-- the actual bodyparts to cull
local severedLimbs = {
    ["head"] = {tes3.activeBodyPart.head, tes3.activeBodyPart.hair},
    ["rightArm"] = {tes3.activeBodyPart.rightForearm, tes3.activeBodyPart.rightWrist, tes3.activeBodyPart.rightHand},
    ["leftArm"]  = {tes3.activeBodyPart.leftForearm,  tes3.activeBodyPart.leftWrist,  tes3.activeBodyPart.leftHand},
    ["rightLeg"] = {tes3.activeBodyPart.rightKnee, tes3.activeBodyPart.rightAnkle, tes3.activeBodyPart.rightFoot},
    ["leftLeg"] = {tes3.activeBodyPart.leftKnee,  tes3.activeBodyPart.leftAnkle,  tes3.activeBodyPart.leftFoot}
}

--- Create the Gore Data and set to default values
--- @param ref tes3reference
local function initializeGoreData(ref)
    ref.data.goreData = {}
    ref.data.goreData.severedParts = {
        [tes3.activeBodyPart.head] = false,
        [tes3.activeBodyPart.hair] = false,
        [tes3.activeBodyPart.rightForearm] = false,
        [tes3.activeBodyPart.rightWrist] = false,
        [tes3.activeBodyPart.rightHand] = false,
        [tes3.activeBodyPart.leftForearm] = false,
        [tes3.activeBodyPart.leftWrist] = false,
        [tes3.activeBodyPart.leftHand] = false,
        [tes3.activeBodyPart.rightKnee] = false,
        [tes3.activeBodyPart.rightAnkle] = false,
        [tes3.activeBodyPart.rightFoot] = false,
        [tes3.activeBodyPart.leftKnee] = false,
        [tes3.activeBodyPart.leftAnkle] = false,
        [tes3.activeBodyPart.leftFoot] = false
    }
    ref.data.goreData.partsList = {}
end

--- Convenience function to get the Gore Data
--- @param ref tes3reference
--- @return goreData
local function getGoreData(ref)
    return ref.data.goreData
end

--- Removes all blood spurts
--- because I can't figure out how to clamp the particle anim in the nif
--- @param ref tes3reference
local function clearBloodSpurts(ref)
    local sceneNode = ref.sceneNode
    if not sceneNode then return end

    local bloodSpurts = {}

    for node in table.traverse(sceneNode.children) do
        if node.name == "GORE Bloodspurt" then
            table.insert(bloodSpurts, node)
        end
    end

    for _, bloodSpurt in ipairs(bloodSpurts) do
        bloodSpurt.appCulled = true
        bloodSpurt:update()
    end

    sceneNode:update()
end


--- Credits to Greatness7 for the function
--- attaches the nodemesh to the npc with nodes in approximate bodypart locations
local function attachSkinnedMesh(ref, fileName)
    local mesh = assert(tes3.loadMesh(fileName)):clone()

    local attachNode = niNode.new()
    attachNode.name = "GORE Root" -- use some unique name

    do -- Apply non-uniform (racial) scaling
        local weight = 1 / ref.object.weight
        local height = 1 / ref.object.height
        local scale = tes3vector3.new(weight, weight, height)

        local r = attachNode.rotation
        attachNode.rotation = tes3matrix33.new(r.x * scale, r.y * scale, r.z * scale)
    end

    for shape in table.traverse(mesh.children) do
        if shape.skinInstance then
            shape.skinInstance.root = attachNode
            for i, bone in pairs(shape.skinInstance.bones) do
                shape.skinInstance.bones[i] = assert(ref.sceneNode:getObjectByName(bone.name))
            end
            attachNode:attachChild(shape, true)
        end
    end

    ref.sceneNode:attachChild(attachNode, true)

    attachNode:update()
    attachNode:updateEffects()
    attachNode:updateProperties()
end

--- Goes through the nodemap mesh bodypart nodes to determine the closest one to the blood splatter
--- @param bloodSplash tes3splashControllerActiveSplash
--- @param ref tes3reference
--- @return tes3bodyPartManagerActiveBodyPart|nil closestPart the closest activeBodyPart (or nil on fail)
--- @return integer|nil closestActivePartIndex since activeBodyPart and bodyPart have difference indices (WTF...) 
local function findClosestPart(bloodSplash, ref)
    local bloodNode = bloodSplash.node
    local bloodVector = bloodNode.translation   --global and local are the same
    local closestVector = -1
    --- @type tes3bodyPartManagerActiveBodyPart
    local closestPart
    local closestActivePartIndex

    for activeParts,tri in pairs(nodeMap) do
        local sceneNode = ref.sceneNode
        if not sceneNode then return end

        local bip01 = sceneNode:getObjectByName("Bip01")
        if not bip01 then return end

        --- @type niTriShape
        local bodyPart = sceneNode:getObjectByName(tri)
        if bodyPart then
            local bodyVector = bodyPart.worldTransform.translation
            bodyVector.z = bodyVector.z + 70   -- close enough
            local vectorDistance = tes3vector3.distance(bodyVector, bloodVector)

            if closestVector == -1 or vectorDistance < closestVector then
                closestVector = vectorDistance
                for _, layer in pairs(tes3.activeBodyPartLayer) do
                    local activePart = ref.bodyPartManager:getActiveBodyPart(layer, activeParts)
                    if activePart.bodyPart then
                        closestPart = activePart
                        closestActivePartIndex = activeParts
                    end
                end
            end
        end
    end

    return closestPart, closestActivePartIndex
end

--- Culls bodyparts in the severableLimb list
--- @param severableLimb table
--- @param ref tes3reference
local function cullPart(severableLimb, ref)
    for _, bp in pairs(severableLimb) do
        for _, layer in pairs(tes3.activeBodyPartLayer) do
            local activePart = ref.bodyPartManager:getActiveBodyPart(layer, bp)
            if activePart.bodyPart and activePart.node then
                --timer.delayOneFrame(function() activePart.node.appCulled = true end)
                local actiHandle = tes3.makeSafeObjectHandle(activePart)
                timer.delayOneFrame(function ()
                    if not actiHandle then
                        return
                    end
                    if not actiHandle:valid() then
                        return
                    end
                    local r = actiHandle:getObject()
                    if not r then
                        return
                    end
                    r.node.appCulled = true
                end)
            end
        end
    end

    ref.modified = true
end

--- @param closestActivePartIndex integer
--- @param ref tes3reference
local function placeGore(closestActivePartIndex, ref)
    local mesh = assert(tes3.loadMesh(GOREPATH)):clone()
    local bloodMesh = assert(tes3.loadMesh(BLOODPATH)):clone()

    bloodMesh.scale = 0.5

    local sceneNode = ref.sceneNode
    if not sceneNode then return end

    local goreData = getGoreData(ref)
    if not goreData or not goreData.severedParts then initializeGoreData(ref) end
    goreData = getGoreData(ref)

    -- Hardcoded because I don't want to juggle 6 tables
    if table.find(limbs.head, closestActivePartIndex) then
        local bip01 = sceneNode:getObjectByName("Bip01 Head")
        local gore = mesh:getObjectByName("Tri GoreCap:Head")
        if not bip01 or not gore then return end
        bip01:attachChild(gore)
        bip01:attachChild(bloodMesh)
        goreData.severedParts[tes3.activeBodyPart.head] = true
        goreData.severedParts[tes3.activeBodyPart.hair] = true
    elseif table.find(limbs.rightArm, closestActivePartIndex) then
        local bip01 = sceneNode:getObjectByName("Bip01 R Forearm")
        local gore = mesh:getObjectByName("Tri GoreCap:RightArm")
        if not bip01 or not gore then return end
        bip01:attachChild(gore)
        bip01:attachChild(bloodMesh)
        goreData.severedParts[tes3.activeBodyPart.rightForearm] = true
        goreData.severedParts[tes3.activeBodyPart.rightWrist] = true
        goreData.severedParts[tes3.activeBodyPart.rightHand] = true
    elseif table.find(limbs.leftArm, closestActivePartIndex) then
        local bip01 = sceneNode:getObjectByName("Bip01 L Forearm")
        local gore = mesh:getObjectByName("Tri GoreCap:LeftArm")
        if not bip01 or not gore then return end
        bip01:attachChild(gore)
        bip01:attachChild(bloodMesh)
        goreData.severedParts[tes3.activeBodyPart.leftForearm] = true
        goreData.severedParts[tes3.activeBodyPart.leftWrist] = true
        goreData.severedParts[tes3.activeBodyPart.leftHand] = true
    elseif table.find(limbs.rightLeg, closestActivePartIndex) then
        local bip01 = sceneNode:getObjectByName("Bip01 R Thigh")
        local gore = mesh:getObjectByName("Tri GoreCap:RightLeg")
        if not bip01 or not gore then return end
        bip01:attachChild(gore)
        bip01:attachChild(bloodMesh)
        goreData.severedParts[tes3.activeBodyPart.rightKnee] = true
        goreData.severedParts[tes3.activeBodyPart.rightAnkle] = true
        goreData.severedParts[tes3.activeBodyPart.rightFoot] = true
    elseif table.find(limbs.leftLeg, closestActivePartIndex) then
        local bip01 = sceneNode:getObjectByName("Bip01 L Thigh")
        local gore = mesh:getObjectByName("Tri GoreCap:LeftLeg")
        if not bip01 or not gore then return end
        bip01:attachChild(gore)
        bip01:attachChild(bloodMesh)
        goreData.severedParts[tes3.activeBodyPart.leftKnee] = true
        goreData.severedParts[tes3.activeBodyPart.leftAnkle] = true
        goreData.severedParts[tes3.activeBodyPart.leftFoot] = true
    end

    tes3.playSound({reference = ref, soundPath = "cz\\gore\\gore.wav"})

    sceneNode:update()
    mesh:update()
    bloodMesh:update()

    local refHandle = tes3.makeSafeObjectHandle(ref)
    timer.start({duration = 5, callback =
        function ()
        if not refHandle then
            return
        end
        if not refHandle:valid() then
            return
        end
        local r = refHandle:getObject()
        if not r then
            return
        end
        clearBloodSpurts(r)
    end})
end

--- Placeholder, if I do other limbs this function gets the axe
--- @param ref tes3reference
local function placeHead(ref)
    local mesh = assert(tes3.loadMesh(GOREPATH)):clone()

    for _, layer in pairs(tes3.activeBodyPartLayer) do
        local activePart = ref.bodyPartManager:getActiveBodyPart(layer, tes3.activeBodyPart.head)
        if activePart and activePart.node then
            if activePart.bodyPart then
                local limbMesh = activePart.bodyPart.mesh
                local severedLimb = tes3.createObject({ objectType = tes3.objectType.static, getIfExists = false, mesh = limbMesh })
                tes3.setSourceless(severedLimb)

                local pos = ref.position:copy()
                pos.x = pos.x + math.random(-30, 30)
                pos.y = pos.y + math.random(-30, 30)
                pos.z = pos.z + 10

                local limbRef = tes3.createReference({
                    object = severedLimb,
                    position = pos,
                    orientation = { math.random() * 3.14, math.random() * 3.14, math.random() * 3.14 },
                    cell = ref.cell
                })

                local gore = mesh:getObjectByName("Tri GoreCap:HeadCap")
                local sceneNode = limbRef.sceneNode
                if not sceneNode or not gore then return end
                sceneNode:attachChild(gore)

                for _, hairLayer in pairs(tes3.activeBodyPartLayer) do
                    local hairPart = ref.bodyPartManager:getActiveBodyPart(hairLayer, tes3.activeBodyPart.hair)

                    if hairPart.bodyPart then
                        local hairMesh = assert(tes3.loadMesh(hairPart.bodyPart.mesh)):clone()
                        sceneNode:attachChild(hairMesh)
                        break
                    end
                end

                sceneNode:update()
                mesh:update()

                local goreData = getGoreData(ref)
                if not goreData or not goreData.partsList then initializeGoreData(ref) end
                goreData = getGoreData(ref)
                table.insert(goreData.partsList, limbRef)
                return
            end
        end
    end
end

--- Doesn't work since body replacers usually use the whole body mesh for each limb
--- @param closestActivePartIndex integer
--- @param ref tes3reference
local function placeLimbs(closestActivePartIndex, ref)
    local mesh = assert(tes3.loadMesh(GOREPATH)):clone()

    for _, layer in pairs(tes3.activeBodyPartLayer) do
        local index
        if table.find(limbs["head"], closestActivePartIndex) then
            index = tes3.activeBodyPart.head
        elseif table.find(limbs["leftArm"], closestActivePartIndex) then
            index = tes3.activeBodyPart.leftForearm
        elseif table.find(limbs["rightArm"], closestActivePartIndex) then
            index = tes3.activeBodyPart.rightForearm
        elseif table.find(limbs["legs"], closestActivePartIndex) then
            index = tes3.activeBodyPart.rightKnee
        end
        if not index then return end

        local activePart = ref.bodyPartManager:getActiveBodyPart(layer, index)
        if activePart and activePart.node then
            if activePart.bodyPart then
                local limbMesh = activePart.bodyPart.mesh
                local severedLimb = tes3.createObject({ objectType = tes3.objectType.static, getIfExists = false, mesh = limbMesh })
                tes3.setSourceless(severedLimb)

                local pos = ref.position:copy()
                pos.x = pos.x + math.random(-30, 30)
                pos.y = pos.y + math.random(-30, 30)
                pos.z = pos.z + 10

                local limbRef = tes3.createReference({
                    object = severedLimb,
                    position = pos,
                    orientation = { math.random() * 3.14, math.random() * 3.14, math.random() * 3.14 },
                    cell = ref.cell
                })

                local gore = mesh:getObjectByName("Tri GoreCap:HeadCap")
                local sceneNode = limbRef.sceneNode
                if not sceneNode then return end
                sceneNode:attachChild(gore)

                if index == tes3.activeBodyPart.head then
                    for _, hairLayer in pairs(tes3.activeBodyPartLayer) do
                        local hairPart = ref.bodyPartManager:getActiveBodyPart(hairLayer, tes3.activeBodyPart.hair)

                        if hairPart.bodyPart then
                            local hairMesh = assert(tes3.loadMesh(hairPart.bodyPart.mesh)):clone()
                            mwse.log("attaching part %s", hairPart.bodyPart.id)
                            sceneNode:attachChild(hairMesh)
                            break
                        end
                    end
                    local gore = mesh:getObjectByName("Tri GoreCap:HeadCap")
                    if not gore then return end
                    sceneNode:attachChild(gore)
                elseif index == tes3.activeBodyPart.leftForearm then
                    for _, wristLayer in pairs(tes3.activeBodyPartLayer) do
                        local wristPart = ref.bodyPartManager:getActiveBodyPart(wristLayer, tes3.activeBodyPart.leftWrist)

                        if wristPart.bodyPart then
                            local wristMesh = assert(tes3.loadMesh(wristPart.bodyPart.mesh)):clone()
                            mwse.log("attaching part %s", wristPart.bodyPart.id)
                            sceneNode:attachChild(wristMesh)
                            break
                        end
                    end
                    for _, handLayer in pairs(tes3.activeBodyPartLayer) do
                        local handPart = ref.bodyPartManager:getActiveBodyPart(handLayer, tes3.activeBodyPart.leftHand)

                        if handPart.bodyPart then
                            local handMesh = assert(tes3.loadMesh(handPart.bodyPart.mesh)):clone()
                            mwse.log("attaching part %s", handPart.bodyPart.id)
                            sceneNode:attachChild(handMesh)
                            break
                        end
                    end
                    local gore = mesh:getObjectByName("Tri GoreCap:LeftArmCap")
                    if not gore then return end
                    sceneNode:attachChild(gore)
                elseif index == tes3.activeBodyPart.rightForearm then
                    for _, wristLayer in pairs(tes3.activeBodyPartLayer) do
                        local wristPart = ref.bodyPartManager:getActiveBodyPart(wristLayer, tes3.activeBodyPart.rightWrist)

                        if wristPart.bodyPart then
                            local wristMesh = assert(tes3.loadMesh(wristPart.bodyPart.mesh)):clone()
                            mwse.log("attaching part %s", wristPart.bodyPart.id)
                            sceneNode:attachChild(wristMesh)
                            break
                        end
                    end
                    for _, handLayer in pairs(tes3.activeBodyPartLayer) do
                        local handPart = ref.bodyPartManager:getActiveBodyPart(handLayer, tes3.activeBodyPart.rightHand)

                        if handPart.bodyPart then
                            local handMesh = assert(tes3.loadMesh(handPart.bodyPart.mesh)):clone()
                            mwse.log("attaching part %s", handPart.bodyPart.id)
                            sceneNode:attachChild(handMesh)
                            break
                        end
                    end
                    local gore = mesh:getObjectByName("Tri GoreCap:RightArmCap")
                    if not gore then return end
                    sceneNode:attachChild(gore)
                elseif index == tes3.activeBodyPart.rightKnee then
                    for _, wristLayer in pairs(tes3.activeBodyPartLayer) do
                        local wristPart = ref.bodyPartManager:getActiveBodyPart(wristLayer, tes3.activeBodyPart.rightAnkle)

                        if wristPart.bodyPart then
                            local wristMesh = assert(tes3.loadMesh(wristPart.bodyPart.mesh)):clone()
                            mwse.log("attaching part %s", wristPart.bodyPart.id)
                            sceneNode:attachChild(wristMesh)
                            break
                        end
                    end
                    for _, handLayer in pairs(tes3.activeBodyPartLayer) do
                        local handPart = ref.bodyPartManager:getActiveBodyPart(handLayer, tes3.activeBodyPart.rightFoot)

                        if handPart.bodyPart then
                            local handMesh = assert(tes3.loadMesh(handPart.bodyPart.mesh)):clone()
                            mwse.log("attaching part %s", handPart.bodyPart.id)
                            sceneNode:attachChild(handMesh)
                            break
                        end
                    end
                    local gore = mesh:getObjectByName("Tri GoreCap:LeftLegCap")
                    local gore2 = mesh:getObjectByName("Tri GoreCap:RightLegCap")
                    if not gore or not gore2 then return end
                    sceneNode:attachChild(gore)
                    sceneNode:attachChild(gore2)
                else return
                end

                sceneNode:update()
                mesh:update()
                return
            end
        end
    end
end

--- @param e damagedEventData
local function dismemberNPC(e)
    if not config.enabled then return end
    if not e.killingBlow then return end

    local target = e.reference
    if not target or (target.object.objectType ~= tes3.objectType.npc and target.mobile.actorType ~= tes3.actorType.player) then return end

    if e.damage < config.minDamage then return end
    if math.random(0, 99) >= config.baseChance then return end

    if not e.attacker then return end
    local weap = e.attacker.readiedWeapon
    if not weap then
        if e.attacker.actorType == tes3.actorType.creature and not config.enableCreatures then return end
        if not config.enableFists then return end
    elseif weap.object.type == tes3.weaponType.shortBladeOneHand and not config.enableShortBlade       then return
    elseif weap.object.type == tes3.weaponType.longBladeOneHand  and not config.enableLongBladeOneHand then return
    elseif weap.object.type == tes3.weaponType.longBladeTwoClose and not config.enableLongBladeTwoHand then return
    elseif weap.object.type == tes3.weaponType.bluntOneHand      and not config.enableBluntOneHand     then return
    elseif weap.object.type == tes3.weaponType.bluntTwoClose     and not config.enableBluntTwoClose    then return
    elseif weap.object.type == tes3.weaponType.bluntTwoWide      and not config.enableBluntTwoWide     then return
    elseif weap.object.type == tes3.weaponType.spearTwoWide      and not config.enableSpearTwoWide     then return
    elseif weap.object.type == tes3.weaponType.axeOneHand        and not config.enableAxeOneHand       then return
    elseif weap.object.type == tes3.weaponType.axeTwoHand        and not config.enableAxeTwoHand       then return
    elseif weap.object.type == tes3.weaponType.marksmanBow       and not config.enableMarksmanBow      then return
    elseif weap.object.type == tes3.weaponType.marksmanCrossbow  and not config.enableMarksmanCrossbow then return
    elseif weap.object.type == tes3.weaponType.marksmanThrown    and not config.enableMarksmanThrown   then return
    end

    local goreData = getGoreData(target)
    if not goreData or not goreData.severedParts then initializeGoreData(target) end
    attachSkinnedMesh(target, BASEPATH)

    local bloodSplashes = tes3.worldController.splashController.activeSplashes

    -- So we don't double place
    local gorePartsTable = {
        head = true,
        leftArm = true,
        rightArm = true,
        rightLeg = true,
        leftLeg = true
    }

    -- Because apparently only the player generates blood splatter
    -- So I'll just pick a random bodypart for npcs
    if e.attacker.objectType == tes3.objectType.npc or e.attacker.objectType == tes3.objectType.creature then
        local idx = table.choice({"head", "rightArm", "leftArm", "rightLeg", "leftLeg"})
        local closestActivePartIndex = table.choice(limbs[idx])

        -- start chopping :)
        placeGore(closestActivePartIndex, target)
        --placeSeveredLimb(severedLimbs[idx], target)       -- Needs redesign with custom assets 
        if table.find(limbs["head"], closestActivePartIndex) and gorePartsTable.head then
            placeHead(target)
            gorePartsTable.head = false
        end
        cullPart(severedLimbs[idx], target)

        return
    end

    for _,bloodSplash in ipairs(bloodSplashes) do
        local closestPart, closestActivePartIndex = findClosestPart(bloodSplash, target)

        if closestPart and closestPart.node and closestActivePartIndex then
            for idx, limb in pairs(limbs) do
                if table.find(limb, closestActivePartIndex) then
                    -- start chopping :)
                    placeGore(closestActivePartIndex, target)
                    --placeSeveredLimb(severedLimbs[idx], target)       -- Needs redesign with custom assets 
                    if table.find(limbs["head"], closestActivePartIndex) and gorePartsTable.head then
                        placeHead(target)
                        gorePartsTable.head = false
                    end
                    cullPart(severedLimbs[idx], target)
                end
            end
        end
    end
end

--- @param e bodyPartAssignedEventData
local function blockBodyUpdate(e)
    if not config.enabled then return end
    local ref = e.reference
    local goreData = getGoreData(ref)
    if not goreData or not goreData.severedParts then return end   -- shouldn't happen but just in case I guess
    if goreData.severedParts and goreData.severedParts[e.index] and goreData.severedParts[e.index] == true then return false end
end

--- @param e mobileActivatedEventData
local function resetActor(e)
    if not config.enabled then return end
    if e.mobile.objectType ~= tes3.objectType.mobileNPC then return end
    local ref = e.reference

    if not ref.isDead and getGoreData(ref) then initializeGoreData(ref) end
    clearBloodSpurts(ref)
end

--- @param e uiActivatedEventData
local function clearBodyParts(e)
    local element = e.element
    local ref = element:getPropertyObject("MenuContents_ObjectRefr")
	if (ref == nil) then
		return
	end

    local removebutton = element:findChild('MenuContents_removebutton')
	if (removebutton ~= nil) then
		removebutton:registerBefore(
            'mouseClick',
            function()
                local goreData = getGoreData(ref)
                if not goreData or not goreData.partsList then return end

                for _,part in pairs(goreData.partsList) do
                    part:disable()
                end
            end
        )
	end
end

local function onInitialized()
    event.register("damaged", dismemberNPC)
    event.register("bodyPartAssigned", blockBodyUpdate)
    event.register("mobileActivated", resetActor)
    event.register("uiActivated", clearBodyParts, { filter = "MenuContents" })
    mwse.log("[Tis But A Scratch] initialized")
end
event.register("initialized", onInitialized)
event.register("modConfigReady", function() require("cz.Dismember.mcm") end)