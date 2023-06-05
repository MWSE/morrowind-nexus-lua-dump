require("classImages.mcm")
local config = require("classImages.config")
local common = require("classImages.common")
local logger = common.createLogger("main")
local ImagePiece = require("classImages.components.ImagePiece")
local FakeClass = require("classImages.components.FakeClass")
local Requirements = require("classImages.components.Requirements")

---@class ClassImageService
local ClassImageService = {}

--- Adds the piece to the class image
---@param imageConfig ClassImages.ImageConfig
---@param parent tes3uiElement
---@param imagePath string
local function addImage(imageConfig, parent, imagePath)
    local image = parent:createImage{
        path = imagePath
    }
    image.width = imageConfig.width
    image.height = imageConfig.height
    image.scaleMode = true
    image.absolutePosAlignX = 0.5
    image.absolutePosAlignY = 0.5
end

---@class ClassImage.processPiece.processData
---@field slots table<ClassImages.ImagePiece.slot, boolean>
---@field piecesAdded table<string, number>
---@field count number
---@field hasShield boolean
---@field hasGold boolean
---@field doFiller boolean

---@param processData ClassImage.processPiece.processData
---@param piece ClassImages.ImagePiece
local function processPiece(processData, piece)
    logger:debug("Filler: %s. Priority: %s", processData.doFiller, piece.priority)

    if not Requirements.checkIsFiller(piece) == processData.doFiller then
        return true
    end
    if processData.count >= config.maxPieces then
        logger:debug("Max items reached")
        return false
    end
    logger:debug("----------------------------")
    logger:debug("CHECKING PIECE %s", piece.texture)
    logger:debug("----------------------------")

    local valid = Requirements.validForClass(piece)
        and Requirements.hasFreeSlot(processData.slots, piece)
        and Requirements.checkShieldState(processData.hasShield, piece)
        and Requirements.checkExclusions(processData.piecesAdded, piece)
        and Requirements.checkGold(processData.hasGold, piece)
    if valid then
        processData.piecesAdded[piece.priority] = piece
        if piece.isGold then
            processData.hasGold = true
        end
        if piece.shieldState == "isShield" then
            logger:debug("    - piece is a shield, set hasShield to true")
            processData.hasShield = true
        end
        for _, slot in ipairs(piece.slots) do
            logger:debug("    Filled slot %s", slot)
            logger:assert(processData.slots[slot] ~= true, "Slot already filled")
            processData.slots[slot] = true
            processData.count = processData.count + 1
        end
        logger:debug("------------------------------------------------")
        logger:debug("---- Piece %s is valid, image added", piece.texture)
        logger:debug("------------------------------------------------")
    else
        logger:debug("------------------------------------------------")
        logger:debug("---- Piece %s is not valid", piece.texture)
        logger:debug("------------------------------------------------")
    end
    logger:debug("\n")
    return true
end

local function initProcessData()
    ---@class ClassImage.processPiece.processData
    local processData = {
        slots = {
            Below_Left_1 = false,
            Below_Left_2 = false,
            Below_Left_3 = false,
            Below_Left_4 = false,
            Below_Left_5 = false,
            Below_Middle = false,
            Below_Right_1 = false,
            Below_Right_2 = false,
            Below_Right_3 = false,
            Background_Left = false,
            Background_Middle = false,
            Background_Right = false,
            Midground_Left = false,
            Midground_Middle = false,
            Midground_Right = false,
            Foreground_Left = false,
            Foreground_Middle = false,
            Foreground_Right = false,
            Above_Left_1 = false,
            Above_Left_2 = false,
            Above_Left_3 = false,
            Above_Left_4 = false,
            Above_Middle = false,
            Above_Right_1 = false,
            Above_Right_2 = false,
            Above_Right_3 = false,
            Above_Right_4 = false,
            Above_Right_5 = false,
            Above_Left_5 = false,
        },
        piecesAdded = {},
        count = 0,
        hasShield = false,
        hasGold = false,
        doFiller = false
    }
    return processData
end

--- Update the class image
---@param imageConfig ClassImages.ImageConfig
---@param parent tes3uiElement
function ClassImageService.doUpdate(imageConfig, parent)
    local class = FakeClass()
    if not config.mcm.enabled then
        logger:trace("Disabled")
        return
    end
    local classImageBlock = parent:findChild(imageConfig.imageBlockName)
    if not classImageBlock then
        logger:error("%s not found", imageConfig.imageBlockName)
        return
    end
    logger:debug(classImageBlock.name)
    --set up image block
    classImageBlock:destroyChildren()
    classImageBlock.minWidth = imageConfig.parentWidth
    classImageBlock.minHeight = imageConfig.parentHeight
    --get override if available
    local override = ClassImageService.getOverride()
    if override then
        logger:debug("Override found for class %s", class.name)
        addImage(imageConfig, classImageBlock, override)
        parent:updateLayout()
        return
    end

    --add background
    addImage(imageConfig, classImageBlock, "textures\\classImages\\0.background.tga")
    logger:debug("CHECKING CLASS %s", class.name)
    --Process pieces
    local pieces = ImagePiece:getRegisteredPieces()
    local processData = initProcessData()
    for i, piece in pairs(pieces) do
        logger:debug("non filler %d", i)
        if not processPiece(processData, piece) then break end
    end
    for i, piece in pairs(pieces) do
        logger:debug("filler %d", i)
        processData.doFiller = true
        if not processPiece(processData, piece) then break end
    end
    --add images in order of slot
    for _, slot in ipairs(config.slotsOrdered) do
        for _, piece in pairs(processData.piecesAdded) do
            if table.find(piece.slots, slot) then
                logger:debug("adding %s : %s", piece.priority, piece.texture)
                local path = string.format("textures\\classImages\\%s.tga", piece.texture)
                addImage(imageConfig, classImageBlock, path)
                --remove from pieces
                processData.piecesAdded[piece.priority] = nil
            end
        end
    end
    --add vignette
    addImage(imageConfig, classImageBlock, "textures\\classImages\\0.vignette.tga")
    parent:updateLayout()
end

--[[
    See if there is an image inside /textures/levelup named after
    the class and use that instead.
]]
function ClassImageService.getOverride()
    if not tes3.player then return end
    local path = string.format("textures\\levelup\\%s.dds", FakeClass().id)
    if tes3.getFileExists(path) then
        return path
    end
end


---@param e uiActivatedEventData
function ClassImageService.updateClassImage(e)
    local imageConfig = config.menuData[e.element.name]
    if imageConfig then
        local classList = e.element:findChild("MenuChooseClass_ClassScroll")
        if classList then
            classList = classList:getContentElement()
            for _, button in ipairs(classList.children) do
                button:registerAfter("mouseClick", function()
                    ClassImageService.doUpdate(imageConfig, e.element)
                end)
            end
        end
        ClassImageService.doUpdate(imageConfig, e.element)
    end
end


--- @param e tes3uiEventData
local function addClassImageToTooltip(e)
    local imageConfig = config.tooltipConfig
    local tooltip = tes3ui.findHelpLayerMenu("HelpMenu")
    if not tooltip then
        return
    end
    ClassImageService.doUpdate(imageConfig, tooltip)
end


---@param e uiActivatedEventData
function ClassImageService.doClassTooltip(e)
    if not tes3.player then return end
    if ClassImageService.getOverride() then return end
    logger:debug("MenuStat activated, registering tooltip")

	-- Improve class tooltips.
	local classLayout = e.element:findChild("MenuStat_class_layout") or e.element:findChild("MenuStatReview_class_layout")
	if (classLayout) then
		local label = classLayout:findChild("MenuStat_class_name")
		if label then
			label:registerAfter("help", addClassImageToTooltip)
		end
		local class = classLayout:findChild("MenuStat_class") or classLayout:findChild("MenuStatReview_class")
		if class then
			class:registerAfter("help", addClassImageToTooltip)
		end
	end
end

---@param e uiActivatedEventData
function ClassImageService.doCreateClassMenu(e)
    logger:debug("Activated createClassMenu")
    local imageConfig = config.createClassMenuConfig
    local menu = e.element
    local contents = menu:getContentElement()
    local block = contents:createThinBorder({ id = "CreateClassImage"})
    block.paddingAllSides = 2
    block.width = imageConfig.parentWidth
    block.height = imageConfig.parentHeight
    block.borderBottom = 4

    contents:reorderChildren(0, -1, 1)
    ClassImageService.doUpdate(imageConfig, menu)
end

---@param e uiActivatedEventData
function ClassImageService.updateCreateClassMenuOnButtonClose(e)
    local menus = {
        MenuSkills = true,
        MenuAttributes = true,
        MenuSpecialization = true,
    }
    local menuConfig = menus[e.element.name]
    if menuConfig then
        logger:debug("Opened a create class menu: %s", e.element.name)
        local menu = e.element
        menu:registerAfter("destroy", function()
            logger:debug("Menu destroyed, updating class image")
            local createClassMenu = tes3ui.findMenu("MenuCreateClass")
            if createClassMenu then
                ClassImageService.doUpdate(
                    config.createClassMenuConfig,
                    createClassMenu)
            else
                logger:warn("Menu not found")
            end
        end)
    end
end

return ClassImageService