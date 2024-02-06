
local common = require("mer.theGuarWhisperer.common")
local logger = common.createLogger("AIFixer")

---@class GuarWhisperer.AIFixer.GuarCompanion.refData

---@class GuarWhisperer.AIFixer.GuarCompanion : GuarWhisperer.GuarCompanion
---@field refData GuarWhisperer.AIFixer.GuarCompanion.refData

---@class GuarWhisperer.AIFixer
---@field guar  GuarWhisperer.AIFixer.GuarCompanion
local AIFixer = {}

---@param guar  GuarWhisperer.AIFixer.GuarCompanion
---@return GuarWhisperer.AIFixer
function AIFixer.new(guar)
    local self = setmetatable({}, { __index = AIFixer })
    self.guar = guar
    return self
end

--- If too far away, AI FOllow won't work,
--- so make it invisible and teleport it to the player,
--- then teleport it back after a frame and make it visible again...
---
function AIFixer:resetFollow()
    timer.delayOneFrame(function()timer.delayOneFrame(function()
        if not self.guar:isValid() then return end
        if self.guar:distanceFrom(tes3.player) > 500 then
            local lastKnownPosition = self.guar.reference.position:copy()
            local lastKnownCell = self.guar.reference.cell
            local lanternOn = self.guar.lantern:isOn()
            if lanternOn then
                -- Disable lantern so the player doesn't notice lighting changes
                self.guar.lantern:turnLanternOff()
            end
            -- Make guar invisble while we sneakily move it to the player
            self.guar.reference.sceneNode.appCulled = true
            -- Teleport to the player to trigger AI Follow
            tes3.positionCell{
                cell = tes3.player.cell,
                orientation = self.guar.reference.orientation,
                position = tes3.player.position,
                reference = self.guar.reference,
            }
            -- Wait a frame
            timer.delayOneFrame(function()
                if not self.guar:isValid() then return end
                -- Then return to where it was
                tes3.positionCell{
                    cell = lastKnownCell,
                    orientation = self.guar.reference.orientation,
                    position = lastKnownPosition,
                    reference = self.guar.reference,
                }
                -- make visible and turn lights back on
                self.guar.reference.sceneNode.appCulled = false
                if lanternOn then
                    self.guar.lantern:turnLanternOn()
                end
            end)
        end
    end)end)
end

local function createContainer()
    ---@type tes3container
    local obj = tes3.createObject {
        id = "tgw_cont_lightfix",
        objectType = tes3.objectType.container,
        getIfExists = true,
        name = "Light Fix",
        mesh = [[EditorMarker.nif]],
        capacity = 10000
    }
    local ref = tes3.createReference {
        object = obj,
        position = tes3.player.position,
        orientation = tes3.player.orientation,
        cell = tes3.player.cell
    }
    ref.sceneNode.appCulled = true
    return ref
end

function AIFixer:fixSoundBug()
    if self.guar.reference.mobile.inCombat then return end
    local playingAttackSound =
           tes3.getSoundPlaying{ sound = "SwishL", reference = self.guar.reference }
        or tes3.getSoundPlaying{ sound = "SwishM", reference = self.guar.reference }
        or tes3.getSoundPlaying{ sound = "SwishS", reference = self.guar.reference }
        or tes3.getSoundPlaying{ sound = "guar roar", reference = self.guar.reference }
    if playingAttackSound then
        logger:warn("AI Fix - fixing attack sound")
        tes3.removeSound{ reference = self.guar.reference, "SwishL"}
        tes3.removeSound{ reference = self.guar.reference, "SwishM"}
        tes3.removeSound{ reference = self.guar.reference, "SwishS"}
        tes3.removeSound{ reference = self.guar.reference, "guar roar"}
        local container = createContainer()
        --Transfer all lights, preserving item data, from guar to player
        for _, stack in pairs(self.guar.object.inventory) do
            if stack.object.objectType == tes3.objectType.light then
                tes3.transferItem{
                    from = self.guar.reference,
                    to = container,
                    item = stack.object,
                    count = stack.count,
                    playSound = false,
                }
            end
        end
        --now transfer them all back after a frame
        timer.delayOneFrame(function()
            if not self.guar:isValid() then return end
            for _, stack in pairs(container.object.inventory) do
                if stack.object.objectType == tes3.objectType.light then
                    tes3.transferItem{
                        from = container,
                        to = self.guar.reference,
                        item = stack.object,
                        count = stack.count,
                        playSound = false,
                    }
                end
            end
            container:delete()
            --toggle lights to update scene effects etc
            if self.guar.lantern:isOn() then
                logger:debug("AI Fix - Toggling lantern")
                self.guar.lantern:turnLanternOff()
                self.guar.lantern:turnLanternOn()
            end
        end)
    end
end

return AIFixer