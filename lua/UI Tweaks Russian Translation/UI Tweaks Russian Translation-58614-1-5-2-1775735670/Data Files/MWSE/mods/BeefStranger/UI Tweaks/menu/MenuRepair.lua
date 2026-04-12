local cfg = require("BeefStranger.UI Tweaks.config")
local bs = require("BeefStranger.UI Tweaks.common")
local id = require("BeefStranger.UI Tweaks.ID")

---@class bsMenuRepair_This
local this = {}

---@class bsMenuRepair
local Repair = {}
function Repair:get() return tes3ui.findMenu(id.Repair) end---Get Top Level Menu
function Repair:child(child) return self:get() and self:get():findChild(child) or nil end ---@param child string|number
function Repair:Close() return self:child("MenuRepair_Okbutton") end---The Close Button
function Repair:Items() return self:child("PartScrollPane_pane") end---The Direct Parent of Items to Repair
---The List of Items to Repair: Returns ContentElement
function Repair:ServiceList() return self:child("MenuRepair_ServiceList"):getContentElement() end
---The Title Block Containing: Icon: Uses: Quality
function Repair:TitleBlock() return self:child("title layout") end
---The Repair Hammer Block
function Repair:ObjectBlock() return self:child("MenuRepair_object_layout") end
---The Icon of the Repair Hammer/Tongs
function Repair:RepairIcon() return self:child("repairimage") end
---The Remaining Uses
function Repair:RepairUses() return self:child("MenuRepair_uses") end
---The Quality of the Hammer/Tongs
function Repair:RepairQuality() return self:child("MenuRepair_quality") end
---The Block Containing the Close button
function Repair:ButtonBlock() return self:child("MenuRepair_Okbutton").parent end
---MenuRepair has updates disabled, this enables it, though only for 1 update.
function Repair:enableUpdates() self:get():setPropertyBool("update_disable", true) end

---Enables updates then updates
function Repair:update()
    self:enableUpdates()
    self:get():updateLayout()
end

function Repair:object() return self:get():bs_getObj() end
function Repair:itemData() return self:get():bs_getItemData() end

--- @param e uiActivatedEventData
function this.ToolSelect(e)
    local objectBlock = Repair:ObjectBlock()
    objectBlock:bs_autoSize(true)
    objectBlock.borderAllSides = 0
    Repair:ObjectBlock():registerBefore(tes3.uiEvent.destroy, this.onLastTool)

    local select = objectBlock:createImage({ id = "Select", path = bs.textures.menu_icon_equip })
    select.height = 50
    select.width = 50

    ---Move repairicon to select img before editing
    Repair:RepairIcon():move { to = select }
    local icon = Repair:RepairIcon()
    icon.borderAllSides = 6

    Repair:update()

    objectBlock:register(tes3.uiEvent.help, this.tooltip)
    objectBlock:register(tes3.uiEvent.mouseClick, this.showToolSelect)
end


---@param e uiActivatedEventData
local function RepairActivated(e)
    if not cfg.repair.enable then return end
    this.renameChildren()

    if cfg.repair.select then
        this.ToolSelect(e)
    end

    if cfg.repair.hold then
        for _, item in ipairs(Repair:ServiceList().children) do
            item:findChild("Icon"):bs_holdClick({
                triggerClick = true,
                startInterval = 0.80,
                minInterval = cfg.repair.interval,
                skipFirstClick = true,
                acceleration = 0.1
            })
        end
    end
end
event.register(tes3.event.uiActivated, RepairActivated, {filter = id.Repair})

function this.showToolSelect()
    tes3ui.showInventorySelectMenu({
        title = "Инструменты для ремонта",
        filter = function (s)
            local repairItem = s.item.objectType == tes3.objectType.repairItem
            local notSelected = not (s.itemData == Repair:itemData() and s.item == Repair:object())
            if repairItem and notSelected then
                return true
            else
                return false
            end
        end,
        callback = function (s)
            if s.item then
                Repair:get():bs_setObj({object = s.item})
                if not s.itemData then
                    local itemData = tes3.addItemData({ item = s.item, to = tes3.mobilePlayer })
                    s.itemData = itemData
                end
                Repair:get():bs_setItemData({ data = s.itemData })
                Repair:RepairIcon().contentPath = "Icons\\" .. s.item.icon
                Repair:RepairUses().text = "Зарядов " .. s.itemData.condition
                Repair:RepairQuality().text = ("Качество %.2f"):format(s.item.quality)

                Repair:update()
            end
        end
    })
end

function this.onLastTool()
    if Repair:child("MenuRepair_object_layout") then
        local objectCopy = Repair:ObjectBlock():copy{to = Repair:TitleBlock(), copyChildren = true, copyProperties = false}
        local titleCopy = Repair:TitleBlock().children[2]:copy{to = Repair:TitleBlock(), copyChildren = true}

        objectCopy:findChild("repairimage").contentPath = bs.textures.menu_icon_none
        objectCopy.children[1]:register(tes3.uiEvent.mouseClick, this.showToolSelect)
        objectCopy.children[1]:register(tes3.uiEvent.help, this.tooltip)
        objectCopy:registerBefore(tes3.uiEvent.destroy, this.onLastTool)

        titleCopy:findChild("MenuRepair_uses").text = "Выберите предмет для ремонта..."
        titleCopy:findChild("MenuRepair_quality").text = ""
    end
end

function this.tooltip()
    if Repair:object() and Repair:itemData() then
        tes3ui.createTooltipMenu({item = Repair:object(), itemData = Repair:itemData()})
    end
end

function this.renameChildren()
    for index, item in ipairs(Repair:ServiceList().children) do
        item:setPropertyProperty("name", "Item_"..index)
        item.children[1]:setPropertyProperty("name", "Item_Label")
        item.children[2]:setPropertyProperty("name", "IconBlock")
        item.children[2].children[1]:setPropertyProperty("name", "Icon")
        item.children[2].children[2]:setPropertyProperty("name", "Fillbar")
    end
end


return Repair