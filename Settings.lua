-- Slightly Improved™ Dialogues
-- The MIT License © 2016 Arthur Corenzan

local NAMESPACE = "SlightlyImprovedDialogues"

local settings = {}

local panel =
{
    type = "panel",
    name = "Slightly Improved™ Dialogues",
    displayName = "Slightly Improved™ Dialogues",
    author = nil,
    version = nil,
}

local options =
{
    {
        type = "checkbox",
        name = "Unlocked Camera",
        tooltip = "Prevent the game from locking the camera on the NPC you're talking to.",
        getFunc = function() return settings.unlockCamera end,
        setFunc = function(value) settings.unlockCamera = value end,
    }, {
        type = "checkbox",
        name = "Goodbye Greyed out by Default",
        tooltip = "Make the goodbye option always appear faded.",
        getFunc = function() return settings.goodbyeAlwaysSeen end,
        setFunc = function(value) settings.goodbyeAlwaysSeen = value end,
    }, {
        type = "checkbox",
        name = "Prefix Options with their Numbers",
        tooltip = "Add the corresponding number before each option in the dialogue.",
        getFunc = function() return settings.addNumberPrefix end,
        setFunc = function(value) settings.addNumberPrefix = value end,
    },
}

CALLBACK_MANAGER:RegisterCallback(NAMESPACE.."_OnAddOnLoaded", function(savedVars)
    settings = savedVars

    local LAM = LibStub("LibAddonMenu-2.0")
    LAM:RegisterAddonPanel(NAMESPACE, panel)
    LAM:RegisterOptionControls(NAMESPACE, options)
end)
