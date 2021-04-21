--[[
	Refresh Magic Quill using inkwell
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
	
local inkwellReference
local ignoreActivateEvent

local bCreate = "Create Magic Quill"
local bPickup = "Pick up"
local bCancel = "Do nothing"
local menuButtons = { bCreate, bPickup, bCancel }
	
local function pickUp()
    -- delay to prevent activation while menu mode
    timer.delayOneFrame(
        function ()
            -- bypass the event
            tes3.player:activate(inkwellReference)
        end
    )
end

local function doMakeQuill()
	local scrollList = mwse.loadConfig("mmm2018/sx2/scrolls").scrollIds
	local skill = skillModule.getSkill(common.inscriptionSkillId).value or 5
	debugMessage("Skill: " .. skill)
	--calculate chance to succeed
	mwscript.explodeSpell({ reference = inkwellReference, spell = "dispel" })
	skillModule.incrementSkill( common.inscriptionSkillId, { progress = 35 } )
	mwscript.removeItem({ reference = tes3.player, item = "Misc_Quill", count = 1 })
	mwscript.addItem({ reference = tes3.player, item = common.itemIds.quill, count = 1 })
	tes3.messageBox("You have created a Magic Quill.")
end
	
	
local function onMenuSelect(e)
	local result = menuButtons[e.button + 1]
	if 		result 	== bCreate then
		doMakeQuill()
	elseif 	result 	== bPickup then
		ignoreActivateEvent = 1
		pickUp()
	elseif 	result 	== bCancel then
		return
	end
end	
	
	
local function activateInkwell(e)
	if tes3.getGlobal(common.globalIds.inscriptionSkill) == 1  then
		if e.target.object.id == "Misc_Inkwell" then
			if mwscript.getItemCount({ reference = tes3.player, item = "Misc_Quill" }) > 0 then
				debugMessage("Have quill")
	
				inkwellReference = e.target
				
				if ignoreActivateEvent == 1 then
					debugMessage("Ignoring activate")
					ignoreActivateEvent = nil
					return
				end
				tes3.messageBox({
					message = "Inkwell",
					buttons = menuButtons,
					callback = onMenuSelect,
				})
				return false
			end
		end
	end
end	
	
event.register("activate", activateInkwell)