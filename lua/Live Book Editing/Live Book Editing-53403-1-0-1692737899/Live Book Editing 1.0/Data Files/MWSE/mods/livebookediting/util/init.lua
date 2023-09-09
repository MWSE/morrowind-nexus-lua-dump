local log = require("logging.logger").getLogger("livebookediting") --[[@as mwseLogger]]

local i18n = mwse.loadTranslations("livebookediting")
---@type table<string, tes3book>
local items = {
	---@diagnostic disable
	book = -1,
	scroll = -1,
	---@diagnostic enable
}

local util = {
	id = {
		book = "c3pa_booktextedit",
		scroll = "c3pa_scrolltextedit",
	}
}

local function onInitialized()
	items.book = tes3.createObject({
		id = util.id.book,
		objectType = tes3.objectType.book,
		name = "Preview your book's text",
		mesh = "m\\text_octavo_08.nif",
		icon = "m\\tx_book_02.tga",
		text = i18n("defaultText"),
		type = tes3.bookType.book,
		value = 1,
		weight = 0,
	})
	items.scroll = tes3.createObject({
		id = util.id.scroll,
		objectType = tes3.objectType.book,
		name = "Preview your scroll's text",
		mesh = "m\\text_parchment_01.nif",
		icon = "m\\tx_parchment_01.tga",
		text = i18n("defaultText"),
		type = tes3.bookType.scroll,
		value = 1,
		weight = 0,
	})
end
event.register(tes3.event.initialized, onInitialized)

--- Adds a preview book of given type to the player.
---@param bookType livebookeditingBookType
---@return boolean added
function util.addItem(bookType)
	if not tes3.player then
		tes3.messageBox(i18n("loadNeeded"))
		return false
	end

	local inventory = tes3.player.object.inventory
	local book = items[bookType]
	if not inventory:contains(book) then
		tes3.addItem({
			reference = tes3.player,
			item = book,
			showMessage = true,
		})
		return true
	else
		tes3.messageBox(i18n("alreadyAdded"))
		return false
	end
end

return util
