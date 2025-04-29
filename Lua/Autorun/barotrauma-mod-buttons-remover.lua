-- if true then return; end

ModButtonsRemover = {}
ModButtonsRemover.Path = ...
ModButtonsRemover.Config = dofile(ModButtonsRemover.Path .. "/Lua/Config/Config.lua");
local Config = ModButtonsRemover.Config.LoadConfig();

local function ModButtonsRemoverMain()

    ---@param notString any
    ---@return string
    local function ToString(notString)
        if type(notString) ~= "string" then
            notString = notString.toString()
        end
        return notString;
    end

    ---@param button Barotrauma.GUIButton
    local function GetFavState(button)
        if Config.excluded[ToString(button.Text):lower()] == nil then
            Config.excluded[ToString(button.Text):lower()] = false;
        end

        return Config.excluded[ToString(button.Text):lower()];
    end

    ---@param buttonContainer Barotrauma.GUILayoutGroup
    ---@return table
    local function FindModButtons(buttonContainer)

        -- in pause menu last button always "Main Menu"
        -- so all buttons after is mod buttons
        local mainMenuButtonText = ToString(TextManager.Get("PauseMenuQuit")):lower();
        local mainMenuButton = nil;

        local modButtons = {};

        local buttonContainerChildren = buttonContainer.GetAllChildren();
        for button in buttonContainerChildren do
            if LuaUserData.IsTargetType(button, "Barotrauma.GUIButton") then

                if mainMenuButton ~= nil then
                    table.insert(modButtons, button);

                    GetFavState(button); -- adds button to config
                end

                if ToString(button.Text):lower() == mainMenuButtonText then
                    mainMenuButton = button;
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

        modsButton.OnClicked = buttonsWindow;
    end

    ---@param button Barotrauma.GUIButton
    ---@param state boolean
    local function RecolorButton(button, state)
        if state then
            button.Color = Color(255, 255, 255)
        else
            button.Color = Color(75, 75, 75)
        end
    end

    ---@type Barotrauma.GUIButton
    local DefaultButton = GUI.Button(GUI.RectTransform(Vector2(0.13, 0.3)));

    ---@param button Barotrauma.GUIButton
    function UnifyButton(button)
        GUI.Style.Apply(button, "GUIButton");
        button.Color = DefaultButton.Color;
        button.TextColor = DefaultButton.TextColor;
        button.Font = DefaultButton.Font;
        button.HoverColor = DefaultButton.HoverColor;
        button.HoverCursor = DefaultButton.HoverCursor;
        button.HoverTextColor = DefaultButton.HoverTextColor;
        button.OutlineColor = DefaultButton.OutlineColor;
    end

    ---@param container Barotrauma.GUILayoutGroup|Barotrauma.GUIFrame
    local function GetContainerInnerHeight(container)

        local padding = 0;
        if LuaUserData.IsTargetType(container, "Barotrauma.GUILayoutGroup") then
            padding = container.AbsoluteSpacing;
        end

        local height = 0;
        for child in container.Children do
            local childHeight = 0;
            childHeight = child.RectTransform.Rect.Height;

            height = height + childHeight + padding;
        end

        local ret = height / container.RectTransform.RelativeSize.Y - padding;

        return ret;
    end

    ---@param modButtons table<Barotrauma.GUIButton>
    ---@return Barotrauma.GUIFrame
    function OpenButtonsWindow(modButtons)

        -- wappers like pauseMenuInner and buttonContainer
        local modButtonsFrame = GUI.Frame(GUI.RectTransform(Vector2(0.15, 0.3), GUI.GUI.PauseMenu.RectTransform, GUI.Anchor.Center));
        modButtonsFrame.RectTransform.MinSize = Point(250, 300);

        local modButtonsContainer = GUI.LayoutGroup(GUI.RectTransform(Vector2(0.8, 0.8), modButtonsFrame.RectTransform, GUI.Anchor.TopCenter));
        modButtonsContainer.RectTransform.RelativeOffset = Vector2(0.0, 0.1); -- makes top padding

        local buttonMargin = 15;
        modButtonsContainer.AbsoluteSpacing = Int32(buttonMargin);

        local buttonsHeight = 0;
        for _, button in pairs(modButtons) do

            UnifyButton(button);

            local row = GUI.LayoutGroup(GUI.RectTransform(
                    Point(modButtonsContainer.RectTransform.ScaledSize.X, button.RectTransform.ScaledSize.Y),
                    modButtonsContainer.RectTransform,
                    GUI.Anchor.Center
            ), true);

            -- i dunno why, but "button.set_Parent" makes huge margins
            local newButton = GUI.Button(GUI.RectTransform(Vector2(0.96, 1), row.RectTransform), button.Text);
            newButton.OnClicked = button.OnClicked;

            -- space between main and favorite buttons
            GUI.LayoutGroup(GUI.RectTransform(Vector2(0.05, 1), row.RectTransform))

            -- sizes makes small overflow (0.96 + 0.05 + 0.07 = 1.08), but it looks better
            local favoriteButton = GUI.Button(GUI.RectTransform(Vector2(0.07, 1), row.RectTransform), nil, "GUIStarIconBright");
            favoriteButton.ToolTip = "If checked, button will remain in pause menu";


            RecolorButton(favoriteButton, GetFavState(newButton));
            favoriteButton.OnClicked = function ()
                Config.excluded[ToString(newButton.Text):lower()] = not GetFavState(newButton);
                RecolorButton(favoriteButton, GetFavState(newButton));
                ModButtonsRemover.Config.SaveConfig(Config);
            end;

            buttonsHeight = buttonsHeight + row.RectTransform.ScaledSize.Y + buttonMargin;
        end

        local RelativeSize = modButtonsContainer.RectTransform.RelativeSize;
        modButtonsContainer.RectTransform.Resize(Point(
            modButtonsFrame.RectTransform.ScaledSize.X * RelativeSize.X,
            buttonsHeight - buttonMargin
        ), false);

        modButtonsFrame.RectTransform.Resize(Point(
            modButtonsContainer.RectTransform.ScaledSize.X / RelativeSize.X,
            modButtonsContainer.RectTransform.ScaledSize.Y / RelativeSize.Y
        ), false);

    end

    ---@param pauseMenuInner Barotrauma.GUIFrame
    ---@param buttonContainer Barotrauma.GUILayoutGroup
    ---@param modButtons table<Barotrauma.GUIButton>
    local function BeautifyPauseMenu(pauseMenuInner, buttonContainer, modButtons)

        -- resetting pause menu size because some mods (like gh/Landbanana/Smarter-Bot-AI)
        -- resizing it to fit buttons
        pauseMenuInner.RectTransform.MinSize = Point(250, 300);

        -- used for top margin via AbsoluteSpacing
        GUI.LayoutGroup(GUI.RectTransform(Vector2(1, 0), buttonContainer.RectTransform));


        local buttonsHeight = buttonContainer.AbsoluteSpacing;
        local buttonsAdded = false;

        for _, button in pairs(modButtons) do
            if GetFavState(button) then
                buttonsAdded = true;
                UnifyButton(button);
                button.RectTransform.set_Parent(buttonContainer.RectTransform);

                button.SetAsLastChild();

                buttonsHeight = buttonsHeight + button.Rect.Height + buttonContainer.AbsoluteSpacing;
            else
                button.RectTransform.set_Parent(nil);
            end
        end

        if buttonsAdded then
            pauseMenuInner.RectTransform.Resize(Point(
                pauseMenuInner.Rect.Width,
                GetContainerInnerHeight(buttonContainer)
            ))
        end
    end

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

            -- just test buttons
            GUI.Button(GUI.RectTransform(Vector2(1, 0.13), buttonContainer.RectTransform), "Smarter Bot AI", nil, "GUIButtonSmall");
            GUI.Button(GUI.RectTransform(Vector2(1, 0.13), buttonContainer.RectTransform), "Neurotrauma", nil, "GUIButtonSmall");
            GUI.Button(GUI.RectTransform(Vector2(1, 0.13), buttonContainer.RectTransform), "AI NPCS OPTIONS", nil, "GUIButton");
            GUI.Button(GUI.RectTransform(Vector2(1, 0.13), buttonContainer.RectTransform), "SoundProof Walls", nil, "GUIButtonSmall");
            -- GUI.Button(GUI.RectTransform(Vector2(1, 0.13), buttonContainer.RectTransform), "Perfomance Fix", nil, "GUIButtonSmall");

            local modButtons = FindModButtons(buttonContainer)
            if #modButtons == 0 then return; end

            BeautifyPauseMenu(pauseMenuInner, buttonContainer, modButtons);

            CreateOpenButton(pauseMenuInner, function ()
                OpenButtonsWindow(modButtons)
                pauseMenuInner.Visible = false;
            end);

        end);

    end

    Hook.Patch("Barotrauma.GUI", "TogglePauseMenu", {}, function ()
        if GUI.GUI.PauseMenuOpen then

            -- prevents blinking. restored in MakeItBeautiful()
            GUI.GUI.PauseMenu.Visible = false;
            MakeItBeautiful();
        end
    end, Hook.HookMethodType.After)
end

ModButtonsRemoverMain();