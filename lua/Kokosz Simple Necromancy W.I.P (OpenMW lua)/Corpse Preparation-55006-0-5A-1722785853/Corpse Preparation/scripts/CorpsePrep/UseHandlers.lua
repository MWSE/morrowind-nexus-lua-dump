local world = require("openmw.world")
local core = require("openmw.core")
local I = require("openmw.interfaces")
local types = require("openmw.types")
local anim = require('openmw.animation')
local fixedCell = false




local function useHandler(obj)
    print(obj.recordId)
    if obj.recordId == gemId then
        world.players[1]:sendEvent("OpenEnchantMenu", obj)
        return false
    end
    if obj.recordId == "ksn_misc_boneskelarmr" then
	core.sendGlobalEvent("OpenNecroCrafting")
    end
    if obj.recordId == "ksn_misc_boneskelpelvis" then
	core.sendGlobalEvent("OpenNecroCrafting")
    end
    if obj.recordId == "ksn_misc_boneskelskullupper" then
	core.sendGlobalEvent("OpenNecroCrafting")
    end
    if obj.recordId == "ksn_misc_boneskeltorso" then
	core.sendGlobalEvent("OpenNecroCrafting")
    end
    if obj.recordId == "ksn_misc_leg" then
	core.sendGlobalEvent("OpenNecroCrafting")
    end
    if obj.recordId == "ksn_misc_torsobroken" then
	core.sendGlobalEvent("OpenNecroCrafting")
    end

    if obj.recordId == "ksn_crippled_skeleton" then
	local PlayerInventory = types.Actor.inventory(world.players[1])
	local item = PlayerInventory:find('ksn_crippled_skeleton')
	item:remove('ksn_crippled_skeleton')
	core.sendGlobalEvent("SpawnProp", "KSN_Skeleton_Weak_PROP")
    end
end
        I.ItemUsage.addHandlerForType(types.Miscellaneous, useHandler)


