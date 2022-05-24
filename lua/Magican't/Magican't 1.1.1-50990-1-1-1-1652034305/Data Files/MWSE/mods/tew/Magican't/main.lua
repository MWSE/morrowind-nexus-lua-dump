local fillbarVisible = false

local function setFillbar(bool)
    local menuMulti = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
    local magicIcon = menuMulti:findChild(tes3ui.registerID("MenuMulti_magic_fill"))

    if magicIcon then
        magicIcon.children[1].visible = bool
        magicIcon:updateLayout()
    end

    fillbarVisible = bool
end

-- Necrolesian, you're my hero.
local function fillbarCheck()

    local mp = tes3.mobilePlayer
    if not mp then return end

    local spell = mp.currentSpell
    if not spell then return end

    local spellCost = spell.magickaCost
    if not spellCost then return end

    local currentMagicka = mp.magicka.current
    local bool = spellCost <= currentMagicka

    if fillbarVisible ~= bool then
        setFillbar(bool)
    end
end

local function init()
    event.register("enterFrame", fillbarCheck)
end

event.register("initialized", init)