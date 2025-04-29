local ConfigDir = Game.SaveFolder .. "/ModConfigs";
local ConfigFile = ConfigDir .. "/ModButtonsRemover.json";
local Migration = dofile(ModButtonsRemover.Path .. "/Lua/Config/Migration.lua");
local Default = dofile(ModButtonsRemover.Path .. "/Lua/Config/Default.lua");
local Config = {};

local function ReadConfig()
    return json.parse(File.Read(ConfigFile))
end

function Config.SaveConfig(config)
    File.CreateDirectory(ConfigDir);
    File.Write(
        ConfigFile,
        json.serialize(config)
    )
end

function Config.LoadConfig()
    -- default config if config.json not exists
    if not File.Exists(ConfigFile) then
        Config.SaveConfig(Default.Config())
    end

    local migrated, config = Migration(ReadConfig());

    -- update file if config changed
    if migrated then
        Config.SaveConfig(config);
    end

    return config;
end

return Config;