local framework = require("OperatorJack.MagickaExpanded")

tes3.claimSpellEffectId("teleportToAkamora", 293)
tes3.claimSpellEffectId("teleportToFirewatch", 294)
tes3.claimSpellEffectId("teleportToHelnim", 295)
tes3.claimSpellEffectId("teleportToNecrom", 296)
tes3.claimSpellEffectId("teleportToOldEbonheart", 297)
tes3.claimSpellEffectId("teleportToPortTelvannis", 298)

tes3.claimSpellEffectId("teleportToAltBosara", 299)
tes3.claimSpellEffectId("teleportToBalOrya", 300)
tes3.claimSpellEffectId("teleportToGahSadrith", 301)
tes3.claimSpellEffectId("teleportToGorne", 302)
tes3.claimSpellEffectId("teleportToLlothanis", 303)
tes3.claimSpellEffectId("teleportToMarog", 304)
tes3.claimSpellEffectId("teleportToMeralag", 305)
tes3.claimSpellEffectId("teleportToTelAranyon", 306)
tes3.claimSpellEffectId("teleportToTelMothrivra", 307)
tes3.claimSpellEffectId("teleportToTelMuthada", 308)
tes3.claimSpellEffectId("teleportToTelOuada", 309)

local function getDescription(location) return
    "Этот эффект телепортирует субъект в " .. location .. "." end

framework.effects.mysticism.createBasicTeleportationEffect({
    id = tes3.effect.teleportToAkamora,
    name = "Телепорт в Акамору",
    description = getDescription("Акамору"),
    baseCost = 150,
    positionCell = {
        position = tes3vector3.new(249793, -90523, 3039),
        orientation = tes3vector3.new(0, 0, 349),
        cell = "Akamora"
    }
})
framework.effects.mysticism.createBasicTeleportationEffect({
    id = tes3.effect.teleportToFirewatch,
    name = "Телепорт в Файрвотч",
    description = getDescription("Файрвотч"),
    baseCost = 150,
    positionCell = {
        position = tes3vector3.new(150453, 126079, 510),
        orientation = tes3vector3.new(0, 0, 0),
        cell = "Firewatch"
    }
})
framework.effects.mysticism.createBasicTeleportationEffect({
    id = tes3.effect.teleportToHelnim,
    name = "Телепорт в Хелним",
    description = getDescription("Хелним"),
    baseCost = 150,
    positionCell = {
        position = tes3vector3.new(215604, 9145, 647),
        orientation = tes3vector3.new(0, 0, 291),
        cell = "Helnim"
    }
})
framework.effects.mysticism.createBasicTeleportationEffect({
    id = tes3.effect.teleportToNecrom,
    name = "Телепорт в Некром",
    description = getDescription("Некром"),
    baseCost = 150,
    positionCell = {
        position = tes3vector3.new(342132, -85025, 1310),
        orientation = tes3vector3.new(0, 0, 92),
        cell = "Necrom"
    }
})
framework.effects.mysticism.createBasicTeleportationEffect({
    id = tes3.effect.teleportToOldEbonheart,
    name = "Телепорт в Старый Эбенгард",
    description = getDescription("Старый Эбенгард"),
    baseCost = 150,
    positionCell = {
        position = tes3vector3.new(57948, -155684, 710),
        orientation = tes3vector3.new(0, 0, 0),
        cell = "Old Ebonheart"
    }
})
framework.effects.mysticism.createBasicTeleportationEffect({
    id = tes3.effect.teleportToPortTelvannis,
    name = "Телепорт в Порт Тельваннис",
    description = getDescription("Порт Тельваннис"),
    baseCost = 150,
    positionCell = {
        position = tes3vector3.new(343425, 132953, 257),
        orientation = tes3vector3.new(0, 0, 297),
        cell = "Port Telvannis"
    }
})
framework.effects.mysticism.createBasicTeleportationEffect({
    id = tes3.effect.teleportToAltBosara,
    name = "Телепорт в Альт Босару",
    description = getDescription("Альт Босару"),
    baseCost = 150,
    positionCell = {
        position = tes3vector3.new(299317, -33706, 1111),
        orientation = tes3vector3.new(0, 0, 69),
        cell = "Alt Bosara"
    }
})
framework.effects.mysticism.createBasicTeleportationEffect({
    id = tes3.effect.teleportToBalOrya,
    name = "Телепорт в Бал Ориа",
    description = getDescription("Бал Ориа"),
    baseCost = 150,
    positionCell = {
        position = tes3vector3.new(154938, 196334, 302),
        orientation = tes3vector3.new(0, 0, 320),
        cell = "Bal Orya"
    }
})
framework.effects.mysticism.createBasicTeleportationEffect({
    id = tes3.effect.teleportToGahSadrith,
    name = "Телепорт в Га Садрит",
    description = getDescription("Га Садрит"),
    baseCost = 150,
    positionCell = {
        position = tes3vector3.new(344677, 112667, 941),
        orientation = tes3vector3.new(0, 0, 92),
        cell = "Gah Sadrith"
    }
})
framework.effects.mysticism.createBasicTeleportationEffect({
    id = tes3.effect.teleportToGorne,
    name = "Телепорт в Горн",
    description = getDescription("Горн"),
    baseCost = 150,
    positionCell = {
        position = tes3vector3.new(334020, -239395, 444),
        orientation = tes3vector3.new(0, 0, 92),
        cell = "Gorne"
    }
})
framework.effects.mysticism.createBasicTeleportationEffect({
    id = tes3.effect.teleportToLlothanis,
    name = "Телепорт в Ллотанис",
    description = getDescription("Ллотанис"),
    baseCost = 150,
    positionCell = {
        position = tes3vector3.new(263895, 86714, 258),
        orientation = tes3vector3.new(0, 0, 97),
        cell = "Llothanis"
    }
})
framework.effects.mysticism.createBasicTeleportationEffect({
    id = tes3.effect.teleportToMarog,
    name = "Телепорт в Марог",
    description = getDescription("Марог"),
    baseCost = 150,
    positionCell = {
        position = tes3vector3.new(192921, -15703, 1627),
        orientation = tes3vector3.new(0, 0, 303),
        cell = "Marog"
    }
})
framework.effects.mysticism.createBasicTeleportationEffect({
    id = tes3.effect.teleportToMeralag,
    name = "Телепорт в Мералаг",
    description = getDescription("Мералаг"),
    baseCost = 150,
    positionCell = {
        position = tes3vector3.new(211327, -179157, 305),
        orientation = tes3vector3.new(0, 0, 0),
        cell = "Meralag"
    }
})
framework.effects.mysticism.createBasicTeleportationEffect({
    id = tes3.effect.teleportToTelAranyon,
    name = "Телепорт в Тель Араньон",
    description = getDescription("Тель Араньон"),
    baseCost = 150,
    positionCell = {
        position = tes3vector3.new(232546, 102444, 3366),
        orientation = tes3vector3.new(0, 0, 90),
        cell = "Tel Aranyon"
    }
})
framework.effects.mysticism.createBasicTeleportationEffect({
    id = tes3.effect.teleportToTelMothrivra,
    name = "Телепорт в Тель Мотривру",
    description = getDescription("Тель Мотривру"),
    baseCost = 150,
    positionCell = {
        position = tes3vector3.new(277984, 22615, 1160),
        orientation = tes3vector3.new(0, 0, 270),
        cell = "Tel Mothrivra"
    }
})
framework.effects.mysticism.createBasicTeleportationEffect({
    id = tes3.effect.teleportToTelMuthada,
    name = "Телепорт в Тель Мутаду",
    description = getDescription("Тель Мутаду"),
    baseCost = 150,
    positionCell = {
        position = tes3vector3.new(221231, -37731, 2995),
        orientation = tes3vector3.new(0, 0, 46),
        cell = "Tel Muthada"
    }
})
framework.effects.mysticism.createBasicTeleportationEffect({
    id = tes3.effect.teleportToTelOuada,
    name = "Телепорт в Тель Оуаду",
    description = getDescription("Тель Оуаду"),
    baseCost = 150,
    positionCell = {
        position = tes3vector3.new(210154, 147991, 246),
        orientation = tes3vector3.new(0, 0, 303),
        cell = "Tel Ouada"
    }
})
