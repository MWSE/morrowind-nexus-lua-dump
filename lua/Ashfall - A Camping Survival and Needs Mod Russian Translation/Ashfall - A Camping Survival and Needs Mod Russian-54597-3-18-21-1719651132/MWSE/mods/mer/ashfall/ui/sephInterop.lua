local hudCustomizerInterop = include("Seph.HUDCustomizer.interop")
if hudCustomizerInterop then
    hudCustomizerInterop:registerElement("Ashfall:HUD_mainHUDBlock",
    "Пеплопад", {positionX = 0.5, positionY = 0.0}, {position = true})
end