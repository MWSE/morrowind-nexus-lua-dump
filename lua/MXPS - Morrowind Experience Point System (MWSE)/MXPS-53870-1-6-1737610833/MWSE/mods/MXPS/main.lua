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
		if e.skill == 0 then
			data.MXPS_xp = data.MXPS_xp + (e.progress * config.SkillBlockRate)
		end
		if e.skill == 1 then
			data.MXPS_xp = data.MXPS_xp + (e.progress * config.SkillArmorerRate)
		end
		if e.skill == 2 then
			data.MXPS_xp = data.MXPS_xp + (e.progress * config.SkillMediumarmorRate)
		end
		if e.skill == 3 then
			data.MXPS_xp = data.MXPS_xp + (e.progress * config.SkillHeavyarmorRate)
		end
		if e.skill == 4 then
			data.MXPS_xp = data.MXPS_xp + (e.progress * config.SkillBluntweaponRate)
		end		
		if e.skill == 5 then
			data.MXPS_xp = data.MXPS_xp + (e.progress * config.SkillLongbladeRate)
		end
		if e.skill == 6 then
			data.MXPS_xp = data.MXPS_xp + (e.progress * config.SkillAxeRate)
		end	
		if e.skill == 7 then
			data.MXPS_xp = data.MXPS_xp + (e.progress * config.SkillSpearRate)
		end	
		if e.skill == 8 then
			data.MXPS_xp = data.MXPS_xp + (e.progress * config.SkillAthleticsRate)
		end
		if e.skill == 9 then
			data.MXPS_xp = data.MXPS_xp + (e.progress * config.SkillEnchantRate)
		end		
		if e.skill == 10 then
			data.MXPS_xp = data.MXPS_xp + (e.progress * config.SkillDestructionRate)
		end
		if e.skill == 11 then
			data.MXPS_xp = data.MXPS_xp + (e.progress * config.SkillAlterationRate)
		end	
		if e.skill == 12 then
			data.MXPS_xp = data.MXPS_xp + (e.progress * config.SkillIllusionRate)
		end	
		if e.skill == 13 then
			data.MXPS_xp = data.MXPS_xp + (e.progress * config.SkillConjurationRate)
		end
		if e.skill == 14 then
			data.MXPS_xp = data.MXPS_xp + (e.progress * config.SkillMysticismRate)
		end		
		if e.skill == 15 then
			data.MXPS_xp = data.MXPS_xp + (e.progress * config.SkillRestorationRate)
		end	
		if e.skill == 16 then
			data.MXPS_xp = data.MXPS_xp + (e.progress * config.SkillAlchemyRate)
		end	
		if e.skill == 17 then
			data.MXPS_xp = data.MXPS_xp + (e.progress * config.SkillUnarmoredRate)
		end
		if e.skill == 18 then
			data.MXPS_xp = data.MXPS_xp + (e.progress * config.SkillSecurityRate)
		end		
		if e.skill == 19 then
			data.MXPS_xp = data.MXPS_xp + (e.progress * config.SkillSneakRate)
		end
		if e.skill == 20 then
			data.MXPS_xp = data.MXPS_xp + (e.progress * config.SkillAcrobaticsRate)
		end
		if e.skill == 21 then
			data.MXPS_xp = data.MXPS_xp + (e.progress * config.SkillLightarmorRate)
		end	
		if e.skill == 22 then
			data.MXPS_xp = data.MXPS_xp + (e.progress * config.SkillShortbladeRate)
		end	
		if e.skill == 23 then
			data.MXPS_xp = data.MXPS_xp + (e.progress * config.SkillMarksmanRate)
		end		
		if e.skill == 24 then
			data.MXPS_xp = data.MXPS_xp + (e.progress * config.SkillMercantileRate)
		end
		if e.skill == 25 then
			data.MXPS_xp = data.MXPS_xp + (e.progress * config.SkillSpeechcraftRate)
		end		
		if e.skill == 26 then
			data.MXPS_xp = data.MXPS_xp + (e.progress * config.SkillHandtohandRate)
		end	
		e.progress = 0
	else
		if e.skill == 0 then
			e.progress = e.progress * config.SkillBlockRate
		end
		if e.skill == 1 then
			e.progress = e.progress * config.SkillArmorerRate
		end
		if e.skill == 2 then
			e.progress = e.progress * config.SkillMediumarmorRate
		end
		if e.skill == 3 then
			e.progress = e.progress * config.SkillHeavyarmorRate
		end
		if e.skill == 4 then
			e.progress = e.progress * config.SkillBluntweaponRate
		end		
		if e.skill == 5 then
			e.progress = e.progress * config.SkillLongbladeRate
		end
		if e.skill == 6 then
			e.progress = e.progress * config.SkillAxeRate
		end	
		if e.skill == 7 then
			e.progress = e.progress * config.SkillSpearRate
		end	
		if e.skill == 8 then
			e.progress = e.progress * config.SkillAthleticsRate
		end
		if e.skill == 9 then
			e.progress = e.progress * config.SkillEnchantRate
		end		
		if e.skill == 10 then
			e.progress = e.progress * config.SkillDestructionRate
		end
		if e.skill == 11 then
			e.progress = e.progress * config.SkillAlterationRate
		end	
		if e.skill == 12 then
			e.progress = e.progress * config.SkillIllusionRate
		end	
		if e.skill == 13 then
			e.progress = e.progress * config.SkillConjurationRate
		end
		if e.skill == 14 then
			e.progress = e.progress * config.SkillMysticismRate
		end		
		if e.skill == 15 then
			e.progress = e.progress * config.SkillRestorationRate
		end	
		if e.skill == 16 then
			e.progress = e.progress * config.SkillAlchemyRate
		end	
		if e.skill == 17 then
			e.progress = e.progress * config.SkillUnarmoredRate
		end
		if e.skill == 18 then
			e.progress = e.progress * config.SkillSecurityRate
		end		
		if e.skill == 19 then
			e.progress = e.progress * config.SkillSneakRate
		end
		if e.skill == 20 then
			e.progress = e.progress * config.SkillAcrobaticsRate
		end
		if e.skill == 21 then
			e.progress = e.progress * config.SkillLightarmorRate
		end	
		if e.skill == 22 then
			e.progress = e.progress * config.SkillShortbladeRate
		end	
		if e.skill == 23 then
			e.progress = e.progress * config.SkillMarksmanRate
		end		
		if e.skill == 24 then
			e.progress = e.progress * config.SkillMercantileRate
		end
		if e.skill == 25 then
			e.progress = e.progress * config.SkillSpeechcraftRate
		end		
		if e.skill == 26 then
			e.progress = e.progress * config.SkillHandtohandRate
		end
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

-- function GetSkillStr(param)
	-- if tes3.mobilePlayer:getSkillStatistic(param).type == 0 then
		-- return i18n('MajorSkillType')
	-- else
		-- if tes3.mobilePlayer:getSkillStatistic(param).type == 1 then
			-- return i18n('MinorSkillType')
		-- else
			-- if tes3.mobilePlayer:getSkillStatistic(param).type == 2 then
				-- return i18n('MiscSkillType')
			-- end
		-- end
	-- end	
-- end

local this = {}
function this.init()
    this.id_menu = tes3ui.registerID('example:MenuMXPS')
	this.id_xp = tes3ui.registerID('example:MenuMXPS_xp')
	this.id_ok = tes3ui.registerID('example:MenuMXPS_Ok')
	this.id_icon = tes3ui.registerID('example:MenuMXPS_icon')
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
	local img = p2:createImage{id = this.id_icon, path = tes3.getSkill(p4).iconPath}
	img.borderBottom = 1
	img.borderLeft = 5
	img.borderRight = 5
	img.borderTop = 1
	local sName = p2:createLabel{text = tes3.findGMST(p3).value}
	sName.borderRight = 5
	sName.borderTop = 5
	local p1 = p2:createButton{text = i18n('LVL')..' '..tostring(player.mobile:getSkillStatistic(p4).base)..' ('..i18n('XPNeed')..': '..tostring(math.round(p5,2))..')'}
	local aName = p2:createLabel{text = GetAttStr(p4)}
	aName.borderRight = 5
	aName.borderTop = 5			
	return p1
end

function MouseReg(p1,p2,p3,p4)
	p1:register('mouseClick', 
	function(e) 						
		local PR = p2
		local SK = p3
		local BU = p1
		local player = tes3.getPlayerRef()
		local data = tes3.getPlayerRef().data
		PR = player.mobile:getSkillProgressRequirement(SK)
		if data.MXPS_xp >= PR then	
			data.MXPS_xp = data.MXPS_xp - PR
			p4.text = i18n('XP')..': '..tostring(math.round(data.MXPS_xp,2))
			player.mobile:progressSkillToNextLevel(SK)
			PR = player.mobile:getSkillProgressRequirement(SK)
			BU.text = i18n('LVL')..' '..tostring(player.mobile:getSkillStatistic(SK).base)..' ('..i18n('XPNeed')..': '..tostring(math.round(PR,2))..')'
		end
	end)
end

function CreateSort(p1,p2,p3)
	local player = tes3.getPlayerRef()
	local tProgressRequirement = {}
	local tBlock = {}
	local tButton = {}
	local tSkill = {
		'sSkillBlock',
		'sSkillArmorer',
		'sSkillMediumarmor',
		'sSkillHeavyarmor',
		'sSkillBluntweapon',
		'sSkillLongblade',
		'sSkillAxe',
		'sSkillSpear',
		'sSkillAthletics',
		'sSkillEnchant',
		'sSkillDestruction',
		'sSkillAlteration',
		'sSkillIllusion',
		'sSkillConjuration',
		'sSkillMysticism',
		'sSkillRestoration',
		'sSkillAlchemy',
		'sSkillUnarmored',
		'sSkillSecurity',
		'sSkillSneak',
		'sSkillAcrobatics',
		'sSkillLightarmor',
		'sSkillShortblade',
		'sSkillMarksman',
		'sSkillMercantile',
		'sSkillSpeechcraft',
		'sSkillHandtohand'
	}	
	for i = 0, 26 do 
		if tes3.mobilePlayer:getSkillStatistic(i).type == p1 then
			if tes3.getSkill(i).attribute == p2 then
				tProgressRequirement[i] = player.mobile:getSkillProgressRequirement(i)
				tBlock[i] = CBlock(i,p3)
				tButton[i] = CButton(i,tBlock[i],tSkill[i+1],i,tProgressRequirement[i])
				MouseReg(tButton[i],tProgressRequirement[i],i,label_xp)
			end
		end
	end
end

function this.createWindow()
    if (tes3ui.findMenu(this.id_menu) ~= nil) then
        return
    end
	local data = tes3.getPlayerRef().data
	local player = tes3.getPlayerRef()	
	
	menu = tes3ui.createMenu{id = this.id_menu, fixedFrame = true}
    menu.alpha = 1.0
		
	label_xp = menu:createLabel{id = this.id_xp, text = i18n('XPTotal')..': '..tostring(math.round(data.MXPS_xp,2))}
	label_xp.wrapText = true
    label_xp.justifyText = "center"
	
	local block = menu
	if config.ScrollMenu == true then
		local block1 = menu:createBlock{}
		block1.width = 640
		block1.height = 480		
		block = block1:createVerticalScrollPane()
		block.width = 640
		block.height = 480
	end	
	
	local label1 = block:createLabel{text = i18n('MajorSkillText')}
	label1.borderAllSides = 2.5
	BorderBlock1 = block:createThinBorder{}
	BorderBlock1.autoHeight = true
	BorderBlock1.autoWidth = true
	BorderBlock1.flowDirection = "top_to_bottom"
	CreateSort(0,0,BorderBlock1)
	CreateSort(0,1,BorderBlock1)
	CreateSort(0,2,BorderBlock1)
	CreateSort(0,3,BorderBlock1)
	CreateSort(0,4,BorderBlock1)
	CreateSort(0,5,BorderBlock1)
	CreateSort(0,6,BorderBlock1)
	CreateSort(0,7,BorderBlock1)
	local label2 = block:createLabel{text = i18n('MinorSkillText')}
	label2.borderAllSides = 2.5
	BorderBlock2 = block:createThinBorder{}
	BorderBlock2.autoHeight = true
	BorderBlock2.autoWidth = true	
	BorderBlock2.flowDirection = "top_to_bottom"
	CreateSort(1,0,BorderBlock2)
	CreateSort(1,1,BorderBlock2)
	CreateSort(1,2,BorderBlock2)
	CreateSort(1,3,BorderBlock2)
	CreateSort(1,4,BorderBlock2)
	CreateSort(1,5,BorderBlock2)
	CreateSort(1,6,BorderBlock2)
	CreateSort(1,7,BorderBlock2)
	local label3 = block:createLabel{text = i18n('MiscSkillText')}
	label3.borderAllSides = 2.5
	BorderBlock3 = block:createThinBorder{}
	BorderBlock3.autoHeight = true
	BorderBlock3.autoWidth = true
	BorderBlock3.flowDirection = "top_to_bottom"	
	CreateSort(2,0,BorderBlock3)
	CreateSort(2,1,BorderBlock3)
	CreateSort(2,2,BorderBlock3)
	CreateSort(2,3,BorderBlock3)
	CreateSort(2,4,BorderBlock3)
	CreateSort(2,5,BorderBlock3)
	CreateSort(2,6,BorderBlock3)
	CreateSort(2,7,BorderBlock3)

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