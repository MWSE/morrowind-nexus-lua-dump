---@meta

-- Dedicated LuaLS stub for require("openmw.interfaces").MWUI.
-- Source: files/data/scripts/omw/mwui/init.lua
-- Runtime availability depends on script context, OpenMW version, and active content files.

-- OpenMW script contexts: menu|player

---@class openmw.interfaces.MWUI
---@field templates openmw.interfaces.MWUI.Templates
---@field version number
local MWUI = {}

---local I = require('openmw.interfaces')
---local ui = require('openmw.ui')
---local auxUi = require('openmw_aux.ui')
---ui.create {
---}
----- important to copy here
---local myText = auxUi.deepLayoutCopy(I.MWUI.templates.textNormal)
---myText.props.textSize = 20
---I.MWUI.templates.textNormal = myText
---ui.updateAll()
---@class openmw.interfaces.MWUI.Templates
---@field padding openmw.ui.Template
---@field interval openmw.ui.Template
---@field borders openmw.ui.Template
---@field box openmw.ui.Template
---@field boxTransparent openmw.ui.Template
---@field boxSolid openmw.ui.Template
---@field verticalLine openmw.ui.Template
---@field horizontalLine openmw.ui.Template
---@field bordersThick openmw.ui.Template
---@field boxThick openmw.ui.Template
---@field boxTransparentThick openmw.ui.Template
---@field boxSolidThick openmw.ui.Template
---@field verticalLineThick openmw.ui.Template
---@field horizontalLineThick openmw.ui.Template
---@field textNormal openmw.ui.Template
---@field textHeader openmw.ui.Template
---@field textParagraph openmw.ui.Template
---@field textEditLine openmw.ui.Template
---@field textEditBox openmw.ui.Template
---@field disabled openmw.ui.Template
local Templates = {}

---@type openmw.interfaces.MWUI.Templates
MWUI.templates = nil

---Interface version
---@type number
MWUI.version = nil

return MWUI
