local log = mwse.Logger.new()
log.level = "DEBUG"
local i18n = require("alchemyFiltering.i18n")
local config = require("alchemyFiltering.config")
local chooser = require("alchemyFiltering.chooser")
local selecter = require("alchemyFiltering.selecter")

-- This isn't actually needed for the mod to work, but it is useful for
-- debugging when your character gains alchemy skill causing more effects
-- to be visible, thus repopulating the chooser panes
local function onAlchemyRaised()
    if not config.modEnabled then return end
    log:debug("Alchemy raised")

    -- log:debug("Bump to skill 61")
    -- tes3.mobilePlayer.alchemy.current = 61
end

local function onModConfigEntryClosed()
    chooser:onModConfigEntryClosed()
    selecter:onModConfigEntryClosed()
end

local function onInitialized(e)
    chooser:init()
    selecter:init(chooser)
    if config.modEnabled then
        log:debug("enabled")
    else
        log:debug("disabled")
        chooser.data.active = false
    end
    event.register("modConfigEntryClosed", onModConfigEntryClosed, {filter = i18n("mcm.modName")})
    -- event.register("skillRaised", onAlchemyRaised, {filter = tes3.skill.alchemy})
end

event.register("initialized", onInitialized)
