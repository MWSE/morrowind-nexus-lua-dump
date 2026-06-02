local function onHaggleOrbActivated(data)
    if not haggleLightState then return end
    if haggleLightState.isRemoving then return end
    if haggleLightState.activationCount >= 1 then return end

    haggleLightState.activationCount = 1

    local player       = data.player or haggleLightState.attacker
    local containerObj = haggleLightState.containerObj

    if not (player and player:isValid()) then return end
    if not (containerObj and containerObj:isValid()) then return end

    -- No teleport at all — activate remotely while underground
    local ok, err = pcall(function()
        containerObj:activate(player)
    end)
    if not ok then
        print("[Arcane Illumination] ERROR opening container UI: " .. tostring(err))
    else
        print("[Arcane Illumination] Haggle container UI opened remotely — awaiting second activation")
    end
end