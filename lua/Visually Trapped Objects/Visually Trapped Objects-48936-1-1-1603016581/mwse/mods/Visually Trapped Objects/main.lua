
-- Checking whether Locks and Traps Detection is on
local LnTDLockData = include("AdituV.DetectTrap.LockData")
local LnTDConfig

if LnTDLockData then
    event.register("modConfigReady", function()
        LnTDConfig = require("AdituV.DetectTrap.Config")
        if LnTDConfig.modEnabled == false then
            LnTDLockData = nil
        end
    end)
end


local effectEnchantment = nil

-- Callback for when a new scene node is created for a reference.
-- We'll use it add a visual effect to trapped objects.
local function onReferenceSceneNodeCreated(e)
    local ref = e.reference
    if not (ref.object.objectType == tes3.objectType.container or ref.object.objectType == tes3.objectType.door) then
        return
    end
    
    -- No trap? No effect.
    local trapData = ref.lockNode
    if (trapData == nil or trapData.trap == nil) then
        return
    end
    
    -- L&TD is on and trap wasn't detected by it? No effect.
    if LnTDLockData then
      ld = LnTDLockData.getForReference(ref)
      ld:attemptDetectTrap()
      if not ld:getTrapDetected() then
        return
      end
    end

    effectEnchantment = trapData.trap
    tes3.worldController:applyEnchantEffect(ref.sceneNode, effectEnchantment)
    ref.sceneNode:updateNodeEffects()
end

local function onInitialized()
    event.register("referenceSceneNodeCreated", onReferenceSceneNodeCreated)
end
event.register("initialized", onInitialized)