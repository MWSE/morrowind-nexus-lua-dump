local confPath = "lack_autoGreet_config"
local configDefault = {
	enabled = true,
	allowRepeats = false,
	useWhitelist = true,
	verbose = false
}

local config = mwse.loadConfig(confPath, configDefault)

if not config then
    config = { blocked = {} }
end

local gtimer
local enabledButton
local repeatsButton
local whitelistButton
local verboseButton

local seen = {}

-- List of companions known to have commentary on things
-- You can add more if necessary following the same structure ["NPC ID"] = true
-- or you can delete ids you don't want to hear from
-- Some talkative companions, like Vaba-Amus, won't really be compatible with this mod 
-- since most of their commentary is not done through id-filtered greetings (he uses messagebox on other npcs for instance)

local whitelist = {
	["LACK_qac_aaIona"] = true,
	["LACK_qac_aandren"] = true,
	["LACK_qac_AmelieRelm"] = true,
	["LACK_qac_Assassin"] = true,
	["KS_Shani"] = true,
	["KS_Julan"] = true,
	["OR_Vess"] = true,
	["NON_SabrinaCompanion"] = true,
	["aa_comp_constance"] = true,
	["LACK_Telvi"] = true,
	["_Taryn_companion"] = true,
	["JAC_Jasmine"] = true,
	["gp_npc_sara"] = true,
	["AAJohnny_Rains"] = true,
	["AAJohnny_Rains2"] = true,
	["AASynda_Rains"] = true,
	["AASynda_Rains2"] = true,
	["gg_caswyn"] = true,
	["LACK_aaYashga"] = true,
	["NON3_BelialCompanion"] = true
--	["AAkar_winged twilight"] = true does dialog through topics
}

local function validCompanionCheck(actor)
	if (actor == tes3.mobilePlayer) then
		return false
	end

	if config.useWhitelist and ( not whitelist[actor.reference.baseObject.id]) then
		return false
	end

	-- Restrict based on AI package type.
	local allowedPackages = { [tes3.aiPackage.none] = true, [tes3.aiPackage.follow] = true }
	if (not allowedPackages[tes3.getCurrentAIPackageId({ reference = actor })]) then
		return false
	end

	-- Make sure we don't talk to dead actors.
	local animState = actor.actionData.animationAttackState
	if (actor.health.current <= 0 or animState == tes3.animationState.dying or animState == tes3.animationState.dead) then
		return false
	end

	return true
end

local function createMessage(info, n)
	local s = n .. ": " .. info.text
	s = string.gsub(s, "@", "")
	s = string.gsub(s, "#", "")
	s = string.gsub(s, "%%PCName", tes3.player.object.name)

	tes3.messageBox(s)
--	print(s)
end

local function greet()
	if not config.enabled then
		return
	end

	local page0 = tes3.findDialogue({type = tes3.dialogueType.greeting, page = tes3.dialoguePage.greeting.greeting0})
	local page1 = tes3.findDialogue({type = tes3.dialogueType.greeting, page = tes3.dialoguePage.greeting.greeting1})
	local page2 = tes3.findDialogue({type = tes3.dialogueType.greeting, page = tes3.dialoguePage.greeting.greeting2})
	local info

	local talkers = {}

	local i = 0

	for a in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
		if validCompanionCheck(a) then
			info = page0:getInfo({
				actor = a
			})
	
			if info then
				if (info.type == 3) then -- service refusal, try page 1 instead
					info = page1:getInfo({
						actor = a
					})
					if (info.type == 3) then -- sill service refusal, try page 1 instead
						info = page2:getInfo({
							actor = a
						})
					end
				end
				if ( not seen[info.id] or config.allowRepeats ) then
					talkers[i] = { a, info }
					i = i + 1
				end
			end
		end
	end

	if i > 0 then

		if ( config.verbose ) then -- everyone talks
			for _, talker in ipairs(talkers) do
				local a = talker[1]

				info = talker[2]
	
				createMessage(info, a.object.name)
				seen[info.id] = true
			end
		else -- pick one person to talk
			local toTalk = math.random(0, (i - 1))
			toTalk = math.floor(toTalk)
			local a = talkers[toTalk][1]

			info = talkers[toTalk][2]

			createMessage(info, a.object.name)
			seen[info.id] = true
		end

	end
end


local function startTimer()

	if gtimer then
		gtimer:cancel()
	end

	local d = math.random(1,7)
	gtimer = timer.start({
		duration = d,
		callback = greet
	})
end

local function initialized()

	event.register(tes3.event.cellChanged, startTimer)
	event.register(tes3.event.journal, startTimer)
	
	print("[AutoGreet] AutoGreet Initialized")
end

event.register(tes3.event.initialized, initialized)

local function getButtonText(featureString, bool)
	local s
	
	if ( bool ) then
		s = featureString .. " Enabled"
	else
		s = featureString .. " Disabled"
	end
	
	return s
end

local function registerModConfig()

    local mcm = mwse.mcm
    local template = mcm.createTemplate("AutoGreet - Running Commentary")
    template:saveOnClose(confPath, config)

    local page = template:createSideBarPage{
        sidebarComponents = {
            mcm.createInfo{ 
			text = "AutoGreet\n \nBy AlandroSul\n\nAutomatically display companion greetings on cell change and journal update, for more dynamic companion commentary."},
        }
    }
	
    local category = page:createCategory("Settings")

    enabledButton = category:createButton({
	
        buttonText = getButtonText("Mod", config.enabled),
        description = "Toggle the mod's functionality.",
        callback = function(self)
            config.enabled = not config.enabled
			event.unregister(tes3.event.cellChanged, startTimer)
			event.unregister(tes3.event.journal, startTimer)
			
			if ( config.enabled ) then
				enabledButton.buttonText = getButtonText("Mod", config.enabled)
				enabledButton:setText(getButtonText("Mod", config.enabled))
				event.register(tes3.event.cellChanged, startTimer)
				event.register(tes3.event.journal, startTimer)
			else
				enabledButton.buttonText = getButtonText("Mod", config.enabled)
				enabledButton:setText(getButtonText("Mod", config.enabled))
			end
        end
    })
	
	repeatsButton = category:createButton({
	
        buttonText = getButtonText("Repeats", config.allowRepeats),
        description = "Allow or disallow repeats of the same greeting per session. Default: false",
        callback = function(self)
            config.allowRepeats = not config.allowRepeats
			repeatsButton.buttonText = getButtonText("Repeats", config.allowRepeats)
			repeatsButton:setText(getButtonText("Repeats", config.allowRepeats))
        end
    })

	verboseButton = category:createButton({
	
        buttonText = getButtonText("Everyone greets", config.verbose),
        description = "If enabled, every follower will greet. If disabled, a single randomly selected follower will greet. Default: disabled. Enabling can result in too many messageboxes with many followers, as Morrowind only displays 3 at a time.",
        callback = function(self)
            config.verbose = not config.verbose
			verboseButton.buttonText = getButtonText("Everyone greets", config.verbose)
			verboseButton:setText(getButtonText("Everyone greets", config.verbose))
        end
    })

	whitelistButton = category:createButton({
	
        buttonText = getButtonText("Use Whitelist", config.useWhitelist),
        description = "If enabled, autogreeting will be restricted to a defined set of known commentary-heavy mods, to prevent generic followers from greeting. Default: enabled",
        callback = function(self)
            config.useWhitelist = not config.useWhitelist
			whitelistButton.buttonText = getButtonText("Use Whitelist", config.useWhitelist)
			whitelistButton:setText(getButtonText("Use Whitelist", config.useWhitelist))
        end
    })

    mcm.register(template)
end

event.register("modConfigReady", registerModConfig)