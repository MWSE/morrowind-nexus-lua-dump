--[[

	inom - User interface hider
	An MWSE-lua mod for Morrowind
	
	@version      v1.1.0
	@author       Isnan
	@last-update  September 12, 2021
	@changelog
        v1.1.0
        - Refactored for future granularity. Other mods must be supported on a case-by-base after this.
        - Added support for Ashfall
        - Added support for Clock Block
        - Prevented the mod from ever hiding the stealth icon
		v1.0.0
		- Initial release

]]


-- store
local isCrosshairHidden = true
local isGUIHidden       = true
local isModActive       = true
local isForcedOn        = false
local timerCrosshair    = nil
local timerGUI          = nil
local timerVisibility   = nil
local uiMenuMulti       = nil
local uiMenuMultiBottom = nil

-- different bottom row blocks
local uiMenuMultiBottomWeaponMagicNotify  = nil
local uiMenuMultiBottomNPCHealthBar       = nil
local uiMenuMultiBottomFillbarsLayout     = nil
local uiMenuMultiBottomWeaponLayout       = nil
local uiMenuMultiBottomMagicLayout        = nil
local uiMenuMultiBottomSneakIcon          = nil
local uiMenuMultiBottomAshfallBlock       = nil
local uiMenuMultiBottomAshfallBlockTop    = nil
local uiMenuMultiBottomAshfallBlockBottom = nil
local uiMenuMultiBottomClockBlock         = nil
local uiMenuMultiBottomMagicIconsLayout   = nil
local uiMenuMultiBottomMapNotify          = nil
local uiMenuMultiBottomMenuMap            = nil

-- config
local config = mwse.loadConfig( "inom - User interface hider" )

config = config or {}
config.toggleModKey = config.toggleModKey or {
	keyCode         = tes3.scanCode.x,
	isShiftDown     = false,
	isAltDown       = true,
	isControlDown   = false,
}


local function isHealthAbove50Perc()
    local perc = math.floor( tes3.player.mobile.health.current / tes3.player.mobile.health.base * 100 )
    return perc >= 50
end


local function renderGUI()

    -- find menus
	local menuMulti                         = tes3ui.findMenu( uiMenuMulti )
    local menuMultiBottom                   = menuMulti:findChild( uiMenuMultiBottom                   )
    local menuMultiBottomWeaponMagicNotify  = menuMulti:findChild( uiMenuMultiBottomWeaponMagicNotify  )
    local menuMultiBottomNPCHealthBar       = menuMulti:findChild( uiMenuMultiBottomNPCHealthBar       )
    local menuMultiBottomFillbarsLayout     = menuMulti:findChild( uiMenuMultiBottomFillbarsLayout     )
    local menuMultiBottomWeaponLayout       = menuMulti:findChild( uiMenuMultiBottomWeaponLayout       )
    local menuMultiBottomMagicLayout        = menuMulti:findChild( uiMenuMultiBottomMagicLayout        )
    local menuMultiBottomSneakIcon          = menuMulti:findChild( uiMenuMultiBottomSneakIcon          )
    local menuMultiBottomAshfallBlock       = menuMulti:findChild( uiMenuMultiBottomAshfallBlock       ) -- ashfall itself changes the visibility of this element.
    local menuMultiBottomAshfallBlockTop    = menuMulti:findChild( uiMenuMultiBottomAshfallBlockTop    )
    local menuMultiBottomAshfallBlockBottom = menuMulti:findChild( uiMenuMultiBottomAshfallBlockBottom )
    local menuMultiBottomMagicIconsLayout   = menuMulti:findChild( uiMenuMultiBottomMagicIconsLayout   )
    local menuMultiBottomMapNotify          = menuMulti:findChild( uiMenuMultiBottomMapNotify          )
    local menuMultiBottomMenuMap            = menuMulti:findChild( uiMenuMultiBottomMenuMap            )
    local menuMultiBottomClockBlock         = menuMulti:findChild( uiMenuMultiBottomClockBlock         )

    -- if the gui is forced on, or the mod is disabled - turn all visibility on.
    if isForcedOn or not isModActive or tes3.player.mobile.combat or not isHealthAbove50Perc() then
        isGUIHidden       = false
        isCrosshairHidden = false
    end

    if tes3.player.mobile.isSneaking then
        isCrosshairHidden = false
    end

    -- perform visibility logic
    if isGUIHidden then
        menuMulti.visible = not isCrosshairHidden

        -- left side fillbars, weapon and magic.
        menuMultiBottomWeaponMagicNotify.visible      = false
        menuMultiBottomFillbarsLayout.visible         = false
        menuMultiBottomWeaponLayout.visible           = false
        menuMultiBottomMagicLayout.visible            = false
        --menuMultiBottomSneakIcon  -- we never touch the sneak icon.

        -- right side buffs and map
        menuMultiBottomMagicIconsLayout.visible       = false
        menuMultiBottomMapNotify.visible              = false
        menuMultiBottomMenuMap.visible                = false

        -- other mods supported (ashfall and clock block)
        if menuMultiBottomAshfallBlock then
            menuMultiBottomAshfallBlockTop.visible    = false
            menuMultiBottomAshfallBlockBottom.visible = false
        end
        if menuMultiBottomClockBlock then
            menuMultiBottomClockBlock.visible         = false
        end
    else
        menuMulti.visible = true

        -- left side fillbars, weapon and magic.
        menuMultiBottomWeaponMagicNotify.visible      = true
        menuMultiBottomFillbarsLayout.visible         = true
        menuMultiBottomWeaponLayout.visible           = true
        menuMultiBottomMagicLayout.visible            = true
        --menuMultiBottomSneakIcon  -- we never touch the sneak icon.

        -- right side buffs and map
        menuMultiBottomMagicIconsLayout.visible       = true
        menuMultiBottomMapNotify.visible              = true
        menuMultiBottomMenuMap.visible                = true

        -- other mods supported (ashfall and clock block)
        if menuMultiBottomAshfallBlock then
            menuMultiBottomAshfallBlockTop.visible    = true
            menuMultiBottomAshfallBlockBottom.visible = true
        end
        if menuMultiBottomClockBlock then
            menuMultiBottomClockBlock.visible         = true
        end
    end
end


local function hideGUI( seconds, isForcedTimer )
    -- no hiding for the unhealthy, mod flagged, nor those in combat
    if isHealthAbove50Perc() and isModActive and not tes3.player.mobile.combat then

        -- end any existing timer if asked to
        if isForcedTimer and timerGUI then
            timerGUI:cancel()
            timerGUI = nil
        end

        -- start a new timer if one isn't running
        if seconds and not timerGUI then
            timerGUI = timer.start({
                duration    = seconds,
                callback    = function()
                    isGUIHidden = true
                    renderGUI()
                end,
            })
        end
    end
end


local function hideCrosshair( seconds )
    -- no hiding for the unhealthy, mod flagged, nor those in combat
    if isHealthAbove50Perc() and isModActive and not tes3.player.mobile.combat then

    -- always stop the timer when working on the crosshair visibility.
        if timerCrosshair then
            timerCrosshair:cancel()
            timerCrosshair = nil
        end

        -- start a new timer
        if seconds then
            timerCrosshair = timer.start({
                duration = seconds,
                callback = function()
                    isCrosshairHidden = true
                    renderGUI()
                end,
            })
        end
    end
end


local function showGUI( seconds )
    -- turn on the GUI and the crosshair.
    isGUIHidden       = false
    isCrosshairHidden = false
    renderGUI()

    -- queue gui removal later if available.
    if seconds then
        hideGUI( seconds, true ) -- every time we show the GUI, we force reset any hide gui timer.
        hideCrosshair( seconds )
    end
end


local function showCrosshair( seconds )
    -- turn on the crosshair
    isCrosshairHidden = false
    renderGUI()

    -- always stop the timer when working with the crosshair.
    if timerCrosshair then
        timerCrosshair:cancel()
        timerCrosshair = nil
    end

    -- queue crosshair removal later if available
    if ( seconds ) then
        hideCrosshair( seconds )
    end
end


local function toggleVisibility()
    if isModActive then
        -- turn mod off
        isModActive = false
        -- show all elements indefinately
        showGUI( nil )
        showCrosshair( nil )
        -- inform user
        tes3.messageBox( "User interface hider paused for three minutes." )
        -- set a timer for when the mod returns
        timerVisibility = timer.start({
            duration = 180,
            callback = function()
                isModActive     = true
                timerVisibility = nil
                hideGUI( 7 )
                hideCrosshair( 7 )
            end,
        })
    else
        -- stop the timer
        if timerVisibility then
            timerVisibility:cancel()
            timerVisibility = nil
        end
        -- turm mod on and disable forced (this means a double-tap of the toggle key will allow the GUI to hide - for immersive ashfall resting or whatnot.)
        isModActive = true
        isForcedOn  = false
        -- init hide timers
        showGUI( 2 )
        showCrosshair( 2 )
        -- inform user
        tes3.messageBox( "User interface hider resumed." )
    end
end

local function isToggleModKey( event )
    local key = config.toggleModKey
    -- make sure the key matches all the criteria
    return ( key.keyCode       == event.keyCode )
    and    ( key.isShiftDown   == event.isShiftDown )
    and    ( key.isAltDown     == event.isAltDown )
    and    ( key.isControlDown == event.isControlDown)
end

local function onKeyDown( event )
    -- all the keys
    local inputController = tes3.worldController.inputController
    local keySneak        = tes3.keybind.sneak
    local keyWeapon       = tes3.keybind.readyWeapon
    local keyMagic        = tes3.keybind.readyMagic
    local keysActivate    = {
        tes3.keybind.nextSpell,
        tes3.keybind.nextWeapon,
        tes3.keybind.previousSpell,
        tes3.keybind.previousWeapon,
        tes3.keybind.readyMagicMCP,
        tes3.keybind.quick1,
        tes3.keybind.quick2,
        tes3.keybind.quick3,
        tes3.keybind.quick4,
        tes3.keybind.quick5,
        tes3.keybind.quick6,
        tes3.keybind.quick7,
        tes3.keybind.quick8,
        tes3.keybind.quick9,
        tes3.keybind.quick10,
    }

    -- config key for toggling the mod off for three minutes.
    if isToggleModKey( event ) then
        toggleVisibility()
    end

    if inputController:keybindTest( keySneak ) then
        -- if you're not sneaking when the key is pressed, it means you're about to turn it on.
        if not tes3.player.mobile.isSneaking then
            -- this is a response, turn the crosshair on for a longer while.
            showCrosshair( 7 )
        end
    end

    if inputController:keybindTest( keyWeapon ) then
        -- if you already have a weapon in your hands, this is an idle hands move.
        if tes3.player.mobile.weaponDrawn then
            -- this is an idle response, which turns the GUI off after a short while.
            hideGUI( 2 )
            hideCrosshair( 2 )
        else
            -- this is an activation move, which always turns the GUI on for a short while.
            showGUI( 4 )
        end
    end

    if inputController:keybindTest( keyMagic ) then
        -- if you already have magic hands out, this is an idle hands move.
        if tes3.player.mobile.castReady then
            -- this is an idle response, which turns the GUI off after a short while.
            hideGUI( 2 )
            hideCrosshair( 2 )
        else
            -- this is an activation move, which always turns the GUI on for a short while.
            showGUI( 4 )
        end
    end

    -- the activate keys always turns the GUI on.
    for _, key in pairs( keysActivate ) do
        if ( inputController:keybindTest( key ) ) then
            -- this is an activation move, which always turns the GUI on for a short while.
            showGUI( 4 )
        end
    end

end

local function onAshfallResting()
    -- this is resting, which turns the GUI on indefinately (so you can keep tabs on current health).
    isForcedOn = true
    showGUI( nil )
end


local function onMenuEnter()
    -- menus are a special case where everything is on indefinately.
    showGUI( nil )
    showCrosshair( nil )
end


local function onAttackStart()
    -- this is like combat, show the crosshair indefinately.
    showCrosshair( nil )
end


local function onUiObjectTooltip()
    -- this is a response, turn the crosshair on for a longer while.
    showCrosshair( 7 )
end


local function onAttack()
    -- this is a response, which always turns the GUI on for a longer while.
    showGUI( 7 )
    hideCrosshair( 7 )
end


local function onDamage()
    -- this is a response, which always turns the GUI on for a longer while.
    showGUI( 7 )
end


local function onCombatStarted()
    -- this is combat, which turns the GUI on indefinately.
    isForcedOn = true
    showGUI( nil )
end


local function onMagicCasted()
    -- this is an activation move, which always turns the GUI on for a short while.
    showGUI( 4 )
end


local function onSpellCast()
    -- this is an activation move, which always turns the GUI on for a short while.
    showGUI( 4 )
end


local function onCombatStopped()
    -- this is an after-response, which turns the GUI off after a longer while.
    isForcedOn = false
    hideGUI( 7, true )
end

local function onAshfallRestingEnd()
    -- this is an after-response, which turns the GUI off after a longer while.
    isForcedOn = false
    hideGUI( 7, true )
end


local function onMenuExit()
    -- this is an idle response, which turns the GUI off after a short while.
    showGUI( 2 )
    showCrosshair( 2 )
end


local function onLoaded()
    -- make sure to reset flags on load
    isForcedOn  = false
    isModActive = true
    -- this is an idle response, which turns the GUI off after a short while.
    hideGUI( 2 )
    hideCrosshair( 2 )
end


local function onInitialized()

    -- main elements
    uiMenuMulti                        = tes3ui.registerID( "MenuMulti"                     )
    uiMenuMultiBottom                  = tes3ui.registerID( "MenuMulti_bottom_row"          )

    -- left side bottom elements
    uiMenuMultiBottomWeaponMagicNotify = tes3ui.registerID( "MenuMulti_weapon_magic_notify" )
    uiMenuMultiBottomNPCHealthBar      = tes3ui.registerID( "MenuMulti_npc_health_bar"      )
    uiMenuMultiBottomFillbarsLayout    = tes3ui.registerID( "MenuMulti_fillbars_layout"     )
    uiMenuMultiBottomWeaponLayout      = tes3ui.registerID( "MenuMulti_weapon_layout"       )
    uiMenuMultiBottomMagicLayout       = tes3ui.registerID( "MenuMulti_magic_layout"        )
    uiMenuMultiBottomSneakIcon         = tes3ui.registerID( "MenuMulti_sneak_icon"          )

    -- right side bottom elements
    uiMenuMultiBottomMagicIconsLayout  = tes3ui.registerID( "MenuMulti_magic_icons_layout"  )
    uiMenuMultiBottomMapNotify         = tes3ui.registerID( "MenuMulti_map_notify"          )
    uiMenuMultiBottomMenuMap           = tes3ui.registerID( "MenuMap_panel"                 )

    -- elements from other mods
    uiMenuMultiBottomAshfallBlock       = tes3ui.registerID( "Ashfall:HUD_mainHUDBlock"     )
    uiMenuMultiBottomAshfallBlockTop    = tes3ui.registerID( "Ashfall:HUD_topHUDBlock"      )
    uiMenuMultiBottomAshfallBlockBottom = tes3ui.registerID( "Ashfall:HUD_bottomBlock"      )
    uiMenuMultiBottomClockBlock         = tes3ui.registerID( "Aleist3r:ClockBlock"          )

    -- keypresses always mean some form of activation, cancellation or need of a crosshair
    event.register( "keyDown",                   onKeyDown )

    -- resting or waiting in ashfall shows the GUI.
    event.register( "Ashfall:LayDown",           onAshfallResting )
    event.register( "Ashfall:SitDown",           onAshfallResting )

    -- when menus are opened - show the GUI
    event.register( "menuEnter",                 onMenuEnter )

    -- if you draw your bow, or look at anything (including ashfall-things), show the crosshair
    event.register( "attackStart",               onAttackStart )
    event.register( "uiObjectTooltip",           onUiObjectTooltip )
    event.register( "Ashfall:Activator_tooltip", onUiObjectTooltip )

    -- if you attack, take damage, or combat initiates - show the GUI
    event.register( "attack",                    onAttack )
    event.register( "damage",                    onDamage )
    event.register( "combatStarted",             onCombatStarted )

    -- casting spells and using potions also shows the GUI
    event.register( "magicCasted",               onMagicCasted )
    event.register( "spellCast",                 onSpellCast )

    -- hide the GUI whenever we stop resting in Ashfall
    event.register( "Ashfall:CancelAnimation",   onAshfallRestingEnd )

    -- hide the GUI whenever we're out of combat, done with the menus, or just loaded the game
    event.register( "combatStopped",             onCombatStopped )
    event.register( "menuExit",                  onMenuExit )
    event.register( "loaded",                    onLoaded )

end

event.register( 'initialized', onInitialized, { doOnce = true } )

-- MCM page
local function registerModConfig()

    local EasyMCM = require( "easyMCM.EasyMCM" )

    local template = EasyMCM.createTemplate( "inom - User interface hider" )
    template:saveOnClose( "inom - User interface hider", config )

	local page = template:createPage()
	page:createKeyBinder{
		label             = "Key to toggle GUI on for three minutes.",
		allowCombinations = true,
		variable          = mwse.mcm.createTableVariable{
			id               = "toggleModKey",
			table            = config,
			defaultSetting   = {
				keyCode         = tes3.scanCode.x,
				isAltDown       = true,
				isControlDown   = false,
				isShiftDown     = false,
			}
		}
	}

	EasyMCM.register( template )
end

event.register( "modConfigReady", registerModConfig )
