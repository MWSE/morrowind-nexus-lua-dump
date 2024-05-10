local Class = require("seph.class")

--- @class Mcm : Class
--- @field mod Mod The mod this MCM belongs to. This should not be changed manually.
--- @field logger MWSELogger The logger of this MCM. This will automatically be generated during initialization. This should not be changed manually.
--- @field headerImagePath string The path of the texture to be used as a header image. This is relative to the Morrowind 'Data Files' directory.
--- @field showInfoPage boolean Indicates if a generic info page should be created. This should be assigned before the create function gets called.
--- @field showEnabledButton boolean Indicates if the enabled button should be created. This should be assigned before the create function gets called.
--- @field showResetButton boolean Indicates if the reset button should be created. This should be assigned before the create function gets called.
--- @field showLogLevelDropdown boolean Indicates if the log level dropdown should be created. This should be assigned before the create function gets called.
--- @field enableRequiresRestart boolean Indicates if the user should be notified to restart the game when clicking the enabled button. This should be assigned before the create function gets called.
--- @field saveOnClose boolean Indicates if the current config should be saved after closing the MCM. This should be assigned before the create function gets called.
--- @field reenableOnClose boolean Indicates if the mod should be disabled and enabled after closing the MCM. Only applies if the mod was already enabled. This should be assigned before the create function gets called.
--- @field template table The MCM template. This will automatically be generated during creation. This should not be changed manually.
--- @field infoPage table The info page of this mod. Contains generic information and settings for the mod. This will automatically be generated during creation if 'showInfoPage' is true. This should not be changed manually.
--- @field onCreate fun(mcm: Mcm) Callback. Gets called during the MWSE 'modConfigReady' event.
--- @field onOpen fun(mcm: Mcm) Callback. Gets called every time the MCM of this mod is being opened.
--- @field onClose fun(mcm: Mcm) Callback. Gets called every time the MCM of this mod is being closed, just before the config is saved.
--- @field onEnabledButtonClicked fun(mcm: Mcm) Callback. Gets called every time the enabled button is clicked.
--- @field onResetButtonClicked fun(mcm: Mcm) Callback. Gets called every time the reset button is clicked.
local Mcm = Class("seph.Mcm")

function Mcm:initialize()
    self.mod = nil
    self.logger = nil
    self.headerImagePath = ""
    self.showInfoPage = true
    self.showEnabledButton = true
    self.showResetButton = true
    self.showLogLevelDropdown = true
    self.enableRequiresRestart = false
    self.saveOnClose = true
    self.reenableOnClose = false
    self.template = nil
    self.infoPage = nil
    self.onCreate = nil
    self.onOpen = nil
    self.onClose = nil
    self.onEnabledButtonClicked = nil
    self.onResetButtonClicked = nil
end

--- Creates a info page with generic information and settings for this mod.
function Mcm:createInfoPage()
    self.infoPage = self.template:createPage{label = "Информация"}

    local title = self.infoPage:createCategory{
        label = string.format("%s %s", self.mod.name, self.mod.version:toString()),
        postCreate =
            function(component)
                component.elements.outerContainer.borderTop = 16
                component.elements.label.justifyText = "center"
            end
    }
    if self.mod.author ~= "" then
        title.label = string.format("%s, от %s", title.label, self.mod.author)
    end

    if self.mod.hyperlink ~= "" then
        self.infoPage:createHyperLink{
            text = self.mod.hyperlink,
            exec = string.format("start %s", self.mod.hyperlink),
            postCreate =
                function(component)
                    component.elements.info.justifyText = "center"
                end
        }
    end

    self.infoPage:createInfo{
        text = "",
        postCreate =
            function(component)
                component.elements.info.maxHeight = 0
                local divider = component.elements.outerContainer:createDivider()
                divider.borderAllSides = 16
            end
    }

    self.infoPage:createInfo{
        text = self.mod.description,
        postCreate =
            function(component)
                component.elements.info.justifyText = "center"
            end
    }

    local function getEnabledButtonText()
        if self.mod.config.current.enabled then
            return "Включено"
        else
            return "Выключено"
        end
    end

    if self.showEnabledButton then
        local enabledButton = self.infoPage:createButton{
            buttonText = getEnabledButtonText(),
            postCreate =
                function(component)
                    component.elements.outerContainer.borderTop = 32
                    component.elements.button.layoutOriginFractionX = 0.5
                    component.elements.button.text = getEnabledButtonText()
                end
        }
        enabledButton.callback =
            function()
                self.mod.config.current.enabled = not self.mod.config.current.enabled
                self.mod:enableOrDisable(self.mod.config.current.enabled)
                enabledButton.elements.button.text = getEnabledButtonText()
                if self.enableRequiresRestart then
                    local restartRequiredMessage = mwse.mcm.i18n("The game must be restarted before this change will come into effect.")
                    tes3.messageBox{message = restartRequiredMessage, buttons = {tes3.findGMST(tes3.gmst.sOK).value}}
                end
                if self.onEnabledButtonClicked then
                    self:onEnabledButtonClicked()
                end
            end
    end

    if self.showResetButton then
       self.infoPage:createButton{
            buttonText = "Сброс настроек",
            postCreate =
                function(component)
                    component.elements.outerContainer.borderTop = 8
                    component.elements.button.layoutOriginFractionX = 0.5
                end,
            callback =
                function()
                    tes3.messageBox{
                        message = "Вы уверены, что хотите восстановить настройки по умолчанию?",
                        buttons = {tes3.findGMST(tes3.gmst.sYes).value, tes3.findGMST(tes3.gmst.sNo).value},
                        callback = function(eventData)
                            if eventData.button == 0 then
                                self.mod.config:reset()
                                if self.template.elements.tabsBlock then
                                    self.template:clickTab(self.infoPage)
                                else
                                    local pageBlock = self.template.elements.pageBlock
                                    pageBlock:destroyChildren()
                                    self.infoPage:create(pageBlock)
                                    self.template.currentPage = self.infoPage
                                    pageBlock:getTopLevelParent():updateLayout()
                                end
                                if self.onResetButtonClicked then
                                    self:onResetButtonClicked()
                                end
                            end
                        end
                    }
                end
        }
    end

    if self.showLogLevelDropdown then
        self.infoPage:createDropdown{
            label = "Log Level",
            options = {
                { label = "Trace", value = "TRACE"},
                { label = "Debug", value = "DEBUG"},
                { label = "Info", value = "INFO"},
                { label = "Warn", value = "WARN"},
                { label = "Error", value = "ERROR"},
                { label = "None", value = "NONE"}
            },
            variable = mwse.mcm.createTableVariable{id = "logLevel", table = self.mod.config.current, restartRequired = false},
            callback =
                function()
                    self.mod:updateLogLevel()
                end,
            postCreate =
                function(component)
                    component.elements.outerContainer.borderTop = 24
                    component.elements.outerContainer.widthProportional = 0.3
                    component.elements.outerContainer.childAlignX = 0.5
                    component.elements.outerContainer.parent.childAlignX = 0.5
                    component.elements.label.justifyText = "center"
                end
        }
    end

    self.logger:debug("Info page created")
end

--- Creates all components of this MCM.
function Mcm:create()
    assert(type(self.headerImagePath) == "string", "headerImagePath must be a string")
    assert(type(self.showInfoPage) == "boolean", "showInfoPage must be a boolean")
    assert(type(self.showEnabledButton) == "boolean", "showEnabledButton must be a boolean")
    assert(type(self.showLogLevelDropdown) == "boolean", "showLogLevelDropdown must be a boolean")

    self.template = mwse.mcm.createTemplate{name = self.mod.name}
    self.template.onClose =
        function()
            if self.onClose then
                self:onClose()
            end
            if self.saveOnClose then
                self.mod.config:save(true)
            end
            if self.reenableOnClose and self.mod.isEnabled then
                self.mod:disable()
                self.mod:enable()
            end
            self.logger:debug("Closed")
        end
    self.template.postCreate =
        function()
            if self.onOpen then
                self:onOpen()
            end
            self.logger:debug("Opened")
        end

    if self.headerImagePath ~= "" then
        self.template.headerImagePath = self.headerImagePath
    end

    self.template:register()
    if self.showInfoPage then
        self:createInfoPage()
    end
    if self.onCreate then
        self:onCreate()
    end
    self.logger:debug("Created")
end

return Mcm