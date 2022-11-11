-- try and fix keys not marked to be detected /abot

event.register('modConfigReady',
	function ()
		local tes3_objectType_miscItem = tes3.objectType.miscItem
		for _, obj in ipairs(tes3.dataHandler.nonDynamicData.objects) do
			if obj.objectType == tes3_objectType_miscItem then
				if not obj.isKey then
					if obj.id:lower():find('key') then
						obj.isKey = true
					end
				end
			end
		end
	end, {doOnce = true}
)