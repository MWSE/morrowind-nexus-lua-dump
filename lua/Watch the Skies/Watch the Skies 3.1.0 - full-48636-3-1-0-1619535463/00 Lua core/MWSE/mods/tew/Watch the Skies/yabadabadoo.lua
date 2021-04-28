local this = {}
function this.yabadabadoo()
    ----------------------------------------------------
    -- Beneath you can find some useful functions to automatically generate varied weather --
    -- Note that this is super wonky lol I suck at maths --

    -- Prints a lua-friendly table with weather chances per month (vanilla - same base values for all months) --
    local months = {1,2,3,4,5,6,7,8,9,10,11,12}
    for region in tes3.iterate(tes3.dataHandler.nonDynamicData.regions) do
        print("[\""..region.name.."\"] = {")
        for _, month in ipairs(months) do
            print("["..month.."] = {"..region.weatherChanceClear..", "..region.weatherChanceCloudy..", "..region.weatherChanceFoggy..", "..region.weatherChanceOvercast..", "..region.weatherChanceRain..", "..region.weatherChanceThunder..", "..region.weatherChanceAsh..", "..region.weatherChanceBlight..", "..region.weatherChanceSnow..", "..region.weatherChanceBlizzard.."},")
        end
        print("},\n")
    end

    -- Adjusts value per month --
    for region in tes3.iterate(tes3.dataHandler.nonDynamicData.regions) do
        for month, chanceArray in ipairs(seasonalChances[region.name]) do
            if month ==  1 then
                chanceArray[1] = math.ceil(chanceArray[1] + chanceArray[1]*15/100)
                chanceArray[2] = math.ceil(chanceArray[2] - chanceArray[2]*20/100)
                chanceArray[3] = math.ceil(chanceArray[3] + chanceArray[3]*50/100)
                chanceArray[4] = math.ceil(chanceArray[4] + chanceArray[4]*20/100)
                chanceArray[5] = math.ceil(chanceArray[5] + chanceArray[5]*15/100)
                if chanceArray[7]~=0 then
                    chanceArray[7] = math.ceil(chanceArray[7] - chanceArray[7]*12/100)
                end
                if chanceArray[9]~=0 then
                    chanceArray[5] = 0
                    chanceArray[6] = 0
                    chanceArray[9] = math.ceil(chanceArray[9] + chanceArray[9]*10/100)
                    chanceArray[10] = math.ceil(chanceArray[10] + chanceArray[10]*10/100)
                end
            elseif month == 2 then
                chanceArray[1] = math.ceil(chanceArray[1] + chanceArray[1]*20/100)
                chanceArray[2] = math.ceil(chanceArray[2] - chanceArray[2]*30/100)
                chanceArray[3] = math.ceil(chanceArray[3] + chanceArray[3]*60/100)
                chanceArray[4] = math.ceil(chanceArray[4] + chanceArray[4]*15/100)
                chanceArray[5] = math.ceil(chanceArray[5] + chanceArray[5]*20/100)
                if chanceArray[7]~=0 then
                    chanceArray[7] = math.ceil(chanceArray[7] - chanceArray[7]*10/100)
                end
                if chanceArray[9]~=0 then
                    chanceArray[5] = 0
                    chanceArray[6] = 0
                    chanceArray[9] = math.ceil(chanceArray[9] + chanceArray[9]*16/100)
                    chanceArray[10] = math.ceil(chanceArray[10] + chanceArray[10]*4/100)
                end
            elseif month == 3 then
                chanceArray[1] = math.ceil(chanceArray[1] + chanceArray[1]*25/100)
                chanceArray[2] = math.ceil(chanceArray[2] - chanceArray[2]*5/100)
                chanceArray[3] = math.ceil(chanceArray[3] + chanceArray[3]*20/100)
                chanceArray[4] = math.ceil(chanceArray[4] + chanceArray[4]*25/100)
                chanceArray[5] = math.ceil(chanceArray[5] + chanceArray[5]*50/100)
                chanceArray[6] = math.ceil(chanceArray[6] + chanceArray[6]*120/100)
                if chanceArray[7]~=0 then
                    chanceArray[7] = math.ceil(chanceArray[7] - chanceArray[7]*4/100)
                end
                if chanceArray[9]~=0 then
                    chanceArray[5] = 0
                    chanceArray[6] = 0
                    chanceArray[9] = math.ceil(chanceArray[9] + chanceArray[9]*28/100)
                    chanceArray[10] = math.ceil(chanceArray[10] + chanceArray[10]*12/100)
                end
            elseif month == 4 then
                chanceArray[1] = math.ceil(chanceArray[1] + chanceArray[1]*40/100)
                chanceArray[2] = math.ceil(chanceArray[2] - chanceArray[2]*12/100)
                chanceArray[3] = math.ceil(chanceArray[3] + chanceArray[3]*40/100)
                chanceArray[4] = math.ceil(chanceArray[4] + chanceArray[4]*20/100)
                chanceArray[5] = math.ceil(chanceArray[5] + chanceArray[5]*170/100)
                chanceArray[6] = math.ceil(chanceArray[6] + chanceArray[6]*70/100)
                if chanceArray[7]~=0 then
                    chanceArray[7] = math.ceil(chanceArray[7] - chanceArray[7]*25/100)
                end
                if chanceArray[9]~=0 then
                    chanceArray[5] = 10
                    chanceArray[6] = 5
                    chanceArray[9] = math.ceil(chanceArray[9] + chanceArray[9]*12/100)
                    chanceArray[10] = math.ceil(chanceArray[10] + chanceArray[10]*18/100)
                end
            elseif month == 5 then
                chanceArray[1] = math.ceil(chanceArray[1] + chanceArray[1]*80/100)
                chanceArray[2] = math.ceil(chanceArray[2] + chanceArray[2]*30/100)
                chanceArray[3] = math.ceil(chanceArray[3] + chanceArray[3]*20/100)
                chanceArray[4] = math.ceil(chanceArray[4] - chanceArray[4]*30/100)
                chanceArray[5] = math.ceil(chanceArray[5] + chanceArray[5]*75/100)
                chanceArray[6] = math.ceil(chanceArray[6] + chanceArray[6]*30/100)
                if chanceArray[7]~=0 then
                    chanceArray[7] = math.ceil(chanceArray[7] + chanceArray[7]*25/100)
                end
                if chanceArray[9]~=0 then
                    chanceArray[9] = 0
                    chanceArray[10] = 0
                end
            elseif month == 6 then
                chanceArray[1] = math.ceil(chanceArray[1] + chanceArray[1]*150/100)
                chanceArray[2] = math.ceil(chanceArray[2] + chanceArray[2]*80/100)
                chanceArray[3] = math.ceil(chanceArray[3] + chanceArray[3]*40/100)
                chanceArray[4] = math.ceil(chanceArray[4] - chanceArray[4]*25/100)
                chanceArray[5] = math.ceil(chanceArray[5] + chanceArray[5]*25/100)
                chanceArray[6] = math.ceil(chanceArray[6] + chanceArray[6]*30/100)
                if chanceArray[7]~=0 then
                    chanceArray[7] = math.ceil(chanceArray[7] + chanceArray[7]*35/100)
                end
                if chanceArray[9]~=0 then
                    chanceArray[9] = 0
                    chanceArray[10] = 0
                end
            elseif month == 7 then
                chanceArray[1] = math.ceil(chanceArray[1] + chanceArray[1]*120/100)
                chanceArray[2] = math.ceil(chanceArray[2] + chanceArray[2]*70/100)
                chanceArray[3] = math.ceil(chanceArray[3] + chanceArray[3]*50/100)
                chanceArray[4] = math.ceil(chanceArray[4] - chanceArray[4]*15/100)
                chanceArray[5] = math.ceil(chanceArray[5] - chanceArray[5]*16/100)
                chanceArray[6] = math.ceil(chanceArray[6] - chanceArray[6]*12/100)
                if chanceArray[7]~=0 then
                    chanceArray[7] = math.ceil(chanceArray[7] + chanceArray[7]*30/100)
                end
                if chanceArray[9]~=0 then
                    chanceArray[9] = 0
                    chanceArray[10] = 0
                end
            elseif month == 8 then
                chanceArray[1] = math.ceil(chanceArray[1] + chanceArray[1]*90/100)
                chanceArray[2] = math.ceil(chanceArray[2] + chanceArray[2]*150/100)
                chanceArray[3] = math.ceil(chanceArray[3] - chanceArray[3]*35/100)
                chanceArray[4] = math.ceil(chanceArray[4] - chanceArray[4]*15/100)
                chanceArray[5] = math.ceil(chanceArray[5] - chanceArray[5]*16/100)
                chanceArray[6] = math.ceil(chanceArray[6] - chanceArray[6]*28/100)
                if chanceArray[7]~=0 then
                    chanceArray[7] = math.ceil(chanceArray[7] + chanceArray[7]*20/100)
                end
                if chanceArray[9]~=0 then
                    chanceArray[9] = 0
                    chanceArray[10] = 0
                end
            elseif month == 9 then
                chanceArray[1] = math.ceil(chanceArray[1] + chanceArray[1]*70/100)
                chanceArray[2] = math.ceil(chanceArray[2] + chanceArray[2]*100/100)
                chanceArray[3] = math.ceil(chanceArray[3] + chanceArray[3]*50/100)
                chanceArray[4] = math.ceil(chanceArray[4] + chanceArray[4]*30/100)
                chanceArray[5] = math.ceil(chanceArray[5] + chanceArray[5]*25/100)
                chanceArray[6] = math.ceil(chanceArray[6] + chanceArray[6]*10/100)
                if chanceArray[7]~=0 then
                    chanceArray[7] = math.ceil(chanceArray[7] + chanceArray[7]*16/100)
                end
                if chanceArray[9]~=0 then
                    chanceArray[5] = 10
                    chanceArray[6] = 0
                    chanceArray[9] = math.ceil(chanceArray[9] + chanceArray[9]*10/100)
                    chanceArray[10] = math.ceil(chanceArray[10] + chanceArray[10]*10/100)
                end
            elseif month == 10 then
                chanceArray[1] = math.ceil(chanceArray[1] + chanceArray[1]*40/100)
                chanceArray[2] = math.ceil(chanceArray[2] + chanceArray[2]*80/100)
                chanceArray[3] = math.ceil(chanceArray[3] + chanceArray[3]*70/100)
                chanceArray[4] = math.ceil(chanceArray[4] + chanceArray[4]*60/100)
                chanceArray[5] = math.ceil(chanceArray[5] + chanceArray[5]*15/100)
                chanceArray[6] = math.ceil(chanceArray[6] + chanceArray[6]*17/100)
                if chanceArray[7]~=0 then
                    chanceArray[7] = math.ceil(chanceArray[7] - chanceArray[7]*10/100)
                end
                if chanceArray[9]~=0 then
                    chanceArray[5] = 5
                    chanceArray[6] = 0
                    chanceArray[9] = math.ceil(chanceArray[9] + chanceArray[9]*30/100)
                    chanceArray[10] = math.ceil(chanceArray[10] + chanceArray[10]*15/100)
                end
            elseif month == 11 then
                chanceArray[1] = math.ceil(chanceArray[1] - chanceArray[1]*20/100)
                chanceArray[2] = math.ceil(chanceArray[2] + chanceArray[2]*60/100)
                chanceArray[3] = math.ceil(chanceArray[3] + chanceArray[3]*100/100)
                chanceArray[4] = math.ceil(chanceArray[4] + chanceArray[4]*70/100)
                chanceArray[5] = math.ceil(chanceArray[5] + chanceArray[5]*28/100)
                chanceArray[6] = math.ceil(chanceArray[6] + chanceArray[6]*4/100)
                if chanceArray[7]~=0 then
                    chanceArray[7] = math.ceil(chanceArray[7] - chanceArray[7]*16/100)
                end
                if chanceArray[9]~=0 then
                    chanceArray[5] = 0
                    chanceArray[6] = 0
                    chanceArray[9] = math.ceil(chanceArray[9] + chanceArray[9]*105/100)
                    chanceArray[10] = math.ceil(chanceArray[10] + chanceArray[10]*15/100)
                end
            elseif month == 12 then
                chanceArray[1] = math.ceil(chanceArray[1] - chanceArray[1]*40/100)
                chanceArray[2] = math.ceil(chanceArray[2] + chanceArray[2]*60/100)
                chanceArray[3] = math.ceil(chanceArray[3] + chanceArray[3]*120/100)
                chanceArray[4] = math.ceil(chanceArray[4] + chanceArray[4]*150/100)
                chanceArray[5] = math.ceil(chanceArray[5] + chanceArray[5]*28/100)
                chanceArray[6] = math.ceil(chanceArray[6] + chanceArray[6]*12/100)
                if chanceArray[7]~=0 then
                    chanceArray[7] = math.ceil(chanceArray[7] - chanceArray[7]*10/100)
                end
                if chanceArray[9]~=0 then
                    chanceArray[5] = 0
                    chanceArray[6] = 0
                    chanceArray[9] = math.ceil(chanceArray[9] + chanceArray[9]*18/100)
                    chanceArray[10] = math.ceil(chanceArray[10] + chanceArray[10]*15/100)
                end
            end
        end
    end

    -- Adjusts values to give 100% weather chances sum per month --
    for _, month in pairs(seasonalChances) do
        for _, chanceArray in pairs(month) do
            local sum = 0
            local diff
            for _, chance in ipairs(chanceArray) do
                sum = sum + chance
            end
            if sum > 100 then
                diff = sum - 100
                chanceArray[2] = chanceArray[2] - diff
                if chanceArray[2] < 5 then
                    diff = 5 - chanceArray[2]
                    chanceArray[2] = 5
                    chanceArray[1] = chanceArray[1] + diff
                end
                sum = 0
                for _, chance in ipairs(chanceArray) do
                    sum = sum + chance
                end
                if sum > 100 then
                    diff = sum - 100
                    local valueMax = math.max(unpack(chanceArray))
                    for index, chance in ipairs(chanceArray) do
                        if chance == valueMax then
                            chanceArray[index] = chanceArray[index] - diff
                        end
                    end
                end
            end
            if sum < 100 then
                diff = 100 - sum
                chanceArray[1] = chanceArray[1] + diff
            end
        end
    end

    -- Ensures there are no negative values --
    for _, month in pairs(seasonalChances) do
        local added = 0
        for _, chanceArray in pairs(month) do
            for index, chance in ipairs(chanceArray) do
                if chance < 0 then
                    added = math.abs(2*chance)
                    chanceArray[index] = added
                end
            end
            local valueMax = math.max(unpack(chanceArray))
            for index, chance in ipairs(chanceArray) do
                if chance == valueMax then
                    chanceArray[index] = chanceArray[index] - added
                end
            end
        end
    end

    -- Prints a lua-friendly table with weather chances per month (adjusted - each month has different value) --
    for region in tes3.iterate(tes3.dataHandler.nonDynamicData.regions) do
        print("[\""..region.name.."\"] = {")
        for month, chanceArray in ipairs(seasonalChances[region.name]) do
            print("["..month.."] = {"..chanceArray[1]..", "..chanceArray[2]..", "..chanceArray[3]..", "..chanceArray[4]..", "..chanceArray[5]..", "..chanceArray[6]..", "..chanceArray[7]..", "..chanceArray[8]..", "..chanceArray[9]..", "..chanceArray[10].."},")
        end
        print("},\n")
    end

    -- Check if all chances are 100% --
    local flag = 0
    print("Starting weather chances check.")
    for region, month in pairs(seasonalChances) do
        for monthIndex, array in pairs(month) do
            local sum = 0
            for _, num in pairs(array) do
                sum = sum + num
            end
            if sum ~= 100 then
                flag = 1
                print("\nWARNING! Month chances doesn't add up to 100.")
                print("Sum: "..sum)
                print("Region: "..region)
                print("Month: "..monthIndex.."\n")
            end
        end
    end
    print("Chances check finished.")
    if flag == 1 then
        print("Process finished with errors. See above.")
    else
        print("No problems detected.")
    end
end

return this