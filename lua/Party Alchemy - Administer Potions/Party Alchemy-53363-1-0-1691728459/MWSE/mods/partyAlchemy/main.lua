--[[
    Party Alchemy
    By Shanjaq
--]]

local function addPAFlask()
	local menu = tes3ui.findMenu(tes3ui.registerID("MenuDialog"))
	if not menu then return end

	local companionShareButton = menu:findChild("MenuDialog_service_companion")
	if not companionShareButton then return end

	companionShareButton:register("mouseClick", function(e)
    --local menu = tes3ui.findMenu(tes3ui.registerID("MenuDialog"))
    local companion = tes3ui.getServiceActor()
    local count = mwscript.getItemCount{reference=companion.reference, item="misc_pa_flask"}
    if count == 0 then
        mwscript.addItem({ reference=companion.reference, item="misc_pa_flask", count=1 })
    elseif count > 1 then
        mwscript.removeItem({ reference=companion.reference, item="misc_pa_flask", count=(count-1) })
    end
    e.source:forwardEvent(e)
	end)
end

event.register("initialized", function()
    -- load modules
    dofile("partyAlchemy.partyalch")
    event.register("uiActivated", addPAFlask, { filter = "MenuDialog" })
end)
