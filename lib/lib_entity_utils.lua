-- Shared utilities for cleaner entity creation
-- Replaces the messy ExtendDataCopy pattern across multiple files

local utils = {}

-- Helper function for RGB colors
function utils.rgb(r, g, b, a)
    a = a or 255
    return {r = r/255, g = g/255, b = b/255, a = a/255}
end

-- Factorio 2.0 compatibility fixes
local function applyFactorio2Compatibility(entity, entity_type)
    if entity_type == "accumulator" then
        -- Remove deprecated circuit connector properties
        entity.circuit_wire_connection_point = nil
        entity.circuit_connector_sprites = nil
        -- Set default circuit wire distance if not specified
        if not entity.circuit_wire_max_distance then
            entity.circuit_wire_max_distance = 7.5
        end
    end
    return entity
end

-- Clean entity builder function
function utils.createEntity(config)
    local base_name = config.base or error("base prototype required")
    local entity_type = config.type or error("entity type required")
    local new_name = config.name or error("name required")
    
    -- Get base prototype
    local base = data.raw[entity_type][base_name]
    if not base then
        error("Base prototype not found: " .. entity_type .. "." .. base_name)
    end
    
    -- Deep copy and modify
    local entity = table.deepcopy(base)
    entity.name = new_name
    
    -- Apply modifications
    if config.properties then
        for key, value in pairs(config.properties) do
            if value == false then
                entity[key] = nil
            elseif type(value) == "table" and type(entity[key]) == "table" then
                -- Merge tables
                for sub_key, sub_value in pairs(value) do
                    entity[key][sub_key] = sub_value
                end
            else
                entity[key] = value
            end
        end
    end
    
    -- Apply Factorio 2.0 compatibility
    applyFactorio2Compatibility(entity, entity_type)
    
    return entity
end

-- Clean item builder function
function utils.createItem(config)
    local base_name = config.base or error("base item required")
    local new_name = config.name or error("name required")
    
    local base = data.raw.item[base_name]
    if not base then
        error("Base item not found: " .. base_name)
    end
    
    local item = table.deepcopy(base)
    item.name = new_name
    item.place_result = new_name
    
    if config.properties then
        for key, value in pairs(config.properties) do
            item[key] = value
        end
    end
    
    return item
end

-- Clean recipe builder function
function utils.createRecipe(config)
    local base_name = config.base or error("base recipe required")
    local new_name = config.name or error("name required")
    
    local base = data.raw.recipe[base_name]
    if not base then
        error("Base recipe not found: " .. base_name)
    end
    
    local recipe = table.deepcopy(base)
    recipe.name = new_name
    recipe.results = {{type = "item", name = new_name, amount = 1}}
    recipe.enabled = false
    
    if config.properties then
        for key, value in pairs(config.properties) do
            recipe[key] = value
        end
    end
    
    return recipe
end

-- Complete entity builder (entity + item + recipe)
function utils.createComplete(config)
    local entities = {}
    
    -- Create entity
    if config.entity then
        local entity_config = table.deepcopy(config.entity)
        entity_config.name = config.name
        table.insert(entities, utils.createEntity(entity_config))
    end
    
    -- Create item
    if config.item then
        local item_config = table.deepcopy(config.item)
        item_config.name = config.name
        table.insert(entities, utils.createItem(item_config))
    end
    
    -- Create recipe
    if config.recipe then
        local recipe_config = table.deepcopy(config.recipe)
        recipe_config.name = config.name
        table.insert(entities, utils.createRecipe(recipe_config))
    end
    
    return entities
end

-- Helper for creating series of similar entities
function utils.createSeries(base_config, variations)
    local all_entities = {}
    
    for _, variation in ipairs(variations) do
        local config = table.deepcopy(base_config)
        config.name = variation.name
        
        -- Apply variation properties
        if variation.properties then
            if not config.entity then config.entity = {} end
            if not config.entity.properties then config.entity.properties = {} end
            
            for key, value in pairs(variation.properties) do
                config.entity.properties[key] = value
            end
        end
        
        local entities = utils.createComplete(config)
        for _, entity in ipairs(entities) do
            table.insert(all_entities, entity)
        end
    end
    
    return all_entities
end

-- Science pack utilities
utils.techPacks = {
    red = "automation-science-pack",
    green = "logistic-science-pack", 
    blue = "chemical-science-pack",
    black = "military-science-pack",
    purple = "production-science-pack",
    yellow = "utility-science-pack",
    white = "space-science-pack"
}

function utils.sciencePacks(packs)
    local ingredients = {}
    for color, count in pairs(packs) do
        local pack_name = utils.techPacks[color]
        if pack_name then
            table.insert(ingredients, {pack_name, count})
        end
    end
    return ingredients
end

return utils
