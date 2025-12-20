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
	if self.recordId=="cst_sort_alch" then  --write here your activator record id
		if actor.type==types.Player then
			core.sendGlobalEvent("runAutoSort", {
				actor=actor,
				autoSortObject=self.object,
				posInfo=posInfo,
				sortType = "alch",
				cellInfo = "Castany Manor, Study",
                containerInfo = "cst_alch_ing"
			})
		end
	end
end


return {
	engineHandlers = {	onActivated=activateSorter
	}

}