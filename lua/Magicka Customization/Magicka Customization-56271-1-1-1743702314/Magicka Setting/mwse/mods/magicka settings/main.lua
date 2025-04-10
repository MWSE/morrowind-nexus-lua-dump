-- Default config.
---@class Kirgan.magickaConfig
local defaultConfig = {
    -- Use a subtable in case you want to add more settings later.
    magickaModifiers = {
        [tes3.skill.alteration]     = 0.50,
        [tes3.skill.conjuration]    = 0.50,
        [tes3.skill.destruction]    = 0.50,
        [tes3.skill.illusion]       = 0.50,
        [tes3.skill.restoration]    = 0.50,
        [tes3.skill.mysticism]      = 0.50,
    },
}

-- Load configuration and use default values if no configuration exists
-- Pass in the default config so that it adds in missing settings and properly converts numerical values.
---@type Kirgan.magickaConfig
local config = mwse.loadConfig("magicka_settings", defaultConfig)

-- Function to calculate and set Magicka
local function calculateMagicka(mobile)
    if mobile then
        local intelligence = mobile.intelligence.current
        local magickaMultiplier = mobile.magickaMultiplier.current
        local totalSkillContribution = 0

        -- Calculate the total contribution from skills
        for skillId, modifier in pairs(config.magickaModifiers) do
            local skillValue = mobile.skills[skillId + 1].current  -- Current skill value
            local contribution = skillValue * modifier
            totalSkillContribution = totalSkillContribution + contribution
        end

        -- Calculate the individual Magicka
        local customMagicka = (intelligence * magickaMultiplier) + totalSkillContribution

        -- Set the current and base Magicka (we're only setting base for now)
        tes3.setStatistic({ reference = mobile.reference, name = "magicka", base = customMagicka })
        -- tes3.setStatistic({ reference = mobile.reference, name = "magicka", current = customMagicka })
    end
end

-- Function to calculate Magicka for all relevant NPCs in the player's cell
local function calculateMagickaForNPCsInCell()
    for ref in tes3.getPlayerCell():iterateReferences(tes3.objectType.npc) do
        local mobile = ref.mobile
        if mobile then
            calculateMagicka(mobile)
        end
    end
end

-- Store previous intelligence values for tracking
local previousIntelligence = {}

local function checkIntelligenceIncrease()
    local mobile = tes3.mobilePlayer
    if mobile then
        local currentIntelligence = mobile.intelligence.current
        local previousInt = previousIntelligence[mobile.reference] or currentIntelligence

   
      

        -- Check if intelligence has increased and recalculate Magicka if so
        if currentIntelligence > previousInt then
           
            calculateMagicka(mobile)
        end

        -- Update stored intelligence value
        previousIntelligence[mobile.reference] = currentIntelligence
    end
end

-- Register the check function to run on each frame
event.register("simulate", checkIntelligenceIncrease)

-- Calculation after saving and closing the menu
local function onMCMClose()
    -- Calculation for the player
    calculateMagicka(tes3.mobilePlayer)
    -- Calculation for all NPCs in the current cell
    calculateMagickaForNPCsInCell()
end

local function customOnClose()
    -- Manually save the configuration
    mwse.saveConfig("magicka_settings", config)
    -- Then perform the Magicka calculation
    onMCMClose()
end

-- MCM menu setup
local function registerMCM()
    local template = mwse.mcm.createTemplate{
        name = "Magicka Customization",
        config = config,
        defaultConfig = defaultConfig,
        showDefaultSetting = true,
    }
    template:register()
    -- Save configuration in MCM
    template.onClose = customOnClose

    local page = template:createSideBarPage{
        label = "Magicka Skill Modifiers",
        description = "Customize the skill modifiers for each school of magic affecting Magicka calculation.",
        -- The subtable this page is responsible for
        configKey = "magickaModifiers",
    }

    -- Create sliders for each skill modifier
    for skillId, _modifier in pairs(config.magickaModifiers) do
        page:createPercentageSlider{
            label = tes3.getSkillName(skillId) .. " Modifier",
            step = 0.05,
            jump = 0.10,
            configKey = skillId
        }
    end
end

-- Register MCM and events
event.register("modConfigReady", registerMCM)

event.register("loaded", function()
    -- Calculation for the player
    calculateMagicka(tes3.mobilePlayer)
    -- Calculation for all NPCs in the current cell
    calculateMagickaForNPCsInCell()
end)

event.register(tes3.event.skillRaised, function()
    calculateMagicka(tes3.mobilePlayer)
end)

event.register("cellChanged", function()
    -- Calculation for all NPCs in the new cell
    calculateMagickaForNPCsInCell()
end)

event.register("levelUp", function()
    -- Calculation for the player
    calculateMagicka(tes3.mobilePlayer)
    -- Calculation for all NPCs in the current cell
    calculateMagickaForNPCsInCell()
end)
