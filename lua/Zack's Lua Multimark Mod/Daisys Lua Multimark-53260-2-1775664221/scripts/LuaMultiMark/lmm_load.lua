local load = require("openmw.content")

print("Loading effect")
load.magicEffects.records.multimark_mark = {
    template = load.magicEffects.records['mark'],
    name = 'Greater Mark',
    description = "This effect establishes a target location for the greater recall spell. The location is established directly at the position of the caster when the spell is cast. Multiple locations can be established, depending on skill."
}

--load.spells.records.mark.effects[1].id = "multimark_mark"

load.magicEffects.records.multimark_recall = {
    template = load.magicEffects.records['recall'],
    name = 'Greater Recall',
    description = "The subject of this spell is instantaneously transported to a recall marker set by the Greater Mark spell effect, once selected."
}

--load.spells.records.recall.effects[1].id = "multimark_recall"

load.spells.records.multimark_mark_spell = {
    template = load.spells.records["mark"],
    name = "Greater Mark"
}
load.spells.records.multimark_mark_spell.effects[1].id = "multimark_mark"

load.spells.records.multimark_recall_spell = {
    template = load.spells.records["recall"],
    name = "Greater Recall"
}
load.spells.records.multimark_recall_spell.effects[1].id = "multimark_recall"
