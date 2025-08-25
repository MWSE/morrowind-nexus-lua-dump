return function (challengeFilter)
	
	if hud_challengeTracker then
		hud_challengeTracker:destroy()
		hud_challengeTracker = nil
	end
	
	local challengeCount = 0
	for challengeId, value in pairs(saveData.challenges or {}) do
		if value < 3 then
			challengeCount = challengeCount + 1
		end
	end
	if challengeCount == 0 then return end
	
	
	local makeBorder = require("scripts.Roguelite.ui_makeborder") 
	local borderOffset = 1
	local borderFile = "thin"
	hudAlpha = math.max(hudAlpha,1)
	local function getColorFromGameSettings(colorTag)
		local result = core.getGMST(colorTag)
		if not result then
			return util.color.rgb(1,1,1)
		end
		local rgb = {}
		for color in string.gmatch(result, '(%d+)') do
			table.insert(rgb, tonumber(color))
		end
		if #rgb ~= 3 then
			print("UNEXPECTED COLOR: rgb of size=", #rgb)
			return util.color.rgb(1, 1, 1)
		end
		return util.color.rgb(rgb[1] / 255, rgb[2] / 255, rgb[3] / 255)
	end
	local function mixColors(color1, color2)
		return util.color.rgb((color1.r+color2.r)*0.5, (color1.g+color2.g)*0.5, (color1.b+color2.b)*0.5)
	end
	local fontColor = getColorFromGameSettings("FontColor_color_normal_over")
	local darkerFont = util.color.rgb(fontColor.r*0.7,fontColor.g*0.7,fontColor.b*0.7)
	local fontSize = 20
	local background = ui.texture { path = 'black' }
	
	-- Morrowind-inspirierte Farben
	local morrowindGold = getColorFromGameSettings("FontColor_color_normal")
	local morrowindBrown = util.color.rgb(0.4, 0.3, 0.2)
	
	
	local function textElement(str, color)
		return { 
			type = ui.TYPE.Text,
			props = {
				textColor = color or fontColor,
				textShadow = true,
				textShadowColor = util.color.rgba(0,0,0,0.9),
				textAlignV = ui.ALIGNMENT.Center,
				textAlignH = ui.ALIGNMENT.Center,
				text = " "..str.." ",
				textSize = fontSize,
				autoSize = true
			},
		}
	end
	
	--root
	hud_challengeTracker = ui.create({
		type = ui.TYPE.Container,
		layer = 'HUD',
		name = "hud_challengeTracker",
		template = borderTemplate,
		props = {
			relativePosition = v2(1,0.5),
			anchor = v2(1,0.5),
		},
		content = ui.content {
	
		}
	})
	
	local flex = {
		type = ui.TYPE.Flex,
		layer = 'HUD',
		name = 'mainFlex',
		props = {
			autoSize = true,
			arrange = ui.ALIGNMENT.End,
		},
		content = ui.content {
		}
	}
	hud_challengeTracker.layout.content:add(flex)
	local penaltyMult = 1
	if (runDB:get(saveData.runId) or 0) > 0 then
		--print("Roguelite Hardcore Penalty","*",playerSection:get("DYING_PENALTY"))
		if playerSection:get("PENALTY_PER_DEATH") then
			penaltyMult = (1 + runDB:get(saveData.runId) * playerSection:get("DYING_PENALTY") / 100)
		else
			penaltyMult = (1 + playerSection:get("DYING_PENALTY") / 100)
		end
	end
	
	local sortedIds = {}
	for challengeId, _ in pairs(saveData.challenges or {}) do
		table.insert(sortedIds, challengeId)
	end
	table.sort(sortedIds)
	
	
	local shownChallenges = 0
	--for challengeId, value in pairs(saveData.challenges or {}) do
	for _, challengeId in ipairs(sortedIds) do
		local value = saveData.challenges[challengeId]
		if value < 3 and not challengeFilter or challengeFilter == challengeId then
			shownChallenges = shownChallenges + 1
		end
	end
	if shownChallenges > 0 and (runDB:get(saveData.runId) or 0) > 0 then
		local titleContainer = {
			type = ui.TYPE.Flex,
			props = {
				autoSize = true,
				arrange = ui.ALIGNMENT.Center,
				horizontal = true,
			},
			content = ui.content {}
		}
		flex.content:add(titleContainer)
		-- Spacer für Einrückung
		
		-- Challenge Icon
			titleContainer.content:add{
				type = ui.TYPE.Image,
				props = {
					resource = ui.texture { path = "textures/roguelite/deaths.png" },
					size = v2(fontSize+5, fontSize+5),
					--alpha = math.max(0,1-value/3),
				}
			}
			titleContainer.content:add{ props = { size = v2(2, 1) } }
		
		titleContainer.content:add{
			type = ui.TYPE.Text,
			props = {
				text = (runDB:get(saveData.runId) or 0) .. " ",
				textColor = mixColors(fontColor, morrowindGold),
				textShadow = true,
				textShadowColor = util.color.rgba(0,0,0,1),
				textSize = fontSize-2 ,
				textAlignH = ui.ALIGNMENT.Start,
				textAlignV = ui.ALIGNMENT.Start,
				autoSize = true,
				--alpha = math.max(0,1-value/3),
			},
		}
	end
			
	--for challengeId, value in pairs(saveData.challenges or {}) do
	for _, challengeId in ipairs(sortedIds) do
		local value = saveData.challenges[challengeId]
		if value < 3 and not challengeFilter or challengeFilter == challengeId then
		--for challengeId in pairs(challengeData) do
			local challenge = challengeData[challengeId]
			local titleContainer = {
				type = ui.TYPE.Flex,
				props = {
					autoSize = true,
					arrange = ui.ALIGNMENT.Center,
					horizontal = true,
				},
				content = ui.content {}
			}
			flex.content:add(titleContainer)
			-- Spacer für Einrückung
			
			-- Challenge Icon
			if challenge.icon then
				titleContainer.content:add{
					type = ui.TYPE.Image,
					props = {
						resource = ui.texture { path = challenge.hudIcon },
						size = v2(fontSize+5, fontSize+5),
						alpha = math.max(0,1-value/3),
					}
				}
				titleContainer.content:add{ props = { size = v2(2, 1) } }
			end
			titleContainer.content:add{
				type = ui.TYPE.Text,
				props = {
					text = challenge.name .. " ",
					textColor = mixColors(fontColor, morrowindGold),
					textShadow = true,
					textShadowColor = util.color.rgba(0,0,0,1),
					textSize = fontSize ,
					textAlignH = ui.ALIGNMENT.Start,
					textAlignV = ui.ALIGNMENT.Start,
					autoSize = true,
					alpha = math.max(0,1-value/3),
				},
			}
			--flex.content:add{ props = { size = v2(1, 1) * 2 } }
			local challengeRequirement = challenge.requirement * playerSection:get("CHALLENGE_DIFFICULTY")

			challengeRequirement = math.max(1,challengeRequirement * penaltyMult)
			
			challengeRequirement = math.floor(challengeRequirement+0.5)
			if challenge.fixRequirement then
				challengeRequirement = challenge.requirement
			end
			local alpha = 1
			-- check if quest is completed

			if value == 0 then
				if (saveData.progress[challengeId] or 0) >= challengeRequirement then
					saveData.challenges[challengeId] = 1
					value = 1
					saveData.completedChallenges = saveData.completedChallenges + 1
					print(saveData.completedChallenges ,">", (runDB:get(saveData.runId.."completedChallenges") or 0))
					if saveData.completedChallenges > (runDB:get(saveData.runId.."completedChallenges") or 0) and saveData.completedChallenges % playerSection:get("CHALLENGES_TARGET") == 0
					and (saveData.completedChallenges <= playerSection:get("CHALLENGES_TARGET") or not playerSection:get("ONE_UNLOCK_PER_RUN")) then
						runDB:set("UNLOCKED_BLESSINGS", (runDB:get("UNLOCKED_BLESSINGS") or 0) + 1)
						print("unlocked a blessing!")
						ui.showMessage("Unlocked a blessing!")
						runDB:set(saveData.runId.."completedChallenges", saveData.completedChallenges)
					end
				end
			elseif value >= 1 then
				saveData.challenges[challengeId] = value + 1
			end
			if value >=1 then
				flex.content:add{
					type = ui.TYPE.Text,
					props = {
						text = "Completed ",
						textColor = util.color.rgb(0.2,0.8,0.2),
						textShadow = true,
						textShadowColor = util.color.rgba(0,0,0,1),
						textSize = fontSize - 2,
						textAlignH = ui.ALIGNMENT.Start,
						textAlignV = ui.ALIGNMENT.Start,
						autoSize = true,
						alpha = math.max(0,1-value/3),
					},
				}
			else
				flex.content:add{
					type = ui.TYPE.Text,
					props = {
						text = (saveData.progress[challengeId] or 0) .." / "..challengeRequirement.." ",
						textColor = morrowindGold,
						textShadow = true,
						textShadowColor = util.color.rgba(0,0,0,1),
						textSize = fontSize - 2,
						textAlignH = ui.ALIGNMENT.Start,
						textAlignV = ui.ALIGNMENT.Start,
						autoSize = true,
					},
				}
			end
			flex.content:add{ props = { size = v2(1, 1) * 5 } }
		end
	end

end