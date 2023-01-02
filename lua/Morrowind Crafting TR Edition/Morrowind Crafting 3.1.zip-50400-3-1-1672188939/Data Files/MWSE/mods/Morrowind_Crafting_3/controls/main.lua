--[[ Part of Morrowind Crafting 3 
	Initialization, registry and configuration
	Drac and Toccatta, 2019 ]]--
	
local buttonText

local configPath = "Morrowind_Crafting_3"
local config = mwse.loadConfig(configPath)
if (config == nil) then
	config = { 
        skillcaps = false,
		learningcurve = 5,
		casualmode = false,
		feedback = "Simple"
    }
end 

local mc = require("Morrowind_Crafting_3.mc_common")

--------------------------------------------
--MCM
--------------------------------------------

local function registerMCM()
    local  sideBarDefault = (
        "Morrowind Crafting adds several skills and sets of "..
		"tools (kits, really) that allow the player to create, "..
		"place and use most of the objects available within "..
		"the game, as well as adding a number of new items "..
		"such as poisons, ores to mine and refine, and most "..
		"of the new items included in Tamriel Rebuilt. There "..
		"are also new traders that buy items produced by local "..
		"crafters (ie, the player), and some trainers for "..
		"the new skills. The new skills available are "..
		"fletching of missiles, cooking of food items, sewing "..
		"and weaving of clothing, rugs and tapestries, mining "..
		"and smelting of ores for raw materials, woodworking "..
		"to produce furniture and other items, smithing of "..
		"weapons and armors, crafting of glass and lighting "..
		"items, and masonry of stone and clay items (such "..
		"as pottery and planters. Also included is a placement "..
		"tool activated by placing crosshairs upon whatever you "..
		"want to move and pressing 'Home'. If a moveable item, "..
		"a small menu will appear in the upper left showing position "..
		"and controls. Remember to press 'End' when done. "
    )
    local function addSideBar(component)
        component.sidebar:createInfo{ text = sideBarDefault}
        local hyperlink = component.sidebar:createCategory("Credits: ")
        hyperlink:createHyperLink{
			text = "Drac: Lua Scripting, NPCs and Concepts",
			exec = "start http://denina.fliggerty.com/forum/index.php",
        }
        hyperlink:createHyperLink{
			text = "Toccatta: Scripting, Balancing and Concepts",
			exec = "start http://denina.fliggerty.com/forum/index.php",
		}
		local mentions = component.sidebar:createCategory("Add'l credits due: ")
		mentions:createHyperLink{
			text = "Merlord: OtherSkills mod (which made life much easier)",
			exec = "start https://www.nexusmods.com/users/3040468",
		}
		mentions:createHyperLink{
			text = "NullCascade: Invaluable assistance with MWSE and Lua",
			exec = "start https://www.nexusmods.com/morrowind/users/26153919",
		}
		mentions:createHyperLink{
			text = "RedFurryDemon: Model creation and support",
			exec = "start https://www.nexusmods.com/morrowind/users/46908543",
        }
		mentions:createHyperLink{
			text = "Denina: Invaluable assistance with suggestions and playtesting",
			exec = "start http://denina.fliggerty.com/forum/index.php",
		}
		mentions:createHyperLink{
			text = "The Wanderer: File drawers initial nif and texture",
			exec = "start https://www.nexusmods.com/morrowind/users/61496"
		}
    end

    local  skillcapsDescription = (
        "When skillcaps are in place, the maximum skill level "..
		"becomes 100 as per the basic version of Morrowind. When "..
		"skillcaps are removed, crafting skill levels of several "..
		"hundred become possible, though at high levels advancement "..
		"becomes increasingly difficult to reach. All crafting "..
		"skills start at 5."
    )

	local learningcurveDescription = (
		"The learning curve determines how quickly a skill advances "..
		"to new levels. Difficult progresses at a speed comparable "..
		"to earlier versions of Morrowind Crafting. Intermediate "..
		"progresses twice as fast, and Easy is three times as fast. "..
		"In Easy mode, early levels will advance extremely quickly."
	)
	
	local casualmodeDescription = (
		"Casual mode is for players who just want to craft items "..
		"without the role-playing aspect of having to learn skills. "..
		"When turned on, success with any project will be automatic "..
		"provided the player has the required materials on-hand. "..
		"Since skills are ignored in this mode, completing a project "..
		"will not result in any skill training. "
		)
		
	local feedbackDescription = (
		"Various levels of feedback are available to the player when "..
		"crafting items. With feedback set to Detailed, projects "..
		"will give very specific information on project difficulty "..
		"and the likelihood of success. When set to Simple, a more "..
		"vague indication of difficulty and success are reported. "..
		"When turned off, projects will not report difficulty level "..
		"or likelihood of success at all. This is intended for "..
		"people who want no handholding whatsoever; difficulties and "..
		"chances of success must be discovered by trial and error."
	)

	local taskTimeDescription = (
		"Crafting tasks can be set to require time to pass. While the "..
		"default is for tasks to not take up time, the recipe lists can "..
		"be set to take anywhere from a few minutes to as long as 24 "..
		"hours. If you want to alter the time that a task entails, just "..
		"edit the value of taskTime in the recipes."
	)

	local animatedMiningDescription = (
		"Turning Animated Mining on means that in order to mine ores "..
		"and such, you must equip a mining pick (regular or Nordic) and "..
		"actually swing it at the selected rock. Note that the rock must "..
		"be activated in order to begin. To 'fast mine' hold the shift key. "
	)
	
	local function curvename(x)
		if config.learningcurve == 7.5 then 
			return "Easy"
		elseif config.learningcurve == 5 then 
			return "Intermediate"
		elseif config.learningcurve == 2.5 then
			return "Difficult"  
		end
	end
	
    local template = mwse.mcm.createTemplate("Morrowind Crafting")
    template:saveOnClose(configPath, config)
    local page = template:createSideBarPage{}
    addSideBar(page)

    page:createOnOffButton{
        label = "Skillcaps",
        variable = mwse.mcm.createTableVariable{
            id = "skillcaps", 
            table = config
		},
        description = skillcapsDescription
    }
	
	page:createButton{
    label = "Learning Curve",
    getText = function() return curvename() end,
    description = learningcurveDescription,
    callback = function(self)
        if config.learningcurve == 7.5 then
            config.learningcurve = 5
        elseif config.learningcurve == 5 then
            config.learningcurve = 2.5
        elseif config.learningcurve == 2.5 then
            config.learningcurve = 7.5
        end
        self:setText(curvename())
    end
	}
	
	page:createOnOffButton{
        label = "Casual mode",
        variable = mwse.mcm.createTableVariable{
            id = "casualmode", 
            table = config
		},
        description = casualmodeDescription
    }
	
	page:createButton{
        label = "Feedback",
		getText = function() return config.feedback end,
		--buttonText = config.feedback,
        description = feedbackDescription,
		callback = ( function(self)
			if config.feedback == "Off" then
				--self:setText("Simple")
				config.feedback = "Simple"
			elseif config.feedback == "Simple" then
				--self:setText("Detailed")
				config.feedback = "Detailed"
			else
				--self:setText("Off")
				config.feedback = "Off"
			end
			self:setText(config.feedback)
		end
		)
	}
	
	page:createOnOffButton{
        label = "Crafting Passes Time",
        variable = mwse.mcm.createTableVariable{
            id = "tasktime", 
            table = config
		},
        description = taskTimeDescription
	}
	
	page:createOnOffButton{
        label = "Animated Mining",
        variable = mwse.mcm.createTableVariable{
            id = "animatedMining", 
            table = config
		},
        description = animatedMiningDescription
    }

    template:register()
end

event.register("modConfigReady", registerMCM)