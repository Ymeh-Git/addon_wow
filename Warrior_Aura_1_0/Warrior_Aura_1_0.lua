local frame = CreateFrame("FRAME")

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("SPELL_UPDATE_USABLE")
frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

-- ==============================================================================
-- CATALOGUE DES SORTS
-- ==============================================================================

-- Sorts proposés dans l'onglet "Sorts & Auras".
-- On utilise les numéros de sort (id) : le jeu nous donne lui-même le nom et l'icône dans la langue du client.
-- Types de déclencheur :
--   "usable"   : affiché dès que le sort est utilisable (comme Vengeance après un blocage/esquive/parade),
--                avec le chrono de recharge tant que l'icône est affichée
--   "cooldown" : affiché quand le sort est prêt (recharge finie + assez de rage),
--                avec un chrono pendant les 5 dernières secondes de recharge (comme Onde de choc)
--   "proc"     : affiché tant qu'une aura est présente sur le joueur (comme Épée et bouclier)
local spellCatalog = {
    { key = "vengeance",    id = 57823, type = "usable" },   -- Vengeance
    { key = "onde",         id = 46968, type = "cooldown" }, -- Onde de choc
    { key = "heurt_proc",   id = 47488, type = "proc", auraId = 50227, suffix = " (Épée et bouclier)" },
    { key = "heurt",        id = 47488, type = "cooldown" }, -- Heurt de bouclier (recharge)
    { key = "charge",       id = 11578, type = "cooldown" }, -- Charge
    { key = "interception", id = 20252, type = "cooldown" }, -- Interception
    { key = "intervention", id = 3411,  type = "cooldown" }, -- Intervention
    { key = "tonnerre",     id = 47502, type = "cooldown" }, -- Coup de tonnerre
    { key = "provocation",  id = 355,   type = "cooldown" }, -- Provocation
    { key = "cridefi",      id = 1161,  type = "cooldown" }, -- Cri de défi
    { key = "coupbouclier", id = 72,    type = "cooldown" }, -- Coup de bouclier
    { key = "renvoi",       id = 23920, type = "cooldown" }, -- Renvoi de sort
    { key = "desarmement",  id = 676,   type = "cooldown" }, -- Désarmement
    { key = "commotion",    id = 12809, type = "cooldown" }, -- Coup traumatisant
    { key = "lancer",       id = 57755, type = "cooldown" }, -- Lancer héroïque
    { key = "blocage",      id = 2565,  type = "cooldown" }, -- Maîtrise du blocage
    { key = "mur",          id = 871,   type = "cooldown" }, -- Mur protecteur
    { key = "rempart",      id = 12975, type = "cooldown" }, -- Dernier rempart
}

-- On complète chaque sort avec son nom et son icône, et on les range aussi par clé
local spellsByKey = {}
for _, spell in ipairs(spellCatalog) do
    local name, _, icon = GetSpellInfo(spell.id)
    spell.name = name or ("Sort " .. spell.id)
    spell.icon = icon or "Interface\\Icons\\INV_Misc_QuestionMark"
    spell.label = spell.name .. (spell.suffix or "")
    spellsByKey[spell.key] = spell
end

-- ==============================================================================
-- LES 3 POSITIONS À L'ÉCRAN
-- ==============================================================================

-- oldSoundKey : ancienne clé des sons (avant le choix des sorts), pour garder les réglages existants
local slots = {
    { key = "gauche", label = "Gauche", x = -150, y = 0,   default = "vengeance",  oldSoundKey = "vengeance" },
    { key = "haut",   label = "Haut",   x = 0,    y = 150, default = "heurt_proc", oldSoundKey = "heurt" },
    { key = "droite", label = "Droite", x = 150,  y = 0,   default = "onde",       oldSoundKey = "onde" },
}

-- Le sort choisi pour une position (sauvegardé dans Warrior_Aura_1_0_DB.slotSpells, sinon le sort par défaut)
-- Lecture seule : on ne crée pas Warrior_Aura_1_0_DB ici, car cette fonction peut être appelée avant son chargement
local function GetSlotSpell(slot)
    local saved = Warrior_Aura_1_0_DB and Warrior_Aura_1_0_DB.slotSpells and Warrior_Aura_1_0_DB.slotSpells[slot.key]
    return spellsByKey[saved] or spellsByKey[slot.default]
end

-- ==============================================================================
-- AURAS (grandes images lumineuses autour du personnage, comme l'addon Cheese)
-- ==============================================================================

local auraFolder = "Interface\\AddOns\\Warrior_Aura_1_0\\Textures\\Auras\\"

-- vertical = true : image faite pour les côtés (128 x 256)
-- vertical = false : image faite pour le haut (256 x 128)
-- Une image peut aller sur n'importe quelle position : on la tourne si besoin
local auraCatalog = {
    { file = "Sword_and_Board",     vertical = true },
    { file = "Sudden_Death",        vertical = true },
    { file = "Blood_Surge",         vertical = true },
    { file = "Arcane_Missiles",     vertical = true },
    { file = "Art_of_War",          vertical = true },
    { file = "Blood_Boil",          vertical = true },
    { file = "Brain_Freeze",        vertical = true },
    { file = "Daybreak",            vertical = true },
    { file = "Feral_OmenOfClarity", vertical = true },
    { file = "Focus_Fire",          vertical = true },
    { file = "GenericArc_01",       vertical = true },
    { file = "GenericArc_02",       vertical = true },
    { file = "GenericArc_03",       vertical = true },
    { file = "GenericArc_04",       vertical = true },
    { file = "GenericArc_05",       vertical = true },
    { file = "GenericArc_06",       vertical = true },
    { file = "Grand_Crusader",      vertical = true },
    { file = "Hot_Streak",          vertical = true },
    { file = "Imp_Empowerment",     vertical = true },
    { file = "Killing_Machine",     vertical = true },
    { file = "Molten_Core",         vertical = true },
    { file = "Natures_Grace",       vertical = true },
    { file = "Nightfall",           vertical = true },
    { file = "Sudden_Doom",         vertical = true },
    { file = "Surge_of_Light",      vertical = true },
    { file = "Backlash",            vertical = false },
    { file = "Berserk",             vertical = false },
    { file = "Dark_Transformation", vertical = false },
    { file = "Denounce",            vertical = false },
    { file = "Frozen_Fingers",      vertical = false },
    { file = "Fulmination",         vertical = false },
    { file = "Fury_of_Stormrage",   vertical = false },
    { file = "GenericTop_01",       vertical = false },
    { file = "GenericTop_02",       vertical = false },
    { file = "Hand_of_Light",       vertical = false },
    { file = "Impact",              vertical = false },
    { file = "Lock_and_Load",       vertical = false },
    { file = "Maelstrom_Weapon",    vertical = false },
    { file = "Master_Marksman",     vertical = false },
    { file = "Necropolis",          vertical = false },
    { file = "Rime",                vertical = false },
    { file = "Serendipity",         vertical = false },
    { file = "Shooting_Stars",      vertical = false },
    { file = "Slice_and_Dice",      vertical = false },
}

-- On complète chaque aura avec son nom affiché et son chemin, et on les range aussi par fichier
local aurasByFile = {}
for _, aura in ipairs(auraCatalog) do
    aura.label = gsub(aura.file, "_", " ")
    aura.path = auraFolder .. aura.file
    aurasByFile[aura.file] = aura
end

-- L'aura choisie pour une position (sauvegardée dans Warrior_Aura_1_0_DB.slotAuras), ou nil pour afficher l'icône du sort
-- Lecture seule, comme GetSlotSpell
local function GetSlotAura(slot)
    local saved = Warrior_Aura_1_0_DB and Warrior_Aura_1_0_DB.slotAuras and Warrior_Aura_1_0_DB.slotAuras[slot.key]
    return aurasByFile[saved]
end

-- ==============================================================================
-- CHOIX DES SONS
-- ==============================================================================

-- Liste des sons proposés (le 1er est le son d'origine, utilisé par défaut)
local soundChoices = {
    { label = "Alerte raid",  file = "Sound\\Interface\\RaidWarning.wav" },
    { label = "Appel prêt",   file = "Sound\\Interface\\ReadyCheck.wav" },
    { label = "Ping carte",   file = "Sound\\Interface\\MapPing.wav" },
    { label = "Réveil",       file = "Sound\\Interface\\AlarmClockWarning3.wav" },
    { label = "Drapeau JcJ",  file = "Sound\\Spells\\PVPFlagTaken.wav" },
    { label = "Niveau gagné", file = "Sound\\Interface\\LevelUp.wav" },
}

-- Le son choisi pour chaque position (numéro dans soundChoices) est sauvegardé dans Warrior_Aura_1_0_DB.
-- On ne lit Warrior_Aura_1_0_DB qu'en jeu (jamais au chargement du fichier), quand le jeu l'a déjà chargé.
local function GetSoundChoice(slotKey)
    Warrior_Aura_1_0_DB = Warrior_Aura_1_0_DB or {}
    Warrior_Aura_1_0_DB.sounds = Warrior_Aura_1_0_DB.sounds or {}
    return Warrior_Aura_1_0_DB.sounds[slotKey] or 1
end

local function SetSoundChoice(slotKey, index)
    GetSoundChoice(slotKey) -- S'assure que Warrior_Aura_1_0_DB.sounds existe
    Warrior_Aura_1_0_DB.sounds[slotKey] = index
end

-- Une position peut être mise en muet (sauvegardé dans Warrior_Aura_1_0_DB.mute)
local function IsSlotMuted(slotKey)
    return Warrior_Aura_1_0_DB and Warrior_Aura_1_0_DB.mute and Warrior_Aura_1_0_DB.mute[slotKey] or false
end

local function SetSlotMuted(slotKey, muted)
    Warrior_Aura_1_0_DB = Warrior_Aura_1_0_DB or {}
    Warrior_Aura_1_0_DB.mute = Warrior_Aura_1_0_DB.mute or {}
    Warrior_Aura_1_0_DB.mute[slotKey] = muted
end

-- Joue le son choisi pour une position ("gauche", "haut" ou "droite"), sauf si elle est en muet
local function PlaySlotSound(slotKey)
    if IsSlotMuted(slotKey) then return end
    local choice = soundChoices[GetSoundChoice(slotKey)] or soundChoices[1]
    PlaySoundFile(choice.file)
end

-- ==============================================================================
-- CRÉATION DES VISUELS (UI)
-- ==============================================================================

-- Fonction générique pour créer l'image d'une position à l'écran
local function CreateAuraFrame(xOffset, yOffset)
    -- On crée un cadre parent au centre de l'écran
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(64, 64) -- Taille de l'icône (tu peux ajuster : 48, 64, 80...)
    f:SetPoint("CENTER", UIParent, "CENTER", xOffset, yOffset)
    f:Hide() -- On le cache par défaut

    -- On lui ajoute une texture (l'image du sort, choisie plus tard)
    local icon = f:CreateTexture(nil, "BACKGROUND")
    icon:SetAllPoints(f)

    -- On rend l'image légèrement transparente pour ne pas bloquer la vue (0 = invisible, 1 = opaque)
    icon:SetAlpha(0.7)
    f.icon = icon

    -- On crée une zone de texte pour le chrono (vide par défaut)
    local text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    text:SetPoint("CENTER", f, "CENTER", 0, 0)
    text:SetTextColor(1, 1, 0) -- Couleur du texte : Jaune
    f.text = text

    return f
end

-- Taille des auras : comme Cheese, une image de 128 x 256 réduite à 80 %
local auraShortSide, auraLongSide = 102, 205

-- Oriente l'image d'une aura selon la position : on la retourne en miroir ou on la tourne d'un quart de tour
-- (SetTexCoord avec 8 valeurs : coins haut-gauche, bas-gauche, haut-droite, bas-droite de l'image)
local function SetAuraTexCoord(texture, vertical, slotKey)
    if slotKey == "haut" then
        if vertical then
            texture:SetTexCoord(0, 1, 1, 1, 0, 0, 1, 0) -- Quart de tour dans le sens des aiguilles d'une montre
        else
            texture:SetTexCoord(0, 1, 0, 1) -- Image faite pour le haut : telle quelle
        end
    elseif slotKey == "gauche" then
        if vertical then
            texture:SetTexCoord(0, 1, 0, 1) -- Image faite pour la gauche : telle quelle
        else
            texture:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1) -- Quart de tour dans le sens inverse
        end
    else -- droite
        if vertical then
            texture:SetTexCoord(1, 0, 0, 1) -- Miroir de l'image de gauche
        else
            texture:SetTexCoord(0, 1, 1, 1, 0, 0, 1, 0) -- Quart de tour dans le sens des aiguilles d'une montre
        end
    end
end

-- Met l'image choisie (aura ou icône du sort) sur la position et remet son état à zéro
local function ApplySlotSpell(slot)
    local visual = slot.visual
    local aura = GetSlotAura(slot)

    if aura then
        -- Aura : grande image, allongée sur les côtés et couchée en haut
        if slot.key == "haut" then
            visual:SetSize(auraLongSide, auraShortSide)
        else
            visual:SetSize(auraShortSide, auraLongSide)
        end
        visual.icon:SetTexture(aura.path)
        SetAuraTexCoord(visual.icon, aura.vertical, slot.key)
        visual.icon:SetAlpha(1)
    else
        -- Icône du sort, légèrement transparente
        visual:SetSize(64, 64)
        visual.icon:SetTexture(GetSlotSpell(slot).icon)
        visual.icon:SetTexCoord(0, 1, 0, 1)
        visual.icon:SetAlpha(0.7)
    end

    -- Taille de base, gardée pour la pulsation
    visual.baseWidth, visual.baseHeight = visual:GetWidth(), visual:GetHeight()
    slot.pulseTime = nil

    visual.text:SetText("")
    visual:SetAlpha(0) -- Invisible : le fondu d'arrivée partira de 0
    visual:Hide()
    slot.wantShown = false
    slot.active = false
end

-- ==============================================================================
-- FONDU ET PULSATION
-- ==============================================================================

local FADE_DURATION = 0.25 -- Durée du fondu d'arrivée et de départ (en secondes)
local PULSE_PERIOD = 1     -- Durée d'une pulsation complète (en secondes)
local PULSE_AMOUNT = 0.08  -- L'image grossit jusqu'à +8 % pendant la pulsation

-- Mode test : actif tant que l'onglet "Sorts & Auras" est ouvert (affichage seul, sans son)
local previewMode = false

-- Demande l'affichage d'une position : l'image apparaît en fondu
local function ShowVisual(slot)
    slot.wantShown = true
    slot.visual:Show()
end

-- Demande de cacher une position : l'image disparaît en fondu, puis le cadre est caché
local function HideVisual(slot)
    slot.wantShown = false
end

-- Fait avancer le fondu d'une position (appelé à chaque image du jeu)
local function UpdateFade(slot, elapsed)
    local visual = slot.visual
    local alpha = visual:GetAlpha()
    if slot.wantShown then
        if alpha < 1 then
            visual:SetAlpha(math.min(1, alpha + elapsed / FADE_DURATION))
        end
    elseif visual:IsShown() then
        alpha = alpha - elapsed / FADE_DURATION
        if alpha <= 0 then
            visual:SetAlpha(0)
            visual:Hide()
        else
            visual:SetAlpha(alpha)
        end
    end
end

-- Fait pulser l'image (elle grossit puis revient à sa taille) tant que le chrono s'affiche
local function UpdatePulse(slot, elapsed, counting)
    local visual = slot.visual
    if counting then
        slot.pulseTime = (slot.pulseTime or 0) + elapsed
        local scale = 1 + PULSE_AMOUNT / 2 * (1 - math.cos(slot.pulseTime * 2 * math.pi / PULSE_PERIOD))
        visual:SetSize(visual.baseWidth * scale, visual.baseHeight * scale)
    elseif slot.pulseTime then
        -- Fin du chrono : on remet la taille normale
        slot.pulseTime = nil
        visual:SetSize(visual.baseWidth, visual.baseHeight)
    end
end

-- On crée les 3 positions autour du centre : gauche (-150), haut (150), droite (150)
for _, slot in ipairs(slots) do
    slot.visual = CreateAuraFrame(slot.x, slot.y)
    slot.active = false
    ApplySlotSpell(slot)
end

-- Temps de recharge restant d'un sort (nil s'il n'est pas en recharge)
local function GetCooldownLeft(spellName)
    local start, duration = GetSpellCooldown(spellName)
    -- duration > 1.5 permet d'ignorer le "Global Cooldown" (GCD) de 1.5s
    -- On ne veut afficher le chrono que si c'est le VRAI temps de recharge du sort
    if start and start > 0 and duration > 1.5 then
        local timeLeft = (start + duration) - GetTime()
        if timeLeft > 0 then return timeLeft end
    end
    return nil
end

-- Les chronomètres de toutes les positions.
-- Les icônes sont cachées pendant la recharge (et un cadre caché n'exécute pas son OnUpdate),
-- donc on utilise un cadre séparé, toujours actif, qui gère les chronos et affiche l'icône au bon moment
local slotTimer = CreateFrame("Frame")
slotTimer:SetScript("OnUpdate", function(self, elapsed)
    -- Mode test (onglet "Sorts & Auras" ouvert) : les 3 images restent affichées, sans chrono
    if previewMode then
        for _, slot in ipairs(slots) do
            ShowVisual(slot)
            slot.visual.text:SetText("")
            UpdateFade(slot, elapsed)
            UpdatePulse(slot, elapsed, false)
        end
        return
    end

    for _, slot in ipairs(slots) do
        local spell = GetSlotSpell(slot)
        local visual = slot.visual
        local timeLeft = GetCooldownLeft(spell.name)
        local counting = false -- Le chrono est-il affiché ? (pour la pulsation)

        if spell.type == "usable" then
            -- Chrono complet tant que l'icône est affichée (comportement de Vengeance)
            if visual:IsShown() then
                visual.text:SetText(timeLeft and math.ceil(timeLeft) or "") -- math.ceil arrondit à l'entier supérieur
                counting = (timeLeft ~= nil)
            end

        elseif spell.type == "cooldown" then
            -- Chrono uniquement pendant les 5 dernières secondes (comportement d'Onde de choc)
            if timeLeft and timeLeft <= 5 then
                ShowVisual(slot)
                visual.text:SetText(math.ceil(timeLeft))
                counting = true
            else
                visual.text:SetText("")
                -- On ne cache l'icône que si le sort n'est pas prêt (sinon c'est CheckSpells qui la gère)
                if not slot.active then
                    HideVisual(slot)
                end
            end
        end

        UpdateFade(slot, elapsed)
        UpdatePulse(slot, elapsed, counting)
    end
end)

-- ==============================================================================
-- LOGIQUE ET DÉCLENCHEURS (EVENTS)
-- ==============================================================================

local function HasPlayerAura(auraId)
    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, _, spellId = UnitAura("player", i)
        if not name then break end
        if spellId == auraId then return true end
    end
    return false
end

-- Le sort doit-il être annoncé maintenant ?
local function IsSpellReady(spell)
    if spell.type == "proc" then
        return HasPlayerAura(spell.auraId)
    end

    local usable, noMana = IsUsableSpell(spell.name)
    if spell.type == "usable" then
        return usable or noMana
    end

    -- "cooldown" : assez de rage et recharge terminée
    local start, duration = GetSpellCooldown(spell.name)
    return usable and start and (start == 0 or duration <= 1.5)
end

-- silent = true : met à jour l'affichage sans jouer de son (utilisé à la sortie du mode test)
local function CheckSpells(silent)
    if previewMode then return end -- En mode test, c'est l'affichage de test qui a la main

    local _, classFilename = UnitClass("player")
    if classFilename ~= "WARRIOR" then return end

    for _, slot in ipairs(slots) do
        if IsSpellReady(GetSlotSpell(slot)) then
            if not slot.active then
                ShowVisual(slot)
                if not silent then
                    PlaySlotSound(slot.key) -- Petit son d'alerte
                end
                slot.active = true
            end
        else
            if slot.active then
                HideVisual(slot)
                slot.active = false
            end
        end
    end
end

-- À la connexion (Warrior_Aura_1_0_DB est alors chargé) : on reprend les réglages sauvegardés
local function LoadSavedSettings()
    Warrior_Aura_1_0_DB = Warrior_Aura_1_0_DB or {}
    Warrior_Aura_1_0_DB.sounds = Warrior_Aura_1_0_DB.sounds or {}
    Warrior_Aura_1_0_DB.slotSpells = Warrior_Aura_1_0_DB.slotSpells or {}

    local sounds = Warrior_Aura_1_0_DB.sounds
    for _, slot in ipairs(slots) do
        -- Les sons étaient avant rangés par sort : on les reprend pour la position correspondante
        if sounds[slot.key] == nil and sounds[slot.oldSoundKey] ~= nil then
            sounds[slot.key] = sounds[slot.oldSoundKey]
        end
        ApplySlotSpell(slot)
    end
    for _, slot in ipairs(slots) do
        sounds[slot.oldSoundKey] = nil
    end
end

frame:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_LOGIN" then
        LoadSavedSettings()
        return
    end
    if event == "UNIT_AURA" and unit ~= "player" then return end
    CheckSpells()
end)

-- Démarre le mode test : les 3 images s'affichent en continu, sans son
local function StartPreview()
    previewMode = true
end

-- Arrête le mode test : on cache tout, puis on réaffiche en silence ce qui est vraiment disponible
local function StopPreview()
    previewMode = false
    for _, slot in ipairs(slots) do
        slot.active = false
        HideVisual(slot)
    end
    CheckSpells(true)
end

-- Change le sort d'une position
local function SetSlotSpell(slot, spellKey)
    Warrior_Aura_1_0_DB = Warrior_Aura_1_0_DB or {}
    Warrior_Aura_1_0_DB.slotSpells = Warrior_Aura_1_0_DB.slotSpells or {}
    Warrior_Aura_1_0_DB.slotSpells[slot.key] = spellKey
    ApplySlotSpell(slot)
    CheckSpells()
end

-- Change l'aura d'une position (nil = revenir à l'icône du sort)
local function SetSlotAura(slot, auraFile)
    Warrior_Aura_1_0_DB = Warrior_Aura_1_0_DB or {}
    Warrior_Aura_1_0_DB.slotAuras = Warrior_Aura_1_0_DB.slotAuras or {}
    Warrior_Aura_1_0_DB.slotAuras[slot.key] = auraFile
    ApplySlotSpell(slot)
    CheckSpells()
end

-- ==============================================================================
-- FENÊTRE D'OPTIONS
-- ==============================================================================

local optionsFrame = CreateFrame("Frame", "Warrior_Aura_1_0_OptionsFrame", UIParent)
optionsFrame:SetSize(510, 290)
optionsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
optionsFrame:SetFrameStrata("DIALOG")
optionsFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
})
optionsFrame:Hide() -- Cachée par défaut
tinsert(UISpecialFrames, "Warrior_Aura_1_0_OptionsFrame") -- Fermeture avec la touche Échap

-- Déplacer la fenêtre en la faisant glisser (clic gauche maintenu)
optionsFrame:EnableMouse(true)
optionsFrame:SetMovable(true)
optionsFrame:SetClampedToScreen(true) -- La fenêtre ne peut pas sortir de l'écran
optionsFrame:RegisterForDrag("LeftButton")
optionsFrame:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)
optionsFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    -- On sauvegarde la position dans Warrior_Aura_1_0_DB
    local point, _, relativePoint, x, y = self:GetPoint()
    Warrior_Aura_1_0_DB = Warrior_Aura_1_0_DB or {}
    Warrior_Aura_1_0_DB.optionsPosition = { point = point, relativePoint = relativePoint, x = x, y = y }
end)

-- À l'ouverture, on remet la fenêtre à sa dernière position sauvegardée
optionsFrame:SetScript("OnShow", function(self)
    local pos = Warrior_Aura_1_0_DB and Warrior_Aura_1_0_DB.optionsPosition
    if pos then
        self:ClearAllPoints()
        self:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    end
end)

local optionsTitle = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
optionsTitle:SetPoint("TOP", optionsFrame, "TOP", 0, -20)
optionsTitle:SetText("Warrior_Aura_1_0")

-- Petite croix en haut à droite pour fermer
local optionsClose = CreateFrame("Button", nil, optionsFrame, "UIPanelCloseButton")
optionsClose:SetPoint("TOPRIGHT", optionsFrame, "TOPRIGHT", -6, -6)

-- Chaque onglet est une "page" qui occupe toute la fenêtre ; on n'en affiche qu'une à la fois
local soundPage = CreateFrame("Frame", nil, optionsFrame)
soundPage:SetAllPoints(optionsFrame)

local spellPage = CreateFrame("Frame", nil, optionsFrame)
spellPage:SetAllPoints(optionsFrame)
spellPage:Hide()

-- ------------------------------------------------------------------------------
-- Onglet "Sons"
-- ------------------------------------------------------------------------------

local soundDropDowns = {} -- soundDropDowns[clé de la position] = menu déroulant du son
local muteCheckboxes = {} -- muteCheckboxes[clé de la position] = case "Muet"

-- Affiche le son choisi et l'état "Muet" de chaque position
local function RefreshSoundPage()
    for _, slot in ipairs(slots) do
        local choice = soundChoices[GetSoundChoice(slot.key)] or soundChoices[1]
        UIDropDownMenu_SetText(soundDropDowns[slot.key], choice.label)
        muteCheckboxes[slot.key]:SetChecked(IsSlotMuted(slot.key))
    end
end

-- Une colonne par position : titre, menu déroulant du son et case "Muet"
for col, slot in ipairs(slots) do
    -- Centre de la colonne : colonnes de 160 de large, celle du milieu au centre de la fenêtre
    local centerX = (col - 2) * 160

    -- Titre centré au-dessus de la colonne
    local header = soundPage:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    header:SetPoint("TOP", soundPage, "TOP", centerX, -80)
    header:SetText(slot.label)

    -- Menu déroulant centré sur la colonne
    local dropDown = CreateFrame("Frame", "Warrior_Aura_1_0_SoundDropDown_" .. slot.key, soundPage, "UIDropDownMenuTemplate")
    dropDown:SetPoint("TOP", soundPage, "TOP", centerX, -100)
    UIDropDownMenu_SetWidth(dropDown, 120)
    UIDropDownMenu_Initialize(dropDown, function(self, level)
        for i, sound in ipairs(soundChoices) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = sound.label
            info.checked = (GetSoundChoice(slot.key) == i)
            info.func = function()
                SetSoundChoice(slot.key, i)
                RefreshSoundPage()
                CloseDropDownMenus()
                PlaySoundFile(sound.file) -- Aperçu du son choisi
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    soundDropDowns[slot.key] = dropDown

    -- Case "Muet" : la case + son texte font environ 56 de large, on commence 28 à gauche du centre
    local mute = CreateFrame("CheckButton", "Warrior_Aura_1_0_Mute_" .. slot.key, soundPage, "UICheckButtonTemplate")
    mute:SetSize(24, 24)
    mute:SetPoint("TOPLEFT", soundPage, "TOP", centerX - 28, -140)
    _G[mute:GetName() .. "Text"]:SetText("Muet")
    mute:SetScript("OnClick", function(self)
        SetSlotMuted(slot.key, self:GetChecked() and true or false)
    end)
    muteCheckboxes[slot.key] = mute
end

soundPage:SetScript("OnShow", RefreshSoundPage)

-- Bouton pour remettre toutes les positions sur le son par défaut (Alerte raid) et enlever le muet
local defaultSoundButton = CreateFrame("Button", nil, soundPage, "UIPanelButtonTemplate")
defaultSoundButton:SetSize(180, 22)
defaultSoundButton:SetPoint("BOTTOM", soundPage, "BOTTOM", 0, 18)
defaultSoundButton:SetText("Paramètres par défaut")
defaultSoundButton:SetScript("OnClick", function()
    for _, slot in ipairs(slots) do
        SetSoundChoice(slot.key, 1)
        SetSlotMuted(slot.key, false)
    end
    RefreshSoundPage()
    PlaySoundFile(soundChoices[1].file) -- Aperçu du son par défaut
end)

-- ------------------------------------------------------------------------------
-- Onglet "Sorts & Auras"
-- ------------------------------------------------------------------------------

-- Les menus de cet onglet restent ouverts après un clic (keepShownOnClick), pour enchaîner les essais.
-- Le jeu ne met alors pas à jour les coches tout seul : cette fonction coche uniquement l'élément choisi
-- dans les listes ouvertes (chaque élément porte sa valeur dans arg1).
local function UpdateOpenMenuChecks(selected)
    for level = 1, 2 do
        local list = _G["DropDownList" .. level]
        if list and list:IsShown() then
            for i = 1, (list.numButtons or 0) do
                local button = _G["DropDownList" .. level .. "Button" .. i]
                if button and button.arg1 ~= nil then
                    local isSelected = (button.arg1 == selected)
                    button.checked = isSelected
                    if isSelected then
                        _G[button:GetName() .. "Check"]:Show()
                    else
                        _G[button:GetName() .. "Check"]:Hide()
                    end
                end
            end
        end
    end
end

local spellIcons = {}     -- spellIcons[clé de la position] = icône du sort choisi
local spellDropDowns = {} -- spellDropDowns[clé de la position] = menu déroulant du sort
local auraDropDowns = {}  -- auraDropDowns[clé de la position] = menu déroulant de l'aura

-- Affiche l'icône et le nom du sort choisi, et l'aura choisie, pour chaque position
local function RefreshSpellPage()
    for _, slot in ipairs(slots) do
        local spell = GetSlotSpell(slot)
        spellIcons[slot.key]:SetTexture(spell.icon)
        UIDropDownMenu_SetText(spellDropDowns[slot.key], spell.label)
        local aura = GetSlotAura(slot)
        UIDropDownMenu_SetText(auraDropDowns[slot.key], aura and aura.label or "Icône du sort")
    end
end

-- Les deux familles d'auras, en sous-menus pour que la liste ne soit pas trop longue
local auraGroups = {
    { label = "Auras des côtés", vertical = true },
    { label = "Auras du haut",   vertical = false },
}

-- Une colonne par position : son nom, l'icône du sort choisi, un menu pour le sort et un menu pour l'aura
for col, slot in ipairs(slots) do
    -- Centre de la colonne : colonnes de 160 de large, celle du milieu au centre de la fenêtre
    local centerX = (col - 2) * 160

    -- Titre, icône et menu déroulant centrés sur la colonne
    local header = spellPage:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    header:SetPoint("TOP", spellPage, "TOP", centerX, -80)
    header:SetText(slot.label)

    local icon = spellPage:CreateTexture(nil, "ARTWORK")
    icon:SetSize(48, 48)
    icon:SetPoint("TOP", spellPage, "TOP", centerX, -105)
    spellIcons[slot.key] = icon

    local dropDown = CreateFrame("Frame", "Warrior_Aura_1_0_SpellDropDown_" .. slot.key, spellPage, "UIDropDownMenuTemplate")
    dropDown:SetPoint("TOP", spellPage, "TOP", centerX, -165)
    UIDropDownMenu_SetWidth(dropDown, 120)
    UIDropDownMenu_Initialize(dropDown, function(self, level)
        for _, spell in ipairs(spellCatalog) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = spell.label
            info.icon = spell.icon
            info.checked = (GetSlotSpell(slot).key == spell.key)
            info.arg1 = spell.key
            info.keepShownOnClick = true -- Le menu reste ouvert après le clic
            info.func = function()
                SetSlotSpell(slot, spell.key)
                RefreshSpellPage()
                UpdateOpenMenuChecks(spell.key)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    spellDropDowns[slot.key] = dropDown

    -- Menu de l'aura : "Icône du sort", puis deux sous-menus (auras des côtés / auras du haut)
    local auraDropDown = CreateFrame("Frame", "Warrior_Aura_1_0_AuraDropDown_" .. slot.key, spellPage, "UIDropDownMenuTemplate")
    auraDropDown:SetPoint("TOP", spellPage, "TOP", centerX, -200)
    UIDropDownMenu_SetWidth(auraDropDown, 120)
    UIDropDownMenu_Initialize(auraDropDown, function()
        local level = UIDROPDOWNMENU_MENU_LEVEL or 1
        local current = GetSlotAura(slot)

        if level == 1 then
            local info = UIDropDownMenu_CreateInfo()
            info.text = "Icône du sort"
            info.checked = (current == nil)
            info.arg1 = "none"
            info.keepShownOnClick = true -- Le menu reste ouvert après le clic
            info.func = function()
                SetSlotAura(slot, nil)
                RefreshSpellPage()
                UpdateOpenMenuChecks("none")
            end
            UIDropDownMenu_AddButton(info, 1)

            for _, group in ipairs(auraGroups) do
                info = UIDropDownMenu_CreateInfo()
                info.text = group.label
                info.value = group.vertical and "vertical" or "horizontal"
                info.hasArrow = true      -- Ouvre un sous-menu au survol
                info.notCheckable = true
                UIDropDownMenu_AddButton(info, 1)
            end

        elseif level == 2 then
            local wantVertical = (UIDROPDOWNMENU_MENU_VALUE == "vertical")
            for _, aura in ipairs(auraCatalog) do
                if aura.vertical == wantVertical then
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = aura.label
                    info.checked = (current == aura)
                    info.arg1 = aura.file
                    info.keepShownOnClick = true -- Le menu reste ouvert après le clic
                    info.func = function()
                        SetSlotAura(slot, aura.file)
                        RefreshSpellPage()
                        UpdateOpenMenuChecks(aura.file)
                    end
                    UIDropDownMenu_AddButton(info, 2)
                end
            end
        end
    end)
    auraDropDowns[slot.key] = auraDropDown
end

-- Tant que l'onglet est ouvert, les images sont affichées en test (sans son) pour régler le visuel
spellPage:SetScript("OnShow", function()
    RefreshSpellPage()
    StartPreview()
end)
spellPage:SetScript("OnHide", StopPreview) -- Aussi appelé quand on ferme la fenêtre

-- Bouton pour remettre les sorts d'origine (Vengeance, Heurt de bouclier, Onde de choc) et les icônes
local defaultSpellButton = CreateFrame("Button", nil, spellPage, "UIPanelButtonTemplate")
defaultSpellButton:SetSize(180, 22)
defaultSpellButton:SetPoint("BOTTOM", spellPage, "BOTTOM", 0, 18)
defaultSpellButton:SetText("Paramètres par défaut")
defaultSpellButton:SetScript("OnClick", function()
    for _, slot in ipairs(slots) do
        SetSlotSpell(slot, slot.default)
        SetSlotAura(slot, nil)
    end
    RefreshSpellPage()
end)

-- ------------------------------------------------------------------------------
-- Boutons d'onglets
-- ------------------------------------------------------------------------------

local soundTab = CreateFrame("Button", nil, optionsFrame, "UIPanelButtonTemplate")
soundTab:SetSize(140, 22)
soundTab:SetPoint("TOP", optionsFrame, "TOP", -75, -45)
soundTab:SetText("Sons")

local spellTab = CreateFrame("Button", nil, optionsFrame, "UIPanelButtonTemplate")
spellTab:SetSize(140, 22)
spellTab:SetPoint("TOP", optionsFrame, "TOP", 75, -45)
spellTab:SetText("Sorts & Auras")

-- Affiche une page et met en surbrillance le bouton de l'onglet actif
local function SelectTab(page)
    CloseDropDownMenus()
    soundPage:Hide()
    spellPage:Hide()
    page:Show()
    if page == soundPage then
        soundTab:LockHighlight()
        spellTab:UnlockHighlight()
    else
        spellTab:LockHighlight()
        soundTab:UnlockHighlight()
    end
end

soundTab:SetScript("OnClick", function() SelectTab(soundPage) end)
spellTab:SetScript("OnClick", function() SelectTab(spellPage) end)
soundTab:LockHighlight() -- L'onglet "Sons" est affiché à l'ouverture

optionsFrame:SetScript("OnHide", function() CloseDropDownMenus() end) -- Ferme un menu resté ouvert

-- ==============================================================================
-- BOUTON DE LA MINIMAP
-- ==============================================================================

local minimapButton = CreateFrame("Button", "Warrior_Aura_1_0_MinimapButton", Minimap)
minimapButton:SetSize(31, 31)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetFrameLevel(Minimap:GetFrameLevel() + 10) -- Au-dessus des éléments de la minimap
minimapButton:EnableMouse(true)
minimapButton:RegisterForClicks("LeftButtonUp")
minimapButton:RegisterForDrag("LeftButton")
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

-- Place le bouton sur le bord de la minimap selon un angle (0 = droite, 90 = haut, 270 = bas)
local function SetMinimapButtonAngle(angle)
    local rad = math.rad(angle)
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", math.cos(rad) * 80, math.sin(rad) * 80)
end
SetMinimapButtonAngle(250) -- En bas à gauche de la minimap, zone libre par défaut

-- À la connexion (Warrior_Aura_1_0_DB est alors chargé), on remet le bouton à sa dernière position sauvegardée
minimapButton:RegisterEvent("PLAYER_LOGIN")
minimapButton:SetScript("OnEvent", function(self)
    if Warrior_Aura_1_0_DB and Warrior_Aura_1_0_DB.minimapAngle then
        SetMinimapButtonAngle(Warrior_Aura_1_0_DB.minimapAngle)
    end
end)

-- Glisser le bouton pour le déplacer autour de la minimap
minimapButton:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        px, py = px / scale, py / scale
        local angle = math.deg(math.atan2(py - my, px - mx))
        SetMinimapButtonAngle(angle)

        -- On sauvegarde la position dans Warrior_Aura_1_0_DB
        Warrior_Aura_1_0_DB = Warrior_Aura_1_0_DB or {}
        Warrior_Aura_1_0_DB.minimapAngle = angle
    end)
end)
minimapButton:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
end)

-- L'icône de l'addon sur la minimap
local minimapIcon = minimapButton:CreateTexture(nil, "ARTWORK")
minimapIcon:SetSize(20, 20)
minimapIcon:SetPoint("TOPLEFT", minimapButton, "TOPLEFT", 6, -5)
minimapIcon:SetTexture("Interface\\Icons\\Ability_warrior_defensivestance")
minimapIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- On rogne les bords de l'icône

-- La bordure dorée ronde, comme les autres boutons de la minimap
local minimapBorder = minimapButton:CreateTexture(nil, "OVERLAY")
minimapBorder:SetSize(53, 53)
minimapBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
minimapBorder:SetPoint("TOPLEFT", minimapButton, "TOPLEFT", 0, 0)

-- Un clic ouvre ou ferme la fenêtre
minimapButton:SetScript("OnClick", function()
    if optionsFrame:IsShown() then
        optionsFrame:Hide()
    else
        optionsFrame:Show()
    end
end)
