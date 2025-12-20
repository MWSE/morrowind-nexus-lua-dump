local self=require('openmw.self')
local types = require('openmw.types')
local core = require("openmw.core")
local nearby = require('openmw.nearby')

local posInfo = {
    cell=self.cell.id,
    position=self.position,
    rotation=self.rotation
}

local function activateSorter(actor)
	if self.recordId=="cst_sort_scrolls" then  --write here your activator record id
		if actor.type==types.Player then
			core.sendGlobalEvent("runAutoSort", {
				actor=actor,
				autoSortObject=self.object,
				posInfo=posInfo,
                sortType = "scrolls",
                cellInfo = "Castany Manor, Study",
                containerInfo = "cst_scrolls"
			})
		end
	end
end


return {
	engineHandlers = {	onActivated=activateSorter
	}

}