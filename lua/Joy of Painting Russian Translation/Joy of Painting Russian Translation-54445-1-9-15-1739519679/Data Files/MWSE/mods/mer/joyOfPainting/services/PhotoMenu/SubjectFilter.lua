--[[

    While the painting menu is open
    On a 0.5 second timer
    raytest from the cursor
    if it hits an object in the scene
    Show tootip ("Filter %s")
    When the user clicks on the object
    use the SubjectService to capture a screenshot of the filtered obejct
    Save it as a texture
]]

local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("SubjectFilter")
local Subject = require("mer.joyOfPainting.items.Subject")

local compositeShader

---@class JOP.SubjectFilter.params
---@field PhotoMenu JOP.PhotoMenu

---@class JOP.SubjectFilter : JOP.SubjectFilter.params
---@field oldRoot niNode
---@field oldDistantLand boolean|nil
---@field oldDistantStatics boolean|nil
---@field oldDistantWater boolean|nil
---@field safeTarget mwseSafeObjectHandle
local SubjectFilter = {}

---@param e JOP.SubjectFilter.params
function SubjectFilter.new(e)
    local self = setmetatable({}, {__index = SubjectFilter})
    self.PhotoMenu = e.PhotoMenu
    return self
end

local function getShader()
    if not compositeShader then
        compositeShader = mgeShadersConfig.find{ name = "jop_composite" }
    end
    return compositeShader
end

function SubjectFilter:getTarget()
    local result = common.getCursorTarget()
    local target = result and result.reference
    return target and Subject.isSubject(target) and target or nil
end

local onMouseButtonDown
local onEnterFrame
function SubjectFilter:registerEvents()
    ---@param e mouseButtonDownEventData
    onMouseButtonDown = function(e)
        if e.button ~= 0 then return end
        if not tes3ui.menuMode() then return end
        if tes3ui.getMenuOnTop() ~= self.PhotoMenu.menu then
            logger:debug("Not in photo menu")
            return
        end

        if common.clickedUIElement() then
            logger:debug("Clicked UI Element")
            return
        end

        if self.oldRoot then
            self:disableOcclusion()
            return
        else
            logger:debug("Mouse Button down")
            local target = self:getTarget()
            if not target then return end
            self:enableOcclusion(target)
        end
    end
    event.register("mouseButtonDown", onMouseButtonDown)

    onEnterFrame = function()
        self:subjectTooltip()
    end
    event.register("enterFrame", onEnterFrame)
end

function SubjectFilter:isolationActive()
    return self.oldRoot ~= nil
end

function SubjectFilter:setLabelText(menu, target)
    local label = menu:findChild("jop_subjectFilterTooltipLabel")
    if not label then return end
    local text = "Отменить изоляцию"
    if target and not self:isolationActive() then
        local name = target.object.name or target.object.id
        text = string.format("Изолировать объект '%s'", name)
    end
    label.text = text
end


local tooltipMenuId = "jop_subjectFilterTooltip"
local labelId = "jop_subjectFilterTooltipLabel"
function SubjectFilter:subjectTooltip()
    local target = self:getTarget() --[[@as tes3reference]]
    local validTarget = not not target
    local MenuMulti = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
    if not MenuMulti then return end

    local showTooltip = (not self.PhotoMenu.isLooking)
        and (self:isolationActive() or validTarget)

    local menu = MenuMulti:findChild(tooltipMenuId)
    if menu then
        menu.visible = showTooltip
        self:setLabelText(menu, target)
    else
        if not showTooltip then return end
        menu = MenuMulti:createBlock{ id = tooltipMenuId }
        menu.absolutePosAlignX = 0.5
        menu.absolutePosAlignY = 0.95
        menu.autoWidth = true
        menu.autoHeight = true

        local labelBackground = menu:createRect({color = {0, 0, 0}})
        labelBackground.autoHeight = true
        labelBackground.autoWidth = true
        local labelBorder = labelBackground:createThinBorder()
        labelBorder.autoHeight = true
        labelBorder.autoWidth = true
        labelBorder.childAlignX = 0.5
        labelBorder.paddingAllSides = 10
        labelBorder.flowDirection = "top_to_bottom"

        labelBorder:createLabel{id = labelId}
        self:setLabelText(menu, target)
    end
end


---@param reference tes3reference
function SubjectFilter:enableOcclusion(reference)
    logger:debug("Enabling occlusion for %s", reference.baseObject.id)

    self.oldRoot = tes3.getCamera().scene
    tes3.getCamera().scene = reference.sceneNode
    self.oldDistantLand = mge.render.distantLand
    mge.render.distantLand = false

    self.oldDistantStatics = mge.render.distantStatics
    mge.render.distantStatics = false

    self.oldDistantWater = mge.render.distantWater
    mge.render.distantWater = false

    ---@diagnostic disable-next-line: undefined-field
    if tes3.dataHandler.waterController.waterPlane.appCulled == false then
        tes3.runLegacyScript{command = "ToggleWater"}
    end

    self.safeTarget = tes3.makeSafeObjectHandle(reference)
end

function SubjectFilter:disableOcclusion()
    logger:debug("Disabling occlusion")
    if self.oldDistantLand ~= nil then
        mge.render.distantLand = self.oldDistantLand
        self.oldDistantLand = nil
    end

    if self.oldDistantStatics ~= nil then
        mge.render.distantStatics = self.oldDistantStatics
        self.oldDistantStatics = nil
    end

    if self.oldDistantWater ~= nil then
        mge.render.distantWater = self.oldDistantWater
        self.oldDistantWater = nil
    end

    if self.oldRoot ~= nil then
        tes3.getCamera().scene = self.oldRoot
        self.oldRoot = nil
    end
    ---@diagnostic disable-next-line: undefined-field
    if tes3.dataHandler.waterController.waterPlane.appCulled == true then
        tes3.runLegacyScript{command = "ToggleWater"}
    end

    self.safeTarget = nil

    --delete menu
    local MenuMulti = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
    if not MenuMulti then return end
    local menu = MenuMulti:findChild(tooltipMenuId)
    if menu then
        menu:destroy()
    end
end

function SubjectFilter:unregisterEvents()
    event.unregister("mouseButtonDown", onMouseButtonDown)
    event.unregister("enterFrame", onEnterFrame)
end



return SubjectFilter