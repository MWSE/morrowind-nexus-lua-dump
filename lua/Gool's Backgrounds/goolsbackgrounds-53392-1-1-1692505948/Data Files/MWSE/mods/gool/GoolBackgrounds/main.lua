local GUI_ID_MenuPersuasion_ServiceList_Tax = nil

-- get the current merBackgrounds data
local function getData()
    local data = tes3.player.data.merBackgrounds or {}
    return data
end

-- Collect Taxes
local function onTaxClick(e)

    local result = tes3ui.getServiceActor()

	if (result.object.baseDisposition < 25) then
		tes3.messageBox("Why would I give you anything?")
		result.object.baseDisposition = result.object.baseDisposition - 5
		return
	end


	local giveCoin = result.object.level * 5
	tes3.addItem({
		reference = tes3.player,
		item = "Gold_001",
		count = giveCoin,
		showMessage = false,
	})
	local begMessage = "Fine, here's " .. tostring(giveCoin) .. " coins."
	tes3.messageBox(begMessage)
	result.object.baseDisposition = result.object.baseDisposition - 5

end

-- start the mod
local function onInit(e)
	local interop = require("mer.characterBackgrounds.interop")

	-- init Assassin
	local assassinDoOnce
    local assassinBackground = {
        id = "assassin",
        name = "Assassin",
        description = (
                      "As a professional hitman, you'll do any dirty job no matter the target. You've just  " ..
                      "completed your last job, the assassination of Ralen Hlaalo, without anyone even " ..
                      "suspecting you. With the key to his manor and 1200 gold from completing the contract, " ..
                      "you are ready to start your life in Morrowind. "
    ),
        doOnce = function()
			mwscript.addItem({
				reference = tes3.player,
				item = "key_hlaalo_manor",
				count = 1
			})
			
			mwscript.addItem{
				reference = tes3.player,
				item = "Gold_001",
				count = 1200
			}
      end
    }
    interop.addBackground(assassinBackground)

	-- init Merchant
	local merchant
    local merchantBackground = {
        id = "merchant",
        name = "Merchant",
        description = (
                      "Trained more in the art of trading than fighting, you gain a large bonus to " ..
                      "Mercantile (+35) but take a -10 in all combat skills. You also start with 3000 " ..
                      "gold from your previous life. "
    ),
        doOnce = function()
			local nonskills = {
				tes3.skill.axe,
				tes3.skill.block,
				tes3.skill.bluntWeapon,
				tes3.skill.conjuration,
				tes3.skill.destruction,
				tes3.skill.handToHand,
				tes3.skill.heavyArmor,
				tes3.skill.lightArmor,
				tes3.skill.longBlade,
				tes3.skill.marksman,
				tes3.skill.mediumArmor,
				tes3.skill.shortBlade,
				tes3.skill.spear,
			}
			
			for _, skill in ipairs(nonskills) do
				tes3.modStatistic({
					reference = tes3.player,
					skill = skill,
					value = -10
				})
			end
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.mercantile,
				value = 35
			})
			mwscript.addItem{
				reference = tes3.player,
				item = "Gold_001",
				count = 3000
			}
      end
    }
    interop.addBackground(merchantBackground)
	

	-- init Prince
	local prince
    local princeBackground = {
        id = "prince",
        name = "Prince",
        description = (
                      "The child of royalty, you've grown accustom to being waited on hand and foot. " ..
                      "You suffer from a lack of strength and endurance (-5), but a life of learning has " ..
                      "given you a bonus (+5) to alchemy, enchanting, mercantile, and security. You also have " ..
                      "1000 gold from your life of wealth. "
    ),
        doOnce = function()
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.strength,
				value = -5
			})
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.endurance,
				value = -5
			})
			local princeSkills = {
				tes3.skill.alchemy,
				tes3.skill.enchant,
				tes3.skill.mercantile,
				tes3.skill.security,
			}
			for _, skill in ipairs(princeSkills) do
				tes3.modStatistic({
					reference = tes3.player,
					skill = skill,
					value = 5
				})
			end
			mwscript.addItem{
				reference = tes3.player,
				item = "Gold_001",
				count = 1000
			}
      end
    }
    interop.addBackground(princeBackground)


	-- init Princess
	local princess
    local princessBackground = {
        id = "princess",
        name = "Princess",
        description = (
                      "The child of royalty, you've grown accustom to being waited on hand and foot. " ..
                      "You suffer from a lack of strength and endurance (-5), but a life of learning has " ..
                      "given you a bonus (+5) to alchemy, enchanting, mercantile, and security. You also have " ..
                      "1000 gold from your life of wealth. "
    ),
        doOnce = function()
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.strength,
				value = -5
			})
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.endurance,
				value = -5
			})
			local princeSkills = {
				tes3.skill.alchemy,
				tes3.skill.enchant,
				tes3.skill.mercantile,
				tes3.skill.security,
			}
			for _, skill in ipairs(princeSkills) do
				tes3.modStatistic({
					reference = tes3.player,
					skill = skill,
					value = 5
				})
			end
			mwscript.addItem{
				reference = tes3.player,
				item = "Gold_001",
				count = 1000
			}
      end
    }
    interop.addBackground(princessBackground)

	-- init Disgraced Ordinator
	local disgracedOrdinator
    local disgracedOrdinatorBackground = {
        id = "disgracedOrdinator",
        name = "Disgraced Ordinator",
        description = (
                      "Your title has been taken from you. You no longer serve The Tribunal. Your reputation " ..
                      "has been tarnished and your willpower is low but your training remains. You take a " ..
                      "penalty to personality and willpower (-10) but gain a bonus to strength and endurance (+10). "
    ),
        doOnce = function()
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.strength,
				value = 10
			})
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.endurance,
				value = 10
			})
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.willpower,
				value = -10
			})
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.personality,
				value = -10
			})
      end
    }
    interop.addBackground(disgracedOrdinatorBackground)
	
	-- init Artisan
	local artisan
    local artisanBackground = {
        id = "artisan",
        name = "Artisan",
        description = (
                      "You've dedicated your life to craftwork and creation. A life of metalworking, brewing, " ..
                      "and construction has given you a +15 in Armorer, Alchemy, and Security, as well as a Master's " ..
                      "Lockpick, Master's Mortar and Pestle, and a Master's Armorer's Hammer. However, all combat " ..
					  "skills are -5."
    ),
        doOnce = function()
			
			local combatSkills = {
				tes3.skill.axe,
				tes3.skill.block,
				tes3.skill.bluntWeapon,
				tes3.skill.conjuration,
				tes3.skill.destruction,
				tes3.skill.handToHand,
				tes3.skill.heavyArmor,
				tes3.skill.lightArmor,
				tes3.skill.longBlade,
				tes3.skill.marksman,
				tes3.skill.mediumArmor,
				tes3.skill.shortBlade,
				tes3.skill.spear,
			}
			local artisanSkills = {
				tes3.skill.security,
				tes3.skill.alchemy,
				tes3.skill.armorer,
			}
			for _, skill in ipairs(artisanSkills) do
				tes3.modStatistic({
					reference = tes3.player,
					skill = skill,
					value = 15
				})
			end
			for _, skill in ipairs(combatSkills) do
				tes3.modStatistic({
					reference = tes3.player,
					skill = skill,
					value = -5
				})
			end
			mwscript.addItem{
				reference = tes3.player,
				item = "apparatus_m_mortar_01",
				count = 1
			}
			mwscript.addItem{
				reference = tes3.player,
				item = "repair_master_01",
				count = 1
			}
			mwscript.addItem{
				reference = tes3.player,
				item = "pick_master",
				count = 1
			}
      end
    }
    interop.addBackground(artisanBackground)

	-- init DremoraPact
	local dremoraPact
    local dremoraPactBackground = {
        id = "dremoraPact",
        name = "Dremora Pact",
        description = (
                      "You made a deal with devil. Start with a Daedric claymore and a +15 Axe. However, " ..
                      "it has cost you some of your sanity (-10 willpower, intelligence, and speechcraft)."
    ),
        doOnce = function()
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.intelligence,
				value = -10
			})
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.willpower,
				value = -10
			})
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.speechcraft,
				value = -10
			})
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.axe,
				value = 15
			})
			mwscript.addItem{
				reference = tes3.player,
				item = "daedric battle axe",
				count = 1
			}
      end
    }
    interop.addBackground(dremoraPactBackground)

	-- init Raised In Carnival
	-- Idea by Glittergear!
	local raisedInCarnival
    local raisedInCarnivalBackground = {
        id = "raisedInCarnival",
        name = "Raised in a Carnival",
        description = (
                      "Raised in a travelling carnival, you travelled in many places and interacted with many " ..
                      "different people from all manner of society. Your Illusion, Acrobatics and Speechcraft are " ..
                      "raised by 10, but your formal education was lacking (-10 intelligence)."
    ),
        doOnce = function()
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.intelligence,
				value = -10
			})
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.illusion,
				value = 10
			})
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.acrobatics,
				value = 10
			})
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.speechcraft,
				value = 10
			})
      end
    }
    interop.addBackground(raisedInCarnivalBackground)

end

event.register("initialized", onInit)