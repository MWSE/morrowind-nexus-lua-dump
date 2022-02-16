local seph = require("seph")

local mod = seph.Mod()

mod.id = "seph.hudCustomizer"
mod.name = "Seph's HUD Customizer"
mod.description = [[
This mod makes almost every element of the HUD customizable to a certain degree.
It has a very large set of customization options. Please select one of the tabs for more information on configuration.
The look and feel of the vanilla UI is almost completely unchanged with only a few elements slightly moved.
If you don't like these changes you can easily readjust them to your tastes.
The days of the static and ugly HUD are ending. Make your own HUD!]]
mod.author = "Sephumbra"
mod.hyperlink = "https://www.nexusmods.com/morrowind/mods/50588"
mod.version = {major = 2, minor = 1, patch = 1}
mod.requiredModules = {
    "hud",
    "highlighter",
    "interop",
    "compatibility"
}

return mod