-- ============================================================
-- Spells of Morrowind: Haggle-light and Travel Illumination — SETTINGS Script (Player)
-- ============================================================

local I       = require("openmw.interfaces")
local async   = require("openmw.async")
local core    = require("openmw.core")
local storage = require("openmw.storage")
local selfMod = require("openmw.self")

local player = selfMod.object or selfMod

I.Settings.registerPage{
  key         = "ArcaneIllumination",
  l10n        = "ArcaneIllumination",
  name        = "Spells of Morrowind: Haggle-light and Travel Illumination",
  description = "Configure mod settings below.",
}

I.Settings.registerGroup{
  key              = "Settings_ArcaneIllumination_Debug",
  page             = "ArcaneIllumination",
  l10n             = "ArcaneIllumination",
  name             = "Debug Settings",
  permanentStorage = true,
  settings = {
    {
      key         = "debugMode",
      default     = false,
      renderer    = "checkbox",
      name        = "Enable Debug Logging",
      description = "If enabled, logs will be printed to the console.",
    },
  },
}

I.Settings.registerGroup{
  key              = "ArcaneIlluminationSettings",
  page             = "ArcaneIllumination",
  l10n             = "ArcaneIllumination",
  name             = "Haggle-light",
  permanentStorage = true,
  settings = {
    {
      key         = "haggleCooldownHours",
      renderer    = "select",
      name        = "Haggle-light Cooldown Duration",
      description = "Select the cooldown duration for Haggle-light after a successful cast.",
      default     = "1 Hour",
      argument    = {
        disabled = false,
        l10n     = "ArcaneIllumination",
        items    = { "Disabled", "1 Hour", "3 Hours", "6 Hours", "12 Hours", "24 Hours" },
      },
    },
    {
      key         = "haggleMercantileRatio",
      renderer    = "number",
      name        = "Mercantile → Sell % Ratio",
      description = "Gold payout percent = Mercantile * ratio. Default 0.5 means Mercantile 100 => 50% payout.",
      default     = 0.5,
    },
    {
      key         = "haggleMagnitudeMultiplier",
      renderer    = "number",
      name        = "Magnitude → Capacity Multiplier",
      description = "Container capacity = Magnitude * multiplier. Default 0.5 means Magnitude 100 = 50 capacity.",
      default     = 0.5,
    },
  },
}

I.Settings.registerGroup{
  key              = "ArcaneIlluminationVisuals",
  page             = "ArcaneIllumination",
  l10n             = "ArcaneIllumination",
  name             = "Visual Settings",
  permanentStorage = true,
  settings = {
    {
      key         = "lightPosition",
      renderer    = "select",
      name        = "Light Position",
      description = "Choose whether conjured lights appear on your left or right side. Changes apply immediately.",
      default     = "Left",
      argument    = {
        disabled = false,
        l10n     = "ArcaneIllumination",
        items    = { "Left", "Right" },
      },
    },
    {
      key         = "vfxEnabled",
      renderer    = "checkbox",
      name        = "Enable Sparkle VFX",
      description = "If disabled, removes the magical sparkle VFX from all conjured lights.",
      default     = true,
    },
    {
      key         = "vfxOffsetConjure",
      renderer    = "number",
      name        = "VFX Vertical Offset — Conjure Lantern",
      description = "Vertical offset of the sparkle anchor below the lantern. Negative = lower. Range -100 to 100.",
      default     = -50,
    },
    {
      key         = "vfxOffsetAttach",
      renderer    = "number",
      name        = "VFX Vertical Offset — Attach Light (Fallback)",
      description = "Fallback offset for attached lights. Torches use +10, lanterns use -41, candles use -10 (hardcoded). This setting applies to all other light types. Range -100 to 100.",
      default     = -50,
    },
    {
      key         = "vfxScaleConjure",
      renderer    = "number",
      name        = "VFX Scale — Conjure Lantern",
      description = "Size of the sparkle effect on the Conjure Lantern spell. Range 0.05–1.0.",
      default     = 0.3,
    },
    {
      key         = "vfxScaleAttach",
      renderer    = "number",
      name        = "VFX Scale — Attach Light",
      description = "Size of the sparkle effect on the Attach Light spell. Range 0.05–1.0.",
      default     = 0.2,
    },
    {
      key         = "vfxScaleWispHaggle",
      renderer    = "number",
      name        = "VFX Scale — Light Wisp & Haggle-light",
      description = "Size of the sparkle effect on the Light Wisp and Haggle-light spells. Range 0.05–1.0.",
      default     = 0.2,
    },
  },
}

local function updateSettings()
  local debugMode = storage.playerSection("Settings_ArcaneIllumination_Debug"):get("debugMode")

  local haggle                    = storage.playerSection("ArcaneIlluminationSettings")
  local haggleCooldownHours       = haggle:get("haggleCooldownHours")
  local haggleMercantileRatio     = haggle:get("haggleMercantileRatio")
  local haggleMagnitudeMultiplier = haggle:get("haggleMagnitudeMultiplier")

  local visuals            = storage.playerSection("ArcaneIlluminationVisuals")
  local lightPosition      = visuals:get("lightPosition")
  local vfxEnabled         = visuals:get("vfxEnabled")
  local vfxScaleConjure    = visuals:get("vfxScaleConjure")
  local vfxScaleAttach     = visuals:get("vfxScaleAttach")
  local vfxScaleWispHaggle = visuals:get("vfxScaleWispHaggle")
  local vfxOffsetConjure   = visuals:get("vfxOffsetConjure")
  local vfxOffsetAttach    = visuals:get("vfxOffsetAttach")

  core.sendGlobalEvent("ArcaneIllumination_UpdateSettings", {
    debugMode                 = debugMode,
    haggleCooldownHours       = haggleCooldownHours,
    haggleMercantileRatio     = haggleMercantileRatio,
    haggleMagnitudeMultiplier = haggleMagnitudeMultiplier,
    lightPosition             = lightPosition,
    vfxEnabled                = vfxEnabled,
    vfxScaleConjure           = vfxScaleConjure,
    vfxScaleAttach            = vfxScaleAttach,
    vfxScaleWispHaggle        = vfxScaleWispHaggle,
    vfxOffsetConjure          = vfxOffsetConjure,
    vfxOffsetAttach           = vfxOffsetAttach,
  })

  if player and player.sendEvent then
    player:sendEvent("ArcaneIllumination_UpdateLightPos", { position = lightPosition })
  end
end

storage.playerSection("Settings_ArcaneIllumination_Debug"):subscribe(async:callback(updateSettings))
storage.playerSection("ArcaneIlluminationSettings"):subscribe(async:callback(updateSettings))
storage.playerSection("ArcaneIlluminationVisuals"):subscribe(async:callback(updateSettings))

return {
  engineHandlers = {
    onActive = function()
      updateSettings()
    end
  }
}