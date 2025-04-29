local Default = {};

function Default.Config()
	local config = {};

	config.version = "1";

	config.excluded = {
		["item finder mod"] = true
	}

	return config;
end

return Default;