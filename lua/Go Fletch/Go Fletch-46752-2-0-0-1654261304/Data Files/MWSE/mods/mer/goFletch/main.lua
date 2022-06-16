local configPath = "go_fletch"
local registerRecipes = require("mer.goFletch.registerRecipes")
local config = mwse.loadConfig(configPath)
if (config == nil) then
	config = {
        fletchFromInventory = false,
        dontShowAgain = false
    }
end


--INITIALISE SKILLS--
local skillModule = include("OtherSkills.skillModule")

--Initialise Recipes



local function noSkillsMessage(e)
    if e.button == 0 then
        os.execute("start https://www.nexusmods.com/morrowind/mods/46034")
    elseif e.button == 1 then
        config.dontShowAgain = true
        mwse.saveConfig(configPath, config)
    end
end

local charGen
local function checkCharGen()
    if charGen.value == -1 then
        if ( not skillModule ) and ( not config.dontShowAgain ) then
            tes3.messageBox({
                message = "Go Fletch requires Skills Module to be installed!",
                buttons = { "Go to Skills Module Nexus Page", "Don't tell me again", "Cancel"},
                callback = noSkillsMessage
            })
        end
        event.unregister("simulate", checkCharGen)
        local agilBase = tes3.mobilePlayer.attributes[tes3.attribute.agility + 1].base
        local startingSkill = math.remap(agilBase, 0, 100, 10, 20)

        local fletchingDescription = (
            "The Fletching skill determines your ability to craft arrows and bolts from raw ingredients."
        )
        skillModule.registerSkill(
            "fletching",
            {
                name = "Fletching",
                icon = "Icons/fletching/skill.dds",
                value = startingSkill,
                attribute =  tes3.attribute.agility,
                description = fletchingDescription,
                specialization = tes3.specialization.stealth
            }
        )
    end
end
local function onSkillsReady()
    charGen = tes3.findGlobal("CharGenState")
    event.unregister("simulate", checkCharGen)
    event.register("simulate", checkCharGen)
end
event.register("OtherSkills:Ready", onSkillsReady)


-- local function fletchTooltip(e)
--     if e.object.id == "mer_fletch_kit" then
--         e.tooltip:findChild(tes3ui.registerID("HelpMenu_uses")).visible = false
--         e.tooltip:findChild(tes3ui.registerID("HelpMenu_qualityCondition")).visible = false
--     end
-- end

-- event.register("uiObjectTooltip", fletchTooltip)

local function initialised()
    mwse.log("Registering Fletching Recipes")
    registerRecipes()
end

event.register("initialized", initialised)



--------------------------------------------
--MCM
--------------------------------------------

local function registerMCM()
    local  sideBarDefault = (
        "Go Fletch adds a brand new Fletching skill to the game, " ..
        "utilising the latest skill and crafting frameworks in MWSE " ..
        "to fully integrate it into the vanilla UI. \n\n" ..
        "Purchase a Fletching Station from various smiths and " ..
        "weapons merchants, place it down and activate to bring up " ..
        "the fletching menu. Choose whether to craft arrows, bolts " ..
        "or darts. \n\n" ..
        "Your Fletching skill can be found in your stats menu under " ..
        "'Other Skills'. Your skill will start between 10 and 20, " ..
        "based on your Agility."
    )
    local function addSideBar(component)
        component.sidebar:createInfo{ text = sideBarDefault}
        local hyperlink = component.sidebar:createCategory("Credits: ")
        hyperlink:createHyperLink{
            text = "Scripting: Merlord",
            exec = "start https://www.nexusmods.com/users/3040468?tab=user+files",
        }
        hyperlink:createHyperLink{
            text = "Models: Remiros",
            exec = "start https://www.nexusmods.com/morrowind/users/899234?tab=user+files",
        }
    end

    local  fletchFromInventoryDescription = (
        "When enabled, you can access the Fletching menu by equipping " ..
        "the fletching station in your inventory. When disabled, you can " ..
        "only do so by activating it after it has been placed in the world."
    )


    local template = mwse.mcm.createTemplate("Go Fletch")
    template:saveOnClose(configPath, config)
    local page = template:createSideBarPage{}
    addSideBar(page)

    page:createOnOffButton{
        label = "Fletch from Inventory",
        variable = mwse.mcm.createTableVariable{
            id = "fletchFromInventory",
            table = config
        },
        description = fletchFromInventoryDescription
    }

    template:register()
end

event.register("modConfigReady", registerMCM)