local core = require('openmw.core')

if core.API_REVISION < 39 then
    return
end

local storage = require('openmw.storage')
local ui = require('openmw.ui')

if core.contentFiles.has('TR_Mainland.esm') and not core.contentFiles.has('TR_Firemoth_remover.esp') then
    local miscSettings = storage.playerSection('Settings_TamrielRebuilt_Misc')
    
    if not miscSettings:get('FiremothComp') then
        return
    end
    local getActivePlugin = require('MWSE.mods.TamrielRebuilt.firemoth')
    local firemothPlugin = getActivePlugin(core.contentFiles.has)
    if firemothPlugin then
        local l10n = core.l10n('TamrielRebuilt')
        ui.showMessage(l10n('FiremothCompWarning', { plugin = firemothPlugin }))
    end
end