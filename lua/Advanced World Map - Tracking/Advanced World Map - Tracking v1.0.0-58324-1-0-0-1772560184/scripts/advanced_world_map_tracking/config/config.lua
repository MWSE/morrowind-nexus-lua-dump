local I = require("openmw.interfaces")

local commonData = require("scripts.advanced_world_map_tracking.common")
local tableLib = require("scripts.advanced_world_map_tracking.utils.table")


local this = {}

---@class advWMap_tracking.config
this.default = {
    version = 1,
    tracking = {
        aboveBelowHeight = 200,
        itemUpdateTime = 3,
        visibilityUpdateTime = 0.5,
        visibilityUpdateTimeLimit = 0.0015,
        visibilityUpdateStepLimit = 100,
        markersPerFrame = 50,
    },
    spDetection = {
        markerSize = 4,
        animal = {
            enabled = true,
            detectNPC = true,
            detectEnemy = true,
            distanceMul = 2,
            color = commonData.detectAnimalColor,
            npcColor = commonData.detectAnimalNPCColor,
            enemyColor = commonData.detectAnimalEnemyColor,
        },
        key = {
            enabled = true,
            distanceMul = 2,
            color = commonData.detectKeyColor,
        },
        enchantment = {
            enabled = true,
            distanceMul = 2,
            color = commonData.detectEnchantmentColor,
            maxTooltipItems = 3,
        },
    }
}


---@class advWMap_tracking.config
this.data = tableLib.deepcopy(this.default)

return this