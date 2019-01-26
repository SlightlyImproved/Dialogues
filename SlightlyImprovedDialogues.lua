-- Slightly Improved™ Dialogues
-- The MIT License © 2016 Arthur Corenzan

local NAMESPACE = "SlightlyImprovedDialogues"

-- Uncomment to prevent debug messages
local function d()  end
local function df() end

-- See esoui/ingame/interactwindow/keyboard/interactwindow_keyboard.lua:2
local chatterOptionIndent = 30

-- See esoui/ingame/interactwindow/keyboard/interactwindow_keyboard.lua:13
local chosenBeforeColor = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_GENERAL, INTERFACE_GENERAL_COLOR_DISABLED))

-- Updated position for the background.
local backgroundOffsetX = -40 -- was -10.
local backgroundHeight = 120 -- stayed the same.

-- Since GetChatterOptionData doesn't provide an index
-- for the chatter option we keep count ourselves.
-- No, optionIndex is NOT a number. Don't ask me why.
local chatterOptionCount = 1

-- Intercept the method that prepares conversation data for the UI.
local function hookInteractionGetChatterOptionData(savedVars)
    local getChatterOptionData = INTERACTION.GetChatterOptionData
    function INTERACTION:GetChatterOptionData(...)

        -- Invoke the original method.
        local chatterData = getChatterOptionData(self, ...)

        -- Bail early if it's moot.
        if (not chatterData.optionText) or (not chatterData.optionType) then
            return chatterData
        end

        d("Valid chatter option")
        d(chatterData)
        d("---")

        -- Add number prefix to static options.
        if (savedVars.addNumberPrefix) then
            chatterData.optionText = chatterOptionCount..". "..chatterData.optionText
            chatterOptionCount = chatterOptionCount + 1
        end

        -- Always flag Goodbye as "seen before" unless you're
        -- under arrest, because then its the Flee option.
        if (savedVars.goodbyeAlwaysSeen) then
            if (chatterData.optionType == CHATTER_GOODBYE and not IsUnderArrest()) then
                chatterData.chosenBefore = true
            end
        end

        -- Return the modified data.
        return chatterData
    end
end

-- Tried:
-- - Listening to EVENT_CONVERSATION_UPDATED event;
-- - Hooking into INTERACTION.UpdateChatterOptions;
-- - Hooking into INTERACTION.PopulateChatterOptions;
-- But all the above miss some edge case where the conversation is updated
-- but these methods aren't called. Though I finanly found one that is
-- always called.
local function hookInteractionInitializeInteractWindow(savedVars)
    local initializeInteractWindow = INTERACTION.InitializeInteractWindow
    function INTERACTION:InitializeInteractWindow(...)
        df("initializeInteractWindow called at %d", GetTimeStamp())
        chatterOptionCount = 1
        initializeInteractWindow(self, ...)
    end
end


-- For some reason there are times when there's only one important option.
-- In these cases we skip the second press, since there's no point in confirming our only option.
local function countImportantChatterOptions()
    local count = 0
    for optionIndex, optionControl in ipairs(INTERACTION.optionControls) do
        if optionControl.isImportant then
            count = count + 1
        end
    end
    return count
end

-- Since we're emulating a "mouse over" with the first key press, it
-- never is going to trigger a "mouse exit", so we emulate that too.
local function exitInteractionCurrentMouseLabel()
    if (INTERACTION.currentMouseLabel ~= nil) then
        ZO_ChatterOption_MouseExit(INTERACTION.currentMouseLabel)
    end
end

-- To add the "press again to confirm" when selecting important options with the keyboard we intercept
-- this method and instead of making the selection right away we first highlight the option by emulating
-- a "mouse over" and only if it's already highlighted we let it proceed as usual.
local function hookInteractionSelectChatterOptionByIndex()
    local selectChatterOptionByIndex = INTERACTION.SelectChatterOptionByIndex

    -- See esoui/ingame/interactwindow/keyboard/interactwindow_keyboard.lua:224
    function INTERACTION:SelectChatterOptionByIndex(optionIndex)
        local optionControl = INTERACTION.optionControls[optionIndex]
        if optionControl.isImportant then
            if (INTERACTION.currentMouseLabel == optionControl or countImportantChatterOptions() == 1) then
                selectChatterOptionByIndex(self, optionIndex)
                exitInteractionCurrentMouseLabel()
            else
                exitInteractionCurrentMouseLabel()
                ZO_ChatterOption_MouseEnter(optionControl)
            end
        else
            selectChatterOptionByIndex(self, optionIndex)
        end
    end
end

local defaultSavedVars = {
    goodbyeAlwaysSeen = true,
    addNumberPrefix = true,
}

local function onAddOnLoaded(event, addOnName)
    if (addOnName == NAMESPACE) then
        local savedVars = ZO_SavedVars:New(NAMESPACE.."_SavedVars", 1, nil, defaultSavedVars)

        -- Reposition the top part of the background.
        -- See esoui/ingame/interactwindow/keyboard/interactwindow_keyboard.xml:131
        ZO_InteractWindowTopBG:ClearAnchors()
        ZO_InteractWindowTopBG:SetAnchor(TOPLEFT, ZO_InteractWindowTargetAreaTitle, nil, backgroundOffsetX, -backgroundHeight)
        ZO_InteractWindowTopBG:SetAnchor(BOTTOMRIGHT, GuiRoot, RIGHT)

        -- The bottom part of the background is repositioned dynamically, so we're overriding this method.
        -- See esoui/ingame/interactwindow/keyboard/interactwindow_keyboard.lua:204
        function INTERACTION:AnchorBottomBG(optionControl)
            self.control:GetNamedChild("BottomBG"):ClearAnchors()
            self.control:GetNamedChild("BottomBG"):SetAnchor(TOPRIGHT, GuiRoot, RIGHT)
            self.control:GetNamedChild("BottomBG"):SetAnchor(BOTTOMLEFT, optionControl, BOTTOMLEFT, backgroundOffsetX - chatterOptionIndent, backgroundHeight)
        end

        -- Hide the old highlight effect.
        ZO_InteractWindowPlayerAreaHighlight:GetNamedChild("Top"):SetHidden(true)
        ZO_InteractWindowPlayerAreaHighlight:GetNamedChild("Bottom"):SetHidden(true)

        -- Create the new highlight effect.
        local highlight = CreateControl("ZO_InteractWindowPlayerAreaHighlightBackground", ZO_InteractWindowPlayerAreaHighlight, CT_TEXTURE)
        highlight:SetTexture("esoui\\art\\buttons\\gamepad\\inline_controllerbkg_darkgrey-center.dds")
        highlight:SetTextureCoords(0.5, 1, 0, 1)
        highlight:SetAlpha(0.75)
        highlight:SetBlendMode(TEX_BLEND_MODE_ALPHA)
        highlight:SetAnchor(TOPLEFT, ZO_InteractWindowPlayerAreaHighlight, nil, -chatterOptionIndent + backgroundOffsetX, -2)
        highlight:SetAnchor(BOTTOMRIGHT, ZO_InteractWindowPlayerAreaHighlight, nil, 0, 3)

        -- Replace the title's format with one without the dashes.
        ZO_CreateStringId("SI_INTERACT_TITLE_FORMAT", "<<1>>")

        -- Restyle the label.
        ZO_InteractWindowTargetAreaTitle:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
        ZO_InteractWindowTargetAreaTitle:SetFont("ZoFontCallout")

        -- Hook up.
        hookInteractionInitializeInteractWindow()
        hookInteractionGetChatterOptionData(savedVars)
        hookInteractionSelectChatterOptionByIndex()

        -- Fire a callback so code can hook after this add-on.
        CALLBACK_MANAGER:FireCallbacks(NAMESPACE.."_OnAddOnLoaded", savedVars)
    end
end
EVENT_MANAGER:RegisterForEvent(NAMESPACE, EVENT_ADD_ON_LOADED, onAddOnLoaded)
