-- effects whose dummy spell will NOT be auto-created at runtime.
-- vanilla effects still use their pre-built enchantdummy_<id> spell from the omwaddon.
-- this list only affects custom magic effects added by other mods.
-- ids are lowercase, matching MagicEffect.id.

return {
	["restoremagicka"] = true,
	["fortifymaximummagicka"] = true,
}
