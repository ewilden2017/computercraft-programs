-- Generic crafter. Requires a modem connected to all inventories for crafting,
-- an output inventory in front of the turtle, and a return inventory beneath it.

local MODEM_DIR = "back"
local SLEEP_TIME = 10

-----

-- Convert crafting numbers to turtle slot numbers
local CRAFTING_SLOT_MAPPING = {[1]=1, [2]=2, [3]=3, [4]=5, [5]=6, [6]=7, [7]=9, [8]=10, [9]=11}

function main()
    -- Convert list of patterns into a list of recipes
    local patterns = require("patterns")
    local recipes = {}
    for name, p in pairs(patterns) do
        recipes[name] = create_recipe(p)
    end

    local modem = peripheral.wrap(MODEM_DIR)
    local inventories = get_inventories(modem)
    local self_name = modem.getNameLocal()

    while true do
        clear_inventory(false)
        turtle.select(1)

        -- Get a new list of items
        local items = list_items(inventories)

        -- Try to craft as many as possible of each recipe in order.
        -- TODO consider having a scheduler or something to not starve later recipes that share items.
        for name, recipe in pairs(recipes) do
            local able_to_craft = true
            local num_to_craft = 64
            for item, count in pairs(recipe.ingredients) do
                if items[item] == nil or items[item].total < count then
                    able_to_craft = false
                    break
                end
                local possible = items[item].total / count
                if possible < num_to_craft then
                    num_to_craft = possible
                end
            end

            -- If we have all of the required ingredients, craft as many as possible.
            if able_to_craft then
                print("Crafting " .. name .. ": " .. num_to_craft)
                clear_inventory(false)
                turtle.select(1)

                -- Load the crafting grid with the required items.
                for slot,item in pairs(recipe.pattern) do
                    if item ~= nil then
                        fetch_item(items[item].locations, self_name, CRAFTING_SLOT_MAPPING[slot], num_to_craft)
                    end
                end

                local success, err = turtle.craft(num_to_craft)
                if success then
                    clear_inventory(true)
                    turtle.select(1)
                else
                    print("Failed to craft: " .. err)
                end
            end
        end

        os.sleep(SLEEP_TIME)
    end

end

function get_inventories(modem)
    local peripherals = modem.getNamesRemote()
    local inventories = {}
    for _, p in ipairs(peripherals) do
        if modem.hasTypeRemote(p, "inventory") then
            inventories[#inventories+1] = p
        end
    end
    return inventories
end

function list_items(inventories)
    local items = {}
    for _, inv_name in ipairs(inventories) do
        inv = peripheral.wrap(inv_name)
        for slot, item in pairs(inv.list()) do
            -- Save the location and count of the item in the items table.
            local location = {name = inv_name, slot = slot, count = item.count}
            if items[item.name] == nil then
                items[item.name] = {total = item.count, locations = {location}}
            else 
                items[item.name].total = items[item.name].total + item.count
                local locations = items[item.name].locations
                locations[#locations+1] = location
                items[item.name].locations = locations
            end
        end
    end

    return items
end

function fetch_item(locations, dest_name, dest_slot, count)
    local remaining = count

    -- Go through as many locations as needed for the desired count.
    for _, location in ipairs(locations) do
        if location.count ~= 0 then
            local inv = peripheral.wrap(location.name)
            local moved = inv.pushItems(dest_name, location.slot, remaining, dest_slot)
            remaining = remaining - moved

            -- Make sure to update the locations accurately by directly reading item count.
            local slot_data = inv.getItemDetail(location.slot)
            if slot_data == nil then
                location.count = 0
            else
                location.count = slot_data.count
            end
        end

        if remaining <= 0 then
            break
        end
    end
end

function create_recipe(pattern)
    -- Count each ingredient in the pattern
    local ingredients = {}
    for _, ing in pairs(pattern) do
        if ingredients[ing] == nil then
            ingredients[ing] = 1
        else
            ingredients[ing] = ingredients[ing] + 1
        end
    end

    local recipe = {ingredients = ingredients, pattern = pattern}
    return recipe
end

function clear_inventory(output)
    for i = 1, 16 do
        turtle.select(i)
        if output then
            turtle.drop()
        else
            turtle.dropDown()
        end
    end
end



main()
