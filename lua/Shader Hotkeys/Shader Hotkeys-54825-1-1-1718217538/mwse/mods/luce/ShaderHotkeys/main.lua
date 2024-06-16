local configPath = "Shader Hotkeys"

local config = mwse.loadConfig(configPath, {
    enabled = true,
    specialProcessHotkey = {
        keyCode = tes3.scanCode["questionMark"],
        isShiftDown = true,
        isAltDown = false,
        isControlDown = false,
        isSuperDown = false
    },
    hdrHotkey = {
        keyCode = tes3.scanCode["openPointyBracket"],
        isShiftDown = true,
        isAltDown = false,
        isControlDown = false,
        isSuperDown = false
    },
    ssaoHotkey = {
        keyCode = tes3.scanCode["closePointyBracket"],
        isShiftDown = true,
        isAltDown = false,
        isControlDown = false,
        isSuperDown = false
    }
})

local function registerModConfig()
    local template = mwse.mcm.createTemplate({ name = "Shader Hotkeys" })
    template:saveOnClose(configPath, config)

    local settings = template:createPage({ label = "Settings" })

    settings:createKeyBinder({
        label = "Toggle SpecialProcess",
        description = "Toggle SpecialProcess shader on or off.",
        variable = mwse.mcm.createTableVariable{ id = "specialProcessHotkey", table = config },
        allowCombinations = true,
    })

    settings:createKeyBinder({
        label = "Toggle HDR",
        description = "Toggle HDR on or off.",
        variable = mwse.mcm.createTableVariable{ id = "hdrHotkey", table = config },
        allowCombinations = true,
    })

    settings:createKeyBinder({
        label = "Toggle SSAO",
        description = "Toggle SSAO on or off.",
        variable = mwse.mcm.createTableVariable{ id = "ssaoHotkey", table = config },
        allowCombinations = true,
    })

    template:register()
end

local function toggleShader(shaderName)
    mwse.log("Called " .. shaderName .. " toggle")
    for i, shader in pairs(mge.shaders.list) do
        if (shader.name == shaderName) then
            if (shader.enabled) then
                mwse.log("Disabling " .. shaderName)
                shader.enabled = false
                return
            end
            mwse.log("Enabling" .. shaderName)
            shader.enabled = true
        end
      end
end

---comment
---@param e table|keyDownEventData
local function toggleShaderCheck(e)
    if tes3.isKeyEqual{ actual = e, expected = config.specialProcessHotkey } then toggleShader("Special_Process") end

    if tes3.isKeyEqual{ actual = e, expected = config.hdrHotkey } then toggleShader("Eye Adaptation (HDR)") end

    if tes3.isKeyEqual{ actual = e, expected = config.ssaoHotkey } then toggleShader("SSAO_UHQ") end

end

event.register(tes3.event.modConfigReady, registerModConfig)
event.register(tes3.event.keyDown, toggleShaderCheck)