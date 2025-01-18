local skillModule = require("OtherSkills.skillModule")
local strings = require("NecroCraft.strings")
local bones = require("NecroCraft.bones")
local undead = require("NecroCraft.undead")
local common  = require("NecroCraft.common")
local utility = require("NecroCraft.utility")
local recipes = require("NecroCraft.crafting.recipes")

local this = {}

local function getCorpseType(object)
	if object.objectType == tes3.objectType.npc then
		if object.race.id == "skeletonrace" then
			return "skeletonChampion"
		else
			return "npc"
		end
	elseif string.startswith(object.id, "BM_wolf_") or string.startswith(object.id, "NC_bonewolf") then
		return "wolf"
	end
	return undead.getType(object)
end

local function buttonSwitch(button, corpseType)
	local function altDown(e)
		if not tes3.menuMode() then return end
		if button.text == strings.dispose then
			if corpseType ~= "wolf" then
				button.text = strings.harvest
			else
				button.text = strings.prepare
			end
		elseif button.text == strings.harvest then
			if corpseType == "npc" or corpseType == "bonewalker" or corpseType == "greaterBonewalker" then
				button.text = strings.prepare
			else
				button.text = strings.dispose
			end
		elseif button.text == strings.prepare then
			button.text = strings.dispose
		end
	end
	event.register("keyDown", altDown, { filter = tes3.scanCode.lAlt })
	timer.start{
		duration = 0.5,
		callback = function()
			event.unregister("keyDown", altDown, { filter = tes3.scanCode.lAlt })
		end
	}
end

local MAX_PROGRESS_DEFAULT = 30
local MAX_SKILL_DIFF = 40

local practiceSkill = function(difficulty)
	local skill = skillModule.getSkill("NC:CorpsePreparation")
	local current = skill.value
    local required = difficulty
    local difference = math.clamp(current - required, 0, MAX_SKILL_DIFF)
    local differenceMulti = (MAX_SKILL_DIFF-difference) / MAX_SKILL_DIFF
    local progress = differenceMulti * MAX_PROGRESS_DEFAULT
    skill:progressSkill(progress)
end

local function restoreBody(reference)
	local new = tes3.createReference{
        object = reference.baseObject,
        position = reference.position,
		orientation = reference.orientation,
        cell = reference.cell,
    }
	for _, stack in pairs(new.object.inventory) do
		tes3.removeItem{reference=new, item=stack.object, count=stack.count, playSound=false}
	end
	-- if reference.data and reference.data.necroCraft then
	-- 	new.data.necroCraft = reference.data.necroCraft
	-- 	new.data.necroCraft.isBeingRaised = nil
	-- end
	for _, stack in pairs(reference.object.inventory) do
		tes3.transferItem{from=reference, to=new, item=stack.object, count=stack.count, playSound=false}
	end
	reference:disable()
    -- timer.delayOneFrame(function()
    --   reference:delete()
    -- end)
	-- utility.safeDelete(reference)
	-- tes3.playAnimation{reference = new, group = tes3.animationGroup.knockOut, startFlag = tes3.animationStartFlag.immediateLoop}
	-- new.mobile.paralyze = 1
	-- tes3.playAnimation{reference = new, group=tes3.animationGroup.idle, startFlag=tes3.animationStartFlag.normal}
end

this.onCorpseContents = function(ev, reference)
	local menu = ev.element
	local button = menu:findChild(tes3ui.registerID("MenuContents_removebutton"))
	if not button then return end
	local corpseType = getCorpseType(reference.object.baseObject)
	if not corpseType then
		return
	end
	buttonSwitch(button, corpseType)
	local doOnce = function(e)
		button:unregister("mouseClick", doOnce)
		local behaviour = button.text
		tes3ui.leaveMenuMode()
		timer.delayOneFrame(function()
			if behaviour == strings.dispose then
				utility.disposeCorpse(reference)
			elseif behaviour == strings.harvest then
				practiceSkill(0)
				bones.harvest(corpseType)
				utility.disposeCorpse(reference)
				tes3.triggerCrime({
					criminal = tes3.player,
					type = tes3.crimeType.killing,
					value = common.config.bountyValue
				})
			elseif behaviour == strings.prepare then
				recipes.handler = corpseType == "wolf" and "Wolf" or "Humanoid"
				event.trigger("Necrocraft:CorpsePreparation")
				event.register("Necrocraft:CorpsePrepared", function(eventData)
					eventData.reference.data.necroCraft = {}
					if reference.data and reference.data.necroCraft then
						eventData.reference.data.necroCraft = reference.data.necroCraft
					end
					eventData.reference.data.necroCraft.resurrectionCount = eventData.reference.data.necroCraft.resurrectionCount and eventData.reference.data.necroCraft.resurrectionCount + 1 or 0
					local safeRef = tes3.makeSafeObjectHandle(reference)
					timer.delayOneFrame(function()
						if safeRef:valid() then
							utility.disposeCorpse(reference)
						end
					end)
					event.clear("Necrocraft:CorpsePrepared")
					-- event.clear("Necrocraft:BodyCrafted")
				end)
				-- event.register("Necrocraft:BodyCrafted", function()
				-- 	tes3.messageBox('Body Crafted')
				-- 	reference:disable()
				-- 	event.clear("Necrocraft:BodyCrafted")
				-- end)
				-- event.register("Necrocraft:BodyPositioned", function()
				-- 	tes3.messageBox('Body Positioned')
				-- 	reference:disable()
				-- 	event.clear("Necrocraft:BodyPositioned")
				-- end)
			end
		end)
	end
	button:register("mouseClick", doOnce)
end

event.register("Necrocraft:CorpseDestroyed", function() 
	bones.harvest("skeletonWarrior")
	practiceSkill(0)
end)

return this


