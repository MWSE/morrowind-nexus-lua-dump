local util = require('openmw.util')
local core = require('openmw.core')
local ambient = require('openmw.ambient')
local storage = require('openmw.storage')
local ui = require('openmw.ui')

local I = require('openmw.interfaces')

I.Settings.registerPage {
    key = 'FoxyJumpscare',
    l10n = 'FoxyJumpscare',
    name = 'Foxy Jumpscare',
    description = 'Random chance for Withered Foxy to jumpscare you',
}
I.Settings.registerGroup {
    key = 'SettingsFoxyJumpscare',
    page = 'FoxyJumpscare',
    l10n = 'FoxyJumpscareSettings',
    name = 'Settings',
    permanentStorage = false,
    settings = {
        {
            key = 'Enabled',
            renderer = 'checkbox',
            name = 'Enable Mod',
            description = 'Enable or disable the jumpscares',
            default = true,
        },
        {
            key = 'Chance',
            renderer = 'number',
            name = 'Jumpscare Chance',
            description = 'Chance every second that you get jumpscared, one in X',
            default = 10000,
        },
    },
}

local playerSettings = storage.playerSection('SettingsFoxyJumpscare')

local frame = 0
local timer = 0
local active = false
local frameInterval = 1 / 24

local chanceTimer = 0
local chanceInterval = 1

local texturePaths = {
    "textures/384.png",
    "textures/385.png",
    "textures/386.png",
    "textures/388.png",
	"textures/389.png",
    "textures/390.png",
    "textures/391.png",
    "textures/392.png",
	"textures/393.png",
    "textures/394.png",
    "textures/395.png",
    "textures/396.png",
	"textures/397.png",
    "textures/398.png",
}

local function jumpscare()
    frame = 0
    timer = 0
    active = true
	
	jumpTex = ui.texture{path = texturePaths[1]}
	
    jumpFrame=ui.create({
		layer = 'HUD',  
		type = ui.TYPE.Image,  
		props = {
			relativeSize = util.vector2(1, 1),
			resource = jumpTex
		}
	})
	
    ambient.playSoundFile("Sound\\Xscream2.wav", {volume=100.0})
end

local function onUpdate(dt)
    if playerSettings:get('Enabled') == true then
        chanceTimer = chanceTimer + dt

        if chanceTimer >= chanceInterval then
            chanceTimer = chanceTimer - chanceInterval
            if math.random(playerSettings:get('Chance')) == 1 and not active then
                jumpscare()
            end
        end

        if active then
            timer = timer + dt
            while timer >= frameInterval and frame < 14 do
                timer = timer - frameInterval
                frame = frame + 1
				
				jumpTex = ui.texture{path = texturePaths[frame]}
				jumpFrame.layout.props.resource = jumpTex
                jumpFrame:update()
            end
            if frame >= 14 then
                active = false
				jumpFrame:destroy()
            end
        end
    else
        
    end
end

local function onInit()


end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onInit = onInit,
    }
}
