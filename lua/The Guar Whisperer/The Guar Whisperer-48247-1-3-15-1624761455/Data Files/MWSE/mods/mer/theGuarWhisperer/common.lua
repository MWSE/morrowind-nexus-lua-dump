local this = {} 

this.fetchItems = {}

local logger = require("mer.theGuarWhisperer.logger")

this.configPath = "guar_whisperer"
local inMemConfig 
function this.getConfig()
    return inMemConfig and inMemConfig or mwse.loadConfig(this.configPath,
    {
        enabled = true,
        commandToggleKey = { keyCode = tes3.scanCode.q},
        logLevel = logger.logLevel.INFO,
        teleportDistance = 1500,
        merchants = {
            ["arrille"] = true,
            ["ra'virr"] = true,
            ["mebestian ence"] = true,
            ["alveno andules"] = true,
            ["dralasa nithryon"] = true,
            ["galtis guvron"] = true,
            ["goldyn belaram"] = true,
            ["irgola"] = true,
            ["clagius clanler"] = true,
            ["fadase selvayn"] = true,
            ["tiras sadus"] = true,
            ["heifnir"] = true,
            ["ancola"] = true,
        },
        exclusions = {
            guar = true,
            guar_feral = true
        }
    }
)
end
function this.saveConfig(newConfig)
    inMemConfig = newConfig
    mwse.saveConfig(this.configPath, newConfig)
end
 

this.log = logger.new{ 
    name = "The Guar Whisperer",
    logLevel = this.getConfig().logLevel
}
this.merchantContainer = "mer_tgw_crate"
this.packId = "mer_tgw_guarpack"
this.ballId = "mer_tgw_ball"
this.fluteId = "mer_tgw_flute"
this.fluteSound = "mer_flutesound"

this.packItems = {
    pack = {
        id = "SWITCH_PACK",
        items = { this.packId },
        --grabNode = "PACK"
    },
    tent = {
        id = "SWITCH_TENT",
        items = {
            "a_tent_pack", 
            "a_bed_covered", 
            "a_bed_roll", 
            "ashfall_bedroll",
            "ashfall_cbroll_misc",
            "ashfall_tent_misc",
            "ashfall_tent_ashl_misc",
            "ashfall_tent_canv_b_misc"
        },
        dispAll = true,
        grabNode = "TENT"
    },
    
    axe = {
        id = "SWITCH_AXE",
        items = {
            "ashfall_woodaxe"
        },
        dispAll = true,
        grabNode = "AXE"
    },
    accessories = {
        id = "SWITCH_ACCESSORIES",
        dispAll = true,
    },
    wood = {
        id = "SWITCH_WOOD",
        items = {"a_firewood", "ashfall_firewood" },
        dispAll = true,
        grabNode = "WOOD"
    },
    pot = {
        id = "SWITCH_POT",
        items = { "ashfall_cooking_pot", "misc_com_bucket_metal"},
        dispAll = true,
        grabNode = "POT"
    },
    grill = {
        id = "SWITCH_GRILL",
        items = {"ashfall_grill" },
        dispAll = true,
        grabNode = "GRILL"
    },
    lute = {
        id = "SWITCH_LUTE",
        items = { "misc_de_lute_01", "misc_de_lute_01_phat", "mer_lute", "mer_lute_fat"},
        grabNode = "LUTE"
    },
    lantern = {
        id = "SWITCH_LANTERN",
        items = {
            "light_com_lantern_02_Off",
            "light_com_lantern_02",
            "light_com_lantern_02_128",
            "light_com_lantern_02_128_Off",
            "light_com_lantern_02_177",
            "light_com_lantern_02_256",
            "light_com_lantern_02_64",
            "light_com_lantern_02_INF",
            "light_com_lantern_02_Off",
            "light_com_lantern_01",
            "light_com_lantern_01_128",
            "light_com_lantern_01_256",
            "light_com_lantern_01_77",
            "light_com_lantern_01_Off",
            "light_de_lantern_14",
            "light_de_lantern_11",
            "light_de_lantern_10",
            "light_de_lantern_10_128",
            "light_de_lantern_07",
            "light_de_lantern_07_128",
            "light_de_lantern_07_warm",
            "light_de_lantern_06",
            "light_de_lantern_06_128",
            "light_de_lantern_06_177",
            "light_de_lantern_06_256",
            "light_de_lantern_06_64",
            "Light_De_Lantern_06A",
            "light_de_lantern_05",
            "light_de_lantern_05_128_Carry",
            "light_de_lantern_05_200",
            "light_de_lantern_05_Carry",
            "light_de_lantern_02",
            "light_de_lantern_02-128",
            "light_de_lantern_02-177",
            "light_de_lantern_02_128",
            "light_de_lantern_02_256_blue",
            "light_de_lantern_02_256_Off",
            "light_de_lantern_02_blue",
            "Light_De_Lantern_01",
            "Light_De_Lantern_01_128",
            "Light_De_Lantern_01_177",
            "Light_De_Lantern_01_77",
            "light_de_lantern_01_off",
            "Light_De_Lantern_01white",
            "dx_l_ashl_lantern_01",
            "dx_l_lant_crystal_01",
            "dx_l_lant_crystal_02",
            "dx_l_lant_paper_01",        },
        attach = true,
        light = true,
        grabNode = "LANTERN"
    }
}


this.idleChances = {
   { group = "idle3", maxChance =  25 },  --sit
   { group = "idle4", maxChance = 50 },  --eat 
   { group = "idle5", maxChance = 100 },  --look 
}




function this.getModEnabled()
    return (
        this.getConfig().enabled and
        tes3.isModActive("TheGuarWhisperer.ESP")
    )
end

local fading
local function initialiseData()
    if not tes3.player.data.theGuarWhisperer then
        tes3.player.data.theGuarWhisperer = {}
    end
    
    this.data = tes3.player.data.theGuarWhisperer

    --in case you were stupid enough to save/load during a fadeout
    if fading then
        tes3.fadeIn(0)
    end
    event.trigger("GuarWhispererDataLoaded")
end
event.register("loaded", initialiseData)

function this.getHoursPassed()
    return ( tes3.worldController.daysPassed.value * 24 ) + tes3.worldController.hour.value
end

function this.upperFirst(str)
    return (string.gsub( str, "^%l", string.upper))
end


function this.getIsDead(ref)
    if not ref.mobile then return false end
    local animState = ref.mobile.actionData.animationAttackState
    local isDead = (
        ref.mobile.health.current <= 0 or 
        animState == tes3.animationState.dying or 
        animState == tes3.animationState.dead
    )
    return isDead
end

function this.messageBox(params)
    --[[
        Button = { text, callback}
    ]]--
    local message = params.message
    local buttons = params.buttons
    local function callback(e)
        --get button from 0-indexed MW param
        local button = buttons[e.button+1]
        if button.callback then
            button.callback()
        end
    end
    --Make list of strings to insert into buttons
    local buttonStrings = {}
    for _, button in ipairs(buttons) do
        table.insert(buttonStrings, button.text)
    end
    tes3.messageBox({
        message = message,
        buttons = buttonStrings,
        callback = callback
    })
end

function this.yeet(reference)
    reference.sceneNode.appCulled = true
    tes3.positionCell{
        reference = reference, 
        position = { 0, 0, 0, },
    }
    reference:disable()
    timer.delayOneFrame(function()
        mwscript.setDelete{ reference = reference}
    end)
end

local function setControlsDisabled(state)
    tes3.mobilePlayer.controlsDisabled = state
    tes3.mobilePlayer.jumpingDisabled = state
    tes3.mobilePlayer.viewSwitchDisabled = state
    tes3.mobilePlayer.vanityDisabled = state
    tes3.mobilePlayer.attackDisabled = state
    tes3.mobilePlayer.magicDisabled = state
end
function this.disableControls()
    setControlsDisabled(true)
end

function this.enableControls()
    setControlsDisabled(false)
    tes3.runLegacyScript{command = "EnableInventoryMenu"}
end

function this.fadeTimeOut( hoursPassed, secondsTaken, callback )
    local function fadeTimeIn()
        this.enableControls()
        fading = false
    end
    fading = true
    tes3.fadeOut({ duration = 0.5 })
    this.disableControls()
    --Halfway through, advance gamehour
    local iterations = 10
    timer.start({
        type = timer.real,
        iterations = iterations,
        duration = ( secondsTaken / iterations ),
        callback = (
            function()
                local gameHour = tes3.findGlobal("gameHour")
                gameHour.value = gameHour.value + (hoursPassed/iterations)
            end
        )
    })
    --All the way through, fade back in
    timer.start({
        type = timer.real,
        iterations = 1,
        duration = secondsTaken,
        callback = (
            function()
                local fadeBackTime = 1
                tes3.fadeIn({ duration = fadeBackTime })
                callback()
                timer.start({
                    type = timer.real,
                    iterations = 1,
                    duration = fadeBackTime, 
                    callback = fadeTimeIn
                })
            end
        )
    })
end

local refController = require("mer.theGuarWhisperer.referenceController")
function this.iterateRefType(refType, callback)
    for ref, _ in pairs(refController.controllers[refType].references) do
        --check requirements in case it's no longer valid
        if refController.controllers[refType]:requirements(ref) then
            if callback(ref) == false then break end
        else
            --no longer valid, remove from ref list
            refController.controllers[refType].references[ref] = nil
        end
    end
end

local function onLoadInitialiseRefs(e)
    this.log:debug("\n\nInitialising companion refs")
    for i, cell in ipairs(tes3.dataHandler.nonDynamicData.cells) do
        for reference in cell:iterateReferences() do
            event.trigger("GuarWhisperer:registerReference", { reference = reference })
        end
    end
end
event.register("loaded", onLoadInitialiseRefs)

return this