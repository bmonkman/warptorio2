local spider={}
spider.tint={r=0.4,g=0.4,b=1,a=0.7}
spider.name="warptorio-warpspider"
spider.size=0.5

spider.item=util.table.deepcopy(data.raw["item-with-entity-data"].spidertron)
spider.item.name=spider.name
spider.item.icons={{icon=spider.item.icon,icon_size=spider.item.icon_size,tint=spider.tint}}
spider.item.place_result=spider.name
spider.item.icon=nil

spider.recipe=util.table.deepcopy(data.raw.recipe.spidertron)
spider.recipe.name=spider.name
spider.recipe.results={
  {
    type = "item",
    name = spider.name,
    amount = 1
  }
}
spider.recipe.icons=spider.item.icons
spider.recipe.category="crafting" -- Changed from "recipe-category" (deprecated) to "category"

spider.recipe.ingredients={
  {type="item", name="spidertron", amount=8},
  {type="item", name="power-armor-mk2", amount=2},
  {type="item", name="fission-reactor-equipment", amount=8},
  {type="item", name="raw-fish", amount=9},
  {type="item", name="artillery-turret", amount=8},
  {type="item", name="rocket-silo", amount=1}
}

spider.tech=util.table.deepcopy(data.raw["technology"].spidertron)
spider.tech.name=spider.name
spider.tech.effects={{type="unlock-recipe",recipe="warptorio-warpspider"}}
spider.tech.prerequisites={"spidertron","space-science-pack","warptorio-reactor-8","artillery"}
spider.tech.icons={{icon=spider.tech.icon,icon_size=spider.tech.icon_size,tint=spider.tint}}
spider.tech.icon=nil
spider.tech.localised_description={"technology-description.warptorio-warpspider"}

spider.vehicle_grid=util.table.deepcopy(data.raw["equipment-grid"]["spidertron-equipment-grid"])
spider.vehicle_grid.name="warptorio-warpspider-equipment-grid"
spider.vehicle_grid.height=10 --6
spider.vehicle_grid.width=12 --10

spider.vehicle=util.table.deepcopy(data.raw["spider-vehicle"].spidertron)
spider.vehicle.name=spider.name
spider.vehicle.equipment_grid="warptorio-warpspider-equipment-grid"
spider.vehicle.icons={{icon=spider.vehicle.icon,icon_size=spider.vehicle.icon_size,tint=spider.tint}}
spider.vehicle.icon=nil

spider.vehicle.max_health=9001 --3000
-- In Factorio 2.0, 'height' property may not exist on spider vehicles
if spider.vehicle.height then
	spider.vehicle.height=spider.vehicle.height*spider.size --12
end
spider.vehicle.minable.result=spider.name
spider.vehicle.inventory_size=200
spider.vehicle.torso_rotation_speed = 0.01 --0.005
spider.vehicle.movement_energy_consumption="250kW"
-- Check if chain_shooting_cooldown_modifier exists (may be renamed/removed in 2.0)
if spider.vehicle.chain_shooting_cooldown_modifier ~= nil then
	spider.vehicle.chain_shooting_cooldown_modifier = 0.35 --0.5
end

--[[spider.vehicle.guns = {
        "spidertron-rocket-launcher-1",
        "spidertron-rocket-launcher-2",
        "spidertron-rocket-launcher-3",
        "spidertron-rocket-launcher-4"
      }]]

spider.legs={}
for i=1,8,1 do
	local leg_name = "spidertron-leg-"..i
	if data.raw["spider-leg"] and data.raw["spider-leg"][leg_name] then
		local leg=util.table.deepcopy(data.raw["spider-leg"][leg_name])
		proto.TintImages(leg,spider.tint)
		proto.SizeTo(leg,spider.size)
		leg.name="warptorio-"..leg.name
		-- Check if part_length exists before using it (Factorio 2.0 compatibility)
		if leg.part_length then
			leg.part_length=leg.part_length*spider.size
		end
		-- Check if movement properties exist before modifying them
		if leg.movement_acceleration then
			leg.movement_acceleration = leg.movement_acceleration/(spider.size/1.5) --0.3 --0.03
		end
		if leg.movement_based_position_selection_distance then
			leg.movement_based_position_selection_distance= leg.movement_based_position_selection_distance*spider.size*1.5 -- 12 --4
		end
		if leg.initial_movement_speed then
			leg.initial_movement_speed = leg.initial_movement_speed/(spider.size/1.5) --0.6 --0.06
		end
		spider.legs[i]=leg
	end
end

spider.vehicle.guns={}
spider.guns={}
for i=1,4,1 do
	for x=1,2,1 do
		local launcher_name = "spidertron-rocket-launcher-"..i
		if data.raw.gun and data.raw.gun[launcher_name] then
			local w=util.table.deepcopy(data.raw.gun[launcher_name])
			w.name="warptorio-spidertron-rocket-launcher-"..(i*2)-2+x
			-- Check if attack_parameters exists before modifying it
			if w.attack_parameters then
				w.attack_parameters.cooldown=45 --60
				w.attack_parameters.range=45 --60
			end
			w.localised_name={"item-name."..w.name}
			table.insert(spider.guns,w)
			table.insert(spider.vehicle.guns,w.name)
			data:extend{w}
		end
	end
end

--[[ rocket launchers are better. tank shells would be good but they hit the spider.

spider.shotgun=util.table.deepcopy(data.raw.gun["combat-shotgun"])
spider.shotgun.name="warptorio-spidertron-shotgun"
spider.shotgun.attack_parameters.cooldown=30 --30
spider.shotgun.attack_parameters.range=36

spider.flame=util.table.deepcopy(data.raw.gun["flamethrower"])
spider.flame.name="warptorio-spidertron-flamethrower"
spider.flame.attack_parameters.range=36

spider.smg=util.table.deepcopy(data.raw.gun["tank-machine-gun"])
spider.smg.name="warptorio-spidertron-machine-gun"
spider.smg.attack_parameters.range=36

--spider.artillery=table.deepcopy(data.raw.gun["artillery-wagon-cannon"])
--spider.artillery.name="warptorio-spidertron-artillery"

--spider.tank=table.deepcopy(data.raw.gun["tank-cannon"])
--spider.tank.name="warptorio-spidertron-tank-cannon"

--spider.vehicle.guns[4]=nil
--spider.vehicle.guns[3]=nil

for i=1,2,1 do local w=util.table.deepcopy(spider.shotgun) w.name=w.name.."-"..i data:extend{w} table.insert(spider.vehicle.guns,w.name) end
for i=1,2,1 do local w=util.table.deepcopy(spider.flame) w.name=w.name.."-"..i data:extend{w} table.insert(spider.vehicle.guns,w.name) end
for i=1,2,1 do local w=util.table.deepcopy(spider.smg) w.name=w.name.."-"..i data:extend{w} table.insert(spider.vehicle.guns,w.name) end
--crash --for i=1,2,1 do local w=table.deepcopy(spider.artillery) w.name=w.name.."-"..i data:extend{w} table.insert(spider.vehicle.guns,w.name) end
--spidertron shoots itself --for i=1,2,1 do local w=table.deepcopy(spider.tank) w.name=w.name.."-"..i data:extend{w} table.insert(spider.vehicle.guns,w.name) end

]]

-- Update spider engine leg references if they exist
if spider.vehicle.spider_engine and spider.vehicle.spider_engine.legs then
	for k,v in pairs(spider.vehicle.spider_engine.legs)do
		v.leg="warptorio-"..v.leg
	end
end

proto.SizeTo(spider.vehicle,spider.size)
proto.TintImages(spider.vehicle,spider.tint)
spider.vehicle.selection_box={{-1,-1},{1,1}}
data:extend(spider.guns)
data:extend(spider.legs)
data:extend{spider.recipe,spider.item,spider.tech,spider.vehicle_grid,spider.vehicle}

--error(serpent.block(spider.vehicle))