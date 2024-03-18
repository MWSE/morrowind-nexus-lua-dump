---@diagnostic disable: undefined-field, undefined-doc-name

local translations = {}

local function onDialogueGetText(e)
	local info = e.info
	if (info.type == tes3.dialogueType.voice or info.type == tes3.dialogueType.journal) then return end

	local translatedText = translations[info.id];
	if translatedText ~= nil and translatedText ~= '' then
		e.text = translatedText .. "\n\n" .. e:loadOriginalText()
	end
end

local function onBookGetText(e)
	local translatedText = translations[e.book.id];
	if translatedText ~= nil and translatedText ~= '' then
		e.text = translations[e.book.id] .. "<br>";
	else
		mwse.log(string.format("Couldn't find translation for %s", e.book.id))
	end
end

local function loadDialogueTranslation(previousLine, line)
	local key = string.match(previousLine, "[^<]*^([%d]+)</key>")
	if key ~= nil then
		translations[key] = line
	end
end

local function loadBookTranslation(previousLine, line)
	local key = string.match(previousLine, "<key>(.-)</key>")
	if key ~= nil then
		translations[key] = line
	end
end

local function loadTranslationFile()
	local file = assert(io.open("Data Files/Translations/ENtoPL.txt", "r"))
	local previousLine = ""
	for line in file:lines() do
		if (string.find(previousLine, "bk_") or string.find(string.lower(previousLine), "bookskill_")) then
			loadBookTranslation(previousLine, line)
		elseif (string.find(previousLine, "<key>")) then
			loadDialogueTranslation(previousLine, line)
		end
		previousLine = line
	end
	file:close()
end

local function init()
	event.register(tes3.event.infoGetText, onDialogueGetText)
	event.register(tes3.event.bookGetText, onBookGetText)
	loadTranslationFile();
	mwse.log(string.format("Translator loaded."))
end

event.register(tes3.event.initialized, init)
