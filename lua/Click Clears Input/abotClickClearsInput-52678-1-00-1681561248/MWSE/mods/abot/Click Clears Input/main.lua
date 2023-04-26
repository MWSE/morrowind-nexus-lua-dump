--[[
Makes MCM filter/Console text input clear by clicking the input text space.
If you have UIExpansion installed also works with UI Expansion text input filters.
]]

local tes3_uiElementType_textInput = tes3.uiElementType.textInput

local function uiActivated(e)
	if not e.newlyCreated then
		return
	end
	---mwse.log('uiActivated(e) e.element = %s', e.element)
	local parent, children, child
	for el in table.traverse({e.element}) do
		if el.type == tes3_uiElementType_textInput then
			if el.name == 'UIEXP:FiltersearchBlock' then
				parent = el.parent
				children = parent.children
				for i = 1, #children do
					child = children[i]
					---mwse.log('i = %s, child = %s', i, child.name)
					if child.name == 'UIEXP:SearchClearIcon' then
						parent:registerAfter('mouseClick',
							function ()
								---mwse.log('uiActivatedOptions(e) child = %s', child.name)
								child:triggerEvent('mouseClick')
							end
						)
						return
					end
				end
				return
			end
		end
	end
end

local idMenuOptions_MCM_container = tes3ui.registerID('MenuOptions_MCM_container')

local function uiActivatedOptions(e)
	if not e.newlyCreated then
		return
	end
	local elem = e.element
	---mwse.log('uiActivatedOptions(e) e.element = %s', elem)
	elem = elem:findChild(idMenuOptions_MCM_container)
	if not elem then
		return
	end
	---mwse.log('uiActivatedOptions(e) e.element = %s', el.name)
	elem:registerAfter('mouseClick',
		function ()
			---mwse.log('idMenuOptions_MCM_container mouseClick')
			local menu = tes3ui.findMenu('MWSE:ModConfigMenu')
			if not menu then
				return
			end
			---mwse.log('menu = %s', menu.name)
			for el in table.traverse({menu}) do
				if el.type == tes3_uiElementType_textInput then
					if el.name == 'SearchBar' then
						el.parent:registerAfter('mouseClick',
							function ()
								---mwse.log('uiActivatedOptions(e) el = %s', el.name)
								el.text = ''
								el:triggerEvent('textCleared')
							end
						)
						return
					end
				end
			end
		end
	)
end

local function uiActivatedConsole(e)
	if not e.newlyCreated then
		return
	end
	for el in table.traverse({e.element}) do
		if (el.type == tes3_uiElementType_textInput)
		and (not el.disabled)
		and el.visible then
			el.parent:registerAfter('mouseClick',
				function ()
					---mwse.log('uiActivatedConsole(e) el = %s, el.parent = %s', el.name, el.parent.name)
					el.text = ''
					el:triggerEvent('textCleared')
				end
			)
			return
		end
	end
end

event.register('modConfigReady', function ()
	---mwse.log('Click Clears Input/modConfigReady')
	local menusUIE = {
	'MenuBarter',
	'MenuContents',
	'MenuEnchantment',
	'MenuInventory',
	'MenuInventorySelect',
	'MenuMagic',
	'MenuMagicSelect',
	'MenuSpellmaking',
	}
	for i = 1, #menusUIE do
		event.register('uiActivated', uiActivated, {filter = menusUIE[i], priority = -100000})
	end
	event.register('uiActivated', uiActivatedOptions, {filter = 'MenuOptions'})
	event.register('uiActivated', uiActivatedConsole, {filter = 'MenuConsole'})
end,
{priority = -100000--[[, doOnce = true]]}
)

