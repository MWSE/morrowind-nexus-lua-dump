local AnimationService = {}
local Util = require('mer.skoomaesthesia.util.Util')
local config = require('mer.skoomaesthesia.config')
local TripStateService = require('mer.skoomaesthesia.services.TripStateService')
local meshRoot = 'skoomaesthesia'
local meshes = {
    attach = 'AttachApparatus',
    equip = 'SkoomaEquip',
    world = 'SkoomaWorld'
}

local function getDuration(duration)
    local tripping = TripStateService.getState()
    local multi = tripping and config.static.timeShift or 1.0
    return duration / multi
end

local function getMeshPath(meshType)
    local animPath = string.format('%s\\%s.nif', meshRoot, meshes[meshType])
    Util.log:debug("getMeshPath: %s", animPath)
    return animPath
end

local function getPipeMesh(pipeObject)
    Util.log:debug("getPipeMesh")
    local skoomaMeshPath = pipeObject.mesh
    Util.log:debug("skoomaMeshPath: %s", skoomaMeshPath)
    local skoomaMesh = tes3.loadMesh(skoomaMeshPath):clone()
    return skoomaMesh
end

local function attachPipe(ref, pipeObject)
    Util.log:debug("attachPipe")
    local skooma = getPipeMesh(pipeObject)
    local attachPath = getMeshPath('attach')
    local node = tes3.loadMesh(attachPath):clone()
    node:attachChild(skooma, true)
    ref.sceneNode:getObjectByName("Bip01 R Hand"):attachChild(node)
    ref:updateSceneGraph()
    ref.sceneNode:updateNodeEffects()
end

local function detachPipe(ref)
    Util.log:debug("detachPipe")
    local node = ref.sceneNode:getObjectByName("Bip01 R Hand")
    local attach = node:getObjectByName("Attach Apparatus")
    node:detachChild(attach)
end

local function setPipeCullState(refHandle, state)
    if refHandle and refHandle:valid() then
        refHandle:getObject().sceneNode.appCulled = state
    end
end


local function playSmokingAnimation(meshPath, pipeObject, pipeRef)
    Util.log:debug("playSmokingAnimation")
    local ref = tes3.is3rdPerson() and tes3.player or tes3.player1stPerson
    local pipeRefHandle = pipeRef and tes3.makeSafeObjectHandle(pipeRef)
    --unequip any weapon
    tes3.mobilePlayer:unequip{ type = tes3.objectType.weapon }

    --Set data used for blocking equip
    config.pipeAnimating = true
    timer.start{
        duration = getDuration(4.5),
        callback = function()
            config.pipeAnimating = nil
        end
    }

    --play the animation
    tes3.playAnimation({
        reference= ref,
        upper= tes3.animationGroup.idle9,
        mesh= meshPath,
        loopCount=0,
        startFlag = 1,
    })
    event.trigger("Ashfall:triggerPackUpdate")
    --Transfer pipe to hands at appropriate times in animation
    if pipeRef then -- take from world
        timer.start{
            duration = getDuration(1),
            callback = function()
                attachPipe(ref, pipeObject)
                setPipeCullState(pipeRefHandle, true)
            end
        }
    else -- pull from pocket
        attachPipe(ref, pipeObject)
        setPipeCullState(pipeRefHandle, true)
    end
    --Return the pipe        
    timer.start{
        duration = getDuration(3.5),
        callback = function()
            detachPipe(ref)
            setPipeCullState(pipeRefHandle, false)
        end
    }
end




function AnimationService.smokeSkooma(e)
    local pipeRef = e.reference
    local pipeObj = e.object or pipeRef and pipeRef.object

    Util.log:debug("smokeSkooma")
    local animPath
    if pipeRef then
        animPath = getMeshPath('world')
    else
        animPath = getMeshPath('equip')
    end
    playSmokingAnimation(animPath, pipeObj, pipeRef)
end

return AnimationService

