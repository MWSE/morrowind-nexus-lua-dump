local this = {}

this.new = function(name)      -- функция, создающая новое окно и возвращающая нам его данные

	local m = {                    -- данные нашего нового окна
	 id = tes3ui.registerID(name),
	 ltext = ' Enter: ',
	 block = {[1] = ''},
	}
	m.menu = tes3ui.createMenu{id = m.id, fixedFrame = true}
	m.menu.alpha = 1.0             -- нулевая прозрачность

	m.show = function()            -- отобразить окно
	  m.menu:updateLayout()
	  tes3ui.enterMenuMode(m.id)
	end

	m.hide = function()            -- спрятать окно
	  if not tes3ui.findMenu(m.id) then return end
	  m.menu:destroy()
	  if tes3ui.menuMode then tes3ui.leaveMenuMode() end
	end
	
	--[[ Добавить блок
	* n - номер блока
	* width - ширина блока
	* ltext - необязательный текст надписи
	* mih - мин. высота блока
	--]]
	m.addBlock = function(n, width, ltext, mih)
	  m.block[n] = m.menu:createBlock{}
	  m.block[n].width = width or 360
	  m.block[n].autoHeight = true
	  m.block[n].minHeight = mih or nil
	  m.block[n].childAlignX = 0.5
	  m.block[n].childAlignY = 0.5
	  m.block[n].flowDirection = 'top_to_bottom'
	  
	  if ltext then -- если указан 3 параметр - текст надписи, то добавляем её
		m.block[n]:createLabel {text = ltext}
	  end
	end
	
	--[[ Добавить в блок номер n кнопку
	n - номер блока
	buttext - текст кнопки
	func - функция срабатывающая при нажатии кнопки
	bpw - ширина кнопки(не работает если указана позиция кнопки)
	ay - позиция кнопки по Y
	ax - позиция кнопки по X
	--]]
	m.addBlockButton = function(n, buttext, func, bwp, ay, ax)  -- добавить в блок номер n кнопку с текстом buttext
	  local button = m.block[n]:createButton
	  {
		id = tes3ui.registerID(buttext),
		text = buttext
	  }
	  --button.minWidth = 50
	  button.widthProportional = bwp or nil
	  button.absolutePosAlignY = ay or nil
	  button.absolutePosAlignX = ax or nil
	  button.minHeight = 22
	  button:register("mouseClick", func)  -- при нажатии на кнопку будет вызываться функция func
	end
	
	m.addScrollPane = function(n, width)  -- добавить скрол-панель в блок с номером n
		local ThinBorder = m.block[n]:createThinBorder{}
		ThinBorder.flowDirection = "top_to_bottom"
		ThinBorder.width = width or 150
		ThinBorder.height = height or 200
		ThinBorder.childAlignX = 0.5
		ThinBorder.childAlignY = 0.5
		
		paneList = ThinBorder:createVerticalScrollPane{}
		paneList.widthProportional = 1.0
		paneList.height = height or 200
	end

	m.addScrollPaneBtn = function(buttext, func) --Добавляем кнопку в список

		local paneButton = paneList:createButton
		{
			id = tes3ui.registerID(buttext),
			text = buttext
		}
		paneButton:register("mouseClick", func)  -- при нажатии на кнопку будет вызываться функция func
	end

	m.addScrollPaneTxt = function(buttext, func) --Добавляем текстовую кнопку в список

		local paneTextSelect = paneList:createTextSelect
		{
			id = tes3ui.registerID(buttext),
			text = buttext
		}
		paneTextSelect:register("mouseClick", func)  -- при нажатии на кнопку будет вызываться функция func
	end
	
	m.ScrollPaneSort = function() --Добавляем текстовую кнопку в список

		paneList:getContentElement():sortChildren(function(a, b)
			return a.text < b.text
		end)
	end
	
  return m  -- возвращаем созданную таблицу с данными и функциями для нашего нового окна
end

return this