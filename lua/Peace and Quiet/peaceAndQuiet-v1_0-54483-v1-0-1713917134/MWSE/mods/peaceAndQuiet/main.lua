local MODNAME = "peaceAndQuiet"

local mcm = require("peaceAndQuiet.peaceandquiet_mcm")

--- @type ModConfig
local config = mwse.loadConfig(MODNAME, mcm.defaults)

local schools = {
    "alteration",
    "conjuration",
    "destruction",
    "illusion",
    "mysticism",
    "restoration",
}

---@param eventName tes3.event | string
---@param callback fun(e: table)
---@param options? event.register.options
local function tryRegisterEvent(eventName, callback, options)
    if options and options.filter then
        if not event.isRegistered(eventName, callback, { filter = options.filter }) then
            event.register(eventName, callback, options)
        end
    end

    if not event.isRegistered(eventName, callback) then
        event.register(eventName, callback)
    end
end

---@param e addSoundEventData
local function suppressSoundFX(e)
    if not table.find(schools, string.split(e.sound.id, " ")[1]) then
        return
    end

    e.block = true
    timer.delayOneFrame(function()
        event.unregister(tes3.event.addSound, suppressSoundFX)
    end)
end

---@param e vfxCreatedEventData
local function suppressVisualFX(e)
    local effectName = e.vfx.effectObject.id
    local _, _, capture = string.find(effectName, "VFX_(%a+)Hit")

    if not capture then
        return
    end

    local school = string.lower(capture)
    if not table.find(schools, school) then
        return
    end

    e.vfx.expired = true

    timer.delayOneFrame(function()
        event.unregister(tes3.event.vfxCreated, suppressVisualFX)
    end)
end

---@param e magicCastedEventData
local function magicEffectHandler(e)

    if e.source.objectType == tes3.objectType.enchantment then

        local enchantment = e.source --[[@as tes3enchantment]]

        if enchantment.castType ~= tes3.enchantmentType.constant then
            return
        end

        if config.suppressEnchantVFX then
            tryRegisterEvent(tes3.event.vfxCreated, suppressVisualFX)
        end

        if config.suppressEnchantAudio then
            tryRegisterEvent(tes3.event.addSound, suppressSoundFX)
        end

    end

    if e.source.objectType == tes3.objectType.alchemy then

        if config.suppressAlchemyVFX then
            tryRegisterEvent(tes3.event.vfxCreated, suppressVisualFX)
        end

        if config.suppressAlchemyAudio then
            tryRegisterEvent(tes3.event.addSound, suppressSoundFX)
        end
    end
end

event.register(tes3.event.initialized, function()
    mwse.log("[%s] Initialized", MODNAME)
    event.register(tes3.event.magicCasted, magicEffectHandler)
end)

event.register(tes3.event.modConfigReady, function()
    mcm.registerMCM(MODNAME, config)
end)
