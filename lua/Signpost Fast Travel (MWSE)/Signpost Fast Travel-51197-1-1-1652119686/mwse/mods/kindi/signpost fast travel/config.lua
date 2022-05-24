local defconfig =
{

modActive = true,
travelTo2 = "TravelMarker",
travelTo3 = "TempleMarker",
travelTo4 = "DivineMarker",
travelTo1 = "other",
penalty = false,
timeAdvance = true,
combatDeny = false,
showConfirm = true,
bringFriends = true,
extraRealism = false,



}


local conf = mwse.loadConfig("signpost_travel", defconfig)

return conf;
