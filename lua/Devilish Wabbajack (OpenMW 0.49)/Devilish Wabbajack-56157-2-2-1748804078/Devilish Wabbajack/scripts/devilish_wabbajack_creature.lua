local self  = require('openmw.self')
local types = require('openmw.types')
local time  = require('openmw_aux.time')
local core  = require('openmw.core')
local AI    = require('openmw.interfaces').AI

--------------------------------------------------------------------
-- Hilfsfunktion: führt genau EINEN Wabba-Effekt pro Aktivierung aus
--------------------------------------------------------------------
local doOnce = false      -- Zurücksetzen, sobald Spell nicht mehr aktiv

local function castWabbaEffect()
    -- Zufalls­zahl 1-9  (Option 7 ist die neue „Skalengruppe“)
local WEIGHTED_OPTIONS = {
    -- high-probability picks
    1,1,       -- option 1  (×10)
    2,              -- option 2  (×7)
    3,3,          -- option 3  (×9)
    4,4,            -- option 5  (×8)
    5,              -- option 7  (×7)
    6,
    7,7, -- option 8  (×5)
    8,
                        -- option 6  (×1)
}

    local option = WEIGHTED_OPTIONS[math.random(#WEIGHTED_OPTIONS)]
    ----------------------------------------------------------------
    -- 1   Schrumpfen + tödlicher Witz
    -- 2   Unsichtbarkeit
    -- 3   Paralyse
    -- 4   Hearth Heal
    -- 5   Health = 10 Punkte
    -- 6   Calm + Fight = 0
    -- 7   ► Größenlogik (Shrink / Enlarge / Grow / Normalize)
    -- 9   Daedric Bite         (ehemals 10, weil 8 entfällt)
    ----------------------------------------------------------------

    ----------------------------------------------------------------
    --  Option 1
    ----------------------------------------------------------------
    if option == 1 then
        core.sendGlobalEvent("detd_WabbaEvent",         { obj = self })
        core.sendGlobalEvent("detd_SmallifyActorWabba", { obj2 = self })
        types.Actor.stats.dynamic.fatigue(self).current = 0
        types.Actor.stats.dynamic.health (self).current = 0
        types.Actor.spells(self):add('detd_wabbakillinvis')

    ----------------------------------------------------------------
    --  Option 2
    ----------------------------------------------------------------
    elseif option == 2 then
        types.Actor.activeSpells(self):add{ id = 'invisibility', effects = { 0 } }

    ----------------------------------------------------------------
    --  Option 3
    ----------------------------------------------------------------
    elseif option == 3 then
        types.Actor.activeSpells(self):add{ id = 'Paralysis', effects = { 0 } }

    ----------------------------------------------------------------
    --  Option 4
    ----------------------------------------------------------------
    elseif option == 4 then
        types.Actor.activeSpells(self):add{ id = 'hearth heal', effects = { 0 } }

    ----------------------------------------------------------------
    --  Option 5
    ----------------------------------------------------------------
    elseif option == 5 then
        types.Actor.stats.dynamic.health(self).current = 10

    ----------------------------------------------------------------
    --  Option 6
    ----------------------------------------------------------------
    elseif option == 6 then
        types.Actor.stats.ai.fight(self).base = 0
        types.Actor.activeSpells(self):add{ id = 'detd_wabbacalm', effects = { 0 } }
        AI.removePackages("Combat")

    ----------------------------------------------------------------
    --  Option 7  –––>  deine kombinierte Größen-Logik
    ----------------------------------------------------------------
    elseif option == 7 then
        local s = self.scale

        --  a) Unter 0,30  →  GROW
        if s < 0.30 then
            core.sendGlobalEvent('detd_StartGradualGrow', { obj = self })

        --  b) Über 1,20  →  NORMALIZE
        elseif s > 1.20 then
            core.sendGlobalEvent('detd_StartGradualNormalize', { obj = self })

        --  c) Zwischen 0,90 – 1,10  →  50 % Shrink  /  50 % Enlarge
        elseif s >= 0.90 and s <= 1.10 then
            if math.random() < 0.5 then
                core.sendGlobalEvent('detd_StartGradualShrink',  { obj = self })
            else
                core.sendGlobalEvent('detd_StartGradualEnlarge', { obj = self })
            end
        --  d) alle Zwischen­bereiche (0,30-0,90  bzw. 1,10-1,20) bleiben ohne Effekt
        end

    ----------------------------------------------------------------
    --  Option 9  (ehemals 10)
    ----------------------------------------------------------------
    elseif option == 8 then
        types.Actor.activeSpells(self):add{ id = 'daedric bite', effects = { 0 } }
    end
end

----------------------------------------------------------
--  Poll-Schleife alle 0,1 s: prüft, ob Spell aktiv ist
----------------------------------------------------------
time.runRepeatedly(function()
    local hasWabba = types.Actor.activeSpells(self):isSpellActive('detd_wabbajack_staff')

    if hasWabba and not doOnce then
        castWabbaEffect()
        doOnce = true                    -- erst nach dem ersten Tick
    elseif not hasWabba then
        doOnce = false                   -- Spell vorbei → zurücksetzen
    end
end, 0.1 * time.second)
