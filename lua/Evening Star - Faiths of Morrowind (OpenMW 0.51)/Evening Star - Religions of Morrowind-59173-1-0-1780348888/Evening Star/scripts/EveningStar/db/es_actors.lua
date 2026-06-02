-- ------------------------------ actor category sets ----------------------
-- groups of actor recordIds (lowercase, exact match) referenced by deity
-- favorKills.recordIdSet and tabooKills.recordIdSet. lookups are map-style
-- (id -> true), so each category is a hash set.

ES = ES or {}
ES.DB = ES.DB or {}

ES.DB.actors = {
	-- blighted creatures (vanilla). listed explicitly because some ids use a
	-- space rather than underscore (e.g. "nix-hound blighted") and miss the
	-- "_blighted" / "blighted_" substring patterns on the deity record.
	blighted = {
		["cliff racer_blighted"] = true,
		["alit_blighted"]        = true,
		["kagouti_blighted"]     = true,
		["nix-hound blighted"]   = true,
		["rat_blighted"]         = true,
		["shalk_blighted"]       = true,
	},
}
