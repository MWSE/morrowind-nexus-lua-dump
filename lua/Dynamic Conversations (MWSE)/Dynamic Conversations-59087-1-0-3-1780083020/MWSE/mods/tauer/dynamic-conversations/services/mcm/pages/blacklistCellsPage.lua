local translations = require("tauer.dynamic-conversations.services.translations.translations")
local settings = require("tauer.dynamic-conversations.services.mcm.mcmSettings")

local TRANSLATION_KEY = require("tauer.dynamic-conversations.services.translations.enums.TRANSLATION_KEY")

---@class blacklistCellsPage : mcmPage
local this = {}

---@private
---@param template mwseMCMTemplate
function this.initialize(template)
    template:createExclusionsPage({
        label = translations.get(TRANSLATION_KEY.blacklistedCellsTitleLabel),
        description = translations.get(TRANSLATION_KEY.blacklistedCellsDescription),
        leftListLabel = translations.get(TRANSLATION_KEY.blacklistedCellsLeftLabel),
        rightListLabel = translations.get(TRANSLATION_KEY.blacklistedCellsRightLabel),
        variable = mwse.mcm.createTableVariable {
            id = "blacklistedCells",
            table = settings.mcm,
        },
        filters = {
            {
                label = translations.get(TRANSLATION_KEY.blacklistedCellsRightLabel),
                callback = function()
                    local cells = tes3.dataHandler.nonDynamicData.cells

                    local cellNames = {}
                    for i = 1, table.size(cells) do
                        cellNames[i] = cells[i].id:lower()
                    end

                    table.sort(cellNames)
                    return cellNames
                end
            },
        },
    })
end

return this
