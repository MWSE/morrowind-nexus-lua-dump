local config = require("OperatorJack.IllegalSummoning.config")

local function getMagicEffects()
    local list = {}
    local MGEF = tes3.dataHandler.nonDynamicData.magicEffects

    for i=1, #MGEF do
        list[#list+1] = MGEF[i].name:lower()
    end
    table.sort(list)
    return list
end

local function getNPCs()
    local temp = {}
    for obj in tes3.iterateObjects(tes3.objectType.npc) do
        temp[obj.name:lower()] = true
    end
    
    local list = {}
    for name in pairs(temp) do
        list[#list+1] = name
    end
    
    table.sort(list)
    return list
end

local function createGeneralCategory(template)
    local page = template:createSideBarPage{
        label = "General Settings",
        description = "Hover over a setting to learn more about it."
    }

    local category = page:createCategory{
        label = "General Settings"
    }

    -- Create option to capture debug mode.
    category:createSlider{
        label = "Bounty Value",
        description = "Use this option to configure the amount of bounty received when getting caught during an illegal summon.",
        min = 0,
        max = 2500,
        step = 1,
        jump = 50,
        variable = mwse.mcm.createTableVariable{
            id = "bountyValue",
            table = config
        }
    }

    -- Create option to capture debug mode.
    category:createSlider{
        label = "NPC Crime Trigger Distance",
        description = "Use this option to configure the distance at which guards will attack an NPC during an illegal summon. This ONLY applies to NPCs.",
        min = 0,
        max = 5000,
        step = 1,
        jump = 100,
        variable = mwse.mcm.createTableVariable{
            id = "npcTriggerDistance",
            table = config
        }
    }

    return category
end

local function createNpcWhitelist(template)
    -- Whitelist Page
    template:createExclusionsPage{
        label = "Whitelist NPCs",
        description = "Whitelisted NPCs can cast magic effects that are not blacklisted.",
        leftListLabel = "Whitelist NPCs",
        rightListLabel = "NPCs",
        variable = mwse.mcm.createTableVariable{
            id = "npcWhitelist",
            table = config,
        },
        filters = {
            {callback = getNPCs},
        },
    }
end

local function createMagicEffectBlacklist(template)
    template:createExclusionsPage{
        label = "Blacklist Magic Effects",
        description = "Blacklisted magic effects will trigger a crime, even on whitelisted NPCs. Whitelisted magic effects override blacklisted magic effects.",
        leftListLabel = "Blacklist Effects",
        rightListLabel = "Magic Effects",
        variable = mwse.mcm.createTableVariable{
            id = "effectBlacklist",
            table = config,
        },
        filters = {
            {callback = getMagicEffects},
        },
    }
end

local function createMagicEffectWhitelist(template)
    template:createExclusionsPage{
        label = "Whitelist Magic Effects",
        description = "Whitelisted magic effects will never trigger a crime.",
        leftListLabel = "Whitelist Effects",
        rightListLabel = "Magic Effects",
        variable = mwse.mcm.createTableVariable{
            id = "effectWhitelist",
            table = config,
        },
        filters = {
            {callback = getMagicEffects},
        },
    }
end

-- Handle mod config menu.
local template = mwse.mcm.createTemplate("Illegal Summoning")
template:saveOnClose("Illegal-Summoning", config)

createGeneralCategory(template)
createNpcWhitelist(template)
createMagicEffectBlacklist(template)
createMagicEffectWhitelist(template)

mwse.mcm.register(template)