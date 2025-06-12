local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require("openmw.interfaces")
local auxUi = require('openmw_aux.ui')
local self = require('openmw.self')
local types = require('openmw.types')
local async = require('openmw.async')
local input = require('openmw.input')
local core = require('openmw.core')
local camera = require('openmw.camera')
local debug = require('openmw.debug')
local MODE = camera.MODE

local screenSize = ui.screenSize()

local scriptVersion = 2

-- Calculate positions and sizes
local screenWidth, screenHeight = ui.screenSize().x, ui.screenSize().y
local barWidth = screenWidth * 0.75
local barHeight = screenHeight * 0.17
local barX = (screenWidth - barWidth) / 2
local barY = screenHeight * 0.92 - barHeight
local cursorPos = util.vector2(0, 0)

local staminaBarWidth = screenWidth * 0.135
local magickaBarWidth = screenWidth * 0.135

local actorStamina = types.Actor.stats.dynamic.fatigue
local actorMagicka = types.Actor.stats.dynamic.magicka
local actorHealth = types.Actor.stats.dynamic.health

local meleeMode


local interventionButtonState = "divine" -- default intervention state
local interventionPauseTime = nil

local assignedItems = {} -- Table for storing items assigned to slots
local assignedSpells = {} -- Table for storing spells assigned to slots

-- Track mouse button press states
local mouseButtonWasPressed = {false, false, false}
local mouseButtonJustPressed = {false, false, false} -- Extra state array for debouncing

-- Store the raw class name
local rawClass = types.NPC.record(self.object).class

-- Capitalize only the first letter
local playerClass = rawClass:sub(1, 1):upper() .. rawClass:sub(2)

local classAtlas = 'Textures/classatlasround.dds' -- a 640x640 texture atlas of class icons

local classTextures = {
    Acrobat = ui.texture{
        path = classAtlas,
        offset = util.vector2(0, 0),
        size = util.vector2(128, 128)
    },
    Agent = ui.texture{
        path = classAtlas,
        offset = util.vector2(128, 0),
        size = util.vector2(128, 128)
    },
    Archer = ui.texture{
        path = classAtlas,
        offset = util.vector2(256, 0),
        size = util.vector2(128, 128)
    },
    Assassin = ui.texture{
        path = classAtlas,
        offset = util.vector2(384, 0),
        size = util.vector2(128, 128)
    },
    Barbarian = ui.texture{
        path = classAtlas,
        offset = util.vector2(512, 0),
        size = util.vector2(128, 128)
    },
    Bard = ui.texture{
        path = classAtlas,
        offset = util.vector2(0, 128),
        size = util.vector2(128, 128)
    },
    Battlemage = ui.texture{
        path = classAtlas,
        offset = util.vector2(128, 128),
        size = util.vector2(128, 128)
    },
    Crusader = ui.texture{
        path = classAtlas,
        offset = util.vector2(256, 128),
        size = util.vector2(128, 128)
    },
    Healer = ui.texture{
        path = classAtlas,
        offset = util.vector2(384, 128),
        size = util.vector2(128, 128)
    },
    Knight = ui.texture{
        path = classAtlas,
        offset = util.vector2(512, 128),
        size = util.vector2(128, 128)
    },
    Mage = ui.texture{
        path = classAtlas,
        offset = util.vector2(0, 256),
        size = util.vector2(128, 128)
    },
    Monk = ui.texture{
        path = classAtlas,
        offset = util.vector2(128, 256),
        size = util.vector2(128, 128)
    },
    Nightblade = ui.texture{
        path = classAtlas,
        offset = util.vector2(256, 256),
        size = util.vector2(128, 128)
    },
    Pilgrim = ui.texture{
        path = classAtlas,
        offset = util.vector2(384, 256),
        size = util.vector2(128, 128)
    },
    Rogue = ui.texture{
        path = classAtlas,
        offset = util.vector2(512, 256),
        size = util.vector2(128, 128)
    },
    Scout = ui.texture{
        path = classAtlas,
        offset = util.vector2(0, 384),
        size = util.vector2(128, 128)
    },
    Sorcerer = ui.texture{
        path = classAtlas,
        offset = util.vector2(128, 384),
        size = util.vector2(128, 128)
    },
    Spellsword = ui.texture{
        path = classAtlas,
        offset = util.vector2(256, 384),
        size = util.vector2(128, 128)
    },
    Thief = ui.texture{
        path = classAtlas,
        offset = util.vector2(384, 384),
        size = util.vector2(128, 128)
    },
    Warrior = ui.texture{
        path = classAtlas,
        offset = util.vector2(512, 384),
        size = util.vector2(128, 128)
    },
    Witchhunter = ui.texture{
        path = classAtlas,
        offset = util.vector2(0, 512),
        size = util.vector2(128, 128)
    }
}

-- Get a default texture or random texture from classTextures if player class isn't recognized
local function getClassTexture(className)
    -- Check if the class exists in our texture collection
    if classTextures[className] then
        return classTextures[className]
    else
        -- Option 1: Return a default class texture (Warrior is a good default)
        -- return classTextures.Warrior
        
        -- Option 2: Return a random class texture
        local availableClasses = {}
        for class, _ in pairs(classTextures) do
            table.insert(availableClasses, class)
        end
        local randomClass = availableClasses[math.random(1, #availableClasses)]
        return classTextures[randomClass]
    end
end

local element = ui.create {
  layer = 'Windows',
  type = ui.TYPE.Widget,
  props = {
	size = util.vector2(16, 16),
  },
}

actionSlotsContent1 = ui.content{}
for i = 1, 8 do
    table.insert(actionSlotsContent1, {
        name = "stackCount",
        type = ui.TYPE.Text,
        props = {
            autoSize = false,
			textAlignH = ui.ALIGNMENT.End,
			textAlignV = ui.ALIGNMENT.End,
			size = util.vector2(screenWidth * 0.02625, screenWidth * 0.02625),
			text = "",
            textSize = math.floor(22 * (screenHeight / 1080)),
            textColor = util.color.rgb(223/255, 201/255, 159/255),
            --relativePosition = util.vector2(1, 0.5),
        },
        content = ui.content{
            {
                name = "backgroundImage",
                type = ui.TYPE.Image,
                props = {
                    size = util.vector2(screenWidth * 0.02625, screenWidth * 0.02625),
                    resource = ui.texture({ path = 'Textures/slot.png' }),
                    alpha = 1.0, -- Changed from 0.7 to 1.0 to remove transparency
                },
                content = ui.content{
                    {
                        name = "magicIndicator",
                        type = ui.TYPE.Image, -- Using Flex for flexibility, change if needed
                        props = {
                            relativeSize = util.vector2(0.85, 0.85),
							relativePosition = util.vector2(0.5, 0.5),
							anchor = util.vector2(0.5, 0.5),
							resource = ui.texture({ path = "textures\\menu_icon_magic_mini.dds" }),
                            visible = false,
							
                        },
                    },
                    {
                        name = "itemSlot",
                        type = ui.TYPE.Image, -- Using Flex for flexibility, change if needed
                        props = {
                            relativeSize = util.vector2(0.85, 0.85),
							relativePosition = util.vector2(0.5, 0.5),
							anchor = util.vector2(0.5, 0.5),
							resource = ui.texture({ path = 'Textures/slot.png' }),
							
                        },
                    },
                },
            },
        },
    })
end

actionSlotsContent2 = ui.content{}
for i = 9, 16 do
    table.insert(actionSlotsContent2, {
        name = "stackCount",
        type = ui.TYPE.Text,
        props = {
            autoSize = false,
			textAlignH = ui.ALIGNMENT.End,
			textAlignV = ui.ALIGNMENT.End,
			size = util.vector2(screenWidth * 0.02625, screenWidth * 0.02625),
			text = "",
            textSize = math.floor(22 * (screenHeight / 1080)),
            textColor = util.color.rgb(223/255, 201/255, 159/255),
            --relativePosition = util.vector2(1, 0.5),
        },
        content = ui.content{
            {
                name = "backgroundImage",
                type = ui.TYPE.Image,
                props = {
                    size = util.vector2(screenWidth * 0.02625, screenWidth * 0.02625),
                    resource = ui.texture({ path = 'Textures/slot.png' }),
                    alpha = 1.0,
                },
                content = ui.content{
                    {
                        name = "magicIndicator",
                        type = ui.TYPE.Image, -- Using Flex for flexibility, change if needed
                        props = {
                            relativeSize = util.vector2(0.85, 0.85),
							relativePosition = util.vector2(0.5, 0.5),
							anchor = util.vector2(0.5, 0.5),
							resource = ui.texture({ path = "textures\\menu_icon_magic_mini.dds" }),
                            visible = false,
							
                        },
                    },
                    {
                        name = "itemSlot",
                        type = ui.TYPE.Image, -- Using Flex for flexibility, change if needed
                        props = {
                            relativeSize = util.vector2(0.85, 0.85),
							relativePosition = util.vector2(0.5, 0.5),
							anchor = util.vector2(0.5, 0.5),
							resource = ui.texture({ path = 'Textures/slot.png' }),
							
                        },
                    },
                },
            },
        },
    })
end

spellSlotsContent1 = ui.content{}
for i = 17, 24 do
    table.insert(spellSlotsContent1, {
        type = ui.TYPE.Image,
        props = {
            size = util.vector2(screenWidth * 0.02625, screenWidth * 0.02625),
            resource = ui.texture({ path = 'Textures/slot.png' }),
        },
    })
end

spellSlotsContent2 = ui.content{}
for i = 25, 32 do
    table.insert(spellSlotsContent2, {
        type = ui.TYPE.Image,
        props = {
            size = util.vector2(screenWidth * 0.02625, screenWidth * 0.02625),
            resource = ui.texture({ path = 'Textures/slot.png' }),
        },
    })
end
statusContent1 = ui.content{}
for i = 1, 3 do
    table.insert(statusContent1, {
        type = ui.TYPE.Image,
        props = {
            size = util.vector2(screenWidth * 0.01, screenWidth * 0.01),
            resource = ui.texture({ path = 'Textures/slot.png' }),
        },
    })
end
statusContent2 = ui.content{}
for i = 4, 6 do
    table.insert(statusContent2, {
        type = ui.TYPE.Image,
        props = {
            size = util.vector2(screenWidth * 0.01, screenWidth * 0.01),
            resource = ui.texture({ path = 'Textures/slot.png' }),
        },
    })
end
statusContent3 = ui.content{}
for i = 7, 9 do
    table.insert(statusContent3, {
        type = ui.TYPE.Image,
        props = {
            size = util.vector2(screenWidth * 0.01, screenWidth * 0.01),
            resource = ui.texture({ path = 'Textures/slot.png' }),
        },
    })
end

miscContent1 = ui.content{}
for i = 1, 2 do
    table.insert(miscContent1, {
        name = "stackCount",
        type = ui.TYPE.Text,
        props = {
            autoSize = false,
			textAlignH = ui.ALIGNMENT.End,
			textAlignV = ui.ALIGNMENT.End,
			size = util.vector2(screenWidth * 0.02625, screenWidth * 0.02625),
			text = "",
            textSize = math.floor(22 * (screenHeight / 1080)),
            textColor = util.color.rgb(223/255, 201/255, 159/255),
            --relativePosition = util.vector2(1, 0.5),
        },
        content = ui.content{
            {
                name = "backgroundImage",
                type = ui.TYPE.Image,
                props = {
                    size = util.vector2(screenWidth * 0.02625, screenWidth * 0.02625),
                    resource = ui.texture({ path = 'Textures/slot.png' }),
                    alpha = 1.0, -- Changed from 0.7 to 1.0 to remove transparency
                },
                content = ui.content{
                    {
                        name = "magicIndicator",
                        type = ui.TYPE.Image, -- Using Flex for flexibility, change if needed
                        props = {
                            relativeSize = util.vector2(0.85, 0.85),
							relativePosition = util.vector2(0.5, 0.5),
							anchor = util.vector2(0.5, 0.5),
							resource = ui.texture({ path = "textures\\menu_icon_magic_mini.dds" }),
                            visible = false,
							
                        },
                    },
                    {
                        name = "itemSlot",
                        type = ui.TYPE.Image, -- Using Flex for flexibility, change if needed
                        props = {
                            relativeSize = util.vector2(0.85, 0.85),
							relativePosition = util.vector2(0.5, 0.5),
							anchor = util.vector2(0.5, 0.5),
							resource = ui.texture({ path = 'Textures/slot.png' }),
							
                        },
                    },
                },
            },
        },
    })
end

miscContent2 = ui.content{}
for i = 3, 4 do
    table.insert(miscContent2, {
        name = "stackCount",
        type = ui.TYPE.Text,
        props = {
            autoSize = false,
			textAlignH = ui.ALIGNMENT.End,
			textAlignV = ui.ALIGNMENT.End,
			size = util.vector2(screenWidth * 0.02625, screenWidth * 0.02625),
			text = "",
            textSize = math.floor(22 * (screenHeight / 1080)),
            textColor = util.color.rgb(223/255, 201/255, 159/255),
            --relativePosition = util.vector2(1, 0.5),
        },
        content = ui.content{
            {
                name = "backgroundImage",
                type = ui.TYPE.Image,
                props = {
                    size = util.vector2(screenWidth * 0.02625, screenWidth * 0.02625),
                    resource = ui.texture({ path = 'Textures/slot.png' }),
                    alpha = 1.0,
                },
                content = ui.content{
                    {
                        name = "magicIndicator",
                        type = ui.TYPE.Image, -- Using Flex for flexibility, change if needed
                        props = {
                            relativeSize = util.vector2(0.85, 0.85),
							relativePosition = util.vector2(0.5, 0.5),
							anchor = util.vector2(0.5, 0.5),
							resource = ui.texture({ path = "textures\\menu_icon_magic_mini.dds" }),
                            visible = false,
							
                        },
                    },
                    {
                        name = "itemSlot",
                        type = ui.TYPE.Image, -- Using Flex for flexibility, change if needed
                        props = {
                            relativeSize = util.vector2(0.85, 0.85),
							relativePosition = util.vector2(0.5, 0.5),
							anchor = util.vector2(0.5, 0.5),
							resource = ui.texture({ path = 'Textures/slot.png' }),
							
                        },
                    },
                },
            },
        },
    })
end



-- Create container tables for dynamic UI elements
local statusRows = {
    elements = {},  -- Store UI elements
    contents = {}   -- Store content data
}



local bg = ui.create {
    layer = 'HUD',
    type = ui.TYPE.Image,
    props = {
        position = util.vector2(1, 0),
        visible = true,
        resource = ui.texture({ path = 'Textures/bg.png' }),
        size = util.vector2(screenWidth*1.004, screenHeight)
    },
}   

-- Define the action bar layout
local actionBar = ui.create {
    layer = 'HUD',
    type = ui.TYPE.Flex,
    props = {
        relativePosition = util.vector2(0.1275, 0.75),
        size = util.vector2(barWidth, barHeight),
        horizontal = false,
    },
    content = ui.content{
        -- First top-level widget: top_widget_root
        {
            name = "top_widget_root",
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
            },
            content = ui.content{
                {
                    name = "spacer_top",
                    type = ui.TYPE.Flex,
                    props = {
                        size = util.vector2(screenWidth * 0.176, screenWidth * 0.04025),
                    },
                },
                {
                    name = "character_status_parent_placeholder",
                    type = ui.TYPE.Flex,
                    props = {
                        --size = util.vector2(screenWidth * 0.1225, screenWidth * 0.035),
                    },
                    content = ui.content{
                        {
                            name = "status_effects_placeholder",
                            type = ui.TYPE.Flex,
                            props = {
                                --size = util.vector2(screenWidth * 0.1225, screenWidth * 0.0525),
                                horizontal = false,
                                arrange = ui.ALIGNMENT.Start,
                            },
                            content = ui.content{
                                {
                                    name = "status_container_placeholder",
                                    type = ui.TYPE.Flex,
                                    props = {
                                        --size = util.vector2(screenWidth * 0.1225, screenWidth * 0.0525),
                                        horizontal = false,
                                        arrange = ui.ALIGNMENT.Start,
                                    },
                                    content = ui.content{} -- Empty content to be filled dynamically
                                }
                            },
                        },
                    },
                },
                {
                    name = "bars_parent",
                    type = ui.TYPE.Flex,
                    props = {
                        size = util.vector2(screenWidth * 0.40075, screenHeight * 0.105),
						align = ui.ALIGNMENT.End,
						arrange = ui.ALIGNMENT.Center,
                    },
                    content = ui.content{
                        {
                            name = "magicka_bar",
                            type = ui.TYPE.Image,
                            props = {
                                size = util.vector2(screenWidth * 0.14, screenHeight * 0.0175),
                                resource = ui.texture({ path = 'Textures/bar.png' }),
                                color = util.color.rgb(0.16, 0.21, 0.49), -- Blue for magicka
                            },
                        },
                        {
                            name = "stamina_bar",
                            type = ui.TYPE.Image,
                            props = {
                                size = util.vector2(screenWidth * 0.14, screenHeight * 0.0175),
                                resource = ui.texture({ path = 'Textures/bar.png' }),
                                color = util.color.rgb(0, 0.46, 0.18), -- Green for stamina
                            },
                        },
                    },
                },
            },
        },
        -- Second top-level widget
        {
            name = "bottom_widget_root",
            type = ui.TYPE.Flex,
            props = {
                size = util.vector2(barWidth, screenHeight * 0.35),
                horizontal = true,
            },
            content = ui.content{
                {
                    name = "class_button_container",
                    type = ui.TYPE.Flex,
                    props = {
                        size = util.vector2(screenWidth * 0.04025, screenWidth * 0.06125),
						align = ui.ALIGNMENT.End
                    },
					content = ui.content {
						{
							name = "class_button",
							type = ui.TYPE.Image,
							props = {
								size = util.vector2(screenWidth * 0.04025, screenWidth * 0.04025),
								--resource = classTextures.Witchhunter,
								resource = getClassTexture(playerClass),
							},
						},
					},
                },
                {
                    name = "character_portrait",
                    type = ui.TYPE.Image,
                    props = {
                        resource = ui.texture({ path = 'Textures/portraits/' .. I.MM_WIDGET.getPortraitPath(self.object) .. 'portrait.png' }),
                        size = util.vector2(screenWidth * 0.0735, screenWidth * 0.0735),
                    },
                    content = ui.content{
                        {
                            name = "damage_overlay",
                            type = ui.TYPE.Image,
                            props = {
                                resource = ui.texture({ path = 'Textures/damageSlider.png' }),
                                size = util.vector2(screenWidth * 0.0735, screenWidth * 0.0735),
                                color = util.color.rgb(1, 0, 0),
                                alpha = 0.5,
                                visible = true,
                                relativePosition = util.vector2(0, -1),
                            },
                        },
                        {
                            name = "health_text",
                            type = ui.TYPE.Text,
                            props = {
                                autoSize = false,
                                size = util.vector2(screenWidth * 0.0735, screenWidth * 0.0735),
                                relativePosition = util.vector2(0, 0.75),
                                text = 'NaN/NaN',
                                textSize = math.floor(24 * (screenHeight / 1080)),
                                textShadow = true,
                                textShadowColor = util.color.rgb(0, 0, 0),
                                textColor = util.color.rgb(1, 1, 1),
                                textAlignH = ui.ALIGNMENT.Center,
                            },
                        },
                    },
                },
                {
                    name = "melee_weapon_parent",
                    type = ui.TYPE.Widget,
                    props = {
                        size = util.vector2(screenWidth * 0.02625, screenWidth * 0.02625),
                    },
					content = ui.content{
                        {
                            name = "magicIndicator",
                            type = ui.TYPE.Image, -- Using Flex for flexibility, change if needed
                            props = {
                                relativeSize = util.vector2(0.85, 0.85),
                                relativePosition = util.vector2(0.5, 0.5),
                                anchor = util.vector2(0.5, 0.5),
                                resource = ui.texture({ path = "textures\\menu_icon_magic_mini.dds" }),
                                visible = false,
                                
                            },
                        },
						{
							name = "melee_weapon_button",
							type = ui.TYPE.Image,
							props = {
								size = util.vector2(screenWidth * 0.02275, screenWidth * 0.02275),
								resource = ui.texture({ path = 'icons/k/stealth_handtohand.dds' }),
								relativePosition = util.vector2(0.5, 0.5),
								anchor = util.vector2(0.5, 0.5)
							},
						},
					}
                },
				{
                    name = "ranged_weapon_parent",
                    type = ui.TYPE.Widget,
                    props = {
                        size = util.vector2(screenWidth * 0.02625, screenWidth * 0.02625),
                    },
					content = ui.content{
                        {
                            name = "magicIndicator",
                            type = ui.TYPE.Image, -- Using Flex for flexibility, change if needed
                            props = {
                                relativeSize = util.vector2(0.85, 0.85),
                                relativePosition = util.vector2(0.5, 0.5),
                                anchor = util.vector2(0.5, 0.5),
                                resource = ui.texture({ path = "textures\\menu_icon_magic_mini.dds" }),
                                visible = false,
                                
                            },
                        },
						{
							name = "ranged_weapon_button",
							type = ui.TYPE.Image,
							props = {
								size = util.vector2(screenWidth * 0.02275, screenWidth * 0.02275),
								resource = ui.texture({ path = 'icons/k/stealth_marksman.dds' }),
								relativePosition = util.vector2(0.5, 0.5),
								anchor = util.vector2(0.5, 0.5)
							},
						},
					}
                },
                {
                    name = "slots_group",
                    type = ui.TYPE.Flex,
                    props = {
                        horizontal = true,
                    },
                    content = ui.content{
                        {
                            name = "action_slots",
                            type = ui.TYPE.Flex,
                            props = {
                                --size = util.vector2(screenWidth * 0.10, screenWidth * 0.045),
                                horizontal = false,
                            },
                            content = ui.content{
                                {
                                    name = "action_slots_child_1",
                                    type = ui.TYPE.Flex,
                                    props = {
                                        size = util.vector2(screenWidth * 0.02625, screenWidth * 0.02625),
                                        horizontal = true,
                                    },
									content = actionSlotsContent1,

								},
                                {
                                    name = "action_slots_child_2",
                                    type = ui.TYPE.Flex,
                                    props = {
                                        size = util.vector2(screenWidth * 0.02625, screenWidth * 0.02625),
                                        horizontal = true,
                                    },
                                    content = actionSlotsContent2,
                                },
                            },
                        },
                        {
                            name = "spell_slots",
                            type = ui.TYPE.Flex,
                            props = {
                                --size = util.vector2(screenWidth * 0.12, screenWidth * 0.03),
                                horizontal = false,
                            },
                            content = ui.content{
                                {
                                    name = "spell_slots_child_1",
                                    type = ui.TYPE.Flex,
                                    props = {
                                        size = util.vector2(screenWidth * 0.02625, screenWidth * 0.02625),
                                        horizontal = true,
                                    },
                                    content = spellSlotsContent1,
                                },
                                {
                                    name = "spell_slots_child_2",
                                    type = ui.TYPE.Flex,
                                    props = {
                                        size = util.vector2(screenWidth * 0.02625, screenWidth * 0.02625),
                                        horizontal = true,
                                    },
                                    content = spellSlotsContent2,
                                },
                            },
                        },
						{
                            name = "misc_slots",
                            type = ui.TYPE.Flex,
                            props = {
                                size = util.vector2(screenWidth * 0.0525, screenWidth * 0.0525),
                                horizontal = false,
								
                            },
                            content = ui.content{
                                {
                                    name = "misc_slots_child_1",
                                    type = ui.TYPE.Flex,
                                    props = {
                                        size = util.vector2(screenWidth * 0.02625, screenWidth * 0.02625),
                                        horizontal = true,
                                    },
                                    content = miscContent1,
                                },
                                {
                                    name = "misc_slots_child_2",
                                    type = ui.TYPE.Flex,
                                    props = {
                                        size = util.vector2(screenWidth * 0.02625, screenWidth * 0.02625),
                                        horizontal = true,
                                    },
                                    content = miscContent2,
                                },
                            },
                        },
                    },
                },
                {
                    name = "intervention_button",
                    type = ui.TYPE.Image,
                    props = {
                        size = util.vector2(screenWidth * 0.073, screenWidth * 0.073),
                        resource = ui.texture({ path = 'Textures/divine.png' }),
                    },
                },
				
				{
                    name = "rest_button_container",
                    type = ui.TYPE.Flex,
                    props = {
                        size = util.vector2(screenWidth * 0.04025, screenWidth * 0.06125),
						align = ui.ALIGNMENT.End,
                        
                    },
					content = ui.content {
						{
							name = "rest_button",
							type = ui.TYPE.Image,
							props = {
								size = util.vector2(screenWidth * 0.04025, screenWidth * 0.04025),
								resource = ui.texture({ path = 'Textures/rest.png' }),
							},
						},
					},
                },

            },
        },
    },
}

-- Pre-cache widget references with their relative positions
local targetWidgets = {
	melee_weapon = {
		widget = actionBar.layout.content[2].content[3].content[2],
		relX = barX + screenWidth * 0.089 + actionBar.layout.content[2].content[3].props.size.x,  -- Adjust these offsets based on layout
		relY = barY + screenHeight * 0.104
	},
	ranged_weapon = {
		widget = actionBar.layout.content[2].content[4].content[2],
		relX = barX + screenWidth * 0.118 + actionBar.layout.content[2].content[3].props.size.x,
		relY = barY + screenHeight * 0.104
	},
	intervention_button = {
		widget = actionBar.layout.content[2].content[6],
		relX = barX + screenWidth * 0.593 + actionBar.layout.content[2].content[6].props.size.x,
		relY = barY + screenHeight * 0.104
	},
	rest_button = {
		widget = actionBar.layout.content[2].content[7].content[1],
		relX = barX + screenWidth * 0.635 + actionBar.layout.content[2].content[6].props.size.x,
		relY = barY + screenHeight * 0.142
	},
	class_button = {
		widget = actionBar.layout.content[2].content[1].content[1],
		relX = barX,
		relY = barY + screenHeight * 0.142
	}
}

local contentTables = {
	actionSlotsContent1 = {
		content = actionBar.layout.content[2].content[5].content[1].content[2].content,
		relX = barX + screenWidth * 0.14 + actionBar.layout.content[2].content[3].props.size.x,
		relY = barY + screenHeight * 0.104
	},
	actionSlotsContent2 = {
		content = actionBar.layout.content[2].content[5].content[1].content[2].content,
		relX = barX + screenWidth * 0.14 + actionBar.layout.content[2].content[3].props.size.x,
		relY = barY + screenHeight * 0.151
	},
	spellSlotsContent1 = {
		content = actionBar.layout.content[2].content[5].content[2].content[1].content,
		relX = barX + screenWidth * 0.35 + actionBar.layout.content[2].content[3].props.size.x,
		relY = barY + screenHeight * 0.104
	},
	spellSlotsContent2 = {
		content = actionBar.layout.content[2].content[5].content[2].content[2].content,
		relX = barX + screenWidth * 0.35 + actionBar.layout.content[2].content[3].props.size.x,
		relY = barY + screenHeight * 0.151
	},
	miscContent1 = {
		content = actionBar.layout.content[2].content[5].content[3].content[1].content,
		relX = barX + screenWidth * 0.56 + actionBar.layout.content[2].content[3].props.size.x,
		relY = barY + screenHeight * 0.104,
	},
	miscContent2 = {
		content = actionBar.layout.content[2].content[5].content[3].content[2].content,
		relX = barX + screenWidth * 0.56 + actionBar.layout.content[2].content[3].props.size.x,
		relY = barY + screenHeight * 0.151
	}
}

local lineHeight = I.MWUI.templates.textNormal.props.textSize
local tooltipOffset = util.vector2(lineHeight, lineHeight)
local currentTooltip
local assignWindow

-- Helper function to capitalize the start of every word
local function capitalizeWords(str)
    return str:gsub("(%a)(%w*)", function(first, rest) 
        return first:upper() .. rest:lower() 
    end)
end

local function formatTooltipText(key, value, itemType, item)
    if key == "armorRatingType" then
        if itemType == "Armor" then
            return string.format("Armor Rating: %s", value)
        elseif itemType == "Weapon" then
            return string.format("Type: %s", getWeaponType(value))
        end
    elseif key == "usesDuration" then
        if itemType == "Light" then
            return string.format("Duration: %s", value)
        else
            return string.format("Uses Remaining: %s", value)
        end
    elseif key == "condition" then
        -- Special case for condition
        local currentCondition = types.Item.itemData(item).condition or 0
        return string.format("Condition: %d/%s", currentCondition, value) 
    elseif key == "chop" then
        -- For weapons, check if it's a ranged weapon
        if itemType == "Weapon" then
            local record = types.Weapon.record(item)
            local weaponTypeIndex = record.type
            if weaponTypeIndex >= 9 then -- Ranged weapon
                return string.format("Attack: %s", value)
            else
                return string.format("Chop: %s", value)
            end
        end
    elseif key == "range" then
        return string.format("Range: %d ft", value * 6) -- Convert game units to feet
    elseif key == "speed" then
        return string.format("Speed: %d%%", value * 100)
    elseif key == "enchantmentType" then
        -- Format enchantment type
        if value == core.magic.ENCHANTMENT_TYPE.CastOnStrike then
            return "Cast When Strikes"
        elseif value == core.magic.ENCHANTMENT_TYPE.CastOnUse then
            return "Cast When Used"
        elseif value == core.magic.ENCHANTMENT_TYPE.ConstantEffect then
            return "Constant Effect"
        elseif value == core.magic.ENCHANTMENT_TYPE.CastOnce then
            return "Cast Once"
        end
    elseif key == "enchantmentEffects" then
        -- This is handled separately, not in this function
        return nil
    else
        -- Default case
        return string.format("%s: %s", capitalizeWords(key), value)
    end
end


local function formatDuration(seconds)
    if seconds then
        local minutes = math.floor(seconds / 60) -- Get whole minutes
        local remainingSeconds = seconds % 60   -- Get remaining seconds

        if remainingSeconds == 0 then
            return string.format("%d min", minutes) -- Only display minutes
        elseif minutes > 0 then
            return string.format("%d min %d s", minutes, remainingSeconds) -- Display both minutes and seconds
        else
            return string.format("%d s", remainingSeconds) -- Only display seconds
        end
    end
    return "Unknown"
end

-- Determine armorStyle
local function determineArmorStyle(weight, type)
	local styles = {
		light = {
			Boots = 12.0, Cuirass = 18.0, Greaves = 9.0, Shield = 9.0,
			Bracer = 3.0, Gauntlet = 3.0, Helmet = 3.0, Pauldron = 6.0
		},
		medium = {
			Boots = 18.0, Cuirass = 27.0, Greaves = 13.5, Shield = 13.5,
			Bracer = 4.5, Gauntlet = 4.5, Helmet = 4.5, Pauldron = 9.0
		}
	}

	local slotNames = {
		[0] = "Helmet", [1] = "Cuirass", [2] = "Pauldron",
		[3] = "Pauldron", [4] = "Greaves", [5] = "Boots",
		[6] = "Gauntlet", [7] = "Gauntlet", [8] = "Shield"
	}

	local slotName = slotNames[type]
	if not slotName then return "Unknown" end

	if weight <= styles.light[slotName] then
		return "Light"
	elseif weight <= styles.medium[slotName] then
		return "Medium"
	else
		return "Heavy"
	end
end

-- Global function so it can be accessed from formatTooltipText()
function getWeaponType(index)
    local weaponTypes = {
        [0] = "Short Blade, One Handed",
        [1] = "Long Blade, One Handed",
        [2] = "Long Blade, Two Handed",
        [3] = "Blunt Weapon, One Handed",
        [4] = "Blunt Weapon, Two Handed",
        [5] = "Blunt Weapon, Two Handed",
        [6] = "Spear, Two Handed",
        [7] = "Axe, One Handed",
        [8] = "Axe, Two Handed",
        [9] = "Marksman", -- Bows
        [10] = "Marksman", -- Crossbows
        [11] = "Marksman", -- Throwing Weapons
        [12] = "Marksman", -- Arrows
        [13] = "Marksman" -- Bolts
    }

    return weaponTypes[index] or "Unknown Weapon Type"
end

function getItemType(item)
    local typeCheckers = {
		Apparatus = types.Apparatus.objectIsInstance,
        Weapon = types.Weapon.objectIsInstance,
        Armor = types.Armor.objectIsInstance,
        Clothing = types.Clothing.objectIsInstance,
		Ingredient = types.Ingredient.objectIsInstance,
		Lockpick = types.Lockpick.objectIsInstance,
		Probe = types.Probe.objectIsInstance,
		Repair = types.Repair.objectIsInstance,
        Book = types.Book.objectIsInstance,
		Light = types.Light.objectIsInstance,
        Potion = types.Potion.objectIsInstance,
        Miscellaneous = types.Miscellaneous.objectIsInstance,
    }

    for typeName, checker in pairs(typeCheckers) do
        if checker(item) then
            return typeName
        end
    end
    return nil -- Return nil if no matching type is found
end

function getItemIcon(item)
    local itemType = getItemType(item)
    if itemType and types[itemType] then
        return types[itemType].record(item).icon
    end
    return nil -- Fallback if the type or icon cannot be determined
end

function getItemName(item)
    local itemType = getItemType(item)
    if itemType and types[itemType] then
        return types[itemType].record(item).name
    end
    return nil -- Fallback if the type or id cannot be determined
end

-- Helper function to format weight values
local function formatWeight(weight)
    -- Check if the weight is a whole number
    if weight == math.floor(weight) then
        return tostring(math.floor(weight)) -- Return as integer
    else
        return string.format("%.1f", weight) -- Return with 1 decimal place
    end
end

function getItemDetails(item)
    local itemType = getItemType(item)
    local details = {}
    
    if itemType == "Weapon" then
        local record = types.Weapon.record(item)
        local itemData = types.Item.itemData(item)
        
        -- Determine weapon type
        local weaponTypeIndex = record.type
        local isRangedWeapon = weaponTypeIndex >= 9 -- Index 9-13 are ranged weapons
        local isThrowingWeapon = weaponTypeIndex == 11
        local isAmmo = weaponTypeIndex == 12 or weaponTypeIndex == 13 -- Arrows or Bolts
        
        -- common details for all weapons
        details = {
            armorRatingType = record.type,
            weight = formatWeight(record.weight), -- Format weight properly
            value = record.value
        }
        
        -- Add specific details based on weapon type
        if isRangedWeapon then
            -- For all ranged weapons, "chop" becomes "attack"
            details.chop = string.format("%d-%d", record.chopMinDamage, record.chopMaxDamage)
            
            -- Only add condition for bows and crossbows (not for throwing weapons, arrows, bolts)
            if not (isThrowingWeapon or isAmmo) then
                details.condition = record.health
            end
            
            -- Only add speed for weapons that aren't arrows or bolts
            if not isAmmo then
                details.speed = record.speed
            end
        else
            -- For melee weapons, add all standard details
            details.chop = string.format("%d-%d", record.chopMinDamage, record.chopMaxDamage)
            details.slash = string.format("%d-%d", record.slashMinDamage, record.slashMaxDamage)
            details.thrust = string.format("%d-%d", record.thrustMinDamage, record.thrustMaxDamage)
            details.condition = record.health
            details.range = record.reach
            details.speed = record.speed
        end
        
        -- Add enchantment information if the item is enchanted
        if itemData and itemData.enchantmentCharge ~= nil then
            local record = types.Weapon.record(item)
            if record and record.enchant then
                local enchantment = core.magic.enchantments.records[record.enchant]
                if enchantment then
                    details.enchantmentType = enchantment.type
                    details.enchantmentEffects = enchantment.effects
                end
            end
        end
        
    elseif itemType == "Armor" then
        local record = types.Armor.record(item)
        local armorStyle = determineArmorStyle(record.weight, record.type)
        local armorSkill = string.lower(armorStyle .. "armor")
        local itemData = types.Item.itemData(item)
        
        details = {
            armorRatingType = math.floor(record.baseArmor * (types.NPC.stats.skills[armorSkill](self.object).base / 30)),
            condition = record.health,
            weight = string.format("%s (%s)", formatWeight(record.weight), armorStyle), -- Format weight properly
            value = record.value
        }
        
        -- Add enchantment information if the item is enchanted
        if itemData and itemData.enchantmentCharge ~= nil then
            local record = types.Armor.record(item)
            if record and record.enchant then
                local enchantment = core.magic.enchantments.records[record.enchant]
                if enchantment then
                    details.enchantmentType = enchantment.type
                    details.enchantmentEffects = enchantment.effects
                end
            end
        end
        
    elseif itemType == "Clothing" or itemType == "Book" or itemType == "Potion" or itemType == "Ingredient" or itemType == "Miscellaneous" then
        local record = types[itemType].record(item)
        local itemData = types.Item.itemData(item)
        details = {
            weight = formatWeight(record.weight), -- Format weight properly
            value = record.value
        }
        
        -- Add enchantment information for clothing and books if they are enchanted
        if (itemType == "Clothing" or itemType == "Book") and itemData and itemData.enchantmentCharge ~= nil then
            local record = types[itemType].record(item)
            if record and record.enchant then
                local enchantment = core.magic.enchantments.records[record.enchant]
                if enchantment then
                    details.enchantmentType = enchantment.type
                    details.enchantmentEffects = enchantment.effects
                end
            end
        end
        
        -- Add potion effects
        if itemType == "Potion" then
            local record = types.Potion.record(item)
            if record and record.effects then
                details.enchantmentEffects = record.effects
            end
        end
        
    elseif itemType == "Lockpick" or itemType == "Probe" or itemType == "Repair" then
        local record = types[itemType].record(item)
        details = {
            uses = record.maxCondition,
            quality = string.format("%.1f", record.quality),
            weight = formatWeight(record.weight), -- Format weight properly
            value = record.value
        }
    
    elseif itemType == "Light" then
        local record = types[itemType].record(item)
        details = {
            duration = formatDuration(types[itemType].baseType.itemData(item).condition),
            quality = record.quality,
            weight = formatWeight(record.weight), -- Format weight properly
            value = record.value
        }
        
    else
        details = { description = "Details not available for this item type" }
    end
    
    return details
end

local function createItemSelectionTooltip()
    local title = {
        template = I.MWUI.templates.textHeader,
        name = 'name', --- name, quantity, soulName, spell/power
        props = {
            text = nil,
            textAlignH = ui.ALIGNMENT.Center,
        }
    }

    local descriptionWidget = {
        type = ui.TYPE.Flex,
        name = 'description',
        props = {
            arrange = ui.ALIGNMENT.Center,
        },
		content = ui.content({})

    }
	local tooltipPadding = {
		template = I.MWUI.templates.padding
	}
	local tooltipContent = {
		name = "tooltip_flex",
		type = ui.TYPE.Flex,
		props = {
			arrange = ui.ALIGNMENT.Center,
			align = ui.ALIGNMENT.Center,
		},
		content = ui.content({
			tooltipPadding,
			tooltipPadding,
			title,
			descriptionWidget,
			tooltipPadding,
			tooltipPadding,
		}),
	}
	local outerTooltip = {
		name = "outer_tooltip_flex",
		type = ui.TYPE.Flex,
		props = {
			arrange = ui.ALIGNMENT.Center,
			align = ui.ALIGNMENT.Center,
			horizontal = true,
		},
			content = ui.content({
			tooltipPadding,
			tooltipPadding,
			tooltipContent,
			tooltipPadding,
			tooltipPadding,
		}),
	}
	-- Define key ordering for each type of item
	local keyOrder = {
		Weapon = { "armorRatingType", "chop", "slash", "thrust", "condition", "range", "speed", "weight", "value", "enchantmentType", "enchantmentEffects" },
		RangedWeapon = { "armorRatingType", "chop", "condition", "speed", "weight", "value", "enchantmentType", "enchantmentEffects" },
		ThrowingWeapon = { "armorRatingType", "chop", "speed", "weight", "value", "enchantmentType", "enchantmentEffects" },
		Ammo = { "armorRatingType", "chop", "weight", "value", "enchantmentType", "enchantmentEffects" },
		Clothing = { "weight", "value", "enchantmentType", "enchantmentEffects" },
		Ingredient = { "weight", "value" },
		Armor = { "armorRatingType", "condition", "weight", "value", "enchantmentType", "enchantmentEffects" },
		Light = { "duration", "quality", "weight", "value" },
		Repair = { "uses", "weight", "value" },
		Lockpick = { "uses", "quality", "weight", "value" },
		Probe = { "uses", "quality", "weight", "value" },
		Potion = { "weight", "value", "enchantmentEffects" },
		Book = { "weight", "value", "enchantmentType", "enchantmentEffects" },
		Miscellaneous = { "weight", "value" },
		spell = { "effects", "cost", "chance" },
        power = { "effects" }, -- Powers only have effects
	}

    currentTooltip = ui.create({
		name = "tooltip",
        template = I.MWUI.templates.boxTransparent,
        layer = 'Popup',
        props = {
            visible = false,
            arrange = ui.ALIGNMENT.Center, -- Center align the tooltip box
			align = ui.ALIGNMENT.Center, -- Center align contents within Flex
        },
        content = ui.content({
            {
                type = ui.TYPE.Flex,
                props = {
                    arrange = ui.ALIGNMENT.Center, -- Center align contents within Flex
					align = ui.ALIGNMENT.Center, -- Center align contents within Flex
                },
                content = ui.content({outerTooltip})
            },
        }),
    })
	
    return {
        destroy = function()
			if currentTooltip then
                currentTooltip:destroy()
            end
        end,
		show = function(itemData, pos)
		-- Set the title
		title.props.text = itemData.name

		-- Recreate the descriptionWidget with a fresh content array
		descriptionWidget.content = ui.content({})

		if itemData.type == "spell" or itemData.type == "power" then
			-- Handle spell or power-specific content
			local effects = itemData.item.effects

			-- Player's magic skills
			local userMagicSkills = {
				alteration = types.NPC.stats.skills.alteration(self.object).modified,
				conjuration = types.NPC.stats.skills.conjuration(self.object).modified,
				destruction = types.NPC.stats.skills.destruction(self.object).modified,
				illusion = types.NPC.stats.skills.illusion(self.object).modified,
				mysticism = types.NPC.stats.skills.mysticism(self.object).modified,
				restoration = types.NPC.stats.skills.restoration(self.object).modified,
			}

			if itemData.type == "spell" and #effects > 0 then
				-- Determine if the spell is custom
				local isCustomSpell = false
				for i, record in ipairs(core.magic.spells.records) do
					if record.name == itemData.name then
						isCustomSpell = i > 1065
						break
					end
				end

				if isCustomSpell then
					-- For custom spells, use the lowest magic skill logic
					local normalizedSkills = {}
					for school, skill in pairs(userMagicSkills) do
						normalizedSkills[string.lower(school)] = skill
					end

					-- Sort effects based on the lowest magic skill level
					table.sort(effects, function(a, b)
						local skillA = normalizedSkills[string.lower(a.effect.school)] or math.huge
						local skillB = normalizedSkills[string.lower(b.effect.school)] or math.huge

						-- Primary sorting: Compare magic skill levels (ascending)
						if skillA ~= skillB then
							return skillA < skillB
						end

						-- Secondary sorting: Alphabetical order by school name
						return a.effect.school < b.effect.school
					end)

					-- Determine the school based on the first effect in the sorted list
					local schoolName = capitalizeWords(effects[1].effect.school)

					-- Add the school information to the tooltip
					table.insert(descriptionWidget.content, {
						template = I.MWUI.templates.textNormal,
						props = {
							text = string.format("School: %s", schoolName),
							textAlignH = ui.ALIGNMENT.Start,
						}
					})
				else
					-- For non-custom spells, use the first effect's school
					local schoolName = capitalizeWords(effects[1].effect.school)

					-- Add the school information to the tooltip
					table.insert(descriptionWidget.content, {
						template = I.MWUI.templates.textNormal,
						props = {
							text = string.format("School: %s", schoolName),
							textAlignH = ui.ALIGNMENT.Start,
						}
					})
				end
			end





			-- Loop through all effects
			for _, effect in ipairs(effects) do
				local effectRecord = effect.effect
				if effectRecord then
					-- Retrieve effect properties
					local icon = effectRecord.icon
					local effectName = effectRecord.name

					-- Determine magnitude, duration, and area
					local magnitude = effectRecord.hasMagnitude and effect.magnitudeMax > 0
						and (effect.magnitudeMin == effect.magnitudeMax
							and string.format("%d pts", effect.magnitudeMax)
							or string.format("%d to %d pts", effect.magnitudeMin, effect.magnitudeMax))
						or nil
					local duration = effectRecord.hasDuration and effect.duration > 0
						and (effect.duration <= 60
							and string.format("%d sec%s", effect.duration, effect.duration == 1 and "" or "s")
							or string.format("%.1f mins", effect.duration / 60))
						or nil
					local area = effect.area > 0 and string.format("in %d ft", effect.area) or nil
					local range = effect.range == core.magic.RANGE.Self and "Self"
								or effect.range == core.magic.RANGE.Touch and "Touch"
								or core.magic.RANGE.Target and "Target"

					-- Build the effect description
					local effectParts = {}
					table.insert(effectParts, string.format(" %s", effectName))
					if magnitude then table.insert(effectParts, magnitude) end
					if duration then table.insert(effectParts, string.format("for %s", duration)) end
					if area then table.insert(effectParts, area) end
					table.insert(effectParts, string.format("on %s", range))

					local effectText = table.concat(effectParts, " ")

					table.insert(descriptionWidget.content, {
						type = ui.TYPE.Flex,
						props = {
							horizontal = true
						},
						content = ui.content{
							{ 
								type = ui.TYPE.Image,
								props = {
									resource = ui.texture({ path = icon }),
									size = util.vector2(16, 16)
								}
							}, 
							{
								template = I.MWUI.templates.textNormal,
								props = {
									text = effectText,
									textAlignH = ui.ALIGNMENT.Start,
								}
							}
						}
					})

				end
			end
		else
			-- Populate the description dynamically for regular items
			local currentKeyOrder = keyOrder[itemData.type]
			
			-- Special handling for weapon types
			if itemData.type == "Weapon" and itemData.item then
				local record = types.Weapon.record(itemData.item)
				local weaponTypeIndex = record.type
				
				if weaponTypeIndex >= 9 then -- Ranged weapon
					if weaponTypeIndex == 11 then -- Throwing weapon
						currentKeyOrder = keyOrder.ThrowingWeapon
					elseif weaponTypeIndex == 12 or weaponTypeIndex == 13 then -- Arrows or Bolts
						currentKeyOrder = keyOrder.Ammo
					else -- Bows and Crossbows
						currentKeyOrder = keyOrder.RangedWeapon
					end
				end
			end
			
			for _, key in ipairs(currentKeyOrder) do
				local value = itemData.description[key]
				if value then
					if key == "enchantmentEffects" then
						if #value > 0 then
							-- Loop through all effects
							for _, effect in ipairs(value) do
								local effectRecord = effect.effect
								if effectRecord then						
									-- Retrieve effect properties
									local icon = effectRecord.icon
									local effectName = effectRecord.name
                                    
									-- Special handling for attribute effects
									if effectRecord.id == "fortifyattribute" and effect.affectedAttribute then
										-- Capitalize the first letter of the attribute name
										local attributeName = effect.affectedAttribute
										attributeName = string.upper(string.sub(attributeName, 1, 1)) .. string.sub(attributeName, 2)
										effectName = "Fortify " .. attributeName
									elseif effectRecord.id == "drainattribute" and effect.affectedAttribute then
										-- Capitalize the first letter of the attribute name
										local attributeName = effect.affectedAttribute
										attributeName = string.upper(string.sub(attributeName, 1, 1)) .. string.sub(attributeName, 2)
										effectName = "Drain " .. attributeName
									elseif effectRecord.id == "damageattribute" and effect.affectedAttribute then
										-- Capitalize the first letter of the attribute name
										local attributeName = effect.affectedAttribute
										attributeName = string.upper(string.sub(attributeName, 1, 1)) .. string.sub(attributeName, 2)
										effectName = "Damage " .. attributeName
									elseif effectRecord.id == "absorbattribute" and effect.affectedAttribute then
										-- Capitalize the first letter of the attribute name
										local attributeName = effect.affectedAttribute
										attributeName = string.upper(string.sub(attributeName, 1, 1)) .. string.sub(attributeName, 2)
										effectName = "Absorb " .. attributeName
									elseif effectRecord.id == "restoreattribute" and effect.affectedAttribute then
										-- Capitalize the first letter of the attribute name
										local attributeName = effect.affectedAttribute
										attributeName = string.upper(string.sub(attributeName, 1, 1)) .. string.sub(attributeName, 2)
										effectName = "Restore " .. attributeName
									elseif effectRecord.id == "fortifyskill" and effect.affectedSkill then
										-- Capitalize the first letter of the skill name
										local skillName = effect.affectedSkill
										skillName = string.upper(string.sub(skillName, 1, 1)) .. string.sub(skillName, 2)
										effectName = "Fortify " .. skillName
									elseif effectRecord.id == "drainskill" and effect.affectedSkill then
										-- Capitalize the first letter of the skill name
										local skillName = effect.affectedSkill
										skillName = string.upper(string.sub(skillName, 1, 1)) .. string.sub(skillName, 2)
										effectName = "Drain " .. skillName
									elseif effectRecord.id == "damageskill" and effect.affectedSkill then
										-- Capitalize the first letter of the skill name
										local skillName = effect.affectedSkill
										skillName = string.upper(string.sub(skillName, 1, 1)) .. string.sub(skillName, 2)
										effectName = "Damage " .. skillName
									elseif effectRecord.id == "absorbskill" and effect.affectedSkill then
										-- Capitalize the first letter of the skill name
										local skillName = effect.affectedSkill
										skillName = string.upper(string.sub(skillName, 1, 1)) .. string.sub(skillName, 2)
										effectName = "Absorb " .. skillName
									elseif effectRecord.id == "restoreskill" and effect.affectedSkill then
										-- Capitalize the first letter of the skill name
										local skillName = effect.affectedSkill
										skillName = string.upper(string.sub(skillName, 1, 1)) .. string.sub(skillName, 2)
										effectName = "Restore " .. skillName
									end

									-- Determine magnitude, duration, and area
									local magnitude = effectRecord.hasMagnitude and effect.magnitudeMax > 0
									local duration = effectRecord.hasDuration and effect.duration > 0
									local area = effectRecord.hasArea and effect.area > 0
									local range = effect.range == core.magic.RANGE.Self and "Self"
												or effect.range == core.magic.RANGE.Touch and "Touch"
												or core.magic.RANGE.Target and "Target"
									
									-- Function to check if an effect should be displayed as a percentage
									local function isPercentageEffect(effectId)
										local percentageEffects = {
											["weaknesstofire"] = true,
											["weaknesstofrost"] = true,
											["weaknesstoshock"] = true,
											["weaknesstomagicka"] = true,
											["weaknesstonormalweapons"] = true,
											["weaknesstoblightdisease"] = true,
											["weaknesstocommondisease"] = true,
											["weaknesstocorprusdisease"] = true,
											["weaknesstopoison"] = true,
											["blind"] = true,
											["chameleon"] = true,
											["dispel"] = true,
											["reflect"] = true,
											["resistfire"] = true,
											["resistfrost"] = true,
											["resistshock"] = true,
											["resistmagicka"] = true,
											["resistnormalweapons"] = true,
											["resistblightdisease"] = true,
											["resistcommondisease"] = true,
											["resistcorprusdisease"] = true,
											["resistparalysis"] = true,
											["resistpoison"] = true
										}
										return percentageEffects[effectId] or false
									end
									
									-- Build the effect description
									local effectParts = {}
									table.insert(effectParts, string.format(" %s", effectName))
									

									local isConstantEffect = false
									
									if itemData.description.enchantmentType == 3 then
										isConstantEffect = true
									else
										isConstantEffect = false
									end
									-- Format magnitude based on effect type
									if magnitude then
										if isPercentageEffect(effectRecord.id) then
											if effect.magnitudeMin == effect.magnitudeMax then
												table.insert(effectParts, string.format("%d%%", effect.magnitudeMax))
											else
												table.insert(effectParts, string.format("%d to %d%%", effect.magnitudeMin, effect.magnitudeMax))
											end
										else
											if effect.magnitudeMin == effect.magnitudeMax then
												table.insert(effectParts, string.format("%d pts", effect.magnitudeMax))
											else
												table.insert(effectParts, string.format("%d to %d pts", effect.magnitudeMin, effect.magnitudeMax))
											end
										end
									end
									
									-- For constant effects do nothing
									if isConstantEffect == false then
										-- Add duration for non-constant effects
										if duration then
											if effect.duration <= 60 then
												table.insert(effectParts, string.format("for %d sec%s", effect.duration, effect.duration == 1 and "" or "s"))
											else
												table.insert(effectParts, string.format("for %.1f mins", effect.duration / 60))
											end
										end
										
										-- Add area if applicable
										if area then
											table.insert(effectParts, string.format("in %d ft", effect.area))
										end
										
										-- Add range for non-constant effects
										table.insert(effectParts, string.format("on %s", range))
									end
									
									local effectText = table.concat(effectParts, " ")
									
									-- Add the effect to the tooltip with its icon
									table.insert(descriptionWidget.content, {
										type = ui.TYPE.Flex,
										props = {
											horizontal = true,
											align = ui.ALIGNMENT.Start
										},
										content = ui.content{
											{ 
												type = ui.TYPE.Image,
												props = {
													resource = ui.texture({ path = icon }),
													size = util.vector2(16, 16)
												}
											}, 
											{
												template = I.MWUI.templates.textNormal,
												props = {
													text = effectText,
													textAlignH = ui.ALIGNMENT.Start,
												}
											}
										}
									})
								end
							end
						end
					else
						local childWidget = {
							template = I.MWUI.templates.textNormal,
							props = {
								text = nil,
								textAlignH = ui.ALIGNMENT.Start,
								visible = true,
							}
						}

						-- Use helper function for formatting
						childWidget.props.text = formatTooltipText(key, value, itemData.type, itemData.item)
						
						-- Only add if there's text to display
						if childWidget.props.text then
							-- Add to description widget
							descriptionWidget.content:add(childWidget)
						end
					end
				end
			end
		end

		-- Position and display the tooltip
		currentTooltip.layout.props.position = pos + tooltipOffset
		currentTooltip.layout.props.visible = true
		currentTooltip:update()
	end,

	
	
        hide = function()
            currentTooltip.layout.props.visible = false
            currentTooltip:update()
        end,
		

		
    }
end



-- Function to format large numbers in a compact way
local function formatStackCount(count)
    if count < 1000 then
        -- Display numbers under 1000 normally
        return tostring(count)
    elseif count < 100000 then
        -- Display numbers between 1000 and 99999 as "Xk"
        return string.format("%dk", math.floor(count / 1000))
    elseif count < 1000000 then
        -- Display numbers between 100000 and 999999 as ".XM"
        return string.format(".%dM", math.floor(count / 100000))
    else
        -- Display numbers 1000000 and above as "XM"
        return string.format("%dM", math.floor(count / 1000000))
    end
end

local function createItemSelectionWindow(slotName, slotIndex, assignCallback)
    local playerInventory = types.Actor.inventory(self.object)
    local tooltip = createItemSelectionTooltip()
    
    -- Collect items based on slot type
    local function collectItemsForSlot()
        local items = {}
        local uniqueItemIds = {} -- Track unique item IDs
        
        -- Logic to collect appropriate items based on slot name
        if slotName == "melee_weapon" then
            -- assigning items to melee_weapon slot
            return {}
        elseif slotName == "ranged_weapon" then
            -- assigning items to ranged_weapon slot
            return {}
        elseif slotName:match("potion") then
            --items = playerInventory:getAll(types.Potion)
        elseif slotName:match("miscContent") then
            local allMisc = playerInventory:getAll(types.Miscellaneous)
            for _, misc in ipairs(allMisc) do
                local itemId = types.Miscellaneous.record(misc).id
                if not uniqueItemIds[itemId] then
                    table.insert(items, misc)
                    uniqueItemIds[itemId] = true
                end
            end
        else
            -- Default to all items, but deduplicate by ID
            local allItems = playerInventory:getAll()
            for _, item in ipairs(allItems) do
                local itemType = getItemType(item)
                if itemType then
                    local itemId = types[itemType].record(item).id
                    if not uniqueItemIds[itemId] then
                        table.insert(items, item)
                        uniqueItemIds[itemId] = true
                    end
                end
            end
        end
        return items
    end
    
    local items = collectItemsForSlot()
    
    -- Check if inventory is empty for this slot type
    if #items == 0 then
        -- Create a window with a message about empty inventory
        return ui.create({
            template = I.MWUI.templates.boxTransparentThick,
            layer = 'Windows',
            props = {
                anchor = util.vector2(0.5, 0.5),
                relativePosition = util.vector2(0.5, 0.5),
                padding = util.vector2(16, 16)
            },
            content = ui.content({
                {
                    type = ui.TYPE.Flex,
                    props = {
                        vertical = true,
                        arrange = ui.ALIGNMENT.Center,
                        align = ui.ALIGNMENT.Center,
                    },
                    content = ui.content({
                        {
                            template = I.MWUI.templates.textHeader,
                            props = {
                                text = "No items available",
                                textAlignH = ui.ALIGNMENT.Center,
                                padding = util.vector2(0, 8)
                            }
                        },
                        {
                            template = I.MWUI.templates.textNormal,
                            props = {
                                text = "You don't have any suitable items for this slot.",
                                textAlignH = ui.ALIGNMENT.Center,
                                padding = util.vector2(0, 8)
                            }
                        }
                    })
                }
            })
        })
    end
    
    -- Create grid of items
    local gridContent = {}
    local itemsPerRow = 8 -- Adjust this number to control grid width
    local currentRow = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            padding = util.vector2(2, 2),
            align = ui.ALIGNMENT.Center
        },
        content = ui.content({})
    }
    
    for i, item in ipairs(items) do
        local itemIcon = getItemIcon(item)
        local itemType = getItemType(item)
        local itemId = types[itemType].record(item).id
        local count = playerInventory:countOf(itemId)
        
        local gridItem = {
            type = ui.TYPE.Flex,
            props = {
                padding = util.vector2(2, 2)
            },
            content = ui.content({
                {
                    type = ui.TYPE.Widget,
                    props = {
                        size = util.vector2(screenWidth * 0.02625, screenWidth * 0.02625),
                        relativePosition = util.vector2(0.5, 0.5),
                        anchor = util.vector2(0.5, 0.5),
                    },
                    content = ui.content({
                        -- Magic indicator as the background
                        {
                            name = "magicIndicator",
                            type = ui.TYPE.Image,
                            props = {
                                relativeSize = util.vector2(1.0, 1.0), -- Changed from 1.5 to 1.0 to prevent cutoff
                                relativePosition = util.vector2(0.5, 0.5), -- Center position
                                anchor = util.vector2(0.5, 0.5), -- Center anchor
                                resource = ui.texture({ path = "textures\\menu_icon_magic_mini.dds" }),
                                visible = false, -- Will be set based on enchantment check
                            },
                        },
                        -- Item icon on top of the magic indicator
                        {
                            name = "itemIcon",
                            type = ui.TYPE.Image,
                            props = {
                                relativeSize = util.vector2(0.85, 0.85),
                                relativePosition = util.vector2(0.5, 0.5),
                                anchor = util.vector2(0.5, 0.5),
                                resource = ui.texture({ path = itemIcon }),
                            },
                        },
                        -- Stack count display
                        count > 1 and {
                            name = "stackCount",
                            type = ui.TYPE.Text,
                            props = {
                                autoSize = false,
                                size = util.vector2(screenWidth * 0.02625, screenWidth * 0.02625),
                                text = formatStackCount(count),
                                textAlignH = ui.ALIGNMENT.End,
                                textAlignV = ui.ALIGNMENT.End,
                                textSize = math.floor(22 * (screenHeight / 1080)),
                                textColor = util.color.rgb(223/255, 201/255, 159/255),
                            }
                        } or nil
                    })
                }
            }),
            events = {
                mouseClick = async:callback(function()
                    assignCallback(slotName, slotIndex, item)
                    I.UI.setMode()
                end),
                mouseMove = async:callback(function(e)
                    tooltip.show({
                        name = getItemName(item),
                        description = getItemDetails(item),
                        type = getItemType(item),
                        item = item,
                    }, e.position)
                    return false
                end)
            }
        }
        
        -- Check if the item is enchanted and update the magic indicator visibility
        local itemData = types.Item.itemData(item)
        local isEnchanted = (itemData and itemData.enchantmentCharge ~= nil)
        local isEquipped = false
        
        -- Check if the item is equipped
        local equipment = types.Actor.getEquipment(self)
        if equipment then
            for _, equippedItem in pairs(equipment) do
                if equippedItem and equippedItem.id == item.id then
                    isEquipped = true
                    break
                end
            end
        end
        
        if isEnchanted then
            -- Show magic indicator for enchanted items
            gridItem.content[1].content[1].props.visible = true
            -- Use standard magic indicator for enchanted items
            gridItem.content[1].content[1].props.resource = ui.texture({ path = "textures\\menu_icon_magic_mini.dds" })
            
            if isEquipped then
                -- Green color for enchanted and equipped items
                gridItem.content[1].content[1].props.color = util.color.rgb(0, 1, 0)
            else
                -- Default color for enchanted but not equipped items
                gridItem.content[1].content[1].props.color = util.color.rgb(1, 1, 1)
            end
        else
            -- For non-enchanted items
            if isEquipped then
                -- Make indicator visible with slot.png for equipped non-enchanted items
                gridItem.content[1].content[1].props.visible = true
                -- Use slot.png for non-enchanted equipped items
                gridItem.content[1].content[1].props.resource = ui.texture({ path = "Textures/slot.png" })
                -- Ensure proper positioning and sizing to prevent cutoff
                gridItem.content[1].content[1].props.relativeSize = util.vector2(1.0, 1.0)
                gridItem.content[1].content[1].props.relativePosition = util.vector2(0.5, 0.5)
                gridItem.content[1].content[1].props.anchor = util.vector2(0.5, 0.5)
                -- Green color for equipped items - same as enchanted equipped items
                gridItem.content[1].content[1].props.color = util.color.rgb(0.4, 1, 0.4)
            else
                -- Show slot.png with default color for non-enchanted, non-equipped items
                gridItem.content[1].content[1].props.visible = true
                -- Use slot.png for non-enchanted non-equipped items
                gridItem.content[1].content[1].props.resource = ui.texture({ path = "Textures/slot.png" })
                -- Ensure proper positioning and sizing to prevent cutoff
                gridItem.content[1].content[1].props.relativeSize = util.vector2(1.0, 1.0)
                gridItem.content[1].content[1].props.relativePosition = util.vector2(0.5, 0.5)
                gridItem.content[1].content[1].props.anchor = util.vector2(0.5, 0.5)
                -- Default color for non-equipped, non-enchanted items
                gridItem.content[1].content[1].props.color = util.color.rgb(1, 1, 1)
            end
        end
        
        table.insert(currentRow.content, gridItem)
        
        -- Start a new row when reaching itemsPerRow
        if i % itemsPerRow == 0 then
            table.insert(gridContent, currentRow)
            currentRow = {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                    padding = util.vector2(2, 2),
                    align = ui.ALIGNMENT.Center
                },
                content = ui.content({})
            }
        end
    end
    
    -- Add the last row if it has any items
    if #currentRow.content > 0 then
        table.insert(gridContent, currentRow)
    end
    
    -- Create header section with instructions
    local headerSection = {
        template = I.MWUI.templates.textHeader,
        props = {
            text = "Select an item",
            textAlignH = ui.ALIGNMENT.Center,
            padding = util.vector2(0, 8)
        }
    }
    
    local instructionSection = {
        template = I.MWUI.templates.textNormal,
        props = {
            text = "Click an item to assign it to the selected slot.",
            textAlignH = ui.ALIGNMENT.Center,
            padding = util.vector2(0, 8)
        }
    }
    
    local divider = {
        template = I.MWUI.templates.horizontalLine,
        props = {
            size = util.vector2(itemsPerRow * 32, 2),
            padding = util.vector2(0, 16)
        }
    }
    
    local window = ui.create({
        template = I.MWUI.templates.boxTransparentThick,
        layer = 'Windows',
        props = {
            anchor = util.vector2(0.5, 0.5),
            relativePosition = util.vector2(0.5, 0.5),
            padding = util.vector2(16, 16)
        },
        events = {
            mouseMove = async:callback(function()
                tooltip.hide()
            end)
        },
        content = ui.content({
            {
                type = ui.TYPE.Flex,
                props = {
                    vertical = true,
                    arrange = ui.ALIGNMENT.Center,
                    align = ui.ALIGNMENT.Center,
                },
                content = ui.content({
                    headerSection,
                    instructionSection,
                    divider,
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            vertical = true,
                            arrange = ui.ALIGNMENT.Center,
                            align = ui.ALIGNMENT.Center,
                            padding = util.vector2(0, 8)
                        },
                        content = ui.content(gridContent)
                    }
                })
            }
        })
    })
    return window
end

-- Similarly, update the spell selection window
local function assignSpellToSlot(slotName, slotIndex)
    -- Retrieve and categorize spells
    local playerSpells = types.Actor.spells(self.object)
    local powers, spells = {}, {}
    
    for _, spell in ipairs(playerSpells) do
        if spell.type == core.magic.SPELL_TYPE.Power then
            table.insert(powers, spell)
        elseif spell.type == core.magic.SPELL_TYPE.Spell then
            table.insert(spells, spell)
        end
    end
    
    -- Check if player has any spells or powers
    if #powers == 0 and #spells == 0 then
        return ui.create({
            template = I.MWUI.templates.boxTransparentThick,
            layer = 'Windows',
            props = {
                anchor = util.vector2(0.5, 0.5),
                relativePosition = util.vector2(0.5, 0.5),
                padding = util.vector2(16, 16)
            },
            content = ui.content({
                {
                    template = I.MWUI.templates.textHeader,
                    props = {
                        text = "No spells available",
                        textAlignH = ui.ALIGNMENT.Center
                    }
                },
                {
                    template = I.MWUI.templates.padding
                },
                {
                    template = I.MWUI.templates.textNormal,
                    props = { 
                        text = "You don't know any spells or powers.",
                        textAlignH = ui.ALIGNMENT.Center
                    }
                }
            })
        })
    end
    
    -- Sort spells alphabetically
    local function sortByName(a, b) return a.name < b.name end
    table.sort(powers, sortByName)
    table.sort(spells, sortByName)

    -- Check if there's already a spell assigned to this slot
    if assignedSpells[slotName] and assignedSpells[slotName][slotIndex] then
        local existingSpell = assignedSpells[slotName][slotIndex]
        
        -- Create a modified spell list item that checks for the same spell
        local function createModifiedSpellListItem(spell, slotName, slotIndex, tooltip)
            return {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                    padding = util.vector2(4, 2),
                },
                content = ui.content({
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = true,
                            align = ui.ALIGNMENT.Start,
                        },
                        content = ui.content({
                            {
                                template = I.MWUI.templates.textNormal,
                                props = { 
                                    text = spell.name,
                                    textAlignH = ui.ALIGNMENT.Start
                                }
                            }
                        })
                    }
                }),
                events = {
                    mouseClick = async:callback(function()
                        -- Check if this is the same spell that's already assigned
                        if existingSpell.id == spell.id then
                            -- Same spell is being assigned, so remove it instead
                            local slotTable = _G[slotName]
                            if slotTable and slotTable[slotIndex] then
                                -- Reset the slot visual with the correct texture path
                                -- Spell slots have a different structure than item slots
                                slotTable[slotIndex].props.resource = ui.texture({ path = 'Textures/slot.png' })
                                slotTable[slotIndex].props.alpha = 1.0  -- Changed from 0.5 to 1.0 to remove transparency
                                
                                -- Remove the spell reference
                                assignedSpells[slotName][slotIndex] = nil
                            end
                        else
                            -- Different spell, proceed with normal assignment
                            local slotTable = _G[slotName]
                            if slotTable and slotTable[slotIndex] then
                                -- Get the icon path and insert "b_" before the filename
                                local iconPath = spell.effects[1].effect.icon
                                local bigIconPath = iconPath:gsub("icons\\s\\", "icons\\s\\b_")
                                
                                -- Store both the icon and the spell reference
                                -- Spell slots have a different structure than item slots
                                slotTable[slotIndex].props.resource = ui.texture({ path = bigIconPath })
                                slotTable[slotIndex].props.alpha = 1  -- Set alpha to 1 when spell is assigned
                                assignedSpells[slotName] = assignedSpells[slotName] or {}
                                assignedSpells[slotName][slotIndex] = spell
                            else
                                print("Error: Invalid slot configuration:", slotName, slotIndex)
                            end
                        end
                        I.UI.setMode()
                    end),
                    mouseMove = async:callback(function(e)
                        tooltip.show({
                            name = spell.name,
                            type = spell.type == core.magic.SPELL_TYPE.Power and 'power' or 'spell',
                            item = spell,
                        }, e.position)
                        return false
                    end)
                }
            }
        end
        
        local tooltip = createItemSelectionTooltip()
        local listContent = {}
        
        -- Only add Powers section if there are powers
        if #powers > 0 then
            table.insert(listContent, { 
                template = I.MWUI.templates.textHeader, 
                props = { 
                    text = "Powers",
                    padding = util.vector2(0, 8)
                } 
            })
            
            -- Add powers with modified behavior
            for _, power in ipairs(powers) do
                table.insert(listContent, createModifiedSpellListItem(power, slotName, slotIndex, tooltip))
            end
        end

        -- Add separator
        if #powers > 0 and #spells > 0 then
            for _, element in ipairs({
                {template = I.MWUI.templates.padding},
                {template = I.MWUI.templates.horizontalLine, props = {size = util.vector2(200, 2)}},
                {template = I.MWUI.templates.padding},
            }) do
                table.insert(listContent, element)
            end
        end

        -- Only add Spells section if there are spells
        if #spells > 0 then
            table.insert(listContent, { 
                template = I.MWUI.templates.textHeader, 
                props = { 
                    text = "Spells",
                    padding = util.vector2(0, 8),
                } 
            })
            
            -- Add spells with modified behavior
            for _, spell in ipairs(spells) do
                table.insert(listContent, createModifiedSpellListItem(spell, slotName, slotIndex, tooltip))
            end
        end
        
        -- Create and return the window
        return ui.create({
            template = I.MWUI.templates.boxTransparentThick,
            layer = 'Windows',
            props = {
                anchor = util.vector2(0.5, 0.5),
                relativePosition = util.vector2(0.5, 0.5),
                padding = util.vector2(16, 16), -- Add padding around the content
            },
            events = {
                mouseMove = async:callback(function()
                    tooltip.hide()
                end)
            },
            content = ui.content({
                {
                    type = ui.TYPE.Flex,
                    props = {
                        arrange = ui.ALIGNMENT.Center,
                    },
                    content = ui.content(listContent)
                }
            })
        })
    end

    -- No existing spell, use standard assignment
    local tooltip = createItemSelectionTooltip()
    local listContent = {}
    
    -- Only add Powers section if there are powers
    if #powers > 0 then
        table.insert(listContent, { 
            template = I.MWUI.templates.textHeader, 
            props = { 
                text = "Powers",
                padding = util.vector2(0, 8)
            } 
        })
        
        -- Add powers
        for _, power in ipairs(powers) do
            table.insert(listContent, createSpellListItem(power, slotName, slotIndex, tooltip))
        end
    end

    -- Add separator
    if #powers > 0 and #spells > 0 then
        for _, element in ipairs({
            {template = I.MWUI.templates.padding},
            {template = I.MWUI.templates.horizontalLine, props = {size = util.vector2(200, 2)}},
            {template = I.MWUI.templates.padding},
        }) do
            table.insert(listContent, element)
        end
    end

    -- Only add Spells section if there are spells
    if #spells > 0 then
        table.insert(listContent, { 
            template = I.MWUI.templates.textHeader, 
            props = { 
                text = "Spells",
                padding = util.vector2(0, 8)
            } 
        })
        
        -- Add spells with modified behavior
        for _, spell in ipairs(spells) do
            table.insert(listContent, createSpellListItem(spell, slotName, slotIndex, tooltip))
        end
    end
    
    -- Create and return the window
    return ui.create({
        template = I.MWUI.templates.boxTransparentThick,
        layer = 'Windows',
        props = {
            anchor = util.vector2(0.5, 0.5),
            relativePosition = util.vector2(0.5, 0.5),
            padding = util.vector2(16, 16), -- Add padding around the content
        },
        events = {
            mouseMove = async:callback(function()
                tooltip.hide()
            end)
        },
        content = ui.content({
            {
                type = ui.TYPE.Flex,
                props = {
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content(listContent)
            }
        })
    })
end

local function hasSpell(actor, spellName)
    -- Get the table of spells known by the actor
    local spells = types.Actor.spells(actor)

    -- Iterate through the spells table
    for _, spell in ipairs(spells) do
        if spell.id == spellName then
            return true -- Spell found
        end
    end

    return false -- Spell not found
end

-- Create a separate element for status effects
local statusEffectsElement
local effectsPerRow = 5
-- Scale effect icon size based on screen resolution (base size is 16px at 1080p)
local effectIconSize = math.floor(28 * (screenHeight / 1080))

local function createStatusEffectsElement()
    statusEffectsElement = ui.create({
        name = "status_effects",
        type = ui.TYPE.Widget,
        layer = 'HUD',
        props = {
            visible = true,
            size = util.vector2(effectIconSize*effectsPerRow, effectIconSize*effectsPerRow),
            position = util.vector2(screenWidth * 0.169, screenHeight * 0.72),
        },
        content = ui.content({
            {
                type = ui.TYPE.Flex,
                props = {
                    arrange = ui.ALIGNMENT.Center,
                    align = ui.ALIGNMENT.Center,
                },
                content = ui.content({})
            }
        })
    })
    return statusEffectsElement
end

local function updateStatusEffects()
    -- Create the element if it doesn't exist
    if not statusEffectsElement then
        createStatusEffectsElement()
    end

    local effectsMap = {} -- Use a map to combine identical effects

    -- Get the active effects directly
    local activeSpells = types.Actor.activeSpells(self)
    for _, spell in pairs(activeSpells) do
        for _, effect in ipairs(spell.effects) do
            local effectId = effect.id
            local effectRecord = core.magic.effects.records[effectId]
            if effectRecord then
                if not effectsMap[effectId] then
                    effectsMap[effectId] = {
                        id = effectId,
                        record = effectRecord,
                        magnitude = effect.magnitude or 0
                    }
                else
                    local currentMagnitude = effectsMap[effectId].magnitude or 0
                    local newMagnitude = effect.magnitude or 0
                    effectsMap[effectId].magnitude = math.max(currentMagnitude, newMagnitude)
                end
            end
        end
    end

    -- Convert map to array
    local effects = {}
    for _, effect in pairs(effectsMap) do
        table.insert(effects, effect)
    end

    -- Clear existing content
    local container = statusEffectsElement.layout.content[1]
    container.content = ui.content({})

    -- Ensure static 5x5 grid
    local numRows = 5
    local numCols = effectsPerRow
    local rows = {}

    -- Create empty rows first (this ensures the grid is always structured)
    for i = 1, numRows do
        rows[i] = {
            type = ui.TYPE.Flex,
            props = {
				size = util.vector2(effectIconSize, effectIconSize),
                horizontal = true,
                align = ui.ALIGNMENT.Center,
                arrange = ui.ALIGNMENT.Center
            },
            content = ui.content({})
        }
    end

    -- Populate rows from **bottom-up**
    for i, effect in ipairs(effects) do
        local row = math.floor((i - 1) / numCols) + 1 -- Fill Row 1 first, then move up
        if row > numRows then break end -- Stop if exceed 5 rows

        -- Insert effect into the correct row
        table.insert(rows[row].content, {
            type = ui.TYPE.Image,
            props = {
                size = util.vector2(effectIconSize, effectIconSize),
                resource = ui.texture({ path = effect.record.icon }),
                visible = true
            }
        })
    end

    -- Insert rows in order (bottom to top)
    for i = numRows, 1, -1 do
        table.insert(container.content, rows[i])
    end

    -- Update the UI
    statusEffectsElement:update()
end


-- Make sure to destroy the element when needed
local function destroyStatusEffects()
    if statusEffectsElement then
        statusEffectsElement:destroy()
        statusEffectsElement = nil
    end
end

-- Call this function whenever effects/spells change
-- You might want to call this in your onFrame function

local function updateStaminaBar(actor)
    -- Fetch the current and base stamina values for the actor (player)
    local staminaCurrent = actorStamina(actor).current
    local staminaBase = actorStamina(actor).base

    -- Get the current size of the stamina bar (this should include the width and height)
    local barSize = actionBar.layout.content[1].content[3].content[2].props.size
    local maxBarWidth = staminaBarWidth -- Set the max width explicitly

    -- Calculate the ratio of current stamina to max stamina, ensuring it stays between 0 and 1
    local ratio = math.max(0, math.min(staminaCurrent / staminaBase, 1))

    -- Calculate the new width of the stamina bar based on the ratio
    local newWidth = maxBarWidth * ratio

    -- Update the stamina bar size: if stamina is 0 or less, set the width to 0
    local updatedSize = util.vector2(staminaCurrent > 0 and newWidth or 0, barSize.y)
    actionBar.layout.content[1].content[3].content[2].props.size = updatedSize
end

local function updateMagickaBar(actor)
    -- Fetch the current and base magicka values for the actor (player)
    local magickaCurrent = actorMagicka(actor).current
    local magickaBase = actorMagicka(actor).base

    -- Get the current size of the magicka bar (this should include the width and height)
    local barSize = actionBar.layout.content[1].content[3].content[1].props.size
    local maxBarWidth = magickaBarWidth  -- Set the max width explicitly

    -- Calculate the ratio of current magicka to max magicka, ensuring it stays between 0 and 1
    local ratio = math.max(0, math.min(magickaCurrent / magickaBase, 1))

    -- Calculate the new width of the magicka bar based on the ratio
    local newWidth = maxBarWidth * ratio

    -- Update the magicka bar size: if magicka is 0 or less, set the width to 0
    local updatedSize = util.vector2(magickaCurrent > 0 and newWidth or 0, barSize.y)
    actionBar.layout.content[1].content[3].content[1].props.size = updatedSize
end

local function updateHealthValue(actor)
    -- Fetch current and base health values for the actor
    local healthCurrent = actorHealth(actor).current
    local healthBase = actorHealth(actor).base

    -- Ensure the health values are valid before proceeding
    if healthCurrent == nil or healthBase == nil then
        print("Error: Invalid health data for actor.")
        return
    end

    -- Get the text element for health display
    local healthTextElement = actionBar.layout.content[2].content[2].content[2].props

    -- Update the health text
    healthTextElement.text = string.format("%d/%d", healthCurrent, healthBase)
end

-- Add this function after the other update functions
local function updatePortraitColor(actor)
    -- Get the portrait widget and damage overlay
    local portraitWidget = actionBar.layout.content[2].content[2]
    local damageOverlay = portraitWidget.content[1]
    
    -- Calculate health ratio
    local healthCurrent = actorHealth(actor).current
    local healthBase = actorHealth(actor).base
    local healthRatio = healthCurrent / healthBase
    
    -- If health is 0, desaturate the portrait and show full overlay
    if healthCurrent <= 0 then
        portraitWidget.props.color = util.color.rgb(0.5, 0.5, 0.5) -- Gray for death
        damageOverlay.props.relativePosition = util.vector2(0, 0) -- Full overlay
        damageOverlay.props.color = util.color.rgb(0.5, 0.5, 0.5) -- Change overlay to gray
    else
        -- Reset portrait color
        portraitWidget.props.color = util.color.rgb(1, 1, 1)
        damageOverlay.props.color = util.color.rgb(1, 0, 0) -- Reset overlay to red
        
        -- Calculate overlay position based on health ratio
        -- Move from 1 (fully hidden below) to 0 (fully visible) as health decreases
        local overlayPosition = healthRatio
        damageOverlay.props.relativePosition = util.vector2(0, overlayPosition)
    end
end

-- Update the existing updateWidgets function to include portrait color update
local function updateWidgets()
    updateStaminaBar(self.object)
    updateMagickaBar(self.object)
    updateHealthValue(self.object)
    updatePortraitColor(self.object)
    actionBar:update()
end

local function createCursorOverlapChecker(actionBar)

    local function isCursorOverWidget(cursorPos, widgetRelX, widgetRelY, widget)
		local size
		if widget.props.size then
			size = widget.props.size 
        else
			size = util.vector2(screenWidth * 0.015, screenWidth * 0.015)
		end
        return cursorPos.x >= widgetRelX and 
               cursorPos.x <= widgetRelX + size.x and
               cursorPos.y >= widgetRelY and 
               cursorPos.y <= widgetRelY + size.y
    end

    return function(cursorPos, cursorSize, mouseButtonWasPressed)
        local overlappingWidgets = {}
        local overlappingContentSlots = {}

        -- Check main widgets
        for name, data in pairs(targetWidgets) do
            if isCursorOverWidget(cursorPos, data.relX, data.relY, data.widget) then
                table.insert(overlappingWidgets, name)
            end
        end

        -- Check content slots
        for contentName, data in pairs(contentTables) do
            for i, slot in ipairs(data.content) do
                if isCursorOverWidget(cursorPos, data.relX + (i-1) * (screenWidth * 0.026), data.relY, slot) then
                    table.insert(overlappingContentSlots, {contentName = contentName, index = i})
                end
            end
        end

        return overlappingWidgets, overlappingContentSlots
    end
end

-- Function to change texture color and toggle state for "intervention_button"
local function toggleInterventionState(button)
    if interventionButtonState == "divine" then
        interventionButtonState = "almsivi"
        button.props.resource = ui.texture({path = 'Textures/almsivi.png'})
    elseif interventionButtonState == "almsivi" then
        interventionButtonState = "recall"
        button.props.resource = ui.texture({path = 'Textures/recall.png'})
    else
		interventionButtonState = "divine"
		button.props.resource = ui.texture({path = 'Textures/divine.png'})
	end
end

-- Function to cast a spell based on intervention button state
local function setInterventionTimer()
    local spells = {
        divine = "divine intervention",
        almsivi = "almsivi intervention",
        recall = "recall"
    }

    local spellName = spells[interventionButtonState]

    if not spellName then
        print("Invalid intervention state: " .. tostring(interventionButtonState))
        return
    end

    if not hasSpell(self.object, spellName) then
        ui.showMessage("You do not know " .. spellName:gsub("^%l", string.upper) .. "!")
        return
    end
	
	if types.Actor.getSelectedSpell(self) ~= spellName then
		types.Actor.setSelectedSpell(self, spellName)
	end
    -- Ensure stance is set before casting
    if types.Actor.stance(self.object) ~= types.Actor.STANCE.Spell then
		async:newUnsavableSimulationTimer(0.005, function()
			types.Actor.setStance(self, types.Actor.STANCE.Spell)
		end)

        -- Set a pause time before "pressing" the use button after the stance is set
        interventionPauseTime = 0.25
    else

        interventionPauseTime = 0.1  -- Set a short pause before releasing the button
    end
end

local function equipWeapon(weapon)
    if types.Actor.hasEquipped(self, weapon) then
        return
    else
        -- Get current equipment to preserve other slots
        local currentEquipment = types.Actor.getEquipment(self)
        
        -- All weapons go in CarriedRight slot
        currentEquipment[types.Actor.EQUIPMENT_SLOT.CarriedRight] = weapon
        
        -- Apply equipment update
        types.Actor.setEquipment(self, currentEquipment)
    end
end

-- Function to update stack count for a specific slot
local function updateSlotStackCount(slotName, slotIndex, item)
    -- Find the appropriate content table and slot based on the slot name and index
    local slotWidget
    
    if slotName == "actionSlotsContent1" then
        slotWidget = actionSlotsContent1[slotIndex]
    elseif slotName == "actionSlotsContent2" then
        slotWidget = actionSlotsContent2[slotIndex]
    elseif slotName == "miscContent1" then
        slotWidget = miscContent1[slotIndex]
    elseif slotName == "miscContent2" then
        slotWidget = miscContent2[slotIndex]
    else
        -- Not a slot that needs stack count (spell slots or weapon slots)
        return
    end
    
    if not slotWidget then return end
    
    -- Clear the stack count if no item is assigned
    if not item then
        slotWidget.props.text = ""
        return
    end
    
    -- Get the item count from inventory
    local playerInventory = types.Actor.inventory(self.object)
    local itemType = getItemType(item)
    if not itemType then return end
    
    -- Get the item ID from the record
    local itemId = types[itemType].record(item).id
    
    -- Count items with this ID in the inventory
    local count = playerInventory:countOf(itemId)
    
    -- Only show count if greater than 1
    if count > 1 then
        slotWidget.props.text = formatStackCount(count)
    else
        slotWidget.props.text = ""
    end
end

-- Function to update all slot stack counts
local function updateAllStackCounts()
    for slotName, slots in pairs(assignedItems) do
        if slotName ~= "melee_weapon" and slotName ~= "ranged_weapon" then
            for index, item in pairs(slots) do
                updateSlotStackCount(slotName, index, item)
            end
        end
    end
end

-- Modify the existing assignItemToSlot function to update stack counts
local function assignItemToSlot(slotName, slotIndex)
    -- Validate inputs
    if not slotName or not slotIndex then
        print("Error: Invalid slot parameters", slotName, slotIndex)
        return nil
    end

    local function updateSlotVisual(target, icon)
        if not target or not icon then return false end
        target.content[1].content[2].props.resource = ui.texture({ path = icon })
        return true
    end

    local function storeItemReference(item)
        -- Initialize slot table if needed
        assignedItems[slotName] = assignedItems[slotName] or {}
        assignedItems[slotName][slotIndex] = item
        
        -- Update stack count for non-weapon slots
        if slotName ~= "melee_weapon" and slotName ~= "ranged_weapon" then
            updateSlotStackCount(slotName, slotIndex, item)
        end
        
        -- Check if the item is enchanted
        local itemData = types.Item.itemData(item)
        local isEnchanted = (itemData and itemData.enchantmentCharge ~= nil)
        
        -- Update magicIndicator visibility based on enchantment
        if slotName == "melee_weapon" then
            -- For melee weapon, find the magicIndicator in the parent widget
            local parentWidget = actionBar.layout.content[2].content[3]
            if parentWidget and parentWidget.content[1] then
                parentWidget.content[1].props.visible = isEnchanted
                -- Keep default color for weapon slots (not green)
                parentWidget.content[1].props.color = util.color.rgb(1, 1, 1)
            end
        elseif slotName == "ranged_weapon" then
            -- For ranged weapon, find the magicIndicator in the parent widget
            local parentWidget = actionBar.layout.content[2].content[4]
            if parentWidget and parentWidget.content[1] then
                parentWidget.content[1].props.visible = isEnchanted
                -- Keep default color for weapon slots (not green)
                parentWidget.content[1].props.color = util.color.rgb(1, 1, 1)
            end
        else
            -- For regular slots
            local slotTable = _G[slotName]
            if slotTable and slotTable[slotIndex] and slotTable[slotIndex].content[1].content[1] then
                slotTable[slotIndex].content[1].content[1].props.visible = isEnchanted
                
                -- Only set green color for enchanted items that are equipped
                if isEnchanted then
                    -- Check if the item is equipped
                    local equipment = types.Actor.getEquipment(self)
                    local isEquipped = false
                    
                    if equipment then
                        for _, equippedItem in pairs(equipment) do
                            if equippedItem and equippedItem.id == item.id then
                                isEquipped = true
                                break
                            end
                        end
                    end
                    
                    if isEquipped then
                        -- Green color for enchanted and equipped items
                        slotTable[slotIndex].content[1].content[1].props.color = util.color.rgb(0, 1, 0)
                    else
                        -- Default color for enchanted but not equipped items
                        slotTable[slotIndex].content[1].content[1].props.color = util.color.rgb(1, 1, 1)
                    end
                else
                    -- Default color for non-enchanted items
                    slotTable[slotIndex].content[1].content[1].props.color = util.color.rgb(1, 1, 1)
                end
            end
        end
    end

    -- Check if there's already an item assigned to this slot
    if assignedItems[slotName] and assignedItems[slotName][slotIndex] then
        local existingItem = assignedItems[slotName][slotIndex]
        
        -- Callback for item assignment that checks if the same item is being assigned
        local function onItemSelected(_, _, item)
            local itemIcon = getItemIcon(item)
            if not itemIcon then
                print("Error: Could not get icon for item")
                return
            end
            
            -- Check if this is the same item that's already assigned
            local existingItemType = getItemType(existingItem)
            local newItemType = getItemType(item)
            
            if existingItemType == newItemType and 
               types[existingItemType].record(existingItem).id == types[newItemType].record(item).id then
                -- Same item is being assigned, so remove it instead
                assignedItems[slotName][slotIndex] = nil
                
                -- Update the slot visual to default
                if slotName == "melee_weapon" or slotName == "ranged_weapon" then
                    targetWidgets[slotName].widget.props.resource = ui.texture({path = 'Textures/slot.png'})
                    
                    -- Hide the magic indicator for weapon slots
                    if slotName == "melee_weapon" then
                        local parentWidget = actionBar.layout.content[2].content[3]
                        if parentWidget and parentWidget.content[1] then
                            parentWidget.content[1].props.visible = false
                        end
                    elseif slotName == "ranged_weapon" then
                        local parentWidget = actionBar.layout.content[2].content[4]
                        if parentWidget and parentWidget.content[1] then
                            parentWidget.content[1].props.visible = false
                        end
                    end
                else
                    local slotTable = _G[slotName]
                    if slotTable and slotTable[slotIndex] then
                        -- Reset the slot visual
                        slotTable[slotIndex].content[1].content[2].props.resource = ui.texture({ path = 'Textures/slot.png' })
                        -- Clear the stack count
                        slotTable[slotIndex].props.text = ""
                        -- Hide the magic indicator
                        if slotTable[slotIndex].content[1].content[1] then
                            slotTable[slotIndex].content[1].content[1].props.visible = false
                        end
                    end
                end
                
                I.UI.setMode()
                return
            end
            
            -- Different item, proceed with normal assignment
            if slotName == "melee_weapon" or slotName == "ranged_weapon" then
                targetWidgets[slotName].widget.props.resource = ui.texture({path = itemIcon})
                storeItemReference(item)
                return
            end

            -- Handle regular slots
            local slotTable = _G[slotName]
            if slotTable and slotTable[slotIndex] then
                if updateSlotVisual(slotTable[slotIndex], itemIcon) then
                    storeItemReference(item)
                end
            else
                print("Error: Invalid slot configuration", slotName, slotIndex)
            end
        end

        return createItemSelectionWindow(slotName, slotIndex, onItemSelected)
    end

    -- No existing item, use standard assignment
    local function onItemSelected(_, _, item)
        local itemIcon = getItemIcon(item)
        if not itemIcon then
            print("Error: Could not get icon for item")
            return
        end

        -- Handle special weapon slots
        if slotName == "melee_weapon" or slotName == "ranged_weapon" then
            targetWidgets[slotName].widget.props.resource = ui.texture({path = itemIcon})
            storeItemReference(item)
            return
        end

        -- Handle regular slots
        local slotTable = _G[slotName]
        if slotTable and slotTable[slotIndex] then
            if updateSlotVisual(slotTable[slotIndex], itemIcon) then
                storeItemReference(item)
            end
        else
            print("Error: Invalid slot configuration", slotName, slotIndex)
        end
    end

    return createItemSelectionWindow(slotName, slotIndex, onItemSelected)
end

-- Function to create a spell list item
local function createSpellListItem(spell, slotName, slotIndex, tooltip)
    return {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            padding = util.vector2(4, 2),
        },
        content = ui.content({
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                    align = ui.ALIGNMENT.Start,
                },
                content = ui.content({
                    {
                        template = I.MWUI.templates.textNormal,
                        props = { 
                            text = spell.name,
                            textAlignH = ui.ALIGNMENT.Start
                        }
                    }
                })
            }
        }),
        events = {
            mouseClick = async:callback(function()
                local slotTable = _G[slotName]
                if slotTable and slotTable[slotIndex] then
                    -- Get the icon path and insert "b_" before the filename
                    local iconPath = spell.effects[1].effect.icon
                    local bigIconPath = iconPath:gsub("icons\\s\\", "icons\\s\\b_")
                    
                    -- Store both the icon and the spell reference
                    -- Spell slots have a different structure than item slots
                    slotTable[slotIndex].props.resource = ui.texture({ path = bigIconPath })
                    slotTable[slotIndex].props.alpha = 1  -- Set alpha to 1 when spell is assigned
                    assignedSpells[slotName] = assignedSpells[slotName] or {}
                    assignedSpells[slotName][slotIndex] = spell
                else
                    print("Error: Invalid slot configuration:", slotName, slotIndex)
                end
                I.UI.setMode()
            end),
            mouseMove = async:callback(function(e)
                tooltip.show({
                    name = spell.name,
                    type = spell.type == core.magic.SPELL_TYPE.Power and 'power' or 'spell',
                    item = spell,
                }, e.position)
                return false
            end)
        }
    }
end

local function assignSpellToSlot(slotName, slotIndex)
    -- Retrieve and categorize spells
    local playerSpells = types.Actor.spells(self.object)
    local powers, spells = {}, {}
    
    for _, spell in ipairs(playerSpells) do
        if spell.type == core.magic.SPELL_TYPE.Power then
            table.insert(powers, spell)
        elseif spell.type == core.magic.SPELL_TYPE.Spell then
            table.insert(spells, spell)
        end
    end
    
    -- Check if player has any spells or powers
    if #powers == 0 and #spells == 0 then
        return ui.create({
            template = I.MWUI.templates.boxTransparentThick,
            layer = 'Windows',
            props = {
                anchor = util.vector2(0.5, 0.5),
                relativePosition = util.vector2(0.5, 0.5),
                padding = util.vector2(16, 16)
            },
            content = ui.content({
                {
                    template = I.MWUI.templates.textHeader,
                    props = {
                        text = "No spells available",
                        textAlignH = ui.ALIGNMENT.Center
                    }
                },
                {
                    template = I.MWUI.templates.padding
                },
                {
                    template = I.MWUI.templates.textNormal,
                    props = { 
                        text = "You don't know any spells or powers.",
                        textAlignH = ui.ALIGNMENT.Center
                    }
                }
            })
        })
    end
    
    -- Sort spells alphabetically
    local function sortByName(a, b) return a.name < b.name end
    table.sort(powers, sortByName)
    table.sort(spells, sortByName)

    -- Check if there's already a spell assigned to this slot
    if assignedSpells[slotName] and assignedSpells[slotName][slotIndex] then
        local existingSpell = assignedSpells[slotName][slotIndex]
        
        -- Create a modified spell list item that checks for the same spell
        local function createModifiedSpellListItem(spell, slotName, slotIndex, tooltip)
            return {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                    padding = util.vector2(4, 2),
                },
                content = ui.content({
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = true,
                            align = ui.ALIGNMENT.Start,
                        },
                        content = ui.content({
                            {
                                template = I.MWUI.templates.textNormal,
                                props = { 
                                    text = spell.name,
                                    textAlignH = ui.ALIGNMENT.Start
                                }
                            }
                        })
                    }
                }),
                events = {
                    mouseClick = async:callback(function()
                        -- Check if this is the same spell that's already assigned
                        if existingSpell.id == spell.id then
                            -- Same spell is being assigned, so remove it instead
                            local slotTable = _G[slotName]
                            if slotTable and slotTable[slotIndex] then
                                -- Reset the slot visual with the correct texture path
                                slotTable[slotIndex].props.resource = ui.texture({ path = 'Textures/slot.png' })
                                slotTable[slotIndex].props.alpha = 1.0  -- Set alpha back to default
                                
                                -- Remove the spell reference
                                assignedSpells[slotName][slotIndex] = nil
                            end
                        else
                            -- Different spell, proceed with normal assignment
                            local slotTable = _G[slotName]
                            if slotTable and slotTable[slotIndex] then
                                -- Get the icon path and insert "b_" before the filename
                                local iconPath = spell.effects[1].effect.icon
                                local bigIconPath = iconPath:gsub("icons\\s\\", "icons\\s\\b_")
                                
                                -- Store both the icon and the spell reference
                                slotTable[slotIndex].props.resource = ui.texture({ path = bigIconPath })
                                slotTable[slotIndex].props.alpha = 1  -- Set alpha to 1 when spell is assigned
                                assignedSpells[slotName] = assignedSpells[slotName] or {}
                                assignedSpells[slotName][slotIndex] = spell
                            else
                                print("Error: Invalid slot configuration:", slotName, slotIndex)
                            end
                        end
                        I.UI.setMode()
                    end),
                    mouseMove = async:callback(function(e)
                        tooltip.show({
                            name = spell.name,
                            type = spell.type == core.magic.SPELL_TYPE.Power and 'power' or 'spell',
                            item = spell,
                        }, e.position)
                        return false
                    end)
                }
            }
        end
        
        local tooltip = createItemSelectionTooltip()
        local listContent = {}
        
        -- Only add Powers section if there are powers
        if #powers > 0 then
            table.insert(listContent, { 
                template = I.MWUI.templates.textHeader, 
                props = { 
                    text = "Powers",
                    padding = util.vector2(0, 8)
                } 
            })
            
            -- Add powers with modified behavior
            for _, power in ipairs(powers) do
                table.insert(listContent, createModifiedSpellListItem(power, slotName, slotIndex, tooltip))
            end
        end

        -- if both powers and spells
        if #powers > 0 and #spells > 0 then
            for _, element in ipairs({
                {template = I.MWUI.templates.padding},
                {template = I.MWUI.templates.horizontalLine, props = {size = util.vector2(200, 2)}},
                {template = I.MWUI.templates.padding},
            }) do
                table.insert(listContent, element)
            end
        end

        -- Only add Spells section if there are spells
        if #spells > 0 then
            table.insert(listContent, { 
                template = I.MWUI.templates.textHeader, 
                props = { 
                    text = "Spells",
                    padding = util.vector2(0, 8)
                } 
            })
            
            -- Add spells with modified behavior
            for _, spell in ipairs(spells) do
                table.insert(listContent, createModifiedSpellListItem(spell, slotName, slotIndex, tooltip))
            end
        end
        
        -- Create and return the window
        return ui.create({
            template = I.MWUI.templates.boxTransparentThick,
            layer = 'Windows',
            props = {
                anchor = util.vector2(0.5, 0.5),
                relativePosition = util.vector2(0.5, 0.5),
                padding = util.vector2(16, 16), -- Add padding around the content
            },
            events = {
                mouseMove = async:callback(function()
                    tooltip.hide()
                end)
            },
            content = ui.content({
                {
                    type = ui.TYPE.Flex,
                    props = {
                        arrange = ui.ALIGNMENT.Center,
                    },
                    content = ui.content(listContent)
                }
            })
        })
    end

    -- No existing spell, use standard assignment
    local tooltip = createItemSelectionTooltip()
    local listContent = {}
    
    -- Only add Powers section if there are powers
    if #powers > 0 then
        table.insert(listContent, { 
            template = I.MWUI.templates.textHeader, 
            props = { 
                text = "Powers",
                padding = util.vector2(0, 8)
            } 
        })
        
        -- Add powers
        for _, power in ipairs(powers) do
            table.insert(listContent, createSpellListItem(power, slotName, slotIndex, tooltip))
        end
    end

    -- if both powers and spells
    if #powers > 0 and #spells > 0 then
        for _, element in ipairs({
            {template = I.MWUI.templates.padding},
            {template = I.MWUI.templates.horizontalLine, props = {size = util.vector2(200, 2)}},
            {template = I.MWUI.templates.padding},
        }) do
            table.insert(listContent, element)
        end
    end

    -- Only add Spells section if there are spells
    if #spells > 0 then
        table.insert(listContent, { 
            template = I.MWUI.templates.textHeader, 
            props = { 
                text = "Spells",
                padding = util.vector2(0, 8)
            } 
        })
        
        -- Add spells with modified behavior
        for _, spell in ipairs(spells) do
            table.insert(listContent, createSpellListItem(spell, slotName, slotIndex, tooltip))
        end
    end
    
    -- Create and return the window
    return ui.create({
        template = I.MWUI.templates.boxTransparentThick,
        layer = 'Windows',
        props = {
            anchor = util.vector2(0.5, 0.5),
            relativePosition = util.vector2(0.5, 0.5),
            padding = util.vector2(16, 16), -- Add padding around the content
        },
        events = {
            mouseMove = async:callback(function()
                tooltip.hide()
            end)
        },
        content = ui.content({
            {
                type = ui.TYPE.Flex,
                props = {
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content(listContent)
            }
        })
    })
end

-- Function to check if an item is equipped by the player
local function isItemEquipped(item)
    if not item then return false end
    
    -- Get the player's equipment
    local equipment = types.Actor.getEquipment(self.object)
    if not equipment then return false end
    
    -- Check all equipment slots
    for slotId, equippedItem in pairs(equipment) do
        if equippedItem and equippedItem.id == item.id then
            return true
        end
    end
    
    return false
end

-- Function to update the color of magic indicators for enchanted equipped items
local function updateEquippedItemHighlight()
    -- Process action slots content
    local slotTables = {
        {name = "actionSlotsContent1", content = actionSlotsContent1},
        {name = "actionSlotsContent2", content = actionSlotsContent2}
    }
    
    for _, slotTable in ipairs(slotTables) do
        local slotName = slotTable.name
        local content = slotTable.content
        
        -- Check each slot in this table
        if assignedItems[slotName] then
            for index, item in pairs(assignedItems[slotName]) do
                if content and content[index] then
                    -- Check if the item is enchanted
                    local itemData = types.Item.itemData(item)
                    local isEnchanted = (itemData and itemData.enchantmentCharge ~= nil)
                    local isEquipped = isItemEquipped(item)
                    
                    -- Find the magicIndicator widget (first element in the backgroundImage content)
                    local magicIndicator = content[index].content[1].content[1]
                    
                    if isEnchanted then
                        -- Make sure the magic indicator is visible for enchanted items
                        magicIndicator.props.visible = true
                        -- Use standard magic indicator for enchanted items
                        magicIndicator.props.resource = ui.texture({ path = "textures\\menu_icon_magic_mini.dds" })
                        
                        -- Update color based on equipped status
                        if isEquipped then
                            -- Green color for enchanted and equipped items
                            magicIndicator.props.color = util.color.rgb(0, 1, 0)
                        else
                            -- Default color for enchanted but not equipped items
                            magicIndicator.props.color = util.color.rgb(1, 1, 1)
                        end
                    else
                        -- For non-enchanted items
                        if isEquipped then
                            -- Make indicator visible with slot.png for equipped non-enchanted items
                            magicIndicator.props.visible = true
                            -- Use slot.png for non-enchanted equipped items
                            magicIndicator.props.resource = ui.texture({ path = "Textures/slot.png" })
                            -- Ensure proper positioning and sizing to prevent cutoff
                            magicIndicator.props.relativeSize = util.vector2(1.0, 1.0)
                            magicIndicator.props.relativePosition = util.vector2(0.5, 0.5)
                            magicIndicator.props.anchor = util.vector2(0.5, 0.5)
                            -- Green color for equipped items - same as enchanted equipped items
                            magicIndicator.props.color = util.color.rgb(0.4, 1, 0.4)
                        else
                            -- Hide indicator for non-enchanted, non-equipped items
                            magicIndicator.props.visible = false
                        end
                    end
                    
                    -- Reset background image color to default (not green)
                    content[index].content[1].props.color = util.color.rgb(1, 1, 1)
                end
            end
        end
    end
end


-- Function to use an item from an assigned slot
local function useAssignedItem(slotName, slotIndex)
    -- Skip processing for melee_weapon and ranged_weapon as they're no longer assignable slots
    if slotName == "melee_weapon" or slotName == "ranged_weapon" then
        return
    end
    
    -- Check if there's an item assigned to this slot
    if not assignedItems[slotName] or not assignedItems[slotName][slotIndex] then
        return
    end

    local item = assignedItems[slotName][slotIndex]
    local itemType = getItemType(item)
    
    if not itemType then
        print("Error: Could not determine item type")
        return
    end
    
    -- Check if the item still exists in inventory
    local playerInventory = types.Actor.inventory(self.object)
    local itemId = types[itemType].record(item).id
    if playerInventory:countOf(itemId) <= 0 then
        -- Item no longer exists, remove from slot
        assignedItems[slotName][slotIndex] = nil
        
        -- Update the slot visual
        if slotName == "melee_weapon" then
            -- Update melee weapon icon
            targetWidgets[slotName].widget.props.resource = ui.texture({ path = 'Textures/slot.png' })
            -- Hide the magic indicator
            local parentWidget = actionBar.layout.content[2].content[3]
            if parentWidget and parentWidget.content[1] then
                parentWidget.content[1].props.visible = false
            end
        elseif slotName == "ranged_weapon" then
            -- Update ranged weapon icon
            targetWidgets[slotName].widget.props.resource = ui.texture({ path = 'Textures/slot.png' })
            -- Hide the magic indicator
            local parentWidget = actionBar.layout.content[2].content[4]
            if parentWidget and parentWidget.content[1] then
                parentWidget.content[1].props.visible = false
            end
        else
            local slotTable = _G[slotName]
            if slotTable and slotTable[slotIndex] then
                -- Check if this is a spell slot or an item slot
                if slotName == "spellSlotsContent1" or slotName == "spellSlotsContent2" then
                    -- Spell slots have a different structure
                    slotTable[slotIndex].props.resource = ui.texture({ path = 'Textures/slot.png' })
                else
                    -- Item slots have a nested content structure
                    slotTable[slotIndex].content[1].content[2].props.resource = ui.texture({ path = 'Textures/slot.png' })
                    
                    -- Hide the magic indicator
                    if slotTable[slotIndex].content[1].content[1] then
                        slotTable[slotIndex].content[1].content[1].props.visible = false
                    end
                end
            end
        end
        return
    end
    
    -- Send the UseItem event to use/equip the item
    core.sendGlobalEvent('UseItem', {object = item, actor = self.object})
    
    -- Update UI to reflect equipped status immediately
    async:newUnsavableSimulationTimer(0.05, function()
        updateEquippedItemHighlight()
    end)
    
    -- Check if the item has a CastOnUse enchantment
    local itemData = types.Item.itemData(item)
    if itemData and itemData.enchantmentCharge ~= nil then
        -- Item is enchanted, get the record to check enchantment type
        local record = types[itemType].record(item)
        if record and record.enchant then
            local enchantment = core.magic.enchantments.records[record.enchant]
            if enchantment and enchantment.type == core.magic.ENCHANTMENT_TYPE.CastOnUse then
                -- Using the same pattern as in castAssignedSpell function
                -- Get current selected enchanted item (if any)
                local currentItem = types.Actor.getSelectedEnchantedItem(self)
                
                -- If already in spell stance and using the same item, switch to nothing stance
                if types.Actor.stance(self) == types.Actor.STANCE.Spell and currentItem and currentItem.id == item.id then
                    types.Actor.setStance(self, types.Actor.STANCE.Nothing)
                    return
                end
                
                -- Set the selected enchanted item
                types.Actor.setSelectedEnchantedItem(self, item)
                
                -- Set stance to weapon if not already
                if types.Actor.stance(self) ~= types.Actor.STANCE.Spell then
                    async:newUnsavableSimulationTimer(0.005, function()
                        types.Actor.setStance(self, types.Actor.STANCE.Spell)
                    end)
                end
            end
        end
    end
    
    -- For consumable items, check if they're gone after use and update slot if needed
    async:newUnsavableSimulationTimer(0.1, function()
        -- Check if the item still exists in inventory after using it
        if playerInventory:countOf(itemId) <= 0 then
            -- Item was consumed, remove from slot
            assignedItems[slotName][slotIndex] = nil
            
            -- Update the slot visual
            if slotName == "melee_weapon" then
                -- Update melee weapon icon
                targetWidgets[slotName].widget.props.resource = ui.texture({ path = 'Textures/slot.png' })
                -- Hide the magic indicator
                local parentWidget = actionBar.layout.content[2].content[3]
                if parentWidget and parentWidget.content[1] then
                    parentWidget.content[1].props.visible = false
                end
            elseif slotName == "ranged_weapon" then
                -- Update ranged weapon icon
                targetWidgets[slotName].widget.props.resource = ui.texture({ path = 'Textures/slot.png' })
                -- Hide the magic indicator
                local parentWidget = actionBar.layout.content[2].content[4]
                if parentWidget and parentWidget.content[1] then
                    parentWidget.content[1].props.visible = false
                end
            else
                local slotTable = _G[slotName]
                if slotTable and slotTable[slotIndex] then
                    -- Check if this is a spell slot or an item slot
                    if slotName == "spellSlotsContent1" or slotName == "spellSlotsContent2" then
                        -- Spell slots have a different structure
                        slotTable[slotIndex].props.resource = ui.texture({ path = 'Textures/slot.png' })
                    else
                        -- Item slots have a nested content structure
                        slotTable[slotIndex].content[1].content[2].props.resource = ui.texture({ path = 'Textures/slot.png' })
                        
                        -- Hide the magic indicator
                        if slotTable[slotIndex].content[1].content[1] then
                            slotTable[slotIndex].content[1].content[1].props.visible = false
                        end
                    end
                end
            end
        else
            -- Update stack count for remaining items
            updateSlotStackCount(slotName, slotIndex, item)
            
            -- Update equipped item indicators
            updateEquippedItemHighlight()
        end
    end)
end

-- Function to cast a spell from an assigned slot
local function castAssignedSpell(slotName, slotIndex)
    -- Check if there's a spell assigned to this slot
    if not assignedSpells[slotName] or not assignedSpells[slotName][slotIndex] then
        return
    end

    local spell = assignedSpells[slotName][slotIndex]
    
    -- Verify spell is valid
    if not spell or not spell.id then
        print("Error: Invalid spell in slot", slotName, slotIndex)
        return
    end

    -- Check if actor has the spell
    if not hasSpell(self.object, spell.id) then
        -- Spell no longer known, remove from slot
        assignedSpells[slotName][slotIndex] = nil
        
        -- Update the slot visual
        local slotTable = _G[slotName]
        if slotTable and slotTable[slotIndex] then
            -- Spell slots have a different structure than item slots
            slotTable[slotIndex].props.resource = ui.texture({ path = 'Textures/slot.png' })
            slotTable[slotIndex].props.alpha = 1.0  -- Changed from 0.5 to 1.0 to remove transparency
            slotTable[slotIndex].props.color = util.color.rgb(1.0, 1.0, 1.0)  -- Reset color
        end
        
        ui.showMessage("You do not know " .. spell.name .. "!")
        return
    end
    
    -- Get current selected spell (safely)
    local currentSpell = types.Actor.getSelectedSpell(self)
    local currentSpellId = currentSpell and currentSpell.id or nil

    -- If already in spell stance and using the same spell, switch to nothing stance
    if types.Actor.stance(self.object) == types.Actor.STANCE.Spell and currentSpellId == spell.id then
        types.Actor.setStance(self, types.Actor.STANCE.Nothing)
        return
    end

    -- Set the selected spell (always allow selecting the spell)
    types.Actor.setSelectedSpell(self, spell.id)
    
    -- Set stance to spell if not already
    if types.Actor.stance(self.object) ~= types.Actor.STANCE.Spell then
        async:newUnsavableSimulationTimer(0.005, function()
            types.Actor.setStance(self, types.Actor.STANCE.Spell)
        end)
        
        -- Show warning if insufficient magicka but still allow selecting the spell
        if spell.type == core.magic.SPELL_TYPE.Spell then
            local actorStats = types.Actor.stats
            local currentMagicka = actorStats.dynamic.magicka(self).current
            
            if currentMagicka < spell.cost then
                ui.showMessage("Not enough magicka to cast " .. spell.name)
            end
        end
    end
end

-- Function to open the rest window
local function openRestWindow()
    I.UI.setMode('Rest') -- drop all modes and open interface
    -- Insert logic to open the rest window here
end

local checkCursorOverlap = createCursorOverlapChecker(actionBar)


-- Function to hide all UI elements
local function hideAllUI()
    -- Hide main UI components
    if bg then
        bg.layout.props.visible = false
        bg:update()
    end
    
    if actionBar then
        actionBar.layout.props.visible = false
        actionBar:update()
    end
    
    if statusEffectsElement then
        statusEffectsElement.layout.props.visible = false
        statusEffectsElement:update()
    end
    
    if currentTooltip then
        currentTooltip.layout.props.visible = false
        currentTooltip:update()
    end
    
    -- You may need to add more UI elements here depending on your implementation
end

-- Function to show all UI elements
local function showAllUI()
    -- Show main UI components
    if bg then
        bg.layout.props.visible = true
        bg:update()
    end
    
    if actionBar then
        actionBar.layout.props.visible = true
        actionBar:update()
    end
    
    if statusEffectsElement then
        statusEffectsElement.layout.props.visible = true
        statusEffectsElement:update()
    end
    
    -- You may need to add more UI elements here depending on your implementation
end
-- Function to update the UI for the currently equipped weapon and spell
local function updateEquippedDisplay()
    -- Get current equipment for weapon display
    local equipment = types.Actor.getEquipment(self)
    local equippedWeapon = equipment and equipment[types.Actor.EQUIPMENT_SLOT.CarriedRight]
    
    -- Get current actor stats for magicka
    local actorStats = types.Actor.stats
    local currentMagicka = actorStats.dynamic.magicka(self).current
    
    -- Get current selected spell and enchanted item
    local selectedSpell = types.Actor.getSelectedSpell(self)
    local selectedEnchantedItem = types.Actor.getSelectedEnchantedItem(self)
    
    -- Update melee weapon display
    if equippedWeapon then
        -- Update weapon icon
        targetWidgets.melee_weapon.widget.props.resource = ui.texture({ path = getItemIcon(equippedWeapon) })
        
        -- Check if the weapon is enchanted and update the magicIndicator visibility
        local itemData = types.Item.itemData(equippedWeapon)
        local isEnchanted = (itemData and itemData.enchantmentCharge ~= nil)
        
        -- Update magicIndicator visibility and color
        local parentWidget = actionBar.layout.content[2].content[3]
        if parentWidget and parentWidget.content[1] then
            -- Show the magic indicator if the item is enchanted
            parentWidget.content[1].props.visible = isEnchanted
            
            -- Always use default color for weapon slots (as requested)
            parentWidget.content[1].props.color = util.color.rgb(1, 1, 1)
        end
    else
        -- No weapon equipped, show default icon
        targetWidgets.melee_weapon.widget.props.resource = ui.texture({ path = 'icons/k/stealth_handtohand.dds' })
        
        -- Hide magic indicator
        local parentWidget = actionBar.layout.content[2].content[3]
        if parentWidget and parentWidget.content[1] then
            parentWidget.content[1].props.visible = false
        end
    end
    
    -- Update spell/enchanted item (ranged weapon) display
    if selectedSpell then
        -- Get the spell icon path
        local iconPath = selectedSpell.effects[1].effect.icon
        local bigIconPath = iconPath:gsub("icons\\s\\", "icons\\s\\b_")
        
        -- Update spell icon
        targetWidgets.ranged_weapon.widget.props.resource = ui.texture({ path = bigIconPath })
        
        -- Check if the player has enough magicka to cast the spell
        local hasEnoughMagicka = true
        
        -- Powers don't cost magicka
        if selectedSpell.type == core.magic.SPELL_TYPE.Spell then
            hasEnoughMagicka = (currentMagicka >= selectedSpell.cost)
        end
        
        -- Show magic indicator for spells
        local parentWidget = actionBar.layout.content[2].content[4]
        if parentWidget and parentWidget.content[1] then
            parentWidget.content[1].props.visible = true
        end
        
        -- Darken the icon if not enough magicka
        if not hasEnoughMagicka then
            -- Apply a darker color to indicate the spell can't be cast
            targetWidgets.ranged_weapon.widget.props.color = util.color.rgb(0.5, 0.5, 0.5)
        else
            -- Normal color for castable spells
            targetWidgets.ranged_weapon.widget.props.color = util.color.rgb(1.0, 1.0, 1.0)
        end
    elseif selectedEnchantedItem then
        -- Get the enchanted item icon
        local iconPath = getItemIcon(selectedEnchantedItem)
        
        -- Update icon with the enchanted item
        targetWidgets.ranged_weapon.widget.props.resource = ui.texture({ path = iconPath })
        
        -- Check if the enchanted item has enough charge
        local itemData = types.Item.itemData(selectedEnchantedItem)
        local hasEnoughCharge = true
        
        if itemData then
            local itemType = getItemType(selectedEnchantedItem)
            local record = types[itemType].record(selectedEnchantedItem)
            
            if record and record.enchant then
                local enchantment = core.magic.enchantments.records[record.enchant]
                if enchantment and enchantment.type == core.magic.ENCHANTMENT_TYPE.CastOnUse then
                    -- Check if there's enough enchantment charge for use
                    hasEnoughCharge = (itemData.enchantmentCharge and itemData.enchantmentCharge > 0)
                end
            end
        end
        
        -- Show magic indicator for enchanted items
        local parentWidget = actionBar.layout.content[2].content[4]
        if parentWidget and parentWidget.content[1] then
            parentWidget.content[1].props.visible = true
            
            -- Always use default color for weapon slots (as requested)
            parentWidget.content[1].props.color = util.color.rgb(1, 1, 1)
        end
        
        -- Darken the icon if not enough charge
        if not hasEnoughCharge then
            -- Apply a darker color to indicate the item can't be used
            targetWidgets.ranged_weapon.widget.props.color = util.color.rgb(0.5, 0.5, 0.5)
        else
            -- Normal color for usable enchanted items
            targetWidgets.ranged_weapon.widget.props.color = util.color.rgb(1, 1, 1)
        end
    else
        -- No spell or enchanted item selected, show default icon
        targetWidgets.ranged_weapon.widget.props.resource = ui.texture({ path = 'textures/slot.png' })
        
        -- Reset color to normal
        targetWidgets.ranged_weapon.widget.props.color = util.color.rgb(1, 1, 1)
        
        -- Hide magic indicator
        local parentWidget = actionBar.layout.content[2].content[4]
        if parentWidget and parentWidget.content[1] then
            parentWidget.content[1].props.visible = false
        end
    end
end

-- Function to check if player has enough magicka to cast a spell
-- This only affects the visual appearance, not the ability to select
local function hasEnoughMagickaToCast(spell, currentMagicka)
    -- Powers don't cost magicka
    if spell.type == core.magic.SPELL_TYPE.Power then
        return true
    end
    
    -- Regular spells need to check against current magicka
    return (currentMagicka >= spell.cost)
end

-- Function to update all assigned spell slots based on current magicka
local function updateSpellSlotAppearance()
    -- Get current actor stats for magicka
    local actorStats = types.Actor.stats
    local currentMagicka = actorStats.dynamic.magicka(self).current
    
    -- Spell slot tables to check
    local spellTables = {
        {name = "spellSlotsContent1", content = spellSlotsContent1},
        {name = "spellSlotsContent2", content = spellSlotsContent2}
    }
    
    -- Update each spell slot
    for _, spellTable in ipairs(spellTables) do
        local slotName = spellTable.name
        local content = spellTable.content
        
        -- Check each slot in this table
        if assignedSpells[slotName] then
            for index, spell in pairs(assignedSpells[slotName]) do
                if content and content[index] then
                    -- Check if player has enough magicka to cast this spell
                    local canCast = hasEnoughMagickaToCast(spell, currentMagicka)
                    
                    -- Update appearance based on castability
                    if canCast then
                        -- Normal appearance for castable spells
                        content[index].props.alpha = 1.0
                        content[index].props.color = util.color.rgb(1.0, 1.0, 1.0)
                    else
                        -- Darker appearance for non-castable spells
                        content[index].props.alpha = 1.0
                        content[index].props.color = util.color.rgb(0.5, 0.5, 0.5)
                    end
                end
            end
        end
    end
end

-- Add this to your onUpdate function to regularly check spell castability
local function onUpdate(dt)
    -- Track current mouse button states
    local mouseButtonPressed = {
        input.isMouseButtonPressed(1), -- Left button
        input.isMouseButtonPressed(2), -- Middle button
        input.isMouseButtonPressed(3)  -- Right button
    }

    -- Update "just pressed" states
    for i = 1, 3 do
        if mouseButtonPressed[i] and not mouseButtonWasPressed[i] then
            mouseButtonJustPressed[i] = true
        else
            mouseButtonJustPressed[i] = false
        end
    end

    -- Update the previous states for the next frame
    for i = 1, 3 do
        mouseButtonWasPressed[i] = mouseButtonPressed[i]
    end

    -- Update the widgets or other persistent states as necessary
    updateWidgets()
    --updateStatusEffects()
    updateAllStackCounts()
    updateEquippedItemHighlight() -- Add this line to update equipped item highlights
    
    -- Update the equipped weapon and spell display
    updateEquippedDisplay()
    
    -- Update spell slot appearances based on current magicka
    updateSpellSlotAppearance()
end




local function onFrame(dt)
	
	-- Check if screen size has changed
	local currentScreen = ui.screenSize()
	if screenSize.x ~= currentScreen.x or screenSize.y ~= currentScreen.y then
		debug.reloadLua()
		print("Resolution changed, reloading Lua again...")
	end  

    if core.isWorldPaused() or (I.UI and I.UI.getMode()) or camera.getMode() == MODE.FirstPerson then
        element.layout.props.visible = false
        element:update()
        return
    end

    cursorPos = cursorPos + util.vector2(input.getMouseMoveX(), input.getMouseMoveY())
    local controllerCoef = math.min(screenSize.x, screenSize.y) * (dt * 1.5)
    cursorPos = cursorPos + util.vector2(
        input.getAxisValue(input.CONTROLLER_AXIS.MoveLeftRight),
        input.getAxisValue(input.CONTROLLER_AXIS.MoveForwardBackward)) * controllerCoef
    cursorPos = util.vector2(util.clamp(cursorPos.x, 0, screenSize.x), util.clamp(cursorPos.y, 0, screenSize.y))

    element.layout.props.relativePosition = cursorPos:ediv(ui.screenSize())
    element.layout.props.visible = true
    element:update()

    -- Handle intervention spell cooldown or delay
    if interventionPauseTime then
		if interventionPauseTime > 0 then
			interventionPauseTime = interventionPauseTime - dt  -- Decrease the pause time each frame
		elseif interventionPauseTime <= 0 then
			self.controls.use = 1
			interventionPauseTime = nil
		end
    end

    -- Check for cursor overlap
    local overlappingWidgets, overlappingSlots = checkCursorOverlap(cursorPos, 16)

    -- Handle widget interactions
    for _, widgetName in ipairs(overlappingWidgets) do
        if widgetName == "intervention_button" then
            if mouseButtonJustPressed[3] then
                toggleInterventionState(targetWidgets[widgetName].widget)
            elseif mouseButtonJustPressed[1] then
                setInterventionTimer()  -- Calls the function and sets the intervention pause time
            end
        elseif widgetName == "rest_button" then
            if mouseButtonJustPressed[1] then
                openRestWindow()
            end
        elseif widgetName == "class_button" then
            if mouseButtonJustPressed[1] then
                -- Open the stats screen when class button is clicked
                I.UI.setMode('Interface', {windows = {'Stats'}})
            end
        elseif widgetName == "melee_weapon" then
            if mouseButtonJustPressed[1] then
                -- Get the currently equipped weapon
                local equipment = types.Actor.getEquipment(self)
                local equippedWeapon = equipment and equipment[types.Actor.EQUIPMENT_SLOT.CarriedRight]
                
                if equippedWeapon then
                    -- Toggle weapon stance if theres a weapon equipped
                    if types.Actor.stance(self) == types.Actor.STANCE.Nothing then
                        types.Actor.setStance(self, types.Actor.STANCE.Weapon)
                        meleeMode = true
                    elseif types.Actor.stance(self) == types.Actor.STANCE.Weapon and meleeMode == false then
                        meleeMode = true
                    else
                        types.Actor.setStance(self, types.Actor.STANCE.Nothing)
                    end
                end
            end
            -- Removed right-click handler for assigning weapons
        elseif widgetName == "ranged_weapon" then
            if mouseButtonJustPressed[1] then
                -- Get the currently selected spell and enchanted item
                local selectedSpell = types.Actor.getSelectedSpell(self)
                local selectedEnchantedItem = types.Actor.getSelectedEnchantedItem(self)
                
                if selectedSpell then
                    -- Allow selecting the spell regardless of magicka
                    if types.Actor.stance(self) == types.Actor.STANCE.Nothing then
                        -- Always allow changing to spell stance
                        types.Actor.setStance(self, types.Actor.STANCE.Spell)
                    elseif types.Actor.stance(self) == types.Actor.STANCE.Spell then
                        -- Always allow switching back to nothing stance
                        types.Actor.setStance(self, types.Actor.STANCE.Nothing)
                    end
                    
                    -- Only show the warning if attempting to cast (spell stance) with insufficient magicka
                    if types.Actor.stance(self) == types.Actor.STANCE.Spell and selectedSpell.type == core.magic.SPELL_TYPE.Spell then
                        local actorStats = types.Actor.stats
                        local currentMagicka = actorStats.dynamic.magicka(self).current
                        
                        if currentMagicka < selectedSpell.cost then
                            ui.showMessage("Not enough magicka to cast " .. selectedSpell.name)
                        end
                    end
                elseif selectedEnchantedItem then
                    -- For enchanted items, allow selection but warn about charge
                    if types.Actor.stance(self) == types.Actor.STANCE.Nothing then
                        types.Actor.setStance(self, types.Actor.STANCE.Spell)
                    elseif types.Actor.stance(self) == types.Actor.STANCE.Spell then
                        types.Actor.setStance(self, types.Actor.STANCE.Nothing)
                    end
                    
                    -- Show charge warning if item is selected and has no charge
                    if types.Actor.stance(self) == types.Actor.STANCE.Spell then
                        local itemData = types.Item.itemData(selectedEnchantedItem)
                        
                        if itemData then
                            local itemType = getItemType(selectedEnchantedItem)
                            local record = types[itemType].record(selectedEnchantedItem)
                            
                            if record and record.enchant then
                                local enchantment = core.magic.enchantments.records[record.enchant]
                                if enchantment and enchantment.type == core.magic.ENCHANTMENT_TYPE.CastOnUse then
                                    -- Only warn if there's no charge and user is attempting to use it
                                    if not (itemData.enchantmentCharge and itemData.enchantmentCharge > 0) then
                                        ui.showMessage("This item has no charge left")
                                    end
                                end
                            end
                        end
                    end
                end
            end
            -- Removed right-click handler for assigning ranged weapons
        end
    end

    -- Handle slot interactions
    for _, slotInfo in ipairs(overlappingSlots) do
        if slotInfo.contentName == "actionSlotsContent1" or slotInfo.contentName == "actionSlotsContent2" then
            if mouseButtonJustPressed[3] then
				I.UI.registerWindow('QuickKeys', function()
					if not assignWindow then
						assignWindow = assignItemToSlot(slotInfo.contentName, slotInfo.index)
					end
				end,
				function()
					if assignWindow then
						currentTooltip:destroy()
						currentTooltip = nil
						assignWindow:destroy()
						assignWindow = nil
					end
				end)
				I.UI.setMode('QuickKeysMenu', {windows = {'QuickKeys'}})
            elseif mouseButtonJustPressed[1] then
                useAssignedItem(slotInfo.contentName, slotInfo.index)
            end
        elseif slotInfo.contentName == "spellSlotsContent1" or slotInfo.contentName == "spellSlotsContent2" then
            if mouseButtonJustPressed[3] then
				I.UI.registerWindow('QuickKeys', function()
					if not assignWindow then
						assignWindow = assignSpellToSlot(slotInfo.contentName, slotInfo.index)
					end
				end,
				function()
					if assignWindow then
						currentTooltip:destroy()
						currentTooltip = nil
						assignWindow:destroy()
						assignWindow = nil
					end
				end)
				I.UI.setMode('QuickKeysMenu', {windows = {'QuickKeys'}})
            elseif mouseButtonJustPressed[1] then
                castAssignedSpell(slotInfo.contentName, slotInfo.index)
            end
        elseif slotInfo.contentName == "miscContent1" or slotInfo.contentName == "miscContent2" then
            if mouseButtonJustPressed[3] then
                I.UI.registerWindow('QuickKeys', function()
                    if not assignWindow then
                        assignWindow = assignItemToSlot(slotInfo.contentName, slotInfo.index)
                    end
                end,
                function()
                    if assignWindow then
                        currentTooltip:destroy()
                        currentTooltip = nil
                        assignWindow:destroy()
                        assignWindow = nil
                    end
                end)
                I.UI.setMode('QuickKeysMenu', {windows = {'QuickKeys'}})
            elseif mouseButtonJustPressed[1] then
                useAssignedItem(slotInfo.contentName, slotInfo.index)
            end
        end
    end
end

local questIndex = 1

local function onQuestUpdate(A1_1_FindSpymaster, questIndex)
    print("new character, reloading lua")
    debug.reloadLua()
end


return {
	engineHandlers = 
    { 
		onFrame = onFrame,
        onUpdate = onUpdate,
        onQuestUpdate = onQuestUpdate,
		onSave = function()
            -- Create serializable versions of our assignment tables
            local serializedItems = {}
            for slotName, slots in pairs(assignedItems) do
                serializedItems[slotName] = {}
                for index, item in pairs(slots) do
                    -- Store the item's ID and type for reconstruction
                    serializedItems[slotName][index] = {
                        id = types[getItemType(item)].record(item).id,
                        type = getItemType(item)
                    }
                end
            end

            local serializedSpells = {}
            for slotName, slots in pairs(assignedSpells) do
                serializedSpells[slotName] = {}
                for index, spell in pairs(slots) do
                    -- Store the spell's ID
                    serializedSpells[slotName][index] = spell.id
                end
            end

            return {
                version = scriptVersion,
                cursorPos = cursorPos,
                items = serializedItems,
                spells = serializedSpells,
                interventionState = interventionButtonState
            }
        end,
        onLoad = function(data)
            if not data then return end

            if not data.version or data.version > scriptVersion then
                error('Save data is from a newer version of the script')
            end

            -- Restore cursor position
            if data.cursorPos then 
                cursorPos = data.cursorPos 
            end

            -- Restore intervention button state and color
            if data.interventionState then
                interventionButtonState = data.interventionState
                if interventionButtonState == "divine" then
                    targetWidgets.intervention_button.widget.props.resource = ui.texture({path = 'Textures/divine.png'})
                elseif interventionButtonState == "almsivi" then
                    targetWidgets.intervention_button.widget.props.resource = ui.texture({path = 'Textures/almsivi.png'})
                else -- recall
                    targetWidgets.intervention_button.widget.props.resource = ui.texture({path = 'Textures/recall.png'})
                end
            end

            -- Restore assigned items
            if data.items then
                assignedItems = {}
                for slotName, slots in pairs(data.items) do
                    -- Skip melee_weapon and ranged_weapon slots as they're no longer assignable
                    if slotName ~= "melee_weapon" and slotName ~= "ranged_weapon" then
                    assignedItems[slotName] = {}
                    for index, itemData in pairs(slots) do
                        -- Find the item in the player's inventory
                        local items = types.Actor.inventory(self.object):getAll(types[itemData.type])
                        for _, item in ipairs(items) do
                            if types[itemData.type].record(item).id == itemData.id then
                                assignedItems[slotName][index] = item
                                -- Update the slot's visual appearance
                                    local slotTable = _G[slotName]
                                    if slotTable and slotTable[index] then
                                        -- Update the slot icon
                                        slotTable[index].content[1].content[2].props.resource = ui.texture({ path = getItemIcon(item) })
                                        
                                        -- Check if the item is enchanted and update the magicIndicator visibility
                                        local itemData = types.Item.itemData(item)
                                        local isEnchanted = (itemData and itemData.enchantmentCharge ~= nil)
                                        if slotTable[index].content[1].content[1] then
                                            -- Check if the item is equipped
                                            local isEquipped = isItemEquipped(item)
                                            
                                            if isEnchanted then
                                                -- Set magicIndicator visibility and resource for enchanted items
                                                slotTable[index].content[1].content[1].props.visible = true
                                                slotTable[index].content[1].content[1].props.resource = ui.texture({ path = "textures\\menu_icon_magic_mini.dds" })
                                                -- Ensure proper positioning and sizing
                                                slotTable[index].content[1].content[1].props.relativeSize = util.vector2(0.85, 0.85)
                                                slotTable[index].content[1].content[1].props.relativePosition = util.vector2(0.5, 0.5)
                                                slotTable[index].content[1].content[1].props.anchor = util.vector2(0.5, 0.5)
                                                
                                                -- Update color based on equipped status
                                                if isEquipped then
                                                    slotTable[index].content[1].content[1].props.color = util.color.rgb(0, 1, 0)
                                                else
                                                    slotTable[index].content[1].content[1].props.color = util.color.rgb(1, 1, 1)
                                                end
                                            else
                                                -- For non-enchanted items
                                                if isEquipped then
                                                    -- Make indicator visible with slot.png for equipped non-enchanted items
                                                    slotTable[index].content[1].content[1].props.visible = true
                                                    -- Use slot.png for non-enchanted equipped items
                                                    slotTable[index].content[1].content[1].props.resource = ui.texture({ path = "Textures/slot.png" })
                                                    -- Ensure proper positioning and sizing to prevent cutoff
                                                    slotTable[index].content[1].content[1].props.relativeSize = util.vector2(1.0, 1.0)
                                                    slotTable[index].content[1].content[1].props.relativePosition = util.vector2(0.5, 0.5)
                                                    slotTable[index].content[1].content[1].props.anchor = util.vector2(0.5, 0.5)
                                                    -- Green color for equipped items - same as enchanted equipped items
                                                    slotTable[index].content[1].content[1].props.color = util.color.rgb(0, 1, 0)
                                                else
                                                    -- Hide indicator for non-enchanted, non-equipped items
                                                    slotTable[index].content[1].content[1].props.visible = false
                                                end
                                            end
                                        end
                                    end
                                break
                                end
                            end
                        end
                    end
                end
            end

            -- Call the function to update the weapon and spell displays after loading
            updateEquippedDisplay()
            
            -- Call the function to update equipped item highlights
            updateEquippedItemHighlight()

            -- Restore assigned spells
            if data.spells then
                assignedSpells = {}
                local playerSpells = types.Actor.spells(self.object)
                for slotName, slots in pairs(data.spells) do
                    assignedSpells[slotName] = {}
                    for index, spellId in pairs(slots) do
                        -- Find the spell in the player's spell list
                        for _, spell in ipairs(playerSpells) do
                            if spell.id == spellId then
                                assignedSpells[slotName][index] = spell
                                -- Update the slot's visual appearance with big icon
                                local slotTable = _G[slotName]
                                if slotTable and slotTable[index] then
                                    local iconPath = spell.effects[1].effect.icon
                                    local bigIconPath = iconPath:gsub("icons\\s\\", "icons\\s\\b_")
                                    slotTable[index].props.resource = ui.texture({ path = bigIconPath })
                                end
                                break
                            end
                        end
                    end
                end
            end
            
            -- Update stack counts after loading
            updateAllStackCounts()
        end,
    },
	
    interfaceName = "MMUI_ACTIONBAR",
    interface = {
        hideAllUI = hideAllUI,
        showAllUI = showAllUI,
    },
}