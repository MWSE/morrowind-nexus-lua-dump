local configPath = "marksman_rebalanced"

local config = mwse.loadConfig(configPath)
if (config == nil) then
	config = { 
        enableMod = true,
        minDistanceMultiplier = 2.0,
        maxDistanceMultiplier = 0.5,
        maxDistance = 9000,
        stealthMulti = 1.25,
        debug = false
    }
end 

--remove old main
local lfs = require("lfs")
local pathToOld = lfs.currentdir() .. "/Data Files/MWSE/mods/mer/main.lua"
local fileExists = lfs.attributes(pathToOld, "mode") == "file"
if fileExists then
    os.remove(pathToOld)
    mwse.log("[MarksmanRebalanced] Found old file. Removed %s", pathToOld)
end

local function debug(str, ...)
    if config.debug then
        print( "[Marksman Rebalanced: DEBUG] " .. tostring(str):format(...))
    end
end

local function onHitChance(e)
    local weapon = tes3.getEquippedItem{
        actor = e.attacker,
        objectType = tes3.objectType.weapon
    }
    if weapon and weapon.object.isRanged and config.enableMod then
        

        local distance = e.attackerMobile.position:distance( e.targetMobile.position)

        debug("-----------------------------")
        debug("Distance to target: %.2f", distance)
        debug("Hit chance before: %.2f", e.hitChance)
        

        local logDistance = math.log(distance)
        local logMaxDistance = math.log(config.maxDistance)

        local multi = math.remap(logDistance, 4, logMaxDistance, config.minDistanceMultiplier, config.maxDistanceMultiplier)
        multi = math.clamp(multi, config.maxDistanceMultiplier, config.minDistanceMultiplier)

        e.hitChance = e.hitChance * multi

        debug("Hit chance multiplier: %.2f", multi)
        debug("Hit chance after multiplier %.2f", e.hitChance)

        if e.attacker.mobile.isSneaking then
            e.hitChance = e.hitChance * config.stealthMulti
            debug("Sneak multiplier: %.2f", config.stealthMulti)
            debug("Hit chance after sneak multi: %.2f",  e.hitChance )
        end
        debug("-----------------------------")
    end
end

event.register("calcHitChance", onHitChance)

----------------------------------------------------------
--MCM
---------------------------------------------------------
local  sideBarDefault = (
    "Marksman Rebalanced takes into account the distance to target when " ..
    "calculating the hit chance for ranged weapons. This applies to both the " ..
    "player and NPCs. Crouching also provides a boost to hit chance."
)

local function addSideBar(component)
    component.sidebar:createInfo{ text = sideBarDefault}
    component.sidebar:createHyperLink{
        text = "Made by Merlord",
        exec = "start https://www.nexusmods.com/users/3040468?tab=user+files",
        postCreate = (
            function(self)
                self.elements.outerContainer.borderAllSides = self.indent
                self.elements.outerContainer.alignY = 1.0
                self.elements.outerContainer.layoutHeightFraction = 1.0
                self.elements.info.layoutOriginFractionX = 0.5
            end
        ),
    }
end

local function makeVar(id, numbersOnly)
    return mwse.mcm.createTableVariable{
        id = id, 
        table = config,
        numbersOnly = numbersOnly
    }
end

local function registerMCM()


    local template = mwse.mcm.createTemplate("Marksman Rebalanced")
    template:saveOnClose(configPath, config)
    template:register()

    local page = template:createSideBarPage()
    addSideBar(page)

    page:createOnOffButton{
        label = "Enable Marksman Rebalanced",
        description = "Turn this mod on or off.",
        variable = makeVar("enableMod")
    }
    page:createOnOffButton{
        label = "Enable Debugging",
        description = "Logs distances and multipliers to MWSELog.txt to help with fine-tuning settings.",
        variable = makeVar("debug")
    }

    page:createSlider{
        label = "Maximum Distance",
        description = "The distance at which the maximum hit chance multiplier is applied.",
        variable = makeVar("maxDistance"),
        min = 1000, 
        max = 15000,
        jump = 500,
        step = 100
    }

    page:createTextField{
        label = "Max Distance Hit Chance Multiplier",
        description = "The multiplier applied to hit chance at the maximum enemy distance.",
        variable = makeVar("maxDistanceMultiplier", true)
    }

    page:createTextField{
        label = "Min Distance Hit Chance Multiplier",
        description = "The multiplier applied to hit chance when the target is close to the shooter.",
        variable = makeVar("minDistanceMultiplier", true)
    }



    page:createTextField{
        label = "Sneak Modifier",
        description = "Multiplier to hit chance when sneaking.",
        variable = makeVar("stealthMulti", true)
    }



end

event.register("modConfigReady", registerMCM)