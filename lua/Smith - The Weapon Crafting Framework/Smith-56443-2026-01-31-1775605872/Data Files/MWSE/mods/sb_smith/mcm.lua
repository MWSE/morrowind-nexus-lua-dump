local interop = require("sb_smith.interop")
local confPath = "sb_smith"

local mcm = { config = mwse.loadConfig(confPath) or
    {
        faithfulEnabled = 0
    }
}

local function registerModConfig()
    local template = mwse.mcm.createTemplate { name = "Smith - The Weapon Crafting Framework" }
    template.onClose = function()
        mwse.saveConfig(confPath, mcm.config)
    end

    local page = template:createPage { label = "", noScroll = true }
    local elementGroup = page:createSideBySideBlock()

    elementGroup:createInfo { text = "Faithful Mode" }
    elementGroup:createDropdown {
        options  = {
            { label = "Disabled", value = 0 },
            { label = "Enabled", value = 1 }
        },
        variable = mwse.mcm:createTableVariable {
            id    = "mode",
            table = mcm.config
        }
    }
    page:createInfo{
        text = "Treats weapon crafting similar to repair tools, with a chance for failure and the destruction of the separate parts."
    }

    elementGroup = page:createSideBySideBlock()
    elementGroup:createButton{
        buttonText = "Print Registered Weapons to Log",
        callback = function()
            mwse.log("Smith Registered Weapons (" .. table.size(interop.weaponList) .. ")")
            for key, _ in pairs(interop.weaponList) do
                mwse.log("  - " .. key)
            end
            tes3.messageBox(table.size(interop.weaponList) .. " weapons printed to log.")
        end
    }
    elementGroup:createButton{
        buttonText = "Print Registered Weapon Details to Log",
        callback = function()
            mwse.log("Smith Registered Weapons (" .. table.size(interop.weaponList) .. ")")
            for key, value in pairs(interop.weaponList) do
                mwse.log("  - " .. key .. " = " .. json.encode(value))
            end
            tes3.messageBox(table.size(interop.weaponList) .. " weapon details printed to log.")
        end
    }
    
    elementGroup = page:createSideBySideBlock()
    elementGroup:createButton{
        buttonText = "Print Custom Weapons to Log",
        callback = function()
            if (tes3.player == nil) then
                tes3.messageBox("Try again in-game.")
            else
                mwse.log("Smith Custom Weapons (" .. table.size(tes3.player.data.sb_smith.weapons) .. ")")
                for key, _ in pairs(tes3.player.data.sb_smith.weapons) do
                    mwse.log("  - " .. key)
                end
                tes3.messageBox(table.size(tes3.player.data.sb_smith.weapons) .. " weapons printed to log.")
            end
        end
    }
    elementGroup:createButton{
        buttonText = "Print Custom Weapon Details to Log",
        callback = function()
            if (tes3.player == nil) then
                tes3.messageBox("Try again in-game.")
            else
                mwse.log("Smith Custom Weapons (" .. table.size(tes3.player.data.sb_smith.weapons) .. ")")
                for key, value in pairs(tes3.player.data.sb_smith.weapons) do
                    mwse.log("  - " .. key .. " = " .. json.encode(value))
                end
                tes3.messageBox(table.size(tes3.player.data.sb_smith.weapons) .. " weapon details printed to log.")
            end
        end
    }

    mwse.mcm.register(template)
end

function mcm.init()
    event.register("modConfigReady", registerModConfig)
end

return mcm