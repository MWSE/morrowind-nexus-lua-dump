local I = require('openmw.interfaces')
local vfs = require('openmw.vfs')

for path in vfs.pathsWithPrefix('scripts/niftyspellpack/effects/') do
    if path:match('config%.lua$') then
        local effectId = path:match('scripts/niftyspellpack/effects/(.-)/config%.lua$')
        if effectId then
            local settings = require('scripts.niftyspellpack.effects.' .. effectId .. '.config')
            I.Settings.registerGroup {
                key = 'Settings/NiftySpellPack/Effect_' .. effectId,
                page = 'NiftySpellPack',
                l10n = 'NiftySpellPack',
                name = 'effect_nsp_' .. effectId,
                permanentStorage = true,
                settings = settings,
            }
        end
    end
end