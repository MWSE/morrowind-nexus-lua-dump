local i18n = mwse.loadTranslations('MXPS')
local config = require('MXPS.config')

-- local skillModule = require("OtherSkills.skillModule")
-- local common = require("OtherSkills.common")

local function QuestFinish(e)
	if config.QuestXP then
		local step = 0
		if e.info then
			if e.info.isQuestFinished ~= nil then
				if e.info.isQuestFinished then
					for i = 1,1000 do
						if e.topic:getJournalInfo(i) ~= nil then
							step = step + 1
						end
					end
					local Quest_Name = e.topic:loadQuestName()
					local Experience = step * config.QuestRate
					local data = tes3.getPlayerRef().data
					data.MXPS_xp = data.MXPS_xp + Experience
					if config.QuestMsg then
						tes3.messageBox({message = i18n('QuestOverMsg',{name = Quest_Name, count = Experience}), duration = 5})
					end
				end
			end
		end
	end
end
event.register('journal', QuestFinish)

-- local function target(e)
	-- local ref = e.current
	-- if ref and ref.object and (ref.object.objectType == tes3.objectType.creature or ref.object.objectType == tes3.objectType.npc) then
		-- if ref.mobile and ref.mobile.health.current ~= nil and not ref.mobile.isDead then
			-- tes3.messageBox({message = 'Mobile HP: ' .. ref.mobile.health.current .. ', mobile lvl: ' .. ref.mobile.object.level .. ', Base lvl: ' .. ref.object.level, duration = 10})
		-- end
	-- end
	-- for i,skill in pairs(common.otherSkills) do
		-- if skill.active == 'active' then
			-- tes3.messageBox({message = 'Skill: '..skill.name..' Level: '..tostring(skill.value)..' Prog: '..tostring(skill.progress)..' Att: '..tostring(skill.attribute)..' Spec: '..tostring(skill.specialization), duration = 10})
		-- end
	-- end	
-- end
-- event.register('activationTargetChanged', target)

local function Kill(e)
	if config.KillXP then
		local ref = e.reference
		local data = tes3.getPlayerRef().data
		local Experience = 0.0
		if ref and ref.object and (ref.object.objectType == tes3.objectType.creature or ref.object.objectType == tes3.objectType.npc) then
			if ref.mobile and ref.mobile.health.current ~= nil then
				if ref.mobile.health.current <= 0 and string.find(ref.id, '[Ss]ummon') == nil then
					Experience = math.round(ref.mobile.health.base / config.KillRate * ref.mobile.object.level, 2)
				else
					if ref.mobile.health.current > 0 and ref.mobile.isDead and string.find(ref.id, '[Ss]ummon') == nil then
						Experience = math.round(ref.mobile.health.base / config.KillRate * ref.mobile.object.level, 2)
					end
				end
				data.MXPS_xp = data.MXPS_xp + Experience
				if config.KillMsg then
					tes3.messageBox({message = i18n('KillMsg',{name = ref.object.name, lvl = ref.mobile.object.level, count = Experience, }), duration = 10})
				end
			end
		end
	end
end
event.register('death', Kill)

local function exerciseSkill(e)
	local data = tes3.getPlayerRef().data
	if config.BlockVanillaProgress then
		data.MXPS_xp = data.MXPS_xp + e.progress
		e.progress = 0
	end
	--local skill = skillModule.getSkill('MSS:Staff')
    --skill:progressSkill(config.skillGain + hitMod)
	--tes3.messageBox({message = 'Skill: '..tostring(e.skill), duration = 10})
end
event.register('exerciseSkill', exerciseSkill)

local function NewGame(e)
	if e.newGame then
		local data = tes3.getPlayerRef().data
		data.MXPS_xp = 0.0
	end
end
event.register('load', NewGame)

local function onLoaded(e)
	local data = tes3.getPlayerRef().data
	local player = tes3.getPlayerRef()
	if data.MXPS_xp == nil then
		data.MXPS_xp = 0.0
	end
	--data.MXPS_xp = 999999999
	--data.MXPS_xp = 0
end
event.register('loaded', onLoaded)

function GetAttStr(param)
	if tes3.getSkill(param).attribute == 0 then
		return tes3.findGMST('sAttributeStrength').value
	else
		if tes3.getSkill(param).attribute == 1 then
			return tes3.findGMST('sAttributeIntelligence').value
		else
			if tes3.getSkill(param).attribute == 2 then
				return tes3.findGMST('sAttributeWillpower').value
			else
				if tes3.getSkill(param).attribute == 3 then
					return tes3.findGMST('sAttributeAgility').value
				else
					if tes3.getSkill(param).attribute == 4 then
						return tes3.findGMST('sAttributeSpeed').value
					else
						if tes3.getSkill(param).attribute == 5 then
							return tes3.findGMST('sAttributeEndurance').value
						else
							if tes3.getSkill(param).attribute == 6 then
								return tes3.findGMST('sAttributePersonality').value
							else
								if tes3.getSkill(param).attribute == 7 then
									return tes3.findGMST('sAttributeLuck').value
								end								
							end						
						end
					end
				end
			end
		end
	end	
end

function GetSkillStr(param)
	if tes3.mobilePlayer:getSkillStatistic(param).type == 0 then
		return i18n('MajorSkillType')
	else
		if tes3.mobilePlayer:getSkillStatistic(param).type == 1 then
			return i18n('MinorSkillType')
		else
			if tes3.mobilePlayer:getSkillStatistic(param).type == 2 then
				return i18n('MiscSkillType')
			end
		end
	end	
end

local this = {}
function this.init()
    this.id_menu = tes3ui.registerID('example:MenuMXPS')
	this.id_xp = tes3ui.registerID('example:MenuMXPS_xp')
	this.id_ok = tes3ui.registerID('example:MenuMXPS_Ok')
	this.id_scrollMenu = tes3ui.registerID('example:scrollMenuMXPS')
end

local menu = nil

function CBlock(p1,p2)
	local p1 = p2:createBlock{}
    p1.autoHeight = true
	p1.autoWidth = true
	return p1
end

function CButton(p1,p2,p3,p4,p5)
	local player = tes3.getPlayerRef()	
	local p1 = p2:createButton{text = tes3.findGMST(p3).value..' '..tostring(player.mobile:getSkillStatistic(p4).base)..' ['..GetSkillStr(p4)..', '..GetAttStr(p4)..'] ('..i18n('XPNeed')..': '..tostring(math.round(p5,2))..')'}
	return p1
end

function MouseReg(p1,p2,p3,p4,p5)
	p1:register('mouseClick', 
	function(e) 						
		local PR = p2
		local SK = p3
		local sSK = p4
		local BU = p1
		local player = tes3.getPlayerRef()
		local data = tes3.getPlayerRef().data
		PR = player.mobile:getSkillProgressRequirement(SK)
		if data.MXPS_xp >= PR then	
			data.MXPS_xp = data.MXPS_xp - PR
			p5.text = i18n('XP')..': '..tostring(math.round(data.MXPS_xp,2))
			player.mobile:progressSkillToNextLevel(SK)
			PR = player.mobile:getSkillProgressRequirement(SK)
			BU.text = tes3.findGMST(sSK).value..' '..tostring(player.mobile:getSkillStatistic(SK).base)..' ['..GetSkillStr(SK)..', '..GetAttStr(SK)..'] ('..i18n('XPNeed')..': '..tostring(math.round(PR,2))..')'
		end
	end)
end

function this.createWindow()
    if (tes3ui.findMenu(this.id_menu) ~= nil) then
        return
    end
	local data = tes3.getPlayerRef().data
	local player = tes3.getPlayerRef()	
	
	menu = tes3ui.createMenu{id = this.id_menu, fixedFrame = true}
    menu.alpha = 1.0
	
	
	local label_xp = menu:createLabel{id = this.id_xp, text = i18n('XPTotal')..': '..tostring(math.round(data.MXPS_xp,2))}
	label_xp.wrapText = true
    label_xp.justifyText = "center"
	label_xp.borderBottom = 10
	
	local block = menu
	if config.ScrollMenu == true then
		local block1 = menu:createBlock{}
		block1.width = 640
		block1.height = 480		
		block = block1:createVerticalScrollPane()
		block.width = 640
		block.height = 480
	end

	local PR_block = player.mobile:getSkillProgressRequirement(tes3.skill.block)
	local PR_armorer = player.mobile:getSkillProgressRequirement(tes3.skill.armorer)
	local PR_mediumArmor = player.mobile:getSkillProgressRequirement(tes3.skill.mediumArmor)
	local PR_heavyArmor = player.mobile:getSkillProgressRequirement(tes3.skill.heavyArmor)
	local PR_bluntWeapon = player.mobile:getSkillProgressRequirement(tes3.skill.bluntWeapon)
	local PR_longBlade = player.mobile:getSkillProgressRequirement(tes3.skill.longBlade)
	local PR_axe = player.mobile:getSkillProgressRequirement(tes3.skill.axe)
	local PR_spear = player.mobile:getSkillProgressRequirement(tes3.skill.spear)
	local PR_athletics = player.mobile:getSkillProgressRequirement(tes3.skill.athletics)
	local PR_enchant = player.mobile:getSkillProgressRequirement(tes3.skill.enchant)
	local PR_destruction = player.mobile:getSkillProgressRequirement(tes3.skill.destruction)
	local PR_alteration = player.mobile:getSkillProgressRequirement(tes3.skill.alteration)
	local PR_illusion = player.mobile:getSkillProgressRequirement(tes3.skill.illusion)
	local PR_conjuration = player.mobile:getSkillProgressRequirement(tes3.skill.conjuration)
	local PR_mysticism = player.mobile:getSkillProgressRequirement(tes3.skill.mysticism)
	local PR_restoration = player.mobile:getSkillProgressRequirement(tes3.skill.restoration)
	local PR_alchemy = player.mobile:getSkillProgressRequirement(tes3.skill.alchemy)
	local PR_unarmored = player.mobile:getSkillProgressRequirement(tes3.skill.unarmored)
	local PR_security = player.mobile:getSkillProgressRequirement(tes3.skill.security)
	local PR_sneak = player.mobile:getSkillProgressRequirement(tes3.skill.sneak)
	local PR_acrobatics = player.mobile:getSkillProgressRequirement(tes3.skill.acrobatics)
	local PR_lightArmor = player.mobile:getSkillProgressRequirement(tes3.skill.lightArmor)
	local PR_shortBlade = player.mobile:getSkillProgressRequirement(tes3.skill.shortBlade)
	local PR_marksman = player.mobile:getSkillProgressRequirement(tes3.skill.marksman)
	local PR_mercantile = player.mobile:getSkillProgressRequirement(tes3.skill.mercantile)
	local PR_speechcraft = player.mobile:getSkillProgressRequirement(tes3.skill.speechcraft)
	local PR_handToHand = player.mobile:getSkillProgressRequirement(tes3.skill.handToHand)	
	
	local button_block_block = CBlock(button_block_block,block)
	local button_block_armorer = CBlock(button_block_armorer,block)
	local button_block_mediumArmor = CBlock(button_block_mediumArmor,block)
	local button_block_heavyArmor = CBlock(button_block_heavyArmor,block)
	local button_block_bluntWeapon = CBlock(button_block_bluntWeapon,block)
	local button_block_longBlade = CBlock(button_block_longBlade,block)
	local button_block_axe = CBlock(button_block_axe,block)
	local button_block_spear = CBlock(button_block_spear,block)
	local button_block_athletics = CBlock(button_block_athletics,block)
	local button_block_enchant = CBlock(button_block_enchant,block)
	local button_block_destruction = CBlock(button_block_destruction,block)
	local button_block_alteration = CBlock(button_block_alteration,block)
	local button_block_illusion = CBlock(button_block_illusion,block)
	local button_block_conjuration = CBlock(button_block_conjuration,block)
	local button_block_mysticism = CBlock(button_block_mysticism,block)
	local button_block_restoration = CBlock(button_block_restoration,block)
	local button_block_alchemy = CBlock(button_block_alchemy,block)
	local button_block_unarmored = CBlock(button_block_unarmored,block)
	local button_block_security = CBlock(button_block_security,block)
	local button_block_sneak = CBlock(button_block_sneak,block)
	local button_block_acrobatics = CBlock(button_block_acrobatics,block)
	local button_block_lightArmor = CBlock(button_block_lightArmor,block)
	local button_block_shortBlade = CBlock(button_block_shortBlade,block)
	local button_block_marksman = CBlock(button_block_marksman,block)
	local button_block_mercantile = CBlock(button_block_mercantile,block)
	local button_block_speechcraft = CBlock(button_block_speechcraft,block)
	local button_block_handToHand = CBlock(button_block_handToHand,block)

	local button_block = CButton(button_block,button_block_block,'sSkillBlock',tes3.skill.block,PR_block)
	local button_armorer = CButton(button_armorer,button_block_armorer,'sSkillArmorer',tes3.skill.armorer,PR_armorer)
	local button_mediumArmor = CButton(button_mediumArmor,button_block_mediumArmor,'sSkillMediumarmor',tes3.skill.mediumArmor,PR_mediumArmor)
	local button_heavyArmor = CButton(button_heavyArmor,button_block_heavyArmor,'sSkillHeavyarmor',tes3.skill.heavyArmor,PR_heavyArmor)
	local button_bluntWeapon = CButton(button_bluntWeapon,button_block_bluntWeapon,'sSkillBluntweapon',tes3.skill.bluntWeapon,PR_bluntWeapon)
	local button_longBlade = CButton(button_longBlade,button_block_longBlade,'sSkillLongblade',tes3.skill.longBlade,PR_longBlade)
	local button_axe = CButton(button_axe,button_block_axe,'sSkillAxe',tes3.skill.axe,PR_axe)
	local button_spear = CButton(button_spear,button_block_spear,'sSkillSpear',tes3.skill.spear,PR_spear)
	local button_athletics = CButton(button_athletics,button_block_athletics,'sSkillAthletics',tes3.skill.athletics,PR_athletics)
	local button_enchant = CButton(button_enchant,button_block_enchant,'sSkillEnchant',tes3.skill.enchant,PR_enchant)
	local button_destruction = CButton(button_destruction,button_block_destruction,'sSkillDestruction',tes3.skill.destruction,PR_destruction)
	local button_alteration = CButton(button_alteration,button_block_alteration,'sSkillAlteration',tes3.skill.alteration,PR_alteration)
	local button_illusion = CButton(button_illusion,button_block_illusion,'sSkillIllusion',tes3.skill.illusion,PR_illusion)
	local button_conjuration = CButton(button_conjuration,button_block_conjuration,'sSkillConjuration',tes3.skill.conjuration,PR_conjuration)
	local button_mysticism = CButton(button_mysticism,button_block_mysticism,'sSkillMysticism',tes3.skill.mysticism,PR_mysticism)
	local button_restoration = CButton(button_restoration,button_block_restoration,'sSkillRestoration',tes3.skill.restoration,PR_restoration)
	local button_alchemy = CButton(button_alchemy,button_block_alchemy,'sSkillAlchemy',tes3.skill.alchemy,PR_alchemy)
	local button_unarmored = CButton(button_unarmored,button_block_unarmored,'sSkillUnarmored',tes3.skill.unarmored,PR_unarmored)
	local button_security = CButton(button_security,button_block_security,'sSkillSecurity',tes3.skill.security,PR_security)
	local button_sneak = CButton(button_sneak,button_block_sneak,'sSkillSneak',tes3.skill.sneak,PR_sneak)
	local button_acrobatics = CButton(button_acrobatics,button_block_acrobatics,'sSkillAcrobatics',tes3.skill.acrobatics,PR_acrobatics)
	local button_lightArmor = CButton(button_lightArmor,button_block_lightArmor,'sSkillLightarmor',tes3.skill.lightArmor,PR_lightArmor)
	local button_shortBlade = CButton(button_shortBlade,button_block_shortBlade,'sSkillShortblade',tes3.skill.shortBlade,PR_shortBlade)
	local button_marksman = CButton(button_marksman,button_block_marksman,'sSkillMarksman',tes3.skill.marksman,PR_marksman)
	local button_mercantile = CButton(button_mercantile,button_block_mercantile,'sSkillMercantile',tes3.skill.mercantile,PR_mercantile)
	local button_speechcraft = CButton(button_speechcraft,button_block_speechcraft,'sSkillSpeechcraft',tes3.skill.speechcraft,PR_speechcraft)
	local button_handToHand = CButton(button_handToHand,button_block_handToHand,'sSkillHandtohand',tes3.skill.handToHand,PR_handToHand)

	MouseReg(button_block,PR_block,tes3.skill.block,'sSkillBlock',label_xp)
	MouseReg(button_armorer,PR_armorer,tes3.skill.armorer,'sSkillArmorer',label_xp)
	MouseReg(button_mediumArmor,PR_mediumArmor,tes3.skill.mediumArmor,'sSkillMediumarmor',label_xp)
	MouseReg(button_heavyArmor,PR_heavyArmor,tes3.skill.heavyArmor,'sSkillHeavyarmor',label_xp)
	MouseReg(button_bluntWeapon,PR_bluntWeapon,tes3.skill.bluntWeapon,'sSkillBluntweapon',label_xp)
	MouseReg(button_longBlade,PR_longBlade,tes3.skill.longBlade,'sSkillLongblade',label_xp)
	MouseReg(button_axe,PR_axe,tes3.skill.axe,'sSkillAxe',label_xp)
	MouseReg(button_spear,PR_spear,tes3.skill.spear,'sSkillSpear',label_xp)
	MouseReg(button_athletics,PR_athletics,tes3.skill.athletics,'sSkillAthletics',label_xp)
	MouseReg(button_enchant,PR_enchant,tes3.skill.enchant,'sSkillEnchant',label_xp)	
	MouseReg(button_destruction,PR_destruction,tes3.skill.destruction,'sSkillDestruction',label_xp)
	MouseReg(button_alteration,PR_alteration,tes3.skill.alteration,'sSkillAlteration',label_xp)
	MouseReg(button_illusion,PR_illusion,tes3.skill.illusion,'sSkillIllusion',label_xp)
	MouseReg(button_conjuration,PR_conjuration,tes3.skill.conjuration,'sSkillConjuration',label_xp)
	MouseReg(button_mysticism,PR_mysticism,tes3.skill.mysticism,'sSkillMysticism',label_xp)
	MouseReg(button_restoration,PR_restoration,tes3.skill.restoration,'sSkillRestoration',label_xp)
	MouseReg(button_alchemy,PR_alchemy,tes3.skill.alchemy,'sSkillAlchemy',label_xp)
	MouseReg(button_unarmored,PR_unarmored,tes3.skill.unarmored,'sSkillUnarmored',label_xp)
	MouseReg(button_security,PR_security,tes3.skill.security,'sSkillSecurity',label_xp)
	MouseReg(button_sneak,PR_sneak,tes3.skill.sneak,'sSkillSneak',label_xp)
	MouseReg(button_acrobatics,PR_acrobatics,tes3.skill.acrobatics,'sSkillAcrobatics',label_xp)
	MouseReg(button_lightArmor,PR_lightArmor,tes3.skill.lightArmor,'sSkillLightarmor',label_xp)
	MouseReg(button_shortBlade,PR_shortBlade,tes3.skill.shortBlade,'sSkillShortblade',label_xp)
	MouseReg(button_marksman,PR_marksman,tes3.skill.marksman,'sSkillMarksman',label_xp)
	MouseReg(button_mercantile,PR_mercantile,tes3.skill.mercantile,'sSkillMercantile',label_xp)
	MouseReg(button_speechcraft,PR_speechcraft,tes3.skill.speechcraft,'sSkillSpeechcraft',label_xp)
	MouseReg(button_handToHand,PR_handToHand,tes3.skill.handToHand,'sSkillHandtohand',label_xp)

    menu:updateLayout()
    tes3ui.enterMenuMode(this.id_menu)	
end

local sw = 0
local function onCommand(e)
	if e.keyCode ~= config.key.keyCode then return end
	if sw == 0 then
		if tes3ui.enterMenuMode(0) then 
			this.createWindow()
			sw = 1
		end
	else
		if sw == 1 then
			tes3ui.leaveMenuMode()
			menu:destroy()
			sw = 0
		end
	end	
end
event.register(tes3.event.keyDown, onCommand)

event.register('initialized', this.init)

local function onInitialized(e)
	mwse.log('[MXPS] lua script loaded')
end
event.register('initialized', onInitialized)

event.register('modConfigReady', function() require('MXPS.mcm') end)