--[[
Entity Builder Library - Clean abstraction for creating Factorio entities
Replaces the messy ExtendDataCopy pattern with a fluent, type-safe API
]]
local EntityBuilder = {}

-- Factorio 2.0 compatibility constants
local FACTORIO_2_0_DEFAULTS = {
    circuit_wire_max_distance = 7.5,
    default_circuit_wire_max_distance = 7.5
}

-- Base class for all entity builders
local BaseBuilder = {}
BaseBuilder.__index = BaseBuilder

function BaseBuilder:new(entity_type, base_prototype_name)
    local obj = {
        entity_type = entity_type,
        base_name = base_prototype_name,
        entity_data = {},
        item_data = {},
        recipe_data = {},
        tech_data = {},
        should_create_item = true,
        should_create_recipe = true,
        should_create_tech = false
    }
    setmetatable(obj, self)
    return obj
end

function BaseBuilder:name(name)
    self.entity_data.name = name
    return self
end

function BaseBuilder:property(key, value)
    self.entity_data[key] = value
    return self
end

function BaseBuilder:energy_source(config)
    self.entity_data.energy_source = config
    return self
end

function BaseBuilder:icons(icon_config)
    self.entity_data.icons = icon_config
    self.entity_data.icon = nil -- Clear single icon when using icons
    return self
end

function BaseBuilder:tint(color)
    if not self.entity_data.icons then
        -- If no icons defined, copy from base prototype
        local base = data.raw[self.entity_type][self.base_name]
        if base and base.icon then
            self.entity_data.icons = {{icon = base.icon, tint = color}}
            self.entity_data.icon = nil
        end
    else
        -- Apply tint to existing icons
        for _, icon_def in pairs(self.entity_data.icons) do
            icon_def.tint = color
        end
    end
    return self
end

function BaseBuilder:collision_box(box)
    self.entity_data.collision_box = box
    return self
end

function BaseBuilder:selection_box(box)
    self.entity_data.selection_box = box
    return self
end

function BaseBuilder:health(value)
    self.entity_data.max_health = value
    return self
end

-- Item configuration
function BaseBuilder:item_config(config)
    for key, value in pairs(config) do
        self.item_data[key] = value
    end
    return self
end

function BaseBuilder:no_item()
    self.should_create_item = false
    return self
end

-- Recipe configuration
function BaseBuilder:recipe_ingredients(ingredients)
    self.recipe_data.ingredients = ingredients
    return self
end

function BaseBuilder:recipe_energy(time)
    self.recipe_data.energy_required = time
    return self
end

function BaseBuilder:recipe_enabled(enabled)
    self.recipe_data.enabled = enabled
    return self
end

function BaseBuilder:no_recipe()
    self.should_create_recipe = false
    return self
end

-- Technology configuration
function BaseBuilder:with_tech(config)
    self.should_create_tech = true
    self.tech_data = config
    return self
end

-- Build and register the entity
function BaseBuilder:build()
    local entity_name = self.entity_data.name
    if not entity_name then
        error("Entity name is required")
    end

    -- Create entity
    local entity = self:_create_entity()
    data:extend{entity}

    -- Create item if requested
    local item
    if self.should_create_item then
        item = self:_create_item(entity_name)
        data:extend{item}
    end

    -- Create recipe if requested
    local recipe
    if self.should_create_recipe then
        recipe = self:_create_recipe(entity_name)
        data:extend{recipe}
    end

    -- Create technology if requested
    local tech
    if self.should_create_tech then
        tech = self:_create_technology(entity_name)
        data:extend{tech}
    end

    return {
        entity = entity,
        item = item,
        recipe = recipe,
        tech = tech
    }
end

function BaseBuilder:_create_entity()
    -- Deep copy base prototype
    local base = data.raw[self.entity_type][self.base_name]
    if not base then
        error("Base prototype not found: " .. self.entity_type .. "." .. self.base_name)
    end
    
    local entity = util.table.deepcopy(base)
    
    -- Apply our modifications with proper nested table merging
    for key, value in pairs(self.entity_data) do
        if value == false then
            entity[key] = nil
        elseif key == "picture" and type(value) == "table" then
            -- Handle picture property for Factorio 2.0 compatibility
            if self.entity_type == "accumulator" then
                -- In Factorio 2.0, accumulator graphics go in chargable_graphics.picture
                if not entity.chargable_graphics then
                    entity.chargable_graphics = {}
                end
                entity.chargable_graphics.picture = value
            else
                -- For non-accumulator entities, use picture directly
                entity[key] = value
            end
        elseif type(value) == "table" and type(entity[key]) == "table" then
            -- Smart merging for nested tables like energy_source, but not picture
            self:_merge_nested_table(entity[key], value)
        else
            entity[key] = value
        end
    end
    
    -- Apply Factorio 2.0 compatibility fixes
    self:_apply_factorio_2_compatibility(entity)
    
    return entity
end

-- Helper function to intelligently merge nested tables
function BaseBuilder:_merge_nested_table(target, source)
    for sub_key, sub_value in pairs(source) do
        if type(sub_value) == "table" and type(target[sub_key]) == "table" then
            -- Recursively merge nested tables
            self:_merge_nested_table(target[sub_key], sub_value)
        else
            target[sub_key] = sub_value
        end
    end
end

function BaseBuilder:_apply_factorio_2_compatibility(entity)
    -- Remove deprecated circuit connector properties for accumulators
    if self.entity_type == "accumulator" then
        entity.circuit_wire_connection_point = nil
        entity.circuit_connector_sprites = nil
        
        -- Set default circuit wire distance if not specified
        if not entity.circuit_wire_max_distance then
            entity.circuit_wire_max_distance = FACTORIO_2_0_DEFAULTS.circuit_wire_max_distance
        end
    end
end

function BaseBuilder:_create_item(entity_name)
    -- Find appropriate base item
    local base_item_name = self:_get_base_item_name()
    local base_item = data.raw.item[base_item_name]
    if not base_item then
        error("Base item not found: " .. base_item_name)
    end
    
    local item = util.table.deepcopy(base_item)
    item.name = entity_name
    item.place_result = entity_name
    
    -- Apply custom item data
    for key, value in pairs(self.item_data) do
        item[key] = value
    end
    
    -- Copy icons from entity if not specified
    if not item.icons and self.entity_data.icons then
        item.icons = util.table.deepcopy(self.entity_data.icons)
        item.icon = nil
    end
    
    return item
end

function BaseBuilder:_create_recipe(entity_name)
    local base_recipe_name = self:_get_base_recipe_name()
    local base_recipe = data.raw.recipe[base_recipe_name]
    if not base_recipe then
        error("Base recipe not found: " .. base_recipe_name)
    end
    
    local recipe = util.table.deepcopy(base_recipe)
    recipe.name = entity_name
    recipe.results = {{type = "item", name = entity_name, amount = 1}}
    recipe.enabled = false
    
    -- Apply custom recipe data
    for key, value in pairs(self.recipe_data) do
        recipe[key] = value
    end
    
    return recipe
end

function BaseBuilder:_create_technology(entity_name)
    local tech = util.table.deepcopy(self.tech_data)
    tech.name = tech.name or entity_name
    tech.effects = tech.effects or {{type = "unlock-recipe", recipe = entity_name}}
    
    return tech
end

function BaseBuilder:_get_base_item_name()
    -- Default mapping from entity types to item types
    local entity_to_item = {
        accumulator = "accumulator",
        ["electric-pole"] = "small-electric-pole",
        furnace = "steel-furnace",
        reactor = "nuclear-reactor",
        lab = "lab"
    }
    return entity_to_item[self.entity_type] or "steel-plate"
end

function BaseBuilder:_get_base_recipe_name()
    return self:_get_base_item_name()
end

-- Specialized builder for accumulators
local AccumulatorBuilder = {}
AccumulatorBuilder.__index = AccumulatorBuilder
setmetatable(AccumulatorBuilder, BaseBuilder)

function AccumulatorBuilder:new(base_name)
    local obj = BaseBuilder.new(self, "accumulator", base_name or "accumulator")
    return obj
end

function AccumulatorBuilder:buffer_capacity(capacity)
    -- Ensure energy_source exists but preserve existing properties
    if not self.entity_data.energy_source then
        self.entity_data.energy_source = {}
    end
    self.entity_data.energy_source.buffer_capacity = capacity
    return self
end

function AccumulatorBuilder:flow_limits(input, output)
    -- Ensure energy_source exists but preserve existing properties  
    if not self.entity_data.energy_source then
        self.entity_data.energy_source = {}
    end
    if input then
        self.entity_data.energy_source.input_flow_limit = input
    end
    if output then
        self.entity_data.energy_source.output_flow_limit = output
    end
    return self
end

function AccumulatorBuilder:charge_cooldown(cooldown)
    self.entity_data.charge_cooldown = cooldown
    return self
end

function AccumulatorBuilder:discharge_cooldown(cooldown)
    self.entity_data.discharge_cooldown = cooldown
    return self
end

-- Technology builder for easier tech tree management
local TechnologyBuilder = {}
TechnologyBuilder.__index = TechnologyBuilder

function TechnologyBuilder:new(name)
    local obj = {
        tech_data = {
            name = name,
            type = "technology",
            upgrade = false,
            icon_size = 128,
            effects = {},
            prerequisites = {},
            unit = {
                count = 100,
                time = 30,
                ingredients = {}
            }
        }
    }
    setmetatable(obj, self)
    return obj
end

function TechnologyBuilder:upgrade(is_upgrade)
    self.tech_data.upgrade = is_upgrade
    return self
end

function TechnologyBuilder:icons(icon_config)
    self.tech_data.icons = icon_config
    self.tech_data.icon = nil
    return self
end

function TechnologyBuilder:prerequisites(prereq_list)
    self.tech_data.prerequisites = prereq_list
    return self
end

function TechnologyBuilder:science_packs(packs)
    local pack_map = {
        red = "automation-science-pack",
        green = "logistic-science-pack", 
        blue = "chemical-science-pack",
        black = "military-science-pack",
        purple = "production-science-pack",
        yellow = "utility-science-pack",
        white = "space-science-pack"
    }
    
    local ingredients = {}
    for color, count in pairs(packs) do
        local pack_name = pack_map[color]
        if pack_name then
            table.insert(ingredients, {pack_name, count})
        end
    end
    
    self.tech_data.unit.ingredients = ingredients
    return self
end

function TechnologyBuilder:research_cost(count, time)
    self.tech_data.unit.count = count
    if time then
        self.tech_data.unit.time = time
    end
    return self
end

function TechnologyBuilder:unlocks_recipe(recipe_name)
    table.insert(self.tech_data.effects, {type = "unlock-recipe", recipe = recipe_name})
    return self
end

function TechnologyBuilder:effect(effect)
    table.insert(self.tech_data.effects, effect)
    return self
end

function TechnologyBuilder:build()
    local tech = util.table.deepcopy(self.tech_data)
    data:extend{tech}
    return tech
end

-- Export the builders
EntityBuilder.Base = BaseBuilder
EntityBuilder.Accumulator = AccumulatorBuilder
EntityBuilder.Technology = TechnologyBuilder

return EntityBuilder
