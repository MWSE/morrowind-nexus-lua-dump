--[[ 
	Greater Statue Debuff
]]--
local debug = false
local function debugMessage(string)
	if debug then
		tes3.messageBox(string)
		mwse.log("[radiant common: DEBUG] " .. string)
	end
end


local debuffSpell = "sx1_greater_curse"
local statueID = "sx1_greater"

local cursed

local function addDebuff()
	if not cursed then	
		mwscript.addSpell({reference = tes3.player, spell = debuffSpell})
		tes3.messageBox("Your head fills with whispers of ash and darkness")
		cursed = true
	end
end

local function removeDebuff()
	if cursed then
		mwscript.removeSpell({reference = tes3.player, spell = debuffSpell})
		tes3.messageBox("The whispers in your head have been silenced")
		cursed = false
	end
end

local function cellChange(e)
	local hasStatue = false
	if e.cell.isInterior then
		for ref in e.cell:iterateReferences(tes3.objectType.creature) do
			if ref.id:find(statueID) and ( not ref.disabled ) then 
				hasStatue = true
			end
		end
	end
	if hasStatue then
		addDebuff()
	else
		removeDebuff()
	end
end

--[[
	Greater Statues can only be damaged using a 6th House Hammer
	]]--

local attackCount = 0
local function onDamage(e)
	if e.reference.object.id:find("sx1_greater") then
		if tes3.player.mobile.readiedWeapon.object.id ~= "6th bell hammer" then
			tes3.messageBox("Your attacks are ineffective!")
			attackCount = attackCount + 1
			if attackCount >= 10 then
				attackCount = 0
				local message = "Your attacks are ineffective. You need to find another way to destroy the statue."
				tes3.messageBox{
					message = message,
					buttons = {"Okay"}
				}
			end
			e.damage = 0
		else
			tes3.playSound({reference=tes3.player, sound="Heavy Armor Hit"})
		end
	end
end

local function onAttack(e)
	if e.targetReference and e.targetReference.object.id:find("sx1_greater") then
		if tes3.player.mobile.readiedWeapon.object.id == "6th bell hammer" then
			e.mobile.actionData.physicalDamage = 25
		end
	end
end

local function onDeath(e)
	if e.reference.object.id:find("sx1_greater") then
		--Outside statues
		if not tes3.getPlayerCell().isInterior then
			tes3.fadeOut()
			timer.start({ timer.real, duration = 1.5, callback = 
				function()
					tes3.fadeIn()
					tes3.getWorldController().weatherController:switchImmediate   ( tes3.weather.clear )
					debugMessage("Statue died, sending Trigger")
					event.trigger("Radiant:statueKilled", { reference = e.reference } )
				end
			})
		--inside statues
		else
			removeDebuff()
		end
	end
end

event.register( "attack", onAttack, { filter = tes3.player } )
event.register( "damage", onDamage )
event.register( "death", onDeath )
event.register("cellChanged", cellChange )