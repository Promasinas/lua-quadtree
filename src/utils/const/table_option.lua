local deep_copy
local shallow_copy
local deep_args_instead
local shallow_args_instead

function deep_copy(src_table)
    local copy_table = {}
    for key, value in pairs(src_table) do
        if type(value) == "table" then
            copy_table[key] = deep_copy(value)
        else
            copy_table[key] = value
        end
    end
    return copy_table
end

function shallow_copy(src_table)
    local copy_table = {}
    for key, value in pairs(src_table) do
        copy_table[key] = value
    end
    return copy_table
end

function deep_args_instead(args, table)
    if not args or not table then
        return table
    end

    for key, value in pairs(args) do
        if type(value) == "table" and type(table[key]) == "table" then
            table[key] = deep_args_instead(value, table[key])
        else
            if table[key] then
                table[key] = value
            end
        end
    end

    return table
end

function shallow_args_instead(args, default_table)
    local result_table = shallow_copy(default_table)
    for key, value in pairs(args) do
        result_table[key] = value
    end
    return result_table
end

local table_option = {
    deep_copy = deep_copy,
    shallow_copy = shallow_copy,
    deep_args_instead = deep_args_instead,
    shallow_args_instead = shallow_args_instead,
}

return table_option