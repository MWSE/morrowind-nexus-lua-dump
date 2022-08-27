local defconfig =
{

modActive = true,
debug = false,
showStats = true,

travelTo1 = "Preset",
travelTo2 = "TravelMarker",
travelTo3 = "TempleMarker",
travelTo4 = "DivineMarker",

penalty = false,
timeAdvance = true,
combatDeny = false,
showConfirm = true,
bringFriends = true,
extraRealism = false,



}


local conf = mwse.loadConfig("signpost_travel", defconfig)

return conf;
