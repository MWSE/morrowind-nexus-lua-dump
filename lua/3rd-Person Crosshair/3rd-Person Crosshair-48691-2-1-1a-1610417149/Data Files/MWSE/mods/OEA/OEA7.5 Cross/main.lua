local cursor
local ID1Block
local ID2Elem
local HUDMenuID

local configPath = "3rd-Person_Crosshair"
local defaultConfig = {
	TurnedOn =
		true,
	TurnOff =
		true,
	OffsetX =
		0,
	OffsetZ =
		0,
	PositiveX =
		true,
	PositiveZ =
		true,
	Scale = 
		false
	}
local config = mwse.loadConfig(configPath, defaultConfig)

local function createCursor(e)
    local cursorBlock
    local multiMenu

    if (e.element == nil) then
	multiMenu = tes3ui.findMenu(HUDMenuID)
    else
        multiMenu = e.element
    end

    if (multiMenu:findChild(ID1Block) ~= nil) then
        cursorBlock = multiMenu:findChild(ID1Block)
    else
        cursorBlock = multiMenu:createBlock{ id = ID1Block }
    end
    cursorBlock.positionX = 0
    cursorBlock.positionY = 0
    cursorBlock.autoWidth = true
    cursorBlock.autoHeight = true

    if (tes3.hasCodePatchFeature(130) ~= nil) and (tes3.hasCodePatchFeature(130) == true) then
        cursorBlock.absolutePosAlignX = 0.435
        cursorBlock.absolutePosAlignY = 0.495
    else
        local XO = config.OffsetX
        if (config.PositiveX == false) then
            XO = 0 - XO
        end
        local ZO = config.OffsetZ
        if (config.PositiveZ == false) then
            ZO = 0 - ZO
        end
	if (config.Scale == true) and (tes3.mobilePlayer.is3rdPerson == false) then
		XO = 0
		ZO = 0
	end
        cursorBlock.absolutePosAlignX = 0.5 - ((0.06 * XO) / 25)
        cursorBlock.absolutePosAlignY = 0.5 + ((0.1 * ZO) / 25)
    end

    if (cursorBlock:findChild(ID2Elem) ~= nil) then
        cursorBlock = multiMenu:findChild(ID2Elem)
    else
        cursor = cursorBlock:createImage{ id = ID2Elem, path = "Textures\\target.dds" }
    end
    cursor.imageScaleX = 0.65
    cursor.imageScaleY = 0.65

    if (config.TurnedOn == false) then
	cursor.visible = false
	return
    end

    if (tes3.mobilePlayer.is3rdPerson == false) and (config.TurnOff == true) then
	cursor.visible = false
	return
    elseif (tes3.mobilePlayer.is3rdPerson == true) then
	cursor.visible = true
    end
end

local function OnMenuEnter(e)
    if (cursor ~= nil) then
	cursor.visible = false
    end
end

local function OnMenuExit(e)
    if (cursor ~= nil) and (config.TurnedOn == true) then
        cursor.visible = true
	createCursor(e)
    end
end

local function OnLoad(e)
    mwse.log("[OEA7.5 Cross] Initialized.")
    event.register("uiActivated", createCursor, { filter = "MenuMulti" })
    event.register("menuEnter", OnMenuEnter)
    event.register("menuExit", OnMenuExit)
    ID1Block = tes3ui.registerID("cursorBlockId")
    ID2Elem = tes3ui.registerID("cursorID")
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

    local text = page:createInfo{
        label = "When switching between viewpoints (1st-Person or 3rd-Person), you will need to enter and then exit ".. 
        "Menu Mode in order for the cursor to appear, disappear, or shift, in accordance with the selections below."
    }

    local sign = page:createYesNoButton{
        label = "Enable mod?",
        variable = mwse.mcm:createTableVariable{
            id = "TurnedOn",
            table = config
        }
    }

    local sign7 = page:createYesNoButton{
        label = "Turn cursor off in 1st-Person?",
        variable = mwse.mcm:createTableVariable{
            id = "TurnOff",
            table = config
        }
    }

    local slid = page:createSlider{
	label = "MGE XE 3rd-Person Camera Shift X Offset",
	variable = mwse.mcm:createTableVariable{
	    id = "OffsetX",
	    table = config
	},
	min = 0,
	max = 200
    }

    local sign2 = page:createYesNoButton{
        label = "Is your X offset positive?",
        variable = mwse.mcm:createTableVariable{
            id = "PositiveX",
            table = config
        }
    }

    local slid2 = page:createSlider{
	label = "MGE XE 3rd-Person Camera Shift Z Offset",
	variable = mwse.mcm:createTableVariable{
	    id = "OffsetZ",
	    table = config
	},
	min = 0,
	max = 200
    }

    local sign3 = page:createYesNoButton{
        label = "Is your Z offset positive?",
        variable = mwse.mcm:createTableVariable{
            id = "PositiveZ",
            table = config
        }
    }

    local shorn = page:createYesNoButton{
        label = "Turn on UI Scaling Mode? This centers the crosshair in first person, offsets it in third, and is overidden by the other options.",
        variable = mwse.mcm:createTableVariable{
            id = "Scale",
            table = config
        }
    }

    mwse.mcm.register(template)
end

event.register("modConfigReady", registerModConfig)