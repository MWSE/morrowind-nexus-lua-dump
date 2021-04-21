local mod = "No Auto Vanity Camera"
local version = "1.1"

local config = require("NoAutoVanityCam.config")

local function createPage(template)
    local page = template:createSideBarPage{
        description =
            mod .. "\n" ..
            "Version " .. version .. "\n" ..
            "\n" ..
            "This mod essentially disables automatic switching to vanity camera due to inactivity by setting the vanity timeout to a very large value.",
    }

    page:createTextField{
        label = "Vanity timeout",
        description =
            "This setting allows you to customize the length of time in seconds during which there must be no control input before the vanity camera is activated.\n" ..
            "\n" ..
            "Vanilla Morrowind's default value for this setting is 30 seconds. This mod uses 30000 seconds by default, which essentially disables it.\n" ..
            "\n" ..
            "Default: 30000",
        numbersOnly = true,
        variable = mwse.mcm.createTableVariable{
            id = "vanityTimeout",
            table = config,
        },
        defaultSetting = 30000,
        callback = function()
            local timeout = tonumber(config.vanityTimeout)
            tes3.findGMST(tes3.gmst.fVanityDelay).value = timeout
            tes3.messageBox("New value: \'%.0f\'", timeout)
        end,
    }

    return page
end

local template = mwse.mcm.createTemplate("No Auto Vanity Camera")
template:saveOnClose("NoAutoVanityCam", config)

createPage(template)

mwse.mcm.register(template)