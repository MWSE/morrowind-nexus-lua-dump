local this = {}
local common = require("mer.bardicInspiration.common")


local mesh = "mer_bard\\anim\\Bard.nif"
local group = tes3.animationGroup.idle2

local function onTabDown()
    tes3.mobilePlayer.controlsDisabled = false
    tes3.setVanityMode({ enabled = false })
end

local function onTabUp()
    tes3.mobilePlayer.controlsDisabled = true
    tes3.setVanityMode({ enabled = true })
end

---@param e { lute?: tes3weapon }?
local function attachPlayLute(e)
    e = e or {}
    common.log:debug("attachPlayLute. Lute = %s", e.lute or "nil")
    local shieldBone = tes3.player.sceneNode:getObjectByName("Bip01 L Hand")
    if e.lute then
        local luteMeshId = e.lute.mesh
        common.log:debug("Attaching lute mesh: %s", luteMeshId or "")
        local luteMesh = tes3.loadMesh(luteMeshId, false):clone()
        local transformNode = luteMesh:getObjectByName("LUTE_PLAY_TRANSFORM"):clone()
        shieldBone:attachChild(transformNode, true)
        transformNode:attachChild(luteMesh, true)
    else
        local luteMesh = shieldBone:getObjectByName("LUTE_PLAY_TRANSFORM")
        shieldBone:detachChild(luteMesh)
    end
end


local function isHumanoid(obj)
    local humanoidRaces = {
        ['dark elf'] = true,
        ['high elf'] = true,
        ['breton'] = true,
        ['wood elf'] = true,
        ['redguard'] = true,
        ['orc'] = true,
        ['nord'] = true,
        ['imperial'] = true
    }
    return obj and obj.race and humanoidRaces[obj.race.id:lower()]
end


function this.play()
    --Vanity mode, disable controls
    tes3.setVanityMode({ enabled = true })
    common.disableControls()
    if mesh and isHumanoid(tes3.player.object) then
        common.data.previousAnimationMesh = tes3.player.object.mesh
        local heldItem = tes3.getEquippedItem{
            actor = tes3.player,
            objectType = tes3.objectType.weapon
        }
        if not heldItem then
            common.log:error("No held item")
            return
        end
        local lute = heldItem.object
        common.data.heldLute = lute.id
        common.log:debug("Held lute: %s", common.data.heldLute)
        tes3.playAnimation({
            reference = tes3.player,
            mesh = mesh,
            group = group,
            startFlag = 1
        })
        tes3.mobilePlayer:unequip{ type = tes3.objectType.weapon}


        common.log:debug("Attaching lute: %s", lute)
        attachPlayLute{ lute = lute }
    end
    event.register("keyUp", onTabUp, { filter = tes3.getInputBinding(tes3.keybind.togglePOV).code })
    event.register("keyDown", onTabDown, { filter = tes3.getInputBinding(tes3.keybind.togglePOV).code })
end

function this.stop()
    if common.data.previousAnimationMesh and isHumanoid(tes3.player.object) then
        tes3.playAnimation({
            reference = tes3.player,
            mesh = common.data.previousAnimationMesh,
            group = tes3.animationGroup.idle,
            startFlag = 1
        })
        common.data.previousAnimationMesh = nil
        common.log:debug("Held lute2: %s", common.data.heldLute)

        attachPlayLute()
        mwscript.equip{ reference = tes3.player, item = common.data.heldLute }
        common.data.heldLute = nil
    end
    tes3.setVanityMode({ enabled = false })
    common.enableControls()
    event.unregister("keyUp", onTabUp, { filter = tes3.getInputBinding(tes3.keybind.togglePOV).code })
    event.unregister("keyDown", onTabDown, { filter = tes3.getInputBinding(tes3.keybind.togglePOV).code })

 end


local function clearEventsOnLoad()
    event.unregister("keyUp", onTabUp, { filter = tes3.getInputBinding(tes3.keybind.togglePOV).code })
    event.unregister("keyDown", onTabDown, { filter = tes3.getInputBinding(tes3.keybind.togglePOV).code })
end
event.register("BardicInspiration:DataLoaded", clearEventsOnLoad)


return this