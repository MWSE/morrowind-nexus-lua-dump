local translations = require("tauer.dynamic-conversations.services.translations.translations")
local settings = require("tauer.dynamic-conversations.services.mcm.mcmSettings")

local TRANSLATION_KEY = require("tauer.dynamic-conversations.services.translations.enums.TRANSLATION_KEY")

---@class blacklistNpcsPage : mcmPage
local this = {}

function this.initialize(template)
    template:createExclusionsPage({
        label = translations.get(TRANSLATION_KEY.blacklistedNpcsTitleLabel),
        description = translations.get(TRANSLATION_KEY.blacklistedNpcsDescription),
        leftListLabel = translations.get(TRANSLATION_KEY.blacklistedNpcsLeftLabel),
        rightListLabel = translations.get(TRANSLATION_KEY.blacklistedNpcsRightLabel),
        variable = mwse.mcm.createTableVariable {
            id = "blacklistedNpcs",
            table = settings.mcm,
        },
        filters = {
            {
                label = translations.get(TRANSLATION_KEY.blacklistedNpcsRightLabel),
                callback = function()
                    local npcs = {}

                    --- @param npc tes3npc
                    for npc in tes3.iterateObjects(tes3.objectType.npc) do
                        if not npc.isInstance then
                            table.insert(npcs, npc.id:lower())
                        end
                    end

                    table.sort(npcs)
                    return npcs
                end
            },
        },
    })
end

return this
