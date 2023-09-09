local logger = require("logging.logger")
local config = require("livebookediting.config").config

local log = logger.new({
	name = "livebookediting",
	--outputFile = "livebookediting.log",
	logLevel = config.logLevel,
})

local util = require("livebookediting.util")
dofile("livebookediting.mcm")


local i18n = mwse.loadTranslations("livebookediting")
local id = util.id
local paths = {
	book = tes3.installDirectory .. "\\data files\\booktext.txt",
	scroll = tes3.installDirectory .. "\\data files\\scrolltext.txt",
}

--- Reads the contents of a text file and returns it as a string.
--- Also returns true if the text is missing <br> at the end.
---@param path string
---@return string
local function loadFile(path)
	if not lfs.fileexists(path) then
		log:error("Couldn't open file at: \"%s\"", path)
		return i18n("defaultText")
	end
	local file = io.open(path, "r")
	if not file then
		log:error("Couldn't open file at: \"%s\"", path)
		return i18n("defaultText")
	end
	local buffer = tostring(file:read("*a"))
	file:close()
	log:debug("Read from %s:\n%s", path, buffer)

	return buffer
end

--- Checks if there is missing \<br> statement at the end.
--- Will show a messageBox if it is missing.
---@param text string
local function checkMissingLineBreak(text)
	local ending = text:trim():sub(-4, -1):lower()
	if ending ~= "<br>" then
		tes3.messageBox(i18n("missingLineBreakText"))
	end
end

---@alias livebookeditingBookType
---| "book"
---| "scroll"

--- Opens the book or scroll with text from text file. Performs checks if
--- there is missing \<br> statement at the end.
---@param bookType livebookeditingBookType
local function showText(bookType)
	local text = loadFile(paths[bookType])

	checkMissingLineBreak(text)
	if bookType == "book" then
		tes3ui.showBookMenu(text)
	elseif bookType == "scroll" then
		tes3ui.showScrollMenu(text)
	end
end


---@param e keyDownEventData
local function openBook(e)
	local equal = tes3.isKeyEqual({
		actual = e,
		expected = config.bookKey
	})
	if not equal then return end

	showText("book")
end
event.register(tes3.event.keyDown, openBook, { filter = config.bookKey.keyCode })

---@param e keyDownEventData
local function openScrool(e)
	local equal = tes3.isKeyEqual({
		actual = e,
		expected = config.scrollKey
	})
	if not equal then return end

	showText("scroll")
end
event.register(tes3.event.keyDown, openScrool, { filter = config.scrollKey.keyCode })


---@param e bookGetTextEventData
local function onGetText(e)
	local bookid = e.book.id
	if bookid == id.book then
		local text = loadFile(paths.book)
		checkMissingLineBreak(text)
		e.text = text
	elseif bookid == id.scroll then
		local text = loadFile(paths.scroll)
		checkMissingLineBreak(text)
		e.text = text
	end
end
event.register(tes3.event.bookGetText, onGetText)

---@param e loadedEventData|nil
local function addItems(e)
	-- Wait until chargen is finished.
	if e and e.newGame then return end

	if config.addBook then
		util.addItem("book")
	end
	if config.addScroll then
		util.addItem("scroll")
	end
end
event.register(tes3.event.charGenFinished, addItems)
event.register(tes3.event.loaded, addItems)
