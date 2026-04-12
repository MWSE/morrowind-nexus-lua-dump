local core = require('openmw.core')
local I = require("openmw.interfaces")

local mDef = require('scripts.SBMR.config.definition')
local mH = require("scripts.SBMR.util.helpers")

local L = core.l10n(mDef.MOD_NAME)
local API
local C
local BASE
local currRegen = 0

local module = {}

local function getMagickaTooltipDescription()
    local description = { L(C.Strings.MAGICKA_DESC) }
    table.insert(description, L("tooltipMagickaCurrRegen", { value = mH.round(currRegen, 1) }))
    return table.concat(description, "\n\n")
end

local function setMagicka()
    API.modifyLine(C.DefaultLines.MAGICKA, {
        tooltip = function()
            return API.TooltipBuilders.ICON({
                icon = { bgr = 'icons/k/magicka.dds' },
                title = C.Strings.MAGICKA,
                description = getMagickaTooltipDescription(),
            })
        end,
    })
end

module.setCurrPlayerRegen = function(regen)
    currRegen = regen
end

module.setStatsWindow = function()
    API = I.StatsWindow
    C = API.Constants
    BASE = API.Templates.BASE
    setMagicka()
end

return module