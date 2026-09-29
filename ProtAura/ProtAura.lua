local frame = CreateFrame("FRAME")

frame:RegisterEvent("SPELL_UPDATE_USABLE")
frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

local spellVengeance = "Vengeance"
local spellOndeDeChoc = "Onde de choc"
local spellIdEpeeEtBouclier = 50227

local isVengeanceActive = false
local isOndeActive = false
local isHeurtActive = false

-- ==============================================================================
-- CRÉATION DES VISUELS (UI)
-- ==============================================================================

-- Fonction générique pour créer l'image d'un sort à l'écran
local function CreateAuraFrame(spellName, xOffset, yOffset)
    -- On crée un cadre parent au centre de l'écran
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(64, 64) -- Taille de l'icône (tu peux ajuster : 48, 64, 80...)
    f:SetPoint("CENTER", UIParent, "CENTER", xOffset, yOffset)
    f:Hide() -- On le cache par défaut

    -- On lui ajoute une texture (l'image)
    local icon = f:CreateTexture(nil, "BACKGROUND")
    icon:SetAllPoints(f)
    
    -- On récupère l'image officielle du sort dans les fichiers du jeu
    local _, _, texture = GetSpellInfo(spellName)
    icon:SetTexture(texture)
    
    -- On rend l'image légèrement transparente pour ne pas bloquer la vue (0 = invisible, 1 = opaque)
    icon:SetAlpha(0.7)

    -- On crée une zone de texte pour le chrono (vide par défaut)
    local text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    text:SetPoint("CENTER", f, "CENTER", 0, 0)
    text:SetTextColor(1, 1, 0) -- Couleur du texte : Jaune
    f.text = text

    return f
end

-- On positionne nos 3 auras autour du centre : 
-- Vengeance à gauche (-150), Onde de Choc à droite (150), Heurt Bouclier en haut (150)
local vengeanceVisual = CreateAuraFrame(spellVengeance, -150, 0)
local ondeVisual = CreateAuraFrame(spellOndeDeChoc, 150, 0)
local heurtVisual = CreateAuraFrame("Heurt de bouclier", 0, 150)

-- Le chronomètre en temps réel pour Vengeance
vengeanceVisual:SetScript("OnUpdate", function(self, elapsed)
    local start, duration = GetSpellCooldown(spellVengeance)
    
    -- duration > 1.5 permet d'ignorer le "Global Cooldown" (GCD) de 1.5s
    -- On ne veut afficher le chrono que si c'est le VRAI temps de recharge du sort
    if start > 0 and duration > 1.5 then
        local timeLeft = (start + duration) - GetTime()
        if timeLeft > 0 then
            self.text:SetText(math.ceil(timeLeft)) -- math.ceil arrondit à l'entier supérieur
        else
            self.text:SetText("")
        end
    else
        self.text:SetText("") -- Le sort est prêt, on efface le texte
    end
end)

-- Le chronomètre d'Onde de choc : uniquement pendant les 5 dernières secondes du temps de recharge
-- ondeVisual est caché pendant la recharge (et un cadre caché n'exécute pas son OnUpdate),
-- donc on utilise un cadre séparé, toujours actif, qui affiche l'icône au bon moment
local ondeTimer = CreateFrame("Frame")
ondeTimer:SetScript("OnUpdate", function(self, elapsed)
    local start, duration = GetSpellCooldown(spellOndeDeChoc)

    -- duration > 1.5 permet d'ignorer le "Global Cooldown" (GCD) de 1.5s
    if start and start > 0 and duration > 1.5 then
        local timeLeft = (start + duration) - GetTime()
        if timeLeft > 0 and timeLeft <= 5 then
            ondeVisual:Show()
            ondeVisual.text:SetText(math.ceil(timeLeft)) -- math.ceil arrondit à l'entier supérieur
            return
        end
    end

    -- Hors des 5 dernières secondes : pas de chrono
    ondeVisual.text:SetText("")
    -- On ne cache l'icône que si le sort n'est pas prêt (sinon c'est CheckSpells qui la gère)
    if not isOndeActive then
        ondeVisual:Hide()
    end
end)

-- ==============================================================================
-- LOGIQUE ET DÉCLENCHEURS (EVENTS)
-- ==============================================================================

local function HasSwordAndBoardProc()
    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, _, spellId = UnitAura("player", i)
        if not name then break end 
        if spellId == spellIdEpeeEtBouclier then return true end
    end
    return false
end

local function CheckSpells()
    local _, classFilename = UnitClass("player")
    if classFilename ~= "WARRIOR" then return end

    -- 1. VENGEANCE
    local usableV, noManaV = IsUsableSpell(spellVengeance)
    
    if (usableV or noManaV) then
        if not isVengeanceActive then
            vengeanceVisual:Show()
            PlaySoundFile("Sound\\Interface\\RaidWarning.wav") -- Petit son d'alerte
            isVengeanceActive = true
        end
    else
        if isVengeanceActive then
            vengeanceVisual:Hide()
            isVengeanceActive = false
        end
    end

    -- 2. ONDE DE CHOC
    local usableO, noManaO = IsUsableSpell(spellOndeDeChoc)
    local startO, durationO = GetSpellCooldown(spellOndeDeChoc)
    
    if usableO and (startO == 0 or durationO <= 1.5) then
        if not isOndeActive then
            ondeVisual:Show()
            PlaySoundFile("Sound\\Interface\\RaidWarning.wav")
            isOndeActive = true
        end
    else
        if isOndeActive then
            ondeVisual:Hide()
            isOndeActive = false
        end
    end

    -- 3. HEURT BOUCLIER (Proc)
    if HasSwordAndBoardProc() then
        if not isHeurtActive then
            heurtVisual:Show()
            PlaySoundFile("Sound\\Interface\\RaidWarning.wav")
            isHeurtActive = true
        end
    else
        if isHeurtActive then
            heurtVisual:Hide()
            isHeurtActive = false
        end
    end
end

frame:SetScript("OnEvent", function(self, event, unit)
    if event == "UNIT_AURA" and unit ~= "player" then return end
    CheckSpells()
end)

-- ==============================================================================
-- FENÊTRE "BONJOUR"
-- ==============================================================================

local helloFrame = CreateFrame("Frame", "ProtAuraHelloFrame", UIParent)
helloFrame:SetSize(200, 100)
helloFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
helloFrame:SetFrameStrata("DIALOG")
helloFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
})
helloFrame:Hide() -- Cachée par défaut
tinsert(UISpecialFrames, "ProtAuraHelloFrame") -- Fermeture avec la touche Échap

local helloText = helloFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
helloText:SetPoint("CENTER", helloFrame, "CENTER", 0, 0)
helloText:SetText("Bonjour")

-- Petite croix en haut à droite pour fermer
local helloClose = CreateFrame("Button", nil, helloFrame, "UIPanelCloseButton")
helloClose:SetPoint("TOPRIGHT", helloFrame, "TOPRIGHT", -6, -6)

-- ==============================================================================
-- BOUTON DE LA MINIMAP
-- ==============================================================================

local minimapButton = CreateFrame("Button", "ProtAuraMinimapButton", Minimap)
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

-- Glisser le bouton pour le déplacer autour de la minimap
minimapButton:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        px, py = px / scale, py / scale
        SetMinimapButtonAngle(math.deg(math.atan2(py - my, px - mx)))
    end)
end)
minimapButton:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
end)

-- L'icône d'Onde de choc (avec une icône de secours si le sort n'est pas trouvé)
local minimapIcon = minimapButton:CreateTexture(nil, "ARTWORK")
minimapIcon:SetSize(20, 20)
minimapIcon:SetPoint("TOPLEFT", minimapButton, "TOPLEFT", 6, -5)
local _, _, ondeTexture = GetSpellInfo(spellOndeDeChoc)
minimapIcon:SetTexture("Interface\\Icons\\Ability_warrior_defensivestance")
minimapIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- On rogne les bords de l'icône

-- La bordure dorée ronde, comme les autres boutons de la minimap
local minimapBorder = minimapButton:CreateTexture(nil, "OVERLAY")
minimapBorder:SetSize(53, 53)
minimapBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
minimapBorder:SetPoint("TOPLEFT", minimapButton, "TOPLEFT", 0, 0)

-- Un clic ouvre ou ferme la fenêtre
minimapButton:SetScript("OnClick", function()
    if helloFrame:IsShown() then
        helloFrame:Hide()
    else
        helloFrame:Show()
    end
end)
