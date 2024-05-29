-- Include the Crafting Framework API and check if it exists
local CraftingFramework = include("CraftingFramework")
if not CraftingFramework then return end

-- Load required modules
local materials = require("hornsilk.PRAY.materials")
local prayers = require("hornsilk.PRAY.prayers")
local rituals = require("hornsilk.PRAY.rituals")
local animation = require("hornsilk.PRAY.animation")
local skills = require("hornsilk.PRAY.skills")

-- CONFIGURATION --
local configPath = "PRAY"
local config = mwse.loadConfig(configPath)
if (config == nil) then
	config = {
        logLevel = "INFO",
        hotKey = {
            enabled = true,
            keyCode = tes3.scanCode.p,
        },
        onePrayerPerDay = true,
        allPrayersShortDuration = false,
        allSkillReqZero = false,
        noMaterialsReqs = false,
        allPrayersKnown = false,
    }
end

-- INITIALIZE SKILLS --
local skillModule = require("OtherSkills.skillModule")

-- Register skills for the Prayer System
-- decent place to look for icons https://en.uesp.net/wiki/Category:Morrowind-Banner_Images

local function onSkillReady()
    -- Divine Theology skill
    local divineDescription = (
        "The Divine Theology skill determines your knowledge of prayers and rituals of the Divines."
    )
    skillModule.registerSkill(
        "divine_theology",
        {
            name = "Divine Theology",
            icon = "Icons\\PRAY\\divine.dds",
            value = 10,
            attribute =  tes3.attribute.willpower,
            description = divineDescription,
            specialization = tes3.specialization.magic,
            active = "active"
        }
    )

    -- Tribunal Theology skill
    local tribunalDescription = (
        "The Tribunal Theology skill determines your knowledge of traditional prayers and rituals of the Tribunal Temple."
    )
    skillModule.registerSkill(
        "tribunal_theology",
        {
            name = "Tribunal Theology",
            icon = "Icons\\PRAY\\almsivi.dds",
            value = 10,
            attribute =  tes3.attribute.intelligence,
            description = tribunalDescription,
            specialization = tes3.specialization.magic,
            active = "active"
        }
    )

    -- Ashlander Theology skill
    local ashlanderDescription = (
        "The Ashlander Theology skill determines your knowledge of traditional prayers and rituals of the Ashlanders of Morrowind."
    )
    skillModule.registerSkill(
        "ashlander_theology",
        {
            name = "Ashlander Theology",
            icon = "Icons\\PRAY\\ashlander.dds",
            value = 10,
            attribute =  tes3.attribute.endurance,
            description = ashlanderDescription,
            specialization = tes3.specialization.magic,
            active = "active"
        }
    )

    -- Sixth House Theology skill
    local sixthHouseDescription = (
        "The Sixth House Theology skill determines your knowledge of traditional prayers and rituals of the Tribe Unmourned."
    )
    skillModule.registerSkill(
        "sixth_house_theology",
        {
            name = "Sixth House Theology",
            icon = "Icons\\PRAY\\sixthHouse.dds",
            value = 10,
            attribute =  tes3.attribute.personality,
            description = sixthHouseDescription,
            specialization = tes3.specialization.magic,
            active = "active"
        }
    )
end
event.register("OtherSkills:Ready", onSkillReady)

-- Register materials with the Crafting Framework
local function registerMaterials(materialTable)
    CraftingFramework.Material:registerMaterials(materialTable)
end

-- Register prayers and rituals
local function registerPrayerOrRitual(recipeTable, type)
    -- Extract recipe details
    local id = recipeTable.id
    local name = recipeTable.name
    local skill = recipeTable.skill
    local skillValue = recipeTable.skillReq
    local description = recipeTable.description
    local category = recipeTable.handler
    local text = recipeTable.text
    local effects = recipeTable.spellEffects
    local image = recipeTable.image

    -- defaults
    local prayerDuration = recipeTable.prayerDuration or 15 --15 in game minutes
    local castChance = recipeTable.castChance or 100
    local skillProgress = recipeTable.skillProgress or 50

    local bypassResistances = recipeTable.bypassResistances
    if bypassResistances == nil then
        bypassResistances = true
    end

    -- knowledgeRequirement logic
    local knowledgeRequirement = recipeTable.knowledgeRequirement or skills.data[skill].knowledgeRequirement

    -- materialsReq logic
    local materialsReq = {}
    if type == "prayer" then
        materialsReq = {}
    elseif type == "ritual" then
        materialsReq = recipeTable.materials
    end

    -- soundPath logic
    local soundPath = recipeTable.soundPath or skills.data[skill].sound or "Fx\\envrn\\chant.wav"

    --CONFIG OPTIONS--
    if config.allPrayersShortDuration then prayerDuration = 3 end
    if config.allSkillReqZero then skillValue = 0 end
    if config.noMaterialsReqs then materialsReq = {} end
    if config.allPrayersKnown then
        knowledgeRequirement = function () return true end
    end

    -- Define the recipe
    local recipe = {
        id = id,
        description = description,
        noResult = true,
        materials = materialsReq,
        knowledgeRequirement = knowledgeRequirement,
        skillRequirements = {
            { skill = skill, requirement = skillValue, maxProgress = skillProgress }
        },
        category = category,
        name = name,
        uncarryable = true,
        soundPath = soundPath,
        previewImage = image,
        craftCallback = function()
            -- Display message, play animation, and apply magic effects
            tes3.messageBox(text)
            tes3.player.data.lastDayPrayed = tes3.worldController.daysPassed.value
            animation.defaultAnimationBegin()
            timer.start{
                duration = prayerDuration/60, --duration in hours for game timers
                type = timer.game,
                callback = function ()
                    animation.defaultAnimationEnd()
                    tes3.applyMagicSource({
                        reference = tes3.player,
                        castChance = castChance,
                        bypassResistances = bypassResistances,
                        name = name,
                        effects = effects
                    })
                    tes3.playSound({soundPath = "Fx\\magic\\restH.wav"})
                end
            }
        end
    }
    return recipe
end

-- Register prayers and rituals in the Crafting Framework
local function registerPrayersAndRituals()
    if not CraftingFramework then
        -- CraftingFramework not found, cannot proceed
        return
    end

    -- Create a list to store recipes
    local recipeList = {}
    -- Register prayers
    for _, prayerList in pairs(prayers) do
        for _, prayerTable in pairs(prayerList) do
            local recipe = registerPrayerOrRitual(prayerTable, "prayer")
            table.insert(recipeList, recipe)
        end
    end
    -- Register rituals
    for _, ritualList in pairs(rituals) do
        for _, ritualTable in pairs(ritualList) do
            local recipe = registerPrayerOrRitual(ritualTable, "ritual")
            table.insert(recipeList, recipe)
        end
    end

    -- Register the Prayer Menu using Crafting Framework's MenuActivator
    CraftingFramework.MenuActivator:new{
        id = "PRAY:ActivatePrayerMenu",
        type = "event",
        name = "Prayer Menu",
        recipes = recipeList,
        defaultSort = "skill",
        defaultFilter = "skill",
        defaultShowCategories = true
    }
end

-- Callback when the game is initialized
local function initialised()
    mwse.log("[PRAY] Registering Materials")
    registerMaterials(materials)
    mwse.log("[PRAY] Registering Prayers and Rituals")
    registerPrayersAndRituals()
end
event.register("initialized", initialised)

-- Callback for a key press event
---@param e keyDownEventData
local function onKeyDown(e)
    if e.keyCode ~= config.hotKey.keyCode then return end
    if tes3ui.menuMode() then return end

    -- Check if prayer is allowed based on config settings
    local prayerAllowed = false
    if config.onePrayerPerDay then
        -- Check if player has already prayed today
        if tes3.player.data.lastDayPrayed == nil then
            prayerAllowed = true
        elseif tes3.player.data.lastDayPrayed < tes3.worldController.daysPassed.value then
            prayerAllowed = true
        end
    else
        prayerAllowed = true
    end

    -- Open the Prayer Menu or show a message if prayer is not allowed
    if prayerAllowed then
        event.trigger("PRAY:ActivatePrayerMenu")
    else
        tes3.messageBox("Wait until tomorrow to pray again.")
    end
end
event.register(tes3.event.keyDown, onKeyDown)

-- Callback for obtaining book text (Ashlander Lit Books)
--- @param e bookGetTextEventData
local function ashlanderLitCallback(e)
    if CraftingFramework.interop.getRecipe("basic_ancestor_prayer"):isKnown() then return end
    local isAshlanderLit = false
        for bookId, _ in pairs(CraftingFramework.interop.getMaterials("ashlander_lit").ids) do
        if string.lower(e.book.id) == string.lower(bookId) then
            isAshlanderLit = true
            break
        end
    end
    if not isAshlanderLit then return end

    tes3.messageBox("You have gained knowledge of a prayer from this book.\nYou learned an Ashlander Prayer.")
    tes3.playSound({soundPath = "Fx\\inter\\levelUP.wav"})
    tes3.player.data.hasReadAshlanderLit = true
end
event.register(tes3.event.bookGetText, ashlanderLitCallback)

--------------------------------------------
-- MCM (Mod Configuration Menu)
--------------------------------------------

-- Register the mod configuration menu
local function registerMCM()
    local sideBarDefault = (
        "PRAY: Prayers, Rituals, And You \n\n" ..
        "PRAY adds Tribunal, Divine, Ashlander, and Sixth House Prayers " ..
        "into the game utilising merlord's skill frameworks " ..
        "and MWSE to fully integrate it into the vanilla UI. \n\n" ..
        "Your new skills (Tribunal, Divine, Ashlander, and Sixth House " ..
        "Theology) can be found in your stats menu under 'Other" ..
        " Skills'.\n\nYou are able to pray once a day, and praying " ..
        "will level up the corresponding skill, unlocking new " ..
        "prayers and rituals. Rituals are more involved prayers " ..
        "that consume materials.\n\nUnlock Tribunal Prayers by " ..
        "joining the Tribunal Temple.\nUnlock Divine Prayers by " ..
        "joining the Imperial Cult.\nUnlock Ashlander Prayers " ..
        "becoming a Clanfriend of the Urshilaku Camp.\nUnlock " ..
        "Sixth House Prayers by meeting Dagoth Gares."
    )

    local function addSideBar(component)
        component.sidebar:createInfo{ text = sideBarDefault}
        local hyperlink = component.sidebar:createCategory("Credits: ")
        hyperlink:createHyperLink{
            text = "Scripting: hornsilk",
            exec = "start https://github.com/hornsilk/PRAY_for_morrowind",
        }
        hyperlink:createHyperLink{
            text = "Divines Art: Feivelyn",
            exec = "https://www.deviantart.com/feivelyn",
        }
        hyperlink:createHyperLink{
            text = "Tribunal Saints Art: Matthew Weathers",
            exec = "https://matinthehat.artstation.com/",
        }
        hyperlink:createHyperLink{
            text = "Dagoth Art: Brujoloco",
            exec = "https://www.nexusmods.com/morrowind/mods/48576?tab=files",
        }
    end

    -- Create MCM template
    local template = mwse.mcm.createTemplate("PRAY")
    template:saveOnClose(configPath, config)
    local page = template:createSideBarPage{}
    addSideBar(page)

    -- Add MCM options
    page:createKeyBinder{
        label = "Hot key",
        description = "The key to activate the prayer menu.",
        variable = mwse.mcm.createTableVariable{ id = "hotKey", table = config },
        allowCombinations = true
    }
    -- ... (other MCM options)

    -- Register MCM template
    page:createYesNoButton({
        label = "Limit to one prayer per day",
        description = "By default, the Prayer Menu will not open if you've already crafted a prayer or ritual during this game day.",
        variable = mwse.mcm:createTableVariable({ id = "onePrayerPerDay", table = config }),
    })

    page:createYesNoButton({
        label = "Fast prayer mode",
        description = "Set all prayers and rituals to short duration. RESTART REQUIRED.\nBy default, prayers take 15 game-minutes"..
        "to complete; setting this to `True` will make them take 3 game-minutes.",
        variable = mwse.mcm:createTableVariable({ id = "allPrayersShortDuration", table = config }),
    })

    page:createYesNoButton({
        label = "No skill requirements",
        description = "Set all prayers and rituals skill requirements to zero. RESTART REQUIRED.",
        variable = mwse.mcm:createTableVariable({ id = "allSkillReqZero", table = config }),
    })

    page:createYesNoButton({
        label = "No material requirements",
        description = "Set all prayers and rituals material requirements to none. RESTART REQUIRED.",
        variable = mwse.mcm:createTableVariable({ id = "noMaterialsReqs", table = config }),
    })

    page:createYesNoButton({
        label = "Start with all prayers known",
        description = "Set all prayers and rituals knowledge requirements to none. RESTART REQUIRED.",
        variable = mwse.mcm:createTableVariable({ id = "allPrayersKnown", table = config }),
    })

    template:register()
end

-- Register the MCM registration callback
event.register("modConfigReady", registerMCM)
