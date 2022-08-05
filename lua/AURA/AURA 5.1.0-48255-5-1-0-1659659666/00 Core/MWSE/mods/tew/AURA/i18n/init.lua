-- DO NOT MODIFY THIS --
------------------------------------------------------------------------------------------------

mwse.log("[AURA i18n]: Starting translation verification.")

local defaultLanguage = require("tew.AURA.i18n.en")
local config = require("tew.AURA.config")
local language = require(config.language)

for i, cat in pairs(defaultLanguage) do
	if not language[i] then
		language[i] = defaultLanguage[i]
	else
		for ii, _ in pairs(cat) do
			if (not language[i][ii])
				or (language[i][ii] == "")
				or (language[i][ii] == {}) then
				language[i][ii] = defaultLanguage[i][ii]
			end
		end
	end
end

mwse.log("[AURA i18n]: Translation verified. Missing values have been filled in with defaults.")
