local common = require("KBev.ProgressionMod.common")
local mcm = require("KBev.ProgressionMod.mcm")
local kcp = require("KBev.ProgressionMod.interop")
local player = kcp.playerData
local page --this keeps track of what menu is displayed in the level up menu. I initialize it as a local in this file as redundancy.

--table of the vanilla levelUpMessages
local levelUpMessage = {
	[2] = "Вы понимаете, что до этого момент ваша жизнь проходила мимо вас, как будто во сне. И вдруг, после событий последних нескольких дней, вы наконец поняли, что живы.",
	[3] = "Вы понимаете, что узнали секрет успеха. Все дело в сосредоточенности.",
	[4] = "Неожиданно все становится ясно. Вам просто надо сосредоточиться. Терять время и силы - страшный грех. Но как вы могли понять это, не получив опыта, не рискуя и не беря на себя ответственность за все неудачи?",
	[5] = "Вам все дается немного легче, скорее на подсознательном уровне, результаты становятся гораздо лучше. Как будто бы у вас обострились все чувства и инстинкты.",
	[6] = "Вы ощущаете себя более сведущим, более открытым новым идеям. Вы многое узнали о Морроувинде. Сложно поверить, что совсем недавно вы были настолько невежественны - но очень многому еще придется научиться.",
	[7] = "Вы решаете по-прежнему не давать себя поблажек. Возможно, вы значите больше, чем вам казалось раньше.",
	[8] = "Секрет, судя по всему, заключается в тяжелом труде, да, но это и наваждение, и вдохновение.",
	[9] = "Вам все дается немного легче, скорее на подсознательном уровне, результаты становятся гораздо лучше. Как будто бы у вас обострились все чувства и инстинкты.",
	[10] = "Сегодня вы проснулись с совершенно новыми ощущениями. Вы больше не боитесь неудач. Неудача - это всего лишь возможность узнать что-то новое.",
	[11] = "Быть хитрым - не больно. А немного удачи никогда не помешает. Но ключевой момент - терпение и тяжелый труд. Зато когда виден результат - это ВЕЛИКОЛЕПНО!",
	[12] = "Вы не можете поверить в то, насколько это просто. Нужно всего лишь продолжать -- это безумие. А потом, вдруг, во всем находится свой смысл, и все, что вы делаете, превращается в золото.",
	[13] = "Поразительно. Вчера это было сложно, а сегодня так просто. Всего лишь крепкий здоровый сон, и можно забыть о том, как быть глупым.",
	[14] = "Сегодня вы просыпаетесь, и вас переполняет энергия и новые идеи, каким-то образом вы понимаете, что сегодня все изменилось. Всего один день, а какая разница.",
	[15] = "Сегодня вы вдруг понимаете, что за ту жизнь, которую вы жили, теперь расплачивается ваше тело -- есть пределы человеческим возможностям, вероятно, вы достигли этих пределов. Вам всегда было интересно, как это - стареть. Что ж, теперь вы это знаете.",
	[16] = "Вы слишком сильно старались, слишком много думали. Расслабьтесь. Будьте собой. Делайте маленькие дела, большие позаботятся о себе сами.",
	[17] = "Жизнь продолжается. Вы все еще можете становиться хитрее, умнее, опытнее - но ваша душа и ваше тело никогда уже не станут молодыми.",
	[18] = "Сейчас самое важное - оставаться на пике как можно дольше. Сегодня вы можете быть самым сильным человеком на земле, но всегда придет кто-то, кто будет моложе, и он бросит вам вызов.",
	[19] = "У вас все хорошо. Вероятно, вы лучший. Именно поэтому вам так сложно развиваться дальше. Но вы продолжаете стараться, потому что это ваша натура.",
	[20] = "Лучше чем сегодня вы уже не будете. Если вам повезет, если вы приложите нечеловеческие усилия, вероятно, вам удастся не соскользнуть назад. Но рано или поздно это случится, готовьтесь пропустить шаг, пропустить удар, пропустить какую-то подробность - и тогда вы пропадете навсегда.",
}

local nextLevel = 1

--gets the player's class image. for custom classes it returns an image based on what specialization the class is
local function getPlayerClassImage()
	playerClass = tes3.player.object.class
	if tes3.getFileExists("textures\\levelup\\" .. string.lower(playerClass.name .. ".dds")) then
		return ("textures\\levelup\\" .. string.lower(playerClass.name .. ".dds"))
	elseif playerClass.specialization == tes3.specialization.magic then
		return "textures\\levelup\\mage.dds"
	elseif playerClass.specialization == tes3.specialization.stealth then
		return "textures\\levelup\\thief.dds"
	else return "textures\\levelup\\warrior.dds" 
	end
end

--redundancy for the nextLevel variable
local function onLoaded(e)
	nextLevel = tes3.player.object.level
end
event.register("loaded", onLoaded)

--[[ createStat(tbl, nam, val, bl, typ)
	creates an abstract data table and a tes3uiElement to represent one of the player's statistics
	
	tbl = (table) the metaTable to index the data table into
	nam = (string) the displayed name of the statistic
	val = (number) the initial value to set the stat display to
	bl = (tes3uiElement) the tes3uiElement to act as a parent for the stat's ui element
	typ = (string) the string identifier of the statistic type. should be "atr", "mjr", "mnr", or "msc"
]]
local function createStat(tbl, nam, val, bl, typ)
		--initialize data
		tbl.base = val
		tbl.type = typ
		tbl.pointsSpent = 0
		
		--create ui block
		tbl.block = bl:createBlock{id = tes3ui.registerID("KCP:menuLevelUp_" .. nam)}
		tbl.block.flowDirection = "left_to_right"
		tbl.block.childAlignX = -1
		tbl.block.paddingLeft = 10
		tbl.block.widthProportional = 1
		tbl.block.autoHeight = true
		tbl.block.visible = true
		
			--create stat label
			tbl.label = tbl.block:createLabel({text = nam})
			tbl.label.visible = true
		
			--create value block (this will contain a label representing the stat's current value, as well as it's "+" and "-" buttons
			tbl.valBlock = tbl.block:createBlock{id = tes3ui.registerID("KCP:menuLevelUp_" .. nam .. "_value")}
			tbl.valBlock.autoWidth = true
			tbl.valBlock.autoHeight = true
		
				--create "-" button
				tbl.button_minus = tbl.valBlock:createTextSelect()
				tbl.button_minus.text = "-"
				tbl.button_minus.visible = true
		
				--set up colors
				tbl.button_minus.widget.idleActive = tes3ui.getPalette("active_color")
				tbl.button_minus.widget.pressedActive = tes3ui.getPalette("active_pressed_color")
				tbl.button_minus.widget.overActive = tes3ui.getPalette("active_over_color")
				tbl.button_minus.widget.idleDisabled = tes3ui.getPalette("disabled_color")
				tbl.button_minus.widget.pressedDisabled = tes3ui.getPalette("disabled_pressed_color")
				tbl.button_minus.widget.overDisabled = tes3ui.getPalette("disabled_over_color")
				
				--create current value label
				tbl.value = tbl.valBlock:createLabel({text = tostring(tbl.base + tbl.pointsSpent)})
				tbl.value.visible = true
				
				--create "+" button
				tbl.button_plus = tbl.valBlock:createTextSelect()
				tbl.button_plus.text = "+"
				tbl.button_plus.visible = true
				
				--set up colors
				tbl.button_plus.widget.idleActive = tes3ui.getPalette("active_color")
				tbl.button_plus.widget.pressedActive = tes3ui.getPalette("active_pressed_color")
				tbl.button_plus.widget.overActive = tes3ui.getPalette("active_over_color")
				tbl.button_plus.widget.idleDisabled = tes3ui.getPalette("disabled_color")
				tbl.button_plus.widget.pressedDisabled = tes3ui.getPalette("disabled_pressed_color")
				tbl.button_plus.widget.overDisabled = tes3ui.getPalette("disabled_over_color")
	end
--[[
finalizeChanges(atr, skl, prk) - handles the final steps of levelling up, updating all necessary values.
	atr = attribute data metatable
	skl = skill data metatable
	prk = perk data metatable
]]
local function finalizeChanges(atr, skl, prk)
	
	--Update Player Attributes
	for i, t in ipairs(atr) do
		if t.pointsSpent > 0 then
			tes3.modStatistic{reference = tes3.player, attribute = i-1, value = t.pointsSpent}
		end
	end
	--Update Player Skills
	for i, t in ipairs(skl) do
		if t.pointsSpent > 0 then
			tes3.modStatistic({reference = tes3.player, skill = i-1, value = t.pointsSpent})
		end
	end
	--Add any perks the player selected
	for i, t in pairs(prk) do
		if t.chosen then 
			kcp.perk.playerInfo.grantPerk(i) 
			 common.playerData.levelPoints.prk =  common.playerData.levelPoints.prk - 1 --detract perk points, since this isn't done in the levelUpMenu
		end
	end
	--HP code
	
	--level hp = (strength + (endurance / 2) + (0.1 * end * level - 1)
	tes3.setStatistic({reference = tes3.mobilePlayer, name = "health", value = (tes3.mobilePlayer.strength.base + tes3.mobilePlayer.endurance.base) / 2 + (0.1 * tes3.mobilePlayer.endurance.base * (nextLevel - 1))})
	
	--reset player levelup condition
	tes3.mobilePlayer.levelUpProgress = 0
	
	
	--update the number displayed for the player's level in the stats menu
	local menu = tes3ui.findMenu(tes3ui.registerID("MenuStat"))
    local elem = menu:findChild(tes3ui.registerID("MenuStat_level"))
    elem.text = tostring(nextLevel)
    menu:updateLayout()
	
	--check if the player is eligible for the next character level advancement
	event.trigger("KCP:checkForLevelUP")
end
--[[
asButtonScript({type = ..., tbl = ..., points = ..., incMax = ...}) - Script that controls the behavior of the "+" and "-" buttons next to skills and attributes
	parameters (table):
		type = string identifier for the button type. should be "add" or "sub". in hindsight I should have made this a bool but oh well
		tbl = the data table that represents the stat this button modifies. see creatStat(...) for context
		points = the string identifier for the type of points this needs to increment/decrement. should be "atr", "mjr", "mnr", or "msc"
		incMax = the maximum amount of points that can be allocated to this stat. this is calculated dynamically in buildLevelUpMenu(...)
]]
local function asButtonScript(params)
	if params.type == "add" then
		if (params.tbl.base + params.tbl.pointsSpent < 100) and ( common.playerData.levelPoints[params.points] > 0) and (params.tbl.pointsSpent < params.incMax) then
			params.tbl.pointsSpent = params.tbl.pointsSpent + 1
			 common.playerData.levelPoints[params.points] =  common.playerData.levelPoints[params.points] - 1 
		elseif ( common.playerData.levelPoints[params.points] > 1) and (params.tbl.pointsSpent < params.incMax) then
			params.tbl.pointsSpent = params.tbl.pointsSpent + 1
			 common.playerData.levelPoints[params.points] =  common.playerData.levelPoints[params.points] - 2
		end
	end
	if params.type == "sub" then
		if (params.tbl.base + params.tbl.pointsSpent < 100) and (params.tbl.pointsSpent > 0) then
			 common.playerData.levelPoints[params.points] =  common.playerData.levelPoints[params.points] + 1
			params.tbl.pointsSpent = params.tbl.pointsSpent - 1
		elseif (params.tbl.pointsSpent > 0) then
			 common.playerData.levelPoints[params.points] =  common.playerData.levelPoints[params.points] + 2
			params.tbl.pointsSpent = params.tbl.pointsSpent - 1
		end
	end
	params.tbl.value.text = tostring(params.tbl.base + params.tbl.pointsSpent)
end
--[[
updateASButtons(tbl, typ) 
updates the "+" and "-" buttons next to skills and attributes in the levelup menu
	tbl = The metatable to iterate through, this will be either the atr[] or skl[] tables defined in buildLevelUpMenu()
	
	typ = The string identifier for the type of stat to check. should be "atr", "mjr", "mnr", or "msc".
]]
local function updateASButtons(tbl, typ)
	for i, data in pairs(tbl) do
		if data.type == typ then
			if ( common.playerData.levelPoints[typ] > 0) and (data.pointsSpent < mcm[typ .. "IncMax"]) and ((data.base + data.pointsSpent < 100) or  common.playerData.levelPoints[typ] > 1) then
				data.button_plus.widget.state = tes3.uiState.active
			else data.button_plus.widget.state = tes3.uiState.disabled end
			
			if (data.pointsSpent > 0) then data.button_minus.widget.state = tes3.uiState.active
			else data.button_minus.widget.state = tes3.uiState.disabled end
		end
	end
end

--[[LEVEL UP UI]]
--constructs the level up menu
local function buildLevelUpMenu(e)
	
	frame = e.children[2] --grabs the content section of the levelup menu
	frame:destroyChildren() --destroys the vanilla ui elements so that we can replace them with our own
	
	--set up frame settings
	frame.flowDirection = "top_to_bottom"
	frame.autoHeight = true
	frame.autoWidth = true
	frame.childAlignX = -1
	frame.paddingAllSides = 5
	
	--menu keeps track of a "page" variable that determines which page (intro/splash text page, attributes/skills page, perks page) is being displayed
	page = 0 --initialize to page 0
	
		--set up parameters for intro page
		introPage = frame:createBlock{id = tes3ui.registerID("KCP:introPage")}
		introPage.flowDirection = "top_to_bottom"
		introPage.autoHeight = true
		introPage.width = 460
		introPage.childAlignX = 0.5
		introPage.childAlignY = 0
		introPage.paddingAllSides = 5
		introPage.visible = (page == 0)
			--header: box at top of page that displays which level you are advancing to
			header_layout = introPage:createThinBorder{id = tes3ui.registerID("KCP:introHeader")}
			header_layout.paddingAllSides = 5
			header_layout.widthProportional = 1
			header_layout.autoHeight = true
				header_text = header_layout:createLabel{text = "Вы достигли уровня " .. nextLevel .. "!"}
				header_text.color = tes3ui.getPalette("active_color")
				header_text.widthProportional = 1
				header_text.autoHeight = true
				header_text.wrapText = true
				header_text.justifyText = "center"
			
			--this box displays the image for your character class
			classBanner_layout = introPage:createThinBorder{id = tes3ui.registerID("KCP:classBanner")}
			classBanner_layout.paddingAllSides = 5
			classBanner_layout.autoWidth = true
			classBanner_layout.autoHeight = true
			classBanner_layout.visible = true
				classBanner = classBanner_layout:createImage({path = getPlayerClassImage()})
				classBanner.imageScaleX = 1.2
				classBanner.imageScaleY = 1.2
				classBanner.visible = true
				classBanner_layout.borderBottom = 10
				
			--this box displays the flavor text for the level you have just reached. this pulls from the vanilla list of level up messages
			b_Flavor = introPage:createThinBorder{id = tes3ui.registerID("KCP:flavorText")}
			b_Flavor.widthProportional = 1
			b_Flavor.borderAllSides = 10
			b_Flavor.paddingAllSides = 5
			b_Flavor.autoHeight = true
				FlavorText = b_Flavor:createLabel{id = tes3ui.registerID("KCP:LevelUPFlavorText"),text = (levelUpMessage[nextLevel] or "Результаты тяжелой работы всегда кажутся окружающим всего лишь везением. Но вы знаете, что полностью заслужили все, что получили.")}
				FlavorText.widthProportional = 1
				FlavorText.wrapText = true
				FlavorText.autoHeight = true
				FlavorText.justifyText = "center"
			
			--this summarizes what you are gaining for your level up, displaying your attribute, skill, and perk points
			b_summary = introPage:createThinBorder{id = tes3ui.registerID("KCP:summary")}
			b_summary.flowDirection = "top_to_bottom"
			b_summary.widthProportional = 1
			b_summary.borderAllSides = 10
			b_summary.paddingAllSides = 5
			b_summary.autoHeight = true
				atrText = b_summary:createLabel{id = tes3ui.registerID("KCP:summary_attributes"), text = "Очки характеристик: " .. common.playerData.levelPoints.atr}
				atrText.widthProportional = 1
				atrText.wrapText = true
				atrText.autoHeight = true
				atrText.justifyText = "center"
				atrText.visible = (common.playerData.levelPoints.atr > 0)
				
				mjrText = b_summary:createLabel{id = tes3ui.registerID("KCP:summary_majorSkills"), text = "Очки главных навыков: " .. common.playerData.levelPoints.mjr}
				mjrText.widthProportional = 1
				mjrText.wrapText = true
				mjrText.autoHeight = true
				mjrText.justifyText = "center"
				mjrText.visible = (common.playerData.levelPoints.mjr > 0)
				
				mnrText = b_summary:createLabel{id = tes3ui.registerID("KCP:summary_minorSkills"), text = "Очки важных навыков: " .. common.playerData.levelPoints.mnr}
				mnrText.widthProportional = 1
				mnrText.wrapText = true
				mnrText.autoHeight = true
				mnrText.justifyText = "center"
				mnrText.visible = (common.playerData.levelPoints.mnr > 0)
				
				mscText = b_summary:createLabel{id = tes3ui.registerID("KCP:summary_miscSkills"), text = "Очки маловажных навыков: " .. common.playerData.levelPoints.msc}
				mscText.widthProportional = 1
				mscText.wrapText = true
				mscText.autoHeight = true
				mscText.justifyText = "center"
				mscText.visible = (common.playerData.levelPoints.msc > 0)
				
				prkText = b_summary:createLabel{id = tes3ui.registerID("KCP:summary_perks"), text = "Очки талантов: " .. common.playerData.levelPoints.prk}
				prkText.widthProportional = 1
				prkText.wrapText = true
				prkText.autoHeight = true
				prkText.justifyText = "center"
				prkText.visible = (common.playerData.levelPoints.prk > 0)
				
				dmyText = b_summary:createLabel{id = tes3ui.registerID("KCP:summary_dummy"), text = "Нет изменений в характеристиках, навыках или талантах"}
				dmyText.widthProportional = 1
				dmyText.wrapText = true
				dmyText.autoHeight = true
				dmyText.justifyText = "center"
				dmyText.visible = not ((common.playerData.levelPoints.atr > 0) or (common.playerData.levelPoints.mjr > 0) or (common.playerData.levelPoints.mnr > 0) or (common.playerData.levelPoints.msc > 0) or (common.playerData.levelPoints.prk > 0))

	--stats page starts here. this page is where you allocate attribute and skill points
		atr = {} --attribute data metatable
		skl = {} --skill data metatable
		statsPage = frame:createBlock{id = tes3ui.registerID("KCP:statsPage")}
		statsPage.visible = (page == 1)
		statsPage.flowDirection = "left_to_right"
		statsPage.width = 780
		statsPage.height = 512
	
		statsPage.childAlignX = 0
		statsPage.childAlignY = 0
			--divides the stats page into two halves. left is used for attributes and derived statistics, while right is used for skills
			statsPage_left = statsPage:createBlock{id = tes3ui.registerID("KCP:statsPage_left")}
			statsPage_left.visible = true
			statsPage_left.autoHeight = true
			statsPage_left.autoWidth = true
			statsPage_left.widthProportional = 0.8
			statsPage_left.heightProportional = 1.0
			statsPage_left.flowDirection = "top_to_bottom"
	
			statsPage_right = statsPage:createBlock{id = tes3ui.registerID("KCP:statsPage_right")}
			statsPage_right.visible = true
			statsPage_right.autoHeight = true
			statsPage_right.autoWidth = true
			statsPage_right.widthProportional = 1.2
			statsPage_right.heightProportional = 1.0
				
				--this displays your health, magicka, and fatigue, and updates in real time as you allocate stats
				hmf_border = statsPage_left:createThinBorder{id = tes3ui.registerID("KCP:hmf_border")}
				hmf_border.visible = true
				hmf_border.autoHeight = true
				hmf_border.autoWidth = true
				hmf_border.widthProportional = 1.0
					hmf_layout = hmf_border:createBlock{id = tes3ui.registerID("KCP:hmf_layout")}
					hmf_layout.visible = true
					hmf_layout.autoHeight = true
					hmf_layout.autoWidth = true
					hmf_layout.widthProportional = 1.0
					hmf_layout.flowDirection = "top_to_bottom"
					hmf_layout.paddingAllSides = 5
	
						hmf_health = hmf_layout:createBlock{id = tes3ui.registerID("KCP:hmf_health")}
						hmf_health.borderBottom = 5
						hmf_health.visible = true
						hmf_health.flowDirection = "left_to_right"
						hmf_health.widthProportional = 1.0
						hmf_health.autoWidth = true
						hmf_health.autoHeight = true
						hmf_health.childAlignX = -1
							hmf_healthText = hmf_health:createLabel({text = "Здоровье"})
							hmf_healthText.visible = true
							hmf_healthBar = hmf_health:createFillBar({current = (tes3.mobilePlayer.strength.base + tes3.mobilePlayer.endurance.base) / 2 + (0.1 * tes3.mobilePlayer.endurance.base * (nextLevel - 1)), max = (tes3.mobilePlayer.strength.base + tes3.mobilePlayer.endurance.base) / 2 + (0.1 * tes3.mobilePlayer.endurance.base * (nextLevel - 1))})
							hmf_healthBar.widget.fillColor = tes3ui.getPalette("health_color")
							hmf_healthBar.visible = true
	
						hmf_magicka = hmf_layout:createBlock{id = tes3ui.registerID("KCP:hmf_magicka")}
						hmf_magicka.visible = true
						hmf_magicka.flowDirection = "left_to_right"
						hmf_magicka.widthProportional = 1.0
						hmf_magicka.autoHeight = true
						hmf_magicka.autoWidth = true
						hmf_magicka.childAlignX = -1
							hmf_magickaText = hmf_magicka:createLabel({text = "Магия"})
							hmf_magickaText.visible = true
							hmf_magickaBar = hmf_magicka:createFillBar({current = tes3.mobilePlayer.intelligence.base * tes3.mobilePlayer.magickaMultiplier.current, max = tes3.mobilePlayer.intelligence.base * tes3.mobilePlayer.magickaMultiplier.current})
							hmf_magickaBar.widget.fillColor = tes3ui.getPalette("magic_color")
							hmf_magickaBar.visible = true
				
						hmf_fatigue = hmf_layout:createBlock{id = tes3ui.registerID("KCP:hmf_fatigue")}
						hmf_fatigue.borderTop = 5
						hmf_fatigue.visible = true
						hmf_fatigue.flowDirection = "left_to_right"
						hmf_fatigue.widthProportional = 1.0
						hmf_fatigue.autoHeight = true
						hmf_fatigue.autoWidth = true
						hmf_fatigue.childAlignX = -1
							hmf_fatigueText = hmf_fatigue:createLabel({text = "Усталость"})
							hmf_fatigueText.visible = true
							hmf_fatigueBar = hmf_fatigue:createFillBar({current = tes3.mobilePlayer.strength.base + tes3.mobilePlayer.willpower.base + tes3.mobilePlayer.agility.base + tes3.mobilePlayer.endurance.base, max = tes3.mobilePlayer.strength.base + tes3.mobilePlayer.willpower.base + tes3.mobilePlayer.agility.base + tes3.mobilePlayer.endurance.base})
							hmf_fatigueBar.widget.fillColor = tes3ui.getPalette("fatigue_color")
							hmf_fatigueBar.visible = true

				--this displays your attributes, and allows you to allocate attribute points
				b_atr = statsPage_left:createThinBorder{id = tes3ui.registerID("KCP:Attributes_Border")}
				b_atr.visible = true
				b_atr.flowDirection = "top_to_bottom"
				b_atr.widthProportional = 1
				b_atr.autoHeight = true
				b_atr.autoWidth = true
				b_atr.paddingAllSides = 5
					atrLabel = b_atr:createLabel({text = "Характеристики"})
					atrLabel.color = tes3ui.getPalette("header_color")
					atrRemPoints = b_atr:createLabel({text = "Оставшиеся очки характеристик: " ..  common.playerData.levelPoints.atr})
					atrRemPoints.color = tes3ui.getPalette("header_color")
					atr_layout = b_atr:createBlock()
					atr_layout.flowDirection = "top_to_bottom"
					atr_layout.autoHeight = true
					atr_layout.autoWidth = true
					atr_layout.widthProportional = 1
					atr_layout.visible = true
	
	--this function updates the display on the health/magicka/fatigue bars
	local function updateHMFBars()
		local netStrength = atr[tes3.attribute.strength + 1].base + atr[tes3.attribute.strength + 1].pointsSpent
		local netEndurance = atr[tes3.attribute.endurance + 1].base + atr[tes3.attribute.endurance + 1].pointsSpent
		local netIntelligence = atr[tes3.attribute.intelligence + 1].base + atr[tes3.attribute.intelligence + 1].pointsSpent
		local netWillpower = atr[tes3.attribute.willpower + 1].base + atr[tes3.attribute.willpower + 1].pointsSpent
		local netAgility = atr[tes3.attribute.agility + 1].base + atr[tes3.attribute.agility + 1].pointsSpent
		
		hmf_healthBar.widget.max = (netStrength + netEndurance) / 2 + (0.1 * netEndurance * (nextLevel - 1))
		hmf_healthBar.widget.current = (netStrength + netEndurance) / 2 + (0.1 * netEndurance * (nextLevel - 1))
		
		hmf_magickaBar.widget.max = netIntelligence * tes3.mobilePlayer.magickaMultiplier.current
		hmf_magickaBar.widget.current = netIntelligence * tes3.mobilePlayer.magickaMultiplier.current
		
		hmf_fatigueBar.widget.max = netStrength + netWillpower + netAgility + netEndurance
		hmf_fatigueBar.widget.current = netStrength + netWillpower + netAgility + netEndurance
		
		hmf_layout:updateLayout()
	end
	
	--this loop constructs data tables for each of the player's attributes
	for i, a in pairs(tes3.mobilePlayer.attributes) do
		atr[i] = {}
		local maxInc = function() --determines the maximum amount a stat can be increased based on your current available points, and your mcm settings
			if (mcm.atrLvlCap - a.base < mcm.atrIncMax) then return mcm.atrLvlCap - a.base end
			return mcm.atrIncMax
		end
		createStat(atr[i], tes3.getAttributeName(i - 1), a.base, atr_layout, "atr")
		
		--set up events for the '+' and '-' buttons
		atr[i].button_minus:register("mouseClick", 
			function ()
				asButtonScript({type = "sub", tbl = atr[i], points = "atr", incMax = maxInc()})
				atrRemPoints.text = "Оставшиеся очки характеристик: " ..  common.playerData.levelPoints.atr
				updateHMFBars()
				updateASButtons(atr, "atr")
				b_atr:updateLayout()
			end
		)
		atr[i].button_plus:register("mouseClick", 
			function ()
				asButtonScript({type = "add", tbl = atr[i], points = "atr", incMax = maxInc()})
				atrRemPoints.text = "Оставшиеся очки характеристик: " ..  common.playerData.levelPoints.atr 
				updateHMFBars()
				updateASButtons(atr, "atr")
				b_atr:updateLayout()
			end
		)
	end
	updateASButtons(atr, "atr")
	b_atr:updateLayout()
			
			--this displays your skills, and allows you to allocate skill points
			b_skl = statsPage_right:createThinBorder{id = tes3ui.registerID("KCP:skills_border")}
			b_skl.flowDirection = "top_to_bottom"
			b_skl.widthProportional = 1
			b_skl.heightProportional = 1
			b_skl.autoWidth = true
			b_skl.autoHeight = true
				v_skl = b_skl:createVerticalScrollPane{id = tes3ui.registerID("KCP:skills_scrollPane")}
				v_skl.heightProportional = 1.0
				v_skl.widthProportional = 1.0
				v_skl.widget.contentPane.autoWidth = true
				v_skl.widget.contentPane.paddingAllSides = 5
	
					skl_layout = v_skl:createBlock{id = tes3ui.registerID("KCP:skills_layout")}
					skl_layout.flowDirection = "top_to_bottom"
					skl_layout.autoHeight = true
					skl_layout.autoWidth = true
					skl_layout.widthProportional = 1
	
						mjr = skl_layout:createBlock{id = tes3ui.registerID("KCP:skills_major")}
						mjr.flowDirection = "top_to_bottom"
						mjr.autoHeight = true
						mjr.autoWidth = true
						mjr.widthProportional = 1
						mjr.visible = true
							mjr_label = mjr:createLabel({text = "Главные навыки"})
							mjr_pointsRem = mjr:createLabel({text = "Оставшиеся очки главных навыков: " ..  common.playerData.levelPoints.mjr})
							mjr_label.color = tes3ui.getPalette("header_color")
							mjr_pointsRem.color = tes3ui.getPalette("header_color")
	
						mnr = skl_layout:createBlock{id = tes3ui.registerID("KCP:skills_minor")}
						mnr.flowDirection = "top_to_bottom"
						mnr.autoHeight = true
						mnr.autoWidth = true
						mnr.widthProportional = 1
						mnr.visible = true
							mnr_label = mnr:createLabel({text = "Важные навыки"})
							mnr_pointsRem = mnr:createLabel({text = "Оставшиеся очки важных навыков: " ..  common.playerData.levelPoints.mnr})
							mnr_label.color = tes3ui.getPalette("header_color")
							mnr_pointsRem.color = tes3ui.getPalette("header_color")
	
						msc = skl_layout:createBlock{id = tes3ui.registerID("KCP:skills_misc")}
						msc.flowDirection = "top_to_bottom"
						msc.autoHeight = true
						msc.autoWidth = true
						msc.widthProportional = 1
						msc.visible = true
							msc_label = msc:createLabel({text = "Маловажные навыки"})
							msc_pointsRem = msc:createLabel({text = "Оставшиеся очки маловажных навыков: " ..  common.playerData.levelPoints.msc})
							msc_label.color = tes3ui.getPalette("header_color")
							msc_pointsRem.color = tes3ui.getPalette("header_color")
	
	--generates Skill Data tables
	for i, sk in ipairs(tes3.mobilePlayer.skills) do
		--initialize array
		skl[i] = {}
		--determine skill specialization type
		local skType
		if sk.type == tes3.skillType.major then
			skType = "mjr"
		elseif sk.type == tes3.skillType.minor then
			skType = "mnr"
		else skType = "msc"
		end
		--Calculates the maximum value the player should be able to increase this skill to
		local maxInc = function()
			if (mcm[skType .. "LvlCap"] - sk.base < mcm[skType .. "IncMax"]) then return mcm[skType .. "LvlCap"] - sk.base end
			return mcm[skType .. "IncMax"]
		end
		--Generate UI elements and register buttons
		if (sk.type == tes3.skillType.major) then
			createStat(skl[i], tes3.getSkillName(i-1), sk.base, mjr, "mjr")
			skl[i].button_minus:register("mouseClick", 
				function ()
					asButtonScript({type = "sub", tbl = skl[i], points = "mjr", incMax = maxInc()})
					mjr_pointsRem.text = "Оставшиеся очки главных навыков: " ..  common.playerData.levelPoints.mjr
					updateASButtons(skl, "mjr")
					b_skl:updateLayout()
				end
			)
			skl[i].button_plus:register("mouseClick", 
				function ()
					asButtonScript({type = "add", tbl = skl[i], points = "mjr", incMax = maxInc()})
					mjr_pointsRem.text = "Оставшиеся очки главных навыков: " ..  common.playerData.levelPoints.mjr
					updateASButtons(skl, "mjr")
					b_skl:updateLayout()
				end
			)
		elseif (sk.type == tes3.skillType.minor) then
			createStat(skl[i], tes3.getSkillName(i-1), sk.base, mnr, "mnr")
			skl[i].button_minus:register("mouseClick", 
				function ()
					asButtonScript({type = "sub", tbl = skl[i], points = "mnr", incMax = maxInc()})
					mnr_pointsRem.text = "Оставшиеся очки важных навыков: " ..  common.playerData.levelPoints.mnr
					updateASButtons(skl, "mnr")
					b_skl:updateLayout()
				end
			)
			skl[i].button_plus:register("mouseClick", 
				function ()
					asButtonScript({type = "add", tbl = skl[i], points = "mnr", incMax = maxInc()})
					mnr_pointsRem.text = "Оставшиеся очки важных навыков: " ..  common.playerData.levelPoints.mnr
					updateASButtons(skl, "mnr")
					b_skl:updateLayout()
				end
			)
		elseif (sk.type == tes3.skillType.misc) then
			createStat(skl[i], tes3.getSkillName(i-1), sk.base, msc, "msc")
			skl[i].button_minus:register("mouseClick", 
				function ()
					asButtonScript({type = "sub", tbl = skl[i], points = "msc", incMax = maxInc()})
					msc_pointsRem.text = "Оставшиеся очки маловажных навыков: " ..  common.playerData.levelPoints.msc
					updateASButtons(skl, "msc")
					b_skl:updateLayout()
				end
			)
			skl[i].button_plus:register("mouseClick", 
				function ()
					asButtonScript({type = "add", tbl = skl[i], points = "msc", incMax = maxInc()})
					msc_pointsRem.text = "Оставшиеся очки маловажных навыков: " ..  common.playerData.levelPoints.msc
					updateASButtons(skl, "msc")
					b_skl:updateLayout()
				end
			)
		end
	end
	
	updateASButtons(skl, "mjr")
	updateASButtons(skl, "mnr")
	updateASButtons(skl, "msc")
	
	--create Dividers between skill blocks
	mjr:createDivider()
	mnr:createDivider()
	b_atr:updateLayout()
	

	--perks page starts here
	perksSelected = 0 --the number of perks the player currently has selected
		perksPage = frame:createBlock{id = tes3ui.registerID("KCP:perksPage")}
		perksPage.visible = page == 2
		perksPage.flowDirection = "left_to_right"
		perksPage.autoHeight = true
		perksPage.autoWidth = true
		perksPage.minHeight = 512
		perksPage.minWidth = 780
		perksPage.childAlignX = -1
		perksPage.childAlignY = 0
	
			perksPage_borderL = perksPage:createThinBorder{id = tes3ui.registerID("KCP:perksPage_leftBorder")}
			perksPage_borderL.flowDirection = "top_to_bottom"
			perksPage_borderL.widthProportional = 0.6
			
			perksPage_borderR = perksPage:createThinBorder{id = tes3ui.registerID("KCP:perksPage_rightBorder")}
			perksPage_borderR.flowDirection = "top_to_bottom"
			perksPage_borderR.widthProportional = 1.4
	
				perksPage_perksRem = perksPage_borderL:createLabel({text = "Очки талантов: " ..  common.playerData.levelPoints.prk - perksSelected})
	
				perksPage_borderL_vScroll = perksPage_borderL:createVerticalScrollPane{id = tes3ui.registerID("KCP:perksPage_leftScrollPane")}
				perksPage_borderR_vScroll = perksPage_borderR:createVerticalScrollPane{id = tes3ui.registerID("KCP:perksPage_rightScrollPane")}
	
				perksPage_borderL_vScroll.minHeight = 512
				perksPage_borderR_vScroll.minHeight = 512
	
					perksPage_borderL_layout = perksPage_borderL_vScroll:createBlock{id = tes3ui.registerID("KCP:perksPage_leftBorder_layout")}
					perksPage_borderL_layout.flowDirection = "top_to_bottom"
					perksPage_borderL_layout.visible = true
					perksPage_borderL_layout.autoHeight = true
					perksPage_borderL_layout.autoWidth = true
				
					perksPage_borderR_layout = perksPage_borderR_vScroll:createBlock{id = tes3ui.registerID("KCP:perksPage_rightBorder_layout")}
					perksPage_borderR_layout.flowDirection = "top_to_bottom"
					perksPage_borderR_layout.autoHeight = true
					perksPage_borderR_layout.widthProportional = 1.0
						
						perksPage_availablePerks = perksPage_borderL_layout:createBlock{id = tes3ui.registerID("KCP:avaiablePerks")}
						perksPage_availablePerks.flowDirection = "top_to_bottom"
						perksPage_availablePerks.autoHeight = true
						perksPage_availablePerks.autoWidth = true
						perksPage_availablePerks.visible = true
						
						perksPage_blockedPerks = perksPage_borderL_layout:createBlock{id = tes3ui.registerID("KCP:unavailablePerks")}
						perksPage_blockedPerks.flowDirection = "top_to_bottom"
						perksPage_blockedPerks.autoHeight = true
						perksPage_blockedPerks.autoWidth = true
						perksPage_blockedPerks.visible = true
	
						perksPage_perkInfo_Name = perksPage_borderR_layout:createLabel{id = tes3ui.registerID("KCP:perkInfo_name")}
						
						perksPage_borderR_vScroll:createDivider()
						
						perksPage_perkInfo_Cond = perksPage_borderR_layout:createLabel{id = tes3ui.registerID("KCP:perkInfo_requirements")}
						perksPage_perkInfo_Desc = perksPage_borderR_layout:createLabel{id = tes3ui.registerID("KCP:perkInfo_description")}
						perksPage_perkInfo_Name.widthProportional = 1.0
						perksPage_perkInfo_Name.wrapText = true
						perksPage_perkInfo_Cond.widthProportional = 1.0
						perksPage_perkInfo_Cond.wrapText = true
						perksPage_perkInfo_Desc.widthProportional = 1.0
						perksPage_perkInfo_Desc.wrapText = true
	
	local prk = {} --container for perk entries
	
	--controls which perks are highlighted and which perks are grayed out
	local function updatePerkState()
		for id, data in pairs(prk) do
			if data.chosen then 
				data.element.widget.state = 4
				data.blockedElement.widget.state = 4
			elseif not(kcp.perk.checkPerkConditions(id, atr, skl, prk)) then 
				data.element.widget.state = 2 
				data.blockedElement.widget.state = 2
			else 
				data.element.widget.state = 1 
				data.blockedElement.widget.state = 1
			end
			data.element.visible = kcp.perk.checkPerkConditions(id, atr, skl, prk)
			
			if kcp.perk.getPerk(id).hideInMenu then data.blockedElement.visible = false 
			else data.blockedElement.visible = (not kcp.perk.checkPerkConditions(id, atr, skl, prk))
			end
		end
		if perksPage_borderR_layout.height < perksPage_borderR_vScroll.height then
			perksPage_borderR_vScroll.widget.scrollbarVisible = false
		end
		perksPage_perksRem.text = "Очки талантов: " ..  common.playerData.levelPoints.prk - perksSelected
	end
	
	for id, perkData in pairs(kcp.perk.getPerkMasterList()) do	
		if (kcp.perk.playerInfo.hasPerk(id)) or (perkData.isUnique) then prk[id] = nil -- don't register perks the player already has
		else
		prk[id] = { --initialize perk entry
			chosen = false, --whether or not this perk has been selected in the menu
			
			--each perk has two associated ui elements, one in the available perks block, and one in the unavailable perks block
			--this is done so that unavailable perks are always displayed underneath the available perks
			element = perksPage_availablePerks:createTextSelect({text = perkData.name,	state = 1}), 
			blockedElement = perksPage_blockedPerks:createTextSelect({text = perkData.name,	state = 1}),
		}
		prk[id].element.widthProportional = 1.0
		prk[id].blockedElement.widthProportional = 1.0
		prk[id].element.wrapText = true
		prk[id].blockedElement.wrapText = true
		
		
		--set up colors
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
		
		--register click/mouseover functions
		prk[id].element:register("mouseOver", function()
			local condition = "Требования:\n"
			if perkData.lvlReq > 0 then condition = (condition .. "Уровень " .. perkData.lvlReq .. ",\n") end
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
					condition = (condition .. kcp.perk.getPerk(v).name .. ", ")
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
			if perkData.lvlReq then condition = (condition .. "Уровень " .. perkData.lvlReq .. ",\n") end
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
					condition = (condition .. kcp.perk.getPerk(v).name .. ", ")
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
			elseif (perksSelected < math.floor( common.playerData.levelPoints.prk / 1)) then --floors perkpoints because perk point can be a fraction
				prk[id].chosen = true
				perksSelected = perksSelected + 1
			end
			updatePerkState()
		end)
		end
		updatePerkState()
	end
	
	if perksPage_borderL_layout.height < perksPage_borderL_vScroll.height then
		perksPage_borderL_vScroll.widget.scrollbarVisible = false
	end

	--container for the next and back buttons
		frameButtons = frame:createBlock{id = tes3ui.registerID("KCP:frameButtons")}
		frameButtons.autoHeight = true
		frameButtons.widthProportional = 1.0
		frameButtons.visible = true
		frameButtons.childAlignX = 1
			buttonBack = frameButtons:createButton{id = tes3ui.registerID("KCP:backButton")}
			buttonBack.text = "Назад"
			buttonBack.widget.pressed = tes3ui.getPalette("normal_pressed_color")
			buttonBack.visible = (page ~= 0)
	
			buttonNext = frameButtons:createButton{id = tes3ui.registerID("KCP:nextButton")}
			buttonNext.text = "Вперед"
			buttonNext.widget.pressed = tes3ui.getPalette("normal_pressed_color")
			buttonNext.widget.idleActive = tes3ui.getPalette("active_color")
			buttonNext.widget.pressedActive = tes3ui.getPalette("active_pressed_color")
	
	--updates which page is displayed
	local function updatePageVis()
		introPage.visible = (page == 0)
		statsPage.visible = (page == 1)
		perksPage.visible = (page == 2)
		buttonBack.visible = (page ~= 0)
		if (page == 2) or ((page == 1) and ( common.playerData.levelPoints.prk == 0)) then buttonNext.text = "Конец"
		else buttonNext.text = "Вперед" end
	end
	
	--"back" button code
	buttonBack:register("mouseClick", 
		function()
			for i, t in pairs(prk) do
		if t.chosen then 
			t.chosen = false
			perksSelected = perksSelected + 1
		end
	end
			if page > 2 then
				page = 2
				frame:updateLayout()
			elseif (page > 0) then
				page = page - 1
				frame:updateLayout()
			else
				page = 0
				frame:updateLayout()
			end
			updatePageVis()
		end
	)
	--"next" button code
	buttonNext.visible = true
	buttonNext:register("mouseClick", 
	function()
		if page < 0 then 
			page = 0 
		elseif ((page == 1) and ( common.playerData.levelPoints.prk == 0)) then
			finalizeChanges(atr, skl, prk)
			event.trigger("levelUp", {level = nextLevel})
			frame.visible = false
			tes3ui.leaveMenuMode((frame:getTopLevelMenu()).id)
			frame:getTopLevelMenu():destroy()
		elseif (page < 2) then
			page = page + 1
		elseif page == 2 then --insert skill change finalization here
			finalizeChanges(atr, skl, prk)
			event.trigger("levelUp", {level = nextLevel})
			frame.visible = false
			tes3ui.leaveMenuMode((frame:getTopLevelMenu()).id)
			frame:getTopLevelMenu():destroy()

		else 
			page = 2
		end
		if frame.visible then
			updatePageVis()
			frame:updateLayout()
		end
	end
	)
	
	updatePageVis()
	frame:updateLayout()
end

local function onMenuLevelUp(e)
	if  (not e.newlyCreated) or (not e.element) then return end
	mwscript.setLevel({reference = tes3.player, level = nextLevel})
	e.element.text = "Level Up"
	buildLevelUpMenu(e.element)
end
event.register("uiActivated", onMenuLevelUp, {filter = "MenuLevelUp"})

local function setUpLevel(e) 
	nextLevel = e.level
	common.dbg("Player is advancing to level " .. nextLevel)
	local incPoints = common.playerData.incPoints
	local pntMult = common.playerData.pntMult
	
	player.modLevelPoints{typ = "prk", mod = incPoints.prk}
	if not (nextLevel % mcm.prkLvlInterval > 0) then
		player.modLevelPoints{typ = "prk", mod = (mcm.prkLvlMult * pntMult.prk)}
	end
	
	player.modLevelPoints{typ = "atr", mod = incPoints.atr}
	if not (nextLevel % mcm.atrLvlInterval > 0) then
		player.modLevelPoints{typ = "atr", mod = (mcm.atrLvlMult * pntMult.atr)}
	end
	
	player.modLevelPoints{typ = "mjr", mod = incPoints.mjr}
	if mcm.xpEnabled and not (nextLevel % mcm.mjrLvlInterval > 0) then
		player.modLevelPoints{typ = "mjr", mod = (mcm.mjrLvlMult * pntMult.mjr)}
	end
	
	player.modLevelPoints{typ = "mnr", mod = incPoints.mnr}
	if mcm.xpEnabled and not (nextLevel % mcm.mnrLvlInterval > 0) then
		player.modLevelPoints{typ = "mnr", mod = (mcm.mnrLvlMult * pntMult.mnr)}
	end
	
	player.modLevelPoints{typ = "msc", mod = incPoints.msc}
	if mcm.xpEnabled and not (nextLevel % mcm.mscLvlInterval > 0) then
		player.modLevelPoints{typ = "msc", mod = (mcm.mscLvlMult * pntMult.msc)}
	end
end
event.register("preLevelUp", setUpLevel)