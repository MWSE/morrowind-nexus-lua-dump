local common = require("KBev.ProgressionMod.common")
local mcm = require("KBev.ProgressionMod.mcm")
local kcp = require("KBev.ProgressionMod.interop")
local player = kcp.playerData
local page --this keeps track of what menu is displayed in the level up menu. I initialize it as a local in this file as redundancy.

--table of the vanilla levelUpMessages
local levelUpMessage = {
	[2] = "You realize that all your life you have been coasting along as if you were in a dream. Suddenly, facing the trials of the last few days, you have come alive.",
	[3] = "You realize that you are catching on to the secret of success. It's just a matter of concentration.",
	[4] = "It's all suddenly obvious to you. You just have to concentrate. All the energy and time you've wasted -- it's a sin. But without the experience you've gained, taking risks, taking responsibility for failure, how could you have understood?",
	[5] = "Everything you do is just a bit easier, more instinctive, more satisfying. It is as though you had suddenly developed keen senses and instincts.",
	[6] = "You sense yourself more aware, more open to new ideas. You've learned a lot about Morrowind. It's hard to believe how ignorant you were -- but now you have so much more to learn.",
	[7] = "You resolve to continue pushing yourself. Perhaps there's more to you than you thought.",
	[8] = "The secret does seem to be hard work, yes, but it's also a kind of blind passion, an inspiration.",
	[9] = "Everything you do is just a bit easier, more instinctive, more satisfying. It is as though you had suddenly developed keen senses and instincts.",
	[10] = "You woke today with a new sense of purpose. You're no longer afraid of failure. Failure is just an opportunity to learn something new.",
	[11] = "Being smart doesn't hurt. And a little luck now and then is nice. But the key is patience and hard work. And when it pays off, it's SWEET!",
	[12] = "You can't believe how easy it is. You just have to go -- a little crazy. And then, suddenly, it all makes sense, and everything you do turns to gold.",
	[13] = "It's the most amazing thing. Yesterday it was hard, and today it is easy. Just a good night's sleep, and yesterday's mysteries are today's masteries.",
	[14] = "Today you wake up, full of energy and ideas, and you know, somehow, that overnight everything has changed. What a difference a day makes.",
	[15] = "Having acknowledged your weaknessess, you begin to understand the importance of focusing on things you really good at.",
	[16] = "You've been trying too hard, thinking too much. Relax. Trust your instincts. Just be yourself. Do the little things, and the big things take care of themselves.",
	[17] = "Life is just beginning. Just keep on getting smarter, or cleverer, or meaner -- you still have a lot to experience.",
	[18] = "As the day passes, you seem to have matured and therefore become wiser and stronger.",
	[19] = "You're good, but not good enough. And it gets harder to get better. But you just keep trying, because that's the way you are.",
	[20] = "You may think you can never become better, than you are today, but your success is only an indication that a much difficult road lies ahead. Keep your head straight and do not ever look back.",
	[22] = "Today you awoke with an empowering idea. Your sudden understanding that greater power is inevitable drives you toward the next horizon.",
	[23] = "More time is needed to study your talents. Well, why are you still standing here? Go study!",
	[24] = "All the knowledge in the world couldn't make you the best, no matter how many books you read. You have to get practice in real life to gain the knowledge you seek.",
	[25] = "Your years of intense training seems to be paying off now. But there is still much, much more for you to learn.",
	[26] = "You have learned what carelessness and running into a situation blindly can do. Stay vigilant, so that you may be ready for what still awaits in the dark corners of this land.",
	[27] = "A year ago you would have never believed you would be fighting cliff racers one minute and running from a pack of angry nix-hounds the next. But here you stand none the less, very much alive and full of fire.",
	[28] = "As you look down into a little drop of moisture, you suddenly see your life flash before your eyes. The things you have seen... The things left to see...",
	[29] = "Today you open your eyes to a peaceful sight. Warmth flows through you, along with a deep sense of peace. All things done are in the past, and you have learned well from all your experiences.",
	[30] = "You feel on top of the world today. Does it get much better than this?",
	[31] = "Some things never change. With you things always change, and with time you will learn to accept it.",
	[32] = "As a result of your hard work and dedication you have exceeded your own expectations. Experience is the spice of life.",
	[33] = "Hard work is the key, and you've done plenty. Keep it up.",
	[34] = "The time grows longer now, you should rest in a nearby village and catch up on some lore. The many nights spent abroad have left you with a feeling of disconnection.",
	[35] = "There is always room for more training, but, at this point, people should be paying you to train them.",
	[36] = "As you stroll through civilization, you feel that you have the right to be proud and hold your head high! Well... for the most part.",
	[37] = "As you have traveled you have steadily taken on bigger risks, and landed bigger rewards. Don't get yourself in too deep.",
	[38] = "You side step the thrust of an enemy's blade. You return with a twirl, jab, jab, slash. Your enemy lies mortally wounded on the ground. The world flashes! You awake from your dream.",
	[39] = "With all the talk about adventurers meeting their end, you chuckle at the thought of it happening to you. As you reflect on all that you've seen, that chuckle becomes a full blown cackle.",
	[40] = "It's not every day that stars are born.",
	[41] = "Stay on your toes, now is no time to get careless. There is much work to be done if you are to keep advancing.",
	[42] = "As you awake, hanging in-between the worlds of dream and reality, a vision of all that you have become flashes before your eyes. The world slowly comes into focus. You breathe deep, then smile.",
	[43] = "Hero yay, or nay, it matters not. Great power is yours to seek, and yours to gain.",
	[44] = "Things seem so much more in focus. It's the little details that have lead you this far, and will continue to help you grow.",
	[45] = "The fog of this land sinks into your very bones. You try hard to shake it but the feeling is too real. You tell yourself that it will pass, and move forward with fierce resolve.",
	[46] = "Seas of ghosts and never ending hordes of enemies now consume your thoughts. Your mind is clouded as you think of your death... Your oneiric state ends abruptly; overpowered by the intense courage within you.",
	[47] = "As you sit on the wet ground you find your attention drawn to a single blade of grass. You pluck it, press the blade between your thumbs, then blow a burst of air through your makeshift flute. Its call reminds you that all things are fleeting.",
	[48] = "You regain consciousness to an odd odor. Time for a swim, you say to yourself. All this meditation has left you in a cold sweat and reeking of rotten onions.",
	[49] = "In the middle of your meditation you find yourself drained. Dread fills you as you consider your future. The road ahead is bound to be a hard one.",
	[50] = "A vision of Red Mountain consumes your thoughts. You remember ancient times, long forgotten treasures and the battles fought on its slopes. A deep sense of familiarity grows roots within you...",
	[51] = "You envision far off landscapes, mysterious treasures, and ancient artifacts that are yet to be found.",
	[52] = "A buzzing noise wakes you from your meditation. You let your vision focus on its source. A bee dances before your nose. You pay it no mind and continue to meditate.",
	[53] = "In the distant reaches of your mind you see many different symbols. After aligning them in a certain order... You come to.",
	[54] = "Knowledge is not easily attained. Whether by sword, spell, or Septim you have gleaned much, but still don't know it all.",
	[55] = "There aren't many amongst mortals who can match your prowess. Knowing this does not mean there is nothing left to learn.",
	[56] = "You awake with a new sense of purpose, you set off in hope of finding something worthy of your interest.",
	[57] = "Visions abound within your mind's eye. Damp, deadly caverns, and ancient crypts reveal their secrets to you. Upon waking, you begin to wonder if any of them were real.",
	[58] = "As you rest, a feeling of weightlessness envelopes you. You roll over and open your eyes only to find yourself gazing down upon your own sleeping form. You ponder this curiosity as images of your exploits dance before you. With a sudden whirl you awaken.",
	[59] = "The things that once escaped you have now become clear. The things that you once knew now seem distant. Everything is changing... including you.",
	[60] = "All faults aside, you are on your way to becoming a god amongst men and mer.",
	[61] = "You are getting stronger all of the time. Your hard work has taught you that not all things are as they seem. Although it may feel like you have reached the pinnacle of your power, your experiences tell you different.",
	[62] = "You must remind yourself to always strive for balance while studying your disciplines. You must never forget that the pen is mighty, the sword is heavy, and shadows hide you.",
	[63] = "Your intense thirst for knowledge drives you forward. Most men and mer never attain the level of experience you have.",
	[64] = "Your studies are progressing quickly now. Your proven skills are testament that your efforts have not been in vain. Secret upon secret has been revealed to you, but you know that more lay hidden beneath the surface of the world around you.",
	[65] = "You've traveled the length and breadth of Vvardenfell and seen it all, or so you may think. Every time you entertain this notion, this land of ash wastes and ancient secrets proves you wrong.",
	[66] = "Survival has meant being quick, cunning, and unrelenting. Although the road you have walked has left you travel-worn, you force yourself to take stock of the fact that you are still alive.",
	[67] = "Survival is one thing. What you do can only be described as living large.",
	[68] = "You've made quite a name for yourself. Who knew that the fetcher that stepped off the imperial prison ship and onto the docks at Seyda Neen, many moons ago, would end up wearing the boots you do now?",
	[69] = "Your name carries the weight of all your accomplishments. Those who speak of you do so with respect. Those who behold you stand in awe.",
	[70] = "You are a master of your mind and body. You have seen many things both beautiful and horrible. You are a living legend.",
	[71] = "As your legend continues to grow, so do you.",
	[72] = "Regardless of all that you have accomplished, you still refuse to retire. A new day brings a new goal.",
	[73] = "With every passing moment the tales of your exploits grow. When one story ends, another begins. Such is the cycle of your life.",
	[74] = "You are a paragon of the elite. The epitome of all that adventurers seek to become. No living mortal on Vvardenfell has accomplished as much as you have.",
    [75] = "Many have fallen, but you remain. Most of Tamriel knows your story. Men and mer give you their adoration, and Daedra fear you, knowing that no mere mortal could have accomplished what you have. Hold your head high for you have earned your place in history.",
	[76] = "Your soul burns like brightest star fire. Your mastery of the arts is legendary. Your knowledge and wisdom is second to none!",
	[77] = "With each day, you become closer to reaching godhood.",
	[78] = "Waking up from the strangest dream, you realise you've just gained a knowledge of very high importance. 'It cannot be... I saw them... No one will believe me' -- you say to yourself. After a while, you go back to sleep, forgetting the dream you just had.",
	[79] = "Sometimes I feel that I can no longer distinct the reality from facade. Is this how it feels to be ETERNAL? Did I just see SOMEONE ELSE out there... ?? Are YOU the one behind the WHEEL... ???",
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
				header_text = header_layout:createLabel{text = "You've Advanced to Level " .. nextLevel .. "!"}
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
				FlavorText = b_Flavor:createLabel{id = tes3ui.registerID("KCP:LevelUPFlavorText"),text = (levelUpMessage[nextLevel] or "You have reached the peak of greatness. At this point, nothing is impossible to you anymore. The time has finally come to rest, but you are free to go on with your journey. After all, there will always be quests to undertake, enemies to slay and challenges to face.")}
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
				atrText = b_summary:createLabel{id = tes3ui.registerID("KCP:summary_attributes"), text = "Attribute Points: " .. common.playerData.levelPoints.atr}
				atrText.widthProportional = 1
				atrText.wrapText = true
				atrText.autoHeight = true
				atrText.justifyText = "center"
				atrText.visible = (common.playerData.levelPoints.atr > 0)
				
				mjrText = b_summary:createLabel{id = tes3ui.registerID("KCP:summary_majorSkills"), text = "Major Skill Points: " .. common.playerData.levelPoints.mjr}
				mjrText.widthProportional = 1
				mjrText.wrapText = true
				mjrText.autoHeight = true
				mjrText.justifyText = "center"
				mjrText.visible = (common.playerData.levelPoints.mjr > 0)
				
				mnrText = b_summary:createLabel{id = tes3ui.registerID("KCP:summary_minorSkills"), text = "Minor Skill Points: " .. common.playerData.levelPoints.mnr}
				mnrText.widthProportional = 1
				mnrText.wrapText = true
				mnrText.autoHeight = true
				mnrText.justifyText = "center"
				mnrText.visible = (common.playerData.levelPoints.mnr > 0)
				
				mscText = b_summary:createLabel{id = tes3ui.registerID("KCP:summary_miscSkills"), text = "Misc Skill Points: " .. common.playerData.levelPoints.msc}
				mscText.widthProportional = 1
				mscText.wrapText = true
				mscText.autoHeight = true
				mscText.justifyText = "center"
				mscText.visible = (common.playerData.levelPoints.msc > 0)
				
				prkText = b_summary:createLabel{id = tes3ui.registerID("KCP:summary_perks"), text = "Perk Points: " .. common.playerData.levelPoints.prk}
				prkText.widthProportional = 1
				prkText.wrapText = true
				prkText.autoHeight = true
				prkText.justifyText = "center"
				prkText.visible = (common.playerData.levelPoints.prk > 0)
				
				dmyText = b_summary:createLabel{id = tes3ui.registerID("KCP:summary_dummy"), text = "No Attribute, Skill, or Perk changes"}
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
							hmf_healthText = hmf_health:createLabel({text = "Health"})
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
							hmf_magickaText = hmf_magicka:createLabel({text = "Magicka"})
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
							hmf_fatigueText = hmf_fatigue:createLabel({text = "Fatigue"})
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
					atrLabel = b_atr:createLabel({text = "Attributes"})
					atrLabel.color = tes3ui.getPalette("header_color")
					atrRemPoints = b_atr:createLabel({text = "Remaining Attribute Points: " ..  common.playerData.levelPoints.atr})
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
				atrRemPoints.text = "Remaining Attribute Points: " ..  common.playerData.levelPoints.atr
				updateHMFBars()
				updateASButtons(atr, "atr")
				b_atr:updateLayout()
			end
		)
		atr[i].button_plus:register("mouseClick", 
			function ()
				asButtonScript({type = "add", tbl = atr[i], points = "atr", incMax = maxInc()})
				atrRemPoints.text = "Remaining Attribute Points: " ..  common.playerData.levelPoints.atr 
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
							mjr_label = mjr:createLabel({text = "Major Skills"})
							mjr_pointsRem = mjr:createLabel({text = "Remaining Major Skill Points: " ..  common.playerData.levelPoints.mjr})
							mjr_label.color = tes3ui.getPalette("header_color")
							mjr_pointsRem.color = tes3ui.getPalette("header_color")
	
						mnr = skl_layout:createBlock{id = tes3ui.registerID("KCP:skills_minor")}
						mnr.flowDirection = "top_to_bottom"
						mnr.autoHeight = true
						mnr.autoWidth = true
						mnr.widthProportional = 1
						mnr.visible = true
							mnr_label = mnr:createLabel({text = "Minor Skills"})
							mnr_pointsRem = mnr:createLabel({text = "Remaining Minor Skill Points: " ..  common.playerData.levelPoints.mnr})
							mnr_label.color = tes3ui.getPalette("header_color")
							mnr_pointsRem.color = tes3ui.getPalette("header_color")
	
						msc = skl_layout:createBlock{id = tes3ui.registerID("KCP:skills_misc")}
						msc.flowDirection = "top_to_bottom"
						msc.autoHeight = true
						msc.autoWidth = true
						msc.widthProportional = 1
						msc.visible = true
							msc_label = msc:createLabel({text = "Misc Skills"})
							msc_pointsRem = msc:createLabel({text = "Remaining Misc Skill Points: " ..  common.playerData.levelPoints.msc})
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
					mjr_pointsRem.text = "Remaining Major Skill Points: " ..  common.playerData.levelPoints.mjr
					updateASButtons(skl, "mjr")
					b_skl:updateLayout()
				end
			)
			skl[i].button_plus:register("mouseClick", 
				function ()
					asButtonScript({type = "add", tbl = skl[i], points = "mjr", incMax = maxInc()})
					mjr_pointsRem.text = "Remaining Major Skill Points: " ..  common.playerData.levelPoints.mjr
					updateASButtons(skl, "mjr")
					b_skl:updateLayout()
				end
			)
		elseif (sk.type == tes3.skillType.minor) then
			createStat(skl[i], tes3.getSkillName(i-1), sk.base, mnr, "mnr")
			skl[i].button_minus:register("mouseClick", 
				function ()
					asButtonScript({type = "sub", tbl = skl[i], points = "mnr", incMax = maxInc()})
					mnr_pointsRem.text = "Remaining Minor Skill Points: " ..  common.playerData.levelPoints.mnr
					updateASButtons(skl, "mnr")
					b_skl:updateLayout()
				end
			)
			skl[i].button_plus:register("mouseClick", 
				function ()
					asButtonScript({type = "add", tbl = skl[i], points = "mnr", incMax = maxInc()})
					mnr_pointsRem.text = "Remaining Minor Skill Points: " ..  common.playerData.levelPoints.mnr
					updateASButtons(skl, "mnr")
					b_skl:updateLayout()
				end
			)
		elseif (sk.type == tes3.skillType.misc) then
			createStat(skl[i], tes3.getSkillName(i-1), sk.base, msc, "msc")
			skl[i].button_minus:register("mouseClick", 
				function ()
					asButtonScript({type = "sub", tbl = skl[i], points = "msc", incMax = maxInc()})
					msc_pointsRem.text = "Remaining Misc Skill Points: " ..  common.playerData.levelPoints.msc
					updateASButtons(skl, "msc")
					b_skl:updateLayout()
				end
			)
			skl[i].button_plus:register("mouseClick", 
				function ()
					asButtonScript({type = "add", tbl = skl[i], points = "msc", incMax = maxInc()})
					msc_pointsRem.text = "Remaining Misc Skill Points: " ..  common.playerData.levelPoints.msc
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
	
				perksPage_perksRem = perksPage_borderL:createLabel({text = "Perk Points:  " ..  common.playerData.levelPoints.prk - perksSelected})
	
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
		perksPage_perksRem.text = "Perk Points:  " ..  common.playerData.levelPoints.prk - perksSelected
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
			local condition = "Requirements:\n"
			if perkData.lvlReq > 0 then condition = (condition .. "Level " .. perkData.lvlReq .. ",\n") end
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
			local condition = "Requirements:\n"
			if perkData.lvlReq then condition = (condition .. "Level " .. perkData.lvlReq .. ",\n") end
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
			buttonBack.text = "Back"
			buttonBack.widget.pressed = tes3ui.getPalette("normal_pressed_color")
			buttonBack.visible = (page ~= 0)
	
			buttonNext = frameButtons:createButton{id = tes3ui.registerID("KCP:nextButton")}
			buttonNext.text = "Next"
			buttonNext.widget.pressed = tes3ui.getPalette("normal_pressed_color")
			buttonNext.widget.idleActive = tes3ui.getPalette("active_color")
			buttonNext.widget.pressedActive = tes3ui.getPalette("active_pressed_color")
	
	--updates which page is displayed
	local function updatePageVis()
		introPage.visible = (page == 0)
		statsPage.visible = (page == 1)
		perksPage.visible = (page == 2)
		buttonBack.visible = (page ~= 0)
		if (page == 2) or ((page == 1) and ( common.playerData.levelPoints.prk == 0)) then buttonNext.text = "Finish"
		else buttonNext.text = "Next" end
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