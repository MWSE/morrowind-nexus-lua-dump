local AttackDirection
local HitType
local HitTypeNew
local RageCounter
local config = require("OEA.OEA1 Neo.config")

local function RageFixer()
	if (tes3.player.data.OEA1 == nil) then
		tes3.player.data.OEA1 = {}
	end
	if (tes3.player.data.OEA1.RageData == nil) then
		tes3.player.data.OEA1.RageData = { [1] = 0 }
	end
end

local function HaveNotAttackedRecently()
	RageFixer()
	RageCounter = RageCounter - 1
	if (RageCounter ~= nil) then
		if (RageCounter <= 0) then
			HitTypeNew = 0
			HitType = 0
			tes3.player.data.OEA1.RageData[1] = tes3.player.data.OEA1.RageData[1] - 5
			if (tes3.player.data.OEA1.RageData[1] < 0) then
				tes3.player.data.OEA1.RageData[1] = 0
			end
			RageCounter = 10
		end
	end
end

local function OnSkill(e)
	RageFixer()

	if (AttackDirection == nil) or (AttackDirection == 0) then
		return
	end

	if (e.skill == tes3.skill.axe) or (e.skill == tes3.skill.bluntWeapon) or (e.skill == tes3.skill.longBlade) or (e.skill == tes3.skill.shortBlade) or (e.skill == tes3.skill.spear) then
		if (HitType ~= HitTypeNew) and (tes3.mobilePlayer.readiedWeapon ~= nil) then
			AttackDirection = 0
			--mwse.log("[Neo Combat] skilling HitType = %s", HitType)
			--mwse.log("[Neo Combat] skilling HitTypeNew = %s", HitTypeNew)
            		if (mwscript.getSpellEffects({reference = tes3.player, spell = "OEA1_Key_Rage" }) == true) then
                		return
           		end
			tes3.player.data.OEA1.RageData[1] = tes3.player.data.OEA1.RageData[1] + 1
		end
	end
end

local function KeyDown(e)
	RageFixer()
	local RageLevel = tes3.player.data.OEA1.RageData[1]

	if (e.keyCode == config.attackKey3.keyCode) and not tes3.menuMode() then
		if (mwscript.getSpellEffects({ reference = tes3.player, spell = "OEA1_Key_Rage" }) == true) then
			return
		end
		if ( RageLevel < 25 ) then
			tes3.messageBox(("You only have %s Rage. You need 25 Rage to use this power."):format(RageLevel))
		elseif ( RageLevel >= 25 ) then
			RageLevel = ( RageLevel - 25 )
			tes3.player.data.OEA1.RageData[1] = RageLevel
		    	tes3.cast({ reference = "lord cluttermonkey", target = tes3.player, spell = "OEA1_Key_Rage" })
		    	tes3.messageBox("You are now activating Rage.")
	    	end
	end
end

local function OnAttack(e)
	RageFixer()

	if (e.reference == tes3.player) then
		AttackDirection = tes3.mobilePlayer.actionData.attackDirection
		HitType = HitTypeNew or 0
		HitTypeNew = AttackDirection
		--mwse.log("[Neo Combat] attacking HitType = %s", HitType)
		--mwse.log("[Neo Combat] attacking HitTypeNew = %s", HitTypeNew)
		RageCounter = 10
	else
		return
	end
	if (HitType ~= HitTypeNew) and (tes3.mobilePlayer.readiedWeapon ~= nil) then
            	if (mwscript.getSpellEffects({reference = tes3.player, spell = "OEA1_Key_Rage" }) == true) then
                	return
           	end
		tes3.player.data.OEA1.RageData[1] = tes3.player.data.OEA1.RageData[1] + 1
	end
end

local function OnCell(e)
	if (e.previous ~= nil) then
		return
	end
	RageCounter = 10
	HitType = 0
	HitTypeNew = 0
	local timer2 = timer.start({ duration = 1, callback = HaveNotAttackedRecently, iterations = -1 })
end

event.register("attack", OnAttack)
event.register("keyDown", KeyDown)
event.register("exerciseSkill", OnSkill)
event.register("cellChanged", OnCell)