

Hook.Patch("Barotrauma.GUI", "TogglePauseMenu", {}, function ()
    if GUI.GUI.PauseMenuOpen then

        -- prevents blinking. restored in MakeItBeautiful()
        GUI.GUI.PauseMenu.Visible = false;

        MakeItBeautiful();
    end
end, Hook.HookMethodType.After)

function MakeItBeautiful()
    Timer.NextFrame(function ()

        GUI.GUI.PauseMenu.Visible = true;

        -- gh:// == https://github.com/evilfactory/LuaCsForBarotrauma/blob/4916de359c89ab188ff4f778c51c98f4e523502c/

        -- gh://Barotrauma/BarotraumaClient/ClientSource/GUI/GUI.cs#L2520
        local pauseMenuInner  = GUI.GUI.PauseMenu.GetChild(Int32(1));

        -- gh://Barotrauma/BarotraumaClient/ClientSource/GUI/GUI.cs#L2529
        local bugsButton = pauseMenuInner.GetChild(Int32(1));

        -- gh://Barotrauma/BarotraumaClient/ClientSource/GUI/GUI.cs#L2524
        local buttonContainer = pauseMenuInner.GetChild(Int32(0));

        local modButtons = FindModButtons(buttonContainer)
        if #modButtons == 0 then return; end

        -- resetting pause menu size because some mods (like gh/Landbanana/Smarter-Bot-AI)
        -- resizing it to fit buttons
        pauseMenuInner.RectTransform.MinSize = Point(1, 1);

        local buttonsWindow = CreateButtonsWindow(modButtons);
        CreateOpenButton(pauseMenuInner, buttonsWindow);

    end);

end

---@param buttonContainer Barotrauma.GUILayoutGroup
---@return table
function FindModButtons(buttonContainer)

    -- in pause menu last button always "Main Menu"
    -- so all buttons after is mod buttons
    local mainMenuButtonText = ToString(TextManager.Get("PauseMenuQuit")):lower();
    local mainMenuButton = nil;

    local modButtons = {};

    local buttonContainerChildren = buttonContainer.GetAllChildren();
    for btn in buttonContainerChildren do
        if LuaUserData.IsTargetType(btn, "Barotrauma.GUIButton") then

            if mainMenuButton ~= nil then
                table.insert(modButtons, btn);
            end

            if ToString(btn.Text):lower() == mainMenuButtonText then
                mainMenuButton = btn;
            end
        end

    end

    return modButtons;
end

---@param pauseMenuInner Barotrauma.GUIFrame
---@param buttonsWindow Barotrauma.GUIFrame
function CreateOpenButton(pauseMenuInner, buttonsWindow)
    local modsButton = GUI.Button(GUI.RectTransform(Vector2(0.09, 0.05), pauseMenuInner.RectTransform, GUI.Anchor.TopRight), "", nil, "MergeStacksButton")
    modsButton.RectTransform.RelativeOffset = Vector2(0.17, 0.07);

    modsButton.OnClicked = function ()
        buttonsWindow.RectTransform.set_Parent(GUI.GUI.PauseMenu.RectTransform);
        pauseMenuInner.Visible = false;
    end
end

---@param modButtons table<Barotrauma.GUIButton>
---@return Barotrauma.GUIFrame
function CreateButtonsWindow(modButtons)
    local defaultButton = GUI.Button(GUI.RectTransform(Vector2(0.13, 0.3)));

    local modButtonsFrame = GUI.Frame(GUI.RectTransform(Vector2(0.13, 0.3), nil, GUI.Anchor.Center));
    local modButtonsContainer = GUI.LayoutGroup(GUI.RectTransform(Vector2(0.7, 0.8), modButtonsFrame.RectTransform, GUI.Anchor.Center));
    modButtonsContainer.AbsoluteSpacing = Int32(15);
    local buttonMargin = modButtonsContainer.AbsoluteSpacing;

    local buttonsHeight = 0;
    for _, button in pairs(modButtons) do

        button.RectTransform.set_Parent(modButtonsContainer.RectTransform);

        GUI.Style.Apply(button, "GUIButton");
        button.Color = defaultButton.Color;
        button.TextColor = defaultButton.TextColor;
        button.Font = defaultButton.Font;
        button.HoverColor = defaultButton.HoverColor;
        button.HoverCursor = defaultButton.HoverCursor;
        button.HoverTextColor = defaultButton.HoverTextColor;
        button.OutlineColor = defaultButton.OutlineColor;

        buttonsHeight = buttonsHeight + button.Rect.Height + buttonMargin;
    end

    modButtonsFrame.RectTransform.MinSize = Point(
        modButtonsFrame.RectTransform.MinSize.X,
        buttonsHeight / modButtonsContainer.RectTransform.RelativeSize.Y - buttonMargin
    )

    return modButtonsFrame;
end

---@param notString any
---@return string
function ToString(notString)
    if type(notString) ~= "string" then
        notString = notString.toString()
    end
    return notString;
end