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

local function fillbarCheck()

    if (not tes3.mobilePlayer) then return end

    local spellCost = tes3.mobilePlayer.currentSpell.magickaCost
    local currentMagicka = tes3.mobilePlayer.magicka.current

    if (not spellCost) or (not currentMagicka) then return end

    local bool = spellCost <= currentMagicka

    if fillbarVisible ~= bool then
        setFillbar(bool)
    end
end

local function init()
    event.register("enterFrame", fillbarCheck)
end

event.register("initialized", init)