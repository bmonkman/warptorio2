--[[-------------------------------------

Author: Pyro-Fire
https://patreon.com/pyrofire

Script: lib_control.lua
Purpose: control stuff

-----

Copyright (c) 2019 Pyro-Fire

I put a lot of work into these library files. Please retain the above text and this copyright disclaimer message in derivatives/forks.

Permission to use, copy, modify, and/or distribute this software for any
purpose without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

]]---------------------------------------

--[[ Settings Lib ? ]]--

function lib.setting(n) return lib.modname.."_"..settings.global[n].value end
function lib.call(r,...) if(istable(r))then return remote.call(r[1],r[2],...) end return r(...) end

--[[ Entity Library ]]--

function is_entity(x) return (x.valid~=nil) end

entity={}
function entity.protect(e,min,des) if(min~=nil)then e.minable=min end if(des~=nil)then e.destructible=des end return e end
function entity.spawn(f,n,pos,dir,t) t=t or {} local tx=t or {} tx.name=n tx.position={vector.getx(pos),vector.gety(pos)} tx.direction=dir tx.player=(t.player or game.players[1])
	tx.force=t.force or game.forces.player
	tx.raise_built=true --(t.raise_built~=nil and t.raise_built or true)
	local e=f.create_entity(tx) return e
end
entity.create=entity.spawn -- alias

function entity.destroy(e,r,c) if(e and e.valid)then e.destroy{raise_destroy=(r~=nil and r or true),do_cliff_correction=(c~=nil and c or true)} end end
function entity.ChestRequestMode(e) local cb=e.get_or_create_control_behavior() if(cb.type==defines.control_behavior.type.logistic_container)then
	cb.circuit_exclusive_mode_of_operation=defines.control_behavior.logistic_container.circuit_exclusive_mode_of_operation.set_requests end end
function entity.safeteleport(e,f,pos,bsnap) 
	f = f or e.surface 
	
	-- Normalize position to a proper Factorio position object
	local target_pos = pos or e.position
	if target_pos and type(target_pos) == "table" then
		if target_pos[1] and target_pos[2] then
			-- Array format [x, y] - convert to position object
			target_pos = {x = target_pos[1], y = target_pos[2]}
		elseif not target_pos.x or not target_pos.y then
			-- Invalid position data, use safe default
			target_pos = {x = 0, y = 0}
		end
	else
		target_pos = {x = 0, y = 0}
	end
	
	-- Handle player objects
	if e.object_name == "LuaPlayer" then
		if e.character then
			-- Teleport character first, then sync player view
			local safe_pos = f.find_non_colliding_position(e.character.name, target_pos, 16, 1, bsnap)
			e.character.teleport(safe_pos or target_pos, f)
			e.teleport(e.character.position, f)
		else
			-- Player without character
			local safe_pos = f.find_non_colliding_position("character", target_pos, 16, 1, bsnap)
			e.teleport(safe_pos or target_pos, f)
		end
		return true
	end
	
	-- Handle character entities with players
	if e.type == "character" and e.player then
		local safe_pos = f.find_non_colliding_position(e.name, target_pos, 16, 1, bsnap)
		e.teleport(safe_pos or target_pos, f)
		e.player.teleport(e.position, f)
		return true
	end
	
	-- Handle regular entities
	local prototype_name = e.name or "character"
	local safe_pos = f.find_non_colliding_position(prototype_name, target_pos, 16, 1, bsnap)
	e.teleport(safe_pos or target_pos, f)
	return true
end
function entity.shouldClean(v) return (v.force.name~="player" and v.force.name~="enemy" and v.name:sub(1,9)~="warptorio") end
function entity.tryclean(v) if(v.valid and entity.shouldClean(v))then entity.destroy(v) end end
function entity.emitsound(e,path) for k,v in pairs(game.connected_players)do if(v.surface==e.surface)then v.play_sound{path=path,position=e.position} end end end

--[[ Factorio 2.0 Compatibility Helper ]]--

-- Helper function to convert Factorio 2.0 get_contents() array format to 1.1 dictionary format
function entity.get_contents_dict(inventory)
	local contents = inventory.get_contents()
	local result = {}
	
	-- Handle different return types from get_contents()
	if not contents then
		return result
	end
	
	-- If contents is not a table, return empty result
	if type(contents) ~= "table" then
		return result
	end
	
	-- Handle array format (new Factorio 2.0 format)
	for _, item in pairs(contents) do
		if type(item) == "table" and item.name and item.count then
			result[item.name] = item.count
		end
	end
	
	return result
end

-- Helper function to convert Factorio 2.0 get_fluid_contents() array format to 1.1 dictionary format
function entity.get_fluid_contents_dict(entity)
	local contents = entity.get_fluid_contents()
	local result = {}
	
	-- Handle different return types from get_fluid_contents()
	if not contents then
		return result
	end
	
	-- If contents is a number or not a table, return empty result
	if type(contents) ~= "table" then
		return result
	end
	
	-- Handle array format (new Factorio 2.0 format)
	for _, fluid in pairs(contents) do
		if type(fluid) == "table" and fluid.name and fluid.amount then
			result[fluid.name] = fluid.amount
		end
	end
	
	return result
end

--[[ Entity Cloning helpers ]]--

entity.copy={} entity.copy.__index=entity.copy setmetatable(entity.copy,entity.copy)
function entity.copy.__call(e) end
function entity.copy.chest(a,b) local c=b.get_inventory(defines.inventory.chest) for k,v in pairs(entity.get_contents_dict(a.get_inventory(defines.inventory.chest)))do c.insert{name=k,count=v} end
	-- Factorio 2.0: circuit_connection_definitions was removed, skip circuit copying for now
	-- TODO: Implement proper circuit copying using the new wire connector API if needed
	-- Note: This functionality was used for copying circuit connections when copying chests
	-- local net=a.circuit_connection_definitions
	-- for c,tbl in pairs(net)do 
	-- 	-- Factorio 2.0: Use new wire connector API
	-- 	local wire_type = tbl.wire
	-- 	local wire_connector_id
	-- 	if wire_type == defines.wire_type.red then
	-- 		wire_connector_id = defines.wire_connector_id.circuit_red
	-- 	elseif wire_type == defines.wire_type.green then
	-- 		wire_connector_id = defines.wire_connector_id.circuit_green
	-- 	end
		
	-- 	if wire_connector_id then
	-- 		local source_connector = b.get_wire_connector(wire_connector_id, true)
	-- 		local target_connector = tbl.target_entity.get_wire_connector(wire_connector_id, true)
	-- 		if source_connector and target_connector then
	-- 			source_connector.connect_to(target_connector)
	-- 		end
	-- 	end
	-- end
end

-- --------
-- Logistics system

function entity.AutoBalancePower(t) -- Auto-balance electricity between all entities in a table
	local p=#t local g=0 local c=0
	for k,v in pairs(t)do if(v.valid)then g=g+v.energy c=c+v.electric_buffer_size end end
	for k,v in pairs(t)do if(v.valid)then local r=(v.electric_buffer_size/c) v.energy=g*r end end
end
function entity.BalancePowerPair(a,b) local x=(a.energy+b.energy)/2 a.energy,b.energy=x,x end

--[[Old version, now replaced with: https://mods.factorio.com/mod/warptorio2/discussion/646e46d9225f8dc82fa0a26e
function entity.AutoBalanceHeat(t) -- Auto-balance heat between all entities in a table
	local h=0 for k,v in pairs(t)do h=h+v.temperature end for k,v in pairs(t)do v.temperature=h/#t end
end]]
function entity.AutoBalanceHeat(t) -- Auto-balance heat between all entities in a table (respecting specific heat)
	local e=0 sh=0 tsh=0
	for k,v in pairs(t)do sh=v.prototype.heat_buffer_prototype.specific_heat e=e+v.temperature*sh tsh=tsh+sh end
	for k,v in pairs(t)do v.temperature=e/tsh end
end

function entity.BalanceHeatPair(a,b) -- with respect to specific heat
	local ash,bsh = a.prototype.heat_buffer_prototype.specific_heat, b.prototype.heat_buffer_prototype.specific_heat
	local x=(a.temperature*ash+b.temperature*bsh)/2 a.temperature,b.temperature=x,x
end
function entity.ShiftHeat(a,b) end -- move temperature from a to b

function entity.ShiftContainer(a,b) -- Shift contents from a to b
	local ac,bc=a.get_inventory(defines.inventory.chest),b.get_inventory(defines.inventory.chest)
	for k,v in pairs(entity.get_contents_dict(ac))do local t={name=k,count=v} local c=bc.insert(t) if(c>0)then ac.remove({name=k,count=c}) end end
end

function entity.SyncContainer(a, b, state_key) -- Synchronize container contents between two chests
	local ac, bc = a.get_inventory(defines.inventory.chest), b.get_inventory(defines.inventory.chest)
	local acontents = entity.get_contents_dict(ac)
	local bcontents = entity.get_contents_dict(bc)
	
	-- Use global storage to track previous state
	storage = storage or {}
	storage.sync_states = storage.sync_states or {}
	local key = state_key or (tostring(a.unit_number) .. "_" .. tostring(b.unit_number))
	local prev_state = storage.sync_states[key]
	
	-- If this is the first sync, just make them match and store the state
	if not prev_state then
		-- Choose the chest with more total items as the initial source
		local a_total = 0
		local b_total = 0
		for _, count in pairs(acontents) do a_total = a_total + count end
		for _, count in pairs(bcontents) do b_total = b_total + count end
		
		local source_contents = (a_total >= b_total) and acontents or bcontents
		
		-- Clear both and set to source contents
		ac.clear()
		bc.clear()
		for item_name, count in pairs(source_contents) do
			if count > 0 then
				ac.insert({name = item_name, count = count})
				bc.insert({name = item_name, count = count})
			end
		end
		
		-- Store the synchronized state
		storage.sync_states[key] = {a = source_contents, b = source_contents}
		return
	end
	
	-- Check which chest changed from the previous state
	local a_changed = false
	local b_changed = false
	
	-- Check if chest A changed
	for item_name, count in pairs(acontents) do
		if (prev_state.a[item_name] or 0) ~= count then
			a_changed = true
			break
		end
	end
	if not a_changed then
		for item_name, count in pairs(prev_state.a) do
			if (acontents[item_name] or 0) ~= count then
				a_changed = true
				break
			end
		end
	end
	
	-- Check if chest B changed
	for item_name, count in pairs(bcontents) do
		if (prev_state.b[item_name] or 0) ~= count then
			b_changed = true
			break
		end
	end
	if not b_changed then
		for item_name, count in pairs(prev_state.b) do
			if (bcontents[item_name] or 0) ~= count then
				b_changed = true
				break
			end
		end
	end
	
	-- Sync based on which chest changed
	if a_changed and not b_changed then
		-- A changed, copy A to B
		bc.clear()
		for item_name, count in pairs(acontents) do
			if count > 0 then
				bc.insert({name = item_name, count = count})
			end
		end
		storage.sync_states[key] = {a = acontents, b = acontents}
	elseif b_changed and not a_changed then
		-- B changed, copy B to A
		ac.clear()
		for item_name, count in pairs(bcontents) do
			if count > 0 then
				ac.insert({name = item_name, count = count})
			end
		end
		storage.sync_states[key] = {a = bcontents, b = bcontents}
	elseif a_changed and b_changed then
		-- Both changed (conflict), use chest A as priority
		bc.clear()
		for item_name, count in pairs(acontents) do
			if count > 0 then
				bc.insert({name = item_name, count = count})
			end
		end
		storage.sync_states[key] = {a = acontents, b = acontents}
	end
	-- If neither changed, do nothing
end

function entity.GetFluidTemperature(v) local fb=v.fluidbox if(fb and fb[1])then return fb[1].temperature end return 15 end

function entity.BalanceFluidPair(a,b)
	local af,bf=entity.get_fluid_contents_dict(a),entity.get_fluid_contents_dict(b) local aff,afv=table.First(af) local bff,bfv=table.First(bf) afv=afv or 0 bfv=bfv or 0
	if((not aff and not bff) or (aff and bff and aff~=bff) or (afv<1 and bfv<1) or (afv==bfv))then return end if(not aff)then aff=bff elseif(not bff)then bff=aff end local v=(afv+bfv)/2
	if(aff=="steam")then local temp=15 local at=entity.GetFluidTemperature(a) local bt=entity.GetFluidTemperature(b) temp=math.max(at,bt)
		a.clear_fluid_inside() b.clear_fluid_inside() a.insert_fluid({name=aff,amount=v,temperature=temp}) b.insert_fluid({name=bff,amount=v,temperature=temp})
	else a.clear_fluid_inside() b.clear_fluid_inside() a.insert_fluid({name=aff,amount=v}) b.insert_fluid({name=bff,amount=v}) end
end

function entity.ShiftFluid(a,b)
	local af,bf=entity.get_fluid_contents_dict(a),entity.get_fluid_contents_dict(b) local aff,afv=table.First(af) local bff,bfv=table.First(bf) -- this is apparently broken
	if((not aff and not bff) or (aff and bff and aff~=bff) or (afv<1 and bfv<1))then return end
	if(aff=="steam")then
		local temp=15 local at=entity.GetFluidTemperature(a) local bt=entity.GetFluidTemperature(b) temp=math.max(at,bt)
		local c=b.insert_fluid({name=aff,amount=afv,temperature=temp}) if(c>0)then a.remove_fluid{name=aff,amount=c} end
	elseif(aff)then
		local c=b.insert_fluid({name=aff,amount=afv}) if(c>0)then a.remove_fluid{name=aff,amount=c} end
	end
end

function entity.ShiftBelt(a,b) -- splitters could have up to 4 lines
	for i=1,2,1 do local bl=b.get_transport_line(i) if(bl.can_insert_at_back())then local al=a.get_transport_line(i)
		local contents = entity.get_contents_dict(al) local k,v=next(contents) if(k and v)then bl.insert_at_back{name=k,count=1} al.remove_item{name=k,count=1} end
	end end

end

--[[ Player Library ]]--

players={}
function players.find(f,area) local t={} for k,v in pairs(game.players)do if(v.surface==f and vector.inarea(v.position,area))then table.insert(t,v) end end return t end
function players.playsound(path,f,pos)
	if(f)then f.play_sound{path=path,position=pos} else game.forces.player.play_sound{path=path,position=pos} end
end
function players.safeclean(e,tpo) local f=e.surface local pos=tpo or e.position
	if(tpo or f.count_entities_filtered{area=vector.square(vector.pos(pos),vector(0.5,0.5))}>1)then entity.safeteleport(e,f,pos) end
end

--[[ Technology Library ]]--

research={}
function research.get(n,f) f=f or game.forces.player return f.technologies[n] end
function research.has(n,f) return research.get(n,f).researched end
function research.can(n,f) local r=research.get(n,f) if(r.researched)then return true end local x=table_size(r.prerequisites) for k,v in pairs(r.prerequisites)do if(v.researched)then x=x-1 end end return (x==0) end
--function research.level(n,f) f=f or game.forces.player local ft=f.technologies local r=ft[n.."-0"] or ft[n.."-1"] local i=0 while(r)do if(r.researched)then i=r.level r=ft[n.."-".. i+1] else r=nil end end return i end
function research.level(n,f) f=f or game.forces.player local ft=f.technologies local i,r=0,ft[n.."-0"] or ft[n.."-1"]
	while(r)do if not r.researched then i=r.level-1 r=nil else i=r.level r=ft[n.."-".. i+1] end end
	return i
end -- Thanks Bilka!!

--[[ Surfaces Library ]]--
surfaces={}

function surfaces.BlankSurface(n)

end
function surfaces.spawnbiters(type,n,f) local tbl=game.surfaces[f].find_entities_filtered{type="character"}
	for k,v in ipairs(tbl)do
		for j=1,n do local a,d=math.random(0,2*math.pi),150 local x,y=math.cos(a)*d+v.position.x,math.sin(a)*d+v.position.y
			local p=game.surfaces[f].find_non_colliding_position(t,{x,y},0,2,true)
			local e=game.surfaces[f].create_entity{name=type,position=p}
		end
		game.surfaces[f].set_multi_command{command={type=defines.command.attack,target=v},unit_count=n}
	end
end
function surfaces.EmitText(f,pos,text) 
	rendering.draw_text{
		text=text,
		surface=f,
		target=pos,
		color={r=1,g=1,b=1,a=1},
		scale=1,
		font="default-bold",
		font_size=24,
		alignment="center",
		surface_index=f.index,
		time_to_live=200
	}
end

--[[ Events Library ]]--

events={}
events.defs={}
events.vdefs={}
events.filters={}
events.loadfuncs={}
events.initfuncs={}
events.migratefuncs={}
events.tickers={}
local events_with_filters={"on_built_entity","on_cancelled_deconstruction","on_cancelled_upgrade","on_entity_damaged","on_entity_died","on_marked_for_deconstruction",
	"on_marked_for_upgrade","on_player_mined_item","on_player_repaired_entity","on_post_entity_died","on_pre_ghost_deconstructed","on_pre_player_mined_item","on_robot_built_entity",
	"on_robot_mined","on_robot_pre_mined","on_player_mined_entity"}
events.events_with_filters={}
for k,v in pairs(events_with_filters)do events.events_with_filters[v]=v end

for k,v in pairs(defines.events)do events.defs[v]={} end
function events.hook(nm,func,fts) if(istable(nm))then for k,v in pairs(nm)do events.hook(v,func,fts) end return end
	local nm=(isnumber(nm) and nm or defines.events[nm]) events.defs[nm]=events.defs[nm] or {} table.insert(events.defs[nm],func)
	if(fts)then events.filters[nm]=events.filters[nm] or {} for k,v in pairs(fts)do table.insert(events.filters[nm],util.table.deepcopy(v)) end end
end
events.on_event=events.hook -- alias
function events.raise(name,ev) ev=ev or {} ev.name=ev.name or table.KeyFromName(defines.events,name) script.raise_event(name,ev) end

function events.register(name) events.vdefs[name]=script.generate_event_name() end
-- unused function events.vhook(name,func) if(istable(name))then for k,v in pairs(nm)do events.vhook(name,func) end end events.vhooks[name]=func end
function events.vraise(name,ev) ev=ev or {} ev.name=name script.raise_event(events.vdefs[name],ev) end

function events.entity(ev) return ev.entity or ev.created_entity or ev.destination or ev.mine end
function events.source(ev) return ev.source end
function events.destination(ev) return ev.created_entity or ev.destination end
function events.surface(ev) return ev.surface or game.surfaces[ev.surface_index] end

function events.on_load(f) table.insert(events.loadfuncs,f) end
function events.on_init(f) table.insert(events.initfuncs,f) end
function events.on_migrate(f) table.insert(events.migratefuncs,f) end
events.on_config=events.on_migrate events.on_configration_changed=events.on_migrate -- aliases
function events.raise_load() cache.load() for k,v in ipairs(events.loadfuncs)do v() end if(lib.PLANETORIO)then lib.planets.lua() end end
function events.raise_init() cache.init() for k,v in ipairs(events.initfuncs)do v() end if(lib.PLANETORIO)then lib.planets.lua() end end
function events.raise_migrate(ev) cache.migrate(ev) for k,v in ipairs(events.migratefuncs)do v(ev or {}) end if(lib.PLANETORIO)then lib.planets.lua() end end

function events.on_tick(rate,offset,fnm,func)
	local r=events.tickers[rate] or {} events.tickers[rate]=r local o=r[offset] or {} r[offset]=o o[fnm]=func
	script.on_event(defines.events.on_tick,events.raise_tick)
end
function events.un_tick(rate,offset,fnm) local r=events.tickers[rate] or {} events.tickers[rate]=r local o=r[offset] or {} r[offset]=o o[fnm]=nil
	if(table_size(o)==0)then r[offset]=nil end
	if(table_size(r)==0)then events.tickers[rate]=nil end
	if(table_size(events.tickers)==0)then script.on_event(defines.events.on_tick,nil) end
end
function events.raise_tick(ev) 
	if not rawget(_G, "storage") then return end
	for rt,ff in pairs(events.tickers)do for x,y in pairs(ff)do if(ev.tick%rt==x)then for a,b in pairs(y)do b(ev.tick) end end end end 
end

function events.inject()
	--error(serpent.block(events.filters[defines.events.on_built_entity]))
	for k,v in pairs(events.defs)do if(v and table_size(v)>0)then
		if(events.events_with_filters[table.KeyFromValue(defines.events,k)] and events.filters[k] and table_size(events.filters[k])>0)then
			--if(k==defines.events.on_built_entity and #events.filters[k]>0)then error(k..":\n"..serpent.block(events.filters[k])) end
			script.on_event(k,function(ev) if rawget(_G, "storage") then for x,y in pairs(v)do y(ev) end end end,events.filters[k])
		else script.on_event(k,function(ev) if rawget(_G, "storage") then for x,y in pairs(v)do y(ev) end end end)
		end
	end end
	if(table_size(events.tickers)>0)then script.on_event(defines.events.on_tick,events.raise_tick) end

	script.on_init(events.raise_init)
	script.on_load(events.raise_load)
	script.on_configuration_changed(events.raise_migrate)
end

-- --------
-- Gui

vgui=vgui or {}
function vgui.create(parent,tbl)
	local elm=parent[tbl.name] if(not isvalid(elm))then elm=parent.add(tbl) end
	for k,v in pairs(tbl)do if(vgui.mods[k])then vgui.mods[k](elm,v) end end
	return elm
end

vgui.mods={} vmods=vgui.mods
function vmods.horizontal_align(e,v) e.style.horizontal_align=v end
function vmods.vertical_align(e,v) e.style.vertical_align=v end
function vmods.align(e,v) e.style.horizontal_align=(istable(v) and v[1] or v) e.style.vertical_align=istable(v and v[2] or v) end

-- --------
-- Remotes

