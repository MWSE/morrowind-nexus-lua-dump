local configPath = "go_fletch"

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
    event.register("simulate", checkCharGen)
end
event.register("OtherSkills:Ready", onSkillsReady)



-----------------------------------------------------------------------------------
--Call menu on Fletching equip 
-------------------------------------------------------------------------------------
local currentKit
local skipActivate

local UIDs = {
    menu = tes3ui.registerID("MenuFletching")
}

local crafting = require("mer.goFletch.crafting.module")

local craftButtons = {
    
    { text = "Arrows", callback = function() crafting.showCraftingMenu({ handler = "arrows" }) end },
    { text = "Bolts", callback = function() crafting.showCraftingMenu({ handler = "bolts" }) end },
    { text = "Darts", callback = function() crafting.showCraftingMenu({ handler = "darts" }) end },
}

local pickupButton = { 
    text = "Pick Up", 
    callback = function()  
        skipActivate = true
        tes3.player:activate(currentKit)
    end
}
local cancelButton = { text = "Cancel" }

local function messageBox(params)

    local message = params.message
    local buttons = params.buttons

    local function callback(e)
        --get button from 0-indexed MW param
        local button = buttons[e.button+1]
        if button.callback then
            timer.delayOneFrame( function()
                button.callback()
            end)
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

local function fetchSelectMessage(includePickup)
    local buttons = {}
    for _, button in ipairs(craftButtons) do
        table.insert(buttons, button)
    end
    if includePickup then
        table.insert(buttons, pickupButton)
    end
    table.insert(buttons, cancelButton)

    messageBox{
        message = "Fletching Station",
        buttons = buttons
    }
end



local function onActivate(e)
    if e.target.object.id == "mer_fletch_kit" then
        if skipActivate then 
            skipActivate = false
        else
            if not tes3.menuMode() then
                currentKit = e.target
                fetchSelectMessage(true)
                return false
            end
        end
    end
end

event.register("activate", onActivate)


local function onEquip(e)
    
    if e.item.id == "mer_fletch_kit" then
        if config.fletchFromInventory then
            tes3ui.leaveMenuMode(tes3ui.registerID("MenuInventory"))
            currentKit = e.item.reference
            fetchSelectMessage()
        end
        return false
    end
end
event.register("equip", onEquip, { priority = 2 } ) 


local function fletchTooltip(e)
    if e.object.id == "mer_fletch_kit" then
        e.tooltip:findChild(tes3ui.registerID("HelpMenu_uses")).visible = false
        e.tooltip:findChild(tes3ui.registerID("HelpMenu_qualityCondition")).visible = false
    end
end

event.register("uiObjectTooltip", fletchTooltip)

local function initialised() 
    local crafting = require("mer.goFletch.crafting.module")
    local recipes = require("mer.goFletch.recipes")
    ---------------------------------------------------------
    --Handler
    ---------------------------------------------------------
    crafting.registerHandler{
        id = "arrows",
        title = "Arrow Fletching", 
        successSound = "Item Ammo Up",
        --onClose = fetchSelectMessage
    }
    crafting.registerHandler{
        id = "bolts",
        title = "Bolt Fletching", 
        successSound = "Item Ammo Up",
        --onClose = fetchSelectMessage
    }

    crafting.registerHandler{
        id = "darts",
        title = "Dart Fletching", 
        successSound = "Item Ammo Up",
        --onClose = fetchSelectMessage
    }

    local function registerRecipe(ammo, material, enchantment)

        local handler = ammo.handler
        local skill = "fletching"
        local skillValue = ammo.skillReq + material.skillReq 
        local resultID = ammo.id .. material.id
        local itemReqs = {}

        local description = material.description .. " " .. ammo.description

        for _, item in ipairs(material.ingredients) do
            table.insert(itemReqs, item)
        end
        
        if enchantment then
            description = description .. " " .. enchantment.description
            skillValue = skillValue + enchantment.skillReq
            resultID = resultID .. enchantment.id
            for _, item in ipairs(enchantment.ingredients) do
                table.insert(itemReqs, item)
            end
        end
        description = description .. "."

        crafting.registerRecipe{
            handler = handler,
            skill = skill,
            description = description,
            result = { id = resultID, count = ammo.craftCount },
            skillReqs = {
                { id = skill, value = skillValue }
            },
            difficulty = skillValue,
            itemReqs = itemReqs,
            onCraftSuccess = function(package, attempt)
                local message = "Created %d %s."
                if package.result.count then
                    message = "Created %d %ss."
                end
                tes3.messageBox(message, package.result.count, package.result.item.name )
            end,
        }
    end

    for _, ammo in pairs(recipes.ammoTypes) do
        for _, material in pairs(recipes.materials) do
            registerRecipe(ammo, material)
            for _, enchantment in pairs(recipes.enchantments) do
                registerRecipe(ammo, material, enchantment)
            end
        end
    end
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