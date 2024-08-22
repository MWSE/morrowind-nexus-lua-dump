--[[ 
	Checks each reference in the cell against groups of items and
	enables/disables them depending on if the given global for that 
	group has reached the required value
]]--
local debug = false
local function debugMessage(string)
	if debug then
		tes3.messageBox(string)
		mwse.log("[Demon of Knowledge: DEBUG] " .. string)
	end
end

local function enableClutter(e)
	if not tes3.getPlayerCell().id:find("Район Побережья Азуры") then
		return
	end

	local clutterData = mwse.loadConfig("mmm2018/sx2/clutter")
  	
    for i,journal in ipairs(clutterData.journalIndex) do
	    local currentJournalIndex = tes3.getJournalIndex({ id = journal.id })
		for i,group in ipairs(journal.groups) do
			for i, cell in ipairs( tes3.getActiveCells() ) do
				for ref in cell:iterateReferences() do
			
				--enable item groups 
					if currentJournalIndex and currentJournalIndex >= group.value then
					
						for i,itemId in ipairs(group.itemIds) do
							if ref.object.id == itemId then
								mwscript.enable({ reference = ref })
								debugMessage("Cell: " .. cell.id .. ", Enabling " .. ref.id)
							end

						end
					--disable item groups
					else
						for i,itemId in ipairs(group.itemIds) do
							if ref.object.id == itemId then
								mwscript.disable({ reference = ref })
								debugMessage("JID: " .. journal.id .. "Cell: " .. cell.id .. ", Disabling " .. ref.id)
							end

						end										
					end
				end
			end
		end
    end
end

event.register("cellChanged", enableClutter)