local saveData = {}
local function onLoaded()
	if not tes3.player.data.tarhielData then
		tes3.player.data.tarhielData = {}
		saveData = tes3.player.data.tarhielData
		saveData.firstGreet = 0
		saveData.tarhiel = nil
	else
		saveData = tes3.player.data.tarhielData
	end
end
event.register(tes3.event.loaded, onLoaded)

local function infoGetTextCallback(e)
	local dialogue = e.info:findDialogue()
	if e.info and e.info.actor and e.info.actor.id == "agronian guy" and e.info.type == tes3.dialogueType.greeting and tes3.player.cell.region and tes3.player.cell.region.name == "Район Горького Берега" then
		if saveData.firstGreet == 0 then
			saveData.firstGreet = 1
			saveData.tarhiel = e.info.actor.reference
			e.text = "Вы спасли меня! Это невероятно. Я был уверен, что разобьюсь, заклинание сработало не так, как ожидалось. Но я все еще жив... и все благодаря вам. Сам Юлианос послали вас ко мне. Что это, если не знамение. Значит, надо продолжать свои исследования! Я вернусь в Старый Эбенгард... как только соберусь с мыслями. Там есть ОЧЕНЬ высокая башня для моих экспериментов. Удачи вам и еще раз спасибо!"
			tes3.messageBox("Вы получили новую запись в журнале!")
			tes3.addJournalEntry({ text = [[
				<DIV ALIGN="LEFT"><FONT COLOR="000000" SIZE="3" FACE="Magic Cards">
				<BR>На Горьком Берегу мне посчастливилось спасти... падающего босмера. Его зовут Тархиэль и похоже он - волшебник. Видимо, не самый лучший. Он поблагодарил меня и сказал, что вернется в Старый Эбенгард. Может быть в Гильдии Магов поблизости со мной поделятся 'маленьким секретом' - кто это такой...<BR>]], showMessage = false })
		elseif saveData.firstGreet == 1 then
			e.text = "Еще раз, спасибо. Спасибо вам... и спасибо Юлианосу. Я продолжу свои эксперименты в Эбонитовой Башне, только вот, оклемаюсь чуть-чуть... голова кружится."
		end
	elseif e.info and e.info.npcFaction and e.info.npcFaction.id == "Mages Guild" and e.info.type == tes3.dialogueType.topic and dialogue.id == "маленький секрет" and saveData.firstGreet == 1 and (tes3.player.cell.editorName == "Caldera, Guild of Mages" or tes3.player.cell.editorName == "Balmora, Guild of Mages") then
		e.text = "Некоторые говорят, что видели фигуру, которая летела с материка... и летела крайне быстро. А кое-кто из наших утверждает, что это был Тархиэль. Коллеги со Старого Эбенгарда говорят, что кроме ревнивого поклонения Юлианосу, он всегда питал слабость к магии изменения, но в последнее время совсем потерял голову, пытаясь создать заклинание для прыжков на большие расстояние. Может быть, он смог чего-то добиться в Эбонитовой Башне? *Задумчиво смотрит вверх*"
		tes3.messageBox("Вы получили новую запись в журнале!")
		tes3.addJournalEntry({ text = [[
			<DIV ALIGN="LEFT"><FONT COLOR="000000" SIZE="3" FACE="Magic Cards">
			<BR>В Гильдии Магов мне рассказали, что Тархиэль, вероятно, пытался создать мощное заклинание. Может быть стоит наведаться к нему, в Старый Эбенгард. Мне сказали что-то об Эбонитовой Башне, а так же о том, что он очень чтит Юлианоса...<BR>]], showMessage = false })
		saveData.firstGreet = 2
	end
end
event.register(tes3.event.infoGetText, infoGetTextCallback)

local function cellChangedCallback(e)
	if saveData.firstGreet == 1 and saveData.tarhiel ~= nil then
		tes3.positionCell({ reference = saveData.tarhiel, cell = "ToddTest", position = tes3vector3.new(819, 1440, -597) })
		saveData.tarhiel = nil
	end
end
event.register(tes3.event.cellChanged, cellChangedCallback)