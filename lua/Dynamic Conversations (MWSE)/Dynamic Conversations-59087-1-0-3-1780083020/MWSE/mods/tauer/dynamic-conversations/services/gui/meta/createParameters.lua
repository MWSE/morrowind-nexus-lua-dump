---@meta
---@class createParameters Parameters for creating GUI elements
---@field public id string|number? The ID of the GUI element
---@field public parent tes3uiElement The parent element to create the GUI element under

---@class createMenuParameters Parameters for creating a new menu GUI element
---@field public id string | number? The ID of the menu
---@field public dragFrame boolean Whether the menu has a draggable frame
---@field public fixedFrame boolean Whether the menu has a fixed frame
---@field public modal boolean Whether the menu is modal

---@meta
---@class createImageButtonParameters : createParameters Parameters for creating a button GUI element
---@field public idle string
---@field public over string
---@field public pressed string
---@field scaleMode boolean?
