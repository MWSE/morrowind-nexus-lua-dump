local I = require("openmw.interfaces")
local MLTConstants = require ("scripts.MoveLikeThis.constants")
local core = require("openmw.core")
local l10n = core.l10n("MoveLikeThis")


I.Settings.registerGroup {
    key = "Settings_MoveLikeThis",
    page = "MoveLikeThis",
    l10n = "MoveLikeThis",
    name = "ModSettingsName",
    description = "ModSettingsDescription",
    permanentStorage = true,
    settings = {
		-- General
		{key = "PlayerAdvantage", name = "SettingsPlayerAdvantage", renderer = "checkbox", default = true, description = l10n("SettingsPlayerAdvantageDesc", {default = "true"})},
		{key = "CleaveRangeBonus", name = "SettingsCleaveExtension", renderer = "select", default = MLTConstants.CleaveRangeDefault, description = l10n("SettingsCleaveExtensionDesc",  {default = MLTConstants.CleaveRangeDefault}), argument = {
			l10n = "MoveLikeThis",
			items = MLTConstants.CleaveRangeVals
		}},
		-- Long Blade
		{key = "LB1H_CleaveType", name = "LB1H_SettingsCleave", renderer = "select", default = MLTConstants.CleaveTypeDefaultNorm, description = "SettingsCleaveType", argument = {
			l10n = "MoveLikeThis",
			items = MLTConstants.CleaveTypeVals
		}},
		{key = "LB1H_CritChance", name = "LB1H_SettingsCritChance", renderer = "number", default = 20, description = l10n("CritChanceDesc", {default = 20})},
		{key = "LB1H_CritMult", name = "LB1H_SettingsCritMult", renderer = "number", default = 2, description = l10n("CritMultDesc", {default = 2})},
		{key = "LB2H_CleaveType", name = "LB1H_SettingsCleave", renderer = "select", default = MLTConstants.CleaveTypeDefaultNorm, description = "SettingsCleaveType", argument = {
			l10n = "MoveLikeThis",
			items = MLTConstants.CleaveTypeVals
		}},
		{key = "LB2H_CritChance", name = "LB2H_SettingsCritChance", renderer = "number", default = 20, description = l10n("CritChanceDesc", {default = 20})},
		{key = "LB2H_CritMult", name = "LB2H_SettingsCritMult", renderer = "number", default = 3, description = l10n("CritMultDesc", {default = 3})},
		-- Short Blade
		{key = "SB1H_SlashType", name = l10n("SB1H_SettingsSlashType", {default = MLTConstants.SBSlashDefault}), renderer = "select", default = MLTConstants.SBSlashDefault, description = "SB1H_SlashTypeDesc", argument = {
			l10n = "MoveLikeThis",
			items = MLTConstants.SBSlashVals
		}},
		{key = "SB1H_CritChance", name = "SB1H_SettingsCritChance", renderer = "number", default = 30, description = l10n("CritChanceDesc", {default = 30})},
		{key = "SB1H_CritMult", name = "SB1H_SettingsCritMult", renderer = "number", default = 2.5, description = l10n("CritMultDesc", {default = 2.5})},
		-- Blunt
		{key = "BW_SlashType", name = l10n("BW_SettingsSlashType", {default = MLTConstants.BWSlashDefault}), renderer = "select", default = MLTConstants.BWSlashDefault, description = "BW_SlashTypeDesc", argument = {
			l10n = "MoveLikeThis",
			items = MLTConstants.BWSlashVals
		}},
		{key = "BW1H_ArmorPierce", name = "BW1H_SettingsArmorPierce", renderer = "number", default = 0.5, description = l10n("ArmorPierceDesc", {default = 0.5})},
		{key = "BW1H_StaggerChance", name = "BW1H_SettingsStaggerChance", renderer = "number", default = 10, description = l10n("StaggerChanceDesc", {default = 20})},
		{key = "BW2H_ArmorPierce", name = "BW2H_SettingsArmorPierce", renderer = "number", default = 0.5, description = l10n("ArmorPierceDesc", {default = 0.5})},
		{key = "BW2H_StaggerChance", name = "BW2H_SettingsStaggerChance", renderer = "number", default = 20, description = l10n("StaggerChanceDesc", {default = 30})},
		-- Staff
		{key = "BW2HW_FatigueDamage", name = "BW2HW_SettingsFatigueDamage", renderer = "number", default = 1, description = l10n("BW2HW_SettingsFatigueDamageDesc", {default = 1})},
		{key = "BW2HW_StompDamage", name = "BW2HW_SettingsStompDamage", renderer = "number", default = 1.5, description = l10n("SettingsStompDamageDesc", {default = 1.5})},
		{key = "BW2HW_CleaveType", name = "BW2HW_SettingsCleave", renderer = "select", default = MLTConstants.CleaveTypeDefaultImp, description = "SettingsImprovedCleaveType", argument = {
			l10n = "MoveLikeThis",
			items = MLTConstants.CleaveTypeVals
		}},
		{key = "BW2HW_StaggerChance", name = "BW2HW_SettingsStaggerChance", renderer = "number", default = 60, description = l10n("StaggerChanceDesc", {default = 60})},
		--Axe
		{key = "AX1H_ShieldBreak", name = "AX1H_SettingsShieldBreak", renderer = "number", default = 1, description = l10n("SettingsShieldBreakDesc", {default = 1})},
		{key = "AX1H_CleaveType", name = "AX1H_SettingsCleave", renderer = "select", default = MLTConstants.CleaveTypeDefaultImp, description = "SettingsImprovedCleaveType", argument = {
			l10n = "MoveLikeThis",
			items = MLTConstants.CleaveTypeVals
		}},
		{key = "AX2H_ShieldBreak", name = "AX2H_SettingsShieldBreak", renderer = "number", default = 1, description = l10n("SettingsShieldBreakDesc", {default = 1})},
		{key = "AX2H_CleaveType", name = "AX2H_SettingsCleave", renderer = "select", default = MLTConstants.CleaveTypeDefaultImp, description = "SettingsImprovedCleaveType", argument = {
			l10n = "MoveLikeThis",
			items = MLTConstants.CleaveTypeVals
		}},
		--Spear
		{key = "SP2H_FirstStrike", name = "SP2H_SettingsFirstStrike", renderer = "number", default = 1.5, description = l10n("SettingsFirstStrikeDesc", {default = 1.5})},
		{key = "SP2H_CleaveType", name = "SP2H_SettingsCleave", renderer = "select", default = MLTConstants.CleaveTypeDefaultNorm, description = "SettingsCleaveType", argument = {
			l10n = "MoveLikeThis",
			items = MLTConstants.CleaveTypeVals
		}},
		-- Hand to Hand
		{key = "H2H_StompDamage", name = "H2H_SettingsStompDamage", renderer = "number", default = 1.5, description = l10n("SettingsStompDamageDesc", {default = 1.5})},
		{key = "H2H_SlashType", name = l10n("H2H_SettingsSlashType", {default = MLTConstants.H2HSlashDefault}), renderer = "select", default = MLTConstants.H2HSlashDefault, description = "H2H_SlashTypeDesc", argument = {
			l10n = "MoveLikeThis",
			items = MLTConstants.SBSlashVals
		}},
		{key = "H2H_CritChance", name = "H2H_SettingsCritChance", renderer = "number", default = 20, description = l10n("CritChanceDesc", {default = 20})},
		{key = "H2H_CritMult", name = "H2H_SettingsCritMult", renderer = "number", default = 2, description = l10n("CritMult2Desc", {default = 2})},
		
		{key = "COMP_NgardePierce", name = "COMP_SettingsNgardePierce", renderer = "checkbox", default = true, description = l10n("COMP_SettingsNgardePierceDesc", {default = "true"})},
		{key = "COMP_NgardeCanPPArryAxe", name = "COMP_SettingsNgardeCanPPArryAxe", renderer = "checkbox", default = false, description = l10n("COMP_SettingsNgardeCanPPArryAxeDesc", {default = "false"})},
    },
}
