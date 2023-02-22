local skillModule = require("OtherSkills.skillModule")
local magic = require("NecroCraft.magic")
local utility = require("NecroCraft.utility")
local undead = require("NecroCraft.undead")
local corpsePreparation = require("NecroCraft.corpsePreparation")
local bones = require("NecroCraft.bones")
local soulGemLib = require("NecroCraft.soulgem")
local aiAction = require("NecroCraft.aiAction")
local strings = require("NecroCraft.strings")
local id = require("NecroCraft.magic.id")
local lichdom = require("NecroCraft.lichdom")
local quests = require("NecroCraft.quests")
local cellEdit = require("NecroCraft.cellEdit")
local common = require("NecroCraft.common")

local skillStatus = "inactive"
local activationRef

local function onMenuDialog(e)
	if not activationRef then return end
	local name = activationRef.data.necroCraft and activationRef.data.necroCraft.name
	if not name then return end
	local child = e.element:findChild(-1044)
	child.text = name
end

event.register("modConfigReady", function()
    require("NecroCraft.mcm")
	common.config  = require("NecroCraft.config")
	event.unregister("uiActivated", onMenuDialog, { filter = "MenuDialog" })
	if common.config.preserveTooltip then
		event.register("uiActivated", onMenuDialog, { filter = "MenuDialog" })
	end
end)

-- GUI stuff

local GUI_ID = {}

local function registerGUI()
	GUI_ID.imageParent = tes3ui.registerID("NC_Tooltip_ImageParent")
	GUI_ID.parent = tes3ui.registerID("NC_Tooltip_Parent")
	GUI_ID.image = tes3ui.registerID("NC_Tooltip_Image")
	GUI_ID.name = tes3ui.registerID("NC_Tooltip_Name")
    GUI_ID.weight = tes3ui.registerID("NC_Tooltip_Weight")
    GUI_ID.value = tes3ui.registerID("NC_Tooltip_Value")
end


-- Skill Module and crafting

local function onSkillReady()
	skillModule.registerSkill(
		"NC:CorpsePreparation", 
		{	name 			=		strings.corpsePreparation, 					--default: skill id
			value			= 		5,											--default: 1
			progress		=		0, 											--default: 0
			lvlCap			=		100, 										--default: 100	
			icon 			=		"Icons/NecroCraft/corpsePreparation.dds", 				--default: a circle icon
			attribute 		=		tes3.attribute.intelligence,				--optional
			description 	= 		strings.corpsePreparationDesc,		--optional
			specialization 	= 		tes3.specialization.magic,					--optional. Icon background is gray if none set
			active			=		skillStatus									--defaults to "active"
		}
	)
end			

local function onEquip(e)
	if bones.isBone(e.item.id) then
		tes3ui.leaveMenuMode(tes3ui.registerID("MenuInventory"))
		event.trigger("Necrocraft:BonepilesCreation")
	end
end

local function messageBox(params)

    local message = params.message
    local buttons = params.buttons

    local function callback(e)
        --get button from 0-indexed MW param
        local button = buttons[e.button+1]
        if button.callback then
            timer.start{ duration = 0.1, type = timer.real, callback = function()
                button.callback()
            end}
        end
    end

    --Make list of strings to insert into buttons
    local buttonStrings = {}
    for _, button in ipairs(buttons) do
        table.insert(buttonStrings, button.text)
    end

    tes3.messageBox({
        message = message,
        buttons = buttonStrings,
        callback = callback
    })
end



local function onMenuContents(e)
	corpsePreparation.onCorpseContents(e, activationRef)
end

-- Making pile of bones behave like misc items

local function onTooltipDrawn(e)
	if not e.reference then
		return 
	end
	local child = e.tooltip:findChild(-1216)
	if e.reference.data and e.reference.data.necroCraft and e.reference.data.necroCraft.name then
		if e.reference.data.necroCraft.id or common.config.preserveTooltip then
			child.text = e.reference.data.necroCraft.name
		end
		return
	end
	if e.reference.data and e.reference.data.necroCraft and e.reference.data.necroCraft.isBeingRaised then
		return
	end
	local misc = undead.pileToMisc(e.reference)
	if not misc then return end
	local tooltip = tes3ui.createTooltipMenu()
	child.visible = false
	local helpMenuTitleBlock = e.tooltip:createBlock{id="HelpMenu_titleBlock"}
	helpMenuTitleBlock.flowDirection = "left_to_right"
    helpMenuTitleBlock.childAlignX = 0.5
    helpMenuTitleBlock.autoHeight = true
    helpMenuTitleBlock.autoWidth = true
	local icon = helpMenuTitleBlock:createImage{id="HelpMenu_icon", path="Icons\\"..misc.icon}
	local label = helpMenuTitleBlock:createLabel{id="HelpMenu_name", text=misc.name}
	label.absolutePosAlignY = -0.5
	label.positionY = -7
	label.color = {0.875,0.788,0.624}
	label.wrapText = true
	tooltip:createLabel{id=tes3ui.registerID("HelpMenu_weight"), text="Weight: "..string.format("%.2f", misc.weight)}
	tooltip:createLabel{id=tes3ui.registerID("HelpMenu_value"), text="Value: "..tostring(misc.value)}
	event.trigger("uiObjectTooltip", {tooltip=tooltip, object=misc, count=1})
	-- local parent = e.tooltip:createBlock{id=GUI_ID.parent}
    -- parent.flowDirection = "top_to_bottom"
    -- parent.childAlignX = 0.5
    -- parent.autoHeight = true
    -- parent.autoWidth = true
	-- local label = parent:createLabel{id=GUI_ID.weight, text=string.format(strings.weight, misc.weight)}
    -- label.wrapText = true
    -- local label = parent:createLabel{id=GUI_ID.value, text=string.format(strings.value, misc.value)}
    -- label.wrapText = true
end

local function onCalcHitChance(e)
	if undead.pileToMisc(e.target) or undead.corpseToRaised(e.target) or tes3.isAffectedBy{reference = e.target, effect = tes3.effect.feintDeath} then
		e.hitChance = 0
	end
end

local function harvestAshpit(reference)
	if not string.startswith(reference.id, "nc_ashpit") then
		return
	end
	local bounty = tes3.mobilePlayer.bounty
	timer.start {
		duration = 0.1,
		callback = function()
			if tes3.mobilePlayer.bounty > bounty then
				tes3.mobilePlayer.bounty = tes3.mobilePlayer.bounty + common.config.bountyValue
			end
		end
	}
end

local function pickBonepile(reference)
	if reference.data and reference.data.necroCraft and reference.data.necroCraft.isBeingRaised then
		return false
	end
	local misc = undead.pileToMisc(reference)
	if not misc then 
		return
	end
	utility.safeDelete(reference)
	tes3.addItem{reference=tes3.player, item=misc, count=1, playSound=true}
end

local function onActivate(e)
	if e.activator ~= tes3.player then
		return
	end
	activationRef = e.target
	
	if not activationRef then
		return
	end
	if pickBonepile(activationRef) == false then
		return false
	end
	if undead.isRaisedByPlayer(activationRef) == false then
		return false
	end
	if activationRef.baseObject.objectType == tes3.objectType.npc or activationRef.baseObject.objectType == tes3.objectType.creature then
		if tes3.isAffectedBy{reference = activationRef.mobile, effect = tes3.effect.feintDeath} then
			return false
		end
	end
	harvestAshpit(activationRef)
	undead.skeletonCrippleDrop(activationRef)
	return
end

local function triggerGuards(cell)
	local minions = tes3.player.data.necroCraft.minions
	for ref in cell:iterateReferences(tes3.objectType.npc) do
		if ref.object.isGuard then
			for _, arr in pairs(minions) do
				for minion_id, __ in pairs(arr) do
					if mwscript.getDistance{reference = ref, target = minion_id} < 5000 then
						if not tes3.isAffectedBy{reference = minion_id, effect = tes3.effect.concealUndead} then
							mwscript.startCombat{reference = ref, target = minion_id}
						end
					end
				end
			end
		end
	end
end

local function onDetectUndead(e)
	if not e.isDetected then 
		return 
	end
	if tes3.isAffectedBy{reference = e.target, effect = tes3.effect.concealUndead} then return end
	if (e.target == tes3.mobilePlayer and tes3.player.object.race.id == "skeletonrace") then -- or undead.isRaisedByPlayer(e.target.reference) then
		if e.detector.reference.object.isGuard then
			e.detector:startCombat(e.target)
		end
	end
end

local function editLevelLists()
	mwscript.addToLevItem{list = "random_book_wizard_evil", item = "nc_bk_skeleton_cr"}
	mwscript.addToLevItem{list = "random_book_wizard_evil", item = "nc_bk_bonespider"}
	mwscript.addToLevItem{list = "random_book_wizard_evil", item = "nc_bk_corpse1"}
end

-- Replaces summon skeleton scrolls with random necro books and ashpits in tombs and temples with lootable ones.


local function onCellChanged(e)
	triggerGuards(e.cell)
	cellEdit.replaceBooks(e.cell)
	cellEdit.replaceAshpits(e.cell)
end

local trainingBooks = {
	["TR_bk_i2-25-Bonewalkerbook"] = true,
	["TR_bk_i2-25_Temple-corpse-prep"] = true,
	["TR_bk_m2-68_bwblessings"] = true,
	["T_Bk_OnNecromanyPC"] = true,
	["T_Bk_DresCremationPracticesTR"] = true,
	["bk_legionsofthedead"] = true
}

local function onBookRead(e)

	local corpsePreparationGlobal = tes3.findGlobal("NC_CorpsePreparation")
	local corpsePreparationSkill = skillModule.getSkill("NC:CorpsePreparation")
	if corpsePreparationGlobal.value == 1 then
		if trainingBooks[e.book.id] and not tes3.player.data.necroCraft.trainingBooksRead[e.book.id] then
			tes3.player.data.necroCraft.trainingBooksRead[e.book.id] = true
			corpsePreparationSkill:levelUpSkill(1)
			local message = string.format( tes3.findGMST(tes3.gmst.sNotifyMessage39).value, corpsePreparationSkill.name, corpsePreparationSkill.value ) 
            mwscript.playSound{reference= tes3.player, sound="skillraise"}
			tes3.messageBox( message )
		end
		return
	end

	local book = string.sub(e.book.id, 1, -3)	-- doesn't matter whether the book is opened or closed
	if tes3.player.data.necroCraft.necroBooks[book] == nil then
		return
	end
	tes3.player.data.necroCraft.necroBooks[book] = true
	local count = 0
	for book, status in pairs(tes3.player.data.necroCraft.necroBooks) do
		if status == true then
			count = count + 1
		end
	end
	if count == 3 then
		local buttons = {}
		local yesButton = {	text = strings.yes, 
							callback = function()
										mwscript.addTopic{topic=strings.necromancers}
										skillStatus = "active"
										corpsePreparationGlobal.value = 1
										-- skillModule.updateSkill("NC:CorpsePreparation", { active = skillStatus })
										corpsePreparationSkill:updateSkill({ active = skillStatus })
										-- event.unregister("bookGetText", onBookRead)
										event.register("uiActivated", onMenuContents, { filter = "MenuContents" })
										event.register("equip", onEquip)
							end}
		table.insert(buttons, yesButton)
		table.insert(buttons, {text = strings.no})
		messageBox{
			message = strings.corpsePreparationLearnt, 
			buttons = buttons
		}
	end
end

local function onSpellResist(e)
	if e.target.data.necroCraft and e.target.data.necroCraft.feintDeath  then
		e.resistedPercent = 100
	end
end

local function onDamage(e)
	if not e.reference then return end

	if undead.pileToMisc(e.reference) or undead.corpseToRaised(e.reference) or tes3.isAffectedBy{reference = e.reference, effect = tes3.effect.feintDeath} then
		e.damage = 0
		local health = e.reference.data.necroCraft and e.reference.data.necroCraft.feintDeath or e.mobile.health.base
		e.mobile.health.current = health
		return false
	end
	if e.mobile.health.current - math.abs(e.damage) <= 1 then
		undead.skeletonChampRestore(e.reference)
		if tes3.isAffectedBy{reference = e.reference, effect = tes3.effect.deathPact} then
			local itemData = soulGemLib.releaseSoul{reference=e.reference, position=e.reference.position, gem="NC_SoulGem_AzuraB"}
			if not itemData then
				itemData = soulGemLib.releaseSoul{reference=e.reference, position=e.reference.position, gem="AB_Misc_SoulGemBlack"}
			end
			if itemData then
				local health = e.mobile.health.current + itemData.soul.soul - e.damage
				tes3.modStatistic{reference = e.reference, name = "health", current = health, limit = true}
				e.damage = 0
				return false
			end
		end
		if e.reference == tes3.player and tes3.player.data.necroCraft.phylactery and tes3.player.data.necroCraft.phylactery.container then
			tes3.modStatistic{reference = e.reference, name = "health", current = 99999999, limit = true}
			lichdom.playerDeath()
			e.damage = 0
			return false
		end
	end
end

local function onDeath(e)
	local utype = undead.getType(e.reference.object)
	if not utype then return end
	tes3.player.data.necroCraft.minions[utype][e.reference.id] = nil
end

local function onDetermineAction(e)
	local reference = e.session.mobile.reference
	local utype = undead.getType(reference.object.baseObject)
	if utype == "lich" or utype == "lichKing" then
		aiAction.raiseAll(reference)
	elseif utype == "boneoverlord" then
		aiAction.raiseAllSkeletons(reference)
	elseif utype == "bonelord" then
		aiAction.raiseSkeleton(reference)
	elseif common.config.necromancers[reference.object.baseObject.id:lower()] then
		aiAction.raise(reference)
	end
end

local function onSpellTick(e)
	local raised = undead.pileToRaised(e.target) or undead.corpseToRaised(e.target)
	if raised then
		local effect = nil
		local utype = undead.getType(raised)
		if string.startswith(utype, "skeleton") then
			effect = tes3.effect.raiseSkeleton
		elseif string.endswith(utype, "lord") or string.endswith(utype, "spider") then
			effect = tes3.effect.raiseBoneConstruct
		else
			effect = tes3.effect.raiseCorpse
		end
		if e.effectId ~= effect then
			tes3.removeEffects{reference = e.target, effect = e.effectId}
			return
		end
	end
	if not common.config.editSummonUndeadEffects then return end
	if e.effectId > 106 and e.effectId < 111 then
		magic.edit.createUndead(e)
	end
end

local function test()
	tes3.addItem{reference=tes3.player, item="nc_skeleton_war_misc", count=1, playSound=false}
	tes3.addItem{reference=tes3.player, item="nc_skeleton_weak_misc", count=1, playSound=false}
	tes3.addItem{reference=tes3.player, item="nc_skeleton_champ_misc", count=1, playSound=false}
	tes3.addItem{reference=tes3.player, item="nc_bonelord_misc", count=1, playSound=false}
	tes3.addItem{reference=tes3.player, item="nc_boneoverlord_misc", count=1, playSound=false}
	tes3.addItem{reference=tes3.player, item="nc_bonespider_misc", count=1, playSound=false}
	mwscript.addSpell{reference=tes3.player, spell="NC_ME_RaiseSkeletonChampion"}
	mwscript.addSpell{reference=tes3.player, spell=id.spell.raiseSkeletonWarrior}
	mwscript.addSpell{reference=tes3.player, spell=id.spell.raiseSkeletonCripple}
	mwscript.addSpell{reference=tes3.player, spell="NC_ME_RaiseBoneoverlord"}
	mwscript.addSpell{reference=tes3.player, spell="NC_ME_RaiseBonelord"}
	mwscript.addSpell{reference=tes3.player, spell=id.spell.raiseBonespider}
	mwscript.addSpell{reference=tes3.player, spell="NC_ME_CallSkeletonWarrior"}
	mwscript.addSpell{reference=tes3.player, spell="NC_ME_CallSkeletonCripple"}
	mwscript.addSpell{reference=tes3.player, spell="NC_ME_CallSkeletonChampion"}
	mwscript.addSpell{reference=tes3.player, spell="NC_ME_CallBonespider"}
	mwscript.addSpell{reference=tes3.player, spell="NC_ME_CallBonelord"}
	mwscript.addSpell{reference=tes3.player, spell="NC_ME_CallBoneoverlord"}
	mwscript.addSpell{reference=tes3.player, spell="NC_ME_CallBonewalker"}
	mwscript.addSpell{reference=tes3.player, spell="NC_ME_CallGreaterBonewalker"}
	mwscript.addSpell{reference=tes3.player, spell="NC_ME_SpreadDisease1"}
	mwscript.addSpell{reference=tes3.player, spell="relvel_damage"}
	
end

local lastSpell
local lastShade

local function onSimulate()

    local currentShade = utility.isShade()

    if tes3.mobilePlayer.currentSpell == lastSpell and currentShade == lastShade then
        return
    end

    lastShade = currentShade
    lastSpell = tes3.mobilePlayer.currentSpell
    local bonus = utility.getNecromanticSpellBonus(lastSpell, lastShade)

    tes3.mobilePlayer.sound = tes3.mobilePlayer.sound - tes3.player.data.necroCraft.castBonus + bonus
    tes3.player.data.necroCraft.castBonus = bonus

end

local function openPseudoInventory()
	local container = tes3.createReference{object="NC_Transfer", position={0,0,0}, orientation={0,0,0}, cell="toddtest"}
	event.trigger("activate", {activator = tes3.player, target = container})
	timer.start{
		duration = 0.2,
		callback = function()
			utility.safeDelete(container)
		end
	}
end

local function onLoaded(e)
	undead.init()
	event.unregister("uiActivated", onMenuContents, { filter = "MenuContents" })
	if tes3.player.data.necroCraft == nil then tes3.player.data.necroCraft = {} end
	if tes3.findGlobal("NC_CorpsePreparation").value > 0 then
		skillStatus = "active"
		skillModule.updateSkill("NC:CorpsePreparation", { active = skillStatus })
		event.unregister("uiActivated", onMenuContents, { filter = "MenuContents" })
		event.register("uiActivated", onMenuContents, { filter = "MenuContents" })
		event.unregister("equip", onEquip)
		event.register("equip", onEquip)
		event.register("bookGetText", onBookRead)
	else
		skillStatus = "inactive"
		skillModule.updateSkill("NC:CorpsePreparation", { active = skillStatus })
		event.unregister("bookGetText", onBookRead)
		event.register("bookGetText", onBookRead)
	end
	local necroBooks = {
		bk_corpsepreperation1 = false,
		bk_corpsepreperation2 = false,
		bk_corpsepreperation3 = false
	}
	tes3.player.data.necroCraft.trainingBooksRead = tes3.player.data.necroCraft.trainingBooksRead or {}
	tes3.player.data.necroCraft.necroBooks = tes3.player.data.necroCraft.necroBooks or necroBooks
	tes3.player.data.necroCraft.replacedBooksInCell = tes3.player.data.necroCraft.replacedBooksInCell or {}
	quests.loaded()
	if tes3.isAffectedBy{reference = tes3.player, effect = tes3.effect.darkRitual} then
		lichdom.ritualBegan()
	elseif tes3.player.data.necroCraft.phylactery then
		lichdom.ritualDone()
	else
		lichdom.ritualStopped()
	end
	local cell = tes3.getPlayerCell()
	for reference in cell:iterateReferences(tes3.objectType.creature) do
		if reference.data.necroCraft and reference.data.necroCraft.isBeingRaised then
			local raised = undead.pileToRaised(reference) or undead.corpseToRaised(reference)
			local caster = reference.data.necroCraft.isBeingRaised
			raised = utility.replace(reference, raised, cell)
			undead.handleFollow(caster, raised)
		end
	end
	tes3.player.data.necroCraft.castBonus = tes3.player.data.necroCraft.castBonus or 0
	event.unregister("simulate", onSimulate) -- register after load
	event.register("simulate", onSimulate)
end

local function onMobileActivated(e)
	local reference = e.reference
	if (string.startswith(reference.id, "NC_bonespider_pile") or string.startswith(reference.id, "NC_bonewolf_corpse")) and not (reference.data.necroCraft and reference.data.necroCraft.isBeingRaised) then
		tes3.playAnimation{reference = reference, group = tes3.animationGroup.knockOut, startFlag = tes3.animationStartFlag.immediateLoop}
		reference.mobile.paralyze = 1
		tes3.playAnimation{reference = reference, group=tes3.animationGroup.idle, startFlag=tes3.animationStartFlag.normal}
		return
	elseif string.startswith(reference.id, "NC_bonewalker_corpse") or string.startswith(reference.id, "NC_bonewalkerG_corpse") or string.startswith(reference.id, "NC_zombie_corpse") then
		tes3.playAnimation{reference = reference, group = tes3.animationGroup.deathKnockOut, startFlag = tes3.animationStartFlag.immediate}
		reference.mobile.paralyze = 1
		return
	-- elseif string.startswith(reference.id, "NC_ResurrectionDummy") then
	-- 	tes3.playAnimation{reference = reference, group = tes3.animationGroup.knockOut, startFlag = tes3.animationStartFlag.immediateLoop}
	-- 	reference.mobile.paralyze = 1
	-- 	tes3.playAnimation{reference = reference, group=tes3.animationGroup.idle, startFlag=tes3.animationStartFlag.normal}
	-- 	return
	end
	if undead.isRaisedByPlayer(reference) then
		reference.mobile.fight = 0
	end
	if undead.getType(e.reference.object) == "bonelord" then
		mwscript.addSpell{reference=e.reference, spell=id.spell.raiseBonespider}
		mwscript.addSpell{reference=e.reference, spell=id.spell.raiseSkeleton1}
		mwscript.addSpell{reference=e.reference, spell=id.spell.raiseSkeleton2}
	end
end


local function onItemDropped(e)
	local pile = undead.miscToPile(e.reference)
	if pile then
		for _ = 1, e.reference.stackSize do
			local new = tes3.createReference{object = pile, position = e.reference.position, orientation = e.reference.orientation, cell=tes3.getPlayerCell()}
			tes3.playAnimation{reference = new, group = tes3.animationGroup.knockOut, startFlag = tes3.animationStartFlag.immediateLoop}
			if string.startswith(new.id, "NC_bonespider_pile") then
				tes3.playAnimation{reference = new, group=tes3.animationGroup.idle, startFlag=tes3.animationStartFlag.normal}
			end
			new.mobile.paralyze = 1
		end
		utility.safeDelete(e.reference)
	end
end

local function onCombatStart(e)
	
	if not e.target then return end

	if e.target.data and e.target.data.necroCraft and e.target.data.necroCraft.fightCastiong then
		return false
	elseif e.actor.data and e.actor.data.necroCraft and e.actor.data.necroCraft.fightCastiong then
		return false
	end
	
	local enemy = nil
	
	if e.target == tes3.mobilePlayer then
		enemy = e.actor.reference
	elseif e.actor == tes3.mobilePlayer then
		enemy = e.target.reference
	else
		return
	end
	
	
	if undead.pileToRaised(enemy) then
		return false
	elseif undead.corpseToRaised(enemy) then
		return false
	end
end

local function initialized(e)
	if tes3.isModActive("Necrocraft.esp") then
		mwse.log("NecroCraft: Necrocraft.esp is active. Mod content is enabled")
		utility.ashPitReplacer()
		utility.skeletonReplacer()
		registerGUI()
		event.register("determineAction", onDetermineAction)
		event.register("combatStart", onCombatStart)
		event.register("mobileActivated", onMobileActivated)
		event.register("itemDropped", onItemDropped)
		event.register("damage", onDamage)
		event.register("cellChanged", onCellChanged)
		event.register("activate", onActivate, {priority=201})	-- should execute before Graphic Herbalism
		event.register("calcHitChance", onCalcHitChance)
		event.register("uiObjectTooltip", onTooltipDrawn)
		event.register("spellTick", onSpellTick)
		event.register("OtherSkills:Ready", onLoaded)
		event.register("OtherSkills:Ready", onSkillReady)
		event.register("death", onDeath)
		event.register("spellResist", onSpellResist)
		event.register("detectSneak", onDetectUndead)
		cellEdit.init()
	else
		mwse.log("NecroCraft: Necrocraft.esp is not active. Mod content is disabled")
	end
end

event.register("initialized", initialized)