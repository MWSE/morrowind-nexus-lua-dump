local processusLocations = {
    { cell = {"Bitter Coast Region (-3, -9)"}, position = { -19516.9, -67530.44, 183.04 }, orientation = { 0, 0, 5.73 } },
	{ cell = {"Bitter Coast Region (-3, -9)"}, position = { -20581.69, -68443.97, 137.79 }, orientation = { 0, 0, 226.63 } },
    { cell = {"Bitter Coast Region (-3, -9)"}, position = { -22558.13, -70296.55, 50.33 }, orientation = { 0, 0, 279.38 } },
	{ cell = {"Bitter Coast Region (-3, -9)"}, position = { -23997.02, -65993.61, 142.44 }, orientation = { 0, 0, 314.15 } },
	{ cell = {"Bitter Coast Region (-3, -9)"}, position = { -23243.74, -66197.7, -68.67 }, orientation = { 0, 0, 46 } },
	{ cell = {"Bitter Coast Region (-3, -8)"}, position = { -23124.86, -63226.19, 100.36 }, orientation = { 0, 0, 295.60 } },
	{ cell = {"Bitter Coast Region (-3, -8)"}, position = { -19133.61, -62992.27, 376.78 }, orientation = { 0, 0, 16.91 } },
	{ cell = {"Bitter Coast Region (-2, -8)"}, position = { -15507.29, -64096.44, 720.03 }, orientation = { 0, 0, 13.58 } },
	{ cell = {"Bitter Coast Region (-2, -8)"}, position = { -10894.29, -64079.43, 510.85 }, orientation = { 0, 0, 215.57 } },
	{ cell = {"Bitter Coast Region (-1, -9)"}, position = { -3900.27, -69423.02, 424.34 }, orientation = { 0, 0, 342.29 } },
	{ cell = {"Seyda Neen"}, position = { -7725.81, -67071.63, 207.09 }, orientation = { 0, 0, 39.65 } },
	{ cell = {"Seyda Neen"}, position = { -13388.29, -67603.12, 181.73 }, orientation = { 0, 0, 315.07 } },
	{ cell = {"Seyda Neen"}, position = { -15616.83, -68920.84, 254.29 }, orientation = { 0, 0, 284.41 } },
}

local ernilLocations = {
	{ cell = {"West Gash Region (-2, -1)"}, position = { -8542.54, -2343.78, 1128.85 }, orientation = { 0, 0, 159.46 } },
	{ cell = {"West Gash Region (-1, -1)"}, position = { -6383.31, -7403.48, 805.28 }, orientation = { 0, 0, 190.73 } },
	{ cell = {"Balmora"}, position = { -9850.69, -10857.31, 684.93 }, orientation = { 0, 0, 145.66 } },
	{ cell = {"West Gash Region (-2, -2)"}, position = { -4703.78, -10484.1, 1090.6 }, orientation = { 0, 0, 358.8 } },
	{ cell = {"West Gash Region (-2, -2)"}, position = { -6027.83, -14301.38, 1996.16 }, orientation = { 0, 0, 281.46 } },
	{ cell = {"West Gash Region (-2, -1)"}, position = { -10707.32, -5402.95, -214.62 }, orientation = { 0, 0, 158.81 } },
	{ cell = {"West Gash Region (-2, 0)"}, position = { -7851.37, 2499.76, 1353.38 }, orientation = { 0, 0, 143.59 } },
	{ cell = {"West Gash Region (-2, 0)"}, position = { -9627.23, 6252.13, 1332.48 }, orientation = { 0, 0, 130.38 } },
	{ cell = {"West Gash Region (-1, 0)"}, position = { -7260.88, 6289.05, 1140.85 }, orientation = { 0, 0, 332.38 } },
	{ cell = {"West Gash Region (-2, 1)"}, position = { -8085.1, 11002.58, 1678.85 }, orientation = { 0, 0, 61.23 } },
	{ cell = {"Ascadian Isles Region (-4, -4)"}, position = { -25435.73, -29691.84, 573.73 }, orientation = { 0, 0, 211.02 } },
	{ cell = {"Bitter Coast Region (-5, -4)"}, position = { -37203.66, -26540.12, 505.99 }, orientation = { 0, 0, 110.51 } },
}

local charGen
local newGame
local checkingChargen
local function checkCharGen()
    if charGen.value == 10 then
        newGame = true
    elseif newGame and charGen.value == -1 then
        checkingChargen = false
        event.unregister("simulate", checkCharGen)
                
		--randomise Processus location
            local body1 = tes3.getReference("processus vitellius")
            local location1 = table.choice(processusLocations) 
            if body1 then
                timer.delayOneFrame(function()
                    tes3.positionCell{
						cell = location1.cell, 
                        position = location1.position, 
                        orientation = location1.orientation, 
                        reference = body1
                    };
                end)
                
            end

        --randomise Ernil location
            local body2 = tes3.getReference("ernil omoran")
            local location2 = table.choice(ernilLocations)
            if body2 then
                timer.delayOneFrame(function()
                    tes3.positionCell{
						cell = location2.cell, 
                        position = location2.position, 
                        orientation = location2.orientation, 
                        reference = body2
                    };
                end)
            end
    end
end

local function loaded()
    newGame = nil --reset so we can check chargen state again
    charGen = tes3.findGlobal("CharGenState")
    --Only reregister if necessary. If new game was started during
    --  chargen of previous game, this will already be running
    if not checkingChargen then
        event.register("simulate", checkCharGen)
        checkingChargen = true
    end
end

event.register("loaded", loaded )