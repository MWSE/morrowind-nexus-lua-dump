local I = require('openmw.interfaces')
local o = require('scripts.knockback.settingsObject').o

local MOD_NAME = 'Knockback'
local prefix = 'SettingsPlayer'
local sectionKey = prefix .. MOD_NAME

I.Settings.registerPage {
        key = MOD_NAME,
        l10n = MOD_NAME,
        name = MOD_NAME,
        description = "Allows knocking enemies back"
}

I.Settings.registerGroup {
        key = sectionKey,
        l10n = MOD_NAME,
        name = MOD_NAME,
        page = MOD_NAME,
        permanentStorage = true,
        settings = {
                {
                        key = o.showTrail.key,
                        name = o.showTrail.name,
                        default = o.showTrail.default,
                        renderer = "checkbox",
                },
                {
                        key = o.knockbackMagnitude.key,
                        name = o.knockbackMagnitude.name,
                        default = o.knockbackMagnitude.default,
                        description = o.knockbackMagnitude.description,
                        renderer = "number",
                },
                {
                        key = o.bounceAmount.key,
                        name = o.bounceAmount.name,
                        default = o.bounceAmount.default,
                        description = o.bounceAmount.description,
                        renderer = "number",
                },
                {
                        key = o.verticalKnockFactor.key,
                        name = o.verticalKnockFactor.name,
                        default = o.verticalKnockFactor.default,
                        description = o.verticalKnockFactor.description,
                        renderer = "number",
                },
                {
                        key = o.adjustByAttackPower.key,
                        name = o.adjustByAttackPower.name,
                        default = o.adjustByAttackPower.default,
                        description = o.adjustByAttackPower.description,
                        renderer = "checkbox",
                },
                {
                        key = o.maxBounces.key,
                        name = o.maxBounces.name,
                        default = o.maxBounces.default,
                        description = o.maxBounces.description,
                        renderer = "number",
                },
        }

}
