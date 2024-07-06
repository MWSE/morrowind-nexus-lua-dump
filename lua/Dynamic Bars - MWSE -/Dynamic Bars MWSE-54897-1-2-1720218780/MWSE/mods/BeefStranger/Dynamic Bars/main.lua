local cfg  = require("BeefStranger.Dynamic Bars.config")
local bs   = require("BeefStranger.Dynamic Bars.common")
local hudCustomizer
local menu = {}


local function simulateCallback(e)
    hudCustomizer = tes3.isLuaModActive("seph.hudcustomizer") --Get if hudCustomizer is enabled
    local multiMenu = menu:multiMenu()                        --Get multiMenu
    if not tes3.mobilePlayer then return end                  --Do nothing if mobilePlayer doesnt exist yet
    if not multiMenu then return end                          --Do nothing if the multiMenu hasnt been created

    menu.healthBar  = multiMenu:findChild("MenuStat_health_fillbar")
    menu.fatigueBar = multiMenu:findChild("MenuStat_fatigue_fillbar")
    menu.magicBar   = multiMenu:findChild("MenuStat_magic_fillbar")
    menu.weaponIcon = multiMenu:findChild("MenuMulti_weapon_layout")
    menu.magicIcon  = multiMenu:findChild("MenuMulti_magic_layout")
    menu.sneakIcon  = multiMenu:findChild("MenuMulti_sneak_icon")
    menu.notify     = multiMenu:findChild("MenuMulti_weapon_magic_notify")
    if not cfg.enabled then return end --Stop here if mod disabled 

    --Variables for easy access
    local health     = tes3.mobilePlayer.health
    local fatigue    = tes3.mobilePlayer.fatigue
    local magicka    = tes3.mobilePlayer.magicka
    local healthBar  = menu.healthBar
    local hText      = healthBar:findChild("PartFillbar_text_ptr")
    local fatigueBar = menu.fatigueBar
    local fText      = fatigueBar:findChild("PartFillbar_text_ptr")
    local magicBar   = menu.magicBar
    local mText      = magicBar:findChild("PartFillbar_text_ptr")
    local weaponIcon = menu.weaponIcon
    local magicIcon  = menu.magicIcon
    local sneakIcon  = menu.sneakIcon

    --Modify bar width to base + barPadding, capping at the widthCap
    local hWidth               = math.min(health.base, cfg.widthCap)
    local fWidth               = math.min(fatigue.base, cfg.widthCap)
    local mWidth               = math.min(magicka.base, cfg.widthCap)

    healthBar.width            = hWidth + cfg.barPadding
    hText.positionY            = cfg.textPos
    healthBar.widget.showText  = cfg.showHealth and true or false
    healthBar.widget.current   = health.current
    healthBar.widget.max       = health.base

    fatigueBar.width           = fWidth + cfg.barPadding
    fText.positionY            = cfg.textPos
    fatigueBar.widget.showText = cfg.showFatigue and true or false
    fatigueBar.widget.current  = fatigue.current
    fatigueBar.widget.max      = fatigue.base

    magicBar.width             = mWidth + cfg.barPadding
    mText.positionY            = cfg.textPos
    magicBar.widget.showText   = cfg.showMagicka and true or false
    magicBar.widget.current    = magicka.current
    magicBar.widget.max        = magicka.base

    local healthWidth          = menu.healthBar.width
    local fatigueWidth         = menu.fatigueBar.width
    local magicWidth           = menu.magicBar.width

    ---Very minor support for hudCustomizer
    if hudCustomizer and cfg.hcAutoMove then
        local biggestBar         = math.max(healthWidth, fatigueWidth, magicWidth) + 20
        weaponIcon.ignoreLayoutX = true
        weaponIcon.positionX     = biggestBar

        magicIcon.ignoreLayoutX  = true
        magicIcon.positionX      = biggestBar + 43

        sneakIcon.ignoreLayoutX  = true
        sneakIcon.positionX      = biggestBar + 86
    end
end
event.register(tes3.event.simulate, simulateCallback)

---Event to manually fire menu edits
event.register(bs.barUpdate, simulateCallback)


event.register(bs.defaults, function(e)
    if menu then
        if hudCustomizer then
            mwse.log("Mod Disabled: Applying hudCustomizer defaults")
            menu.healthBar.width              = 80
            menu.fatigueBar.width             = 80
            menu.magicBar.width               = 80
            menu.healthBar.widget.showText    = false
            menu.fatigueBar.widget.showText   = false
            menu.magicBar.widget.showText     = false

            menu:hudCustIconDefault()

            event.trigger(bs.barUpdate)

        else
            mwse.log("Mod Disabled: Applying Vanilla defaults")
            menu.healthBar.width            = 65
            menu.fatigueBar.width           = 65
            menu.magicBar.width             = 65
            menu.healthBar.widget.showText  = false
            menu.fatigueBar.widget.showText = false
            menu.magicBar.widget.showText   = false
            event.trigger(bs.barUpdate)
        end
    end
end)



event.register(bs.manualMove, function (e)
    if menu:multiMenu() then
        if not cfg.hcAutoMove then
            menu.weaponIcon.absolutePosAlignX = 0
            menu.weaponIcon.absolutePosAlignY = 0.93

            menu.magicIcon.absolutePosAlignX  = 0.026
            menu.magicIcon.absolutePosAlignY  = 0.93

            menu.sneakIcon.absolutePosAlignX  = 0.051
            menu.sneakIcon.absolutePosAlignY  = 0.924

            menu.notify.absolutePosAlignX     = 0
            menu.notify.absolutePosAlignY     = 0.875

           event.trigger(bs.barUpdate)
           menu:multiMenu():updateLayout()

        else
            menu:hudCustIconDefault()

            event.trigger(bs.barUpdate)
            menu:multiMenu():updateLayout()
        end

    end
end)

function menu:hudCustIconDefault()
    menu.weaponIcon.ignoreLayoutX     = false
    menu.magicIcon.ignoreLayoutX      = false
    menu.sneakIcon.ignoreLayoutX      = false

    menu.weaponIcon.absolutePosAlignX = 0.055
    menu.magicIcon.absolutePosAlignX  = 0.081
    menu.sneakIcon.absolutePosAlignX  = 0.108

    menu.weaponIcon.absolutePosAlignY = 1
    menu.magicIcon.absolutePosAlignY  = 1
    menu.sneakIcon.absolutePosAlignY  = 1

    menu.notify.absolutePosAlignX     = 0
    menu.notify.absolutePosAlignY     = 0.935
end

function menu:multiMenu()
    return tes3ui.findMenu("MenuMulti")
end

--- @param e loadedEventData
local function onLoad(e)
    event.trigger(bs.barUpdate)
end
event.register(tes3.event.loaded, onLoad)


event.register("initialized", function()
    print("[MWSE:Dynamic Bars] initialized")
    hudCustomizer = tes3.isLuaModActive("seph.hudcustomizer")
    if hudCustomizer then
        print("[MWSE:Dynamic Bars] hudCustomizer Active")
    end
end)
