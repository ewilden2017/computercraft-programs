-- Helper methods for common patterns
function box(name)
    return {name, name, name, name, nil, name, name, name, name}
end

function row(name)
    return {name, name, name}
end

local patterns = {}
patterns["Iron Ingot"] = box("mysticalagriculture:iron_essence")
patterns["Oak Log"] = row("mysticalagriculture:wood_essence")

return patterns
