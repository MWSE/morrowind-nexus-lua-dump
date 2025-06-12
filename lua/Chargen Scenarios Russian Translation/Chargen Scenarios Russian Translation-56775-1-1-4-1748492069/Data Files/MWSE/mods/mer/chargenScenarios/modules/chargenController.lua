
local common = require('mer.chargenScenarios.common')
local logger = common.createLogger("ChargenController")
local controls = require('mer.chargenScenarios.util.Controls')
local Ashfall = include("mer.ashfall.interop")

local defaultTopics = {
    "Задания",
    "Биография",
	"определенное место",
	"кто-то особенный",
	"Услуги",
	"мое занятие",
	"маленький секрет",
	"свежие сплетни",
	"небольшой совет",
}

local chargenObjects = {
    "CharGen Boat",
    "CharGen Boat Guard 1",
    "CharGen Boat Guard 2",
    "CharGen Dock Guard",
    "CharGen_cabindoor",
    "CharGen_chest_02_empty",
    "CharGen_crate_01",
    "CharGen_crate_01_empty",
    "CharGen_crate_01_misc01",
    "CharGen_crate_02",
    "CharGen_lantern_03_sway",
    "CharGen_ship_trapdoor",
    "CharGen_barrel_01",
    "CharGen_barrel_02",
    "CharGenbarrel_01_drinks",
    "CharGen_plank",
    "CharGen StatsSheet",
}
local function disableChargenStuff()
    --Disable chargen objects
    for _, id in ipairs(chargenObjects) do
        local command = string.format('"%s"->Disable', id)
        tes3.runLegacyScript{ command = command} ---@diagnostic disable-line
    end
    --unlock door to census office
    tes3.runLegacyScript{ command = '"CharGen Door Hall"->Unlock'} ---@diagnostic disable-line
end


local function updateSellusGravius()
    local sellus = tes3.getReference("chargen captain")
    if not sellus then
        logger:warn("Sellus Gravius not found")
        return
    end
    logger:debug("Setting Sellus Gravius state to -1")
    sellus.object.script.context.state = -1
end


local function startChargen()
    logger:debug("Starting Chargen")
    --Set Chargen State
    logger:debug("Setting chargen state to 'start'")
    tes3.findGlobal("CharGenState").value = 10
    --Disable Controls
    logger:debug("Disabling controls")
    controls.disableControls()
    --Disable NPCs
    logger:debug("Disabling Vanilla Chargen stuff")
    disableChargenStuff()
    updateSellusGravius()
    --Move Player to Chargen Cell
    logger:debug("Moving player to chargen cell")
    tes3.positionCell(table.copy(
        common.config.chargenLocation,
        ---@type tes3.positionCell.params
        {
            forceCellChange = true
        })
    )
    --Add topics
    for _, topic in ipairs(defaultTopics) do
        tes3.addTopic{
            topic = topic,
            updateGUI = false
        }
    end

    timer.start{
        type = timer.simulate,
        duration = 1,
        callback = function()
            logger:debug("Opening stat review menu")
            tes3.runLegacyScript{ command = "EnableRaceMenu"}
        end
    }

end

--[[
    Prevent vanilla chargen scripts from running,
]]
---@type string[]
local chargenScripts = {
    "CharGen",
    "CharGen_ring_keley",
    "ChargenBed",
    "ChargenBoatNPC",
    "CharGenBoatWomen",
    "CharGenClassNPC",
    "CharGenCustomsDoor",
    "CharGenDagger",
    "CharGenDialogueMessage",
    "CharGenDoorEnterCaptain",
    "CharGenFatigueBarrel",
    "CharGenDoorExit",
    "CharGenDoorExitCaptain",
    "CharGenDoorGuardTalker",
    "CharGenJournalMessage",
    "CharGenNameNPC",
    "CharGenRaceNPC",
    "CharGenStatsSheet",
    "CharGenStuffRoom",
    "CharGenWalkNPC",
}

local function blockChargenScripts()
    logger:debug("Overriding Chargen Scripts")
    for _, scriptId in pairs(chargenScripts) do
        mwse.overrideScript(scriptId, function()
            mwscript.stopScript{script = scriptId} ---@diagnostic disable-line
        end)
    end
end

local function unblockChargenScripts()
    logger:debug("Unblocking Chargen Scripts")
    for _, scriptId in pairs(chargenScripts) do
        mwse.clearScriptOverride(scriptId)
    end
end

event.register("load", function()
    if common.modEnabled() then
        blockChargenScripts()
    else
        unblockChargenScripts()
    end
end)

event.register("loaded", function(e)
    if not common.modEnabled() then
        logger:debug("Positioning at vanilla starting location")
        -- tes3.positionCell{
        --     reference = tes3.player,
        --     position = {61, -135, -104},
        --     orientation = {0, 0, 0},
        --     cellId = "Imperial Prison Ship"
        -- }
    end
end)

---@param e loadedEventData
local function startChargenOnLoad(e)
    if common.modEnabled() and e.newGame then
        if Ashfall then Ashfall.blockNeeds() end
        timer.delayOneFrame(startChargen)
    end
end
event.register("loaded", startChargenOnLoad)

