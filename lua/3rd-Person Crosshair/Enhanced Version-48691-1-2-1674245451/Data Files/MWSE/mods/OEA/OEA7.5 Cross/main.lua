local crosshair
local ID1Block
local ID2Elem
local HUDMenuID

local configPath = "3rd-Person_Crosshair"
local defaultConfig = {
     TurnedOn =
     true,
     CrosshairScale =
     65,
     AutoHide =
     false,
     TurnOff =
     true,
     OffsetX =
     0,
     OffsetZ =
     0,
     Scale =
     false
}
local config = mwse.loadConfig(configPath, defaultConfig)

local POVToggled = false

local function createCrosshair(e)
     local crosshairBlock
     local multiMenu

     local is3rdPerson
     if (POVToggled) then
          is3rdPerson = (not tes3.mobilePlayer.is3rdPerson)
     else
          is3rdPerson = (tes3.mobilePlayer.is3rdPerson)
     end
     POVToggled = false

     if (e.element == nil) then
          multiMenu = tes3ui.findMenu(HUDMenuID)
     else
          multiMenu = e.element
     end

     if (multiMenu:findChild(ID1Block) ~= nil) then
          crosshairBlock = multiMenu:findChild(ID1Block)
     else
          crosshairBlock = multiMenu:createBlock{ id = ID1Block }
     end
     crosshairBlock.positionX = 0
     crosshairBlock.positionY = 0
     crosshairBlock.autoWidth = true
     crosshairBlock.autoHeight = true

     if (tes3.hasCodePatchFeature(130) ~= nil) and (tes3.hasCodePatchFeature(130) == true) then
          crosshairBlock.absolutePosAlignX = 0.435
          crosshairBlock.absolutePosAlignY = 0.495
     else
          local XO = config.OffsetX
          local ZO = config.OffsetZ
          if (config.Scale == true) and (is3rdPerson == false) then
               XO = 0
               ZO = 0
          end
          crosshairBlock.absolutePosAlignX = 0.5 - ((0.06 * XO) / 25)
          crosshairBlock.absolutePosAlignY = 0.5 + ((0.1 * ZO) / 25)
     end

     if (crosshairBlock:findChild(ID2Elem) ~= nil) then
          crosshairBlock = multiMenu:findChild(ID2Elem)
     else
          crosshair = crosshairBlock:createImage{ id = ID2Elem, path = "Textures\\target.dds" }
     end
     crosshair.imageScaleX = config.CrosshairScale / 100
     crosshair.imageScaleY = config.CrosshairScale / 100

     if (config.TurnedOn == false) then
          crosshair.visible = false
          return
     end

     if (config.AutoHide and not tes3.mobilePlayer.inCombat) then
          crosshair.visible = false
          return
     end

     if (is3rdPerson == false) and (config.TurnOff == true) then
          crosshair.visible = false
          return
     elseif (is3rdPerson == true) then
          crosshair.visible = true
     end
end

local function OnMenuEnter(e)
     if (crosshair ~= nil) then
          crosshair.visible = false
     end
end

local function OnMenuExit(e)
     if (crosshair ~= nil) and (config.TurnedOn == true) then
          crosshair.visible = true
          createCrosshair(e)
     end
end

local function OnTogglePOV(e)
     if (e.result and e.transition == tes3.keyTransition.up) then
          POVToggled = true
          createCrosshair(e)
     end
end

local function OnCombatStarted(e)
     if (config.AutoHide) then
          crosshair.visible = true
     end
end

local function OnCombatStopped(e)
     if (config.AutoHide and not tes3.mobilePlayer.inCombat) then
          crosshair.visible = false
     end
end

local function OnCellChanged(e)
     if (config.AutoHide and not tes3.mobilePlayer.inCombat) then
          crosshair.visible = false
     end
end

local function OnLoad(e)
     mwse.log("[OEA7.5 Cross] Initialized.")
     event.register("uiActivated", createCrosshair, { filter = "MenuMulti" })
     event.register("menuEnter", OnMenuEnter)
     event.register("menuExit", OnMenuExit)
     event.register("keybindTested", OnTogglePOV, { filter = tes3.keybind.togglePOV })
     event.register("combatStarted", OnCombatStarted)
     event.register("combatStopped", OnCombatStopped)
     event.register("cellChanged", OnCellChanged)
     ID1Block = tes3ui.registerID("crosshairBlockId")
     ID2Elem = tes3ui.registerID("crosshairID")
     HUDMenuID = tes3ui.registerID("MenuMulti")
end
event.register("initialized", OnLoad)

----MCM
local function registerModConfig()
     local template = mwse.mcm.createTemplate({ name = "3rd-Person Crosshair" })
     template:saveOnClose(configPath, config)

     local page = template:createPage()
     page.noScroll = true
     page.indent = 0
     page.postCreate = function(self)
     self.elements.innerContainer.paddingAllSides = 10
end

local sign = page:createYesNoButton{
     label = "Enable Mod?",
     variable = mwse.mcm:createTableVariable{
          id = "TurnedOn",
          table = config
     }
}

local slid = page:createSlider{
     label = "Crosshair Scale",
     variable = mwse.mcm:createTableVariable{
          id = "CrosshairScale",
          table = config
     },
     min = 25,
     max = 200,
}

local sign1 = page:createYesNoButton{
     label = "Auto-hide crosshair?",
     variable = mwse.mcm:createTableVariable{
          id = "AutoHide",
          table = config
     }
}

local sign2 = page:createYesNoButton{
     label = "Turn off crosshair in 1st-Person?",
     variable = mwse.mcm:createTableVariable{
          id = "TurnOff",
          table = config
     }
}

local slid1 = page:createSlider{
     label = "MGE XE 3rd-Person Camera X Offset",
     variable = mwse.mcm:createTableVariable{
          id = "OffsetX",
          table = config
     },
     min = -200,
     max = 200
}

local slid2 = page:createSlider{
     label = "MGE XE 3rd-Person Camera Z Offset",
     variable = mwse.mcm:createTableVariable{
          id = "OffsetZ",
          table = config
     },
     min = -200,
     max = 200
}

local shorn = page:createYesNoButton{
     label = "Turn on MGE XE UI Scaling Mode? This centers the crosshair in 1st- and offsets it in 3rd-Person view.",
     variable = mwse.mcm:createTableVariable{
          id = "Scale",
          table = config
     }
}

mwse.mcm.register(template)
end

event.register("modConfigReady", registerModConfig)
