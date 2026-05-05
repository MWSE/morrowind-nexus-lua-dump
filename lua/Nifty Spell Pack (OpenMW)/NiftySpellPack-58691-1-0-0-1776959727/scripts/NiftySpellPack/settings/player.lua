local I = require('openmw.interfaces')
local core = require('openmw.core')

local l10n = core.l10n('NiftySpellPack')

local VERSION = "1.0.0"

I.Settings.registerPage {
	key = 'NiftySpellPack',
	l10n = 'NiftySpellPack',
	name = 'ConfigTitle',
	description = l10n('ConfigSummary', { version = VERSION }),
}