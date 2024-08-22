--[[
	apocryphaFader
	
		When in Apocrypha, apply a faint purple vignette fader
]]--

local apocFader = nil

local function enableFader(e)
	if tes3.getPlayerCell().id:find("Apocrypha")then
		apocFader:activate()
		apocFader:fadeTo({ value = 1.0, duration = 0.01 })
	else
		apocFader:deactivate()
	end
end

local function faderSetup()
    -- Create the tentacle fader.
    apocFader = tes3fader.new()
	event.register("cellChanged", enableFader)
    apocFader:setTexture("Textures\\mmm2018\\overlay\\apocryphaFader.dds")
	apocFader:setColor({ color = { 0.5, 0.5, 0.5 }, flag = false })
	
    event.register("enterFrame", function()
        apocFader:update()
    end)
		
end
event.register("fadersCreated", faderSetup)