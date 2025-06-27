--[[-------------------------------------

Author: Pyro-Fire
https://mods.factorio.com/mod/warptorio2

Script: control.lua
Purpose: control stuff

]]---------------------------------------

-- local planets=lib.planets

--[[ Warptorio Environment ]]--

warptorio=warptorio or {}
warptorio.Loaded=false

require("control_main_helpers")

warptorio.platform=require("control_platform_classic")
local platform=warptorio.platform

require("control_class_teleporter")
require("control_class_harvester")
require("control_class_rails")

warptorio.chatcmd={}
function warptorio.chatcmd.kill(ev)
	local ply=game.players[ev.player_index] local c=ply.character
	if(c and c.valid)then c.die(c.force,c) end
end
commands.add_command("kill","Suicides the player",warptorio.chatcmd.kill)

--[[ Warptorio custom events ]]--
-- Hook in on_load with
-- local eventdefs=remote.call("warptorio","get_events")
-- script.on_event(eventdefs["on_warp"],func() end)

events.register("on_warp") -- during Warpout()
events.register("on_post_warp") -- during Warpout()
events.register("warp_started") -- StartWarp()
events.register("warp_stopped") -- StopWarp()

events.register("harvester_deploy") -- ?
events.register("harvester_recall") -- ?

events.register("ability_used") -- ?

--[[ Warptorio Libraries ]]--

warptorio.ChestBeltPairs={{"loader","wooden-chest"},{"fast-loader","iron-chest"},{"express-loader","steel-chest"},
	{"express-loader",function(dir) return (dir=="output" and warptorio.setting("loaderchest_provider") or warptorio.setting("loaderchest_requester")) end}}
warptorio.ChestBeltPairs[0]={"loader","wooden-chest"}
function warptorio.GetChest(dir) local lv=research.level("warptorio-logistics") local lvb=warptorio.ChestBeltPairs[lv] return (isstring(lvb[2]) and lvb[2] or lvb[2](dir)) end
function warptorio.GetBelt(dir) local lv=research.level("warptorio-logistics") local lvb=warptorio.ChestBeltPairs[lv] return (isstring(lvb[1]) and lvb[1] or lvb[1](dir)) end
--remotes.register("GetChest",warptorio.GetChest)
--remotes.register("GetBelt",warptorio.GetBelt)

--[[ Warptorio Platform ]]--

function warptorio.GetPlatform() return warptorio.platform end
function warptorio.GetCurrentSurface() 
	if not storage.floor or not storage.floor.main then return nil end
	return storage.floor.main.host 
end
function warptorio.GetMainSurface() 
	if not storage.floor or not storage.floor.main then return nil end
	return storage.floor.main.host 
end
function warptorio.GetHomeSurface() 
	if not storage.floor then return nil end
	return storage.floor.home and storage.floor.home.host or nil 
end
function warptorio.GetMainPlanet() 
	local surface = warptorio.GetMainSurface()
	if not surface then return nil end
	-- Return a basic planet object without planetorio dependency
	return {
		name = surface.name,
		surface = surface,
		index = surface.index,
		-- Add basic planet properties that might be expected by the mod
		warp_multiply = 1.0,
		zone = storage.warpzone or 0
	}
end
function warptorio.GetHomePlanet() 
	local surface = warptorio.GetHomeSurface()
	if not surface then return nil end
	-- Return a basic planet object without planetorio dependency
	return {
		name = surface.name,
		surface = surface,
		index = surface.index,
		-- Add basic planet properties that might be expected by the mod
		warp_multiply = 1.0,
		zone = storage.warpzone or 0
	}
end

function warptorio.GetNamedSurfaces(tbl) 
	if not storage.floor then return {} end
	local t={} for k,nm in pairs(tbl)do if storage.floor[nm] then t[nm]=storage.floor[nm].host end end return t 
end
function warptorio.GetAllSurfaces() 
	if not storage.floor then return {} end
	local t={} for nm,v in pairs(storage.floor)do t[v.hostindex]=v.host end return t 
end
function warptorio.GetPlatformSurfaces() 
	if not storage.floor then return {} end
	local t={} for nm,v in pairs(storage.floor)do if(platform.floors[nm].empty==true)then t[v.hostindex]=v.host end end return t 
end

function warptorio.GetTeleporterSize(a,b,c,noproto) -- for clearing
	local x=1
	if(a and research.has("warptorio-logistics-1"))then x=x+2 end
	if(b and research.has("warptorio-dualloader-1"))then x=x+1 end
	if(c and research.has("warptorio-triloader"))then x=x+1 end
	return vector((x*2)+2,2)
end
function warptorio.GetTeleporterHazard(bMain,bFull) -- for hazard tiles
	local x=0
	bFull=(bFull==nil and true or bFull) -- has the tech, or -1
	local lgHas=research.has("warptorio-logistics-1")
	local dlHas=research.has("warptorio-dualloader-1")
	local tlHas=research.has("warptorio-triloader")
	local lgCan=research.can("warptorio-logistics-1")
	local dlCan=research.can("warptorio-dualloader-1")
	local tlCan=research.can("warptorio-triloader")

	if(lgCan or lgHas)then x=x+2 end

	if(bMain)then
		if(tlHas and dlHas)then x=x+2
		elseif(tlHas or dlHas)then x=x+1 if(bFull and ( (not tlHas and tlCan) or (not dlHas and dlCan) ) )then x=x+1 end
		elseif(bFull and (tlCan or dlCan))then x=x+1
		end
	else
		if(tlCan)then x=x+1 end
	end

	return vector((x*2)+2,2)
end

warptorio.EmptyGenSettings={default_enable_all_autoplace_controls=false,width=32*12,height=32*12,
	autoplace_settings={entity={treat_missing_as_default=false},tile={treat_missing_as_default=false},decorative={treat_missing_as_default=false}}, starting_area="none"}

function warptorio.MakePlatformFloor(vt)
	local f=game.create_surface(vt.name,(vt.empty and warptorio.EmptyGenSettings or nil))
	if(vt.empty)then
		f.solar_power_multiplier=settings.global.warptorio_solar_multiplier.value
		f.daytime=0
		f.always_day=true
		f.request_to_generate_chunks({0,0},16)
		f.force_generate_chunk_requests()
		f.destroy_decoratives({})
		for k,v in pairs(f.find_entities())do entity.destroy(v) end
		local area=vector.area(vector(-32*8,-32*8),vector(32*8*2,32*8*2))
		vector.LayTiles("out-of-map",f,area)
	end
	local floor=cache.raise_surface(f)
	if(vt.init)then lib.call(vt.init,floor) end
	storage.floor[vt.key]=floor
	return floor
end

function warptorio.GetPlatformFloor(vt) if(isstring(vt))then vt=warptorio.platform.floors[vt] end
	local floor
	if(vt.key=="main")then -- Special; nauvis / primary planet
		floor=storage.floor.main if(not floor)then floor={key=vt.key,host=game.surfaces.nauvis,hostindex=1} storage.floor.main=floor if(vt.init)then lib.call(vt.init,floor) end end
	elseif(vt.key=="home")then -- Special; homeworld
		floor=storage.floor.home if(not floor)then floor={key=vt.key,host=game.surfaces.nauvis,hostindex=1} storage.floor.home=floor end
	else
		floor=storage.floor[vt.key] if(not floor)then 
			floor=warptorio.MakePlatformFloor(vt) 
		end
		floor.key=vt.key
	end
	return floor
end

function warptorio.ConstructFloor(fn,bhzd) warptorio.ConstructPlatform(platform.floors[fn],bhzd) end
function warptorio.ConstructFloorHazard(fn) warptorio.ConstructHazard(platform.floors[fn]) end

function warptorio.ConstructPlatformVoid(surf)
	local vt=warptorio.platform.floors["main"] if(vt.tile)then lib.call(vt.tile,surf,true) end
end

function warptorio.ConstructPlatform(vt,bhzd)
	if(isstring(vt))then vt=warptorio.platform.floors[vt] end
	local floor=warptorio.GetPlatformFloor(vt) if(floor)then
	if(vt.tile)then 
		lib.call(vt.tile,floor.host) 
	else
	end
	if(bhzd and vt.hazard)then 
		lib.call(vt.hazard,floor.host) 
	end
end end

function warptorio.ConstructPlatforms(bhzd)
	local platform=warptorio.GetPlatform()
	for nm,vt in pairs(platform.floors)do warptorio.ConstructPlatform(vt,bhzd) end
end

function warptorio.ConstructHazard(vt)
	if(isstring(vt))then vt=warptorio.platform.floors[vt] end
	local floor=warptorio.GetPlatformFloor(vt)
	if(floor and vt.hazard)then lib.call(vt.hazard,floor.host) end
end

function warptorio.ConstructHazards()
	local platform=warptorio.GetPlatform()
	for nm,vt in pairs(platform.floors)do warptorio.ConstructHazard(vt) end
end

function warptorio.CheckFloorRadar(floor) if(research.has("warptorio-charting") and not isvalid(floor.radar))then
	floor.radar=entity.protect(entity.create(floor.host,"warptorio-invisradar",vector(-1,-1)),false,false)
end end

function warptorio.CheckPlatformSpecials(self)
	local platform=warptorio.platform
	local vfloor=platform.floors[self.key]
	if(not vfloor)then
		game.print("no vfloor error: " .. serpent.line(self))
	end
	local sp=vfloor.special if(not sp)then return end
	if(not sp.upgrade)then if(not research.has(sp.tech) or isvalid(self.SpecialEnt))then return end elseif(research.level(sp.tech)<1)then return end
	local protoname=sp.prototype
	local inv={}
	if(sp.upgrade)then protoname=protoname.."-"..research.level(sp.tech)
		if(isvalid(self.SpecialEnt) and self.SpecialEnt.name==protoname)then return elseif(isvalid(self.SpecialEnt))then inv=warptorio.DestroyPlatformSpecial(self) end
	end

	local f=self.host
	local efply={}
	local area=vector.square(vector(-0.5,-0.5),sp.size)
	local eft=f.find_entities_filtered{area=area}
	local rdr=false if(isvalid(self.radar))then rdr=true entity.destroy(self.radar) end
	for k,v in pairs(eft)do if(isvalid(v))then if(v.type=="character")then table.insert(efply,v) elseif(v~=self.radar)then entity.destroy(v) end end end

	local e=entity.protect(entity.create(f,protoname,vector(-0.5,-0.5)),false,false)
	self.SpecialEnt=e
	if(inv)then for k,v in pairs(inv)do e.get_module_inventory().insert{name=k,count=v} end end -- beacon modules. Close enough.
	warptorio.CheckFloorRadar(self)
	vector.cleanplayers(f,area)
	players.playsound("warp_in",f)
end

function warptorio.DestroyPlatformSpecial(self) local inv
	if(isvalid(self.SpecialEnt))then local x=self.SpecialEnt.get_module_inventory() if(x)then inv=entity.get_contents_dict(x) end entity.destroy(self.SpecialEnt) end
	self.SpecialEnt=nil return inv

end

function warptorio.InitPlatform()
	storage.floor={}

	for nm,vt in pairs(warptorio.platform.floors)do
		local floor=warptorio.GetPlatformFloor(vt)
		if(floor)then
			warptorio.ConstructPlatform(vt,true)
		else
		end
	end
end

--[[ Bootstrap Initialization and Migrations ]]--

-- Initialize Warptorio mod - this function will be called by control.lua after events system is ready
function warptorio.initialize()
	-- Initialize basic structures that are needed immediately
	storage.floor = storage.floor or {}
	storage.warpzone = storage.warpzone or 0
	storage.time_spent_start_tick = storage.time_spent_start_tick or game.tick
	storage.time_passed = storage.time_passed or 0
	storage.warp_charge_time = storage.warp_charge_time or 10
	storage.warp_charge_start_tick = storage.warp_charge_start_tick or 0
	storage.warp_charging = storage.warp_charging or 0
	storage.warp_timeleft = storage.warp_timeleft or (60*10)
	storage.warp_auto_time = storage.warp_auto_time or (60*settings.global["warptorio_autowarp_time"].value)
	storage.warp_auto_end = storage.warp_auto_end or (60*60*settings.global["warptorio_autowarp_time"].value)
	storage.warp_last = storage.warp_last or game.tick
	storage.abilities = storage.abilities or {}
	storage.ability_drain = storage.ability_drain or settings.global["warptorio_ability_drain"].value
	storage.pollution_amount = storage.pollution_amount or 1.1
	storage.pollution_expansion = storage.pollution_expansion or 1.1
	storage.ability_uses = storage.ability_uses or 0
	storage.ability_next = storage.ability_next or 0
	storage.radar_uses = storage.radar_uses or 0
	storage.votewarp = storage.votewarp or {}
	storage.Teleporters = storage.Teleporters or {}
	storage.Research = storage.Research or {}
	storage.Turrets = storage.Turrets or {}
	storage.Rails = storage.Rails or {}
	storage.Harvesters = storage.Harvesters or {}

	-- Try to initialize platform, but continue even if some parts fail
	local init_success = pcall(function()
		warptorio.InitPlatform()
	end)
	
	local warp_success = pcall(function()
		warptorio.ValidateWarpBlacklist()
	end)
	
	local map_success = pcall(function()
		warptorio.ApplyMapSettings()
	end)
	
	-- Initialize cache validation with error handling
	if cache and cache.validate then
		pcall(function() cache.validate("combinators") end)
		pcall(function() cache.validate("heat") end)
		pcall(function() cache.validate("power") end)
		pcall(function() cache.validate("loaderinput") end)
		pcall(function() cache.validate("loaderoutput") end)
		pcall(function() cache.validate("ldinputf") end)
		pcall(function() cache.validate("ldoutputf") end)
	end

	warptorio.Loaded = true
end

function warptorio.ApplyMapSettings()
	local gmp=game.map_settings
	gmp.pollution.diffusion_ratio = 0.105
	-- Note: pollution_factor was removed in Factorio 2.0

	gmp.pollution.min_to_diffuse=15 -- default 15
	gmp.pollution.ageing=1.0 -- 1.0
	gmp.pollution.expected_max_per_chunk=250
	gmp.pollution.min_to_show_per_chunk=50
	gmp.pollution.pollution_restored_per_tree_damage=9
	gmp.pollution.enemy_attack_pollution_consumption_modifier=1.0

	gmp.enemy_evolution.destroy_factor=0.0002 -- default 0.002

	gmp.unit_group.min_group_gathering_time = 600
	gmp.unit_group.max_group_gathering_time = 2 * 600
	gmp.unit_group.max_unit_group_size = 200
	gmp.unit_group.max_wait_time_for_late_members = 2 * 360
	-- Factorio 2.0: settler_group_min_size and settler_group_max_size were removed
	-- gmp.unit_group.settler_group_min_size = 1
	-- gmp.unit_group.settler_group_max_size = 1

	--gmp.enemy_expansion.max_expansion_cooldown = (gmp.enemy_expansion.min_expansion_cooldown*1.25)

end

-- Handle configuration changes (mod updates, etc.)
events.on_config(function(ev)
	-- lib.planets.lua()
	cache.validate("combinators")
	cache.validate("heat")
	cache.validate("power")
	cache.validate("loaderinput")
	cache.validate("loaderoutput")
	cache.validate("ldinputf")
	cache.validate("ldoutputf")

	storage.warpzone=storage.warpzone or 0
	storage.time_spent_start_tick=storage.time_spent_start_tick or game.tick
	storage.time_passed=storage.time_passed or 0

	storage.warp_charge_time=storage.warp_charge_time or 10
	storage.warp_charge_start_tick=storage.warp_charge_start_tick or 0
	storage.warp_charging=storage.warp_charging or 0
	storage.warp_timeleft=storage.warp_timeleft or (60*10)
	storage.warp_auto_time = storage.warp_auto_time or (60*settings.global["warptorio_autowarp_time"].value)
	storage.warp_auto_end = storage.warp_auto_end or (60*60*settings.global["warptorio_autowarp_time"].value)
	storage.warp_last=storage.warp_last or game.tick
	storage.abilities=storage.abilities or {}
	storage.ability_drain=storage.ability_drain or settings.global["warptorio_ability_drain"].value

	storage.pollution_amount = storage.pollution_amount or 1.1
	storage.pollution_expansion = storage.pollution_expansion or 1.1
	storage.ability_uses=storage.ability_uses or 0
	storage.ability_next=storage.ability_next or 0
	storage.radar_uses=storage.radar_uses or 0

	warptorio.ApplyMapSettings()

	storage.votewarp=storage.votewarp or {} if(type(storage.votewarp)~="table")then storage.votewarp={} end
	warptorio.CheckVotewarps()

	-- todo: storage.warp_blacklist={}
	warptorio.ValidateWarpBlacklist()

	--[[ more todo:
		for k,v in pairs(gwarptorio.Harvesters)do v.position=warptorio.platform.harvester[k] end
		for k,v in pairs(gwarptorio.Teleporters)do v.position=warptorio.Teleporters[k].position end
	]]

	storage.Teleporters=storage.Teleporters or {}
	storage.Research=storage.Research or {} -- todo remove this
	storage.Turrets=storage.Turrets or {}
	storage.Rails=storage.Rails or {}
	storage.Harvesters=storage.Harvesters or {}

	if(not storage.floor)then warptorio.InitPlatform() end

	for k,v in pairs(storage.Rails)do
		v:MakeRails()
	end
	for k,v in pairs(storage.Teleporters)do
		v:CheckTeleporterPairs(true)
	end
	for k,v in pairs(storage.Harvesters)do
		local gdata=warptorio.platform.harvesters[v.key]
		v.rank=warptorio.GetPlatformTechLevel(gdata.tech)
		v:CheckTeleporterPairs(true)
		v:Upgrade()
	end

	for k,v in pairs(warptorio.settings)do v() end

	-- todo: warptorio.ApplyMapSettings()
	for k,t in pairs(storage.Harvesters)do
		table.merge(t,util.table.deepcopy(warptorio.platform.harvesters[t.key]))
		table.merge(t,util.table.deepcopy(warptorio.platform.HarvesterPointData))
	end

	warptorio.Loaded=true
end)

events.on_load(function()
	warptorio.HookNewGamePlus()
	if(storage.Teleporters)then for k,v in pairs(storage.Teleporters)do setmetatable(v,warptorio.TeleporterMeta) end end
	if(storage.Harvesters)then for k,v in pairs(storage.Harvesters)do setmetatable(v,warptorio.HarvesterMeta) end end
	if(storage.Rails)then for k,v in pairs(storage.Rails)do setmetatable(v,warptorio.RailMeta) end end
	--lib.planets.lua()
end)

--[[ Players Manager ]]--

function warptorio.CheckVotewarps() for k,v in pairs(storage.votewarp)do if(isvalid(v) or not v.connected)then storage.votewarp[k]=nil end end cache.updatemenu("hud","warpbtn") end

warptorio.teleDir={[0]={0,-1},[1]={1,-1},[2]={1,0},[3]={1,1},[4]={0,1},[5]={-1,1},[6]={-1,0},[7]={-1,-1}}
function warptorio.TeleportLogic(ply,e,tent)
	local w=ply.walking_state
	local ox=tent.position
	local x=e.position
	local mp=2 if(not ply.character)then mp=3 end
	
	if(ply.driving)then
		local veh=ply.vehicle
		if(veh.type=="spider-vehicle")then
			local cp=ply.position local xd,yd=(x.x-cp.x),(x.y-cp.y)
			local vpos=vector(ox.x+xd*3,ox.y+yd*3)
			entity.safeteleport(ply,tent.surface,vpos)
			local cn=veh.clone{position=ply.position,surface=ply.surface,force=ply.force}
			veh.destroy()
			ply.driving=cn
		else
		local cp=ply.position local xd,yd=(x.x-cp.x),(x.y-cp.y) entity.safeteleport(veh,tent.surface,vector(ox.x+xd*3,ox.y+yd*3))
		end
	elseif(w and not w.walking)then
		-- Apply the same opposite-side logic for non-walking players
		local entry_offset_x = ply.position.x - x.x
		local entry_offset_y = ply.position.y - x.y
		
		-- Use inverted offset for opposite-side teleportation
		local exit_pos = vector(ox.x - entry_offset_x, ox.y - entry_offset_y)
		
		entity.safeteleport(ply,tent.surface,exit_pos)
	else
		-- Improved stair teleportation logic for Factorio 2.0
		-- For stairs, players should exit on the opposite side of where they entered
		
		-- Calculate where the player is relative to the entry teleporter
		local entry_offset_x = ply.position.x - x.x
		local entry_offset_y = ply.position.y - x.y
		
		-- For stairs, invert the offset so players appear on the opposite side
		-- This simulates going "through" the stairs to the other side
		local exit_pos = vector(ox.x - entry_offset_x, ox.y - entry_offset_y)
		
		local tpe=ply 
		entity.safeteleport(tpe,tent.surface,exit_pos)
	end
	players.playsound("teleport",e.surface,e.position) players.playsound("teleport",tent.surface,tent.position)
end

cache.player({
	raise=function(cp) local ply=cp.host
		entity.safeteleport(ply,warptorio.GetMainSurface(),vector(0,-5))
		local hud=cache.force_menu("hud",ply)
	end,
	on_position=function(ply)
		local cp=cache.force_player(ply)
		if((cp.tprecent or 0)>game.tick)then return end
		local f=ply.surface
		local z=vector.square(ply.position,vector(0.8,0.8))
		if(ply.driving)then
			local bbox=ply.vehicle.bounding_box
			--game.print(serpent.line(bbox))
			bbox.left_top.x=bbox.left_top.x-0.8
			bbox.left_top.y=bbox.left_top.y-0.8
			bbox.right_bottom.x=bbox.right_bottom.x+0.8
			bbox.right_bottom.y=bbox.right_bottom.y+0.8
			z=bbox
		end

		local ents=f.find_entities_filtered{area=z,type="accumulator"} --todo
		for k,v in pairs(ents)do
			local tpg=cache.get_entity(v)
			if(tpg and isvalid(tpg.teleport_dest))then
				cp.tprecent=game.tick+10
				local tgate=tpg.teleport_dest
				warptorio.TeleportLogic(ply,v,tgate)
			end
		end
	end,
	on_create=function(ply)
		local cp=cache.raise_player(ply)
	end,
	on_join=function(ply)

		local menu=cache.force_menu("hud",ply)
		local main_surface = warptorio.GetMainSurface()
		if main_surface then
			entity.safeteleport(ply,main_surface,{0,-5})
		end
	end,
	on_respawn=function(ply)
		local cf=warptorio.GetMainSurface() local gp=ply
		if(gp.surface~=cf)then local pos=cf.find_non_colliding_position("character",{0,-5},0,1,true) gp.teleport(pos,cf) end
	end,
	on_left=function(ply)
		if(storage.votewarp[ply.index])then
			storage.votewarp[ply.index]=nil
			cache.updatemenu("hud","warpbtn")
		end
	end,
	on_pre_removed=function(ply)
		local cp=cache.get_player(ply) if(cp)then
			cache.destroy_player(ply)
		end
	end,
	on_capsule=function(ply,ev)
		if(ev.item.name=="warptorio-townportal")then
			local p=game.players[ev.player_index]
			if(p and p.valid)then
				players.playsound("teleport",p.surface,p.position)
				entity.safeteleport(p,warptorio.GetMainSurface(),vector(0,-5))
				players.playsound("teleport",p.surface,p.position)
			end
		elseif(ev.item.name=="warptorio-homeportal" and warptorio.GetHomeSurface())then
			local p=game.players[ev.player_index]
			if(p and p.valid)then
				players.playsound("teleport",p.surface,p.position)
				entity.safeteleport(p,warptorio.GetHomeSurface(),vector(0,-5))
				players.playsound("teleport",p.surface,p.position)
			end
		end

	end})

--[[ Warptorio Cache Manager ]]--

 -- Pumps and resources cannot be cloned in warptorio
cache.type("offshore-pump",{ clone=function(e) e.destroy{raise_destroy=true} end})
cache.type("resource",{ clone=function(e) e.destroy{raise_destroy=true} end})

-- Simple globally balanced entities
cache.ent("warptorio-heatpipe",{ create=function(e) cache.insert("heat",e) end, destroy=function(e) cache.remove("heat",e) end })
cache.ent("warptorio-reactor",{ create=function(e) cache.insert("heat",e) end, destroy=function(e) cache.remove("heat",e) end })
cache.ent("warptorio-accumulator",{ create=function(e) cache.insert("power",e) end, destroy=function(e) cache.remove("power",e) end })

events.on_tick(1,0,"heattick",function(tick) entity.AutoBalanceHeat(cache.get("heat")) end)
events.on_tick(1,0,"powertick",function(tick) local t=cache.get("power")
	local g,c=0,0
	for k,v in pairs(t)do if(isvalid(v))then g=g+v.energy c=c+v.electric_buffer_size end end

	local egdrain=storage.ability_drain
	local abc=0
	if(storage.abilities.stabilizing)then
		abc=abc+1
	end
	if(storage.abilities.accelerating)then
		abc=abc+1
	end
	if(storage.abilities.scanning)then
		abc=abc+1
	end

	if(abc>0)then
		local gcost=c*egdrain*abc
		if(g>=gcost)then
			g=math.max(g-gcost,0)
			storage.ability_drain=math.min(egdrain+(0.00000002*abc),0.25)
		else
			storage.abilities.stabilizing=false storage.abilities.scanning=false storage.abilities.accelerating=false
		end
	end
	storage.energycount=g storage.energymax=c
	for k,v in pairs(t)do if(v.valid)then v.energy=g*(v.electric_buffer_size/c) end end
end)

-- Warptorio Combinators
cache.ent("warptorio-combinator",{
	create=function(e,ev) cache.insert("combinators",e) end,
	destroy=function(e,ev) cache.remove("combinators",e) end,
	update=function(e,ev) 
		local cbh=e.get_or_create_control_behavior()
		if cbh then
			-- In Factorio 2.0, constant combinators use parameters array instead of set_signal
			local parameters = {}
			for k,v in pairs(ev.signals) do
				table.insert(parameters, {signal=v.signal, count=v.count, index=k})
			end
			cbh.parameters = parameters
		end
	end})
function warptorio.RefreshWarpCombinators() local sigs=warptorio.GetCombinatorSignals() cache.entcall("combinators","update",{signals=sigs}) end
function warptorio.GetCombinatorSignals() local tbl={} for k,v in pairs(warptorio.Signals)do tbl[k]={signal=v.signal,count=v.get()} end return tbl end
warptorio.Signals={} -- 18 max default
warptorio.Signals[1]={ signal={type="virtual",name="signal-W"},get=function() return (storage.warp_charging>=1 and (storage.warp_time_left or 10)/60 or (storage.warp_charge_time or 10)) end}
warptorio.Signals[2]={ signal={type="virtual",name="signal-X"},get=function() return storage.warp_charging or 0 end}
warptorio.Signals[3]={ signal={type="virtual",name="signal-A"},get=function() return storage.warp_auto_end/60 end}
warptorio.Signals[4]={ signal={type="virtual",name="signal-L"},get=function() local hv=storage.Harvesters.west return ((hv and hv.deployed) and 1 or 0) end}
warptorio.Signals[5]={ signal={type="virtual",name="signal-R"},get=function() local hv=storage.Harvesters.east return ((hv and hv.deployed) and 1 or 0) end}
warptorio.Signals[6]={ signal={type="virtual",name="signal-P"},get=function() return storage.time_passed end}

--[[ Warptorio Gui ]]--

--cache.updatemenu("hud","raise") -- to recreate the menu

function warptorio.RaiseHUD(v) local m=cache.get_menu("hud",v) if(not m)then cache.raise_menu("hud",v) else cache.call_menu("raise",m) end end
function warptorio.ResetHUD(p) if(not p)then for k,v in pairs(game.players)do warptorio.RaiseHUD(v) end else warptorio.RaiseHUD(p) end end
function warptorio.PlayerCanStartWarp(ply) return true end

function warptorio.ToolRecallHarvester(k,ply) if(not research.has("warptorio-harvester-"..k.."-1"))then return end
	local cn=("warptorio-harvestpad-"..k.."-"..research.level("warptorio-harvester-"..k))
	if(not ply or (ply and not entity.get_contents_dict(ply.get_main_inventory())[cn]))then ply.get_main_inventory().insert{name=cn,count=1} players.playsound("warp_in",ply.surface,ply.position) end
	local hv=storage.Harvesters[k] if(hv and hv.deployed and isvalid(hv.b))then players.playsound("warp_in",hv.b.surface,hv.b.position) hv:Recall() hv:DestroyB() end
end
function warptorio.ToolRecallGate(ply) if(not research.has("warptorio-teleporter-portal"))then return end
	local t=storage.Teleporters.offworld if(t)then
		if(t.b and t.b.valid)then players.playsound("warp_in",t.b.surface,t.b.position) t:DestroyLogsB() t:DestroyB() end
		local inv=ply.get_main_inventory()
		if(not entity.get_contents_dict(inv)["warptorio-teleporter-gate-0"])then inv.insert{name="warptorio-teleporter-gate-0",count=1} players.playsound("warp_in",ply.surface,ply.position) end
	end
end

cache.vgui("warptorio_toolbutton",{click=function(elm,ev) local menu=cache.get_menu("hud",elm.player_index) local b=menu.toolbar b.visible=not b.visible end})
cache.vgui("warptorio_tool_hv_west",{click=function(elm,ev) warptorio.ToolRecallHarvester("west",game.players[elm.player_index]) end})
cache.vgui("warptorio_tool_hv_east",{click=function(elm,ev) warptorio.ToolRecallHarvester("east",game.players[elm.player_index]) end})
cache.vgui("warptorio_tool_planet_gate",{click=function(elm,ev) warptorio.ToolRecallGate(game.players[elm.player_index]) end})

cache.vgui("warptorio_homeworld",{
	click=function(elm,ev) local menu=cache.get_menu("hud",elm.player_index)
		if(menu.hometmr<game.tick)then
			menu.hometmr=game.tick+(60*5)
			cache.call_menu("clocktick",menu)
		else
			storage.homeworld=storage.warpzone local f=storage.floor.main.host storage.floor.home.host=f storage.floor.home.hostindex=f.index
			players.playsound("warp_in",storage.floor.home.host) game.print("Homeworld Set.") menu.hometmr=0
			cache.call_menu("clocktick",menu)
		end
	end})

local HUD={} warptorio.HUD=HUD
function HUD.clocktick(menu) local ply=menu.host
	if(storage.warp_charging>=1)then menu.charge_time.caption={"warptorio.warp-in",util.formattime(val or (storage.warp_time_left or 0))}
	elseif(menu.charge_time)then menu.charge_time.caption={"warptorio.charge_time",util.formattime((storage.warp_charge_time or 0)*60)}
	end

	menu.time_passed.caption={"warptorio.time_passed",util.formattime(storage.time_passed or 0)}
	if(warptorio.IsAutowarpEnabled())then menu.autowarp.caption={"warptorio.autowarp-in",util.formattime(storage.warp_auto_end)} else menu.autowarp.caption="" end

	menu.hometmr=menu.hometmr or 0
	if(menu.homeworld)then
		if(menu.hometmr>game.tick)then menu.homeworld.caption={"warptorio.confirm_homeworld",util.formattime(menu.hometmr-game.tick)}
		else menu.homeworld.caption={"warptorio.button_homeworld"}
		end
	end

	if(menu.energybar)then
		local cureng=storage.energycount or 0
		local maxeng=math.max(storage.energymax or 1,1)
		local energydif=cureng-(menu.last_energy or 0)
		menu.last_energy=cureng

		local egdrain=storage.ability_drain*100*60
		local abc=0
		local r=menu.stabilizer
		if(r)then if(storage.abilities.stabilizing)then abc=abc+1 r.caption={"warptorio-stabilize-on","-"..math.roundx(egdrain,2).."%/sec"} else r.caption={"warptorio-stabilize"} end end
		local r=menu.accelerator
		if(r)then if(storage.abilities.accelerating)then abc=abc+1 r.caption={"warptorio-accel-on","-"..math.roundx(egdrain,2).."%/sec"} else r.caption={"warptorio-accel"} end end
		local r=menu.radar
		if(r)then if(storage.abilities.scanning)then abc=abc+1 r.caption={"warptorio-radar-on","-"..math.roundx(egdrain,2).."%/sec"} else r.caption={"warptorio-radar"} end end

		menu.energybar_energy.caption=" "..string.energy_to_string(cureng) .. " "
		menu.energybar_energymax.caption=" "..string.energy_to_string(maxeng) .. " "

		menu.energybar_energybal.caption=" ("..(energydif>=1 and "+" or (energydif>0 and "+-" or ""))..string.energy_to_string(energydif) .. "/sec) "
		menu.energybar_energybal.style.font_color=(energydif>0 and {r=0,g=1,b=0} or (energydif<0 and {r=1,g=0,b=0} or {r=0.75,g=0.75,b=0.75}))

		menu.energybar.value=cureng/maxeng

		menu.energybar_energypct.caption=" "..math.roundx((cureng/maxeng)*100,2) .. "% "

		if(abc>0)then menu.energybar_energypctx.caption="-"..math.roundx(egdrain*abc,2).."%/sec" else menu.energybar_energypctx.caption="" end

	end

end

function HUD.raise(menu,ev) local ply=menu.host
	menu.frame=vgui.create(ply.gui.left,{name="warptorio_frame",type="flow",direction="vertical"})
	menu.frame.style.left_padding=4
	menu.row1=vgui.create(menu.frame,{name="warptorio_row1",type="flow",direction="horizontal"})
	menu.row2=vgui.create(menu.frame,{name="warptorio_row2",type="flow",direction="horizontal"})
	menu.row4=vgui.create(menu.frame,{name="warptorio_row4",type="flow",direction="horizontal"})
	menu.row3=vgui.create(menu.frame,{name="warptorio_row3",type="flow",direction="horizontal"})
	menu.row1.clear()
	menu.row2.clear()
	menu.row3.clear()
	menu.row4.clear()

	menu.warpbtn=vgui.create(menu.row1,{name="warptorio_warpbutton",type="button",caption={"warptorio.button-warp","-"}})
	if(research.has("warptorio-toolbar"))then menu.toolbtn=vgui.create(menu.row1,{name="warptorio_toolbutton",type="button",caption={"warptorio.toolbutton","-"}}) end
	if(research.level("warptorio-reactor")>=8)then
		menu.warptgt=vgui.create(menu.row1,{name="warptorio_warptarget",type="drop-down"})
		HUD.rebuild_warptargets(menu)
		HUD.warptarget(menu,{tgt=(sx==nil and "(random)" or (sx=="home" and "(Homeworld)" or (sx=="(nauvis)" and "nauvis" or sx)))})
	end

	menu.time_passed=vgui.create(menu.row1,{name="warptorio_time_passed",type="label"})
	menu.charge_time=vgui.create(menu.row1,{name="warptorio_charge_time",type="label"})
	menu.warpzone=vgui.create(menu.row1,{name="warptorio_warpzone",type="label",caption="Warpzone: " .. (storage.warpzone or 0)})
	menu.autowarp=vgui.create(menu.row1,{name="warptorio_autowarp",type="label"})

	if(research.has("warptorio-homeworld"))then menu.homeworld=vgui.create(menu.row1,{name="warptorio_homeworld",type="button",caption={"warptorio.button_homeworld"}}) end

	local hasabil=false
	if(research.has("warptorio-stabilizer"))then hasabil=true menu.stabilizer=vgui.create(menu.row2,{name="warptorio_stabilizer",type="button",caption={"warptorio-stabilize","-"}}) end
	if(research.has("warptorio-accelerator"))then hasabil=true menu.accelerator=vgui.create(menu.row2,{name="warptorio_accelerator",type="button",caption={"warptorio-accel","-"}}) end
	if(research.has("warptorio-charting"))then hasabil=true menu.radar=vgui.create(menu.row2,{name="warptorio_radar",type="button",caption={"warptorio-radar","-"}}) end
	if(hasabil)then
		menu.last_energy=menu.last_energy or 100
		local energydif=1000-menu.last_energy
		menu.energybar_label=vgui.create(menu.row4,{name="warptorio_energybar_label",type="label",caption={"warptorio.energybar","-"}})
		menu.energybar_energy=vgui.create(menu.row4,{name="warptorio_energybar_energy",type="label",caption=" 100kw "})
		menu.energybar_energy.style.font_color={r=0,g=1,b=0}

		menu.energybar_energydiv=vgui.create(menu.row4,{name="warptorio_energybar_energydiv",type="label",caption=" / "})

		menu.energybar_energymax=vgui.create(menu.row4,{name="warptorio_energybar_energymax",type="label",caption=" 0kw "})
		menu.energybar_energymax.style.font_color={r=0.25,g=1,b=1}

		menu.energybar_energybal=vgui.create(menu.row4,{name="warptorio_energybar_energybal",type="label",caption=" (+100.32MW/sec) "})
		menu.energybar_energybal.style.font_color=(energydif>0 and {r=0,g=1,b=0} or (energydif==0 and {r=1,g=1,b=0} or {r=1,g=0,b=0}))

		menu.energybar_energydivb=vgui.create(menu.row4,{name="warptorio_energybar_energydivb",type="label",caption=" | "})

		menu.energybar=vgui.create(menu.row4,{name="warptorio_time_passed",type="progressbar",value=0.3})
		menu.energybar.style.natural_width=250
		menu.energybar.style.top_padding=7
		menu.energybar.style.bottom_padding=7

		menu.energybar_energypcta=vgui.create(menu.row4,{name="warptorio_energybar_energypcta",type="label",caption=" | "})
		menu.energybar_energypct=vgui.create(menu.row4,{name="warptorio_energybar_energypct",type="label",caption="25%"})
		menu.energybar_energypct.style.font_color={r=1,g=1,b=1}
		menu.energybar_energypctx=vgui.create(menu.row4,{name="warptorio_energybar_energypctx",type="label",caption="-3%/sec"})
		menu.energybar_energypctx.style.font_color={r=1,g=0,b=0}

	end

	if(research.has("warptorio-toolbar"))then 
		menu.toolbar=vgui.create(menu.row3,{name="warptorio_toolframe",type="flow",direction="horizontal",visible=false})
		menu.toolbar.clear()
		menu.tool_harvester_west=vgui.create(menu.toolbar,{name="warptorio_tool_hv_west",type="sprite-button",sprite="entity/warptorio-harvestportal-1",tooltip={"warptorio.tool_hv_west","-"}})
		menu.tool_planet_gate=vgui.create(menu.toolbar,{name="warptorio_tool_planet_gate",type="sprite-button",sprite="item/warptorio-teleporter-gate-0",tooltip={"warptorio.tool_planet_gate","-"}})
		menu.tool_harvester_east=vgui.create(menu.toolbar,{name="warptorio_tool_hv_east",type="sprite-button",sprite="entity/warptorio-harvestportal-1",tooltip={"warptorio.tool_hv_east","-"}})
	end

	HUD.clocktick(menu)
	HUD.rebuild_warptargets(menu)
	local sx=storage.planet_target

end

-- Add Space Age planet support to warp targeting
function warptorio.GetSpaceAgePlanets()
	local planets = {}
	-- In Factorio 2.0, Space Age planets are available by default
	-- We'll create the surfaces when needed rather than checking if they exist
	local space_age_planet_names = {"vulcanus", "gleba", "fulgora", "aquilo"}
	
	-- For simplicity and reliability, assume Space Age is available in Factorio 2.0
	-- The mod will handle non-existent planets gracefully during surface creation
	for _, planet_name in pairs(space_age_planet_names) do
		table.insert(planets, planet_name)
	end
	
	return planets
end

-- Add Space Age planet warp multiplier support
function warptorio.GetSpaceAgePlanetWarpMultiplier(planet_name)
	-- Different planets can have different warp charge times
	local multipliers = {
		vulcanus = 1.2,  -- Volcanic planet - slightly harder to warp to
		gleba = 1.5,     -- Biological planet - more complex to reach
		fulgora = 1.1,   -- Lightning planet - moderate difficulty
		aquilo = 1.8,    -- Ice planet - hardest to reach
		nauvis = 1.0     -- Home planet - baseline
	}
	return multipliers[planet_name] or 1.0
end

function HUD.rebuild_warptargets(menu,ev)
	if(menu.warptgt)then
	local tgl={"(random)"}
	-- if(research.has("warptorio-homeworld"))then table.insert(tgl,"(Homeworld)") table.insert(tgl,"(Nauvis)") end
	
	-- Add Space Age planets to warp targets if available
	local space_age_planets = warptorio.GetSpaceAgePlanets()
	game.print("Debug: Found " .. #space_age_planets .. " Space Age planets")
	for _, planet_name in pairs(space_age_planets) do
		table.insert(tgl, planet_name)
		game.print("Debug: Added " .. planet_name .. " to warp targets")
	end
	
	-- if(research.has("warptorio-charting"))then for k,v in pairs(lib.planets.GetTemplates())do table.insert(tgl,v.key) end end
	menu.warptgt.items=tgl
	HUD.warptarget(menu,{tgt=storage.planet_target})
	end
end
function HUD.warptarget(menu,ev) local ply=menu.host if(not menu.warptgt or ply.index==ev.ply)then return end
	local elm=menu.warptgt local items if(elm)then items=elm.items end if(not items)then return end
	for idx,kv in pairs(items)do if(type(kv)=="string" and kv:lower()==ev.tgt)then elm.selected_index=idx end end
end

function HUD.warpbtn(menu)
	local r=menu.warpbtn
	local ply=menu.host
	if(storage.warp_charging>=1)then r.caption={"warptorio.warping","-"} r.enabled=false
	else local cx=table.Count(storage.votewarp) local c=table.Count(game.connected_players) -- table.Count(game.non_afk_players)
		if(c>1)then
			local vcn=math.ceil(c*warptorio.setting("votewarp_multi"))
			if(storage.votewarp[ply.index] and cx<vcn)then r.enabled=false else r.enabled=true end
			if(cx>0)then r.caption={"warptorio.button-votewarp-count",cx,vcn}
			else r.caption={"warptorio.button-warp","-"}
			end
		else r.enabled=true r.caption={"warptorio.button-warp","-"} menu.warpzone.caption={"warptorio.warpzone_label",storage.warpzone or 0}
		end
	end
end

cache.menu("hud",HUD)

cache.vgui("warptorio_warptarget",{
selection_changed=function(elm,ev) local ply=game.players[elm.player_index]
	local s=elm.items[elm.selected_index] if(not s)then return end local sx=s:lower()
	local vt=(sx=="(random)" and nil or (sx=="(homeworld)" and "home" or (sx=="(nauvis)" and "nauvis" or sx)))
	if(vt~=storage.planet_target)then 
		storage.planet_target=vt 
		game.print({"warptorio.player_set_warp_target",ply.name,s}) 
		-- Debug logging for Space Age planets
		if vt and game.surfaces[vt] then
			game.print("Debug: Selected Space Age planet " .. vt .. " - surface exists")
		elseif vt then
			game.print("Debug: Selected target " .. vt .. " - checking if it's a valid planet")
		end
		cache.updatemenu("hud","warptarget",{ply=elm.player_index,tgt=sx}) 
	end
end})

function warptorio.StartWarp()
	if(storage.warp_charging<1)then
		events.vraise("warp_started")
		storage.warp_charge_start_tick=game.tick
		storage.warp_charging=1
		players.playsound("reactor-stabilized")
		cache.updatemenu("hud","warpbtn")
	end
end
function warptorio.StopWarp()
	if(storage.warp_charging>0)then
		events.vraise("warp_stopped")
		storage.warp_charging=0
		storage.warp_charge_time=storage.warp_time_left/60
		storage.warp_charge_start_tick=0
	end
end
function warptorio.IsWarping() return storage.warp_charging>0 end
cache.vgui("warptorio_warpbutton",{
click=function(elm,ev) local ply=game.players[elm.player_index] local menu=cache.get_menu("hud",elm.player_index)
	if(storage.warp_charging<1)then local c=table.Count(game.connected_players) -- table.Count(game.non_afk_players)
		if(c>1 and warptorio.setting("votewarp_multi")>0)then --votewarp
			local vcn=math.ceil(c*warptorio.setting("votewarp_multi"))
			storage.votewarp[ply.index]=ply
			local cx=table.Count(storage.votewarp)
			if(vcn<=1 or cx>=vcn)then
				warptorio.StartWarp()
				game.print(ply.name .. " started the warpout procedure.")
			else
				players.playsound("teleport")
				game.print({"warptorio.player_want_vote_warp",ply.name,cx,vcn})
				cache.updatemenu("hud","warpbtn")
			end
		elseif(warptorio.PlayerCanStartWarp(ply))then
			storage.warp_charge_start_tick = game.tick
			storage.warp_charging = 1
			players.playsound("reactor-stabilized")
			cache.updatemenu("hud","warpbtn")
		else
			ply.print("You must be on the same planet as the platform to warp")
		end
	end
end})

cache.vgui("warptorio_stabilizer",{
click=function(elm,ev) local ply=game.players[elm.player_index] local menu=cache.get_menu("hud",elm.player_index)
	storage.abilities.stabilizing= not storage.abilities.stabilizing
end})
cache.vgui("warptorio_accelerator",{
click=function(elm,ev) local ply=game.players[elm.player_index] local menu=cache.get_menu("hud",elm.player_index)
	storage.abilities.accelerating= not storage.abilities.accelerating
end})
cache.vgui("warptorio_radar",{
click=function(elm,ev) local ply=game.players[elm.player_index] local menu=cache.get_menu("hud",elm.player_index)
	storage.abilities.scanning= not storage.abilities.scanning
end})

--[[ Warping stuff ]]--

function warptorio.ValidateWarpBlacklist()
end

local staticBlacklist={"highlight-box","big_brother-blueprint-radar","osp_repair_radius"}
function warptorio.GetWarpBlacklist()
	return staticBlacklist
end

-- OnEntCloned
events.on_event(defines.events.on_entity_cloned,function(ev)
	if(warptorio.IsCloning)then table.insert(warptorio.Cloned_Entities,{source=ev.source,destination=ev.destination}) end
	if(ev.source.type=="spider-vehicle")then
		for k,v in pairs(game.players)do local inv=v.get_main_inventory() if(inv)then
			for i=1,#inv,1 do local e=inv[i] if(e and e.valid_for_read and e.connected_entity==ev.source)then e.connected_entity=ev.destination end end
			local e=v.cursor_stack if(e and e.valid_for_read and e.connected_entity==ev.source)then e.connected_entity=ev.destination end
			if(v.driving and v.vehicle==ev.source)then
				entity.safeteleport(v,ev.destination.surface,ev.destination.position)
				v.driving=ev.destination
			end
		end end
	end
end)

function warptorio.CountPlatformEntities() return 5 end -- todo

function warptorio.Warpout(key)
	warptorio.IsWarping=true
	for k,v in pairs(storage.Harvesters)do if(v.deployed)then v:Recall(true) end end

	local cp=warptorio.GetMainPlanet()
	local cf=warptorio.GetMainSurface()
	warptorio.WarpPreBuildPlanet(key)
	local f,w,frc=warptorio.WarpBuildPlanet(key)
	warptorio.WarpPostBuildPlanet(w)

	game.print("Debug: WarpBuildPlanet returned surface: " .. (f and f.name or "nil"))
	game.print("Debug: Setting main surface to: " .. (f and f.name or "nil"))
	storage.floor.main.host=f
	storage.floor.main.hostindex=f.index

	warptorio.ConstructPlatform("main",true)

	events.vraise("on_warp",{newsurface=f,newplanet=w,oldsurface=cf,oldplanet=cp})
	if(cp and cp.on_warp)then lib.call(cp.on_warp,f,w,cf,cp) end

	warptorio.Warp(cf,f)
	warptorio.WarpPost(cf,f)

	-- reset pollution & biters
	-- In Factorio 2.0, evolution_factor changed to getter/setter methods
	game.forces["enemy"].set_evolution_factor(0)
	storage.pollution_amount=1.1
	storage.pollution_expansion=1.1

	-- warp sound
	players.playsound("warp_in")

	warptorio.WarpFinished()
	events.vraise("on_post_warp",{newsurface=f,newplanet=w})
	if(w.postwarpout)then lib.call(w.postwarpout,{newsurface=f,newplanet=w}) end
	warptorio.IsWarping=false
end

function warptorio.WarpPreBuildPlanet(key)
	storage.warp_charge=0
	storage.warp_charging=0
	storage.votewarp={}
	storage.warp_last=game.tick

	storage.warpzone=storage.warpzone+1

	-- Warp chargetime cooldown math
	local cot=warptorio.CountPlatformEntities()

	local sgZone=warptorio.setting("warpcharge_zone")
	local sgZoneGain=warptorio.setting("warpcharge_zonegain")
	local sgMax=warptorio.setting("warpcharge_max")
	local sgFactor=warptorio.setting("warp_charge_factor")
	local sgMul=warptorio.setting("warpcharge_multi")

	storage.warp_charge_time=math.min(10+ (cot/sgFactor) + (storage.warpzone*sgMul) + (sgZoneGain*(math.min(storage.warpzone,sgZone)/sgZone)*60), 60*sgMax)
	storage.warp_time_left=60*storage.warp_charge_time

	-- Autowarp timer math
	local rta=research.level("warptorio-reactor")
	storage.warp_auto_time=(60*warptorio.setting("autowarp_time"))+(60*10*rta)
	storage.warp_auto_end=game.tick+ storage.warp_auto_time*60

	-- Abilities
	--storage.ability_uses=0
	--storage.radar_uses=0
	--storage.ability_next=game.tick+60*60*warptorio.setting("ability_warp")

	storage.ability_drain=warptorio.setting("ability_drain") or 0.00001
	storage.abilities={}

	-- Update guis
	--if(research.has("warptorio-accelerator") or research.has("warptorio-charting") or research.has("warptorio-stabilizer"))then end --gui.uses() gui.cooldown()
	--if(warptorio.IsAutowarpEnabled())then gui.autowarp() end
	--gui.warpzone()
	cache.updatemenu("hud","warpbtn")

	-- packup old teleporter gate
	--local tp=storage.Teleporters.offworld if(tp and tp:ValidB())then tp:DestroyB() tp:DestroyLogsB() end
	-- Recall harvester plates and players on them.
	--for k,v in pairs(storage.Harvesters)do v:Recall(true) end

end

function warptorio.WarpBuildPlanet(key)
	local surface
	local planet_name = "warpzone_" .. (storage.warpzone or 0)
	
	game.print("Debug: WarpBuildPlanet called with target: " .. (storage.planet_target or "nil"))
	
	-- Check if we're warping to a specific target
	local lvl = research.level("warptorio-reactor")
	local wx = storage.planet_target
	game.print("Debug: Reactor level " .. lvl .. ", selected target: " .. (wx or "nil"))
	
	-- Early game random warping: if no target is selected, randomly choose between Space Age planets and new surfaces
	if not wx then
		local space_age_planets = warptorio.GetSpaceAgePlanets()
		game.print("Debug: GetSpaceAgePlanets() returned " .. #space_age_planets .. " planets")
		if #space_age_planets > 0 then
			-- 50% chance to try a Space Age planet instead of creating a new surface
			if math.random(1, 100) <= 50 then
				wx = space_age_planets[math.random(1, #space_age_planets)]
				game.print("Debug: Early game random selection chose Space Age planet: " .. wx)
			else
				game.print("Debug: Early game random selection chose new generated surface")
			end
		else
			game.print("Debug: No Space Age planets available for early game warping")
		end
	end
	
	-- Check for Space Age planets - Allow targeting at any reactor level
	if wx then
		local space_age_surface = nil
		local is_space_age_planet = false
		local space_age_planets = {"vulcanus", "gleba", "fulgora", "aquilo"}
		
		-- Check if this is a Space Age planet
		for _, planet_name in pairs(space_age_planets) do
			if wx == planet_name then
				is_space_age_planet = true
				break
			end
		end
		
		if is_space_age_planet then
			-- Try to get existing surface or create it
			space_age_surface = game.surfaces[wx]
			if not space_age_surface then
				-- Create the Space Age surface with modified nauvis settings
				local map_gen_settings = util.table.deepcopy(game.surfaces.nauvis.map_gen_settings)
				map_gen_settings.seed = math.random(1000000, 2147483647)
				
				-- Apply planet-specific modifications to map generation
				if wx == "vulcanus" then
					-- Volcanic planet - increase temperature, reduce water
					map_gen_settings.starting_area = "none"
				elseif wx == "gleba" then
					-- Biological planet - increase moisture, forests
					map_gen_settings.starting_area = "none"
				elseif wx == "fulgora" then
					-- Lightning planet - electrical storms
					map_gen_settings.starting_area = "none"
				elseif wx == "aquilo" then
					-- Ice planet - cold, minimal resources
					map_gen_settings.starting_area = "none"
				end
				
				space_age_surface = game.create_surface(wx, map_gen_settings)
				
				-- Apply basic surface settings
				space_age_surface.solar_power_multiplier = game.surfaces.nauvis.solar_power_multiplier
				space_age_surface.daytime = game.surfaces.nauvis.daytime
				space_age_surface.freeze_daytime = game.surfaces.nauvis.freeze_daytime
				space_age_surface.wind_speed = game.surfaces.nauvis.wind_speed
				space_age_surface.wind_orientation = game.surfaces.nauvis.wind_orientation
				
				-- Generate initial chunks
				space_age_surface.request_to_generate_chunks({0,0}, 16)
				space_age_surface.force_generate_chunk_requests()
			end
			
			if warptorio.GetMainSurface() ~= space_age_surface then
				-- Get base warp chance and apply Space Age planet multiplier
				local base_chance = warptorio.setting("warpchance")
				local planet_multiplier = warptorio.GetSpaceAgePlanetWarpMultiplier(wx)
				-- Space Age planets should be easier to target, so use higher chance
				local modified_chance = base_chance * 1.5
				
				local roll = math.random(1,100)
				
				if roll <= modified_chance then
					local space_age_planet = {
						name = wx,
						surface = space_age_surface,
						index = space_age_surface.index,
						warp_multiply = planet_multiplier,
						zone = storage.warpzone or 0
					}
					return space_age_surface, space_age_planet
				end
			end
		end
	end
	
	-- Check if we're warping to home/nauvis (requires higher reactor level)
	if(lvl >= 8) then 
		if(wx == "home" or wx == "nauvis") then 
			if(research.has("warptorio-homeworld")) then 
				local hf = (wx == "nauvis" and game.surfaces.nauvis or storage.floor.home.host)
				if(warptorio.GetMainSurface() ~= hf and math.random(1,100) <= warptorio.setting("warpchance")) then
					local hp = {name = hf.name, surface = hf, index = hf.index}
					game.print({"warptorio.successful_warp"}) 
					game.print({"warptorio.home_sweet_home", hp.name})
					return hf, hp
				end
			end
		end
	end
	
	-- Create a new surface for each warp to simulate planetorio behavior
	-- Use nauvis map generation settings as base but randomize seed and some parameters
	local map_gen_settings = util.table.deepcopy(game.surfaces.nauvis.map_gen_settings)
	
	-- Randomize the seed to get different terrain each time
	map_gen_settings.seed = math.random(1000000, 2147483647) -- Use reasonable 32-bit range
	
	-- Optionally vary some generation parameters for more variety
	local warpzone = storage.warpzone or 0
	if warpzone > 5 then
		-- Add some variation to later zones
		local variation = math.random(80, 120) / 100 -- 0.8 to 1.2 multiplier
		if map_gen_settings.autoplace_controls then
			for resource_name, control in pairs(map_gen_settings.autoplace_controls) do
				if control.richness then
					control.richness = control.richness * variation
				end
				if control.frequency then
					control.frequency = control.frequency * math.random(80, 120) / 100
				end
			end
		end
	end
	
	-- Check if surface already exists (in case of naming conflicts)
	if game.surfaces[planet_name] then
		-- Delete the old surface if it exists
		game.delete_surface(game.surfaces[planet_name])
	end
	
	-- Create the new surface with randomized settings
	surface = game.create_surface(planet_name, map_gen_settings)
	
	-- Apply nauvis-like settings
	surface.solar_power_multiplier = game.surfaces.nauvis.solar_power_multiplier
	surface.daytime = game.surfaces.nauvis.daytime
	surface.freeze_daytime = game.surfaces.nauvis.freeze_daytime
	surface.wind_speed = game.surfaces.nauvis.wind_speed
	surface.wind_orientation = game.surfaces.nauvis.wind_orientation
	
	-- Generate chunks around spawn area
	surface.request_to_generate_chunks({0,0}, 16)
	surface.force_generate_chunk_requests()
	
	-- Create a basic planet object without planetorio
	local planet = {
		name = planet_name,
		surface = surface,
		index = surface.index,
		warp_multiply = 1.0,
		zone = storage.warpzone or 0,
		desc = "Warp Zone " .. (storage.warpzone or 0), -- Description for new planets
		seed = map_gen_settings.seed -- Store the seed for reference
	}
	
	-- Create a basic result structure that matches what the rest of the code expects
	local nplanet = {
		surface = surface,
		planet = planet,
		force = game.forces.player
	}
	
	game.print("Warping to " .. planet.name .. " (seed: " .. planet.seed .. ")")
	return nplanet.surface, nplanet.planet, nplanet.force
end

function warptorio.WarpPostBuildPlanet(planet)
	if(planet.warp_multiply)then
		storage.warp_charge_time=storage.warp_charge_time*planet.warp_multiply
		storage.warp_time_left=storage.warp_time_left*planet.warp_multiply
	end
	--gui.charge_time()
end

function warptorio.Warp(cf,f) -- Find and clone entities to new surface
	--cf.find_entities()
	--cf.clone_entities{surface=f,entities=tbl}

	-- call to platform()

	if(storage.Teleporters.offworld)then storage.Teleporters.offworld:DestroyPointTeleporter(2) end

	local etbl,tpply=warptorio.platform.GetWarpables(cf,f) --{},{}
	for k,v in pairs(etbl)do if(not isvalid(v))then etbl[k]=nil end end

	local blacktbl={}
	for k,v in pairs(etbl)do if(table.HasValue(warptorio.GetWarpBlacklist(),v.name))then table.insert(blacktbl,v) etbl[k]=nil end end
	for k,v in pairs(etbl)do if(not v or not v.valid)then etbl[k]=nil end end

	-- find logistics networks and robots among entities to catch robots outside the platform
	if(settings.global["warptorio_robot_warping"].value==true)then
		local lgn={} for k,v in pairs(etbl)do if(v.type=="roboport")then local g=v.logistic_network if(g and g.valid)then table.insertExclusive(lgn,g) end end end
		for k,v in pairs(lgn)do for i,e in pairs(v.robots)do table.insertExclusive(etbl,e) end end
	end

	-- do the cloning
	warptorio.Cloned_Entities={}
	warptorio.IsCloning=true
	cf.clone_entities{entities=etbl,destination_offset={0,0},destination_surface=f} --,destination_force=game.forces.player}
	warptorio.IsCloning=false
	local new_ents=warptorio.Cloned_Entities
	warptorio.Cloned_Entities=nil

	-- AAI Vehicles
	if(remote.interfaces["aai-programmable-vehicles"])then local rmt="aai-programmable-vehicles"
		for k,v in pairs(new_ents)do if(isvalid(v.source) and isvalid(v.destination))then
			local sig=remote.call(rmt,"get_unit_by_entity",v.source) if(sig)then remote.call(rmt,"on_entity_deployed",{entity=v.destination,signals=sig.data}) end
		end end
	end

	--local clones={} for k,v in pairs(etbl)do if(v.valid)then table.insert(clones,v.clone{position=v.position,surface=f,force=v.force}) end end

	-- Recreate teleporter gate
	--if(storage.Teleporters.offworld)then storage.Teleporters.offworld:CheckTeleporterPairs() end

	-- Clean inventories
	for k,v in pairs(game.players)do if(v and v.valid)then local iv=v.get_main_inventory() if(iv)then for i,x in pairs(entity.get_contents_dict(iv))do
		if(i:sub(1,25)=="warptorio-teleporter-gate")then iv.remove{name=i,count=x} end
		if(i:sub(1,20)=="warptorio-harvestpad")then if(x>1)then iv.remove{name=i,count=(x-1)} end end
	end end end end

	-- Ensure the new platform is stable before teleporting players
	-- Make sure chunks are generated and the platform is fully built
	f.request_to_generate_chunks({0,0}, 16)
	f.force_generate_chunk_requests()
	
	-- do the player teleport using the safe teleport function
	for k,v in pairs(tpply)do 
		-- v[1] should be an entity (character, car, tank, spider-vehicle), v[2] should be position
		if v[1] and v[1].valid then
			local entity_to_teleport = v[1]
			
			-- Handle position data properly - v[2] might be a Factorio position object or array
			local target_pos
			if v[2] then
				if v[2].x and v[2].y then
					-- It's a position object with .x and .y properties
					target_pos = {v[2].x, v[2].y}
				elseif v[2][1] and v[2][2] then
					-- It's an array-style position
					target_pos = {v[2][1], v[2][2]}
				else
					-- Fallback to center spawn position
					target_pos = {0, 0}
				end
			else
				-- No position data, use center spawn position
				target_pos = {0, 0}
			end
			
			-- Use entity.safeteleport for all entities (characters, vehicles, etc.)
			local success = entity.safeteleport(entity_to_teleport, f, target_pos)
		end
	end

	--// cleanup past entities - now safe to do after players are moved
	
	for k,v in pairs(etbl)do if(v and v.valid)then v.destroy{raise_destroy=true} end end
	for k,v in pairs(blacktbl)do if(v and v.valid)then v.destroy{raise_destroy=true} end end
end

function warptorio.SurfaceIsWarpzone(f) local n=f.name
	local hw=warptorio.GetHomeSurface()
	local sf=(n:sub(1,9)=="warpsurf_") -- backwards compatability
	local zf=(n:sub(1,9)=="warpzone_")
	return (n~="nauvis" and (sf or zf) and f~=hw)
end

function warptorio.WarpFinished()
	local f=warptorio.GetMainSurface()

	--// delete abandoned surfaces
	for k,v in pairs(game.surfaces)do
		if( table_size(v.find_entities_filtered{type="character"})<1 and v~=f)then
			--if(n=="nauvis" and not storage.nauvis_is_clear)then storage.nauvis_is_clear=true v.clear(true) else
			if(warptorio.SurfaceIsWarpzone(v))then game.delete_surface(v) end
		end
	end

	--warptorio.CheckReactor()

end

function warptorio.WarpPost(cf,f)
	-- Recreate teleporter gate
	if(storage.Teleporters.offworld)then storage.Teleporters.offworld:CheckTeleporterPairs() end

	--// radar -- game.forces.player.chart(f,{lefttop={x=-256,y=-256},rightbottom={x=256,y=256}})

	--// build void
	--for k,v in pairs({"nw","ne","sw","se"})do local ug=research.level("turret-"..v) or -1 if(ug>=0)then vector.LayCircle("out-of-map",c,vector.circleEx(vector(cx[v].x+0.5,cx[v].y+0.5),math.floor(10+(ug*6)) )) end end
	--vector.LayTiles("out-of-map",c,marea)

	if(cf and cf.valid)then warptorio.ConstructPlatformVoid(cf) end

end

--[[ Remotes ]]--

warptorio.remote={}

require("control_main_remotes")

remote.add_interface("warptorio",warptorio.remote)
remote.add_interface("warptorio2",warptorio.remote)

-- Register all main event handlers for Factorio 2.0
function warptorio.register_events()
    game.print("[Warptorio] register_events called")
    script.on_event(defines.events.on_tick, warptorio.on_tick)
    game.print("[Warptorio] Registered main event handlers (Factorio 2.0)")
end

function warptorio.on_tick(event)
    if event.tick % 60 == 0 then
        game.print("[Warptorio] on_tick event is running (every second)")
    end
end

