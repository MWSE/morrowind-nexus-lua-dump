local mod = {
    name = "What Ails You",
    ver = "1.0.2",
    author = "Shanjaq",
}

local vanillaDialog = require("shan.comp_ailments.vanillaDialog")
local logging = require("logging.logger")


local configPath = "What Ails You"
local defaultConfig = { enabled = true, fromDialog = true, fromShare = true }
local config = mwse.loadConfig(configPath, defaultConfig)

---@type mwseLogger
local log = logging.new({
	name = "What Ails You",
	logLevel = "INFO",
})


-- ============================================================================
-- EVENT HANDLING
-- ============================================================================

local function onMenuDialog(e)
    local dialogMenu = tes3ui.findMenu(tes3ui.registerID("MenuDialog"))
    local shareMenu = tes3ui.findMenu(tes3ui.registerID("MenuContents"))
    
    
    if not config.enabled then
        return
    elseif not config.fromShare and shareMenu then
        return
    elseif not config.fromDialog and dialogMenu and not shareMenu then --Dialog is always showing
        return
    end
    
    if e.newlyCreated then
        local actor = tes3ui.getServiceActor()
        if not actor then return end

        local isFollower = false
        for mobileActor in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
            if mobileActor.reference.id == actor.reference.id then
                isFollower = true
            end
        end
        if not isFollower then return end

        -- Find main panel and append below dialogue section
        vanillaDialog.updateVanillaDialog(actor)
    end
end



local function initialized(e)
    if not config.enabled then
        return
    end
    event.register(tes3.event.uiActivated, onMenuDialog, {filter = "MenuDialog"})
    event.register(tes3.event.uiActivated, onMenuDialog, {filter = "MenuContents"})
end
event.register(tes3.event.initialized, initialized)


local function onModConfigReady()
    local template = mwse.mcm.createTemplate(
        { name = "What Ails You" })
    template:saveOnClose(configPath, config)
    template:register()

    local settings = template:createSideBarPage({ label = "Settings" })
    settings.sidebar:createInfo({
        -- This text will be on the right-hand side block
        text = "What Ails You\n\nCreated by Shanjaq.\n\n" ..
        "This mod allows you check the status effects on your companions through either the dialog or share window.",
    })

    settings:createOnOffButton({
        label = "Enable Mod",
        variable = mwse.mcm.createTableVariable({
            id = "enabled",
            table = config,
            restartRequired = true,
        }),
    })
    settings:createOnOffButton({
        label = "Show in Dialog Window",
        variable = mwse.mcm.createTableVariable({
            id = "fromDialog",
            table = config,
            restartRequired = false,
        }),
    })
    settings:createOnOffButton({
        label = "Show in Share Window",
        variable = mwse.mcm.createTableVariable({
            id = "fromShare",
            table = config,
            restartRequired = false,
        }),
    })
end
event.register(tes3.event.modConfigReady, onModConfigReady)
