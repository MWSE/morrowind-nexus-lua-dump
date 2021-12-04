local mod = "BTBGI Tweaks"
local version = "2.0.8 Rev 3"

local data = dofile("BTBGITweaks.data")

local function onInitialized()

    -- Iterate through our data table.
    for _, dataObject in ipairs(data.objects) do

        -- Get the corresponding game object.
        local object = tes3.getObject(dataObject.id)

		-- For each individual stat, if a stat tweak is present, apply it. Else, keep the vanilla value.
        if object then
			if dataObject.value ~= nil then
				object.value = dataObject.value
			end
        end
    end

    mwse.log("[%s %s] Initialized.", mod, version)
end

event.register("initialized", onInitialized)