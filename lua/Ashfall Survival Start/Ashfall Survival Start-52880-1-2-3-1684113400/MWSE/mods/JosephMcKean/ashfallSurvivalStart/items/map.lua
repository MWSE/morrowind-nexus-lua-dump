---@param e uiEventEventData
local function onUiEvent(e)
	if not tes3.player then
		return
	end
	if not tes3.player.cell then
		return
	end
	if not tes3.player.cell.id:startswith("Masartus") then
		return
	end
	if tes3.player.data.ass and tes3.player.data.ass.hasMap then
		return
	end
	local menu = tes3ui.findMenu("MenuMap")
	if not menu then
		return
	end
	if not menu.visible then
		return
	end
	local worldMap = menu:findChild(tes3ui.registerID("MenuMap_world"))
	worldMap.visible = false
end
event.register("uiEvent", onUiEvent)

---@param e bookGetTextEventData
local function readMap(e)
	if not e.book then
		return
	end
	if e.book.id ~= "jsmk_ass_bk_map" then
		return
	end
	tes3.player.data.ass.hasMap = true
	if tes3.player.data.ass.hasRaft then
		tes3.updateJournal({ id = "jsmk_ass", index = 50, showMessage = true })
	else
		tes3.updateJournal({ id = "jsmk_ass", index = 40, showMessage = true })
	end
end
event.register("bookGetText", readMap)
