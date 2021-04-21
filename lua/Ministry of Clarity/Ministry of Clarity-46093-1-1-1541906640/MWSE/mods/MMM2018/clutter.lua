--[[ 
	Checks each reference in the cell against groups of items and
	enables/disables them depending on if the given global for that 
	group has reached the required value
]]--
local debug = false
local function debugMessage(string)
	if debug then
		tes3.messageBox(string)
		mwse.log("[radiant common: DEBUG] " .. string)
	end
end

local function enableClutter(e)
	local clutterData = mwse.loadConfig("radiantQuests/clutterData")
  	for ref in e.cell:iterateReferences() do
    	for i,global in ipairs(clutterData.globals) do
      		local currentGlobalValue = tes3.getGlobal(global.id)
      		for i,group in ipairs(global.groups) do
				--enable item groups 
        		if currentGlobalValue >= group.value then
          			for i,itemId in ipairs(group.itemIds) do
						if ref.object.id == itemId then
							mwscript.enable({ reference = ref })
							debugMessage("Cell: " .. e.cell.id .. ", Enabling " .. ref.id)
						end
					end
				--disable item groups
				else
          			for i,itemId in ipairs(group.itemIds) do
						if ref.object.id == itemId then
							mwscript.disable({ reference = ref })
							debugMessage("Cell: " .. e.cell.id .. ", Disabling " .. ref.id)
						end
					end						
				end
        	end
      	end
    end
end

event.register("cellChanged", enableClutter, { filter = tes3.getCell{ id = "Vivec, Ministry of Clarity" } } )
event.register("cellChanged", enableClutter, { filter = tes3.getCell{ id = "Ministry of Clarity: Headquarters" } } )