
local common = require("mer.QuickLoadouts.common")

event.register("keyDown", common.keyDown )

require("mer.QuickLoadouts.mcmData")

local function onLoad()
    for i = 1, common.numLoadouts do
        local loadoutID = "loadout_" .. i
        tes3.player.data.loadouts =  tes3.player.data.loadouts or {}
        local loadouts = tes3.player.data.loadouts
        loadouts[loadoutID] = loadouts[loadoutID] or {}

        loadouts[loadoutID].weaponList = loadouts[loadoutID].weaponList or {}
        loadouts[loadoutID].armorList = loadouts[loadoutID].armorList or {}
        loadouts[loadoutID].clothingList = loadouts[loadoutID].clothingList or {}
    end

end

event.register("loaded", onLoad)