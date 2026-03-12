--[[
	--=General Guidelines for making perks=--
	Obviously each perk is going to have it's own unique programming challenges, but there are certain tips that may lead to a smoother experience
	
	spells: A relatively easy way to make a perk work is by attaching a spell to it. You can use Magicka Expanded to create magic effects with custom scripted properties
	--NOTE: Magicka Expanded doesn't support "ability" type spells, so you'll have to use the standard tes3spell.create() function to make abilities with custom effects.
	--extra note: make sure you create your spell BEFORE a save game is loaded, or else you may have persistence issues with save games
	
	events: a custom event, "KBPerks:perkActivated" is sent whenever a perk is marked as activated using the activatePerk() function.
	-You can use this event for perk effects that only apply once, such as perks that grant permanent stat bonuses
	another event, "KBPerks:perkDeactivated" is sent when a perk is deactivated using the deactivatePerk() function.
	-both of these events included a property "perk" which is the perkID of the perk that was activated
	-use this event to remove any effects that are added by the perkActivated event
	-DO NOT set the activate flag on a perk manually, this will not send the perkActivate/Deactivated events, and won't add/remove spells from the player.
	-Be careful when using these events, because they don't get fired when save games are loaded, so make sure you have contingencies in place to ensure your functions still work correctly between saveloads
	
	playerData:hasPerk(id): this is a function in interop.player, and returns whether or not the player has the perk specified. This will return true even if the perk is deactivated
	
	getPerk(id): this returns the perkdata for the specified perkID, useful for checking the activated variable
	
	activatePerk(id): marks the specified perk as activated, adds any relevant spells to the player, and triggers a perkActivated event
	deactivatePerk(id): marks the specified perk as deactivated, removes any relevant spells from the player, and triggers a perkDeactivated event
	
]]


local common = require("KBLib.PerkSystem.common")
local public = {}
public.playerInfo = require("KBLib.PerkSystem.player")


--[[checkPerkConditions(perkID, atrTable, skillTable, prkTable)
	This function checks the conditions on a given perk and returns if said conditions are met.
	---perkID(string): Required - ID of perk to check
	---for regular use, do not provide the atrTable, skillTable, or prkTable parameters. Those are used by specific functions in my character progression mod
	
	The Following variables should be left as NIL during normal use. These only exist for compatibility with Kirbonated Character Progession.
	Documentation is included for posterity
	
	--for examples of how and why I use these tables, look at levelManager.lua in Kirbonated Character Progression
	
	---atrTable - a metatable containing data for the player's attributes during a level up in Kirbonated Character Progression
		--function expects each entry to use the same index as its entry in tes3.mobilePlayer.attributes (tes3.attributes[attribute name] + 1)
			--I.E. atrTable[1] should correspond to strength, atrTable[2] should correspond to intelligence, etc.
		--each entry should have a pointsSpent property (i.e. atrTable[1].pointsSpent), which is added to the players current attribute level when calculating perk requirements.
		In KCP this represents the amount of points the player has currently allocated into the associated stat
		
	---skillTable - a metatable containing data for the player's skills during a level up in Kirbonated Character Progression
		--see atrTable
	
	---prkTable - a metatable containing data for the player's perks during a level up in Kirbonated Character Progression
		--this table should be indexed by perkID, and should have a "chosen" property that denotes whether or not the perk has been selected.
		--This is VERY important if you plan on making your own perk menu, as this is what prevents you from selecting two perks that are mutually exclusive in the menu
]]
public.checkPerkConditions = function(perkID, atrTable, skillTable, prkTable)
	local checkPerk = common.perkList[perkID]
	
	if not checkPerk then
		common.err("Attempted to index unregistered perkID \"" .. perkID .. "\"")
		return false
	end
	
	if (checkPerk.perkExclude)  then 
		for i, p in ipairs(checkPerk.perkExclude) do
			if common.perkList[p] and  (public.playerInfo.hasPerk(p) or (prkTable and prkTable[p] and prkTable[p].chosen)) then
				return false
			end
		end 
	end
	
	if checkPerk.lvlReq > tes3.player.object.level then 
		return false
	end
	
	if (checkPerk.attributeReq) then
		for a, c in pairs(checkPerk.attributeReq) do
			if ((tes3.mobilePlayer[a].base + ((atrTable and atrTable[tes3.attribute[a] + 1].pointsSpent) or 0)) < c) then 
				return false
			end
		end
	end 
	
	
	if (checkPerk.skillReq) then
		for a, c in pairs(checkPerk.skillReq) do
			if ((tes3.mobilePlayer[a].base + ((skillTable and skillTable[tes3.skill[a]+1].pointsSpent) or 0)) < c) then
				return false
			end
		end 
	end 
	
	if (checkPerk.werewolfReq and (tes3.getGlobal("PCWerewolf") ~= 1)) then 
		return false
	end
	
	if(checkPerk.vampireReq and (tes3.getGlobal("PCVampire") ~= 1)) then 
		return false
	end
	
	if checkPerk.perkReq then
		for i, p in ipairs(checkPerk.perkReq) do
			if not common.perkList[p] then
				return false
			end
			if not public.playerInfo.hasPerk(p) then 
				return false 
			end
		end
	end
	
	if checkPerk.customReq and not checkPerk.customReq() then return false end
	
	return true
end



--[[
Perk Parameters
values must be declared unless otherwise specified
	
	id (string): unique identifier (ex. "kb_perk_magickaWell")
	name (string): Display name for perk (ex. "Magicka Well")
	description (string): Description to show in the perk selection menu
	
	isUnique(boolean): When set to true, this perk will not appear in the default perk list, meaning it will have to be manually added to perk selection menus to be acquired
	--use this setting for perks that you only want to be granted from controlled sources, such as quest rewards
	
	(optional)lvlReq(number): The character level that must be reached before the perk can be selected. defaults to 1 if not specified
	(optional)attributeReq(table): a table of required primary attribute values. ex) {attributeReq = {intelligence = 60, willpower = 60}}
	(optional)skillReq(table): a table of skill requirements for the perk. ex) {skillReq = {shortBlade = 50, athletics = 25}}
	(optional)werewolfReq(boolean) whether or not the perk is restricted to werewolves
	(optional)vampireReq(boolean) whether or not the perk is restricted to vampires
	(optional)perkReq(table): a table of perkIDs that the player must have to select the perk. ex) {perkReq = {"kb_perk_SoulSnatcher", "kb_perk_attunement"}}
	
	(optional)perkExclude(table): a table of perkIDs that will block this perk from being selected. ex) {perkExclude = {"kb_perk_atronachAffinity"}}
	
	(optional)hideInMenu(boolean): if set to true, the perk will be hidden from the player unless they meet the requirements to acquire it
	
	(optional)delayActivation(boolean): This can be set to true to prevent the perkActivate function from firing immediately upon granting the perk to the player. May be useful for complex scripted perk effects
	(optional)spells(table)[tes3spell]: list of spells/powers/abilities to add to the player upon selecting the perk
]]

public.createPerk = function(params)
	if common.perkList[params.id] then
		common.info("Perk ID \"" .. params.id .. "\" already present. No data was overwritten")
	else
	common.perkList[params.id] = {
		name = params.name,
		description = params.description,
		
		isUnique = params.isUnique or false,
		
		lvlReq = params.lvlReq or 0,
		attributeReq = params.attributeReq or false,
		skillReq = params.skillReq or false,
		werewolfReq = params.werewolfReq or false,
		vampireReq = params.vampireReq or false,
		perkReq = params.perkReq or false,
		
		customReq = params.customReq or false,
		customReqText = params.CustomReqText or false,
		
		perkExclude = params.perkExclude or false,
		
		
		hideInMenu = params.hideInMenu or false,
		
		
		delayActivation = params.delayActivation or false,
		spells = params.spells or false,
		
		activated = false --is set to true when the perk is activated
	}
	end
	return common.perkList[params.id]
end

public.activatePerk = function(params)
	if not common.perkList[params.id] then common.err("Attempted to activate nonexistent perk \"" .. params.id .. "\"") return false end
	if common.perkList[params.id].spells then 
		for i, s in ipairs(common.perkList[params.id].spells) do
			tes3.addSpell({reference = tes3.player, spell = s}) 
		end
	end
	common.perkList[params.id].activated = true
	common.playerData.activatedPerks[params.id] = true
	tes3.mobilePlayer:updateDerivedStatistics()
	event.trigger("KBPerks:perkActivated", {perk = params.id})
	return true
end
event.register("KBPerks:activatePerk", public.activatePerk, {priority = -1})

public.deactivatePerk = function(params)
	if not common.perkList[params.id] then common.err("Attempted to deactivate nonexistent perk \"" .. params.id .. "\"") return false end
	if common.perkList[params.id].spells then 
		for i, s in ipairs(common.perkList[params.id].spells) do
			if tes3.hasSpell{reference = tes3.player, spell = s} then
				tes3.removeSpell({reference = tes3.player, spell = s}) 
			end
		end
	end
	common.perkList[params.id].activated = false
	common.playerData.activatedPerks[params.id] = nil
	tes3.mobilePlayer:updateDerivedStatistics()
	event.trigger("KBPerks:perkDeactivated", {perk = params.id})
	return true
end
event.register("KBPerks:deactivatePerk", public.deactivatePerk, {priority = -1})

public.getPerk = function(id)
	if not common.perkList[id] then 
		return false
	end
	return common.perkList[id]
end

public.getPerkMasterList = function()
	return common.perkList
end

--[[showPerkMenu params
	perkPoints(number): Required - Number of perks the player can select
	perkList(table[perkID]): Optional -  overwrite perks list with a specific list of perkIDs. if not set this defaults to the default perk list
	header(String): Optional - overwrite the header text for the menu
	ignoreReq(Boolean): Optional - If true, Makes all entries in the perk list selectable, even if their requirements are not met
]]
public.showPerkMenu = function(params)

	frame = tes3ui.createMenu{id = tes3ui.registerID("KBPerks:PerkMenu"), fixedFrame = true}
	frame.text = (params.header or "Perk Selection")
	frame.flowDirection = "top_to_bottom"
	frame.childAlignX = -1
	frame.visible = true
	
	--perks page starts here
	perksSelected = 0
	useCommonList = true
	if params.perkList then
		useCommonList = false
	end
		headerBlock = frame:createThinBorder{id = tes3ui.registerID("KBPerks:perksPageHeader")}
		headerBlock.widthProportional = 1.0
		headerBlock.autoHeight = true
		headerBlock.paddingAllSides = 5
			
			headerLabel = headerBlock:createLabel{text = (params.header or "Выбор талантов")}
			headerLabel.color = tes3ui.getPalette("header_color")
			
		perksPage = frame:createBlock{id = tes3ui.registerID("KBPerks:perksPage")}
		perksPage.visible = true
		perksPage.flowDirection = "left_to_right"
		perksPage.autoHeight = true
		perksPage.autoWidth = true
		perksPage.widthProportional = 1.0
		perksPage.minHeight = 512
		perksPage.minWidth = 780
		perksPage.childAlignX = -1
		perksPage.childAlignY = 0
	
			perksPage_borderL = perksPage:createThinBorder{id = tes3ui.registerID("KBPerks:leftBorder")}
			perksPage_borderL.flowDirection = "top_to_bottom"
			perksPage_borderL.widthProportional = 0.6
			
			perksPage_borderR = perksPage:createThinBorder{id = tes3ui.registerID("KBPerks:rightBorder")}
			perksPage_borderR.flowDirection = "top_to_bottom"
			perksPage_borderR.widthProportional = 1.4
	
				perksPage_perksRem = perksPage_borderL:createLabel({text = "Очки талантов: " .. (params.perkPoints) - perksSelected})
	
				perksPage_borderL_vScroll = perksPage_borderL:createVerticalScrollPane{id = tes3ui.registerID("KBPerks:leftScrollPane")}
				perksPage_borderR_vScroll = perksPage_borderR:createVerticalScrollPane{id = tes3ui.registerID("KBPerks:rightScrollPane")}
		
				perksPage_borderL_vScroll.minHeight = 512
				perksPage_borderR_vScroll.minHeight = 512
	
					perksPage_borderL_layout = perksPage_borderL_vScroll:createBlock()
					perksPage_borderL_layout.flowDirection = "top_to_bottom"
					perksPage_borderL_layout.visible = true
					perksPage_borderL_layout.autoHeight = true
					perksPage_borderL_layout.autoWidth = true

					perksPage_borderR_layout = perksPage_borderR_vScroll:createBlock()
					perksPage_borderR_layout.flowDirection = "top_to_bottom"
					perksPage_borderR_layout.autoHeight = true
					perksPage_borderR_layout.widthProportional = 1.0

					perksPage_availablePerks = perksPage_borderL_layout:createBlock()
					perksPage_availablePerks.flowDirection = "top_to_bottom"
					perksPage_availablePerks.autoHeight = true
					perksPage_availablePerks.autoWidth = true
					perksPage_availablePerks.visible = true
	
					perksPage_blockedPerks = perksPage_borderL_layout:createBlock()
					perksPage_blockedPerks.flowDirection = "top_to_bottom"
					perksPage_blockedPerks.autoHeight = true
					perksPage_blockedPerks.autoWidth = true
					perksPage_blockedPerks.visible = true
	
					perksPage_perkInfo_Name = perksPage_borderR_layout:createLabel()
					
					perksPage_borderR_vScroll:createDivider()
	
					perksPage_perkInfo_Cond = perksPage_borderR_layout:createLabel()
					perksPage_perkInfo_Desc = perksPage_borderR_layout:createLabel()
					perksPage_perkInfo_Name.widthProportional = 1.0
					perksPage_perkInfo_Name.wrapText = true
					perksPage_perkInfo_Cond.widthProportional = 1.0
					perksPage_perkInfo_Cond.wrapText = true
					perksPage_perkInfo_Desc.widthProportional = 1.0
					perksPage_perkInfo_Desc.wrapText = true
	
	local prk = {}
	
	local function updatePerkState()
		for id, data in pairs(prk) do
			if data.chosen then 
				data.element.widget.state = 4
				data.blockedElement.widget.state = 4
			elseif params.ignoreReq or public.checkPerkConditions(id, nil, nil, prk) then 
				data.element.widget.state = 1 
				data.blockedElement.widget.state = 1
			else 
				data.element.widget.state = 2 
				data.blockedElement.widget.state = 2
			end
			data.element.visible = (public.checkPerkConditions(id, nil, nil, prk) or params.ignoreReq)
			
			if common.perkList[id].hideInMenu then data.blockedElement.visible = false 
			else data.blockedElement.visible = (not params.ignoreReq) and (not public.checkPerkConditions(id, nil, nil, prk))
			end
		end
		perksPage_perksRem.text = "Очки талантов: " .. params.perkPoints - perksSelected
	end
	
	local function createPerkEntry(id, perkData)
		if (public.playerInfo.hasPerk(id)) then prk[id] = nil
		else
		prk[id] = {
			chosen = false, 
			element = perksPage_availablePerks:createTextSelect({id = tes3ui.registerID("KCP:selectable_" .. id), text = perkData.name,	state = 1}), 
			blockedElement = perksPage_blockedPerks:createTextSelect({id = tes3ui.registerID("KCP:blocked_" .. id), text = perkData.name,	state = 1}),
		}
		
		prk[id].element.widthProportional = 1.0
		prk[id].blockedElement.widthProportional = 1.0
		prk[id].element.wrapText = true
		prk[id].blockedElement.wrapText = true
		
		prk[id].element.widget.over = tes3ui.getPalette("normal_over_color")
		prk[id].element.widget.pressed = tes3ui.getPalette("normal_pressed_color")
		prk[id].element.widget.idleDisabled = tes3ui.getPalette("disabled_color")
		prk[id].element.widget.overDisabled = tes3ui.getPalette("disabled_over_color")
		prk[id].element.widget.pressedDisabled = tes3ui.getPalette("disabled_over_color")
		prk[id].element.widget.idleActive = tes3ui.getPalette("active_color")
		prk[id].element.widget.overActive = tes3ui.getPalette("active_over_color")
		prk[id].element.widget.pressedActive = tes3ui.getPalette("active_pressed_color")
		prk[id].blockedElement.widget.over = tes3ui.getPalette("normal_over_color")
		prk[id].blockedElement.widget.pressed = tes3ui.getPalette("normal_pressed_color")
		prk[id].blockedElement.widget.idleDisabled = tes3ui.getPalette("disabled_color")
		prk[id].blockedElement.widget.overDisabled = tes3ui.getPalette("disabled_over_color")
		prk[id].blockedElement.widget.pressedDisabled = tes3ui.getPalette("disabled_over_color")
		prk[id].blockedElement.widget.idleActive = tes3ui.getPalette("active_color")
		prk[id].blockedElement.widget.overActive = tes3ui.getPalette("active_over_color")
		prk[id].blockedElement.widget.pressedActive = tes3ui.getPalette("active_pressed_color")
		
		prk[id].element:register("mouseOver", function()
			local condition = "Требования:\n"
			if perkData.lvlReq then condition = (condition .. "Уровень " .. perkData.lvlReq .. ",\n") end
			if perkData.attributeReq then
				for a, v in pairs(perkData.attributeReq) do
					condition = (condition .. tes3.getAttributeName(tes3.attribute[a]) .. " " .. v .. ", ")
				end
				condition = (condition .. "\n")
			end
			if perkData.skillReq then
				for a, v in pairs(perkData.skillReq) do
					condition = (condition .. tes3.getSkillName(tes3.skill[a]) .. " " .. v .. ", ")
				end
				condition = (condition .. "\n")
			end
			if perkData.perkReq then
				for i, v in ipairs(perkData.perkReq) do
					condition = (condition .. perkList[v].name .. ", ")
				end
				condition = (condition .. "\n")
			end
			if perkData.werewolfReq or perkData.vampireReq then
				if not perkData.vampireReq then condition = (condition .. "Lycanthropy, \n")
				elseif not perkData.werewolfReq then condition = (condition .. "Vampirism, \n")
				else condition = (condition .. "Vampire/Lycanthropy hybrid, \n")
				end
				condition = (condition .. "\n")
			end
			if perkData.customReqText then condition = (condition .. perkData.customReqText .. "\n") end
			perksPage_perkInfo_Name.text = perkData.name
			perksPage_perkInfo_Cond.text = condition
			perksPage_perkInfo_Desc.text = perkData.description
			perksPage_borderR_vScroll:updateLayout()
		end)
		prk[id].blockedElement:register("mouseOver", function()
			local condition = "Требования:\n"
			if perkData.lvlReq > 0 then condition = (condition .. "Уровень " .. perkData.lvlReq .. ",\n") end
			if  perkData.attributeReq then
				for a, v in pairs(perkData.attributeReq) do
					condition = (condition .. tes3.getAttributeName(tes3.attribute[a]) .. " " .. v .. ", ")
				end
				condition = (condition .. "\n")
			end
			if perkData.skillReq then
				for a, v in pairs(perkData.skillReq) do
					condition = (condition .. tes3.getSkillName(tes3.skill[a]) .. " " .. v .. ", ")
				end
				condition = (condition .. "\n")
			end
			if perkData.perkReq then
				for i, v in ipairs(perkData.perkReq) do
					condition = (condition .. perkList[v].name .. ", ")
				end
				condition = (condition .. "\n")
			end
			if perkData.werewolfReq or perkData.vampireReq then
				if not perkData.vampireReq then condition = (condition .. "Lycanthropy,")
				elseif not perkData.werewolfReq then condition = (condition .. "Vampirism,")
				else condition = (condition .. "Vampire/Lycanthropy hybrid,")
				end
				condition = (condition .. "\n")
			end
			if perkData.customReqText then condition = (condition .. perkData.customReqText .. "\n") end
			perksPage_perkInfo_Name.text = perkData.name
			perksPage_perkInfo_Cond.text = condition
			perksPage_perkInfo_Desc.text = perkData.description
			perksPage_borderR_vScroll:updateLayout()
		end)
		prk[id].element:register("mouseClick", function()
			if prk[id].element.widget.state == 2 then return end
			if prk[id].chosen then 
				prk[id].chosen = false
				perksSelected = perksSelected - 1
			elseif (perksSelected < math.floor(params.perkPoints / 1)) then --floors perkpoints because perk point can be a fraction
				prk[id].chosen = true
				perksSelected = perksSelected + 1
			end
			updatePerkState()
		end)
		end
		updatePerkState()
	end
	
	if useCommonList then
		for id, perkData in pairs(common.perkList) do
			if (not perkData.isUnique) then
				createPerkEntry(id, perkData)
			end
		end
	else
		for _, id in ipairs(params.perkList) do
			if not common.perkList[id] then
				common.err("Attempted to index nonexistent perk \"" .. id .. "\"")
			else createPerkEntry(id, common.perkList[id])
			end
		end
	end
	updatePerkState()

	--container for the next and back buttons
	frameButtons = frame:createThinBorder()
	frameButtons.autoHeight = true
	frameButtons.widthProportional = 1.0
	frameButtons.visible = true
	frameButtons.childAlignX = 1
	
	
	buttonNext = frameButtons:createButton()
	buttonNext.text = "Конец"
	buttonNext.widget.pressed = tes3ui.getPalette("normal_pressed_color")
	buttonNext.widget.idleActive = tes3ui.getPalette("active_color")
	buttonNext.widget.pressedActive = tes3ui.getPalette("active_pressed_color")
	
	--"next" button code
	buttonNext.visible = true
	buttonNext:register("mouseClick", function()
		for i, t in pairs(prk) do
			if t.chosen then 
				public.playerInfo.grantPerk(i) 
			end
		end
	
		frame.visible = false
		tes3ui.leaveMenuMode((frame:getTopLevelMenu()).id)
		frame:getTopLevelMenu():destroy()
	end)
	frame:updateLayout()
	
end

return public