local types = require('openmw.types')
local core = require('openmw.core')
local I = require("openmw.interfaces")
local anim = require('openmw.animation')
local world = require('openmw.world')
local PlayerInventory = world.players[1]
local gemId = "ab_misc_soulgemblack_filled"
local function OnUpdate()
	for i, actor in ipairs(world.activeActors) do 	
		local isNpc = types.NPC.objectIsInstance(actor) 
			if isNpc == true then 
				local effect = types.Actor.activeEffects(actor):getEffect("soultrap")
				if effect.magnitude > 0 then
					local PlayerInventory = world.players[1]
					local BlackSoulGem = types.Actor.inventory(PlayerInventory):findAll('AB_Misc_SoulGemBlack')
					for i, gems in ipairs(BlackSoulGem) do
						local isDead = types.Actor.isDead(actor)
						if isDead == true then
							gems:remove(1)
							world.players[1]:sendEvent("ShowMessage", core.getGMST("sSoultrapSuccess"))
							money = world.createObject('AB_Misc_SoulGemBlack_Filled', 1)
							money.type.setSoul(money, "kokosz_Mortal_Soul")
							money:moveInto(types.Actor.inventory(PlayerInventory))
							effect = types.Actor.activeEffects(actor):remove("soultrap")
							world.players[1]:sendEvent("playSoundEvent", "conjuration hit")
							anim.addVfx(actor, "VFX_Soul_Trap")
						end

							
					end

				end
			end
	end
end

local function useHandler(obj)
    print(obj.recordId)
    print(BlackSoulGem)
    if obj.recordId == gemId then
        world.players[1]:sendEvent("OpenEnchantMenu", obj)
        return false
    end
end
        I.ItemUsage.addHandlerForType(types.Miscellaneous, useHandler)


return { engineHandlers = {onUpdate = OnUpdate} }
