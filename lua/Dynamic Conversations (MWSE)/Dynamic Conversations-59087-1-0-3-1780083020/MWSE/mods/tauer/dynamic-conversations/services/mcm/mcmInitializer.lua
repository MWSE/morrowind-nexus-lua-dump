local settings = require("tauer.dynamic-conversations.services.mcm.mcmSettings")
local translations = require("tauer.dynamic-conversations.services.translations.translations")

local settingsPage = require("tauer.dynamic-conversations.services.mcm.pages.settingsPage")
local blacklistNpcsPage = require("tauer.dynamic-conversations.services.mcm.pages.blacklistNpcsPage")
local blacklistCellsPage = require("tauer.dynamic-conversations.services.mcm.pages.blacklistCellsPage")
local conversationHistoryPage = require("tauer.dynamic-conversations.services.mcm.pages.conversationHistoryPage")

local TRANSLATION_KEY = require("tauer.dynamic-conversations.services.translations.enums.TRANSLATION_KEY")

---@class mcmInitializer
local this = {}

---@private
---@type string
this.headerImagePath = "textures\\tauer\\dynamic-conversations\\header.tga"

--- @private
--- @type mcmPage[]
this.pages = {
    settingsPage,
    blacklistNpcsPage,
    blacklistCellsPage,
    conversationHistoryPage,
}

--- Initializes the MCM menu
--- @public
function this.initialize()
    local template = mwse.mcm.createTemplate {
        name = translations.get(TRANSLATION_KEY.mcmTitleLabel),
        headerImagePath = this.headerImagePath,
        onClose = this.onClose,
    }

    for _, page in ipairs(this.pages) do
        page.initialize(template)
    end

    template:register()
end

---@private
function this.onClose()
    settings:save()
end

return this
