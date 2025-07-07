local async = require('openmw.async')
local core = require('openmw.core')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local ui = require('openmw.ui')

local l10n = core.l10n('QuickStack')
local commonData = require("scripts.QuickStack.commonData")
local versionString = commonData.metadata.version

local items = { "Verbose", "Simple" }

-- inputKeySelection by Pharis

-- TODO: How to make it so that "combo" keys (shift + V) can be used for keybinds?
I.Settings.registerRenderer('QuickStack/inputKeySelection', function(value, set)
	local name = commonData.config.keybinds.placeholder
	if value then
		name = input.getKeyName(value)
	end
	return {
		template = I.MWUI.templates.box,
		content = ui.content {
			{
				template = I.MWUI.templates.padding,
				content = ui.content {
					{
						template = I.MWUI.templates.textEditLine,
						props = {
							text = name,
						},
						events = {
							keyPress = async:callback(function(e)
								if e.code == input.KEY.Escape then return end
								set(e.code)
							end),
						},
					},
				},
			},
		},
	}
end)

-- Settings page
I.Settings.registerPage {
    key = commonData.metadata.modId,
    l10n = commonData.metadata.modId,
    name = commonData.config.title,
    description = commonData.config.description,
}

I.Settings.registerGroup {
    key = commonData.config.options.key,
    page = commonData.metadata.modId,
    l10n = commonData.metadata.modId,
    name = commonData.config.categoryOptions,
    permanentStorage = true,
    settings = {
		{
            key = commonData.config.options.itemRestrictionGold.key,
            renderer = 'checkbox',
            name = commonData.config.options.itemRestrictionGold.label,
			description = commonData.config.options.itemRestrictionGold.description,
			default = false
        },
		{
            key = commonData.config.options.enableCompanionStacking.key,
            renderer = 'checkbox',
            name = commonData.config.options.enableCompanionStacking.label,
			description = commonData.config.options.enableCompanionStacking.description,
			default = true
        },
        {
            key = commonData.config.options.distanceHorizontal.key,
            renderer = 'number',
            name = commonData.config.options.distanceHorizontal.label,
			description = commonData.config.options.distanceHorizontal.description,
			integer = true,
			min = 100,
			max = 1000,
            default = 250,
        },
		{
            key = commonData.config.options.distanceVertical.key,
            renderer = 'number',
            name = commonData.config.options.distanceVertical.label,
			description = commonData.config.options.distanceVertical.description,
			integer = true,
			min = 10,
			max = 1000,
            default = 100,
        },
		{
            key = commonData.config.options.transferAnimation.key,
            renderer = 'checkbox',
            name = commonData.config.options.transferAnimation.label,
			description = commonData.config.options.transferAnimation.description,
			default = true
        },
		{
            key = commonData.config.options.transferAnimationDuration.key,
            renderer = 'number',
            name = commonData.config.options.transferAnimationDuration.label,
			description = commonData.config.options.transferAnimationDuration.description,
			integer = true,
            default = 10,
        },
		{
            key = commonData.config.options.successNotificationEnabled.key,
            renderer = 'checkbox',
            name = commonData.config.options.successNotificationEnabled.label,
			description = commonData.config.options.successNotificationEnabled.description,
			default = true
        },
		{
            key = commonData.config.options.successNotificationType.key,
            renderer = 'select',
            name = commonData.config.options.successNotificationType.label,
			description = commonData.config.options.successNotificationType.description,
			argument = { 
                items = {commonData.config.options.successNotificationType.items.verbose, commonData.config.options.successNotificationType.items.simple},
                l10n = commonData.metadata.modId,
            },
			default = commonData.config.options.successNotificationType.items.verbose
        },
		{
            key = commonData.config.options.successVerboseNotificationAutoCloseDuration.key,
            renderer = 'number',
            name = commonData.config.options.successVerboseNotificationAutoCloseDuration.label,
			description = commonData.config.options.successVerboseNotificationAutoCloseDuration.description,
			integer = true,
            default = 10,
        },
		{
            key = commonData.config.options.failureNotificationEnabled.key,
            renderer = 'checkbox',
            name = commonData.config.options.failureNotificationEnabled.label,
			description = commonData.config.options.failureNotificationEnabled.description,
			default = false
        },
    },
}

I.Settings.registerGroup {
    key = commonData.config.keybinds.key,
    page = commonData.metadata.modId,
    l10n = commonData.metadata.modId,
    name = commonData.config.categoryKeybinds,
    permanentStorage = true,
    settings = {
        {
            key = 'keybindStack',
            name = commonData.config.keybinds.stackLabel,
			renderer = 'QuickStack/inputKeySelection',
			description = commonData.config.keybinds.stackDescription,
            default = input.KEY.V,

        }
    },
}