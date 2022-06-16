local confPath = "sb_bighead"

local mcm = { config = mwse.loadConfig(confPath) or
    {
        mode = 0
    }
}

local function registerModConfig()
    local template = mwse.mcm.createTemplate { name = "Big Head Mode" }
    template.onClose = function()
        for _, cell in ipairs(tes3.getActiveCells()) do
            for ref in cell:iterateReferences() do
                if (ref.sceneNode) then
                    local head = ref.sceneNode:getObjectByName("Bip01 Head")
                    local leftHand = ref.sceneNode:getObjectByName("Bip01 L Hand")
                    local rightHand = ref.sceneNode:getObjectByName("Bip01 R Hand")
                    if (head) then
                        head.scale = mcm.config.mode > 0 and 2 or 1
                    end
                    if (leftHand) then
                        leftHand.scale = mcm.config.mode == 2 and 2 or 1
                    end
                    if (rightHand) then
                        rightHand.scale = mcm.config.mode == 2 and 2 or 1
                    end
                end
            end
        end
        tes3.player.sceneNode:getObjectByName("Bip01 Head").scale = mcm.config.mode > 0 and 2 or 1
        tes3.player.sceneNode:getObjectByName("Bip01 L Hand").scale = mcm.config.mode == 2 and 2 or 1
        tes3.player.sceneNode:getObjectByName("Bip01 R Hand").scale = mcm.config.mode == 2 and 2 or 1
        tes3.mobilePlayer.firstPersonReference.sceneNode:getObjectByName("Bip01 L Hand").scale = mcm.config.mode == 2 and 2 or 1
        tes3.mobilePlayer.firstPersonReference.sceneNode:getObjectByName("Bip01 R Hand").scale = mcm.config.mode == 2 and 2 or 1
        mwse.saveConfig(confPath, mcm.config)
    end

    local page = template:createPage { label = "", noScroll = true }
    local elementGroup = page:createSideBySideBlock()

    elementGroup = page:createSideBySideBlock()
    elementGroup:createInfo { text = "Enable" }
    elementGroup:createDropdown {
        options  = {
            { label = "Disabled", value = 0 },
            { label = "Big Head Mode", value = 1 },
            { label = "DK Mode", value = 2 }
        },
        variable = mwse.mcm:createTableVariable {
            id    = "mode",
            table = mcm.config
        }
    }

    mwse.mcm.register(template)
end

function mcm.init()
    event.register("modConfigReady", registerModConfig)
end

return mcm
