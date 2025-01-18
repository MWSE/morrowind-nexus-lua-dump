--[[
    Alpha blended meshes are invisible when viewing through water

    This script will switch between BLEND and CLIP switch nodes to make meshes visible
    when viewing through water.
]]

local SwitchNode = require("CraftingFramework.nodeVisuals.SwitchNode")
local common = require("mer.fishing.common")
local logger = common.createLogger("AlphaBlendController")

---@alias Fishing.AlphaBlendController.State
---| '"BLEND"'
---| '"CLIP"'

---@class Fishing.AlphaBlendController
local AlphaBlendController = {
    ---@type { [string]: boolean }
    registeredFish = {}
}

function AlphaBlendController.register(id)
    logger:debug("Registering %s with alpha switch", id)
    AlphaBlendController.registeredFish[id:lower()] = true
end

function AlphaBlendController.setSwitch(reference, state)
    local switchnode = reference.sceneNode:getObjectByName("SWITCH_ALPHA")
    if not switchnode then
        logger:warn("Could not find switch node for alpha blending")
        return
    end
    switchnode.switchIndex = SwitchNode.getIndex(switchnode, state)
end



return AlphaBlendController