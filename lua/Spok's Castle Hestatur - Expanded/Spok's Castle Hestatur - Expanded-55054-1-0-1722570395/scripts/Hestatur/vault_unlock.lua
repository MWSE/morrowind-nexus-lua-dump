local world = require("openmw.world")
local I = require("openmw.interfaces")
local util = require("openmw.util")
local core = require("openmw.core")
local types = require("openmw.types")
local async = require("openmw.async")
local anim = require('openmw.animation')
local lock1Unlocked = false
local lock2Unlocked = false
local lock3Unlocked = false
local lock4Unlocked = false

local vaultUnlocked = false

local messageVault1 = "The vault will only allow in, the Lord of Hestatur who posesses 100,000 septims."
local messageVault2 = "The vault will only allow in, the Lord of Hestatur who displays 4 suits of armor in this room, with great value."
local messageVault3 = "The vault will only allow in, the Lord of Hestatur who displays 10 artifacts, that would be displayed in a musuem."
local messageVault3 = "The vault will only allow in, the Lord of Hestatur who posesses 25 keys."

local function checkForRing(actor)
    local item = types.Actor.inventory():countOf("spok_ht_ring")
end
local function displayPlayerMessage(plr)
    
end

local function checkForVaultLock()
    lock1Unlocked =  world.mwscript.getGlobalVariables(world.players[1]).zhac_hest_vdoor1_state == 1
    lock2Unlocked =  world.mwscript.getGlobalVariables(world.players[1]).zhac_hest_vdoor2_state == 1
    lock3Unlocked =  world.mwscript.getGlobalVariables(world.players[1]).zhac_hest_vdoor3_state == 1
    lock4Unlocked =  world.mwscript.getGlobalVariables(world.players[1]).zhac_hest_vdoor4_state == 1
    local locked = true
    if not lock1Unlocked or not lock2Unlocked or not lock3Unlocked or not lock4Unlocked then
        locked = false
    end
    return locked
end

return {
    interfaceName = "Vault_Lock",
    interface = {
        isVaultLocked = function ()
            return checkForVaultLock()
        end
    },
    engineHandlers = {
        onSave = function ()
            return {
                vaultUnlocked = vaultUnlocked,
                lock1Unlocked = lock1Unlocked,
                lock2Unlocked = lock2Unlocked,
                lock3Unlocked = lock3Unlocked,
                lock4Unlocked = lock4Unlocked,

            }
        end,
        onLoad = function (data)
            if not data then
                return
            end
            vaultUnlocked = data.vaultUnlocked
            lock1Unlocked = data.lock1Unlocked
            lock2Unlocked = data.lock2Unlocked
            lock3Unlocked = data.lock3Unlocked
            lock4Unlocked = data.lock4Unlocked
        end
    }
}