local configPath = "limited_intervention"

local config = mwse.loadConfig(configPath)
if not config then
    config = {
        enableMod = true,
        divineInterventionsPerRank = 2,
        almsiviInterventionsPerRank = 2
    }
end


----------------------------------------------------
--Functions-----------------------------------------
----------------------------------------------------

local function getDivineInterventionsLeft()
    local imperialCult = tes3.getObject("chaplain ogrul").faction
    local data = tes3.player.data.limitedIntervention
    return (
        ( (imperialCult.playerRank + 1)  * config.divineInterventionsPerRank )
        - data.divineInterventionsCast
    )
end
local function getAlmsiviInterventionsLeft()
    local data = tes3.player.data.limitedIntervention
    local temple = tes3.getObject("adrusu rothrano").faction
    return (
        ( (temple.playerRank+1) * config.almsiviInterventionsPerRank )
        - data.almsiviInterventionsCast
    )
end

local function spellCast(e)
    local data = tes3.player.data.limitedIntervention
    if config.enableMod then
        local spell = e.source
        local isDivine = false
        local isAlmsivi = false
        for i=1, #spell.effects do
            if spell.effects[i].id == tes3.effect.divineIntervention then
                isDivine = true
            elseif spell.effects[i].id == tes3.effect.almsiviIntervention then
                isAlmsivi = true
            end
        end

        local imperialCult = tes3.getObject("chaplain ogrul").faction
        local temple = tes3.getObject("adrusu rothrano").faction--("Temple")

        if isDivine then
            if not imperialCult.playerJoined then
                e.castChance = 0
                tes3.messageBox("Only members of the Imperial Cult can use Divine Intervention.")
                return
            elseif getDivineInterventionsLeft() <= 0 then
                e.castChance = 0
                tes3.messageBox("You have no Divine Interventions left.")
            end
        end
        if isAlmsivi then
            if not temple.playerJoined then
                e.castChance = 0
                tes3.messageBox("Only members of the Temple can use Divine Intervention.")
                return
            elseif getAlmsiviInterventionsLeft() <= 0 then
                e.castChance = 0
                tes3.messageBox("You have no Almsivi Interventions left.")
            end
        end
    end
end
event.register("spellCast", spellCast)


local function spellCasted(e)
    if config.enableMod then
        local data = tes3.player.data.limitedIntervention
        local spell = e.source
        local isDivine = false
        local isAlmsivi = false
        for i=1, #spell.effects do
            if spell.effects[i].id == tes3.effect.divineIntervention then
                isDivine = true
            elseif spell.effects[i].id == tes3.effect.almsiviIntervention then
                isAlmsivi = true
            end
        end
        if isDivine then
            data.divineInterventionsCast = data.divineInterventionsCast + 1
            tes3.messageBox("You have %d Divine Interventions remaining", getDivineInterventionsLeft())
        elseif isAlmsivi then
            data.almsiviInterventionsCast = data.almsiviInterventionsCast + 1
            tes3.messageBox("You have %d Almsivi Interventions remaining", getAlmsiviInterventionsLeft())
        end
    end
end
event.register("spellCasted", spellCasted)

local function loaded()
    tes3.player.data.limitedIntervention = tes3.player.data.limitedIntervention or {}
    local data = tes3.player.data.limitedIntervention
    data.divineInterventionsCast = data.divineInterventionsCast or 0
    data.almsiviInterventionsCast = data.almsiviInterventionsCast or 0
end

event.register("loaded", loaded)

---------------------------------------------------
--MCM
---------------------------------------------------

local function registerMCM()
    local  sideBarDefault = (
        "This mod limits the number of times you can cast Divine or " ..
        "ALMSIVI Intervention based on your rank in the Imperial Cult or " ..
        "Tribunal Temple."
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

    local template = mwse.mcm.createTemplate("Limited Intervention")
    template:saveOnClose(configPath, config)
    template:register()

    local page = template:createSideBarPage()
    addSideBar(page)
    
    page:createOnOffButton{
        label = "Enable Limited Intervention",
        description = "Turn Limited Intervention on or off.",
        variable = mwse.mcm.createTableVariable{
            id = "enableMod",
            table = config
        }
    }

    page:createSlider{
        label = "Divine Interventions per Imperial Cult rank",
        description = "Determines how many Divine Interventions you gain per Imperial Cult rank (Default value: 2).",
        max = 10,
        step = 1,
        jump = 1,
        variable = mwse.mcm.createTableVariable{
            id = "divineInterventionsPerRank",
            table = config
        }
    }
    page:createSlider{
        label = "Almsivi Interventions per Tribunal Temple rank",
        description =  "Determines how many Almsivi Interventions you gain per Temple rank (Default value: 2).",
        max = 10,
        step = 1,
        jump = 1,
        variable = mwse.mcm.createTableVariable{
            id = "almsiviInterventionsPerRank",
            table = config
        }
    }
end

event.register("modConfigReady", registerMCM)