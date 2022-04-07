local common = {}

local function loadTranslation()
	-- Get the ISO language code.
	local language = tes3.getLanguage()

	-- Load the dictionaries, and start off with English.
	local dictionaries = dofile("MTArmor.translations")
	local dictionary = dictionaries[language]

	-- If we aren't doing English, copy over missing entries.
	if (language ~= "eng") then
		table.copymissing(dictionary, dictionaries["eng"])
	end
	-- Set the dictionary.
	return dictionary
end

common.dictionary = loadTranslation()

return common