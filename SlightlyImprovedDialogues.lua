-- Slightly Improved™ Dialogues 1.2.0 (Feb 11 2017)
-- Licensed under MIT © 2017 Arthur Corenzan

local NAMESPACE = "SlightlyImprovedDialogues"

-- Uncomment to prevent debug messages
local function d()  end
local function df() end

-- esoui\ingame\interactwindow\keyboard\interactwindow_keyboard.lua:2
local CHATTER_OPTION_INDENT = 30
local BACKGROUND_OFFSETX = -40
local BACKGROUND_HEIGHT = 120

-- esoui\ingame\interactwindow\keyboard\interactwindow_keyboard.lua:209
function ZO_Interaction:AnchorBottomBG(optionControl)
    self.control:GetNamedChild("BottomBG"):ClearAnchors()
    self.control:GetNamedChild("BottomBG"):SetAnchor(TOPRIGHT, GuiRoot, RIGHT)
    self.control:GetNamedChild("BottomBG"):SetAnchor(BOTTOMLEFT, optionControl, BOTTOMLEFT, BACKGROUND_OFFSETX - CHATTER_OPTION_INDENT, BACKGROUND_HEIGHT)
end

local function ChangeBackgrounOffsetX()
    -- esoui\ingame\interactwindow\keyboard\interactwindow_keyboard.xml:126
    ZO_InteractWindowTopBG:ClearAnchors()
    ZO_InteractWindowTopBG:SetAnchor(BOTTOMRIGHT, GuiRoot, RIGHT)
    ZO_InteractWindowTopBG:SetAnchor(TOPLEFT, ZO_InteractWindowTargetAreaTitle, nil, BACKGROUND_OFFSETX, -BACKGROUND_HEIGHT)
end

local function ChangeOptionsHighlight()
    ZO_InteractWindowPlayerAreaHighlight:GetNamedChild("Top"):SetHidden(true)
    ZO_InteractWindowPlayerAreaHighlight:GetNamedChild("Bottom"):SetHidden(true)

    local highlightBackground = CreateControl("ZO_InteractWindowPlayerAreaHighlightBackground", ZO_InteractWindowPlayerAreaHighlight, CT_TEXTURE)
    highlightBackground:SetTexture("esoui\\art\\buttons\\gamepad\\inline_controllerbkg_darkgrey-center.dds")
    highlightBackground:SetTextureCoords(0.5, 1, 0, 1)
    highlightBackground:SetAlpha(0.75)
    highlightBackground:SetBlendMode(TEX_BLEND_MODE_ALPHA)
    highlightBackground:SetAnchor(TOPLEFT, ZO_InteractWindowPlayerAreaHighlight, nil, -CHATTER_OPTION_INDENT + BACKGROUND_OFFSETX, -2)
    highlightBackground:SetAnchor(BOTTOMRIGHT, ZO_InteractWindowPlayerAreaHighlight, nil, 0, 3)
end

local function ChangeTargetTitle()
    local title = ZO_InteractWindowTargetAreaTitle:GetText()
    ZO_InteractWindowTargetAreaTitle:SetText(string.sub(title, 2, -2))
    ZO_InteractWindowTargetAreaTitle:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    ZO_InteractWindowTargetAreaTitle:SetFont("ZoFontCallout")
end

local function OverrideOptionsSetText()
    for index, control in ipairs(INTERACTION.optionControls) do
        local setText = control.SetText
        function control:SetText(text)
            local previousOptionsWithText = 0
            d(index)
            for i = 1, index do
                d(INTERACTION.optionControls[i])
                if INTERACTION.optionControls[i].optionText ~= "" then
                    previousOptionsWithText = previousOptionsWithText + 1
                end
            end
            d("-")
            setText(self, previousOptionsWithText..". "..text)
        end
    end
end

local function HookSelectChatterOptionByIndex()
    local selectChatterOptionByIndex = INTERACTION.SelectChatterOptionByIndex
    -- Override esoui/ingame/interactwindow/keyboard/interactwindow_keyboard.lua:233
    function INTERACTION:SelectChatterOptionByIndex(optionIndex)
        local label = INTERACTION.optionControls[optionIndex]
        if label.isImportant then
            if INTERACTION.currentMouseLabel == label then
                selectChatterOptionByIndex(self, optionIndex)
            else
                if INTERACTION.currentMouseLabel ~= nil then
                    ZO_ChatterOption_MouseExit(INTERACTION.currentMouseLabel)
                end
                ZO_ChatterOption_MouseEnter(label)
            end
        else
            selectChatterOptionByIndex(self, optionIndex)
        end
    end
end

local keepLockedCamera = {
    [INTERACTION_CRAFT] = true,
    [INTERACTION_DYE_STATION] = true,
    [INTERACTION_LOCKPICK] = true,
    [INTERACTION_SIEGE] = true,
    [INTERACTION_FURNITURE] = true,
}

local defaultSavedVars = {
    unlockCamera = true,
}

local function OnAddOnLoaded(event, addOnName)
    if (addOnName == NAMESPACE) then
        local savedVars = ZO_SavedVars:New(NAMESPACE.."_SavedVars", 1, nil, defaultSavedVars)

        ChangeOptionsHighlight()
        ChangeBackgrounOffsetX()
        OverrideOptionsSetText()
        HookSelectChatterOptionByIndex()

        local function SlightlyImproveDialogue(eventCode, ...)
            ChangeTargetTitle()
        end
        EVENT_MANAGER:RegisterForEvent(NAMESPACE, EVENT_CHATTER_BEGIN, SlightlyImproveDialogue)
        EVENT_MANAGER:RegisterForEvent(NAMESPACE, EVENT_QUEST_OFFERED, SlightlyImproveDialogue)
        EVENT_MANAGER:RegisterForEvent(NAMESPACE, EVENT_QUEST_COMPLETE_DIALOG, SlightlyImproveDialogue)
        EVENT_MANAGER:RegisterForEvent(NAMESPACE, EVENT_CONVERSATION_UPDATED, SlightlyImproveDialogue)

        local function OnGameCameraDeactivated()
            if savedVars.unlockCamera and not keepLockedCamera[GetInteractionType()] then
                SetInteractionUsingInteractCamera(false)
            end
        end
        EVENT_MANAGER:RegisterForEvent(NAMESPACE, EVENT_GAME_CAMERA_DEACTIVATED, OnGameCameraDeactivated)

        CALLBACK_MANAGER:FireCallbacks(NAMESPACE.."_OnAddOnLoaded", savedVars)
    end
end
EVENT_MANAGER:RegisterForEvent(NAMESPACE, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
