local interfaces = require('openmw.interfaces')

local l10nKey = 'raffll_limits'
local settingsPageKey = 'SPL'

interfaces.Settings.registerPage({
	key = settingsPageKey,
	l10n = l10nKey,
	name = 'Stats & Potions Limit',
	description = 'Stats & Potions Limit OpenMW Lua addon configuration.',
})