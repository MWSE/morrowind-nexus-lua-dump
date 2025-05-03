local types = require("openmw.types")
local I = require("openmw.interfaces")
local world = require("openmw.world")
local core = require("openmw.core")
local storage = require("openmw.storage")

local configGlobal = require('scripts.OblivionLockpicking.config.global')

return {
    eventHandlers = {
        LockpickSuccess = function(data)
            if data.probe then
                types.Lockable.setTrapSpell(data.target, nil)
                core.sound.playSoundFile3d("sound/Fx/disarm.wav", data.target)
            else
                types.Lockable.unlock(data.target)
                core.sound.playSoundFile3d("sound/OblivionLockpicking/lock_success.wav", data.target, { volume = 2.0 })
            end
        end,
        PlayerLockpicking = function(data)
            local crimeInfo = {
                type = types.Player.OFFENSE_TYPE.Trespassing,
            }
            if data.faction then
                crimeInfo.faction = data.faction
            end
            local startingCrime = types.Player.getCrimeLevel(data.player)
            if I.Crimes.commitCrime(data.player, crimeInfo) then
                if types.Player.getCrimeLevel(data.player) > startingCrime then
                    data.player:sendEvent("PlayerLockpickingSeen")
                end
            end
        end,
        DrainLockpick = function(data)
            local lockpick = types.Actor.getEquipment(data.player, types.Actor.EQUIPMENT_SLOT.CarriedRight)
            types.Item.itemData(lockpick).condition = types.Item.itemData(lockpick).condition - 1
            if types.Item.itemData(lockpick).condition <= 0 then
                lockpick:remove()
            end
        end,
        PauseWorldLockpicking = function(data)
            if data.paused and configGlobal.options.b_PauseTime then
                world.pause('PlayerLockpicking')
            else
                world.unpause('PlayerLockpicking')
            end
        end
    }
}