--[[ 
	Inscription
	While you have a Magic Quill equipped, activate a piece of paper
		to attempt to create a random magic scroll
]]--
local debug = false
local function debugMessage(string)
	if debug then
		tes3.messageBox(string)
		print("[Demon of Knowledge: DEBUG] " .. string)
	end
end	
	
	
local common = require("MMM2018.sx2.common")
local skillModule = require("OtherSkills.skillModule")
	
local paperReference
local ignoreActivateEvent

local bInscribe = "Inscribe"
local bPickup = "Read"
local bCancel = "Do nothing"
local menuButtons = { bInscribe, bPickup, bCancel }
	
local function pickUp()
    -- delay to prevent activation while menu mode
    timer.delayOneFrame(
        function ()
            -- bypass the event
            tes3.player:activate(paperReference)
        end
    )
end

local function doInscribe()
	local scrollList = mwse.loadConfig("mmm2018/sx2/scrolls").scrollIds
	local skill = skillModule.getSkill(common.inscriptionSkillId).value or 5
	debugMessage("Skill: " .. skill)
	--calculate chance to succeed
	if math.random(150) <= ( skill + 50 ) then
		mwscript.explodeSpell({ reference = paperReference, spell = "dispel" })
		skillModule.incrementSkill( common.inscriptionSkillId, { progress = 20 } )
		--pick random scroll
		local chosenScroll = scrollList[ math.random( #scrollList ) ]
		tes3.messageBox("You have successfully created " .. tes3.getObject(chosenScroll).name ..".")
		mwscript.addItem({ reference = tes3.player, item = chosenScroll })
	else
		tes3.playSound({ reference = tes3.player, sound="enchant fail" })
		tes3.messageBox("Your inscription failed.")
	end
	mwscript.disable({ reference = paperReference })
end
	
	
local function onMenuSelect(e)
	local result = menuButtons[e.button + 1]
	if 		result 	== bInscribe then
		doInscribe()
		
	elseif 	result 	== bPickup then
		ignoreActivateEvent = 1
		pickUp()
		
	elseif 	result 	== bCancel then
		return
	end
end	
	
	
local function activatePaper(e)
	if tes3.player.mobile.readiedWeapon and tes3.player.mobile.readiedWeapon.object.id == common.itemIds.quill then
		debugMessage("Have quill")
		if tes3.getMobilePlayer().weaponReady then
			debugMessage("weaponReady")
			if tes3.getGlobal(common.globalIds.inscriptionSkill) == 1  then
				if e.target.object.id == "sc_paper plain" then
					paperReference = e.target
					
					if ignoreActivateEvent == 1 then
						debugMessage("Ignoring activate")
						ignoreActivateEvent = nil
						return
					end
					tes3.messageBox({
						message = "Blank parchment",
						buttons = menuButtons,
						callback = onMenuSelect,
					})
					return false
				end
			end
		end
	end
end	
	

event.register("activate", activatePaper )