local config = mwse.loadConfig("Teleport Menu", {
    combatEnabled = true,
    jailEnabled = true,
    bountyEnabled = true,
    setBounty = 250,
    keyBind = {keyCode = tes3.scanCode.n, isShiftDown = false, isAltDown = false, isControlDown = false},
})

local tome = {}
local main

local function mainMenu()
    return main()
end

function tome.AldRuhn(button)

    if button == 0 then
        tes3.positionCell({cell = "Ald-ruhn", position = {-12682, 54457, 2450}, orientation = {0, 0, 74}})
    elseif button == 1 then
        tes3.positionCell({cell = "Ald-ruhn", position = {-8695.768, 58477.617, 2677.996}, orientation = {0, 0, -135}})
    elseif button == 2 then
        tes3.positionCell({cell = "Ald-ruhn", position = {-7642.483, 52615.957, 2433}, orientation = {0, 0, -25}})
    elseif button == 3 then
        tes3.positionCell({cell = "Ald-ruhn", position = {-16448, 52096, 1920}, orientation = {0, 0, 89.5}})
    elseif button == 4 then
        tes3.positionCell({cell = "Ald-ruhn, Manor District", position = {-77.774, -2187.518, -356}, orientation = {0, 0, 0}})
    elseif button == 5 then
        mainMenu()
    elseif button == 6 then
        return
    end
end

local function teleportMenuAldRuhn()

    tes3.messageBox({message = "Teleport to Where in Ald-Ruhn ?", buttons = {"Central", "North-East", "South-East", "South-West", "Manor District", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.AldRuhn(e.button)
        end)
    end})
end

function tome.Balmora(button)

    if button == 0 then
        tes3.positionCell({cell = "Balmora", position = {-20536.178, -13959.923, 313.89}, orientation = {0, 0, 89.5}})
    elseif button == 1 then
        tes3.positionCell({cell = "Balmora", position = {-15262.94, -12789.999, 540.722}, orientation = {0, 0, 179.1}})
    elseif button == 2 then
        tes3.positionCell({cell = "Balmora", position = {-25516.857, -10150.058, 1122.241}, orientation = {0, 0, 179.1}})
    elseif button == 3 then
        tes3.positionCell({cell = "Balmora", position = {-16623.131, -15619.301, 304.729}, orientation = {0, 0, 0}})
    elseif button == 4 then
        tes3.positionCell({cell = "Balmora", position = {-24576.701, -16072.117, 614.389}, orientation = {0, 0, 63}})
    elseif button == 5 then
        mainMenu()
    elseif button == 6 then
        return
    end
end

local function teleportMenuBalmora()

    tes3.messageBox({message = "Teleport to Where in Balmora ?", buttons = {"Central", "North-East", "North-West", "South-East", "South-West", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.Balmora(e.button)
        end)
    end})
end

function tome.SadrithMora(button)

    if button == 0 then
        tes3.positionCell({cell = "Sadrith Mora", position = {152090.188, 38270.949, 940}, orientation = {0, 0, 51.6}})
    elseif button == 1 then
        tes3.positionCell({cell = "Sadrith Mora", position = {147589.828, 39747.93, 800}, orientation = {0, 0, 154.7}})
    elseif button == 2 then
        tes3.positionCell({cell = "Wolverine Hall", position = {152284.063, 29872.471, 654.71}, orientation = {0, 0, -51.6}})
    elseif button == 3 then
        tes3.positionCell({cell = "Sadrith Mora", position = {147096.156, 34671.242, 846.048}, orientation = {0, 0, -108.9}})
    elseif button == 4 then
        tes3.positionCell({cell = "Sadrith Mora, Tel Naga Great Hall", position = {-4.397, 1264.029, 474.312}, orientation = {0, 0, 179.1}})
    elseif button == 5 then
        tes3.positionCell({cell = "Wolverine Hall", position = {148896, 28512, 1472}, orientation = {0, 0, 0}})
    elseif button == 6 then
        mainMenu()
    elseif button == 7 then
        return
    end
end

local function teleportMenuSadrithMora()

    tes3.messageBox({message = "Teleport to Where in Sadrith Mora ?", buttons = {"North-East", "North-West", "South-East", "South-West", "Tel Naga", "Wolverine Hall", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.SadrithMora(e.button)
        end)
    end})
end

function tome.Vivec(button)

    if button == 0 then
        tes3.positionCell({cell = "Vivec, Arena", position = {36541.844, -88450.211, 1882.470}, orientation = {0, 0, 179.1}})
    elseif button == 1 then
        tes3.positionCell({cell = "Vivec, Foreign Quarter", position = {29919.473, -80957.258, 3104.473}, orientation = {0, 0, 179.1}})
    elseif button == 2 then
        tes3.positionCell({cell = "Vivec, Temple", position = {32878.625, -99092.969, 1167.573}, orientation = {0, 0, 0}})
    elseif button == 3 then
        tes3.positionCell({cell = "Vivec, Hlaalu", position = {22210.990, -86265.078, 2135.178}, orientation = {0, 0, 179.1}})
    elseif button == 4 then
        tes3.positionCell({cell = "Vivec, Redoran", position = {29119.676, -88454.633, 1885.885}, orientation = {0, 0, 179.1}})
    elseif button == 5 then
        tes3.positionCell({cell = "Vivec, St. Delyn", position = {29117.082, -94860.445, 1880.191}, orientation = {0, 0, 179.1}})
    elseif button == 6 then
        tes3.positionCell({cell = "Vivec, St. Olms", position = {36533.168, -94832.164, 1878.606}, orientation = {0, 0, 179.1}})
    elseif button == 7 then
        tes3.positionCell({cell = "Vivec, Telvanni", position = {43450.121, -86262.984, 2129.235}, orientation = {0, 0, 179.1}})
    elseif button == 8 then
        tes3.positionCell({cell = "Vivec, Temple", position = {31982.391, -101138.375, 3415.564}, orientation = {0, 0, -135}})
    elseif button == 9 then
        mainMenu()
    elseif button == 10 then
        return
    end
end

local function teleportMenuVivec()

    tes3.messageBox({message = "Teleport to Where in Vivec ?", buttons = {"Arena", "Foreign Quarter", "High Fane", "Hlaalu", "Redoran", "St. Delyn", "St. Olms", "Telvanni", "Ministry of Truth", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.Vivec(e.button)
        end)
    end})
end

function tome.Cities(button)

    if button == 0 then
        teleportMenuAldRuhn()
    elseif button == 1 then
        teleportMenuBalmora()
    elseif button == 2 then
        teleportMenuSadrithMora()
    elseif button == 3 then
        teleportMenuVivec()
    elseif button == 4 then
        mainMenu()
    elseif button == 5 then
        return
    end
end

local function teleportMenuCities()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Ald-Ruhn", "Balmora", "Sadrith Mora", "Vivec", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.Cities(e.button)
        end)
    end})
end

function tome.MouBA(button)

    if button == 0 then
        tes3.positionCell({cell = "Bamz-Amschend, Hall of Wails", position = {6208.000, 4032.000, 13056.000}, orientation = {0, 0, -89.5}})
    elseif button == 1 then
        tes3.positionCell({cell = "Bamz-Amschend, Hall of Winds", position = {5856.000, 4352.000, 12632.000}, orientation = {0, 0, -89.5}})
    elseif button == 2 then
        tes3.positionCell({cell = "Bamz-Amschend, Hearthfire Hall", position = {2430.701, 3271.007, 13539.292}, orientation = {0, 0, 0}})
    elseif button == 3 then
        tes3.positionCell({cell = "Bamz-Amschend, King's Walk", position = {7872.548, 2047.512, 12496.000}, orientation = {0, 0, -89.5}})
    elseif button == 4 then
        tes3.positionCell({cell = "Bamz-Amschend, Passage of the Walker", position = {3693.306, 5872.738, 12207.204}, orientation = {0, 0, 179.1}})
    elseif button == 5 then
        tes3.positionCell({cell = "Bamz-Amschend, Passage of Whispers", position = {-192.000, 1568.000, 544.000}, orientation = {0, 0, 89.5}})
    elseif button == 6 then
        tes3.positionCell({cell = "Bamz-Amschend, Radac's Forge", position = {256.000, 792.000, 14640.000}, orientation = {0, 0, 0}})
    elseif button == 7 then
        tes3.positionCell({cell = "Bamz-Amschend, Skybreak Gallery", position = {4224.000, 1336.000, 12408.000}, orientation = {0, 0, 0}})
    elseif button == 8 then
        mainMenu()
    elseif button == 9 then
        return
    end
end

local function teleportMenuMouBA()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Hall of Wails", "Hall of Winds", "Hearthfire Hall", "King's Walk", "Passage of the Walker", "Passage of Whispers", "Radac's Forge", "Skybreak Gallery", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.MouBA(e.button)
        end)
    end})
end

function tome.MouMC(button)

    if button == 0 then
        tes3.positionCell({cell = "Mournhold, Godsreach", position = {51.038, 1543.231, 280.656}, orientation = {0, 0, 179.1}})
    elseif button == 1 then
        tes3.positionCell({cell = "Mournhold, Great Bazaar", position = {1494.473, -1245.914, 134.563}, orientation = {0, 0, 0}})
    elseif button == 2 then
        tes3.positionCell({cell = "Mournhold, Museum of Artifacts", position = {-1.604, 131.264, -46.099}, orientation = {0, 0, 0}})
    elseif button == 3 then
        tes3.positionCell({cell = "Mournhold, Plaza Brindisi Dorom", position = {0, 3178.306, 264.756}, orientation = {0, 0, 179.1}})
    elseif button == 4 then
        tes3.positionCell({cell = "Mournhold, Royal Palace: Reception Area", position = {22.260, 997.365, -34.8}, orientation = {0, 0, 179.1}})
    elseif button == 5 then
        tes3.positionCell({cell = "Mournhold, Royal Palace Throne Room", position = {1.186, 995.418, -44.111}, orientation = {0, 0, 179.1}})
    elseif button == 6 then
        tes3.positionCell({cell = "Mournhold, Temple Courtyard", position = {0, -4704.000, 220.167}, orientation = {0, 0, 0}})
    elseif button == 7 then
        tes3.positionCell({cell = "Mournhold Temple: Reception Area", position = {2.261, 543.309, -658.753}, orientation = {0, 0, 0}})
    elseif button == 8 then
        mainMenu()
    elseif button == 9 then
        return
    end
end

local function teleportMenuMouMC()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Godsreach", "Great Bazaar", "Museum of Artifacts", "Plaza Brindisi Dorom", "Royal Palace Reception Area", "Royal Palace Throne Room", "Temple Courtyard", "Temple High Chapel", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.MouMC(e.button)
        end)
    end})
end

function tome.MouND(button)

    if button == 0 then
        tes3.positionCell({cell = "Norenen-Dur", position = {4145.185, -3769.062, -99.428}, orientation = {0, 0, 0}})
    elseif button == 1 then
        tes3.positionCell({cell = "Norenen-Dur, Basilica of Divine Whispers", position = {3089.296, 3554.500, 32.000}, orientation = {0, 0, 0}})
    elseif button == 2 then
        tes3.positionCell({cell = "Norenen-Dur, Citadel of Myn Dhrur", position = {-142.355, 877.206, 617.409}, orientation = {0, 0, 0}})
    elseif button == 3 then
        tes3.positionCell({cell = "Norenen-Dur, The Grand Stair", position = {-4272.000, 2784.000, -272.000}, orientation = {0, 0, 0}})
    elseif button == 4 then
        tes3.positionCell({cell = "Norenen-Dur, The Teeth that Gnash", position = {4208.000, 4224.000, 1040.000}, orientation = {0, 0, 0}})
    elseif button == 5 then
        tes3.positionCell({cell = "Norenen-Dur, The Wailingdelve", position = {3964.976, 3404.013, 4738.391}, orientation = {0, 0, 0}})
    elseif button == 6 then
        mainMenu()
    elseif button == 7 then
        return
    end
end

local function teleportMenuMouND()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Norenen-Dur", "Basilica of Divine Whispers", "Citadel of Myn Dhrur", "The Grand Stair", "The Teeth that Gnash", "The Wailingdelve", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.MouND(e.button)
        end)
    end})
end

function tome.MouOM2(button)

    if button == 0 then
        tes3.positionCell({cell = "Old Mournhold: Palace Sewers", position = {-1953.985, -1599.364, 484.157}, orientation = {0, 0, 165.5}})
    elseif button == 1 then
        tes3.positionCell({cell = "Old Mournhold: Residential Ruins", position = {-3001.525, 2648.683, -806.748}, orientation = {0, 0, 179.1}})
    elseif button == 2 then
        tes3.positionCell({cell = "Old Mournhold: Residential Sewers", position = {567.269, 10905.725, 871.977}, orientation = {0, 0, 89.5}})
    elseif button == 3 then
        tes3.positionCell({cell = "Old Mournhold: Tears of Amun-Shae", position = {-180.840, 11460.979, 1299.754}, orientation = {0, 0, 179.1}})
    elseif button == 4 then
        tes3.positionCell({cell = "Old Mournhold: Temple Catacombs", position = {7216.097, 6399.597, 2560.921}, orientation = {0, 0, -89.5}})
    elseif button == 5 then
        tes3.positionCell({cell = "Old Mournhold: Temple Crypt", position = {10.388, 38.350, 85.308}, orientation = {0, 0, -15}})
    elseif button == 6 then
        tes3.positionCell({cell = "Old Mournhold: Temple Gardens", position = {-1743.769, -1665.309, -362.565}, orientation = {0, 0, 134.1}})
    elseif button == 7 then
        tes3.positionCell({cell = "Old Mournhold: Temple Sewers", position = {-255.231, -2782.626, -159.662}, orientation = {0, 0, 179.1}})
    elseif button == 8 then
        tes3.positionCell({cell = "Old Mournhold: Temple Sewers East", position = {1631.582, 8631.988, 12257.400}, orientation = {0, 0, 0}})
    elseif button == 9 then
        tes3.positionCell({cell = "Old Mournhold: Temple Sewers West", position = {-181.520, 356.991, -176.000}, orientation = {0, 0, -89.5}})
    elseif button == 10 then
        tes3.positionCell({cell = "Old Mournhold: Temple Shrine", position = {5615.727, -5531.344, -1752.251}, orientation = {0, 0, -89.5}})
    elseif button == 11 then
        tes3.positionCell({cell = "Old Mournhold: Teran Hall", position = {-1108.019, -5254.605, -432.925}, orientation = {0, 0, -89.5}})
    elseif button == 12 then
        tes3.positionCell({cell = "Old Mournhold: West Sewers", position = {1249.813, 5552.527, -176.000}, orientation = {0, 0, 0}})
    elseif button == 13 then
        mainMenu()
    elseif button == 14 then
        return
    end
end

local function teleportMenuMouOM2()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Palace Sewers", "Residential Ruins", "Residential Sewers", "Tears of Amun-Shae", "Temple Catacombs", "Temple Crypt", "Temple Gardens", "Temple Sewers", "Temple Sewers East", "Temple Sewers West", "Temple Shrine", "Teran Hall", "West Sewers", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.MouOM2(e.button)
        end)
    end})
end

function tome.MouOM(button)

    if button == 0 then
        tes3.positionCell({cell = "Old Mournhold: Abandoned Crypt", position = {333.016, -194.762, -100.297}, orientation = {0, 0, 0}})
    elseif button == 1 then
        tes3.positionCell({cell = "Old Mournhold: Abandoned Passageway", position = {116.455, -2796.581, 1560.489}, orientation = {0, 0, -89.5}})
    elseif button == 2 then
        tes3.positionCell({cell = "Old Mournhold: Armory Ruins", position = {-511.402, 2168.475, -551.235}, orientation = {0, 0, -89.5}})
    elseif button == 3 then
        tes3.positionCell({cell = "Old Mournhold: Battlefield", position = {2995.547, -3586.494, 890.342}, orientation = {0, 0, -45}})
    elseif button == 4 then
        tes3.positionCell({cell = "Old Mournhold: Bazaar Sewers", position = {2752.493, -2048.906, -678.235}, orientation = {0, 0, 0}})
    elseif button == 5 then
        tes3.positionCell({cell = "Old Mournhold: City Gate", position = {82.287, 979.983, 344.000}, orientation = {0, 0, -135}})
    elseif button == 6 then
        tes3.positionCell({cell = "Old Mournhold: Forgotten Sewer", position = {9538.918, 3013.084, -440.482}, orientation = {0, 0, 0}})
    elseif button == 7 then
        tes3.positionCell({cell = "Old Mournhold: Gedna Relvel's Tomb", position = {185.799, 1.196, -112.000}, orientation = {0, 0, -89.5}})
    elseif button == 8 then
        tes3.positionCell({cell = "Old Mournhold: Manor District", position = {214.530, 89.917, 1012.249}, orientation = {0, 0, 89.5}})
    elseif button == 9 then
        tes3.positionCell({cell = "Old Mournhold: Moril Manor, Courtyard", position = {40.036, 20.003, 69.089}, orientation = {0, 0, 0}})
    elseif button == 10 then
        tes3.positionCell({cell = "Old Mournhold: Moril Manor, East Building", position = {193.677, -6.644, 12.091}, orientation = {0, 0, 89.5}})
    elseif button == 11 then
        tes3.positionCell({cell = "Old Mournhold: Moril Manor, North Building", position = {56.959, 165.104, 16.000}, orientation = {0, 0, 0}})
    elseif button == 12 then
        teleportMenuMouOM2()
    elseif button == 13 then
        mainMenu()
    elseif button == 14 then
        return
    end
end

local function teleportMenuMouOM()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Abandoned Crypt", "Abandoned Passageway", "Armory Ruins", "Battlefield", "Bazaar Sewers", "City Gate", "Forgotten Sewer", "Gedna Relvel's Tomb", "Manor District", "Moril Manor, Courtyard", "Moril Manor, East Building", "Moril Manor, North Building", "Next Page", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.MouOM(e.button)
        end)
    end})
end

function tome.MouSS(button)

    if button == 0 then
        tes3.positionCell({cell = "Sotha Sil, Central Gearworks", position = {-416.000, 624.000, 12736.000}, orientation = {0, 0, -135}})
    elseif button == 1 then
        tes3.positionCell({cell = "Sotha Sil, Chamber of Sohleh", position = {128.000, 16.000, 208.000}, orientation = {0, 0, 0}})
    elseif button == 2 then
        tes3.positionCell({cell = "Sotha Sil, Dome of Kasia", position = {-1120.000, 128.000, 728.000}, orientation = {0, 0, -89.5}})
    elseif button == 3 then
        tes3.positionCell({cell = "Sotha Sil, Dome of Serlyn", position = {4352.000, 4408.000, 12560.000}, orientation = {0, 0, 0}})
    elseif button == 4 then
        tes3.positionCell({cell = "Sotha Sil, Dome of Sotha Sil", position = {4032.000, 3328.000, 12384.000}, orientation = {0, 0, 0}})
    elseif button == 5 then
        tes3.positionCell({cell = "Sotha Sil, Dome of the Imperfect", position = {3904.000, 3328.000, 12384.000}, orientation = {0, 0, 0}})
    elseif button == 6 then
        tes3.positionCell({cell = "Sotha Sil, Dome of Udok", position = {3968.000, 3264.000, 12384.000}, orientation = {0, 0, 0}})
    elseif button == 7 then
        tes3.positionCell({cell = "Sotha Sil, Hall of Delirium", position = {2272.000, 3200.000, 1232.000}, orientation = {0, 0, -89.5}})
    elseif button == 8 then
        tes3.positionCell({cell = "Sotha Sil, Hall of Mileitho", position = {3040.000, 3136.000, 12256.000}, orientation = {0, 0, 89.5}})
    elseif button == 9 then
        tes3.positionCell({cell = "Sotha Sil, Hall of Sallaemu", position = {4024.000, 5688.000, 13504.000}, orientation = {0, 0, 179.1}})
    elseif button == 10 then
        tes3.positionCell({cell = "Sotha Sil, Hall of Theuda", position = {128.000, -480.000, 224.000}, orientation = {0, 0, 0}})
    elseif button == 11 then
        tes3.positionCell({cell = "Sotha Sil, Inner Flooded Halls", position = {-808.000, 64.000, 80.000}, orientation = {0, 0, 89.5}})
    elseif button == 12 then
        tes3.positionCell({cell = "Sotha Sil, Outer Flooded Halls", position = {5024.963, 131.161, 16.000}, orientation = {0, 0, -89.5}})
    elseif button == 13 then
        mainMenu()
    elseif button == 14 then
        return
    end
end

local function teleportMenuMouSS()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Central Gearworks", "Chamber of Sohleh", "Dome of Kasia", "Dome of Serlyn", "Dome of Sotha Sil", "Dome of the Imperfect", "Dome of Udok", "Hall of Delirium", "Hall of Mileitho", "Hall of Sallaemu", "Hall of Theuda", "Inner Flooded Halls", "Outer Flooded Halls", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.MouSS(e.button)
        end)
    end})
end

function tome.Mou(button)

    if button == 0 then
        teleportMenuMouBA()
    elseif button == 1 then
        teleportMenuMouMC()
    elseif button == 2 then
        teleportMenuMouND()
    elseif button == 3 then
        teleportMenuMouOM()
    elseif button == 4 then
        teleportMenuMouSS()
    elseif button == 5 then
        mainMenu()
    elseif button == 6 then
        return
    end
end

local function teleportMenuMou()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Bamz-Amschend", "Mournold City", "Norenen-Dur", "Old Mournhold", "Sotha Sil", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.Mou(e.button)
        end)
    end})
end

function tome.SolAF(button)

    if button == 0 then
        tes3.positionCell({cell = "Solstheim, Aesliip's Lair", position = {-2574.097, -4297.052, 29.341}, orientation = {0, 0, 0}})
    elseif button == 1 then
        tes3.positionCell({cell = "Solstheim, Benkongerike", position = {15.044, -3464.145, 7.979}, orientation = {0, 0, 0}})
    elseif button == 2 then
        tes3.positionCell({cell = "Solstheim, Bjorn", position = {-17.911, -350.903, 44.972}, orientation = {0, 0, 0}})
    elseif button == 3 then
        tes3.positionCell({cell = "Solstheim, Bloodskal Barrow", position = {1.280, -7.542, 34.381, 180}, orientation = {0, 0, 179.1}})
    elseif button == 4 then
        tes3.positionCell({cell = "Solstheim, Castle Karstaag", position = {-194333.406, 217802.047, 1453}, orientation = {0, 0, 0}})
    elseif button == 5 then
        tes3.positionCell({cell = "Solstheim, Cave of Hidden Music", position = {-1.897, 8.107, 19.183}, orientation = {0, 0, 179.1}})
    elseif button == 6 then
        tes3.positionCell({cell = "Solstheim, Caves of Fjalding", position = {-127.657, -343.181, 0}, orientation = {0, 0, -17.1}})
    elseif button == 7 then
        tes3.positionCell({cell = "Solstheim, Chamber of Song", position = {5423.366, 2803.154, 10869.467}, orientation = {0, 0, -89.5}})
    elseif button == 8 then
        tes3.positionCell({cell = "Solstheim, Connorflenge Barrow", position = {24.033, 16.065, 34.381}, orientation = {0, 0, 179.1}})
    elseif button == 9 then
        tes3.positionCell({cell = "Solstheim, Domme", position = {-18.245, -487.277, 35.792}, orientation = {0, 0, 0}})
    elseif button == 10 then
        tes3.positionCell({cell = "Solstheim, Eddard Barrow", position = {13.307, 59.334, -46.548}, orientation = {0, 0, 179.1}})
    elseif button == 11 then
        tes3.positionCell({cell = "Solstheim, Fjell", position = {-123.832, -264.674, 0}, orientation = {0, 0, 0}})
    elseif button == 12 then
        tes3.positionCell({cell = "Solstheim, Frossel", position = {7395.521, 4349.395, 13239.653}, orientation = {0, 0, -89.5}})
    elseif button == 13 then
        tes3.positionCell({cell = "Solstheim, Frosselmane Barrow", position = {16.883, 63.000, -17.036}, orientation = {0, 0, 179.1}})
    elseif button == 14 then
        tes3.positionCell({cell = "Solstheim, Frykte", position = {-102.587, -394.894, 36.935}, orientation = {0, 0, 0}})
    elseif button == 15 then
        mainMenu()
    elseif button == 16 then
        return
    end
end

local function teleportMenuSolAF()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Aesliip's Lair", "Benkongerike", "Bjorn", "Bloodskal Barrow", "Castle Karstaag", "Cave of Hidden Music", "Caves of Fjalding", "Chamber of Song", "Connorflenge Barrow", "Domme", "Eddard Barrow", "Fjell", "Frossel", "Frosselmane Barrow", "Frykte", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.SolAF(e.button)
        end)
    end})
end

function tome.SolGK(button)

    if button == 0 then
        tes3.positionCell({cell = "Solstheim, Gandrung Caverns", position = {3971.876, 5432.454, 14439.774}, orientation = {0, 0, 179.1}})
    elseif button == 1 then
        tes3.positionCell({cell = "Solstheim, Geilir the Mumbling's Dwelling", position = {-14.899, -406.528, 38.803}, orientation = {0, 0, 0}})
    elseif button == 2 then
        tes3.positionCell({cell = "Solstheim, Glenschul's Tomb", position = {9.768, 21.017, 27.209}, orientation = {0, 0, 179.1}})
    elseif button == 3 then
        tes3.positionCell({cell = "Solstheim, Gloomy Cave", position = {-18.042, -366.627, 61.085}, orientation = {0, 0, 0}})
    elseif button == 4 then
        tes3.positionCell({cell = "Solstheim, Graring's House", position = {67.342, -94.901, -123.169}, orientation = {0, 0, 0}})
    elseif button == 5 then
        tes3.positionCell({cell = "Solstheim, Gronn", position = {-18.841, -428.655, 32.967}, orientation = {0, 0, 0}})
    elseif button == 6 then
        tes3.positionCell({cell = "Solstheim, Gyldenhul Barrow", position = {4338.500, -1086.249, 34153.887}, orientation = {0, 0, 0}})
    elseif button == 7 then
        tes3.positionCell({cell = "Solstheim, Halls of Penumbra", position = {-240.710, -403.982, 0, 331.4}, orientation = {0, 0, -28.5}})
    elseif button == 8 then
        tes3.positionCell({cell = "Solstheim, Himmelhost Barrow", position = {12.214, 50.801, -25.009}, orientation = {0, 0, 179.1}})
    elseif button == 9 then
        tes3.positionCell({cell = "Solstheim, Hrothmund's Barrow", position = {4100.534, 4021.043, 16002.516}, orientation = {0, 0, 0}})
    elseif button == 10 then
        tes3.positionCell({cell = "Solstheim, Jolgeirr Barrow", position = {146.425, 320.163, -28.842}, orientation = {0, 0, 179.1}})
    elseif button == 11 then
        tes3.positionCell({cell = "Solstheim, Kelsedolk Barrow", position = {17.680, 43.493, -28.459}, orientation = {0, 0, 179.1}})
    elseif button == 12 then
        tes3.positionCell({cell = "Solstheim, Kjolver's Dwelling", position = {-20.127, -350.821, 8.154}, orientation = {0, 0, 0}})
    elseif button == 13 then
        tes3.positionCell({cell = "Solstheim, Kolbjorn Barrow", position = {5.288, 14.576, 18.938}, orientation = {0, 0, 179.1}})
    elseif button == 14 then
        tes3.positionCell({cell = "Solstheim, Kolfinna's Dwelling", position = {-195.658, -108.075, 38.440}, orientation = {0, 0, 34.1}})
    elseif button == 15 then
        mainMenu()
    elseif button == 16 then
        return
    end
end

local function teleportMenuSolGK()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Gandrung Caverns", "Geilir the Mumbling's Dwelling", "Glenschul's Tomb", "Gloomy Cave", "Graring's House", "Gronn", "Gyldenhul Barrow", "Halls of Penumbra", "Himmelhost Barrow", "Hrothmund's Barrow", "Jolgeirr Barrow", "Kelsedolk Barrow", "Kjolver's Dwelling", "Kolbjorn Barrow", "Kolfinna's Dwelling", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.SolGK(e.button)
        end)
    end})
end

function tome.SolLV(button)

    if button == 0 then
        tes3.positionCell({cell = "Solstheim, Lair of the Udyrfrykte", position = {-102.986, -354.811, 12.255}, orientation = {0, 0, 0}})
    elseif button == 1 then
        tes3.positionCell({cell = "Solstheim, Legge", position = {-169.285, -272.556, 0}, orientation = {0, 0, 0}})
    elseif button == 2 then
        tes3.positionCell({cell = "Solstheim, Lukesturm Barrow", position = {9.000, 26.639, -5.351}, orientation = {0, 0, 179.1}})
    elseif button == 3 then
        tes3.positionCell({cell = "Solstheim, Rimhull", position = {3378.094, 2942.170, 48.374}, orientation = {0, 0, -89.5}})
    elseif button == 4 then
        tes3.positionCell({cell = "Solstheim, Sjobal", position = {-16.978, -476.794, 34.118}, orientation = {0, 0, 0}})
    elseif button == 5 then
        tes3.positionCell({cell = "Solstheim, Skogsdrake Barrow", position = {21.271, 51.431, -21.247}, orientation = {0, 0, 179.1}})
    elseif button == 6 then
        tes3.positionCell({cell = "Solstheim, Skygge", position = {-95.454, -340.562, 0}, orientation = {0, 0, 0}})
    elseif button == 7 then
        tes3.positionCell({cell = "Solstheim, Solvjord", position = {670.609, -413.854, 61.570}, orientation = {0, 0, -22.1}})
    elseif button == 8 then
        tes3.positionCell({cell = "Solstheim, Stahlman's Gorge", position = {1385.557, -273.100, 526.883}, orientation = {0, 0, -125.1}})
    elseif button == 9 then
        tes3.positionCell({cell = "Solstheim, Stormpfund Barrow", position = {4.758, -3.765, 26.164}, orientation = {0, 0, 179.1}})
    elseif button == 10 then
        tes3.positionCell({cell = "Solstheim, Tombs of Skaalara", position = {16.377, 1.050, 27.138}, orientation = {0, 0, 179.1}})
    elseif button == 11 then
        tes3.positionCell({cell = "Solstheim, Ulfgar the Unending's Dwelling", position = {-42.287, -2382.121, 14.383}, orientation = {0, 0, 3.1}})
    elseif button == 12 then
        tes3.positionCell({cell = "Solstheim, Uncle Sweetshare's Workshop", position = {14.506, -240.818, -28.347}, orientation = {0, 0, 0}})
    elseif button == 13 then
        tes3.positionCell({cell = "Solstheim, Valbrandr Barrow", position = {4226.356, 4218.297, 16053.990}, orientation = {0, 0, 179.1}})
    elseif button == 14 then
        tes3.positionCell({cell = "Solstheim, Varstaad Caves", position = {1.601, 443.140, 261.948}, orientation = {0, 0, 179.1}})
    elseif button == 15 then
        mainMenu()
    elseif button == 16 then
        return
    end
end

local function teleportMenuSolLV()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Lair of the Udyrfrykte", "Legge", "Lukesturm Barrow", "Rimhull", "Sjobal", "Skogsdrake Barrow", "Skygge", "Solvjord", "Stahlman's Gorge", "Stormpfund Barrow", "Tomb of Skaalara", "Ulfgar the Unending's Dwelling", "Uncle Sweetshare's Workshop", "Valbrandr Barrow", "Varstaad Caves", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.SolLV(e.button)
        end)
    end})
end

function tome.Sol(button)

    if button == 0 then
        tes3.positionCell({cell = "Fort Frostmoth", position = {-174580.391, 143856.734, 1126.344}, orientation = {0, 0, 179.1}})
    elseif button == 1 then
        tes3.positionCell({cell = "Raven Rock", position = {-197355.328, 159749.469, 824.422}, orientation = {0, 0, -45}})
    elseif button == 2 then
        tes3.positionCell({cell = "Skaal Village", position = {-159040.375, 213038.406, 3040.938}, orientation = {0, 0, 179.1}})
    elseif button == 3 then
        tes3.positionCell({cell = "Solstheim, Thirsk", position = {-128.324, 744.538, -150.985}, orientation = {0, 0, 165}})
    elseif button == 4 then
        teleportMenuSolAF()
    elseif button == 5 then
        teleportMenuSolGK()
    elseif button == 6 then
        teleportMenuSolLV()
    elseif button == 7 then
        mainMenu()
    elseif button == 8 then
        return
    end
end

local function teleportMenuSol()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Fort Frostmoth", "Raven Rock", "Skaal Village", "Thirsk", "Others A-F", "Others G-K", "Others L-V", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.Sol(e.button)
        end)
    end})
end

function tome.Exp(button)

    if button == 0 then
        teleportMenuMou()
    elseif button == 1 then
        teleportMenuSol()
    elseif button == 2 then
        mainMenu()
    elseif button == 3 then
        return
    end
end

local function teleportMenuExp()
    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Mournhold", "Solstheim", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.Exp(e.button)
        end)
    end})
end

function tome.A4(button)

    if button == 0 then
        tes3.positionCell({cell = "Azura's Coast Region", position = {111388.766, 47116.559, 258.117}, orientation = {0, 0, 59}})
    elseif button == 1 then
        tes3.positionCell({cell = "Ashanammu", position = {294.070, -755.965, 342.457}, orientation = {0, 0, -89.5}})
    elseif button == 2 then
        tes3.positionCell({cell = "Ashimanu Egg Mine", position = {539.426, 2688.005, -174.519}, orientation = {0, 0, -89.5}})
    elseif button == 3 then
        tes3.positionCell({cell = "Ashinabi", position = {-4.091, 60.146, 88.687}, orientation = {0, 0, 0}})
    elseif button == 4 then
        tes3.positionCell({cell = "Ashir-Dan", position = {128.818, -2216.621, -423.473}, orientation = {0, 0, 0}})
    elseif button == 5 then
        tes3.positionCell({cell = "Ashirbadon", position = {-544.380, -1840.175, 608.000}, orientation = {0, 0, -89.5}})
    elseif button == 6 then
        tes3.positionCell({cell = "Ashmelech", position = {2816.406, 7016.756, 4306.963}, orientation = {0, 0, 179.1}})
    elseif button == 7 then
        tes3.positionCell({cell = "Ashunartes, Shrine", position = {5607.685, 1787.056, 384.000}, orientation = {0, 0, -89.5}})
    elseif button == 8 then
        tes3.positionCell({cell = "Ashurnibibi, Shrine", position = {-243.507, 1702.584, -294.440}, orientation = {0, 0, 179.1}})
    elseif button == 9 then
        tes3.positionCell({cell = "Assalkushalit, Shrine", position = {254.233, 4160.444, -681.708}, orientation = {0, 0, 179.1}})
    elseif button == 10 then
        tes3.positionCell({cell = "Assarnatamat, Shrine", position = {134.990, 4516.038, -560.000}, orientation = {0, 0, 179.1}})
    elseif button == 11 then
        tes3.positionCell({cell = "Assarnud", position = {153.152, -4.060, 237.788}, orientation = {0, 0, -89.5}})
    elseif button == 12 then
        tes3.positionCell({cell = "Assemanu", position = {-5524.263, 249.121, 212.307}, orientation = {0, 0, 89.5}})
    elseif button == 13 then
        tes3.positionCell({cell = "Assernerairan, Shrine", position = {336.000, 768.000, -432.000}, orientation = {0, 0, -89.5}})
    elseif button == 14 then
        tes3.positionCell({cell = "Assu", position = {509.945, -1746.036, 576.007}, orientation = {0, 0, -89.5}})
    elseif button == 15 then
        tes3.positionCell({cell = "Assumanu", position = {-903.052, 1547.015, 94.678}, orientation = {0, 0, 89.5}})
    elseif button == 16 then
        tes3.positionCell({cell = "Assurdirapal, Shrine", position = {-3325.052, 3980.017, -944.000}, orientation = {0, 0, 179.1}})
    elseif button == 17 then
        tes3.positionCell({cell = "Assurnabitashpi", position = {123.764, -1604.754, 1238.389}, orientation = {0, 0, 179.1}})
    elseif button == 18 then
        mainMenu()
    elseif button == 19 then
        return
    end
end

local function teleportMenuA4()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Ashamanu Camp", "Ashanammu", "Ashimanu Egg Mine", "Ashinabi", "Ashir-Dan", "Ashirbadon", "Ashmelech", "Ashunartes", "Ashurnibibi", "Assalkushalit", "Assarnatamat", "Assarnud", "Assemanu", "Assernerairan", "Assu", "Assumanu", "Assurdirapal", "Assurnabitashpi", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.A4(e.button)
        end)
    end})
end

function tome.A3(button)

    if button == 0 then
        tes3.positionCell({cell = "Andavel Ancestral Tomb", position = {-5212.000, -656.122, 2144.000}, orientation = {0, 0, 179.1}})
    elseif button == 1 then
        tes3.positionCell({cell = "Andrano Ancestral Tomb", position = {1376.000, 7552.000, 14624.000}, orientation = {0, 0, 89.5}})
    elseif button == 2 then
        tes3.positionCell({cell = "Andrethi Ancestral Tomb", position = {2622.785, 1198.403, -809.616}, orientation = {0, 0, -89.5}})
    elseif button == 3 then
        tes3.positionCell({cell = "Andules Ancestral Tomb", position = {-873.483, 50.683, 336.000}, orientation = {0, 0, 0}})
    elseif button == 4 then
        tes3.positionCell({cell = "Ansi", position = {-794.806, 1542.065, 220.775}, orientation = {0, 0, 89.5}})
    elseif button == 5 then
        tes3.positionCell({cell = "Aralen Ancestral Tomb", position = {3547.998, 5728.001, 11520.000}, orientation = {0, 0, 89.5}})
    elseif button == 6 then
        tes3.positionCell({cell = "Aran Ancestral Tomb", position = {-2354.736, 5113.247, -106.918}, orientation = {0, 0, 179.1}})
    elseif button == 7 then
        tes3.positionCell({cell = "Arano Ancestral Tomb", position = {864.040, 2112.659, -624.346}, orientation = {0, 0, -89.5}})
    elseif button == 8 then
        tes3.positionCell({cell = "Arano Plantation", position = {181.875, -104.888, 95.789}, orientation = {0, 0, -45}})
    elseif button == 9 then
        tes3.positionCell({cell = "Arenim Ancestral Tomb", position = {1987.192, -115.135, -195.214}, orientation = {0, 0, 0}})
    elseif button == 10 then
        tes3.positionCell({cell = "Arethan Ancestral Tomb", position = {-736.000, 1568.000, 64.000}, orientation = {0, 0, 0}})
    elseif button == 11 then
        tes3.positionCell({cell = "Arkngthand, Hall of Centrifuge", position = {-801.030, 3607.414, 1616.000}, orientation = {0, 0, 179.1}})
    elseif button == 12 then
        tes3.positionCell({cell = "Arkngthunch-Sturdumz", position = {-2012.758, 1368.461, -1120.000}, orientation = {0, 0, 0}})
    elseif button == 13 then
        tes3.positionCell({cell = "Arvel Manor", position = {642.369, -348.734, 85.078}, orientation = {0, 0, 0}})
    elseif button == 14 then
        tes3.positionCell({cell = "Aryon Ancestral Tomb", position = {-516.048, -6817.083, 1913.612}, orientation = {0, 0, 89.5}})
    elseif button == 15 then
        tes3.positionCell({cell = "Arys Ancestral Tomb", position = {12800.000, -4064.000, -592.698}, orientation = {0, 0, 0}})
    elseif button == 16 then
        tes3.positionCell({cell = "Asha-ahhe Egg Mine", position = {330.024, 147.482, -129.763}, orientation = {0, 0, 0}})
    elseif button == 17 then
        tes3.positionCell({cell = "Ashalmawia, Shrine", position = {257.943, 4035.482, -171.204}, orientation = {0, 0, 179.1}})
    elseif button == 18 then
        tes3.positionCell({cell = "Ashalmimilkala, Shrine", position = {249.457, 4157.349, -827.226}, orientation = {0, 0, 179.1}})
    elseif button == 19 then
        teleportMenuA4()
    elseif button == 20 then
        mainMenu()
    elseif button == 21 then
        return
    end
end

local function teleportMenuA3()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Andavel Ancestral Tomb", "Andrano Ancestral Tomb", "Andrethi Ancestral Tomb", "Andules Ancestral Tomb", "Ansi", "Aralen Ancestral Tomb", "Aran Ancestral Tomb", "Arano Ancestral Tomb", "Arano Plantation", "Arenim Ancestral Tomb", "Arethan Ancestral Tomb", "Arkngthand", "Arkngthunch-Sturdumz", "Arvel Plantation", "Aryon Ancestral Tomb", "Arys Ancestral Tomb", "Asha-Ahhe Egg Mine", "Ashalmawia", "Ashalmimilkala", "Next Page", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.A3(e.button)
        end)
    end})
end

function tome.A2(button)

    if button == 0 then
        tes3.positionCell({cell = "Ainat", position = {-736.000, -1776.000, 608.000}, orientation = {0, 0, -89.5}})
    elseif button == 1 then
        tes3.positionCell({cell = "Akimaes Grotto", position = {-5856.000, 1920.000, -296.115}, orientation = {0, 0, 89.5}})
    elseif button == 2 then
        tes3.positionCell({cell = "Akimaes-Ilanipu Egg Mine", position = {-16.033, 7553.271, -1145}, orientation = {0, 0, 89.5}})
    elseif button == 3 then
        tes3.positionCell({cell = "Alas Ancestral Tomb", position = {-1020.140, -1274.823, 208.000}, orientation = {0, 0, 0}})
    elseif button == 4 then
        tes3.positionCell({cell = "Ald Daedroth, Outer Shrine", position = {-172.268, 378.990, 368.935}, orientation = {0, 0, 179.1}})
    elseif button == 5 then
        tes3.positionCell({cell = "Ald Redaynia, Tower", position = {4453.162, 4101.523, 14576.193}, orientation = {0, 0, -89.5}})
    elseif button == 6 then
        tes3.positionCell({cell = "Ald Sotha, Upper Level", position = {-694.121, 3075.389, -935.462}, orientation = {0, 0, 89.5}})
    elseif button == 7 then
        tes3.positionCell({cell = "Ald Velothi", position = {-85046.273, 126515.828, 968.350}, orientation = {0, 0, -72}})
    elseif button == 8 then
        tes3.positionCell({cell = "Aleft", position = {576.000, 0, 96.000}, orientation = {0, 0, 179.1}})
    elseif button == 9 then
        tes3.positionCell({cell = "Alen Ancestral Tomb", position = {-928.000, 2656.000, 64.000}, orientation = {0, 0, 179.1}})
    elseif button == 10 then
        tes3.positionCell({cell = "Almurbalarammi, Shrine", position = {3767.818, 1015.456, -41.010}, orientation = {0, 0, -89.5}})
    elseif button == 11 then
        tes3.positionCell({cell = "Alof's Farmhouse", position = {40.960, -168.104, -28.333}, orientation = {0, 0, -89.5}})
    elseif button == 12 then
        tes3.positionCell({cell = "An Abandoned Shack", position = {-68.390, -1091.149, 458.074}, orientation = {0, 0, 0}})
    elseif button == 13 then
        tes3.positionCell({cell = "Sheogarad Region", position = {73583.563, 170609.813, 585.673}, orientation = {0, 0, -99}})
    elseif button == 14 then
        tes3.positionCell({cell = "Andalen Ancestral Tomb", position = {866.810, -1014.381, 347.927}, orientation = {0, 0, 0}})
    elseif button == 15 then
        tes3.positionCell({cell = "Andalor Ancestral Tomb", position = {3065.650, 2881.765, 503.395}, orientation = {0, 0, -89.5}})
    elseif button == 16 then
        tes3.positionCell({cell = "Andas Ancestral Tomb", position = {777.565, -541.874, -622.705}, orientation = {0, 0, 0}})
    elseif button == 17 then
        tes3.positionCell({cell = "Andasreth", position = {-68475.234, 46813.227, 1861.841}, orientation = {0, 0, 0}})
    elseif button == 18 then
        teleportMenuA3()
    elseif button == 19 then
        mainMenu()
    elseif button == 20 then
        return
    end
end

local function teleportMenuA2()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Ainat", "Akimaes Grotto", "Akimaes-Ilanipu Egg Mine", "Alas Ancestral Tomb", "Ald Daedroth", "Ald Redaynia", "Ald Sotha", "Ald Velothi", "Aleft", "Alen Ancestral Tomb", "Almurbalarammi", "Alof's Farmhouse", "An Abandoned Shack", "Ancient Shipwreck", "Andalen Ancestral Tomb", "Andalor Ancestral Tomb", "Andas Ancestral Tomb", "Andasreth", "Next Page", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.A2(e.button)
        end)
    end})
end

function tome.A(button)

    if button == 0 then
        tes3.positionCell({cell = "Abaelun Mine", position = {-1522.968, 3034.896, -416.580}, orientation = {0, 0, 0}})
    elseif button == 1 then
        tes3.positionCell({cell = "Abaesen-Pulu Egg Mine", position = {224.105, -1397.514, -2092.981}, orientation = {0, 0, 89.5}})
    elseif button == 2 then
        tes3.positionCell({cell = "Abanabi", position = {-2843.470, 1151.643, 416.811}, orientation = {0, 0, 89.5}})
    elseif button == 3 then
        tes3.positionCell({cell = "Sheogarad Region", position = {8936.84, 188669.328, 156.55}, orientation = {0, 0, 165}})
    elseif button == 4 then
        tes3.positionCell({cell = "Abebaal Egg Mine", position = {929.755, 5630.295, -674.161}, orientation = {0, 0, -89.5}})
    elseif button == 5 then
        tes3.positionCell({cell = "Abernanit", position = {-284.867, 255.532, 601.064}, orientation = {0, 0, 89.5}})
    elseif button == 6 then
        tes3.positionCell({cell = "Abinabi", position = {2180.753, 2034.594, -157.157}, orientation = {0, 0, 0}})
    elseif button == 7 then
        tes3.positionCell({cell = "Adanumuran", position = {1194.982, -4.498, 349.218}, orientation = {0, 0, -89.5}})
    elseif button == 8 then
        tes3.positionCell({cell = "Addadshashanammu, Shrine", position = {4608.042, 7829.745, 13780.849}, orientation = {0, 0, 179.1}})
    elseif button == 9 then
        tes3.positionCell({cell = "Addamasartus", position = {1280.000, 992.000, 480.000}, orientation = {0, 0, 0}})
    elseif button == 10 then
        tes3.positionCell({cell = "Ahallaraddon Egg Mine", position = {1806.764, 2814.783, 530.388}, orientation = {0, 0, -89.5}})
    elseif button == 11 then
        tes3.positionCell({cell = "Ahanibi-Malmus Egg Mine", position = {-721.008, 7170.377, -546.359}, orientation = {0, 0, -89.5}})
    elseif button == 12 then
        tes3.positionCell({cell = "Sheogarad Region", position = {35422.883, 161008.766, 251.771}, orientation = {0, 0, -37}})
    elseif button == 13 then
        tes3.positionCell({cell = "Aharnabi", position = {-1191.344, 2827.520, 838.761}, orientation = {0, 0, 89.5}})
    elseif button == 14 then
        tes3.positionCell({cell = "Aharunartus", position = {172.029, -248.148, -146.470}, orientation = {0, 0, -89.5}})
    elseif button == 15 then
        tes3.positionCell({cell = "Ahemmusa Camp", position = {94337.219, 133704.703, 867.934}, orientation = {0, 0, 0}})
    elseif button == 16 then
        tes3.positionCell({cell = "Ahinipalit", position = {-364.622, 515.099, -532.197}, orientation = {0, 0, -89.5}})
    elseif button == 17 then
        tes3.positionCell({cell = "West Gash Region", position = {-88101.07, 118886.695, 1695.015}, orientation = {0, 0, 89}})
    elseif button == 18 then
        tes3.positionCell({cell = "Ainab", position = {-1291.302, 2817.587, 224.939}, orientation = {0, 0, 89.5}})
    elseif button == 19 then
        teleportMenuA2()
    elseif button == 20 then
        mainMenu()
    elseif button == 21 then
        return
    end
end

local function teleportMenuA()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Abaelun Mine", "Abaesen-Pulu Egg Mine", "Abanabi", "Abandoned Shipwreck", "Abebaal Egg Mine", "Abernanit", "Abinabi", "Adanumuran", "Addadshashanammu", "Addamasartus", "Ahallaraddon Egg Mine", "Ahanibi-Malmus Egg Mine", "Aharasaplit Camp", "Aharnabi", "Aharunartus", "Ahemmusa Camp", "Ahinipalit", "Aidanat Camp", "Ainab", "Next Page", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.A(e.button)
        end)
    end})
end

function tome.B(button)

    if button == 0 then
        tes3.positionCell({cell = "Bal Fell, Outer Shrine", position = {4164.918, 6433.495, 12496.000}, orientation = {0, 0, 179.1}})
    elseif button == 1 then
        tes3.positionCell({cell = "Bal Ur, Shrine", position = {-1920.000, 3328.000, -896.000}, orientation = {0, 0, 89.5}})
    elseif button == 2 then
        tes3.positionCell({cell = "Balur's Farmhouse", position = {220.340, -107.782, -75.080}, orientation = {0, 0, 0}})
    elseif button == 3 then
        tes3.positionCell({cell = "Band Egg Mine", position = {4742.876, 6907.476, -556.794}, orientation = {0, 0, -89.5}})
    elseif button == 4 then
        tes3.positionCell({cell = "Baram Ancestral Tomb", position = {-2532.069, 248.229, 1532.271}, orientation = {0, 0, 179.1}})
    elseif button == 5 then
        tes3.positionCell({cell = "Bensamsi", position = {-2696.265, 2346.727, -393.271}, orientation = {0, 0, 179.1}})
    elseif button == 6 then
        tes3.positionCell({cell = "Azura's Coast Region", position = {108466.719, 25856.018, 336.298}, orientation = {0, 0, 168}})
    elseif button == 7 then
        tes3.positionCell({cell = "Beran Ancestral Tomb", position = {-2554.274, 3920.084, -549.373}, orientation = {0, 0, 0}})
    elseif button == 8 then
        tes3.positionCell({cell = "Berandas", position = {-76944, 76080, 2352}, orientation = {0, 0, -89}})
    elseif button == 9 then
        tes3.positionCell({cell = "Beshara", position = {2087.396, 1031.360, 607.766}, orientation = {0, 0, -89.5}})
    elseif button == 10 then
        tes3.positionCell({cell = "Big Head's Shack", position = {53.519, -38.138, 128.000}, orientation = {0, 0, -89.5}})
    elseif button == 11 then
        tes3.positionCell({cell = "Bthanchend", position = {560.000, 1632.000, -128.000}, orientation = {0, 0, -89.5}})
    elseif button == 12 then
        tes3.positionCell({cell = "Bthuand", position = {-352.000, 2400.000, 256.000}, orientation = {0, 0, 179.1}})
    elseif button == 13 then
        tes3.positionCell({cell = "Bthungthumz", position = {1600.000, 5744.000, -544.000}, orientation = {0, 0, 179.1}})
    elseif button == 14 then
        tes3.positionCell({cell = "Buckmoth Legion Fort, Interior", position = {-3.314, -118.653, -33.685}, orientation = {0, 0, 0}})
    elseif button == 15 then
        mainMenu()
    elseif button == 16 then
        return
    end
end

local function teleportMenuB()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Bal Fell", "Bal Ur", "Balur's Farmhouse", "Band Egg Mine", "Baram Ancestral Tomb", "Bensamsi", "Bensiberib Camp", "Beran Ancestral Tomb", "Berandas", "Beshara", "Big Head's Shack", "Bthanchend", "Bthuand", "Bthungthumz", "Buckmoth Legion Fort", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.B(e.button)
        end)
    end})
end

function tome.C(button)

    if button == 0 then
        tes3.positionCell({cell = "Caldera", position = {-11608.225, 19249.451, 1409.736}, orientation = {0, 0, 0}})
    elseif button == 1 then
        tes3.positionCell({cell = "West Gash Region", position = {-22756.043, 12782.983, 1747.595}, orientation = {0, 0, -160}})
    elseif button == 2 then
        tes3.positionCell({cell = "Ashlands Region", position = {52026.477, 109388.047, 6145.733}, orientation = {0, 0, 10.5}})
    elseif button == 3 then
        tes3.positionCell({cell = "Corprusarium", position = {17.474, -1191.134, 215.989}, orientation = {0, 0, 0}})
    elseif button == 4 then
        mainMenu()
    elseif button == 5 then
        return
    end
end

local function teleportMenuC()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Caldera", "Caldera Mine", "Cavern of the Incarnate", "Corprusarium", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.C(e.button)
        end)
    end})
end

function tome.D2(button)

    if button == 0 then
        tes3.positionCell({cell = "Dreloth Ancestral Tomb", position = {-10.983, 1924.284, 223.000}, orientation = {0, 0, 179.1}})
    elseif button == 1 then
        tes3.positionCell({cell = "Dren Plantation, Dren's Villa", position = {3589.092, 3519.793, 15767.050}, orientation = {0, 0, 179.1}})
    elseif button == 2 then
        tes3.positionCell({cell = "Drethan Ancestral Tomb", position = {5077.188, -2239.904, 916.000}, orientation = {0, 0, -89.5}})
    elseif button == 3 then
        tes3.positionCell({cell = "Drinith Ancestral Tomb", position = {-320.000, -4568.000, 2800.000}, orientation = {0, 0, 179.1}})
    elseif button == 4 then
        tes3.positionCell({cell = "Drulene Falen's Hut", position = {-1.000, -216.000, -166.000}, orientation = {0, 0, 0}})
    elseif button == 5 then
        tes3.positionCell({cell = "Druscashti, Upper Level", position = {2077.101, -785.586, -752.000}, orientation = {0, 0, -89.5}})
    elseif button == 6 then
        tes3.positionCell({cell = "Dubdilla", position = {3796.125, 1482.072, 6024.174}, orientation = {0, 0, -89.5}})
    elseif button == 7 then
        tes3.positionCell({cell = "Dulo Ancestral Tomb", position = {1727.059, 199.944, 2032.000}, orientation = {0, 0, -89.5}})
    elseif button == 8 then
        tes3.positionCell({cell = "Dun-Ahhe", position = {-4324.000, 3736.000, -684.000}, orientation = {0, 0, 89.5}})
    elseif button == 9 then
        tes3.positionCell({cell = "Dunirai Caverns", position = {-2587.325, 4479.520, 733.672}, orientation = {0, 0, 89.5}})
    elseif button == 10 then
        tes3.positionCell({cell = "Dushariran, Shrine", position = {135.814, 3981.229, -688.000}, orientation = {0, 0, 179.1}})
    elseif button == 11 then
        mainMenu()
    elseif button == 12 then
        return
    end
end

local function teleportMenuD2()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Dreloth Ancestral Tomb", "Dren Plantation", "Drethan Ancestral Tomb", "Drinith Ancestral Tomb", "Drulene Falen's Hut", "Druscashti", "Dubdilla", "Dulo Ancestral Tomb", "Dun-Ahhe", "Dunirai Caverns", "Dushariran", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.D2(e.button)
        end)
    end})
end

function tome.D(button)

    if button == 0 then
        tes3.positionCell({cell = "Dagon Fel", position = {62455.566, 182538.906, 227.483}, orientation = {0, 0, -89.5}})
    elseif button == 1 then
        tes3.positionCell({cell = "Dagoth Ur, Outer Facility", position = {0, -40.000, 96.000}, orientation = {0, 0, 179.1}})
    elseif button == 2 then
        tes3.positionCell({cell = "Dareleth Ancestral Tomb", position = {3841.013, -3036.513, 1680.000}, orientation = {0, 0, -89.5}})
    elseif button == 3 then
        tes3.positionCell({cell = "Sheogarad Region", position = {-51763.508, 152122.156, 349.072}, orientation = {0, 0, 159}})
    elseif button == 4 then
        tes3.positionCell({cell = "Azura's Coast Region", position = {74576.641, -86877.875, -92.841}, orientation = {0, 0, 5.7}})
    elseif button == 5 then
        tes3.positionCell({cell = "Ascadian Isles Region", position = {12162.709, -45662.477, -883.232}, orientation = {0, 0, 0}})
    elseif button == 6 then
        tes3.positionCell({cell = "Dirara's Farmhouse", position = {318.333, -47.681, -43.080}, orientation = {0, 0, 28.6}})
    elseif button == 7 then
        tes3.positionCell({cell = "Dissapla Mine", position = {-2649.334, -1151.120, 224.699}, orientation = {0, 0, 89.5}})
    elseif button == 8 then
        tes3.positionCell({cell = "Dralas Ancestral Tomb", position = {-2840.584, -3487.175, 1296.000}, orientation = {0, 0, 0}})
    elseif button == 9 then
        tes3.positionCell({cell = "Drath Ancestral Tomb", position = {-2480.000, -3100.000, 920.000}, orientation = {0, 0, 89.5}})
    elseif button == 10 then
        teleportMenuD2()
    elseif button == 11 then
        mainMenu()
    elseif button == 12 then
        return
    end
end

local function teleportMenuD()

    tes3.messageBox({message = "Teleport to Where ?", buttons = { "Dagon Fel", "Dagoth Ur", "Dareleth Ancestral Tomb", "Derilict Shipwreck", "Deserted Shipwreck", "Desolate Shipwreck", "Dirara's Farmhouse", "Dissapla Mine", "Dralas Ancestral Tomb", "Drath Ancestral Tomb", "Next Page", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.D(e.button)
        end)
    end})
end

function tome.E(button)

    if button == 0 then
        tes3.positionCell({cell = "Ebernanit, Shrine", position = {-253.348, 4301.191, -688.000}, orientation = {0, 0, 179.1}})
    elseif button == 1 then
        tes3.positionCell({cell = "Ebonheart", position = {13577.879, -101930.016, 832}, orientation = {0, 0, 0}})
    elseif button == 2 then
        tes3.positionCell({cell = "Grazelands Region", position = {86155.281, 63565.363, 1120.236}, orientation = {0, 0, 76}})
    elseif button == 3 then
        tes3.positionCell({cell = "Elith-Pal Mine", position = {2013.957, 2309.413, 34.925}, orientation = {0, 0, -89.5}})
    elseif button == 4 then
        tes3.positionCell({cell = "Eluba-Addon Egg Mine", position = {-930.188, 4092.263, 1515.485}, orientation = {0, 0, 89.5}})
    elseif button == 5 then
        tes3.positionCell({cell = "Eluba-Addon Grotto", position = {-2016.000, 4096.000, -176.000}, orientation = {0, 0, 89.5}})
    elseif button == 6 then
        tes3.positionCell({cell = "Endusal, Kagrenac's study", position = {3.865, -44.002, 84.722}, orientation = {0, 0, 179.1}})
    elseif button == 7 then
        tes3.positionCell({cell = "Erabenimsun Camp", position = {110351.516, -3410.381, 637.86, 235}, orientation = {0, 0, -125}})
    elseif button == 8 then
        tes3.positionCell({cell = "Eretammus-Sennammu Egg Mine", position = {-3873.166, 4100.057, -682.082}, orientation = {0, 0, 89.5}})
    elseif button == 9 then
        tes3.positionCell({cell = "Esutanamus, Shrine", position = {25.931, 4282.229, -422.200}, orientation = {0, 0, 179.1}})
    elseif button == 10 then
        mainMenu()
    elseif button == 11 then
        return
    end
end

local function teleportMenuE()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Ebernanit", "Ebonheart", "Elanius Camp", "Elith-Pal Mine", "Eluba-Addon Egg Mine", "Eluba-Addon Grotto", "Endusal", "Erabenimsun Camp", "Eretammus-Sennammu Egg Mine", "Esutanamus", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.E(e.button)
        end)
    end})
end

function tome.F(button)

    if button == 0 then
        tes3.positionCell({cell = "Fadathram Ancestral Tomb", position = {-391.125, 511.601, 535.955}, orientation = {0, 0, 89.5}})
    elseif button == 1 then
        tes3.positionCell({cell = "Falas Ancestral Tomb", position = {134.574, 22.636, 96.000}, orientation = {0, 0, 0}})
    elseif button == 2 then
        tes3.positionCell({cell = "Falasmaryon", position = {-12904.959, 126525.484, 1455.416}, orientation = {0, 0, 17}})
    elseif button == 3 then
        tes3.positionCell({cell = "Falensarano", position = {76899.828, 53324.578, 1678}, orientation = {0, 0, -89.5}})
    elseif button == 4 then
        tes3.positionCell({cell = "Favel Ancestral Tomb", position = {-63.753, 2082.876, 838.322}, orientation = {0, 0, 179.1}})
    elseif button == 5 then
        tes3.positionCell({cell = "West Gash Region", position = {-100230.375, 124807.617, -1438.026}, orientation = {0, 0, -63}})
    elseif button == 6 then
        tes3.positionCell({cell = "Forgotten Vaults of Anudnabia, Forge of Hilbongard", position = {3329.487, 1113.396, -1050}, orientation = {0, 0, -6}})
    elseif button == 7 then
        mainMenu()
    elseif button == 8 then
        return
    end
end

local function teleportMenuF()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Fadathram Ancestral Tomb", "Falas Ancestral Tomb", "Falasmaryon", "Falensarano", "Favel Ancestral Tomb", "Forgotten Shipwreck", "Forgotten Vaults of Anudnabia", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.F(e.button)
        end)
    end})
end

function tome.G(button)

    if button == 0 then
        tes3.positionCell({cell = "Galom Daeus, Entry", position = {-732.552, 5502.982, 12304.000}, orientation = {0, 0, 89.5}})
    elseif button == 1 then
        tes3.positionCell({cell = "Ghostgate", position = {20736.174, 38296.58, 1162}, orientation = {0, 0, 0}})
    elseif button == 2 then
        tes3.positionCell({cell = "Gimothran Ancestral Tomb", position = {-668.000, -336.000, 1048.000}, orientation = {0, 0, 179.1}})
    elseif button == 3 then
        tes3.positionCell({cell = "Ginith Ancestral Tomb", position = {6.100, -9.526, 474.128}, orientation = {0, 0, 0}})
    elseif button == 4 then
        tes3.positionCell({cell = "Gnaar Mok", position = {-60631.27, 26113.229, 482.725}, orientation = {0, 0, 0}})
    elseif button == 5 then
        tes3.positionCell({cell = "Gnisis", position = {-84628.141, 91450.18, 1085.842}, orientation = {0, 0, -34}})
    elseif button == 6 then
        tes3.positionCell({cell = "Gro-Bagrat Plantation", position = {381.525, -92.875, -297.478}, orientation = {0, 0, 0}})
    elseif button == 7 then
        mainMenu()
    elseif button == 8 then
        return
    end
end

local function teleportMenuG()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Galom Daeus", "Ghostgate", "Gimothran Ancestral Tomb", "Ginith Ancestral Tomb", "Gnaar Mok", "Gnisis", "Gro-Bagrat Plantation", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.G(e.button)
        end)
    end})
end

function tome.H(button)

    if button == 0 then
        tes3.positionCell({cell = "Habinbaes", position = {1693.730, 3579.733, -544.000}, orientation = {0, 0, -89.5}})
    elseif button == 1 then
        tes3.positionCell({cell = "Hairat-Vassamsi Egg Mine", position = {-3452.883, 5438.230, -418.640}, orientation = {0, 0, 179.1}})
    elseif button == 2 then
        tes3.positionCell({cell = "Halit Mine", position = {-1129.636, -503.643, 160.143}, orientation = {0, 0, 89.5}})
    elseif button == 3 then
        tes3.positionCell({cell = "Hanud", position = {4836.233, 7416.191, -299.612}, orientation = {0, 0, -89.5}})
    elseif button == 4 then
        tes3.positionCell({cell = "Hassour", position = {-5274.100, 3577.503, -1570.918}, orientation = {0, 0, 89.5}})
    elseif button == 5 then
        tes3.positionCell({cell = "Hawia Egg Mine", position = {-1676.204, 1927.151, -1196.863}, orientation = {0, 0, 89.5}})
    elseif button == 6 then
        tes3.positionCell({cell = "Helan Ancestral Tomb", position = {-1790.895, 381.134, 342.533}, orientation = {0, 0, 0}})
    elseif button == 7 then
        tes3.positionCell({cell = "Helas Ancestral Tomb", position = {-2170.810, 998.104, 377.370}, orientation = {0, 0, 89.5}})
    elseif button == 8 then
        tes3.positionCell({cell = "Heleran Ancestral Tomb", position = {1937.453, 3650.716, 15324.959}, orientation = {0, 0, 89.5}})
    elseif button == 9 then
        tes3.positionCell({cell = "Heran Ancestral Tomb", position = {-16.359, 2755.654, 336.000}, orientation = {0, 0, 179.1}})
    elseif button == 10 then
        tes3.positionCell({cell = "Hinnabi", position = {609.323, -10.968, 483.219}, orientation = {0, 0, -89.5}})
    elseif button == 11 then
        tes3.positionCell({cell = "Hla Oad", position = {-47875.207, -38710.547, 310.294}, orientation = {0, 0, 89.9}})
    elseif button == 12 then
        tes3.positionCell({cell = "Hlaalu Ancestral Tomb", position = {-245.877, 1225.168, 467.894}, orientation = {0, 0, 179.1}})
    elseif button == 13 then
        tes3.positionCell({cell = "Hleran Ancestral Tomb", position = {-792.141, -714.598, 115.722}, orientation = {0, 0, 0}})
    elseif button == 14 then
        tes3.positionCell({cell = "Hlervi Ancestral Tomb", position = {3136.000, -864.000, 1149.967}, orientation = {0, 0, -89.5}})
    elseif button == 15 then
        tes3.positionCell({cell = "Hlervu Ancestral Tomb", position = {-2.985, 2550.127, -432.000}, orientation = {0, 0, 179.1}})
    elseif button == 16 then
        tes3.positionCell({cell = "Hlormaren", position = {-44386, -3908, 2386}, orientation = {0, 0, 179.1}})
    elseif button == 17 then
        tes3.positionCell({cell = "Holamayan", position = {159099.5, -30521.111, 2073.076}, orientation = {0, 0, 0}})
    elseif button == 18 then
        mainMenu()
    elseif button == 19 then
        return
    end
end

local function teleportMenuH()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Habinbaes", "Hairat-Vassamsi Egg Mine", "Halit Mine", "Hanud", "Hassour", "Hawia Egg Mine", "Helan Ancestral Tomb", "Helas Ancestral Tomb", "Heleran Ancestral Tomb", "Heran Ancestral Tomb", "Hinnabi", "Hla Oad", "Hlaalu Ancestral Tomb", "Hleran Ancestral Tomb", "Hlervi Ancestral Tomb", "Hlervu Ancestral Tomb", "Hlormaren", "Holamayan Monastery", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.H(e.button)
        end)
    end})
end

function tome.I(button)

    if button == 0 then
        tes3.positionCell({cell = "Ibar-Dad", position = {-3087.850, 4722.124, -159.271}, orientation = {0, 0, 89.5}})
    elseif button == 1 then
        tes3.positionCell({cell = "Ibishammus, Shrine", position = {443.135, 768.763, -550.441}, orientation = {0, 0, -89.5}})
    elseif button == 2 then
        tes3.positionCell({cell = "Ienith Ancestral Tomb", position = {-1077.025, 347.799, 193.224}, orientation = {0, 0, 0}})
    elseif button == 3 then
        tes3.positionCell({cell = "Ihinipalit, Shrine", position = {720.000, 896.000, -432.000}, orientation = {0, 0, -89.5}})
    elseif button == 4 then
        tes3.positionCell({cell = "Ilanipu Grotto", position = {-7173.957, 2808.000, -681.079}, orientation = {0, 0, 89.5}})
    elseif button == 5 then
        tes3.positionCell({cell = "Ilunibi, Carcass of the Saint", position = {3968.000, 6048.000, 1509}, orientation = {0, 0, 179.1}})
    elseif button == 6 then
        tes3.positionCell({cell = "Inanius Egg Mine", position = {-2815.673, -415.449, 721.200}, orientation = {0, 0, 0}})
    elseif button == 7 then
        tes3.positionCell({cell = "Indalen Ancestral Tomb", position = {-486.060, -96.965, 2565.255}, orientation = {0, 0, 179.1}})
    elseif button == 8 then
        tes3.positionCell({cell = "Indaren Ancestral Tomb", position = {-2664.450, -1241.092, 813.575}, orientation = {0, 0, 89.5}})
    elseif button == 9 then
        tes3.positionCell({cell = "Bal Isra", position = {-35363.855, 79659.125, 1828.908}, orientation = {0, 0, -130}})
    elseif button == 10 then
        tes3.positionCell({cell = "Azura's Coast Region", position = {119894.852, 76614.875, 1418.966}, orientation = {0, 0, -89.5}})
    elseif button == 11 then
        mainMenu()
    elseif button == 12 then
        return
    end
end

local function teleportMenuI()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Ibar-Dad", "Ibishammus", "Ienith Ancestral Tomb", "Ihinipalit", "Ilanipu Grotto", "Ilunibi", "Inanius Egg Mine", "Indalen Ancestral Tomb", "Indaren Ancestral Tomb", "Indarys Manor", "Indoranyon", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.I(e.button)
        end)
    end})
end

function tome.K(button)

    if button == 0 then
        tes3.positionCell({cell = "Azura's Coast Region", position = {110395.375, -72924.695, 1079.31}, orientation = {0, 0, 42.5}})
    elseif button == 1 then
        tes3.positionCell({cell = "Kaushtarari, Shrine", position = {3.339, 3009.927, -432.000}, orientation = {0, 0, 179.1}})
    elseif button == 2 then
        tes3.positionCell({cell = "Khuul", position = {-69823.047, 140879.281, 315.28}, orientation = {0, 0, 89.5}})
    elseif button == 3 then
        tes3.positionCell({cell = "Koal Cave", position = {2738.256, 886.712, 294.042}, orientation = {0, 0, 89.5}})
    elseif button == 4 then
        tes3.positionCell({cell = "Kogoruhn", position = {5216.000, 120544.000, 1504.000}, orientation = {0, 0, 179.1}})
    elseif button == 5 then
        tes3.positionCell({cell = "Kora-Dur", position = {2691.030, -6364.320, 433.182}, orientation = {0, 0, 179.1}})
    elseif button == 6 then
        tes3.positionCell({cell = "Kudanat", position = {-89.793, 1.718, 86.135, 270}, orientation = {0, 0, -89.5}})
    elseif button == 7 then
        tes3.positionCell({cell = "Kumarahaz", position = {795.954, 3208.768, 84.750}, orientation = {0, 0, -89.5}})
    elseif button == 8 then
        tes3.positionCell({cell = "Kunirai", position = {1406.380, -811.684, 602.904}, orientation = {0, 0, 0}})
    elseif button == 9 then
        tes3.positionCell({cell = "Kushtashpi, Shrine", position = {-10.505, 6207.849, 353.538}, orientation = {0, 0, 179.1}})
    elseif button == 10 then
        mainMenu()
    elseif button == 11 then
        return
    end
end

local function teleportMenuK()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Kaushtababi Camp", "Kaushtarari", "Khuul", "Koal Cave", "Kogoruhn", "Kora-Dur", "Kudanat", "Kumarahaz", "Kunirai", "Kushtashpi", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.K(e.button)
        end)
    end})
end

function tome.L(button)

    if button == 0 then
        tes3.positionCell({cell = "Llando Ancestral Tomb", position = {-964.536, 5416.220, 681.203}, orientation = {0, 0, 179.1}})
    elseif button == 1 then
        tes3.positionCell({cell = "Lleran Ancestral Tomb", position = {994.029, -903.218, 192.917}, orientation = {0, 0, 0}})
    elseif button == 2 then
        tes3.positionCell({cell = "Llervu Ancestral Tomb", position = {-2.274, -2.851, 104.226}, orientation = {0, 0, 0}})
    elseif button == 3 then
        tes3.positionCell({cell = "Llirala's Shack", position = {35.611, -52.012, -11.627}, orientation = {0, 0, -89.5}})
    elseif button == 4 then
        tes3.positionCell({cell = "Llovyn's Farmhouse", position = {874.906, 78.851, 84.920}, orientation = {0, 0, -166}})
    elseif button == 5 then
        tes3.positionCell({cell = "Azura's Coast Region", position = {155414.656, -7392.085, -288.781}, orientation = {0, 0, -52}})
    elseif button == 6 then
        tes3.positionCell({cell = "Azura's Coast Region", position = {111250.578, 128260.359, -663.866}, orientation = {0, 0, -13}})
    elseif button == 7 then
        tes3.positionCell({cell = "Azura's Coast Region", position = {127840.094, 94267.617, -313.375}, orientation = {0, 0, -52}})
    elseif button == 8 then
        mainMenu()
    elseif button == 9 then
        return
    end
end

local function teleportMenuL()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Llando Ancestral Tomb", "Lleran Ancestral Tomb", "Llervu Ancestral Tomb", "Llirala's Shack", "Llovyn's Farmhouse", "Lonely Shipwreck", "Lonesome Shipwreck", "Lost Shipwreck", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.L(e.button)
        end)
    end})
end

function tome.M2(button)

    if button == 0 then
        tes3.positionCell({cell = "Masseranit", position = {1669.761, 1799.801, -675.746}, orientation = {0, 0, 0}})
    elseif button == 1 then
        tes3.positionCell({cell = "Mat", position = {5700.845, 6356.055, 8896.693}, orientation = {0, 0, 0}})
    elseif button == 2 then
        tes3.positionCell({cell = "Matus-Akin Egg Mine", position = {802.405, -889.791, -1583.628}, orientation = {0, 0, -89.5}})
    elseif button == 3 then
        tes3.positionCell({cell = "Mausur Caverns", position = {1856.000, 2816.000, -96.000}, orientation = {0, 0, -89.5}})
    elseif button == 4 then
        tes3.positionCell({cell = "Mawia", position = {2035.637, 1790.328, -1196.791}, orientation = {0, 0, -89.5}})
    elseif button == 5 then
        tes3.positionCell({cell = "Mila-Nipal, Manat's Yurt", position = {4108.101, 3963.144, 14755.774}, orientation = {0, 0, -89.5}})
    elseif button == 6 then
        tes3.positionCell({cell = "Milk", position = {2588.222, -1905.808, 350.129}, orientation = {0, 0, -89.5}})
    elseif button == 7 then
        tes3.positionCell({cell = "Minabi", position = {-2706.997, 3078.648, 1119.613}, orientation = {0, 0, 89.5}})
    elseif button == 8 then
        tes3.positionCell({cell = "Missamsi", position = {4907.920, -1137.275, -2717.846}, orientation = {0, 0, -89.5}})
    elseif button == 9 then
        tes3.positionCell({cell = "Missir-Dadalit Egg Mine", position = {2330.094, 3401.095, -813.651}, orientation = {0, 0, 0}})
    elseif button == 10 then
        tes3.positionCell({cell = "Molag Mar", position = {110654.07, -61649.105, 2128}, orientation = {0, 0, 179.1}})
    elseif button == 11 then
        tes3.positionCell({cell = "Moonmoth Legion Fort, Interior", position = {-116.140, 18.225, -46.862}, orientation = {0, 0, 0}})
    elseif button == 12 then
        tes3.positionCell({cell = "Morvayn Manor", position = {4149.940, 4211.546, 14739.750}, orientation = {0, 0, 179.1}})
    elseif button == 13 then
        tes3.positionCell({cell = "Mount Kand, Cavern", position = {3703.474, 4324.122, 13916.574}, orientation = {0, 0, 0}})
    elseif button == 14 then
        tes3.positionCell({cell = "Mudan Grotto", position = {-5505.778, 4126.052, -173.993}, orientation = {0, 0, 179.1}})
    elseif button == 15 then
        tes3.positionCell({cell = "Mudan-Mul Egg Mine", position = {352.000, 768.000, -928.000}, orientation = {0, 0, 89.5}})
    elseif button == 16 then
        tes3.positionCell({cell = "Mul Grotto", position = {-2144.000, 5752.000, -296.398}, orientation = {0, 0, 89.5}})
    elseif button == 17 then
        tes3.positionCell({cell = "Mzahnch", position = {3520.000, 3392.000, 736.000}, orientation = {0, 0, 179.1}})
    elseif button == 18 then
        tes3.positionCell({cell = "Mzanchend", position = {-96.000, 160.000, 64.000}, orientation = {0, 0, 0}})
    elseif button == 19 then
        tes3.positionCell({cell = "Mzuleft", position = {-704.297, 1241.099, -715.413}, orientation = {0, 0, 0}})
    elseif button == 20 then
        mainMenu()
    elseif button == 21 then
        return
    end
end

local function teleportMenuM2()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Masseranit", "Mat", "Matus-Akin Egg Mine", "Mausur Caverns", "Mawia", "Mila-Nipal Camp", "Milk", "Minabi", "Missamsi", "Missir-Dadalit Egg Mine", "Molag Mar", "Moonmoth Legion Fort", "Morvayn Manor", "Mount Kand Cavern", "Mudan Grotto", "Mudan-Mul Egg Mine", "Mul Grotto", "Mzahnch", "Mzanchend", "Mzuleft", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.M2(e.button)
        end)
    end})
end

function tome.M(button)

    if button == 0 then
        tes3.positionCell({cell = "Maar Gan", position = {-20370.283, 102760.078, 1980}, orientation = {0, 0, -34}})
    elseif button == 1 then
        tes3.positionCell({cell = "Maba-Ilu", position = {1153.188, -3091.250, 351.363}, orientation = {0, 0, -89.5}})
    elseif button == 2 then
        tes3.positionCell({cell = "Mababi", position = {1043.222, 1527.955, -668.258}, orientation = {0, 0, 89.5}})
    elseif button == 3 then
        tes3.positionCell({cell = "Madas Grotto", position = {-1525.862, 4999.073, -36.893}, orientation = {0, 0, 179.1}})
    elseif button == 4 then
        tes3.positionCell({cell = "Madas-Zebba Egg Mine", position = {2179.461, 9022.917, -411.202}, orientation = {0, 0, -89.5}})
    elseif button == 5 then
        tes3.positionCell({cell = "Maelkashishi, Shrine", position = {3848.650, 5832.829, 13904.000}, orientation = {0, 0, 179.1}})
    elseif button == 6 then
        tes3.positionCell({cell = "Maelu Egg Mine", position = {-2046.340, 4222.834, -812.549}, orientation = {0, 0, 89.5}})
    elseif button == 7 then
        tes3.positionCell({cell = "Maesa-Shammus Egg Mine", position = {-465.592, 2943.169, -1066.147}, orientation = {0, 0, -89.5}})
    elseif button == 8 then
        tes3.positionCell({cell = "Mallapi", position = {1918.531, 2557.449, 858.904}, orientation = {0, 0, 0}})
    elseif button == 9 then
        tes3.positionCell({cell = "Malmus Grotto", position = {-3664.000, 240.000, -1074.458}, orientation = {0, 0, 89.5}})
    elseif button == 10 then
        tes3.positionCell({cell = "Mamaea, Sanctum of Awakening", position = {5222.000, 5274.000, 492}, orientation = {0, 0, 179.1}})
    elseif button == 11 then
        tes3.positionCell({cell = "Ashlands Region", position = {13813.07, 120960.414, 785.014}, orientation = {0, 0, 157}})
    elseif button == 12 then
        tes3.positionCell({cell = "Manat's Farmhouse", position = {461.790, 246.493, -43.080}, orientation = {0, 0, 89.5}})
    elseif button == 13 then
        tes3.positionCell({cell = "Mannammu", position = {-4751.063, 2556.357, 739.308}, orientation = {0, 0, 89.5}})
    elseif button == 14 then
        tes3.positionCell({cell = "Maran-Adon", position = {4351.719, 5685.893, 14190.312}, orientation = {0, 0, 0}})
    elseif button == 15 then
        tes3.positionCell({cell = "Marandus", position = {35833.527, -20689.791, 1454.000}, orientation = {0, 0, 40}})
    elseif button == 16 then
        tes3.positionCell({cell = "Maren Ancestral Tomb", position = {-1442.830, 2032.039, -47.327}, orientation = {0, 0, 179.1}})
    elseif button == 17 then
        tes3.positionCell({cell = "Marvani Ancestral Tomb", position = {-604.816, 4852.815, -942.650}, orientation = {0, 0, 179.1}})
    elseif button == 18 then
        tes3.positionCell({cell = "Grazelands Region", position = {109066.234, 70085.602, 1338.397}, orientation = {0, 0, 25}})
    elseif button == 19 then
        tes3.positionCell({cell = "Massama Cave", position = {1754.929, -252.065, 480.301}, orientation = {0, 0, -89.5}})
    elseif button == 20 then
        teleportMenuM2()
    elseif button == 21 then
        mainMenu()
    elseif button == 22 then
        return
    end
end

local function teleportMenuM()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Maar Gan", "Maba-Ilu", "Mababi", "Madas Grotto", "Madas-Zebba Egg Mine", "Maelkashishi", "Maelu Egg Mine", "Maesa-Shammus Egg Mine", "Mallapi", "Malmus Grotto", "Mamaea", "Mamshar-Disamus Camp", "Manat's Farmhouse", "Mannammu", "Maran-Adon", "Marandus", "Maren Ancestral Tomb", "Marvani Ancestral Tomb", "Massahanud Camp", "Massama Cave", "Next Page", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.M(e.button)
        end)
    end})
end

function tome.N(button)

    if button == 0 then
        tes3.positionCell({cell = "Nallit", position = {1537.736, 2405.549, 859.023}, orientation = {0, 0, 0}})
    elseif button == 1 then
        tes3.positionCell({cell = "Nammu", position = {-2095.361, 3210.625, -551.906}, orientation = {0, 0, 89.5}})
    elseif button == 2 then
        tes3.positionCell({cell = "Nchardahrk", position = {2240.000, 3744.000, 32.000}, orientation = {0, 0, -89.5}})
    elseif button == 3 then
        tes3.positionCell({cell = "Nchardumz", position = {-128.000, 4480.000, -64.000}, orientation = {0, 0, 179.1}})
    elseif button == 4 then
        tes3.positionCell({cell = "Nchuleft", position = {-512.000, -592.000, 912.000}, orientation = {0, 0, 179.1}})
    elseif button == 5 then
        tes3.positionCell({cell = "Nchuleftingth, Upper Levels", position = {1344.000, -224.000, 96.000}, orientation = {0, 0, 0}})
    elseif button == 6 then
        tes3.positionCell({cell = "Nchurdamz, Interior", position = {2332.800, 896.000, -32.000}, orientation = {0, 0, -89.5}})
    elseif button == 7 then
        tes3.positionCell({cell = "Bitter Coast Region", position = {-73766.977, 39569.609, 35.058}, orientation = {0, 0, -132}})
    elseif button == 8 then
        tes3.positionCell({cell = "Nelas Ancestral Tomb", position = {-2748.000, 2180.000, 1396.000}, orientation = {0, 0, 89.5}})
    elseif button == 9 then
        tes3.positionCell({cell = "Nerano Ancestral Tomb", position = {-2613.048, 2900.472, -494.443}, orientation = {0, 0, 179.1}})
    elseif button == 10 then
        tes3.positionCell({cell = "Nilera's Farmhouse", position = {602.524, -55.562, -36.722}, orientation = {0, 0, -160}})
    elseif button == 11 then
        tes3.positionCell({cell = "Nimawia Grotto", position = {760.000, 1792.000, -297.847}, orientation = {0, 0, -89.5}})
    elseif button == 12 then
        tes3.positionCell({cell = "Nissintu", position = {-1836.650, 4989.005, -115}, orientation = {0, 0, 89.5}})
    elseif button == 13 then
        tes3.positionCell({cell = "Norvayn Ancestral Tomb", position = {-1155.346, -1792.629, 1817.022}, orientation = {0, 0, 89.5}})
    elseif button == 14 then
        tes3.positionCell({cell = "Nund", position = {-641.493, 3692.624, -1437.248}, orientation = {0, 0, 89.5}})
    elseif button == 15 then
        mainMenu()
    elseif button == 16 then
        return
    end
end

local function teleportMenuN()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Nallit", "Nammu", "Nchardahrk", "Nchardumz", "Nchuleft", "Nchuleftingth", "Nchurdamz", "Neglected Shipwreck", "Nelas Ancestral Tomb", "Nerano Ancestral Tomb", "Nilera's Farmhouse", "Nimawia Grotto", "Nissintu", "Norvayn Ancestral Tomb", "Nund", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.N(e.button)
        end)
    end})
end

function tome.O(button)

    if button == 0 then
        tes3.positionCell({cell = "Sheogorad Region", position = {-6076.179, 191792.141, -1083.987}, orientation = {0, 0, 0}})
    elseif button == 1 then
        tes3.positionCell({cell = "Odaishah", position = {1542.922, 1165.476, 771.5}, orientation = {0, 0, 0}})
    elseif button == 2 then
        tes3.positionCell({cell = "Odibaal", position = {-3852.155, -387.141, -222.135}, orientation = {0, 0, 89.5}})
    elseif button == 3 then
        tes3.positionCell({cell = "Odirnamat", position = {1280.362, 3937.982, 465.763}, orientation = {0, 0, 0}})
    elseif button == 4 then
        tes3.positionCell({cell = "Odirniran", position = {347.654, 4863.180, -1065.611}, orientation = {0, 0, -89.5}})
    elseif button == 5 then
        tes3.positionCell({cell = "Odrosal, Dwemer Training Academy", position = {0, 0, 64}, orientation = {0, 0, 179.1}})
    elseif button == 6 then
        tes3.positionCell({cell = "Omalen Ancestral Tomb", position = {-1508.000, -1636.000, 1284.000}, orientation = {0, 0, 179.1}})
    elseif button == 7 then
        tes3.positionCell({cell = "Omani Manor", position = {4592.232, 3318.980, 15962.136}, orientation = {0, 0, -89.5}})
    elseif button == 8 then
        tes3.positionCell({cell = "Omaren Ancestral Tomb", position = {2031.945, -6074.258, 2123.721}, orientation = {0, 0, 0}})
    elseif button == 9 then
        tes3.positionCell({cell = "Onnissiralis, Shrine", position = {-1284.253, 2169.552, -172.567}, orientation = {0, 0, 89.5}})
    elseif button == 10 then
        tes3.positionCell({cell = "Orethi Ancestral Tomb", position = {978.460, -876.555, 80.000}, orientation = {0, 0, 0}})
    elseif button == 11 then
        tes3.positionCell({cell = "Othrelas Ancestral Tomb", position = {1853.587, 779.172, 730.527}, orientation = {0, 0, -89.5}})
    elseif button == 12 then
        mainMenu()
    elseif button == 13 then
        return
    end
end

local function teleportMenuO()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Obscure Shipwreck", "Odaishah", "Odibaal", "Odirnamat", "Odirniran", "Odrosal", "Omalen Ancestral Tomb", "Omani Manor", "Omaren Ancestral Tomb", "Onnissiralis", "Orethi Ancestral Tomb", "Othrelas Ancestral Tomb", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.O(e.button)
        end)
    end})
end

function tome.P(button)

    if button == 0 then
        tes3.positionCell({cell = "Palansour", position = {43.901, -92.852, 120.060}, orientation = {0, 0, 179.1}})
    elseif button == 1 then
        tes3.positionCell({cell = "Panabanit-Nimawia Egg Mine", position = {2218.950, -2178.629, -1199.279}, orientation = {0, 0, -89.5}})
    elseif button == 2 then
        tes3.positionCell({cell = "Panat", position = {-1149.067, 3595.830, 341.991}, orientation = {0, 0, 179.1}})
    elseif button == 3 then
        tes3.positionCell({cell = "Panud Egg Mine", position = {2828.188, 3203.235, -558.054}, orientation = {0, 0, -89.5}})
    elseif button == 4 then
        tes3.positionCell({cell = "Pelagiad", position = {3579.959, -56640.824, 1696.974}, orientation = {0, 0, 0}})
    elseif button == 5 then
        tes3.positionCell({cell = "Piernette's Farmhouse", position = {5753.180, 5994.233, 14553.611}, orientation = {0, 0, 179.1}})
    elseif button == 6 then
        tes3.positionCell({cell = "Pinsun", position = {695.524, 133.044, -936.000}, orientation = {0, 0, -89.5}})
    elseif button == 7 then
        tes3.positionCell({cell = "Piran", position = {1373.604, 3846.307, -1310.064}, orientation = {0, 0, 89.5}})
    elseif button == 8 then
        tes3.positionCell({cell = "Azura's Coast Region", position = {94996.422, -96522.516, 248.584}, orientation = {0, 0, -15}})
    elseif button == 9 then
        tes3.positionCell({cell = "Pudai Egg Mine", position = {-1422.718, 1392.762, -430.898}, orientation = {0, 0, 89.5}})
    elseif button == 10 then
        tes3.positionCell({cell = "Pulk", position = {160.000, 320.000, 352.000}, orientation = {0, 0, 89.5}})
    elseif button == 11 then
        tes3.positionCell({cell = "Punabi", position = {1578.679, 2566.500, 600.062}, orientation = {0, 0, -89.5}})
    elseif button == 12 then
        tes3.positionCell({cell = "Punammu", position = {647.803, -1533.442, -40.513}, orientation = {0, 0, -89.5}})
    elseif button == 13 then
        tes3.positionCell({cell = "Punsabanit", position = {-539.200, -770.319, -33.871}, orientation = {0, 0, 89.5}})
    elseif button == 14 then
        mainMenu()
    elseif button == 15 then
        return
    end
end

local function teleportMenuP()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Palansour", "Panabanit-Nimawia Egg Mine", "Panat", "Panud Egg Mine", "Pelagiad", "Piernette's Farmhouse", "Pinsun", "Piran", "Prelude Shipwreck", "Pudai Egg Mine", "Pulk", "Punabi", "Punammu", "Punsabanit", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.P(e.button)
        end)
    end})
end

function tome.R(button)

    if button == 0 then
        tes3.positionCell({cell = "Ramimilk, Shrine", position = {262.082, 2757.306, -43.206}, orientation = {0, 0, 179.1}})
    elseif button == 1 then
        tes3.positionCell({cell = "Randas Ancestral Tomb", position = {1575.574, -3700.597, 1152.346}, orientation = {0, 0, -89.5}})
    elseif button == 2 then
        tes3.positionCell({cell = "Ravel Ancestral Tomb", position = {-1175.111, 2571.872, 347.201}, orientation = {0, 0, 179.1}})
    elseif button == 3 then
        tes3.positionCell({cell = "Raviro Ancestral Tomb", position = {-0.579, 2051.093, 235.391}, orientation = {0, 0, 179.1}})
    elseif button == 4 then
        tes3.positionCell({cell = "Sheogorad Region", position = {29846, 196905.5, 310}, orientation = {0, 0, -122.5}})
    elseif button == 5 then
        tes3.positionCell({cell = "Redas Ancestral Tomb", position = {3056.000, -2080.000, -544.000}, orientation = {0, 0, 89.5}})
    elseif button == 6 then
        tes3.positionCell({cell = "Releth Ancestral Tomb", position = {2690.092, 901.860, 470.238}, orientation = {0, 0, -89.5}})
    elseif button == 7 then
        tes3.positionCell({cell = "Reloth Ancestral Tomb", position = {1208.000, 1480.000, 416.000}, orientation = {0, 0, 179.1}})
    elseif button == 8 then
        tes3.positionCell({cell = "Bitter Coast Region", position = {-8115.917, -84528.93, -33.595}, orientation = {0, 0, 0}})
    elseif button == 9 then
        tes3.positionCell({cell = "Odai Plateau", position = {-35904, -37056, 1892}, orientation = {0, 0, -89.5}})
    elseif button == 10 then
        tes3.positionCell({cell = "Rethandus Ancestral Tomb", position = {-3160.000, -100.000, 1516.000}, orientation = {0, 0, 179.1}})
    elseif button == 11 then
        tes3.positionCell({cell = "Rissun", position = {3339.307, 7693.472, -1314.617}, orientation = {0, 0, -89.5}})
    elseif button == 12 then
        tes3.positionCell({cell = "Rothan Ancestral Tomb", position = {-2183.633, 3483.432, 168.000}, orientation = {0, 0, 179.1}})
    elseif button == 13 then
        tes3.positionCell({cell = "Rotheran", position = {54269.344, 153974.172, 1860.403}, orientation = {0, 0, -135}})
    elseif button == 14 then
        mainMenu()
    elseif button == 15 then
        return
    end
end

local function teleportMenuR()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Ramimilk", "Randas Ancestral Tomb", "Ravel Ancestral Tomb", "Raviro Ancestral Tomb", "Rayna Drolan's Shack", "Redas Ancestral Tomb", "Releth Ancestral Tomb", "Reloth Ancestral Tomb", "Remote Shipwreck", "Rethan Manor", "Rethandus Ancestral Tomb", "Rissun", "Rothan Ancestral Tomb", "Rotheran", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.R(e.button)
        end)
    end})
end

function tome.S3(button)

    if button == 0 then
        tes3.positionCell({cell = "Shurdan-Raplay Egg Mine", position = {-2603.649, 2049.375, -1067.599}, orientation = {0, 0, 89.5}})
    elseif button == 1 then
        tes3.positionCell({cell = "Shurinbaal", position = {-1194.501, 5380.223, -399.146}, orientation = {0, 0, 89.5}})
    elseif button == 2 then
        tes3.positionCell({cell = "Shushan", position = {0.658, -33.256, 96.926}, orientation = {0, 0, 0}})
    elseif button == 3 then
        tes3.positionCell({cell = "Shushishi", position = {-108.614, -130.473, 233.247}, orientation = {0, 0, -89.5}})
    elseif button == 4 then
        tes3.positionCell({cell = "Sinamusa Egg Mine", position = {896.000, 5792.000, -1312.000}, orientation = {0, 0, 179.1}})
    elseif button == 5 then
        tes3.positionCell({cell = "Sinarralit Egg Mine", position = {-2043.114, 1144.030, -683.575}, orientation = {0, 0, 89.5}})
    elseif button == 6 then
        tes3.positionCell({cell = "Sinsibadon", position = {1322.193, -127.534, 730.602}, orientation = {0, 0, -89.5}})
    elseif button == 7 then
        tes3.positionCell({cell = "Sjorvar Horse-Mouth's House", position = {-76.027, 239.751, 1356.481}, orientation = {0, 0, 31}})
    elseif button == 8 then
        tes3.positionCell({cell = "Small Farmhouse", position = {498.144, -4.236, 237.825}, orientation = {0, 0, 115}})
    elseif button == 9 then
        tes3.positionCell({cell = "Azura's Coast Region", position = {115957.969, 10009.199, 397.601}, orientation = {0, 0, 57}})
    elseif button == 10 then
        tes3.positionCell({cell = "Sterdecan's Farmhouse", position = {96.000, 256.000, -144.000}, orientation = {0, 0, 0}})
    elseif button == 11 then
        tes3.positionCell({cell = "Azura's Coast Region", position = {157596.953, 50471.113, 695.926}, orientation = {0, 0, -17}})
    elseif button == 12 then
        tes3.positionCell({cell = "Subdun", position = {308.530, 12.995, 1229.807}, orientation = {0, 0, 179.1}})
    elseif button == 13 then
        tes3.positionCell({cell = "Sud", position = {892.000, 3312.000, 1004.000}, orientation = {0, 0, 0}})
    elseif button == 14 then
        tes3.positionCell({cell = "Sudanit Mine", position = {2335.687, 2439.073, -290.053}, orientation = {0, 0, -89.5}})
    elseif button == 15 then
        tes3.positionCell({cell = "Sulipund", position = {1056.000, 1664.000, -1072.000}, orientation = {0, 0, 89.5}})
    elseif button == 16 then
        tes3.positionCell({cell = "Sur Egg Mine", position = {-2531.251, 3844.976, -551.652}, orientation = {0, 0, -89.5}})
    elseif button == 17 then
        tes3.positionCell({cell = "Suran", position = {55615.816, -53298.410, 1013.216}, orientation = {0, 0, -45}})
    elseif button == 18 then
        tes3.positionCell({cell = "Surirulk", position = {419.230, 266.070, 95.941}, orientation = {0, 0, -89.5}})
    elseif button == 19 then
        mainMenu()
    elseif button == 20 then
        return
    end
end

local function teleportMenuS3()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Shurdan-Raplay Egg Mine", "Shurinbaal", "Shushan", "Shushishi", "Sinamusa Egg Mine", "Sinarralit Egg Mine", "Sinsibadon", "Sjorvar Horse-Mouth's House", "Small Farmhouse", "Sobitbael Camp", "Sterdecan's Farmhouse", "Strange Shipwreck", "Subdun", "Sud", "Sudanit Mine", "Sulipund", "Sur Egg Mine", "Suran", "Surirulk", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.S3(e.button)
        end)
    end})
end

function tome.S2(button)

    if button == 0 then
        tes3.positionCell({cell = "Senim Ancestral Tomb", position = {1786.698, 830.678, 1264.000}, orientation = {0, 0, 179.1}})
    elseif button == 1 then
        tes3.positionCell({cell = "Sennananit", position = {-2945.101, 3288.276, -1067.854}, orientation = {0, 0, 0}})
    elseif button == 2 then
        tes3.positionCell({cell = "Seran Ancestral Tomb", position = {1340.020, 2811.338, -11.189}, orientation = {0, 0, -89.5}})
    elseif button == 3 then
        tes3.positionCell({cell = "Serano Ancestral Tomb", position = {-480.000, -1376.000, 2080.000}, orientation = {0, 0, 0}})
    elseif button == 4 then
        tes3.positionCell({cell = "Sethan Ancestral Tomb", position = {3076.000, -3576.000, 3372.000}, orientation = {0, 0, 0}})
    elseif button == 5 then
        tes3.positionCell({cell = "Setus Egg Mine", position = {5152.000, 2048.000, 96.000}, orientation = {0, 0, -89.5}})
    elseif button == 6 then
        tes3.positionCell({cell = "Seyda Neen", position = {-10690.568, -70791.961, 338.716}, orientation = {0, 0, -120}})
    elseif button == 7 then
        tes3.positionCell({cell = "Sha-Adnius", position = {-1186.032, 2939.991, 91.350}, orientation = {0, 0, 89.5}})
    elseif button == 8 then
        tes3.positionCell({cell = "Shal", position = {-1467.563, -178.643, 319.175}, orientation = {0, 0, 89.5}})
    elseif button == 9 then
        tes3.positionCell({cell = "Shallit", position = {-1998.297, 1532.762, -296.000}, orientation = {0, 0, 89.5}})
    elseif button == 10 then
        tes3.positionCell({cell = "Shara", position = {1032.789, 6011.066, 1629.614}, orientation = {0, 0, 179.1}})
    elseif button == 11 then
        tes3.positionCell({cell = "Sharapli", position = {-2691.016, 726.759, -1186.475}, orientation = {0, 0, 0}})
    elseif button == 12 then
        tes3.positionCell({cell = "West Gash Region", position = {-68886.008, 125461.391, 1370.377}, orientation = {0, 0, 60}})
    elseif button == 13 then
        tes3.positionCell({cell = "Shashpilamat", position = {637.164, 2465.961, -432.000}, orientation = {0, 0, 179.1}})
    elseif button == 14 then
        tes3.positionCell({cell = "Molag Amur Region", position = {85040.219, -3510.407, 715.437}, orientation = {0, 0, 35}})
    elseif button == 15 then
        tes3.positionCell({cell = "Shishara", position = {1697.600, 2177.600, 96.000}, orientation = {0, 0, 89.5}})
    elseif button == 16 then
        tes3.positionCell({cell = "Shishi", position = {258.253, 4201.616, -1196.251}, orientation = {0, 0, 179.1}})
    elseif button == 17 then
        tes3.positionCell({cell = "Shrine of Azura", position = {2998.637, 5120.137, 80.000}, orientation = {0, 0, -89.5}})
    elseif button == 18 then
        tes3.positionCell({cell = "Shulk Egg Mine", position = {2972.143, -896.339, -1070.529}, orientation = {0, 0, -89.5}})
    elseif button == 19 then
        tes3.positionCell({cell = "Bitter Coast Region", position = {-74754.914, 14566.125, 67.030}, orientation = {0, 0, -100}})
    elseif button == 20 then
        teleportMenuS3()
    elseif button == 21 then
        mainMenu()
    elseif button == 22 then
        return
    end
end

local function teleportMenuS2()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Senim Ancestral Tomb", "Sennananit", "Seran Ancestral Tomb", "Serano Ancestral Tomb", "Sethan Ancestral Tomb", "Setus Egg Mine", "Seyda Neen", "Sha-Adnius", "Shal", "Shallit", "Shara", "Sharapli", "Shashmanu Camp", "Shashpilamat", "Shashurari Camp", "Shishara", "Shishi", "Shrine of Azura", "Shulk Egg Mine", "Shunned Shipwreck", "Next Page", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.S2(e.button)
        end)
    end})
end

function tome.S(button)

    if button == 0 then
        tes3.positionCell({cell = "Sadryon Ancestral Tomb", position = {703.215, -638.163, 112}, orientation = {0, 0, 0}})
    elseif button == 1 then
        tes3.positionCell({cell = "Grazelands Region", position = {104216.984, 92444.828, 770.75}, orientation = {0, 0, -145}})
    elseif button == 2 then
        tes3.positionCell({cell = "Salmantu", position = {3584, 3968, 150.438}, orientation = {0, 0, 0}})
    elseif button == 3 then
        tes3.positionCell({cell = "Salothan Ancestral Tomb", position = {-2459.148, -6143.122, 1200.488}, orientation = {0, 0, 0}})
    elseif button == 4 then
        tes3.positionCell({cell = "Salothran Ancestral Tomb", position = {-1024, -1120, 288}, orientation = {0, 0, 89.5}})
    elseif button == 5 then
        tes3.positionCell({cell = "Salvel Ancestral Tomb", position = {4600, -1928, 1280}, orientation = {0, 0, -89.5}})
    elseif button == 6 then
        tes3.positionCell({cell = "Samarys Ancestral Tomb", position = {-2272, 992, 352}, orientation = {0, 0, 89.5}})
    elseif button == 7 then
        tes3.positionCell({cell = "Sanabi", position = {521.805, 1812.602, 346.077}, orientation = {0, 0, 179.1}})
    elseif button == 8 then
        tes3.positionCell({cell = "Sandas Ancestral Tomb", position = {1660.078, 7.169, 352.050}, orientation = {0, 0, -89.5}})
    elseif button == 9 then
        tes3.positionCell({cell = "Sandus Ancestral Tomb", position = {-319.903, -1467.572, 1904.000}, orientation = {0, 0, -89.5}})
    elseif button == 10 then
        tes3.positionCell({cell = "Sanit", position = {4465.147, 4226.574, -1297.381}, orientation = {0, 0, 89.5}})
    elseif button == 11 then
        tes3.positionCell({cell = "Sanni", position = {119.630, 2951.138, -944.000}, orientation = {0, 0, -89.5}})
    elseif button == 12 then
        tes3.positionCell({cell = "Sarano Ancestral Tomb", position = {224.000, 200.000, 32.000}, orientation = {0, 0, 89.5}})
    elseif button == 13 then
        tes3.positionCell({cell = "Saren Ancestral Tomb", position = {-1312.003, 540.785, 1824.000}, orientation = {0, 0, 89.5}})
    elseif button == 14 then
        tes3.positionCell({cell = "Sarethi Ancestral Tomb", position = {-2937.748, 370.802, 1008.000}, orientation = {0, 0, 179.1}})
    elseif button == 15 then
        tes3.positionCell({cell = "Sargon", position = {-2576.694, 5218.818, -808.286}, orientation = {0, 0, 89.5}})
    elseif button == 16 then
        tes3.positionCell({cell = "Sarimisun-Assa Egg Mine", position = {2190.907, 6006.795, -684.886}, orientation = {0, 0, -89.5}})
    elseif button == 17 then
        tes3.positionCell({cell = "Sarys Ancestral Tomb", position = {7028.375, 4415.659, 15001.793}, orientation = {0, 0, -89.5}})
    elseif button == 18 then
        tes3.positionCell({cell = "Saturan", position = {-3106.257, 1013.923, 738.152}, orientation = {0, 0, 89.5}})
    elseif button == 19 then
        tes3.positionCell({cell = "Savel Ancestral Tomb", position = {384.000, 1272.000, 728.000}, orientation = {0, 0, 179.1}})
    elseif button == 20 then
        teleportMenuS2()
    elseif button == 21 then
        mainMenu()
    elseif button == 22 then
        return
    end
end

local function teleportMenuS()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Sadryon Ancestral Tomb", "Salit Camp", "Salmantu", "Salothan Ancestral Tomb", "Salothran Ancestral Tomb", "Salvel Ancestral Tomb", "Samarys Ancestral Tomb", "Sanabi", "Sandas Ancestral Tomb", "Sandus Ancestral Tomb", "Sanit", "Sanni", "Sarano Ancestral Tomb", "Saren Ancestral Tomb", "Sarethi Ancestral Tomb", "Sargon", "Sarimisun-Assa Egg Mine", "Sarys Ancestral Tomb", "Saturan", "Savel Ancestral Tomb", "Next Page", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.S(e.button)
        end)
    end})
end

function tome.T(button)

    if button == 0 then
        tes3.positionCell({cell = "Tel Aruhn", position = {126224.617, 45887.289, 3714.583}, orientation = {0, 0, -135}})
    elseif button == 1 then
        tes3.positionCell({cell = "Tel Branora", position = {126851.664, -101680.219, 2366.458}, orientation = {0, 0, -15}})
    elseif button == 2 then
        tes3.positionCell({cell = "Tel Fyr", position = {124384.133, 15857.785, 491.903}, orientation = {0, 0, 179.1}})
    elseif button == 3 then
        tes3.positionCell({cell = "Tel Mora", position = {107868.063, 118635.195, 2862.428}, orientation = {0, 0, -160}})
    elseif button == 4 then
        tes3.positionCell({cell = "Uvirith's Grave", position = {87282.320, 10177.420, 2278.930}, orientation = {0, 0, -52}})
    elseif button == 5 then
        tes3.positionCell({cell = "Tel Vos", position = {85730.766, 117960.313, 5081.284}, orientation = {0, 0, 135}})
    elseif button == 6 then
        tes3.positionCell({cell = "Telasero", position = {76221.891, -52880.473, 1436.241}, orientation = {0, 0, 89.5}})
    elseif button == 7 then
        tes3.positionCell({cell = "Telvayn Ancestral Tomb", position = {-2181.687, 2456.948, 1008.000}, orientation = {0, 0, 179.1}})
    elseif button == 8 then
        tes3.positionCell({cell = "Thalas Ancestral Tomb", position = {1118.142, -1272.453, -208.000}, orientation = {0, 0, -89.5}})
    elseif button == 9 then
        tes3.positionCell({cell = "Tharys Ancestral Tomb", position = {2092.789, 272.204, -80.395}, orientation = {0, 0, -89.5}})
    elseif button == 10 then
        tes3.positionCell({cell = "Thelas Ancestral Tomb", position = {120.507, -169.263, 91.203}, orientation = {0, 0, 179.1}})
    elseif button == 11 then
        tes3.positionCell({cell = "Thiralas Ancestral Tomb", position = {-1280.369, 386.138, 217.217}, orientation = {0, 0, 89.5}})
    elseif button == 12 then
        tes3.positionCell({cell = "Tin-Ahhe", position = {1409.833, 4203.653, -423.125}, orientation = {0, 0, 0}})
    elseif button == 13 then
        tes3.positionCell({cell = "Tukushapal", position = {-2765.070, 2794.425, -1700.694}, orientation = {0, 0, 89.5}})
    elseif button == 14 then
        tes3.positionCell({cell = "Tureynulal, Kagrenac's Library", position = {-251.411, 4.800, 84.800}, orientation = {0, 0, 179.1}})
    elseif button == 15 then
        tes3.positionCell({cell = "Tusenend, Shrine", position = {245.580, 3994.707, -678.973}, orientation = {0, 0, 179.1}})
    elseif button == 16 then
        mainMenu()
    elseif button == 17 then
        return
    end
end

local function teleportMenuT()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Tel Aruhn", "Tel Branora", "Tel Fyr", "Tel Mora", "Tel Uvirith", "Tel Vos", "Telasero", "Telvayn Ancestral Tomb", "Thalas Ancestral Tomb", "Tharys Ancestral Tomb", "Thelas Ancestral Tomb", "Thiralas Ancestral Tomb", "Tin-Ahhe", "Tukushapal", "Tureynulal", "Tusenend", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.T(e.button)
        end)
    end})
end

function tome.U(button)

    if button == 0 then
        tes3.positionCell({cell = "Ularradallaku, Shrine", position = {250.968, 1584.735, 468.605}, orientation = {0, 0, 179.1}})
    elseif button == 1 then
        tes3.positionCell({cell = "Ules Manor", position = {-247.864, 690.270, -545.784}, orientation = {0, 0, 0}})
    elseif button == 2 then
        tes3.positionCell({cell = "Ulummusa", position = {-3599.883, -766.500, 468.216}, orientation = {0, 0, 89.5}})
    elseif button == 3 then
        tes3.positionCell({cell = "Ascadian Isles Region", position = {35955.813, -119563.383, 386.706}, orientation = {0, 0, -85}})
    elseif button == 4 then
        tes3.positionCell({cell = "Bitter Coast Region", position = {-40143.520, -55737.395, 129.112}, orientation = {0, 0, -15}})
    elseif button == 5 then
        tes3.positionCell({cell = "Azura's Coast Region", position = {132578.844, 37549.383, 403.360}, orientation = {0, 0, -15}})
    elseif button == 6 then
        tes3.positionCell({cell = "West Gash Region", position = {-119654.391, 120392.883, -1428.948}, orientation = {0, 0, -110}})
    elseif button == 7 then
        tes3.positionCell({cell = "Urshilaku, Astral Burial", position = {3072.000, -1696.000, 14149.000}, orientation = {0, 0, 0}})
    elseif button == 8 then
        tes3.positionCell({cell = "Urshilaku Camp", position = {-26839.053, 150933.813, 787.237}, orientation = {0, 0, -120}})
    elseif button == 9 then
        tes3.positionCell({cell = "Uveran Ancestral Tomb", position = {1934.000, -1558.922, 1774.555}, orientation = {0, 0, 179.1}})
    elseif button == 10 then
        mainMenu()
    elseif button == 11 then
        return
    end
end

local function teleportMenuU()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Ularradallaku", "Ules Manor", "Ulummusa", "Unchartered Shipwreck", "Unexplored Shipwreck", "Unknown Shipwreck", "Unmarked Shipwreck", "Urshilaku Astral Burial", "Urshilaku Camp", "Uveran Ancestral Tomb", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.U(e.button)
        end)
    end})
end

function tome.V(button)

    if button == 0 then
        tes3.positionCell({cell = "Valenvaryon", position = {-2787.027, 152680.109, 2403.076}, orientation = {0, 0, 308}})
    elseif button == 1 then
        tes3.positionCell({cell = "Vandus Ancestral Tomb", position = {-2560.000, 1632.000, -192.000}, orientation = {0, 0, 89.5}})
    elseif button == 2 then
        tes3.positionCell({cell = "Vansunalit Egg Mine", position = {-2424.719, 6517.021, -43.056}, orientation = {0, 0, 89.5}})
    elseif button == 3 then
        tes3.positionCell({cell = "Vas, Entry Level", position = {773.498, 3581.295, 984.240}, orientation = {0, 0, 179.1}})
    elseif button == 4 then
        tes3.positionCell({cell = "Vassamsi Grotto", position = {-1912.000, 3824.000, -44.431}, orientation = {0, 0, 89.5}})
    elseif button == 5 then
        tes3.positionCell({cell = "Vassir-Didanat Cave", position = {3734.344, 3061.911, 224.663}, orientation = {0, 0, -89.5}})
    elseif button == 6 then
        tes3.positionCell({cell = "Velas Ancestral Tomb", position = {-640.000, 3264.000, 144.000}, orientation = {0, 0, 179.1}})
    elseif button == 7 then
        tes3.positionCell({cell = "Veloth Ancestral Tomb", position = {1056.000, -4588.149, 2016.000}, orientation = {0, 0, 179.1}})
    elseif button == 8 then
        tes3.positionCell({cell = "Vemynal, Outer Fortress", position = {3.682, -43.407, 84.088}, orientation = {0, 0, 179.1}})
    elseif button == 9 then
        tes3.positionCell({cell = "Venim Ancestral Tomb", position = {-514.012, 4989.083, 635.230}, orientation = {0, 0, 89.5}})
    elseif button == 10 then
        tes3.positionCell({cell = "Verelnim Ancestral Tomb", position = {3360.000, -512.000, -352.000}, orientation = {0, 0, -89.5}})
    elseif button == 11 then
        tes3.positionCell({cell = "Vos", position = {95140.898, 116387.266, 1904.207}, orientation = {0, 0, -135}})
    elseif button == 12 then
        mainMenu()
    elseif button == 13 then
        return
    end
end

local function teleportMenuV()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Valenvaryon", "Vandus Ancestral Tomb", "Vansunalit Egg Mine", "Vas", "Vassamsi Grotto", "Vassir-Didanat Cave", "Velas Ancestral Tomb", "Veloth Ancestral Tomb", "Vemynal", "Venim Ancestral Tomb", "Verelnim Ancestral Tomb", "Vos", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.V(e.button)
        end)
    end})
end

function tome.Y(button)

    if button == 0 then
        tes3.positionCell({cell = "Yakanalit", position = {1511.370, 2787.166, 115.928}, orientation = {0, 0, 0}})
    elseif button == 1 then
        tes3.positionCell({cell = "Grazelands Region", position = {87035.422, 101582.977, 649.484}, orientation = {0, 0, 45.8}})
    elseif button == 2 then
        tes3.positionCell({cell = "Yakin", position = {1030.027, -4389.852, -542.271}, orientation = {0, 0, 0}})
    elseif button == 3 then
        tes3.positionCell({cell = "Yanemus Mine", position = {-164.726, 6843.935, -793.476}, orientation = {0, 0, -89.5}})
    elseif button == 4 then
        tes3.positionCell({cell = "Yansirramus, Shrine", position = {270.145, 5317.682, -670.678}, orientation = {0, 0, 179.1}})
    elseif button == 5 then
        tes3.positionCell({cell = "Yasammidan, Shrine", position = {-3.773, 5264.765, -281.037}, orientation = {0, 0, 179.1}})
    elseif button == 6 then
        tes3.positionCell({cell = "Yasamsi", position = {-1416.663, 5374.381, -783.081}, orientation = {0, 0, 89.5}})
    elseif button == 7 then
        tes3.positionCell({cell = "Yassu Mine", position = {-1055.723, -391.519, 360.374}, orientation = {0, 0, 89.5}})
    elseif button == 8 then
        tes3.positionCell({cell = "Yesamsi", position = {-1956.000, 3932.000, 908.000}, orientation = {0, 0, 89.5}})
    elseif button == 9 then
        mainMenu()
    elseif button == 10 then
        return
    end
end

local function teleportMenuY()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Yakanalit", "Yakaridan Camp", "Yakin", "Yanemus Mine", "Yansirramus", "Yasammidan", "Yasamsi", "Yassu Mine", "Yesamsi", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.Y(e.button)
        end)
    end})
end

function tome.Z(button)

    if button == 0 then
        tes3.positionCell({cell = "Zainab Camp", position = {78351.016, 83962.664, 1009.659}, orientation = {0, 0, 300}})
    elseif button == 1 then
        tes3.positionCell({cell = "Zainsipilu", position = {-3113.156, 2057.591, 739.189}, orientation = {0, 0, 89.5}})
    elseif button == 2 then
        tes3.positionCell({cell = "Zaintirari", position = {-2571.171, 3641.270, 1367.670}, orientation = {0, 0, 89.5}})
    elseif button == 3 then
        tes3.positionCell({cell = "Zaintiraris, Shrine", position = {2119.235, 891.740, -48.000}, orientation = {0, 0, -89.5}})
    elseif button == 4 then
        tes3.positionCell({cell = "Zalkin Grotto", position = {-632.000, 1560.000, -169.228}, orientation = {0, 0, 0}})
    elseif button == 5 then
        tes3.positionCell({cell = "Zalkin-Sul Egg Mine", position = {-3461.691, 5756.020, -1197.510}, orientation = {0, 0, 89.5}})
    elseif button == 6 then
        tes3.positionCell({cell = "Zanabi", position = {1026.539, 3364.066, 1371.469}, orientation = {0, 0, 179.1}})
    elseif button == 7 then
        tes3.positionCell({cell = "Zebabi", position = {42.290, -4092.992, 1112.845}, orientation = {0, 0, -89.5}})
    elseif button == 8 then
        tes3.positionCell({cell = "Zenarbael", position = {-3362.126, 4614.927, 214.583}, orientation = {0, 0, 89.5}})
    elseif button == 9 then
        tes3.positionCell({cell = "Zergonipal, Shrine", position = {-2.93, 5438.04, -254}, orientation = {0, 0, 179.1}})
    elseif button == 10 then
        mainMenu()
    elseif button == 11 then
        return
    end
end

local function teleportMenuZ()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Zainab Camp", "Zainsipilu", "Zaintirari", "Zaintiraris", "Zalkin Grotto", "Zalkin-Sul Egg Mine", "Zanabi", "Zebabi", "Zenarbael", "Zergonipal", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.Z(e.button)
        end)
    end})
end

function tome.main2(button)

    if button == 0 then
        teleportMenuL()
    elseif button == 1 then
        teleportMenuM()
    elseif button == 2 then
        teleportMenuN()
    elseif button == 3 then
        teleportMenuO()
    elseif button == 4 then
        teleportMenuP()
    elseif button == 5 then
        teleportMenuR()
    elseif button == 6 then
        teleportMenuS()
    elseif button == 7 then
        teleportMenuT()
    elseif button == 8 then
        teleportMenuU()
    elseif button == 9 then
        teleportMenuV()
    elseif button == 10 then
        teleportMenuY()
    elseif button == 11 then
        teleportMenuZ()
    elseif button == 12 then
        mainMenu()
    elseif button == 13 then
        return
    end
end

local function teleportMenu2()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"L", "M", "N", "O", "P", "R", "S", "T", "U", "V", "Y", "Z", "Main Menu", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.main2(e.button)
        end)
    end})
end

function tome.main(button)

    if button == 0 then
        teleportMenuCities()
    elseif button == 1 then
        teleportMenuExp()
    elseif button == 2 then
        teleportMenuA()
    elseif button == 3 then
        teleportMenuB()
    elseif button == 4 then
        teleportMenuC()
    elseif button == 5 then
        teleportMenuD()
    elseif button == 6 then
        teleportMenuE()
    elseif button == 7 then
        teleportMenuF()
    elseif button == 8 then
        teleportMenuG()
    elseif button == 9 then
        teleportMenuH()
    elseif button == 10 then
        teleportMenuI()
    elseif button == 11 then
        teleportMenuK()
    elseif button == 12 then
        teleportMenu2()
    elseif button == 13 then
        return
    end
end

local function teleportMenu()

    tes3.messageBox({message = "Teleport to Where ?", buttons = {"Main Cities", "Expansions", "A", "B", "C", "D", "E", "F", "G", "H", "I", "K", "L-Z", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() tome.main(e.button)
        end)
    end})
end

main = function()
    teleportMenu()
end

--[[local function equipTome(e)

    local pc = tes3.mobilePlayer

    if e.item.id == "Krimson_teleport_tome" then

        if config.combatEnabled then
            if pc.inCombat then
                tes3.messageBox({message = "You can not teleport if you are in combat."})
                return
            end
        end

        if config.jailEnabled then
            if pc.inJail then
                tes3.messageBox({message = "You can not teleport if you are in jail."})
                return
            end
        end

        if config.bountyEnabled then
            if pc.bounty >= config.setBounty then
                tes3.messageBox({message = "You can not teleport if you are wanted for commiting crimes."})
                return
            end
        end
        tes3ui.leaveMenuMode()
        teleportMenu()
    end
end]]

local function openMenu(e)

    if tes3ui.menuMode() then
        return
    end

    local pc = tes3.mobilePlayer

    if e.keyCode == config.keyBind.keyCode then

        if config.combatEnabled then
            if pc.inCombat then
                tes3.messageBox({message = "You can not teleport if you are in combat."})
                return
            end
        end

        if config.jailEnabled then
            if pc.inJail then
                tes3.messageBox({message = "You can not teleport if you are in jail."})
                return
            end
        end

        if config.bountyEnabled then
            if pc.bounty >= config.setBounty then
                tes3.messageBox({message = "You can not teleport if you are wanted for commiting crimes."})
                return
            end
        end
        tes3ui.leaveMenuMode()
        teleportMenu()
    end
end

local function registerConfig()

    local template = mwse.mcm.createTemplate("Teleport Menu")
    template:saveOnClose("Teleport Menu", config)
    template:register()

    local page = template:createSideBarPage({
        label = "Teleport Menu",
    })

    local settings = page:createCategory("Teleport Menu Settings\n\n\n\nCombat")

    settings:createOnOffButton({
        label = "Disable teleporting during combat",
        description = "ON disables use while in combat.\n\nDefault: ON\n\n",
        variable = mwse.mcm.createTableVariable {id = "combatEnabled", table = config}
    })

    local settings1 = page:createCategory("Jail")

    settings1:createOnOffButton({
        label = "Disable teleporting if in Jail",
        description = "ON disables use while in jail.\n\nDefault: ON\n\n",
        variable = mwse.mcm.createTableVariable {id = "jailEnabled", table = config}
    })

    local settings2 = page:createCategory("Bounty")

    settings2:createOnOffButton({
        label = "Disable teleporting if you have a bounty",
        description = "ON disables use while you have a bounty.\n\nBounty amount is set with slider below.\n\nDefault: ON\n\n",
        variable = mwse.mcm.createTableVariable {id = "bountyEnabled", table = config}
    })

    settings2:createSlider{
        label = "Bounty amount to disable teleporting",
        description = "Sets bounty amount to disable teleporting.\n\nNo effect if above button for Bounty is OFF.\n\nDefault: 250\n\n",
        min = 0,
        max = 2500,
        step = 1,
        jump = 100,
        variable = mwse.mcm.createTableVariable{id = "setBounty", table = config}
    }

    local settings3 = page:createCategory("Keybind to open menu")

    settings3:createKeyBinder{
        label = "You will need to restart the game for the changes to apply.",
        description = "Changes the keys to open the teleport menu\n\nDefault: N\n\n",
        allowCombinations = true,
        variable = mwse.mcm.createTableVariable{id = "keyBind", table = config, defaultSetting = {keyCode = tes3.scanCode.n, isShiftDown = false, isAltDown = false, isControlDown = false}}
    }
end

event.register("modConfigReady", registerConfig)

local function modInitialized()

    event.register("keyDown", openMenu, {filter = config.keyBind.keyCode})
    --event.register("equip", equipTome)
    print("Teleporting Initialized")
end

event.register("initialized", modInitialized)