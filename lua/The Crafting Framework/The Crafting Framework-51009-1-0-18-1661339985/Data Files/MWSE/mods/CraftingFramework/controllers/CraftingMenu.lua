local Material = require("CraftingFramework.components.Material")
local Util = require("CraftingFramework.util.Util")
local log = Util.createLogger("CraftingMenu")

local CraftingMenu = {}

local uiids = {
    titleBlock = tes3ui.registerID("Crafting_Menu_TitleBlock"),
    craftingMenu = tes3ui.registerID("CF_Menu"),
    midBlock = tes3ui.registerID("Crafting_Menu_MidBlock"),
    previewBorder = tes3ui.registerID("Crafting_Menu_PreviewBorder"),
    previewBlock = tes3ui.registerID("Crafting_Menu_PreviewBlock"),
    nifPreviewBlock = tes3ui.registerID("Crafting_Menu_NifPreviewBlock"),
    imagePreviewBlock = tes3ui.registerID("Crafting_Menu_ImagePreviewBlock"),
    selectedItem = tes3ui.registerID("Crafting_Menu_SelectedResource"),
    nif = tes3ui.registerID("Crafting_Menu_NifPreview"),
    descriptionBlock = tes3ui.registerID("Crafting_Menu_DescriptionBlock"),
    buttonsBlock = tes3ui.registerID("Crafting_Menu_ButtonsBlock"),
    recipeListBlock = tes3ui.registerID("Crafting_Menu_recipeListBlock"),
    previewPane = tes3ui.registerID("Crafting_Menu_PreviewPane"),
    previewName = tes3ui.registerID("Crafting_Menu_PreviewName"),
    previewDescription = tes3ui.registerID("Crafting_Menu_PreviewDescription"),
    materialRequirementsPane = tes3ui.registerID("Crafting_Menu_MaterialRequirementsPane"),
    materialRequirementsBlock = tes3ui.registerID("Crafting_Menu_MaterialRequirementsBlock"),
    skillRequirementsBlock = tes3ui.registerID("Crafting_Menu_SkillRequirementsBlock"),
    skillRequirementsPane = tes3ui.registerID("Crafting_Menu_SkillsPane"),
    customRequirementsBlock = tes3ui.registerID("Crafting_Menu_CustomRequirementsBlock"),
    customRequirementsPane = tes3ui.registerID("Crafting_Menu_CustomRequirementsPane"),
    toolRequirementsPane = tes3ui.registerID("Crafting_Menu_ToolsPane"),
    toolRequirementsBlock = tes3ui.registerID("Crafting_Menu_ToolsContainer"),
    createItemButton = tes3ui.registerID("Crafting_Menu_CreateItemButton"),
    unlockPackButton = tes3ui.registerID("Crafting_Menu_UnlockPackButton"),
    cancelButton = tes3ui.registerID("Crafting_Menu_CancelButton"),
    searchBar = tes3ui.registerID("Crafting_Menu_SearchBar"),
}
local m1 = tes3matrix33.new()
local m2 = tes3matrix33.new()

---@param menuActivator  craftingFrameworkMenuActivator
function CraftingMenu:new(menuActivator)
    local craftingMenu = setmetatable(menuActivator, self)
    craftingMenu.showCategories = menuActivator.defaultShowCategories
    craftingMenu.currentFilter = menuActivator.defaultFilter
    craftingMenu.currentSorter = menuActivator.defaultSort
    craftingMenu.categories = {}
    self.__index = self
    return craftingMenu
end

function CraftingMenu:closeMenu()
    log:debug("Closing Menu")
    local menu = tes3ui.findMenu(uiids.craftingMenu)
    if menu then
        log:debug("Destroying Menu")
        menu:destroy()
        tes3ui.leaveMenuMode()
        if self.closeCallback then
            self.closeCallback()
        end
    else
        log:error("Can't find menu!!!")
    end
end

function CraftingMenu:craftItem(button)
    if not self.selectedRecipe then return end
    self.selectedRecipe:craft()
    button.widget.state = 2
    button.disabled = true

    if self.selectedRecipe.craftable:isCarryable() then
        self:updateMenu()
    else
        self:closeMenu()
    end
end


local sorters = {}
sorters.name = {
    name = "Name",
    sorter = function(a, b)
        return a.craftable:getName() < b.craftable:getName()
    end,
    nextSorter = "skill",
}
sorters.skill = {
    name = "Difficulty",
    sorter = function(a, b)
        local aSkill = a:getAverageSkillLevel()
        local bSkill = b:getAverageSkillLevel()
        if aSkill == bSkill then
            return sorters.name.sorter(a, b)
        else
            return aSkill < bSkill
        end
    end,
    nextSorter = "canCraft",
}
sorters.canCraft = {
    name = "Can Craft",
    sorter = function(a, b)
        local aMeetsRequirements = a:meetsAllRequirements() and 1 or 0
        local bMeetsRequirements = b:meetsAllRequirements() and 1 or 0
        if aMeetsRequirements == bMeetsRequirements then
            return sorters.name.sorter(a, b)
        else
            return aMeetsRequirements > bMeetsRequirements
        end
    end,
    nextSorter = "name",
}

local filters = {}
filters.all = {
    name = "All",
    filter = function(recipe)
        return true
    end,
    nextFilter = "canCraft"
}
filters.canCraft = {
    name = "Can Craft",
    filter = function(recipe)
        return recipe:meetsAllRequirements()
    end,
    nextFilter = "hasMaterials"
}
filters.hasMaterials = {
    name = "Materials",
    filter = function(recipe)
        return recipe:hasMaterials() and recipe:meetsToolRequirements()
    end,
    nextFilter = "skill"
}
filters.skill = {
    name = "Skill",
    filter = function(recipe)
        return recipe:meetsSkillRequirements()
    end,
    nextFilter = "all"
}


function CraftingMenu:toggleAllCategories()
    for _, category in pairs(self.categories) do
        category.visible = not self.collapseCategories
    end
end

local menuButtons = {
    {
        id = "CraftingFramework_Button_collapse",
        name = function(self)
            return self.collapseCategories and "Expand [+]" or "Collapse [-]"
        end,
        callback = function(self, button)
            self.collapseCategories = not self.collapseCategories
            self:toggleAllCategories()
            button.text = self.collapseCategories and "Expand [+]" or "Collapse [-]"
            self:updateMenu()
        end,
        showRequirements = function(self)
            if not self.showCategories then return false end
            if self.showCollapseCategoriesButton ~= nil then
                return self.showCollapseCategoriesButton
            end
            return true
        end
    },
    {
        id = tes3ui.registerID("CraftingFramework_Button_ShowCategories"),
        name = function(self)
            return "Categories: " .. (self.showCategories and "Visible" or "Hidden")
        end,
        callback = function(self)
            self.collapseCategories = false
            self:toggleAllCategories()
            self.showCategories = not self.showCategories
            self:updateMenu()
        end,
        showRequirements = function(self)
            if self.showCategoriesButton ~= nil then
                return self.showCategoriesButton
            end
            return true
        end
    },
    {
        id = "CraftingFramework_Button_Filter",
        name = function(self)
            return "Filter: " .. filters[self.currentFilter].name
        end,
        callback = function(self)
            local nextFilter = filters[self.currentFilter].nextFilter
            log:debug("Next Filter: " .. nextFilter)
            self.currentFilter = nextFilter
            self.collapseCategories = false
            self:toggleAllCategories()
            self:updateMenu()
        end,
        showRequirements = function(self)
            if self.showFilterButton ~= nil then
                return self.showFilterButton
            end
            return true
        end
    },
    {
        id = tes3ui.registerID("CraftingFramework_Button_Sort"),
        name = function(self)
            return "Sort: " .. sorters[self.currentSorter].name
        end,
        callback = function(self)
            local nextSorter = sorters[self.currentSorter].nextSorter
            log:debug("nextSorter: %s", nextSorter)
            self.currentSorter = nextSorter
            self.collapseCategories = false
            self:toggleAllCategories()
            self:updateMenu()
        end,
        showRequirements = function(self)
            if self.showSortButton ~= nil then
                return self.showSortButton
            end
            return true
        end
    },
    {
        id = tes3ui.registerID("CraftingFramework_Button_CraftItem"),
        name = function(self) return self.craftButtonText end,
        callback = function(self, button)
            self:craftItem(button)
        end,
        requirements = function(self)
            return self.selectedRecipe and self.selectedRecipe:meetsAllRequirements()
        end
    },
}


function CraftingMenu:removeCollision(sceneNode)
    for node in Util.traverseRoots{sceneNode} do
        if node:isInstanceOfType(tes3.niType.RootCollisionNode) then
            node.appCulled = true
        end
    end
end

function CraftingMenu:toggleButtonDisabled(button, isVisible, isDisabled)
    button.visible = isVisible
    button.widget.state = isDisabled and 2 or 1
    button.disabled = isDisabled
end

---@param toolReq craftingFrameworkToolRequirement
function CraftingMenu:createToolTooltip(toolReq)
    local tool = toolReq.tool
    if not tool then return end
    if #tool.ids == 0 then return end
    local tooltip = tes3ui.createTooltipMenu()
    local outerBlock = tooltip:createBlock()
    outerBlock.flowDirection = "top_to_bottom"
    outerBlock.paddingTop = 6
    outerBlock.paddingBottom = 12
    outerBlock.paddingLeft = 6
    outerBlock.paddingRight = 6
    outerBlock.maxWidth = 300
    outerBlock.autoWidth = true
    outerBlock.autoHeight = true
    outerBlock.childAlignX = 0.5

    local header =  outerBlock:createLabel{ text = tool.name}
    header.color = tes3ui.getPalette("header_color")

    for id, _ in pairs(tool:getToolIds()) do
        log:debug("Tool Id: %s", id)
        local item = tes3.getObject(id)
        if item then
            log:debug("checking toolId: %s", id)
            local itemCount =tes3.getItemCount{ reference = tes3.player, item = item }
            local block = outerBlock:createBlock{}
            block.flowDirection = "left_to_right"
            block.autoHeight = true
            block.autoWidth = true
            block.childAlignX = 0.5

            block:createImage{path=("icons\\" .. item.icon)}
            local nameText = string.format("%s (%G)", item.name, itemCount)

            if toolReq.equipped then
                if toolReq:checkToolEquipped(item) then
                    nameText = string.format("%s (Equipped)", item.name)
                else
                    nameText = string.format("%s (Not Equipped)", item.name)
                end
            end
            if itemCount > 0 and not toolReq:checkToolCondition(item) then
                nameText = string.format("%s (Broken)", item.name)
            end
            local textLabel = block:createLabel{ text = nameText}
            textLabel.borderAllSides = 4

            if not toolReq:checkToolRequirements(id) then
                textLabel.color = tes3ui.getPalette("disabled_color")
            end
        else
            log:error("Could not find item %s", id)
        end
    end
end




---@param toolReq craftingFrameworkToolRequirement
---@param parentList table
function CraftingMenu:createToolLabel(toolReq, parentList)
    local tool = toolReq.tool
    if tool then
        local requirementText = string.format("%s x %G", tool.name, (toolReq.count or 1) )
        if toolReq.equipped then
            if toolReq:hasToolEquipped() then
                requirementText = string.format("%s (Equipped)", tool.name)
            else
                requirementText = string.format("%s (Not Equipped)", tool.name)
            end
        end
        if toolReq:hasToolCondition() == false then
            requirementText = string.format("%s (Broken)", tool.name)
        end

        local requirement = parentList:createLabel()
        requirement.borderAllSides = 2
        requirement.text = requirementText

        requirement:register("help", function()
            self:createToolTooltip(toolReq)
        end)

        if toolReq:hasTool() then
            requirement.color = tes3ui.getPalette("normal_color")
        else
            requirement.color = tes3ui.getPalette("disabled_color")
        end
    end
end

function CraftingMenu:updateToolsPane()
    local craftingMenu = tes3ui.findMenu(uiids.craftingMenu)
    if not craftingMenu then return end
    local toolRequirementsBlock = craftingMenu:findChild(uiids.toolRequirementsBlock)
    local list = craftingMenu:findChild(uiids.toolRequirementsPane)
    list:getContentElement():destroyChildren()
    if #self.selectedRecipe.toolRequirements < 1 then
        toolRequirementsBlock.visible = false
    else
        toolRequirementsBlock.visible = true
        for _, toolReq in ipairs(self.selectedRecipe.toolRequirements) do
            self:createToolLabel(toolReq, list)
        end
    end
end

---@param customRequirement craftingFrameworkCustomRequirement
function CraftingMenu:createCustomRequirementLabel(customRequirement, list)
    local requirement = list:createLabel()
    requirement.borderAllSides = 2
    requirement.text = customRequirement:getLabel()
    local meetsRequirements, reason = customRequirement:check()
    if meetsRequirements then
        requirement.color = tes3ui.getPalette("normal_color")
    else
        requirement.color = tes3ui.getPalette("disabled_color")
    end
    if reason then
        --create tooltip
        requirement:register("help", function()
            local tooltip = tes3ui.createTooltipMenu()
            tooltip:createLabel{ text = reason }
        end)
    end
end

function CraftingMenu:updateCustomRequirementsPane()
    local craftingMenu = tes3ui.findMenu(uiids.craftingMenu)
    if not craftingMenu then return end
    local customRequirementsBlock = craftingMenu:findChild(uiids.customRequirementsBlock)
    local list = craftingMenu:findChild(uiids.customRequirementsPane)
    list:getContentElement():destroyChildren()
    local customRequirements = self.selectedRecipe.customRequirements
    if #customRequirements < 1 or customRequirements.showInMenu == false then
        customRequirementsBlock.visible = false
    else
        customRequirementsBlock.visible = true
        for _, customReq in ipairs(customRequirements) do
            self:createCustomRequirementLabel(customReq, list)
        end
    end
end

---@param skillReq craftingFrameworkSkillRequirement
function CraftingMenu:createSkillTooltip(skillReq)
    local name = skillReq:getSkillName()
    local tooltip = tes3ui.createTooltipMenu()
    local outerBlock = tooltip:createBlock()
    outerBlock.flowDirection = "top_to_bottom"
    outerBlock.paddingTop = 6
    outerBlock.paddingBottom = 12
    outerBlock.paddingLeft = 6
    outerBlock.paddingRight = 6
    outerBlock.maxWidth = 300
    outerBlock.autoWidth = true
    outerBlock.autoHeight = true
    outerBlock.childAlignX = 0.5
    local header =  outerBlock:createLabel{ text = name}
    header.color = tes3ui.getPalette("header_color")

    local current = skillReq:getCurrent()
    local required = skillReq.requirement
    outerBlock:createLabel{
        text = string.format("Current: %s", current)
    }
    outerBlock:createLabel{
        text = string.format("Required: %s", required)
    }
end

---@param skillReq craftingFrameworkSkillRequirement
function CraftingMenu:createSkillLabel(skillReq, parentList)
    local current = skillReq:getCurrent()
    local skillText = string.format("%s: %s/%s",
        skillReq:getSkillName(),
        current, skillReq.
        requirement)
    local requirement = parentList:createLabel()
    requirement.borderAllSides = 2
    requirement.text = skillText
    requirement:register("help", function()
        self:createSkillTooltip(skillReq)
    end)
    if skillReq:check() then
        requirement.color = tes3ui.getPalette("normal_color")
    else
        requirement.color = tes3ui.getPalette("disabled_color")
    end
end


function CraftingMenu:updateSkillsRequirementsPane()
    local craftingMenu = tes3ui.findMenu(uiids.craftingMenu)
    if not craftingMenu then return end

    local skillRequirementsPane = craftingMenu:findChild(uiids.skillRequirementsPane)
    local skillsBlock = craftingMenu:findChild(uiids.skillRequirementsBlock)
    skillRequirementsPane:getContentElement():destroyChildren()
    if #self.selectedRecipe.skillRequirements < 1 then
        skillsBlock.visible = false
    else
        skillsBlock.visible = true
        for _, skillReq in ipairs(self.selectedRecipe.skillRequirements) do
            self:createSkillLabel(skillReq, skillRequirementsPane)
        end
    end
end

---@param material craftingFrameworkMaterial
function CraftingMenu:createMaterialTooltip(material)
    local name = material:getName()
    local tooltip = tes3ui.createTooltipMenu()
    local outerBlock = tooltip:createBlock()
    outerBlock.flowDirection = "top_to_bottom"
    outerBlock.paddingTop = 6
    outerBlock.paddingBottom = 12
    outerBlock.paddingLeft = 6
    outerBlock.paddingRight = 6
    outerBlock.maxWidth = 300
    outerBlock.autoWidth = true
    outerBlock.autoHeight = true
    outerBlock.childAlignX = 0.5
    local header =  outerBlock:createLabel{ text = name}
    header.color = tes3ui.getPalette("header_color")
    for id, _ in pairs(material.ids) do
        local item = tes3.getObject(id)
        if item then
            local itemCount = tes3.getItemCount{ reference = tes3.player, item = item }
            local block = outerBlock:createBlock{}
            block.flowDirection = "left_to_right"
            block.autoHeight = true
            block.autoWidth = true
            block.childAlignX = 0.5

            block:createImage{path=("icons\\" .. item.icon)}
            local text = string.format("%s (%G)", item.name, itemCount)
            local textLabel = block:createLabel{ text = text}
            textLabel.borderAllSides = 4

            if itemCount <= 0 then
                textLabel.color = tes3ui.getPalette("disabled_color")
            end
        end
    end
end

---@param materialReq craftingFrameworkMaterialRequirementData
function CraftingMenu:createMaterialButton(materialReq, list)
    local material = Material.getMaterial(materialReq.material)
    local materialText = string.format("%s x %G", material:getName(), materialReq.count )
    local requirement = list:createLabel()
    requirement.borderAllSides = 2
    requirement.text = materialText
    requirement:register("help", function()
        self:createMaterialTooltip(material)
    end)
    if material:checkHasIngredient(materialReq.count) then
        requirement.color = tes3ui.getPalette("normal_color")
    else
        requirement.color = tes3ui.getPalette("disabled_color")
    end
end

function CraftingMenu:updateMaterialsRequirementsPane()
    local craftingMenu = tes3ui.findMenu(uiids.craftingMenu)
    if not craftingMenu then return end
    local materialsBlock = craftingMenu:findChild(uiids.materialRequirementsBlock)
    local list = craftingMenu:findChild(uiids.materialRequirementsPane)
    list:getContentElement():destroyChildren()

    if #self.selectedRecipe.materials < 1 then
        materialsBlock.visible = false
    else
        materialsBlock.visible = true
        for _, materialReq in ipairs(self.selectedRecipe.materials) do
            local material = Material.getMaterial(materialReq.material)
            if material:hasValidIngredient() then
                self:createMaterialButton(materialReq, list)
            end
        end
    end
end

function CraftingMenu:updateDescriptionPane()
    local craftingMenu = tes3ui.findMenu(uiids.craftingMenu)
    if not craftingMenu then return end

    local descriptionBlock = craftingMenu:findChild(uiids.descriptionBlock)
    if not descriptionBlock then return end
    descriptionBlock:destroyChildren()

    local selectedItemLabel = descriptionBlock:createLabel{ id = uiids.selectedItem }
    selectedItemLabel.autoWidth = true
    selectedItemLabel.autoHeight = true
    selectedItemLabel.color = tes3ui.getPalette("header_color")
    selectedItemLabel.text = self.selectedRecipe.craftable:getNameWithCount()

    --If no requirements, make description block extend to bottom
    local hasCustomReqs = self.selectedRecipe.customRequirements and #self.selectedRecipe.customRequirements > 0
    local hasToolReqs = self.selectedRecipe.toolRequirements and #self.selectedRecipe.toolRequirements > 0
    local hasMaterialReqs = self.selectedRecipe.materials and #self.selectedRecipe.materials > 0
    if (hasCustomReqs or hasToolReqs or hasMaterialReqs) then
        descriptionBlock.heightProportional = nil
    else
        descriptionBlock.heightProportional = 1
    end

    local obj = tes3.getObject(self.selectedRecipe.craftable.id)

    local previewDescription = descriptionBlock:createLabel{ id = uiids.previewDescription }
    previewDescription.wrapText = true
    previewDescription.text = self.selectedRecipe.description or ""

    if obj and obj.name and obj.name ~= "" then
        selectedItemLabel:register("help", function()
            tes3ui.createTooltipMenu{ item = self.selectedRecipe.craftable.id }
        end)
        previewDescription:register("help", function()
            tes3ui.createTooltipMenu{ item = self.selectedRecipe.craftable.id }
        end)
    end
end


---@param recipe craftingFrameworkRecipe
---@return craftingFrameworkRotationAxis
local function getRotationAxis(recipe, isSheathMesh)
    local item = recipe:getItem()---@type tes3object|tes3clothing

    local rotationObjectTypes = {
        [tes3.objectType.weapon] = 'y',
        [tes3.objectType.ammunition] = 'y',
        [tes3.objectType.lockpick] = 'y',
        [tes3.objectType.probe] = 'y',
    }
    local clothingSlots = {
        [tes3.clothingSlot.amulet] = 'y'
    }
    local armorSlots = {
       -- [tes3.armorSlot.cuirass] = 'y',
    }
    if item.objectType == tes3.objectType.weapon and isSheathMesh then
        return '-y'
    elseif recipe.craftable.rotationAxis then
        return recipe.craftable.rotationAxis
    elseif rotationObjectTypes[item.objectType] then
        return rotationObjectTypes[item.objectType]
    elseif item.objectType == tes3.objectType.clothing and clothingSlots[item.slot] then
        return clothingSlots[item.slot]
    elseif item.objectType == tes3.objectType.armor and armorSlots[item.slot] then
        return armorSlots[item.slot]
    else
        return 'z'
    end
end

local rotationAxis = 'z'
function CraftingMenu:updatePreviewPane()
    local craftingMenu = tes3ui.findMenu(uiids.craftingMenu)
    if not craftingMenu then return end
    if not self.selectedRecipe then return end
    local item = self.selectedRecipe:getItem()
    if item then
        log:debug("preview pane item: %s", item.id)
        --nifPreviewBLock
        local nifPreviewBlock = craftingMenu:findChild(uiids.nifPreviewBlock)
        if nifPreviewBlock then
            nifPreviewBlock:destroyChildren()

            --[[
                Morrowind UI has a weird bug where if a mesh does not have two parent
                    niNodes above the trishape, it will be rendered incorrectly.

                To get around this, we create the UI Nif with an empty niNode, then
                    attach the object's mesh as a child of that.
            ]]
            local nif = nifPreviewBlock:createNif{ id = uiids.nif, path = "craftingFramework\\empty.nif"}
            local mesh = self.selectedRecipe.craftable.previewMesh or item.mesh

            local isSheathMesh = false
            --Get sheath mesh if item is a weapon
            if item.objectType == tes3.objectType.weapon then
                local sheathMesh = mesh:sub(1, -5) .. "_sh.nif"
                if tes3.getFileExists("meshes\\" .. sheathMesh) then
                    mesh = sheathMesh
                    isSheathMesh = true
                end
            end

            --Avoid popups/CTDs if the mesh is missing.
            if not tes3.getFileExists(string.format("Meshes\\%s", mesh)) then
                log:error("Mesh does not exist: %s", mesh)
                return
            end
            log:debug("Loading mesh: %s", mesh)
            local childNif = tes3.loadMesh(mesh, false)
            log:debug("Mesh loaded: %s", childNif)
            if not nif then return end
            if not childNif then return end
            --Update the layout so the sceneNode becomes available
            craftingMenu:updateLayout()
            local node = nif.sceneNode ---@type any
            --Attach the object's mesh to the empty niNode
            node:attachChild(childNif)

            --Remove parts of the mesh that fuck with bounding box calculations
            Util.removeLight(node)
            self:removeCollision(node)
            node:update()

            --get size from bounding box. This still sucks for autogenerated bounding boxes
            local maxDimension
            local bb = node:createBoundingBox(node.scale)
            local height = bb.max.z - bb.min.z
            local width = bb.max.y - bb.min.y
            local depth = bb.max.x - bb.min.x
            maxDimension = math.max(width, depth, height)

            local targetHeight = 160
            node.scale = targetHeight / maxDimension
            if self.selectedRecipe.craftable.previewScale then
                node.scale = node.scale * self.selectedRecipe.craftable.previewScale
            end
            do --add properties
                ---@diagnostic disable-next-line: undefined-field
                local vertexColorProperty = niVertexColorProperty.new()
                vertexColorProperty.name = "vcol yo"
                vertexColorProperty.source = 2
                node:attachProperty(vertexColorProperty)

                ---@diagnostic disable-next-line: undefined-global
                local zBufferProperty = niZBufferProperty.new()
                zBufferProperty.name = "zbuf yo"
                zBufferProperty:setFlag(true, 0)
                zBufferProperty:setFlag(true, 1)
                node:attachProperty(zBufferProperty)
            end

            do --Apply rotation
                rotationAxis = getRotationAxis(self.selectedRecipe, isSheathMesh)
                local offset = -20
                if rotationAxis == 'x' then
                    m1:toRotationZ(math.rad(-15))
                    local lowestPoint = bb.min.x * node.scale
                    offset = offset - lowestPoint
                    m2:toRotationY(math.rad(90))
                elseif rotationAxis == 'y' then
                    m1:toRotationZ(math.rad(-15))
                    local lowestPoint = bb.min.y * node.scale
                    offset = offset - lowestPoint
                    m2:toRotationX(math.rad(270))
                elseif rotationAxis == 'z' then
                    m1:toRotationX(math.rad(-15))
                    local lowestPoint = bb.min.z * node.scale
                    offset = offset - lowestPoint
                    m2:toRotationZ(math.rad(180))
                --Vertically flipped
                elseif rotationAxis == '-x' then
                    m1:toRotationZ(math.rad(15))
                    local lowestPoint = bb.max.x * node.scale
                    offset = offset + lowestPoint
                    m2:toRotationY(math.rad(-90))
                elseif rotationAxis == '-y' then
                    m1:toRotationZ(math.rad(15))
                    local lowestPoint = bb.max.y * node.scale
                    offset = offset + lowestPoint
                    m2:toRotationX(math.rad(90))
                elseif rotationAxis == '-z' then
                    m1:toRotationX(math.rad(15))
                    local lowestPoint = bb.max.z * node.scale
                    offset = offset + lowestPoint
                    m2:toRotationY(math.rad(180))
                end
                node.translation.z = node.translation.z + offset + self.selectedRecipe.craftable.previewHeight
                node.rotation = node.rotation * m1:copy() * m2:copy()
            end
            node.appCulled = false
            node:updateProperties()
            node:update()
            nifPreviewBlock:updateLayout()
        end
    end
    --updateBuyButtons()
end
function CraftingMenu:updateButtons()
    local craftingMenu = tes3ui.findMenu(uiids.craftingMenu)
    if not craftingMenu then return end
    for _, buttonConf in ipairs(menuButtons) do
        local button = craftingMenu:findChild(buttonConf.id)
        if button then
            button.text = buttonConf.name(self)
            if buttonConf.requirements and buttonConf.requirements(self)== false then
                self:toggleButtonDisabled(button, true, true)
            else
                self:toggleButtonDisabled(button, true, false)
                button:register("mouseClick", function()
                    buttonConf.callback(self, button)
                end)
            end
            --help event doesn't override so we set it once and do logic inside
            button:register("help", function()
                local tooltip = tes3ui.createTooltipMenu()
                if buttonConf.requirements then
                    local meetsRequirements, reason = buttonConf.requirements(self)
                    if reason and not meetsRequirements then
                        tooltip:createLabel{ text = reason }
                    end
                end
            end)
            if buttonConf.showRequirements then
                button.visible = buttonConf.showRequirements(self)
            end
        end
    end
end

function CraftingMenu:updateSidebar()
    if not self.selectedRecipe then return end
    self:updatePreviewPane()
    self:updateDescriptionPane()
    self:updateCustomRequirementsPane()
    self:updateSkillsRequirementsPane()
    self:updateMaterialsRequirementsPane()
    self:updateToolsPane()
end

function CraftingMenu:updateMenu()
    self:populateRecipeList()
    self:updateSidebar()
    self:updateButtons()
end

---@param recipe craftingFrameworkRecipe
function CraftingMenu:recipeMatchesSearch(recipe)
    if (not self.searchText) or self.searchText == "" then return true end
    return string.find(recipe.craftable:getName():lower(), self.searchText:lower())
end

---@param recipes craftingFrameworkRecipe[]
function CraftingMenu:populateCategoryList(recipes, parent)
    table.sort(recipes, sorters[self.currentSorter].sorter)
    for _, recipe in ipairs(recipes) do
        if recipe:isKnown() then
            if not self.selectedRecipe then self.selectedRecipe = recipe end
            local showRecipe = self:recipeMatchesSearch(recipe)
                and filters[self.currentFilter].filter(recipe)

            if showRecipe then
                local button = parent:createTextSelect({ id = string.format("Button_%s", recipe.id)})
                local buttonCallback = function()
                    self.selectedRecipe = recipe
                    self:updateSidebar()
                    self:updateButtons()
                end
                button:register("mouseClick", buttonCallback)
                button.borderAllSides = 2
                button.text = "- " .. recipe.craftable:getName()
                local canCraft = recipe:meetsAllRequirements()
                if not canCraft then
                    button.color = tes3ui.getPalette("disabled_color")
                    button.widget.idle = tes3ui.getPalette("disabled_color")
                end
            end
        end
    end
    if parent.widget and parent.widget.contentsChanged then
        parent:updateLayout()
        parent.widget:contentsChanged()
    end
end

function CraftingMenu:createCategoryBlock(category, scrollbar)
    local block = scrollbar:createBlock{}
    block.flowDirection = "top_to_bottom"
    block.autoHeight = true
    block.widthProportional = 1.0
    block.paddingAllSides = 2
    local headerText = string.format("[-] %s", category.name)
    local header = block:createTextSelect{ text = headerText}---@type tes3uiElement
    header.widget.idle = tes3ui.getPalette(tes3.palette.headerColor)
    header.widget.idleActive = tes3ui.getPalette(tes3.palette.headerColor)
    header.color = tes3ui.getPalette(tes3.palette.headerColor)
    header.borderAllSides = 2
    local recipeBlock = self:createRecipeBlock(block)
    self:populateCategoryList(category.recipes, recipeBlock)
    local function setCategoryVisible()
        if category.visible then
            recipeBlock.visible = true
            header.text = string.format("[-] %s", category.name)
        else
            recipeBlock.visible = false
            header.text = string.format("[+] %s", category.name)
        end
        if #recipeBlock.children == 0 then
            header.widget.idle = tes3ui.getPalette("disabled_color")
        else
            header.widget.idle = tes3ui.getPalette("normal_color")
        end
    end
    header:register("mouseClick", function()
        category.visible = not category.visible
        setCategoryVisible()
    end)
    setCategoryVisible()
end


function CraftingMenu:updateCategoriesList()
    for _, category in pairs(self.categories) do
        log:debug("Clearing recipes for %s", category.name)
        category.recipes = {}
    end
    ---@param recipe craftingFrameworkRecipe
    for _, recipe in pairs(self.recipes) do
        local category = recipe.category
        if not self.categories[category] then
            log:debug("Category %s doesn't exist yet", category)
            self.categories[category] = {
                name = category,
                recipes = {},
                visible = not self.collapseCategories,
            }
        end
        table.insert(self.categories[recipe.category].recipes, recipe)
    end
    return self.categories
end


function CraftingMenu:populateRecipeList()
    local craftingMenu = tes3ui.findMenu(uiids.craftingMenu)
    if not craftingMenu then return end
    local parent = craftingMenu:findChild(uiids.recipeListBlock)
    parent:destroyChildren()
    local title = parent:createLabel()
    title.color = tes3ui.getPalette("header_color")
    title.text = self.recipeHeaderText .. ":"
    self:createSearchBar(parent)
    local scrollBar = parent:createVerticalScrollPane()
    scrollBar.heightProportional = 1.0
    scrollBar.widthProportional = 1.0
    scrollBar.borderTop = 4
    self:updateCategoriesList()
    local sortedList = {}
    for _, category in pairs(self.categories) do
        table.insert(sortedList, category)
    end
    table.sort(sortedList, function(a, b)
        return a.name:lower() < b.name:lower()
    end)
    if #sortedList > 1 and self.showCategories then
        for _, category in pairs(sortedList) do
            self:createCategoryBlock(category, scrollBar)
        end
    else
        self:populateCategoryList(self.recipes, scrollBar)
    end
end


local function rotateNif(e)
    local menu = tes3ui.findMenu(uiids.craftingMenu)
    if not menu then
        event.unregister("enterFrame", rotateNif)
        return
    end
    local nif = menu:findChild(uiids.nif)
    if nif and nif.sceneNode then
        local node = nif.sceneNode
        if rotationAxis == 'x' or rotationAxis == '-x' then
            m2:toRotationX(math.rad(15) * e.delta)
        elseif rotationAxis == 'y' or rotationAxis == '-y' then
            m2:toRotationY(math.rad(15) * e.delta)
        elseif rotationAxis == 'z' or rotationAxis == '-z' then
            m2:toRotationZ(math.rad(15) * e.delta)
        end

        node.rotation = node.rotation * m2
        node:update()
    end
end

function CraftingMenu:resourceSorter(a, b)
	return a.name:lower() < b.name:lower()
end


function CraftingMenu:createSearchBar(parent)
	local searchBlock = parent:createBlock()
	searchBlock.flowDirection = "left_to_right"
	searchBlock.autoHeight = true
	searchBlock.widthProportional = 1.0
    local searchBar = searchBlock:createThinBorder{ id = uiids.searchBar}
    searchBar.flowDirection = "top_to_bottom"
    searchBar.widthProportional= 1
    searchBar.autoHeight = true
    -- Create the search input itself.
    local placeholderText = "Search..."
	local input = searchBar:createTextInput({ id = tes3ui.registerID("ExclusionsSearchInput") })
	input.color = self.searchText and tes3ui.getPalette("normal_color") or tes3ui.getPalette("disabled_color")
	input.text = self.searchText or placeholderText
	input.borderLeft = 5
	input.borderRight = 5
	input.borderTop = 2
	input.borderBottom = 4
	input.widget.eraseOnFirstKey = true
	input.consumeMouseEvents = false
    -- Set up the events to control text input control.
	input:register("keyPress", function(e)
		local inputController = tes3.worldController.inputController
		local pressedTab = (inputController:isKeyDown(tes3.scanCode.tab))
		local backspacedNothing = ((inputController:isKeyDown(tes3.scanCode.delete) or
		                    inputController:isKeyDown(tes3.scanCode.backspace)) and input.text == placeholderText)

		if pressedTab then
			-- Prevent alt-tabbing from creating spacing.
			return
		elseif backspacedNothing then
			-- Prevent backspacing into nothing.
			return
		end

		input:forwardEvent(e)

		input.color = tes3ui.getPalette("normal_color")
        self.searchText = input.text

		input:updateLayout()
		if input.text == "" then
			input.text = placeholderText
			input.color = tes3ui.getPalette("disabled_color")
		end
	end)
    input:register("keyEnter", function(e)
        self:populateRecipeList()
    end)

    -- Add button to exclude all currently filtered items
	local searchButton = searchBlock:createButton({ text = "Search" })
	searchButton.heightProportional = 1.0
	-- searchButton.alignY = 0.0
	searchButton.borderAllSides = 0
	searchButton.paddingAllSides = 2
	searchButton:register("mouseClick", function()
		self:populateRecipeList()
	end)

    searchBar:register("mouseClick", function()
		tes3ui.acquireTextInput(input)
	end)
    tes3ui.acquireTextInput(input)
end

function CraftingMenu:createPreviewPane(parent)
    local previewBorder = parent:createThinBorder{ id = uiids.previewBorder }
    --previewBorder.width = self.previewWidth
    previewBorder.flowDirection = "top_to_bottom"
    previewBorder.widthProportional= 1
    previewBorder.autoHeight = true
    previewBorder.childAlignX = 0.5
    --previewBorder.absolutePosAlignX = 0

    local nifPreviewBlock = previewBorder:createBlock{ id = uiids.nifPreviewBlock }
    --nifPreviewBlock.width = self.previewWidth
    nifPreviewBlock.width = self.previewWidth
    nifPreviewBlock.height = self.previewHeight

    nifPreviewBlock.childOffsetX = self.previewWidth/2
    nifPreviewBlock.childOffsetY = self.previewYOffset
    nifPreviewBlock.paddingAllSides = 2
end

function CraftingMenu:createLeftToRightBlock(parent)
    local block = parent:createBlock()
    block.widthProportional = 1.0
    block.heightProportional = 1.0
    block.flowDirection = "left_to_right"
    return block
end

function CraftingMenu:createTopToBottomBlock(parent)
    local block = parent:createBlock()
    block.widthProportional = 1.0
    block.heightProportional = 1.0
    block.flowDirection = "top_to_bottom"
    return block
end

function CraftingMenu:createTitle(block)
    local title = block:createLabel{ }
    title.text = self.name
    title.color = tes3ui.getPalette("header_color")
    return title
end

function CraftingMenu:createTitleBlock(parent)
    local titleBlock = parent:createBlock{ id = uiids.titleBlock }
    titleBlock.flowDirection = "top_to_bottom"
    titleBlock.childAlignX = 0.5
    titleBlock.autoHeight = true
    titleBlock.widthProportional = 1.0
    titleBlock.borderBottom = 10
    self:createTitle(titleBlock)
    return titleBlock
end

function CraftingMenu:createRecipeBlock(parent)
    local recipeListBlock = parent:findChild(uiids.recipeListBlock)
    if recipeListBlock then recipeListBlock:destroy() end
    recipeListBlock = parent:createBlock({ id = uiids.recipeListBlock})
    recipeListBlock.borderAllSides = 2
    recipeListBlock.widthProportional = 1.0
    recipeListBlock.autoHeight = true
    recipeListBlock.flowDirection = "top_to_bottom"
    return recipeListBlock
end

function CraftingMenu:createLeftBlock(parent)
    local block = parent:createBlock()
    block.widthProportional = 1.0
    block.heightProportional = 1.0
    block.flowDirection = "top_to_bottom"
    return block
end

function CraftingMenu:createRecipeList(parent)
    local block = parent:createThinBorder{ id = uiids.recipeListBlock}
    block.flowDirection = "top_to_bottom"
    block.paddingAllSides = 10
    block.widthProportional = 1.0
    block.heightProportional = 1.0
    return block
end

function CraftingMenu:createDescriptionPane(parent)
    local descriptionBlock = parent:createThinBorder{ id = uiids.descriptionBlock}
    descriptionBlock.flowDirection = "top_to_bottom"
    descriptionBlock.paddingAllSides = 10
    descriptionBlock.widthProportional = 1.0
    descriptionBlock.autoHeight = true
end

function CraftingMenu:createRequirementsPane(parent, name, blockId, paneId)
    local block = parent:createThinBorder{ id = blockId }
    block.flowDirection = "top_to_bottom"
    block.paddingAllSides = 10
    block.widthProportional = 1.0
    block.autoHeight = true

    local title = block:createLabel()
    title.color = tes3ui.getPalette("header_color")
    title.text = name

    local requirementsPane = block:createBlock({ id = paneId})
    requirementsPane.borderTop = 4
    requirementsPane.widthProportional = 1.0
    requirementsPane.autoHeight = true
end

function CraftingMenu:createCustomRequirementsPane(parent)
    self:createRequirementsPane(
        parent,
        "Requirements:",
        uiids.customRequirementsBlock,
        uiids.customRequirementsPane
    )
end

function CraftingMenu:createSkillRequirementsPane(parent)
    self:createRequirementsPane(
        parent,
        "Skills:",
        uiids.skillRequirementsBlock,
        uiids.skillRequirementsPane
    )
end

function CraftingMenu:createToolsPane(parent)
    self:createRequirementsPane(
        parent,
        "Tools:",
        uiids.toolRequirementsBlock,
        uiids.toolRequirementsPane
    )
end

function CraftingMenu:createMaterialRequirementsPane(parent)
    local block = parent:createThinBorder{ id = uiids.materialRequirementsBlock }
    block.flowDirection = "top_to_bottom"
    block.paddingAllSides = 10
    block.widthProportional = 1.0
    block.heightProportional = 1.0

    local title = block:createLabel()
    title.color = tes3ui.getPalette("header_color")
    title.text = "Materials:"

    local skillRequirementsPane = block:createVerticalScrollPane({ id = uiids.materialRequirementsPane})
    skillRequirementsPane.borderTop = 4
    skillRequirementsPane.widthProportional = 1.0
    skillRequirementsPane.heightProportional = 1.0
end

function CraftingMenu:createMenuButtonBlock(parent)
    local buttonsBlock = parent:createBlock{ id = uiids.buttonsBlock}
    buttonsBlock.autoHeight = true
    buttonsBlock.widthProportional = 1.0
    buttonsBlock.childAlignX = 1.0
    --buttonsBlock.absolutePosAlignX = 1
    --buttonsBlock.absolutePosAlignY = 1.0
    return buttonsBlock
end

function CraftingMenu:addMenuButtons(parent)
    for _, buttonConf in ipairs(menuButtons) do
        --if (not buttonConf.showRequirements) or buttonConf.showRequirements(self) then
            local button = parent:createButton({ id = buttonConf.id})
            button.minWidth = 0
            button.text = buttonConf.name(self)
            button.borderLeft = 0
        --end
    end
end

function CraftingMenu:openMenu()
    tes3.playSound{sound="Menu Click", reference=tes3.player}
    self.menu = tes3ui.findMenu(uiids.craftingMenu)
    if self.menu then self.menu:destroy() end
    self.menu = tes3ui.createMenu{ id = uiids.craftingMenu, fixedFrame = true }
    self.menu.minWidth = self.menuWidth
    self.menu.minHeight = self.menuHeight
    self:createTitleBlock(self.menu)
    --Left to Right block. Recipe list on the left, results on the right
    local outerBlock = self:createLeftToRightBlock(self.menu)
    -- --recipes on the left
    -- local recipesBlock = self:createLeftBlock(outerBlock)
    local recipesList = self:createRecipeList(outerBlock)
    recipesList.widthProportional = 0.9
    --Results on the right, consisting of a preview pane, description, and requirements list
    local resultsBlock = self:createTopToBottomBlock(outerBlock)
    resultsBlock.widthProportional = 1.1
    self:createPreviewPane(resultsBlock)
    self:createDescriptionPane(resultsBlock)
    self:createCustomRequirementsPane(resultsBlock)
    self:createToolsPane(resultsBlock)
    self:createSkillRequirementsPane(resultsBlock)
    self:createMaterialRequirementsPane(resultsBlock)
    --Craft and Cancel buttons on the bottom
    local menuButtonBlock = self:createMenuButtonBlock(self.menu)
    self:addMenuButtons(menuButtonBlock)
    self:updateMenu()
    self:updateButtons()
    local closeButton = menuButtonBlock:createButton({ id = uiids.cancelButton})
    closeButton.text = "Cancel"
    closeButton.borderLeft = 0
    closeButton:register("mouseClick", function() self:closeMenu() end)
    self.menu:updateLayout()
    tes3ui.enterMenuMode(uiids.craftingMenu)
    event.unregister("enterFrame", rotateNif)
    event.register("enterFrame", rotateNif)
end

local RightClickMenuExit = include("mer.RightClickMenuExit")
if RightClickMenuExit and RightClickMenuExit.registerMenu then
    log:debug("Registering Crafting Menu Exit button")
    RightClickMenuExit.registerMenu{
        menuId = uiids.craftingMenu,
        buttonId = uiids.cancelButton
    }
end

return CraftingMenu