local function waterCurrent()
    local playerCell = tes3.getPlayerCell()
    for ref in playerCell:iterateReferences(tes3.objectType.static) do

        if ref.baseObject.id == "0s_wc_up_f" then
            local mobileList = tes3.findActorsInProximity{
                reference = ref,
                range = 420
            }
            for _, mobile in ipairs(mobileList) do
                if mobile.isSwimming then
                    mobile.position.z = mobile.position.z + 5
                end
            end

        elseif ref.baseObject.id == "0s_wc_down_f" then
            local mobileList = tes3.findActorsInProximity{
                reference = ref,
                range = 420
            }
            for _, mobile in ipairs(mobileList) do
                if mobile.isSwimming then
                    mobile.position.z = mobile.position.z - 5
                end
            end

        elseif ref.baseObject.id == "0s_wc_east_f" then
            local mobileList = tes3.findActorsInProximity{
                reference = ref,
                range = 420
            }
            for _, mobile in ipairs(mobileList) do
                if mobile.isSwimming then
                    mobile.position.x = mobile.position.x + 5
                end
            end

        elseif ref.baseObject.id == "0s_wc_north_f" then
            local mobileList = tes3.findActorsInProximity{
                reference = ref,
                range = 420
            }
            for _, mobile in ipairs(mobileList) do
                if mobile.isSwimming then
                    mobile.position.y = mobile.position.y + 5
                end
            end

        elseif ref.baseObject.id == "0s_wc_south_f" then
            local mobileList = tes3.findActorsInProximity{
                reference = ref,
                range = 420
            }
            for _, mobile in ipairs(mobileList) do
                if mobile.isSwimming then
                    mobile.position.y = mobile.position.y - 5
                end
            end

        elseif ref.baseObject.id == "0s_wc_west_f" then
            local mobileList = tes3.findActorsInProximity{
                reference = ref,
                range = 420
            }
            for _, mobile in ipairs(mobileList) do
                if mobile.isSwimming then
                    mobile.position.x = mobile.position.x - 5
                end
            end

        elseif ref.baseObject.id == "0s_wc_up_s" then
            local mobileList = tes3.findActorsInProximity{
                reference = ref,
                range = 1024
            }
            for _, mobile in ipairs(mobileList) do
                if mobile.isSwimming then
                    mobile.position.z = mobile.position.z + 2
                end
            end

        elseif ref.baseObject.id == "0s_wc_down_s" then
            local mobileList = tes3.findActorsInProximity{
                reference = ref,
                range = 1024
            }
            for _, mobile in ipairs(mobileList) do
                if mobile.isSwimming then
                    mobile.position.z = mobile.position.z - 2
                end
            end

        elseif ref.baseObject.id == "0s_wc_east_s" then
            local mobileList = tes3.findActorsInProximity{
                reference = ref,
                range = 1024
            }
            for _, mobile in ipairs(mobileList) do
                if mobile.isSwimming then
                    mobile.position.x = mobile.position.x + 2
                end
            end

        elseif ref.baseObject.id == "0s_wc_north_s" then
            local mobileList = tes3.findActorsInProximity{
                reference = ref,
                range = 1024
            }
            for _, mobile in ipairs(mobileList) do
                if mobile.isSwimming then
                    mobile.position.y = mobile.position.y + 2
                end
            end

        elseif ref.baseObject.id == "0s_wc_south_s" then
            local mobileList = tes3.findActorsInProximity{
                reference = ref,
                range = 1024
            }
            for _, mobile in ipairs(mobileList) do
                if mobile.isSwimming then
                    mobile.position.y = mobile.position.y - 2
                end
            end

        elseif ref.baseObject.id == "0s_wc_west_s" then
            local mobileList = tes3.findActorsInProximity{
                reference = ref,
                range = 1024
            }
            for _, mobile in ipairs(mobileList) do
                if mobile.isSwimming then
                    mobile.position.x = mobile.position.x - 2
                end
            end

 	elseif ref.baseObject.id == "0s_wc_southwest_s" then
            local mobileList = tes3.findActorsInProximity{
                reference = ref,
                range = 1024
            }
            for _, mobile in ipairs(mobileList) do
                if mobile.isSwimming then
                    mobile.position.x = mobile.position.x - 2
                    mobile.position.y = mobile.position.y - 2
                end
            end

 	elseif ref.baseObject.id == "0s_wc_northwest_s" then
            local mobileList = tes3.findActorsInProximity{
                reference = ref,
                range = 1024
            }
            for _, mobile in ipairs(mobileList) do
                if mobile.isSwimming then
                    mobile.position.x = mobile.position.x - 2
                    mobile.position.y = mobile.position.y + 2
                end
            end

 	elseif ref.baseObject.id == "0s_wc_southeast_s" then
            local mobileList = tes3.findActorsInProximity{
                reference = ref,
                range = 1024
            }
            for _, mobile in ipairs(mobileList) do
                if mobile.isSwimming then
                    mobile.position.x = mobile.position.x + 2
                    mobile.position.y = mobile.position.y - 2
                end
            end

 	elseif ref.baseObject.id == "0s_wc_northeast_s" then
            local mobileList = tes3.findActorsInProximity{
                reference = ref,
                range = 1024
            }
            for _, mobile in ipairs(mobileList) do
                if mobile.isSwimming then
                    mobile.position.x = mobile.position.x + 2
                    mobile.position.y = mobile.position.y + 2
                end
            end
        end
    end
end

local function onLoaded()
    event.register("simulate", waterCurrent)
end

local function initialized()
	if tes3.isModActive("WaterCurrent.ESP") then
		event.register("loaded", onLoaded)
	else
		mwse.log("WaterCurrent.ESP not detected")
	end
end
event.register("initialized", initialized)