local defaultConfig = {
    Version = "PC Voice, vBeta1.1",
    helloAuto = false,
    helloPer = 50,
    helloTime = 5,
    helloRace = 3,
    helloFem = false,
    helloVol = 1,
    helloPitch = 1,
    helloDisp = 50
}

local config = mwse.loadConfig ("PC Voice", defaultConfig)
return config