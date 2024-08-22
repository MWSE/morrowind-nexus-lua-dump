local debug = false
local function debugMessage(string)
	if debug then
		tes3.messageBox(string)
		print("[Demon of Knowledge: DEBUG] " .. string)
	end
end

local common = require("MMM2018.sx2.common")
local faders = {}


local function startFaders()
	local interval = 0.01
	for i,fader in ipairs(faders) do
		timer.start{ type = timer.real, duration = interval, callback = function() fader:fadeIn() end }
		timer.start{ type = timer.real, duration = interval + 1.2, callback = function() fader:fadeOut() end }	
		interval = interval + 1.0
	end
end


local function updateBookText(e)
	startFaders()
	if not common.data.bookState then
		--common.data.bookState = 1
		tes3.playSound({reference = tes3.player, sound = "sx2_ghost"})
		tes3.runLegacyScript({ command = "addTopic \"странная книга\"" })
		
		local mq_01_index = tes3.getJournalIndex({ id = common.journalIds.quest01}) or -1
		local mq_02_index = tes3.getJournalIndex({ id = common.journalIds.quest02}) or -1
		local mq_03_index = tes3.getJournalIndex({ id = common.journalIds.quest03}) or -1
		local mq_04_index = tes3.getJournalIndex({ id = common.journalIds.quest04}) or -1
		local mq_05_index = tes3.getJournalIndex({ id = common.journalIds.quest05}) or -1
		local mq_06_index = tes3.getJournalIndex({ id = common.journalIds.quest06}) or -1
		--Update Journal when you first open the book
		if mq_01_index < 10 then 
			tes3.runLegacyScript({ command = "Journal sx2_mq1 10" })
		end

		--Update text based on Journal status
		local width = 327
		local height = 327
		local openingTextTag = "<DIV ALIGN=\"CENTER\"><FONT COLOR=\"000000\" SIZE=\"3\" FACE=\"Magic Cards\"><BR>"
		local closingTextTag = "<BR><BR><DIV ALIGN=\"LEFT\"><BR><BR>"
		local openingImageTag = "<DIV ALIGN=\"CENTER\"><BR><BR><IMG SRC=\""
		local closingImageTag = "\" WIDTH=\"" .. width .. "\" HEIGHT=\"" .. height .. "\"><BR><BR>"
		local image = ""
		
		debugMessage("mq1: " .. mq_01_index .. ", mq2: " .. mq_02_index .. ", mq3: " .. mq_03_index .. ", mq4: " .. mq_04_index )
		
		local miscImages = {
			"MMM2018/sx2/misc1.dds",
			"MMM2018/sx2/misc2.dds",
			"MMM2018/sx2/misc3.dds",
			"MMM2018/sx2/misc4.dds"
		}
		
		if mq_06_index >= 10 then
			image = "MMM2018/sx2/mq6_10.dds"
		elseif mq_05_index >= 10 then
			image = "MMM2018/sx2/mq5_10.dds"
		elseif mq_04_index >= 40 then
			image = "MMM2018/sx2/mq4_40.dds"
		elseif mq_04_index >= 20 then
			image = "MMM2018/sx2/mq4_20.dds"
		elseif mq_04_index >= 10 then
			image = "MMM2018/sx2/mq4_10.dds"
		elseif mq_03_index >= 30 then
			image = miscImages[ math.random( table.getn( miscImages ) ) ]
		elseif mq_03_index >= 20 then
			image = "MMM2018/sx2/mq3_20.dds"
		elseif mq_01_index >= 60 then
			image = miscImages[ math.random( table.getn( miscImages ) ) ]
		elseif mq_01_index >= 40 then
			image = "MMM2018/sx2/mq1_40.dds"
		elseif mq_01_index >= 15 then
			image = "MMM2018/sx2/mq1_15.dds"
		else
			image = miscImages[ math.random( table.getn( miscImages ) ) ]
		end				
		e.text = openingImageTag .. image .. closingImageTag
		
	end
end

--Start
for i=1, 4 do
	faders[i] = tes3fader.new()
	faders[i]:setTexture("Textures\\mmm2018\\overlay\\tentacleOverlay_0" .. i .. ".dds")
	faders[i]:setColor({ color = { 0.5, 0.5, 0.5 }, flag = false })
	event.register("enterFrame", function() faders[i]:update() end )
end


event.register("bookGetText", updateBookText, { filter = tes3.getObject( common.itemIds.Occulomicon ) } )
