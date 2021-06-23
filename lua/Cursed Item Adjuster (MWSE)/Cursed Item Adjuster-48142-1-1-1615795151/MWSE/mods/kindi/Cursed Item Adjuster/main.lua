--YOU MAY IMPROVE THIS SCRIPT TO SUIT YOUR NEEDS
-- v1.1

EQ_matchrand = { "Matching summon", "Randomized summon", "Default summon", "Item Value summon", "No summon" }
EQ_matchdetail = { "This will summon a daedra matching the daedric prince, ie. Sheogorath will summon a Golden Saint", "This will summon a random daedra", "This will summon the default daedra (Dremora)", "Summon a daedra based on the cursed item's worth\n Less than 100 gold = Lesser Daedra\n From 100 to 250 gold = Greater Daedra \n More than 250 gold = Powerful Daedra", "Picking up a cursed item will not summon a hostile daedra" }
EQ_type = 1


daedMD = { "dremora", "dremora_lord" } --mehrunes dagon
daedMC = { "ogrim", "ogrim titan" } --malacath
daedSG = { "golden saint" } --sheogorath
daedMB = { "daedroth" } --molag bal
daedAZ = { "winged twilight" } --azura
daedBT = { "hunger" } --boethiah
daedDefault = { "dremora", "dremora_lord", "winged twilight", "scamp", "golden saint", "daedroth", "ogrim", "ogrim titan", "hunger", "clannfear", "atronach_flame", "atronach_frost", "atronach_storm" }
daedGoldRank1 = { "scamp", "hunger", "atronach_flame", "clannfear" }
daedGoldRank2 = { "dremora", "ogrim", "atronach_frost", "daedroth" }
daedGoldRank3 = { "dremora_lord", "winged twilight", "atronach_storm", "golden saint", "ogrim titan" }

local function spawndaedaedra()
local daedra = nil

	if EQ_type == 1 then
	if EQ_sheo then
		--tes3.messageBox("Spawning sheogorath minion")	
	daedra = daedSG[math.random(#daedSG)]
	elseif EQ_mala then
		--tes3.messageBox("Spawning malacath minion")
	daedra = daedMC[math.random(#daedMC)]
	elseif EQ_Mdag then
		--tes3.messageBox("Spawning mehrunes minion")
    daedra = daedMD[math.random(#daedMD)]
	elseif EQ_Mbal then
		--tes3.messageBox("Spawning molag bal minion")
	daedra = daedMB[math.random(#daedMB)]
	elseif EQ_azur then
		--tes3.messageBox("Spawning azura minion")
	daedra = daedAZ[math.random(#daedAZ)]
	elseif EQ_boet then
		--tes3.messageBox("Spawning boethiah minion")
	daedra = daedBT[math.random(#daedBT)]
	daedracount = 2
	else
	daedra = daedDefault[math.random(#daedDefault)]
		--tes3.messageBox("randomed")	
	end
	elseif EQ_type == 2 then
	daedra = daedDefault[math.random(#daedDefault)]
	elseif EQ_type == 3 then
	daedra = "dremora_lord"
	elseif EQ_type == 4 then
	if tvalue < 100 then
	daedra = daedGoldRank1[math.random(#daedGoldRank1)]
	elseif tvalue >= 100 and tvalue < 250 then
	daedra = daedGoldRank2[math.random(#daedGoldRank2)]
	elseif tvalue >= 250 then
	daedra = daedGoldRank3[math.random(#daedGoldRank3)]
	end
		--tes3.messageBox("goldrank")
	elseif EQ_type == 5 then
		--NO SUMMONING
	end
	mwscript.placeAtPC{ reference = tes3.player, object = daedra, direction = 1, distance = 128, count = daedracount }
	EQ_sheo = false
	EQ_Mbal = false
	EQ_Mdag = false
	EQ_mala = false
	EQ_azur = false
	EQ_boet = false
	daedracount = 1
	tvalue = nil
	return false
end

local function findDaed(e) --how can we detect if a cursed item is associated with a particular daedric prince? at least this function did the job the easy way.
	EQ_sheo = false
	EQ_Mbal = false
	EQ_Mdag = false
	EQ_mala = false
	EQ_azur = false
	EQ_boet = false
	daedracount = 1
for ref in e.cell:iterateReferences() do
	if ref.id == "active_dae_sheogorath" or ref.id == "ex_dae_sheogorath" then
	EQ_sheo = true
	--tes3.messageBox("Statue of sheogorath found")
	elseif ref.id == "active_dae_malacath" or ref.id == "ex_dae_malacath" or ref.id == "ex_dae_malacath_attack" then
	EQ_mala = true
	--tes3.messageBox("Statue of malacath found")
	elseif ref.id == "active_dae_molagbal" or ref.id == "ex_dae_molagbal" then
	EQ_Mbal = true
	--tes3.messageBox("Statue of molag bal found")
	elseif ref.id == "active_dae_mehrunes" or ref.id == "ex_dae_mehrunesdagon" then
	EQ_Mdag = true
	--tes3.messageBox("Statue of mehrunes found")
	elseif ref.id == "active_dae_azura" or ref.id == "ex_dae_azura" then
	EQ_azur = true
	--tes3.messageBox("Statue of azura found")
	elseif ref.id == "active_dae_boethiah" or ref.id == "Ex_DAE_Boethiah" then
	EQ_boet = true
	--tes3.messageBox("Statue of boethiah found")	
	end
end
end
event.register("cellChanged", findDaed)




local function cursedobject(t)
	tid = t.target.object.id
	tref = tes3.getReference(tid)
	tvalue = t.target.object.value
	if tref.object.script and tref.object.script.id == "BILL_MarksDaedraSummon" and tref.context.done ~= 1  then
	tref.context.done = 1 --local variable in the cursed item to prevent unlimited summoning
	--tes3.messageBox(tref.object.script.id)
	spawndaedaedra()
	end

end
event.register("activate",cursedobject)


local modConfig = {}
function modConfig.onCreate(container)
    local pane = container:createThinBorder {}
    pane.widthProportional = 1.0
    pane.heightProportional = 1.0
    pane.paddingAllSides = 12
    pane.flowDirection = "top_to_bottom"
    local header = pane:createLabel {}
    header.color = tes3ui.getPalette("header_color")
    header.borderBottom = 25
    header.text = "Cursed Items Adjuster\nversion 1.1"
    local txtBlock = pane:createBlock()
    txtBlock.widthProportional = 1.0
    txtBlock.autoHeight = true
    txtBlock.borderBottom = 25
    local txt = txtBlock:createLabel {}
    txt.wrapText = true
    txt.text = "Adjust how a cursed item will behave when picked up."
    local whenHover = pane:createBlock()
    whenHover.flowDirection = "left_to_right"
    whenHover.widthProportional = 1.0
    whenHover.autoHeight = true
    local hoverLabel = whenHover:createLabel({text = "Type of summoning:"})
	
	local detailBlock = pane:createBlock()
    detailBlock.widthProportional = 1.0
    detailBlock.autoHeight = true
    detailBlock.borderBottom = 25
    local detail = detailBlock:createLabel {}
    detail.wrapText = true
	detail.text = EQ_matchdetail[EQ_type]
	
    local hoverButton =
        whenHover:createButton(
        {text = EQ_matchrand[EQ_type]}
    )
    hoverButton.absolutePosAlignX = 1.0
    hoverButton.paddingTop = 2
    hoverButton.borderRight = 6
    hoverButton:register(
        "mouseClick",
        function(e)
			if EQ_type > 4 then
			EQ_type = 1
			else
            EQ_type = EQ_type + 1
			end
            hoverButton.text =
            EQ_matchrand[EQ_type]
			detail.text = EQ_matchdetail[EQ_type]
        end
    )
    pane:updateLayout()
end

local function registerModConfig()
    mwse.registerModConfig("Cursed Item Adjuster", modConfig)
end
event.register("modConfigReady", registerModConfig)

local function init()
	print("[Cursed Item Adjuster] Initialized")
	mwse.overrideScript("BILL_MarksDaedraSummon", 
	function()
    mwscript.stopScript{script="BILL_MarksDaedraSummon"}
	end	)
end
event.register("initialized", init)


