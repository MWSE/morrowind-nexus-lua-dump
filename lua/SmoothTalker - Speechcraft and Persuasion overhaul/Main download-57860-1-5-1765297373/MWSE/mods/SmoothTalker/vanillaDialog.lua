--[[
    Vanilla Dialog Integration Module
    Handles integration with Morrowind's vanilla dialogue system
]]

local patience = require("SmoothTalker.patience")
local config = require("SmoothTalker.config")
local unlocks = require("SmoothTalker.unlocks")
local npcParams = require("SmoothTalker.npcParams")

local vanillaDialog = {}

-- This is needed to check whether we're talking to a hostile NPC when exiting dialog menu
local HostileNPCSpeaker = nil

-- Get the NPC reference from the dialog menu
function vanillaDialog.getNpcRefFromDialog()
	local dialogMenu = tes3ui.findMenu(tes3ui.registerID("MenuDialog"))
	if not dialogMenu then return nil end

	local actor = dialogMenu:getPropertyObject("PartHyperText_actor")
	if not actor or not actor.reference then return nil end

	return actor.reference
end

-- This event is only registered while dialog menu is open, so we can assume that the menu we're closing is DialogMenu
function vanillaDialog.exitMenu(e)
	if HostileNPCSpeaker then
		HostileNPCSpeaker.object.mobile:stopCombat(true)
		HostileNPCSpeaker = nil
	end

    event.unregister(tes3.event.menuExit, vanillaDialog.exitMenu)
end

--- Check if player is looking at an NPC in activation range.
--- If pressing the button doesn't start dialogue normally, register NPC as hostile and start dialogue regardless. 
--- @param e onKeyEventData (unused)
function vanillaDialog.checkForCombatNPCs(e)
    -- Fail fast if not eligible for combat dialogue (sneaking or too low level) - this is to prevent expensive rayTest calls
	if tes3.mobilePlayer.isSneaking then return end

	if not unlocks.isUnlocked(unlocks.FEATURE.COMBAT_PERSUASION) then
		return
	end

    -- Check if something within activation range
	local hitResult = tes3.rayTest({ position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector(), maxDistance = tes3.getPlayerActivationDistance() })
	local hitReference = hitResult and hitResult.reference
	if (hitReference == nil) then
		return
	end

    -- Check if it's an NPC
	if not hitReference.object.baseObject then return end
	if hitReference.object.baseObject.objectType ~= tes3.objectType.npc then return end

	-- Check if we managed to open a menu in 2 frames. If we didn't it means it's a hostile (or in-combat) NPC, and we force dialogue
	timer.frame.delayOneFrame(function()
		timer.frame.delayOneFrame(function()
			if not tes3.menuMode() then
				if patience.isDepleted(hitReference) then
					tes3.messageBox("This person refuses to talk to you anymore.")
					return
				end

				patience.modPatience(hitReference, -4)
				HostileNPCSpeaker = hitReference
				hitReference.object.mobile:startDialogue()
			end
		end)
	end)
end

--- Check if there's an active dialogue choice in the vanilla dialog menu
--- @return boolean True if there's an active choice
function vanillaDialog.hasActiveDialogueChoice()
    local menu = tes3ui.findMenu(tes3ui.registerID("MenuDialog"))
    if not menu then return false end
    return menu:findChild(tes3ui.registerID("MenuDialog_answer_block")) ~= nil
end

--- Close the persuasion menu if it exists
function vanillaDialog.closePersuasionMenu()
    local persuasionMenu = tes3ui.findMenu("MenuPersuasionImproved")
    if persuasionMenu then
        persuasionMenu:destroy()
    end
end

--- Trigger vanilla persuasion dialogue responses and scripts
--- Returns the dialogue text if quest-related, nil otherwise
--- @param npcRef tes3reference The NPC reference
--- @param actionName string The action name ("Admire", "Intimidate", etc.)
--- @param success boolean Whether the persuasion was successful
--- @return string|nil The dialogue text if quest-related, nil otherwise
function vanillaDialog.triggerVanillaPersuasionResponse(npcRef, actionName, success)
    local pages = {
        Admire = { success = tes3.dialoguePage.service.admireSuccess, failure = tes3.dialoguePage.service.admireFailure },
        Intimidate = { success = tes3.dialoguePage.service.intimidateSuccess, failure = tes3.dialoguePage.service.intimidateFailure },
        Taunt = { success = tes3.dialoguePage.service.tauntSuccess, failure = tes3.dialoguePage.service.tauntFailure },
        Placate = { success = tes3.dialoguePage.service.placateSuccess, failure = tes3.dialoguePage.service.placateFailure },
        Bribe = { success = tes3.dialoguePage.service.bribeSuccess, failure = tes3.dialoguePage.service.bribeFailure }
    }

    local pageId = pages[actionName][success and "success" or "failure"]
    if not pageId then
        return nil
    end

    local dialogue = tes3.findDialogue({ type = tes3.dialogueType.service, page = pageId })
    if not dialogue then
        return nil
    end

    local info = dialogue:getInfo({ actor = npcRef })
    if not info then
        return nil
    end

    local text = info.text
    if not (text and text ~= "") then
        return nil
    end

    info:runScript(npcRef)

    -- Only return text for quest-related responses
    if info.actor or info.cell or info.journalIndex or info.isQuestName then
        return text:gsub("[@#]", "")
    end

    return nil
end

--- Update the status bars in the vanilla dialogue window
--- @param npcRef tes3reference The NPC reference
function vanillaDialog.updateVanillaBars(npcRef)
    local menu = tes3ui.findMenu(tes3ui.registerID("MenuDialog"))
    if not menu then return end

    local dispositionOld = menu:findChild(tes3ui.registerID("MenuDialog_disposition"))
    local parent = dispositionOld.parent

    -- Hide vanilla disposition bar
    dispositionOld.visible = false

    -- Create/update custom disposition bar
    local disposition = menu:findChild(tes3ui.registerID("MenuDialog_disposition2"))
    if disposition then
        disposition:destroy()
    end
    disposition = parent:createFillBar{id = tes3ui.registerID("MenuDialog_disposition2"), current = npcRef.object.disposition, max = 100}
    disposition.width = dispositionOld.width
    disposition.height = 19
    disposition.borderAllSides = 4
    disposition:findChild(tes3ui.registerID("PartFillbar_text_ptr")).text = "Disposition"
    disposition.widget.fillColor = tes3ui.getPalette("magic_color")
    disposition.visible = unlocks.isUnlocked(unlocks.FEATURE.STATUS_DISPOSITION)
    disposition:reorder({ after = dispositionOld })

    -- Create/update patience bar
    local patienceBar = menu:findChild(tes3ui.registerID("MenuDialog_patience"))
    if patienceBar then
        patienceBar:destroy()
    end
    patienceBar = parent:createFillBar{id = tes3ui.registerID("MenuDialog_patience"), current = patience.getPatience(npcRef), max = 100}
    patienceBar.width = dispositionOld.width
    patienceBar.height = 19
    patienceBar.borderLeft = 4
    patienceBar.borderBottom = 4
    patienceBar:findChild(tes3ui.registerID("PartFillbar_text_ptr")).text = "Patience"
    patienceBar.widget.fillColor = tes3ui.getPalette("magic_color")
    patienceBar.visible = config.showVanillaBarPatience and unlocks.isUnlocked(unlocks.FEATURE.STATUS_PATIENCE)
    patienceBar:reorder({ after = disposition })

    -- Create/update fight bar
    local fightBar = menu:findChild(tes3ui.registerID("MenuDialog_fight"))
    if fightBar then
        fightBar:destroy()
    end
    fightBar = parent:createFillBar{id = tes3ui.registerID("MenuDialog_fight"), current = npcRef.mobile.fight, max = 100}
    fightBar.width = dispositionOld.width
    fightBar.height = 19
    fightBar.borderLeft = 4
    fightBar.borderBottom = 4
    fightBar:findChild(tes3ui.registerID("PartFillbar_text_ptr")).text = "Fight"
    fightBar.widget.fillColor = tes3ui.getPalette("health_color")
    fightBar.visible = config.showVanillaBarFight and unlocks.isUnlocked(unlocks.FEATURE.STATUS_FIGHT)
    fightBar:reorder({ after = patienceBar })

    -- Create/update alarm bar
    local alarmBar = menu:findChild(tes3ui.registerID("MenuDialog_alarm"))
    if alarmBar then
        alarmBar:destroy()
    end
    alarmBar = parent:createFillBar{id = tes3ui.registerID("MenuDialog_alarm"), current = npcRef.mobile.alarm, max = 100}
    alarmBar.width = dispositionOld.width
    alarmBar.height = 19
    alarmBar.borderLeft = 4
    alarmBar.borderBottom = 4
    alarmBar:findChild(tes3ui.registerID("PartFillbar_text_ptr")).text = "Alarm"
    alarmBar.widget.fillColor = tes3ui.getPalette("fatigue_color")
    alarmBar.visible = config.showVanillaBarAlarm and unlocks.isUnlocked(unlocks.FEATURE.STATUS_ALARM)
    alarmBar:reorder({ after = fightBar })

    -- Create/update flee bar
    local fleeBar = menu:findChild(tes3ui.registerID("MenuDialog_flee"))
    if fleeBar then
        fleeBar:destroy()
    end
    fleeBar = parent:createFillBar{id = tes3ui.registerID("MenuDialog_flee"), current = npcRef.mobile.flee, max = 100}
    fleeBar.width = dispositionOld.width
    fleeBar.height = 19
    fleeBar.borderLeft = 4
    fleeBar.borderBottom = 4
    fleeBar:findChild(tes3ui.registerID("PartFillbar_text_ptr")).text = "Flee"
    fleeBar.widget.fillColor = tes3ui.getPalette("magic_color")
    fleeBar.visible = config.showVanillaBarFlee and unlocks.isUnlocked(unlocks.FEATURE.STATUS_FLEE)
    fleeBar:reorder({ after = alarmBar })
end

--- Handle info response to close persuasion menu on choice/goodbye
--- @param e infoResponseEventData
function vanillaDialog.onInfoResponse(e)
    local command = e.command
    if not command then return end

    command = string.lower(command)

    if string.match(command, "choice") or string.match(command, "goodbye") then
        vanillaDialog.closePersuasionMenu()
    end
end

function vanillaDialog.postInfoResponseUpdate(e)
    -- Update vanilla bars when info response triggers (catches disposition changes from dialogue)
    local npcRef = vanillaDialog.getNpcRefFromDialog()
    if npcRef then
        vanillaDialog.updateVanillaBars(npcRef)
    end
end
return vanillaDialog
