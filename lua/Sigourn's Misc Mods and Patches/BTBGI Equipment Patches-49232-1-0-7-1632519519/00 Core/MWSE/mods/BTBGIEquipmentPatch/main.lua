local mod = "BTBGI Equipment Patch"
local version = "1.0"

local data = require("BTBGIEquipmentPatch.data")

local function onInitialized()

    -- Iterate through our data table.
    for _, dataObject in ipairs(data.objects) do

        -- Get the corresponding game object.
        local object = tes3.getObject(dataObject.id)

        -- If this object exists in the game, change its stats to match our table.
		-- For each individual stat, if a stat tweak is present, apply it. Else, keep the vanilla value.
        if object then
			if dataObject.name ~= nil then
				object.name = dataObject.name
			end
			if dataObject.value ~= nil then
				object.value = dataObject.value
			end
			if dataObject.health ~= nil then
				object.maxCondition = dataObject.health
			end
			if dataObject.weight ~= nil then
				object.weight = dataObject.weight
			end
			if dataObject.armour ~= nil then
				object.armorRating = dataObject.armour
			end
			if dataObject.enchCap ~= nil then
				object.enchantCapacity = dataObject.enchCap
			end
			if dataObject.ignoresNormalWeaponResistance ~= nil then
				object.ignoresNormalWeaponResistance = dataObject.ignoresNormalWeaponResistance
			end
			if dataObject.silver ~= nil then
				object.isSilver = dataObject.silver
			end
			if dataObject.chopMin ~= nil then
				object.chopMin = dataObject.chopMin
			end
			if dataObject.chopMax ~= nil then
				object.chopMax = dataObject.chopMax
			end
			if dataObject.slashMin ~= nil then
				object.slashMin = dataObject.slashMin
			end
			if dataObject.slashMax ~= nil then
				object.slashMax = dataObject.slashMax
			end	
			if dataObject.thrustMin ~= nil then
				object.thrustMin = dataObject.thrustMin
			end
			if dataObject.thrustMax ~= nil then
				object.thrusthMax = dataObject.thrustMax
			end		
        end
    end

    mwse.log("[%s %s] Initialized.", mod, version)
end

event.register("initialized", onInitialized)