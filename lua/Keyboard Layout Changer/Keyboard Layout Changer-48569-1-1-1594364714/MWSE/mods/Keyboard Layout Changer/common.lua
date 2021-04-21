local keys = require("Keyboard Layout Changer.keys")

local supportedLayouts = ""
for name, _ in pairs(keys) do supportedLayouts = supportedLayouts .. name .. " " end

local this = {}

this.modName = "Keyboard Layout Changer"
this.author = "Celediel"
this.version = "1.0.0"
this.configString = string.gsub(this.modName, "%s+", "")
this.modInfo = "Allows use of non-qwerty keyboard layouts.\n\nCurrently supported:\n" .. supportedLayouts

function this.log(str) mwse.log("[%s] %s", this.modName, str) end

function this.changeLayout(layout)
    if keys[layout] and (#keys[layout].lowercase == 256 and #keys[layout].uppercase == 256) then
        -- Thanks NullCascade
        mwse.memory.writeBytes({address = 0x775148, bytes = keys[layout].lowercase})
        mwse.memory.writeBytes({address = 0x775248, bytes = keys[layout].uppercase})
    else
        local message = "Bad keys.lua file, please re-install."
        this.log(message)
        tes3.messageBox(string.format("(%s) %s", this.modName, message))
    end
end

return this
