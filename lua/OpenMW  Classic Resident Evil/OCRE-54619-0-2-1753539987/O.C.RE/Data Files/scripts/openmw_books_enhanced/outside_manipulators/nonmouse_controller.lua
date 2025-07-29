local content_name = require("scripts.openmw_books_enhanced.window.content_element_names")
local mousewheel = require("scripts.openmw_books_enhanced.outside_manipulators.mousewheel_handler")
local input = require('openmw.input')
local ambient = require('openmw.ambient')

local currentHighlightedObject = nil
local shouldIgnoreButtonReleases = true

local function updateDocumentWindowInKeyboardControllerScript(documentWindow)
    if documentWindow == nil then
        return
    end
    documentWindow:update()
    ambient.playSound("Book Page")
end

local function isButtonHidden(documentWindow, buttonName)
    return documentWindow.layout.content:indexOf(buttonName) == nil
        or documentWindow.layout.content[buttonName].props == nil
        or documentWindow.layout.content[buttonName].props.visible == false
end

local function setUnderline(documentWindow)
    if documentWindow == nil or documentWindow.layout == nil or documentWindow.layout.props == nil or not documentWindow.layout.props.visible then
        return
    end
    local function setUnderlineInButton(buttonName)
        if documentWindow.layout.content:indexOf(buttonName) ~= nil then
            documentWindow.layout.content[buttonName].content[content_name.controlUnderline].props.visible =
                (currentHighlightedObject == buttonName)
        end
    end
    local underLineVisualSetters = {
        [content_name.closeButton] = function()
            setUnderlineInButton(content_name.closeButton)
        end,
        [content_name.prevButton] = function()
            setUnderlineInButton(content_name.prevButton)
        end,
        [content_name.nextButton] = function()
            setUnderlineInButton(content_name.nextButton)
        end,
        [content_name.takeButton] = function()
            setUnderlineInButton(content_name.takeButton)
        end,
    }
    for _, setUnderlineVisual in pairs(underLineVisualSetters) do
        setUnderlineVisual()
    end
end

local function shiftHighlightedObjectBy(documentWindow, nextObject)
    if nextObject[currentHighlightedObject] == nil then return end

    currentHighlightedObject = nextObject[currentHighlightedObject]
    while isButtonHidden(documentWindow, currentHighlightedObject) do
        currentHighlightedObject = nextObject[currentHighlightedObject]
    end
    setUnderline(documentWindow)
    updateDocumentWindowInKeyboardControllerScript(documentWindow)
end

local function executeCurrentHighlightedObject(documentWindow)
    if currentHighlightedObject == nil then
        return
    end
    local objectExecutors = {
        [content_name.closeButton] = function(documentWindow)
            documentWindow.layout.content[content_name.closeButton].userData.onClicking()
        end,
        [content_name.nextButton] = function(documentWindow)
            documentWindow.layout.content[content_name.nextButton].userData.onClicking()
            if not documentWindow.layout.content[content_name.nextButton].props.visible then
                shiftHighlightedObjectBy(
                    documentWindow,
                    {
                        [content_name.nextButton] = content_name.prevButton
                    })
            end
        end,
        [content_name.prevButton] = function(documentWindow)
            documentWindow.layout.content[content_name.prevButton].userData.onClicking()
            if not documentWindow.layout.content[content_name.prevButton].props.visible then
                shiftHighlightedObjectBy(
                    documentWindow,
                    {
                        [content_name.prevButton] = content_name.nextButton
                    })
            end
        end,
        [content_name.takeButton] = function(documentWindow)
            documentWindow.layout.content[content_name.takeButton].userData.onClicking()
        end,
    }
    if objectExecutors[currentHighlightedObject] ~= nil and not isButtonHidden(documentWindow, currentHighlightedObject) then
        objectExecutors[currentHighlightedObject](documentWindow)
    end
end

local function shiftHighlightedObjectToTheLeft(documentWindow)
    shiftHighlightedObjectBy(
        documentWindow,
        {
            [content_name.closeButton] = content_name.nextButton,
            [content_name.nextButton] = content_name.prevButton,
            [content_name.prevButton] = content_name.takeButton,
            [content_name.takeButton] = content_name.closeButton,
        })
end

local function shiftHighlightedObjectToTheRight(documentWindow)
    shiftHighlightedObjectBy(
        documentWindow,
        {
            [content_name.closeButton] = content_name.takeButton,
            [content_name.takeButton] = content_name.prevButton,
            [content_name.prevButton] = content_name.nextButton,
            [content_name.nextButton] = content_name.closeButton,
        })
end

local K = {}

function K.allowReactingToInputs()
    shouldIgnoreButtonReleases = false
end

function K.initiateNonMouseControls(documentWindow)
    currentHighlightedObject = content_name.closeButton
    shouldIgnoreButtonReleases = true
    -- setUnderline(documentWindow)
end

local INPUT = {
    ACTIVATE = 100,
    LEFT = 200,
    RIGHT = 300,
    UP = 400,
    DOWN = 500,
}

local function reactToInput(documentWindow, input)
    if documentWindow == nil or documentWindow.layout == nil or documentWindow.layout.props == nil or not documentWindow.layout.props.visible then
        return
    end
    if shouldIgnoreButtonReleases then
        return
    end
    if input == INPUT.ACTIVATE then
        executeCurrentHighlightedObject(documentWindow)
        updateDocumentWindowInKeyboardControllerScript(documentWindow)
    elseif input == INPUT.LEFT then
        mousewheel.manipulateDocumentWindowBasedOnMouseWheelTurn(documentWindow, 1)
        updateDocumentWindowInKeyboardControllerScript(documentWindow)
        --shiftHighlightedObjectToTheLeft(documentWindow)
    elseif input == INPUT.RIGHT then
        mousewheel.manipulateDocumentWindowBasedOnMouseWheelTurn(documentWindow, -1)
        updateDocumentWindowInKeyboardControllerScript(documentWindow)
        --shiftHighlightedObjectToTheRight(documentWindow)
--   elseif input == INPUT.UP then
--        mousewheel.manipulateDocumentWindowBasedOnMouseWheelTurn(documentWindow, 1)
--        updateDocumentWindowInKeyboardControllerScript(documentWindow)
--    elseif input == INPUT.DOWN then
--        mousewheel.manipulateDocumentWindowBasedOnMouseWheelTurn(documentWindow, -1)
--        updateDocumentWindowInKeyboardControllerScript(documentWindow)
    end
end

function K.reactToKeyboardKey(documentWindow, keyboardKey)
    if documentWindow == nil or documentWindow.layout == nil or documentWindow.layout.props == nil or not documentWindow.layout.props.visible then
        return
    end
    if keyboardKey.code == input.KEY.E or keyboardKey.code == input.KEY.Enter then
        reactToInput(documentWindow, INPUT.ACTIVATE)
    elseif keyboardKey.code == input.KEY.A or keyboardKey.code == input.KEY.LeftArrow then
        reactToInput(documentWindow, INPUT.LEFT)
    elseif keyboardKey.code == input.KEY.D or keyboardKey.code == input.KEY.RightArrow then
        reactToInput(documentWindow, INPUT.RIGHT)
    elseif keyboardKey.code == input.KEY.W or keyboardKey.code == input.KEY.UpArrow then
        reactToInput(documentWindow, INPUT.UP)
    elseif keyboardKey.code == input.KEY.S or keyboardKey.code == input.KEY.DownArrow then
        reactToInput(documentWindow, INPUT.DOWN)
    end
end

function K.reactToControllerKey(documentWindow, controllerKey) --TODO buggy
    if documentWindow == nil or documentWindow.layout == nil or documentWindow.layout.props == nil or not documentWindow.layout.props.visible then
        return
    end
    if controllerKey == input.CONTROLLER_BUTTON.A then
        reactToInput(documentWindow, INPUT.ACTIVATE)
    elseif controllerKey == input.CONTROLLER_BUTTON.DPadLeft then
        reactToInput(documentWindow, INPUT.LEFT)
    elseif controllerKey == input.CONTROLLER_BUTTON.DPadRight then
        reactToInput(documentWindow, INPUT.RIGHT)
    elseif controllerKey == input.CONTROLLER_BUTTON.DPadUp or controllerKey == input.CONTROLLER_BUTTON.LeftShoulder then
        reactToInput(documentWindow, INPUT.UP)
    elseif controllerKey == input.CONTROLLER_BUTTON.DPadDown or controllerKey == input.CONTROLLER_BUTTON.RightShoulder then
        reactToInput(documentWindow, INPUT.DOWN)
    end
end

return K
