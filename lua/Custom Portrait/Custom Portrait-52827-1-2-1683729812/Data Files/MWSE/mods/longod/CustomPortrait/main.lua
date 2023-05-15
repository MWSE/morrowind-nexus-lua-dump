local settings = require("longod.CustomPortrait.config")
local validator = require("longod.CustomPortrait.validator")

--local showPortrait = true
-- cache
local textureWidth = 1
local textureHeight = 1

---@param width integer
---@param n tes3uiElement
---@return integer
local function AddBorderWidth(width, n)
    if n.parent then
        if n.borderRight then
            width = width + n.borderRight
        elseif n.borderAllSides then
            width = width + n.borderAllSides
        end
        if n.borderLeft then
            width = width + n.borderLeft
        elseif n.borderAllSides then
            width = width + n.borderAllSides
        end
    end
    return width
end

---@param width integer
---@param n tes3uiElement
---@return integer
local function AddPaddingWidth(width, n)
    if n.paddingRight then
        width = width + n.paddingRight
    elseif n.paddingAllSides then
        width = width + n.paddingAllSides
    end
    if n.paddingLeft then
        width = width + n.paddingLeft
    elseif n.paddingAllSides then
        width = width + n.paddingAllSides
    end
    return width
end

---@param image tes3uiElement
local function RevertCharacterImage(image)
    image.contentPath = nil
    image.scaleMode = true
    image.minWidth = nil
    image.imageScaleX = 0
    image.imageScaleY = 0
    image.autoWidth = false
    image.autoHeight = false
    tes3ui.updateInventoryCharacterImage()
end

---@param ev tes3uiEventData
local function OnMouseClick(ev)
    -- mwse.log("mouseClick")
    -- When the cursor is holding an item, it is time to equip or use that item, so do it.
    -- Otherwise, it wants to unequip the item, so it ignores it.
    local cursor = tes3ui.findHelpLayerMenu("CursorIcon")
    if cursor then
        local tile = cursor:getPropertyObject("MenuInventory_Thing", "tes3inventoryTile")
        if tile then
            ev.source:forwardEvent(ev)
        end
    end
    -- mwse.log("unregister on mouseClick")
    -- When clicked, leave event is not fired.
    ev.source:unregister(tes3.uiEvent.mouseClick)
end

---@param e tes3uiEventData
---@param image tes3uiElement
---@param sourceAspectRatio number 1:2=0.5
local function OnPreUpdate(e, image, sourceAspectRatio)
    if settings.showPortrait then
        local profile = settings:GetProfile()
        if not profile then
            RevertCharacterImage(image)
            settings.showPortrait = false
            return
        end
        -- mwse.log("OnPreUpdate")

        local path = profile.path
        if image.contentPath ~= path then
            if not validator.IsValidPath(path) then
                tes3.messageBox("[Custom Portrait] Invalid Path:\n" .. profile.path)
                RevertCharacterImage(image)
                settings.showPortrait = false
                return
            end

            local texture = niSourceTexture.createFromPath(path)
            if not validator.IsValidTextue(texture) then
                tes3.messageBox("[Custom Portrait] Invalid Image:\n" .. profile.path)
                RevertCharacterImage(image)
                settings.showPortrait = false
                return
            end

            textureWidth = math.max(texture.width, 1)
            textureHeight = math.max(texture.height, 1)

            image.contentPath = path
        end

        local desiredWidth = math.max(profile.width > 0 and profile.width or textureWidth, 1)
        local desiredHeight = math.max(profile.height > 0 and profile.height or textureHeight, 1)
        local desiredAspect = desiredWidth / desiredHeight
        local widthRatio = desiredWidth / textureWidth
        local heightRatio = desiredHeight / textureHeight
        local aspectRatio = widthRatio / heightRatio

        if sourceAspectRatio > desiredAspect then
            -- fit width base
            local scale = image.width / textureWidth
            image.imageScaleX = scale
            image.imageScaleY = scale / aspectRatio
        else
            -- fit height base
            local scale = image.height / textureHeight
            image.imageScaleX = scale * aspectRatio
            image.imageScaleY = scale
        end
        image.scaleMode = false
        -- it seems required, especially go back from mcm while inventory is open. but it's not perfect.
        image.autoWidth = true
        image.autoHeight = true
        -- crop
        local minWidth = image.height * sourceAspectRatio
        local maxWidth = math.max(minWidth, image.height * desiredAspect)
        image.minWidth = math.ceil(math.lerp(minWidth, maxWidth, profile.cropWidth))
    end
end

--- @param e uiActivatedEventData
local function OnMenuInventoryActivated(e)
    if not e.newlyCreated then
		return
	end

    local image = e.element:findChild("MenuInventory_CharacterImage")
    if image then
        -- mwse.log("Activated")

        settings.showPortrait = true -- initial state

        -- Handle mouse over and click event
        -- Most cases seem to be fine, but sometimes it's not right when going to and from mod config.
        image:register(tes3.uiEvent.mouseOver,
            ---@param ev tes3uiEventData
            function(ev)
                -- mwse.log("mouseOver")
                if settings.showPortrait then
                    -- mouseClick event seems to be unregistered by the character image process or someone else.
                    -- so register each time.
                    -- mwse.log("register on mouseOver")
                    ev.source:register(tes3.uiEvent.mouseClick, OnMouseClick)
                    -- And, suppress tooltips by not handling mouseOver event
                else
                    ev.source:forwardEvent(ev)
                end
            end)
        image:register(tes3.uiEvent.mouseLeave,
            ---@param ev tes3uiEventData
            function(ev)
                -- mwse.log("mouseLeave")
                ev.source:forwardEvent(ev)
                if settings.showPortrait then
                    -- mwse.log("unregister on mouseLeave")
                    ev.source:unregister(tes3.uiEvent.mouseClick)
                end
            end)

        -- aspect ratio of original character image , it's 1:2
        -- fixed value avoid too small values
        local expectAspect = 0.5 -- image.width / image.height

        local imageWidth = image.width
        local imageHeight = image.height

        -- The character image is always resized, so resize them again before updating the inventry menu.
        e.element:register(tes3.uiEvent.preUpdate,
            ---@param ev tes3uiEventData
            function(ev)
                ev.source:forwardEvent(ev) -- nothing seems to happens, but call for compatibility
                OnPreUpdate(ev, image, expectAspect)
                imageWidth = image.width
                imageHeight = image.height
            end)

        -- Then, minWwidth of the menu is set by width (before replaced) of the character image and the weight bar, so recalculate minWidth.
        e.element:register(tes3.uiEvent.update,
            ---@param ev tes3uiEventData
            function(ev)
                ev.source:forwardEvent(ev) -- it seems ok
                if settings.showPortrait then
                    -- mwse.log("Update")
                    local windowMinWidth = math.max(image.minWidth, image.width)
                    local node = image
                    -- exclude padding
                    windowMinWidth = AddBorderWidth(windowMinWidth, node)

                    node = node.parent
                    while node ~= nil do
                        windowMinWidth = AddPaddingWidth(windowMinWidth, node)
                        windowMinWidth = AddBorderWidth(windowMinWidth, node)
                        node = node.parent
                    end
                    -- not enough width, it seems double outer thick border frame do not contain property.
                    windowMinWidth = windowMinWidth + (4 * 2) * 2
                    image:getTopLevelMenu().minWidth = windowMinWidth

                    -- If image size is different from the size at the time of PreUpdate, it will attempt to update the image until it is the same size.
                    -- This avoids changing parameters during Update, but it perhaps not be necessary to adjust the scale in PreUpdate because it perhapsbe OK to do so.
                    if image.width ~= imageWidth or image.height ~= imageHeight then
                        -- mwse.log("Reflesh")
                        timer.delayOneFrame(
                        function()
                            e.element:updateLayout()
                        end,
                        timer.real)
                    end
                end
            end)

        -- toggle portrait when armor rating clicked
        local ar = e.element:findChild("MenuInventory_ArmorRating")
        ar:register(tes3.uiEvent.mouseClick,
            function()
                settings.showPortrait = not settings.showPortrait
                if settings.showPortrait then
                    -- preUpdate
                else
                    RevertCharacterImage(image)
                end
                image:getTopLevelMenu():updateLayout()
            end)

        e.element:updateLayout()
    end
end
event.register(tes3.event.uiActivated, OnMenuInventoryActivated, { filter = "MenuInventory" })

local function OnModConfigReady()
    mwse.registerModConfig("Custom Portrait", require("longod.CustomPortrait.mcm"));
end

event.register(tes3.event.modConfigReady, OnModConfigReady)
