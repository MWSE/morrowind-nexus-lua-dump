local core = require("openmw.core")
local l10n = core.l10n("MoveLikeThis")

MLTConstants = {}

MLTConstants.CleaveBonusRangeTypes = {
	none = 1,
	default = 2,
}

MLTConstants.CleaveRangeVals = {
	[MLTConstants.CleaveBonusRangeTypes.none] = l10n("SelectNone"),
	[MLTConstants.CleaveBonusRangeTypes.default] = l10n("SelectDefault"),
}

MLTConstants.CleaveRangeDefault = MLTConstants.CleaveRangeVals[MLTConstants.CleaveBonusRangeTypes.default]

MLTConstants.CleaveType = {
	none = 1,
	normal = 2,
	improved = 3,
}

MLTConstants.CleaveTypeVals = {
	[MLTConstants.CleaveType.none] = l10n("SelectNone"),
	[MLTConstants.CleaveType.normal] = l10n("CleaveNormal"),
	[MLTConstants.CleaveType.improved] = l10n("CleaveImproved"),
}

MLTConstants.CleaveTypeDefaultNorm = MLTConstants.CleaveTypeVals[MLTConstants.CleaveType.normal]
MLTConstants.CleaveTypeDefaultImp = MLTConstants.CleaveTypeVals[MLTConstants.CleaveType.improved]

MLTConstants.SBSlash = {
	none = 1,
	mobility = 2,
	blind = 3,
	cleave = 4,
	cleaveImp = 5,
}

MLTConstants.SBSlashVals = {
	[MLTConstants.SBSlash.none] = l10n("SlashSelectMobil"),
	[MLTConstants.SBSlash.mobility] = l10n("SlashSelectMobil"),
	[MLTConstants.SBSlash.blind] = l10n("SlashSelectBlind"),
	[MLTConstants.SBSlash.cleave] = l10n("CleaveNormal"),
	[MLTConstants.SBSlash.cleaveImp] = l10n("CleaveImproved"),
}

MLTConstants.SBSlashDefault = MLTConstants.SBSlashVals[MLTConstants.SBSlash.mobility]

MLTConstants.H2HSlashDefault = MLTConstants.SBSlashVals[MLTConstants.SBSlash.none]

MLTConstants.BWSlash = {
	armorPierce = 1,
	cleave = 2,
	cleaveImp = 3,
}

MLTConstants.BWSlashVals = {
	[MLTConstants.BWSlash.armorPierce] = l10n("SlashSelectPierce"),
	[MLTConstants.BWSlash.cleave] = l10n("CleaveNormal"),
	[MLTConstants.SBSlash.cleaveImp] = l10n("CleaveImproved"),
}

MLTConstants.BWSlashDefault = MLTConstants.BWSlashVals[MLTConstants.BWSlash.armorPierce]

return MLTConstants