-- DO NOT MODIFY THIS --
------------------------------------------------------------------------------------------------

mwse.log("[AURA i18n]: Starting translation verification.")

local defaultLanguage = require("tew.AURA.i18n.en")
local config = require("tew.AURA.config")
local language = require(config.language)

table.copymissing(language, defaultLanguage)

-- This is some super silly stuff nicked from official MWSE i18n, but gets the job done, at least for FR
local function convertUTF8Table(t, lang)
	for k, v in pairs(t) do
		local vType = type(v)
		if (vType == "string") then
			--- @diagnostic disable-next-line:undefined-field
			t[k] = mwse.iconv(lang, v)
		elseif (vType == "table") then
			convertUTF8Table(v, lang)
		end
	end
end

convertUTF8Table(language, "eng")


mwse.log("[AURA i18n]: Translation verified. Missing values have been filled in with defaults.")
