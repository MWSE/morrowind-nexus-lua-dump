local storage = require 'openmw.storage'
local types = require 'openmw.types'

local I = require 'openmw.interfaces'
local Combat = I.Combat

local ModInfo = require 'scripts.s3.target.modinfo'
local LockOnSection = storage.globalSection('SettingsGlobal' .. ModInfo.name .. 'LockOnGroup')
local ErrorMessage =
'The S3lf interface is required to use T4rg3t5! You can get it here: https://www.nexusmods.com/morrowind/mods/56417'
Combat.addOnHitHandler(
    function(attackInfo)
        if
            not attackInfo.successful
            or not attackInfo.attacker
            or not types.Player.objectIsInstance(attackInfo.attacker)
            or not LockOnSection:get('EnableHitBounce')
        then
            return
        end

        assert(I.s3lf.gameObject, ErrorMessage)
        attackInfo.attacker:sendEvent('S3TargetLockHit', I.s3lf.gameObject)
    end
)
