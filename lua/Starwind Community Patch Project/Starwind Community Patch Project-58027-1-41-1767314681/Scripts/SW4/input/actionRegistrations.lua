local input = require('openmw.input')

local ModInfo = require 'Scripts.SW4.modinfo'

local Actions = {
    {
        key = 'SW4_TargetLock',
        type = input.ACTION_TYPE.Boolean,
        l10n = ModInfo.l10nName,
        name = 'Target Lock Toggle',
        description = 'Manually engages target locking',
        defaultValue = false,
    },
}

for _, action in ipairs(Actions) do
    input.registerAction(action)
end
