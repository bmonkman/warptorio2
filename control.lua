--[[-------------------------------------

Author: Pyro-Fire
https://mods.factorio.com/mod/warptorio2

Script: control.lua
Purpose: control stuff

]]---------------------------------------

--[[ Environment ]]--
lib={PLANETORIO=false,REMOTES=true}

-- Load the library system first
require("lib/lib")

require("control_main")

-- Initialize the library system - this sets up all events properly
lib.lua()

-- NOW register our initialization events AFTER the events system is active
events.on_init(function()
	game.print("=== WARPTORIO events.on_init FIRED (from control.lua) ===")
	-- Call the actual initialization function from control_main.lua
	if warptorio and warptorio.initialize then
		warptorio.initialize()
	else
		game.print("Error: warptorio.initialize function not found")
	end
end)



-- The actual initialization handlers are in control_main.lua
-- and will be registered through the events system

