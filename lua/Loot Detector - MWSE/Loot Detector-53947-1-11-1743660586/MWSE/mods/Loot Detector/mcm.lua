--local i18n = mwse.loadTranslations('Loot Detector')
local config = require('Loot Detector.config')

local template = mwse.mcm.createTemplate('Loot Detector')
template:saveOnClose('Loot Detector', config)

local page1 = template:createSideBarPage()
page1.label = 'Detect'
page1.description = ''
page1.noScroll = false

local page2 = template:createSideBarPage()
page2.label = 'Size'
page2.description = ''
page2.noScroll = false

local page3 = template:createSideBarPage()
page3.label = 'Distantion'
page3.description = ''
page3.noScroll = false

local page4 = template:createSideBarPage()
page4.label = 'Values'
page4.description = ''
page4.noScroll = false

local category0 = page1:createCategory('Setting')
local category1 = page1:createCategory('Detect (Normal)')
local category11 = page1:createCategory('Detect (Owner)')
local category2 = page2:createCategory('Icons size (Normal)')
local category21 = page2:createCategory('Icons size (Owner)')
local category3 = page3:createCategory('Icons view distance (Normal)')
local category31 = page3:createCategory('Icons view distance (Owner)')
local category4 = page4:createCategory('Cost/Value of items (Normal)')
local category41 = page4:createCategory('Cost/Value of items (Owner)')

local key = category0:createKeyBinder {
    label = 'Show/Hide Icons',
    description = '',
    variable = mwse.mcm.createTableVariable {id = 'key', table = config},
    allowCombinations = false,
}

keyBL = category0:createKeyBinder {
    label = 'Add/Remove Cell to Blacklist',
    description = 'Icons will not be displayed in cells added to the blacklist.\nThis is necessary in order to, for example, hide icons in your home.\n\nHow to use:\nWhile in a cell, press the assigned key and the cell will be added to the black list.\nPressing the key again will remove the cell from the black list.',
    variable = mwse.mcm.createTableVariable {id = 'keyBL', table = config},
    allowCombinations = false,
}

template:createExclusionsPage{
	label = "Blacklist",
	description = "Icons will not be displayed in cells added to the blacklist.\nThis is necessary in order to, for example, hide icons in your home.\n\nHow to use:\nWhile in a cell, press the assigned key and the cell will be added to the black list.\nPressing the key again will remove the cell from the black list.",
	leftListLabel = "Blacklisted Cells",
	variable = mwse.mcm.createTableVariable{
		id = "CellsBL",
		table = config,
	},
	filters = {
		{
			label = "Cells",
			callback = function()
				local cellList = {}
				for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
					table.insert(cellList, cell.id:lower())
				end
				table.sort(cellList)
				return cellList
			end
		},
	},
}

local UpdateSpeed = category0:createDecimalSlider({
	label = 'Icons update speed in sec.',
	description = 'Icon refresh rate.\nIt is not recommended to set too low a value, FPS drop!\nOptimal values from 0.5 to 1.0.\n\nDefault: 1.0.',
	min = 0.01,
	max = 10.00,
	step = 0.01,
	jump = 0.1,
	variable = mwse.mcm.createTableVariable{id = 'UpdateSpeed', table = config },
})

local ClearPreviousCell = category0:createOnOffButton({
	label = 'Clear previous cell from icons',
	description = 'Remove icons from the previous cell when you move to a new cell.\nNecessary for optimization and to prevent the screen from becoming cluttered with multiple icons.\n\nDefault: On.',
	variable = mwse.mcm:createTableVariable{id = 'ClearPreviousCell', table = config}
})

local ShowZeroValueItem = category0:createOnOffButton({
	label = 'Show items with zero value',
	description = 'Shows items that have zero value.\n\nDefault: On.',
	variable = mwse.mcm:createTableVariable{id = 'ShowZeroValueItem', table = config}
})

GoldWithoutValue = category0:createOnOffButton({
	label = 'Gold without "Values" (Normal)',
	description = 'Ignore "Values" settings when displaying gold.\nGold will be displayed even if there is 1 coin.\n\nDefault: Off.',
	variable = mwse.mcm:createTableVariable{id = 'GoldWithoutValue', table = config}
})

GoldWithoutValueOwner = category0:createOnOffButton({
	label = 'Gold without "Values" (Owner)',
	description = 'Ignore "Values" settings when displaying gold.\nGold will be displayed even if there is 1 coin.\n\nDefault: Off.',
	variable = mwse.mcm:createTableVariable{id = 'GoldWithoutValueOwner', table = config}
})

LockContainerValue = category0:createOnOffButton({
	label = 'Closed containers with "Values" (Normal)',
	description = 'This is an analogue of the "Closed containers" option, only taking into account your "Values" settings.\nWith this option, closed containers will be visible if they contain suitable (valuable) loot.\n\nATTENTION:\nWhen this option is enabled, the "Closed containers" setting is ignored!\nAlso taken into account is the option "Gold without "Values"", which will forcefully show a closed container with gold inside.\n\nDefault: Off.',
	variable = mwse.mcm:createTableVariable{id = 'LockContainerValue', table = config}
})

LockContainerValueOwner = category0:createOnOffButton({
	label = 'Closed containers with "Values" (Owner)',
	description = 'This is an analogue of the "Closed containers" option, only taking into account your "Values" settings.\nWith this option, closed containers will be visible if they contain suitable (valuable) loot.\n\nATTENTION:\nWhen this option is enabled, the "Closed containers" setting is ignored!\nAlso taken into account is the option "Gold without "Values"", which will forcefully show a closed container with gold inside.\n\nDefault: Off.',
	variable = mwse.mcm:createTableVariable{id = 'LockContainerValueOwner', table = config}
})
--////////////////////////////////////////////////////////////////////////////////////////

local ClosedDoorOn = category1:createOnOffButton({
	label = 'Closed doors',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ClosedDoorOn', table = config}
})

local ClosedContainerOn = category1:createOnOffButton({
	label = 'Closed containers',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ClosedContainerOn', table = config}
})

local ContainerOn = category1:createOnOffButton({
	label = 'Open containers',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ContainerOn', table = config}
})

local OrganicOn = category1:createOnOffButton({
	label = 'Organic containers',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'OrganicOn', table = config}
})

local NpcOn = category1:createOnOffButton({
	label = 'NPC',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'NpcOn', table = config}
})

local CreatureOn = category1:createOnOffButton({
	label = 'Creature',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'CreatureOn', table = config}
})

local ItemLightOn = category1:createOnOffButton({
	label = 'Light',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ItemLightOn', table = config}
})

local ItemBookOn = category1:createOnOffButton({
	label = 'Book',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ItemBookOn', table = config}
})

local ItemAlchemyOn = category1:createOnOffButton({
	label = 'Alchemy',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ItemAlchemyOn', table = config}
})

local ItemAmmunitionOn = category1:createOnOffButton({
	label = 'Ammunition',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ItemAmmunitionOn', table = config}
})

local ItemApparatusOn = category1:createOnOffButton({
	label = 'Apparatus',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ItemApparatusOn', table = config}
})

local ItemArmorOn = category1:createOnOffButton({
	label = 'Armor',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ItemArmorOn', table = config}
})

local ItemClothingOn = category1:createOnOffButton({
	label = 'Clothing',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ItemClothingOn', table = config}
})

local ItemEnchantmentOn = category1:createOnOffButton({
	label = 'Enchantment',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ItemEnchantmentOn', table = config}
})

local ItemIngredientOn = category1:createOnOffButton({
	label = 'Ingredient',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ItemIngredientOn', table = config}
})

local ItemLockpickOn = category1:createOnOffButton({
	label = 'Lockpick',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ItemLockpickOn', table = config}
})

local ItemMiscItemOn = category1:createOnOffButton({
	label = 'Misc item',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ItemMiscItemOn', table = config}
})

local ItemProbeOn = category1:createOnOffButton({
	label = 'Probe',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ItemProbeOn', table = config}
})

local ItemRepairItemOn = category1:createOnOffButton({
	label = 'Repair item',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ItemRepairItemOn', table = config}
})

local ItemSpellOn = category1:createOnOffButton({
	label = 'Spell',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ItemSpellOn', table = config}
})

local ItemWeaponOn = category1:createOnOffButton({
	label = 'Weapon',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ItemWeaponOn', table = config}
})

local ClosedDoorOwner = category11:createOnOffButton({
	label = 'Closed doors',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ClosedDoorOwner', table = config}
})

local ClosedContainerOwner = category11:createOnOffButton({
	label = 'Closed containers',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ClosedContainerOwner', table = config}
})

local ContainerOwner = category11:createOnOffButton({
	label = 'Open containers',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ContainerOwner', table = config}
})

local OrganicOwner = category11:createOnOffButton({
	label = 'Organic containers',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'OrganicOwner', table = config}
})

local ItemLightOwner = category11:createOnOffButton({
	label = 'Light',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ItemLightOwner', table = config}
})

local ItemBookOwner = category11:createOnOffButton({
	label = 'Book',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ItemBookOwner', table = config}
})

local ItemAlchemyOwner = category11:createOnOffButton({
	label = 'Alchemy',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ItemAlchemyOwner', table = config}
})

local ItemAmmunitionOwner = category11:createOnOffButton({
	label = 'Ammunition',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ItemAmmunitionOwner', table = config}
})

local ItemApparatusOwner = category11:createOnOffButton({
	label = 'Apparatus',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ItemApparatusOwner', table = config}
})

local ItemArmorOwner = category11:createOnOffButton({
	label = 'Armor',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ItemArmorOwner', table = config}
})

local ItemClothingOwner = category11:createOnOffButton({
	label = 'Clothing',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ItemClothingOwner', table = config}
})

local ItemEnchantmentOwner = category11:createOnOffButton({
	label = 'Enchantment',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ItemEnchantmentOwner', table = config}
})

local ItemIngredientOwner = category11:createOnOffButton({
	label = 'Ingredient',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ItemIngredientOwner', table = config}
})

local ItemLockpickOwner = category11:createOnOffButton({
	label = 'Lockpick',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ItemLockpickOwner', table = config}
})

local ItemMiscItemOwner = category11:createOnOffButton({
	label = 'Misc item',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ItemMiscItemOwner', table = config}
})

local ItemProbeOwner = category11:createOnOffButton({
	label = 'Probe',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ItemProbeOwner', table = config}
})

local ItemRepairItemOwner = category11:createOnOffButton({
	label = 'Repair item',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ItemRepairItemOwner', table = config}
})

local ItemSpellOwner = category11:createOnOffButton({
	label = 'Spell',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ItemSpellOwner', table = config}
})

local ItemWeaponOwner = category11:createOnOffButton({
	label = 'Weapon',
	description = '',
	variable = mwse.mcm:createTableVariable{id = 'ItemWeaponOwner', table = config}
})

--////////////////////////////////////////////////////////////////////////////////////////

local AllSize = category2:createDecimalSlider({
	label = 'SET ALL (Normal)(in game only)',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'AllSize', table = config },
})

local ClosedDoorSize = category2:createDecimalSlider({
	label = 'Closed doors',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ClosedDoorSize', table = config },
})

local ClosedContainerSize = category2:createDecimalSlider({
	label = 'Closed containers',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ClosedContainerSize', table = config },
})

local ContainerSize = category2:createDecimalSlider({
	label = 'Open containers',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ContainerSize', table = config },
})

local OrganicSize = category2:createDecimalSlider({
	label = 'Organic containers',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'OrganicSize', table = config },
})

local NpcSize = category2:createDecimalSlider({
	label = 'NPC',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'NpcSize', table = config },
})

local CreatureSize = category2:createDecimalSlider({
	label = 'Creature',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'CreatureSize', table = config },
})

local ItemLightSize = category2:createDecimalSlider({
	label = 'Light',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ItemLightSize', table = config },
})

local ItemBookSize = category2:createDecimalSlider({
	label = 'Book',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ItemBookSize', table = config },
})

local ItemAlchemySize = category2:createDecimalSlider({
	label = 'Alchemy',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ItemAlchemySize', table = config },
})

local ItemAmmunitionSize = category2:createDecimalSlider({
	label = 'Ammunition',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ItemAmmunitionSize', table = config },
})

local ItemApparatusSize = category2:createDecimalSlider({
	label = 'Apparatus',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ItemApparatusSize', table = config },
})

local ItemArmorSize = category2:createDecimalSlider({
	label = 'Armor',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ItemArmorSize', table = config },
})

local ItemClothingSize = category2:createDecimalSlider({
	label = 'Clothing',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ItemClothingSize', table = config },
})

local ItemEnchantmentSize = category2:createDecimalSlider({
	label = 'Enchantment',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ItemEnchantmentSize', table = config },
})

local ItemIngredientSize = category2:createDecimalSlider({
	label = 'Ingredient',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ItemIngredientSize', table = config },
})

local ItemLockpickSize = category2:createDecimalSlider({
	label = 'Lockpick',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ItemLockpickSize', table = config },
})

local ItemMiscItemSize = category2:createDecimalSlider({
	label = 'Misc item',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ItemMiscItemSize', table = config },
})

local ItemProbeSize = category2:createDecimalSlider({
	label = 'Probe',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ItemProbeSize', table = config },
})

local ItemRepairItemSize = category2:createDecimalSlider({
	label = 'Repair item',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ItemRepairItemSize', table = config },
})

local ItemSpellSize = category2:createDecimalSlider({
	label = 'Spell',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ItemSpellSize', table = config },
})

local ItemWeaponSize = category2:createDecimalSlider({
	label = 'Weapon',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ItemWeaponSize', table = config },
})

local AllSizeOwner = category21:createDecimalSlider({
	label = 'SET ALL (Owner)(in game only)',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'AllSizeOwner', table = config },
})

local ClosedDoorOwnerSize = category21:createDecimalSlider({
	label = 'Closed doors',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ClosedDoorOwnerSize', table = config },
})

local ClosedContainerOwnerSize = category21:createDecimalSlider({
	label = 'Closed containers',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ClosedContainerOwnerSize', table = config },
})

local ContainerOwnerSize = category21:createDecimalSlider({
	label = 'Open containers',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ContainerOwnerSize', table = config },
})

local OrganicOwnerSize = category21:createDecimalSlider({
	label = 'Organic containers',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'OrganicOwnerSize', table = config },
})

local ItemLightOwnerSize = category21:createDecimalSlider({
	label = 'Light',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ItemLightOwnerSize', table = config },
})

local ItemBookOwnerSize = category21:createDecimalSlider({
	label = 'Book',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ItemBookOwnerSize', table = config },
})

local ItemAlchemyOwnerSize = category21:createDecimalSlider({
	label = 'Alchemy',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ItemAlchemyOwnerSize', table = config },
})

local ItemAmmunitionOwnerSize = category21:createDecimalSlider({
	label = 'Ammunition',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ItemAmmunitionOwnerSize', table = config },
})

local ItemArmorOwnerSize = category21:createDecimalSlider({
	label = 'Armor',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ItemArmorOwnerSize', table = config },
})

local ItemClothingOwnerSize = category21:createDecimalSlider({
	label = 'Clothing',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ItemClothingOwnerSize', table = config },
})

local ItemEnchantmentOwnerSize = category21:createDecimalSlider({
	label = 'Enchantment',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ItemEnchantmentOwnerSize', table = config },
})

local ItemIngredientOwnerSize = category21:createDecimalSlider({
	label = 'Ingredient',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ItemIngredientOwnerSize', table = config },
})

local ItemLockpickOwnerSize = category21:createDecimalSlider({
	label = 'Lockpick',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ItemLockpickOwnerSize', table = config },
})

local ItemMiscItemOwnerSize = category21:createDecimalSlider({
	label = 'Misc item',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ItemMiscItemOwnerSize', table = config },
})

local ItemProbeOwnerSize = category21:createDecimalSlider({
	label = 'Probe',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ItemProbeOwnerSize', table = config },
})

local ItemRepairItemOwnerSize = category21:createDecimalSlider({
	label = 'Repair item',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ItemRepairItemOwnerSize', table = config },
})

local ItemSpellOwnerSize = category21:createDecimalSlider({
	label = 'Spell',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ItemSpellOwnerSize', table = config },
})

local ItemWeaponOwnerSize = category21:createDecimalSlider({
	label = 'Weapon',
	description = '',
	min = 0.05,
	max = 0.25,
	step = 0.01,
	jump = 0.05,
	variable = mwse.mcm.createTableVariable{id = 'ItemWeaponOwnerSize', table = config },
})

--////////////////////////////////////////////////////////////////////////////////////////

local AllDist = category3:createSlider({
	label = 'SET ALL (Normal)(in game only)',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'AllDist', table = config },
})

local ClosedDoorDist = category3:createSlider({
	label = 'Closed doors',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ClosedDoorDist', table = config },
})

local ClosedContainerDist = category3:createSlider({
	label = 'Closed containers',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ClosedContainerDist', table = config },
})

local ContainerDist = category3:createSlider({
	label = 'Open containers',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ContainerDist', table = config },
})

local OrganicDist = category3:createSlider({
	label = 'Organic containers',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'OrganicDist', table = config },
})

local NpcDist = category3:createSlider({
	label = 'NPC',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'NpcDist', table = config },
})

local CreatureDist = category3:createSlider({
	label = 'Creature',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'CreatureDist', table = config },
})

local ItemLightDist = category3:createSlider({
	label = 'Light',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ItemLightDist', table = config },
})

local ItemBookDist = category3:createSlider({
	label = 'Book',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ItemBookDist', table = config },
})

local ItemAlchemyDist = category3:createSlider({
	label = 'Alchemy',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ItemAlchemyDist', table = config },
})

local ItemAmmunitionDist = category3:createSlider({
	label = 'Ammunition',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ItemAmmunitionDist', table = config },
})

local ItemApparatusDist = category3:createSlider({
	label = 'Apparatus',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ItemApparatusDist', table = config },
})

local ItemArmorDist = category3:createSlider({
	label = 'Armor',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ItemArmorDist', table = config },
})

local ItemClothingDist = category3:createSlider({
	label = 'Clothing',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ItemClothingDist', table = config },
})

local ItemEnchantmentDist = category3:createSlider({
	label = 'Enchantment',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ItemEnchantmentDist', table = config },
})

local ItemIngredientDist = category3:createSlider({
	label = 'Ingredient',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ItemIngredientDist', table = config },
})

local ItemLockpickDist = category3:createSlider({
	label = 'Lockpick',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ItemLockpickDist', table = config },
})

local ItemMiscItemDist = category3:createSlider({
	label = 'Misc item',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ItemMiscItemDist', table = config },
})

local ItemProbeDist = category3:createSlider({
	label = 'Probe',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ItemProbeDist', table = config },
})

local ItemRepairItemDist = category3:createSlider({
	label = 'Repair item',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ItemRepairItemDist', table = config },
})

local ItemSpellDist = category3:createSlider({
	label = 'Spell',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ItemSpellDist', table = config },
})

local ItemWeaponDist = category3:createSlider({
	label = 'Weapon',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ItemWeaponDist', table = config },
})

local AllDistOwner = category31:createSlider({
	label = 'SET ALL (Owner)(in game only)',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'AllDistOwner', table = config },
})

local ClosedDoorOwnerDist = category31:createSlider({
	label = 'Closed doors',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ClosedDoorOwnerDist', table = config },
})

local ClosedContainerOwnerDist = category31:createSlider({
	label = 'Closed containers',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ClosedContainerOwnerDist', table = config },
})

local ContainerOwnerDist = category31:createSlider({
	label = 'Open containers',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ContainerOwnerDist', table = config },
})

local OrganicOwnerDist = category31:createSlider({
	label = 'Organic containers',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'OrganicOwnerDist', table = config },
})

local ItemLightOwnerDist = category31:createSlider({
	label = 'Light',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ItemLightOwnerDist', table = config },
})

local ItemBookOwnerDist = category31:createSlider({
	label = 'Book',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ItemBookOwnerDist', table = config },
})

local ItemAlchemyOwnerDist = category31:createSlider({
	label = 'Alchemy',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ItemAlchemyOwnerDist', table = config },
})

local ItemAmmunitionOwnerDist = category31:createSlider({
	label = 'Ammunition',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ItemAmmunitionOwnerDist', table = config },
})

local ItemApparatusOwnerDist = category31:createSlider({
	label = 'Apparatus',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ItemApparatusOwnerDist', table = config },
})

local ItemArmorOwnerDist = category31:createSlider({
	label = 'Armor',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ItemArmorOwnerDist', table = config },
})

local ItemClothingOwnerDist = category31:createSlider({
	label = 'Clothing',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ItemClothingOwnerDist', table = config },
})

local ItemEnchantmentOwnerDist = category31:createSlider({
	label = 'Enchantment',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ItemEnchantmentOwnerDist', table = config },
})

local ItemIngredientOwnerDist = category31:createSlider({
	label = 'Ingredient',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ItemIngredientOwnerDist', table = config },
})

local ItemLockpickOwnerDist = category31:createSlider({
	label = 'Lockpick',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ItemLockpickOwnerDist', table = config },
})

local ItemMiscItemOwnerDist = category31:createSlider({
	label = 'Misc item',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ItemMiscItemOwnerDist', table = config },
})

local ItemProbeOwnerDist = category31:createSlider({
	label = 'Probe',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ItemProbeOwnerDist', table = config },
})

local ItemRepairItemOwnerDist = category31:createSlider({
	label = 'Repair item',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ItemRepairItemOwnerDist', table = config },
})

local ItemSpellOwnerDist = category31:createSlider({
	label = 'Spell',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ItemSpellOwnerDist', table = config },
})

local ItemWeaponOwnerDist = category31:createSlider({
	label = 'Weapon',
	description = '',
	min = 256,
	max = 9999999,
	step = 1,
	jump = 256,
	variable = mwse.mcm.createTableVariable{id = 'ItemWeaponOwnerDist', table = config },
})

--////////////////////////////////////////////////////////////////////////////////////////

local AllValue = category4:createSlider({
	label = 'SET ALL (Normal)(in game only)',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'AllValue', table = config },
})

local ContainerValueConf = category4:createSlider({
	label = 'From containers: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'ContainerValueConf', table = config },
})

local ContainerValue = category4:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'ContainerValue', table = config },
})

local OrganicValueConf = category4:createSlider({
	label = 'From organic containers: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'OrganicValueConf', table = config },
})

local OrganicValue = category4:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'OrganicValue', table = config },
})

local NpcValueConf = category4:createSlider({
	label = 'From NPC: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'NpcValueConf', table = config },
})

local NpcValue = category4:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'NpcValue', table = config },
})

local CreatureValueConf = category4:createSlider({
	label = 'From creatures: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'CreatureValueConf', table = config },
})

local CreatureValue = category4:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'CreatureValue', table = config },
})

local ItemLightValueConf = category4:createSlider({
	label = 'Items lights: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'ItemLightValueConf', table = config },
})

local ItemLightValue = category4:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'ItemLightValue', table = config },
})

local ItemBookValueConf = category4:createSlider({
	label = 'Items books: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'ItemBookValueConf', table = config },
})

local ItemBookValue = category4:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'ItemBookValue', table = config },
})

local ItemAlchemyValueConf = category4:createSlider({
	label = 'Items alchemys: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'ItemAlchemyValueConf', table = config },
})

local ItemAlchemyValue = category4:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'ItemAlchemyValue', table = config },
})

local ItemAmmunitionValueConf = category4:createSlider({
	label = 'Items ammunitions: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'ItemAmmunitionValueConf', table = config },
})

local ItemAmmunitionValue = category4:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'ItemAmmunitionValue', table = config },
})

local ItemApparatusValueConf = category4:createSlider({
	label = 'Items apparatus: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'ItemApparatusValueConf', table = config },
})

local ItemApparatusValue = category4:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'ItemApparatusValue', table = config },
})

local ItemArmorValueConf = category4:createSlider({
	label = 'Items armors: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'ItemArmorValueConf', table = config },
})

local ItemArmorValue = category4:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'ItemArmorValue', table = config },
})

local ItemClothingValueConf = category4:createSlider({
	label = 'Items clothings: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'ItemClothingValueConf', table = config },
})

local ItemClothingValue = category4:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'ItemClothingValue', table = config },
})

local ItemEnchantmentValueConf = category4:createSlider({
	label = 'Items enchantments: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'ItemEnchantmentValueConf', table = config },
})

local ItemEnchantmentValue = category4:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'ItemEnchantmentValue', table = config },
})

local ItemIngredientValueConf = category4:createSlider({
	label = 'Items ingredients: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'ItemIngredientValueConf', table = config },
})

local ItemIngredientValue = category4:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'ItemIngredientValue', table = config },
})

local ItemLockpickValueConf = category4:createSlider({
	label = 'Items lockpicks: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'ItemLockpickValueConf', table = config },
})

local ItemLockpickValue = category4:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'ItemLockpickValue', table = config },
})

local ItemMiscItemValueConf = category4:createSlider({
	label = 'Misc items: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'ItemMiscItemValueConf', table = config },
})

local ItemMiscItemValue = category4:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'ItemMiscItemValue', table = config },
})

local ItemProbeValueConf = category4:createSlider({
	label = 'Items probes: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'ItemProbeValueConf', table = config },
})

local ItemProbeValue = category4:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'ItemProbeValue', table = config },
})

local ItemRepairItemValueConf = category4:createSlider({
	label = 'Repair items: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'ItemRepairItemValueConf', table = config },
})

local ItemRepairItemValue = category4:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'ItemRepairItemValue', table = config },
})

local ItemSpellValueConf = category4:createSlider({
	label = 'Items spells: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'ItemSpellValueConf', table = config },
})

local ItemSpellValue = category4:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'ItemSpellValue', table = config },
})

local ItemWeaponValueConf = category4:createSlider({
	label = 'Items weapons: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'ItemWeaponValueConf', table = config },
})

local ItemWeaponValue = category4:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'ItemWeaponValue', table = config },
})

local AllValueOwner = category41:createSlider({
	label = 'SET ALL (Owner)(in game only)',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'AllValueOwner', table = config },
})

local ContainerOwnerValueConf = category41:createSlider({
	label = 'From containers: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'ContainerOwnerValueConf', table = config },
})

local ContainerOwnerValue = category41:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'ContainerOwnerValue', table = config },
})

local OrganicOwnerValueConf = category41:createSlider({
	label = 'From organic containers: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'OrganicOwnerValueConf', table = config },
})

local OrganicOwnerValue = category41:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'OrganicOwnerValue', table = config },
})

local ItemLightOwnerValueConf = category41:createSlider({
	label = 'Items lights: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'ItemLightOwnerValueConf', table = config },
})

local ItemLightOwnerValue = category41:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'ItemLightOwnerValue', table = config },
})

local ItemBookOwnerValueConf = category41:createSlider({
	label = 'Items books: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'ItemBookOwnerValueConf', table = config },
})

local ItemBookOwnerValue = category41:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'ItemBookOwnerValue', table = config },
})

local ItemAlchemyOwnerValueConf = category41:createSlider({
	label = 'Items alchemys: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'ItemAlchemyOwnerValueConf', table = config },
})

local ItemAlchemyOwnerValue = category41:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'ItemAlchemyOwnerValue', table = config },
})

local ItemAmmunitionOwnerValueConf = category41:createSlider({
	label = 'Items ammunitios: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'ItemAmmunitionOwnerValueConf', table = config },
})

local ItemAmmunitionOwnerValue = category41:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'ItemAmmunitionOwnerValue', table = config },
})

local ItemApparatusOwnerValueConf = category41:createSlider({
	label = 'Items apparatus: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'ItemApparatusOwnerValueConf', table = config },
})

local ItemApparatusOwnerValue = category41:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'ItemApparatusOwnerValue', table = config },
})

local ItemArmorOwnerValueConf = category41:createSlider({
	label = 'Items armors: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'ItemArmorOwnerValueConf', table = config },
})

local ItemArmorOwnerValue = category41:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'ItemArmorOwnerValue', table = config },
})

local ItemClothingOwnerValueConf = category41:createSlider({
	label = 'Items clothings: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'ItemClothingOwnerValueConf', table = config },
})

local ItemClothingOwnerValue = category41:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'ItemClothingOwnerValue', table = config },
})

ItemEnchantmentOwnerValueConf = category41:createSlider({
	label = 'Items enchantments: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'ItemEnchantmentOwnerValueConf', table = config },
})

ItemEnchantmentOwnerValue = category41:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'ItemEnchantmentOwnerValue', table = config },
})

ItemIngredientOwnerValueConf = category41:createSlider({
	label = 'Items ingredients: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'ItemIngredientOwnerValueConf', table = config },
})

ItemIngredientOwnerValue = category41:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'ItemIngredientOwnerValue', table = config },
})

ItemLockpickOwnerValueConf = category41:createSlider({
	label = 'Items lockpicks: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'ItemLockpickOwnerValueConf', table = config },
})

ItemLockpickOwnerValue = category41:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'ItemLockpickOwnerValue', table = config },
})

ItemMiscItemOwnerValueConf = category41:createSlider({
	label = 'Misc items: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'ItemMiscItemOwnerValueConf', table = config },
})

ItemMiscItemOwnerValue = category41:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'ItemMiscItemOwnerValue', table = config },
})

ItemProbeOwnerValueConf = category41:createSlider({
	label = 'Items probes: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'ItemProbeOwnerValueConf', table = config },
})

ItemProbeOwnerValue = category41:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'ItemProbeOwnerValue', table = config },
})

ItemRepairItemOwnerValueConf = category41:createSlider({
	label = 'Repair items: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'ItemRepairItemOwnerValueConf', table = config },
})

ItemRepairItemOwnerValue = category41:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'ItemRepairItemOwnerValue', table = config },
})

ItemSpellOwnerValueConf = category41:createSlider({
	label = 'Items spells: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'ItemSpellOwnerValueConf', table = config },
})

ItemSpellOwnerValue = category41:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'ItemSpellOwnerValue', table = config },
})

ItemWeaponOwnerValueConf = category41:createSlider({
	label = 'Items weapons: 0 - Value, 1 - Value/Weight',
	description = '',
	min = 0,
	max = 1,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = 'ItemWeaponOwnerValueConf', table = config },
})

ItemWeaponOwnerValue = category41:createSlider({
	label = 'Min',
	description = '',
	min = 0,
	max = 100000,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = 'ItemWeaponOwnerValue', table = config },
})

mwse.mcm.register(template)