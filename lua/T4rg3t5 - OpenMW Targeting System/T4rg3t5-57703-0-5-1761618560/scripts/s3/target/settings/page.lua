local input = require 'openmw.input'

local I = require 'openmw.interfaces'
local ModInfo = require 'scripts.s3.target.modInfo'

I.Settings.registerPage {
    key = ModInfo.name,
    l10n = ModInfo.l10nName,
    name = 'TargetLockPageName',
    description = 'TargetLockPageDescription',
}

input.registerTrigger {
    key = 'S3TargetLock',
    l10n = ModInfo.l10nName,
    name = 'TargetLockActionName',
    description = 'TargetLockActionDesc',
}
