local claseSkill = include("OtherSkills.components.Skill")


local maxBars = 10


local UI_JJMBarrasHabilidad


local defaultConfig = {}

for i = 1, maxBars do

	table.insert(defaultConfig, -1)

end

table.insert(defaultConfig, 1)
table.insert(defaultConfig, 90)
table.insert(defaultConfig, 150)
table.insert(defaultConfig, 20)
table.insert(defaultConfig, 1)

local config = mwse.loadConfig("Skill bars", defaultConfig)


local listaHabilidades = { {label = "Empty",			value = -1},
			   {label = tes3.getSkillName(0),	value =  0},
			   {label = tes3.getSkillName(1),	value =  1},
			   {label = tes3.getSkillName(2),	value =  2},
			   {label = tes3.getSkillName(3),	value =  3},
			   {label = tes3.getSkillName(4),	value =  4},
			   {label = tes3.getSkillName(5),	value =  5},
			   {label = tes3.getSkillName(6),	value =  6},
			   {label = tes3.getSkillName(7),	value =  7},
			   {label = tes3.getSkillName(8),	value =  8},
			   {label = tes3.getSkillName(9),	value =  9},
			   {label = tes3.getSkillName(10),	value =  10},
			   {label = tes3.getSkillName(11),	value =  11},
			   {label = tes3.getSkillName(12),	value =  12},
			   {label = tes3.getSkillName(13),	value =  13},
			   {label = tes3.getSkillName(14),	value =  14},
			   {label = tes3.getSkillName(15),	value =  15},
			   {label = tes3.getSkillName(16),	value =  16},
			   {label = tes3.getSkillName(17),	value =  17},
			   {label = tes3.getSkillName(18),	value =  18},
			   {label = tes3.getSkillName(19),	value =  19},
			   {label = tes3.getSkillName(20),	value =  20},
			   {label = tes3.getSkillName(21),	value =  21},
			   {label = tes3.getSkillName(22),	value =  22},
			   {label = tes3.getSkillName(23),	value =  23},
			   {label = tes3.getSkillName(24),	value =  24},
			   {label = tes3.getSkillName(25),	value =  25},
			   {label = tes3.getSkillName(26),	value =  26}   }



local function crearBloques(indice)

	local UI_JJMBloqueHabilidad = UI_JJMBarrasHabilidad:createBlock({id=tes3ui.registerID("UI_JJMBloqueHabilidad" .. indice) })
	UI_JJMBloqueHabilidad:destroyChildren()

	UI_JJMBloqueHabilidad.autoWidth = true
	UI_JJMBloqueHabilidad.autoHeight = true
	UI_JJMBloqueHabilidad.flowDirection = "top_to_bottom"
	UI_JJMBloqueHabilidad.visible = false
	
	local UI_JJMBloqueTitulo = UI_JJMBloqueHabilidad:createBlock({id=tes3ui.registerID("UI_JJMBloqueTitulo" .. indice) })
	UI_JJMBloqueTitulo.width = config[maxBars + 3]
	UI_JJMBloqueTitulo.autoHeight = true
	UI_JJMBloqueTitulo.flowDirection = "left_to_right"
	
	local UI_JJMTituloHabilidad = UI_JJMBloqueTitulo:createLabel({ id=tes3ui.registerID("UI_JJMTituloHabilidad" .. indice), text = "Creado" })
	
	local UI_JJMValorHabilidad = UI_JJMBloqueTitulo:createLabel({ id=tes3ui.registerID("UI_JJMValorHabilidad" .. indice), text = "0" })
	UI_JJMValorHabilidad.color = tes3ui.getPalette("disabled_color")
	UI_JJMValorHabilidad.absolutePosAlignX = 1
	
	local UI_JJMBloqueValor = UI_JJMBloqueHabilidad:createBlock({id=tes3ui.registerID("UI_JJMBloqueValor" .. indice) })
	UI_JJMBloqueValor.autoWidth = true
	UI_JJMBloqueValor.autoHeight = true
	UI_JJMBloqueValor.flowDirection = "left_to_right"
	
	UI_JJMBarraHabilidad = UI_JJMBloqueValor:createFillBar{current = 50, max = 100, id = tes3ui.registerID("UI_JJMBarraHabilidad" .. indice)}
	UI_JJMBarraHabilidad.width = config[maxBars + 3]
	UI_JJMBarraHabilidad.height = config[maxBars + 4]
	UI_JJMBarraHabilidad.borderTop = 2
	UI_JJMBarraHabilidad.borderBottom = 3
	UI_JJMBarraHabilidad.widget.showText = config[maxBars + 5]


	UI_JJMBarrasHabilidad:updateLayout()

end




local function barrasMenu()

	UI_JJMBarrasHabilidad = tes3ui.createHelpLayerMenu{ id = tes3ui.registerID("JJMBarrasHabilidad"), fixedFrame = true }
	UI_JJMBarrasHabilidad:destroyChildren()


	UI_JJMBarrasHabilidad.absolutePosAlignX = config[maxBars + 1] / 100.0
	UI_JJMBarrasHabilidad.absolutePosAlignY = config[maxBars + 2] / 100.0
	UI_JJMBarrasHabilidad.color = {0, 0, 0}
	UI_JJMBarrasHabilidad.alpha = 0.0
	UI_JJMBarrasHabilidad.autoWidth = true
	UI_JJMBarrasHabilidad.autoHeight = true
	UI_JJMBarrasHabilidad.flowDirection = "top_to_bottom"
	UI_JJMBarrasHabilidad.visible = false


	for i = 1, maxBars do

		crearBloques(i)

	end

end

event.register("uiActivated", barrasMenu, { filter = "MenuMulti" })
event.register("menuExit", barrasMenu)




local function darValores(indice)

	bloque = UI_JJMBarrasHabilidad:findChild(tes3ui.registerID("UI_JJMBloqueHabilidad" .. indice))

	if bloque then

		if not config[indice] then

			bloque.visible = false
			return

		end


		if config[indice] < 0 then

			bloque.visible = false

		else

			if config[indice] < 27 then

				nombre = tes3.getSkillName(config[indice])
				bloque:findChild(tes3ui.registerID("UI_JJMTituloHabilidad" .. indice)).text = nombre
	
				valor = tes3.mobilePlayer:getSkillValue(config[indice])
				bloque:findChild(tes3ui.registerID("UI_JJMValorHabilidad" .. indice)).text = valor
			
				porcentaje = (tes3.mobilePlayer.skillProgress[config[indice] + 1] / tes3.mobilePlayer:getSkillProgressRequirement(config[indice])) * 100
				bloque:findChild(tes3ui.registerID("UI_JJMBarraHabilidad" .. indice)).widget.current = porcentaje

			end

			if config[indice] >= 27 and
			   config[indice] < 100 then

				for i, habilidad in pairs(listaHabilidades) do

					if habilidad.value == config[indice] then

						identificador = habilidad.label

					end

				end


				local otherSkills = tes3.getPlayerRef().data.otherSkills or {}

				if otherSkills then

					for i, skill in pairs(otherSkills) do

						if skill.id then

							if skill.name == identificador then

								nombre = skill.name
								bloque:findChild(tes3ui.registerID("UI_JJMTituloHabilidad" .. indice)).text = nombre
	
								valor = skill.value
								bloque:findChild(tes3ui.registerID("UI_JJMValorHabilidad" .. indice)).text = valor
							
								porcentaje = skill.progress
								bloque:findChild(tes3ui.registerID("UI_JJMBarraHabilidad" .. indice)).widget.current = porcentaje	

							end

						end

					end

				end			

			end


			if config[indice] >= 100 then

				for i, habilidad in pairs(listaHabilidades) do

					if habilidad.value == config[indice] then

						identificador = habilidad.label

					end

				end


				if claseSkill then

					local otherSkills = claseSkill.getSorted()
	
					if otherSkills then
	
						for i, skill in pairs(otherSkills) do
	
							if skill.id then
	
								if skill.name == identificador then
	
									nombre = skill.name
									bloque:findChild(tes3ui.registerID("UI_JJMTituloHabilidad" .. indice)).text = nombre
		
									valor = skill.value
									bloque:findChild(tes3ui.registerID("UI_JJMValorHabilidad" .. indice)).text = valor
								
									porcentaje = skill:getProgressAsPercentage()
									bloque:findChild(tes3ui.registerID("UI_JJMBarraHabilidad" .. indice)).widget.current = porcentaje	
	
								end
	
							end
	
						end
	
					end

				end

			end


			bloque.visible = true

			if bloque:findChild(tes3ui.registerID("UI_JJMTituloHabilidad" .. indice)).text == "Creado" then

				bloque.visible = false

			end

		end

		UI_JJMBarrasHabilidad.visible = true
		UI_JJMBarrasHabilidad:updateLayout()

	end

end




local function barrasUpdate()

	local bloque

	if (UI_JJMBarrasHabilidad ~= nil and
	    not tes3ui.menuMode()) then

		for i = 1, maxBars do

			darValores(i)

		end

	end

end

event.register("enterFrame", barrasUpdate)





local function ocultarBarras()

	UI_JJMBarrasHabilidad.visible = false
	UI_JJMBarrasHabilidad:updateLayout()

end

event.register("menuEnter", ocultarBarras)


local function mostrarBarras()

	UI_JJMBarrasHabilidad.visible = true
	UI_JJMBarrasHabilidad:updateLayout()


end

event.register("menuExit", mostrarBarras)




local function buscarOtherSkills()

	local contador = 0

	local otherSkills = tes3.getPlayerRef().data.otherSkills or {}

	if otherSkills then

		for i, skill in pairs(otherSkills) do

			if skill.id then

				table.insert(listaHabilidades, {label = skill.name, value = 27 + contador})
				contador = contador + 1

			end

		end

	end

end

event.register("OtherSkills:Ready", buscarOtherSkills)




local function buscarOtherSkillsNuevas()


	if not claseSkill then

		event.unregister("enterFrame", buscarOtherSkillsNuevas)
		return

	end


	local contador = 0

	local otherSkills = claseSkill.getSorted()
	if otherSkills then

		for i, skill in pairs(otherSkills) do

			if skill.id then

				table.insert(listaHabilidades, {label = skill.name, value = 100 + contador})
				contador = contador + 1
				event.unregister("enterFrame", buscarOtherSkillsNuevas)
			end

		end

	end

end

event.register("enterFrame", buscarOtherSkillsNuevas)








local generalCategory

local function crearDesplegables(indice)

	generalCategory:createDropdown{
		label = "Skill " .. indice,
		description = "Select skill " .. indice .. ".",
		options = listaHabilidades,
		variable = mwse.mcm:createTableVariable{id = indice, table = config, restartRequired = no}
	}

end


local function registerMCM()

	local template = mwse.mcm.createTemplate("Skill bars")
	template:saveOnClose("Skill bars", config)
	template:register()


	local pagina = template:createPage({})
	pagina.label = "Skills"
	pagina.description = "Skill bars\n\nSelect skills to show their progress."			

	generalCategory = pagina:createCategory("Skills")


	for i = 1, maxBars do

		crearDesplegables(i)

	end


	local paginaGraficos = template:createPage({})
	paginaGraficos.label = "Graphical options"
	paginaGraficos.description = "Change the position and size of the skill bars."


	graphicCategory = paginaGraficos:createCategory("Graphic")

	indice = maxBars + 1

	paginaGraficos:createSlider({
		label = "Horizontal position, from left to right (default 1%)",
		description = "Horizontal position in %.\nDefault: 1%",
		min = 0,
		max = 100,
		step = 1,
		jump = 5,
		variable = mwse.mcm.createTableVariable{id = indice, table = config },
	})

	indice = indice + 1

	paginaGraficos:createSlider({
		label = "Vertical position, from top to bottom (default 90%)",
		description = "Vertical position in %.\nDefault: 90%",
		min = 0,
		max = 100,
		step = 1,
		jump = 5,
		variable = mwse.mcm.createTableVariable{id = indice, table = config },
	})

	indice = indice + 1

	paginaGraficos:createSlider({
		label = "Bar length (default 150)",
		description = "Length of the skill bar.\nDefault: 150",
		min = 100,
		max = 500,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{id = indice, table = config },
	})

	indice = indice + 1

	paginaGraficos:createSlider({
		label = "Bar height (default 20)",
		description = "Height of the skill bar.\nDefault: 10",
		min = 5,
		max = 20,
		step = 1,
		jump = 2,
		variable = mwse.mcm.createTableVariable{id = indice, table = config },
	})

	indice = indice + 1

	paginaGraficos:createOnOffButton({
		label = "Show numbers on bar (default On)",
		description = "Shows the progress value as a percentage in the bar.\nDefault: On",
		variable = mwse.mcm:createTableVariable{id = indice, table = config},
	})

end

event.register("modConfigReady", registerMCM)


