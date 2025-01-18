local defaultConfig ={
    mapPacks = {"mapsWagner", "mapsOutlander", "mapsGridmap",},
    compasses = {"compassface.tga"},
    worldMap = true,
    localMap = true,
    compass = false,
    selectionDropdown = true,
    hideSwitch = true,
    hideMapTitle = false,
    noteKey = {keyCode = tes3.scanCode.leftCtrl},
    maxScale = 3,
    hideMapNotification = false
}
local config = mwse.loadConfig("Map and Compass", defaultConfig)
return config