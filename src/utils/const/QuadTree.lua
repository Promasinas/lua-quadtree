local default_args = require("src.utils.const.default_args")
local table_option = require("src.utils.table_option")

local new_root
local insert
local exist
local remove
local update
local clear

local new_node
local _find_node
local _divide_node
local _has_object_non_recursive
local _in_node_range
local _check_and_merge_node

function new_root(args)
    if not args then
        args = default_args.QuadTree
    end

    return new_node(args)
end

function exist(node, x, y, object)
    if not node or not x or not y then
        return false
    end

    local target_node = _find_node(node, x, y)
    if not target_node then
        return false
    end

    return _has_object_non_recursive(target_node, object)
end

function new_node(args)
    if not args then
        args = default_args.QuadTree
    end

    local node = {
        boundary = {
            x_max = 1024,
            x_min = -1024,
            y_max = 1024,
            y_min = -1024,
        },
        objects = {},
        capacity = 8,
        divided = false,
        top_left = nil,
        top_right = nil,
        bottom_left = nil,
        bottom_right = nil,

        parent = nil,
    }

    table_option.deep_args_instead(args, node)
    
    return node
end

function update(node, old_x, old_y, object)
    if not node or not object then
        return false
    end

    if not old_x or not old_y then
        return false
    end

    local old_node = _find_node(node, old_x, old_y)
    local new_node = _find_node(node, object.position.x, object.position.y)

    if old_node == new_node then
        return true
    end

    if remove(node, old_x, old_y, object) then
        return insert(node, object)
    else
        return false
    end
end

function clear(node)
    if not node then
        return
    end

    if node.divided then
        clear(node.top_left)
        clear(node.top_right)
        clear(node.bottom_left)
        clear(node.bottom_right)
    end

    node.objects = {}
    node.divided = false
    node.top_left = nil
    node.top_right = nil
    node.bottom_left = nil
    node.bottom_right = nil
end

function insert(node, object)
    if not node or not object then
        return false
    end

    if not _in_node_range(node, object.position.x, object.position.y) then
        return false
    end

    local target_node = _find_node(node, object.position.x, object.position.y)
    if not target_node then
        return false
    end

    if #target_node.objects < target_node.capacity then
        table.insert(target_node.objects, object)
        return true
    else
        _divide_node(target_node)
        return insert(node, object)
    end
end

function remove(node, old_x, old_y, object)
    if not node or not object then
        return false
    end

    if not old_x or not old_y then
        return false
    end

    local target_node = _find_node(node, old_x, old_y)
    if not target_node then
        return false
    end

    if _has_object_non_recursive(target_node, object) then
        for i, obj in ipairs(target_node.objects) do
            if obj == object then
                table.remove(target_node.objects, i)
                
                local parent_node = target_node.parent

                if parent_node then
                    _check_and_merge_node(parent_node)
                end

                return true
            end
        end
    end

    return false
end

function _find_node(node, x, y)
    if not node or not x or not y then
        return nil
    end

    if node.divided then
        if _in_node_range(node.top_left, x, y) then
            return _find_node(node.top_left, x, y)
        elseif _in_node_range(node.top_right, x, y) then
            return _find_node(node.top_right, x, y)
        elseif _in_node_range(node.bottom_left, x, y) then
            return _find_node(node.bottom_left, x, y)
        elseif _in_node_range(node.bottom_right, x, y) then
            return _find_node(node.bottom_right, x, y)
        else
            return nil
        end
    else
        for _, obj in ipairs(node.objects) do
            if obj.position.x == x and obj.position.y == y then
                return node
            end
        end

        return nil
    end
end


function _check_and_merge_node(node)
    if not node then
        return false
    end

    if not node.divided then
        return false
    end

    if node.top_left.divided or node.top_right.divided or node.bottom_left.divided or node.bottom_right.divided then
        return false
    end

    if #node.top_left.objects + #node.top_right.objects + #node.bottom_left.objects + #node.bottom_right.objects > node.capacity then
        return false
    end

    for _, obj in ipairs(node.top_left.objects) do
        table.insert(node.objects, obj)
    end

    for _, obj in ipairs(node.top_right.objects) do
        table.insert(node.objects, obj)
    end

    for _, obj in ipairs(node.bottom_left.objects) do
        table.insert(node.objects, obj)
    end

    for _, obj in ipairs(node.bottom_right.objects) do
        table.insert(node.objects, obj)
    end

    node.top_left = nil
    node.top_right = nil
    node.bottom_left = nil
    node.bottom_right = nil
    node.divided = false

    return true
end

function _divide_node(node)
    if not node then
        return
    end

    if node.divided then
        return
    end

    node.top_left = new_node({
        boundary = {
            x_max = (node.boundary.x_min + node.boundary.x_max) / 2,
            x_min = node.boundary.x_min,
            y_max = node.boundary.y_max,
            y_min = (node.boundary.y_min + node.boundary.y_max) / 2,
        },
        capacity = node.capacity,
        parent = node,
    })
    node.top_right = new_node({
        boundary = {
            x_max = node.boundary.x_max,
            x_min = (node.boundary.x_min + node.boundary.x_max) / 2,
            y_max = node.boundary.y_max,
            y_min = (node.boundary.y_min + node.boundary.y_max) / 2,
        },
        capacity = node.capacity,
        parent = node,
    })
    node.bottom_left = new_node({
        boundary = {
            x_max = (node.boundary.x_min + node.boundary.x_max) / 2,
            x_min = node.boundary.x_min,
            y_max = (node.boundary.y_min + node.boundary.y_max) / 2,
            y_min = node.boundary.y_min,
        },
        capacity = node.capacity,
        parent = node,
    })
    node.bottom_right = new_node({
        boundary = {
            x_max = node.boundary.x_max,
            x_min = (node.boundary.x_min + node.boundary.x_max) / 2,
            y_max = (node.boundary.y_min + node.boundary.y_max) / 2,
            y_min = node.boundary.y_min,
        },
        capacity = node.capacity,
        parent = node,
    })
    node.divided = true

    for _, obj in ipairs(node.objects) do
        if _in_node_range(node.top_left, obj.position.x, obj.position.y) then
            insert(node.top_left, obj)
        elseif _in_node_range(node.top_right, obj.position.x, obj.position.y) then
            insert(node.top_right, obj)
        elseif _in_node_range(node.bottom_left, obj.position.x, obj.position.y) then
            insert(node.bottom_left, obj)
        elseif _in_node_range(node.bottom_right, obj.position.x, obj.position.y) then
            insert(node.bottom_right, obj)
        end
    end

    node.objects = {}
end


-- function _has_position(node, x, y)
--     if not node or not x or not y then
--         return false
--     end

--     if node.divided then
--         node = _find_node(node, x, y)
--         if not node then
--             return false
--         end
--     else
--         for _, obj in ipairs(node.objects) do
--             if obj.position.x == x and obj.position.y == y then
--                 return true
--             end
--         end
--         return false
--     end
-- end


function _has_object_non_recursive(node, object)
    if not node or not object then
        return false
    end

    if node.divided then
        return false
    end

    for _, obj in ipairs(node.objects) do
        if obj == object then
            return true
        end
    end

    return false
end


function _in_node_range(node, x, y)
    if not node or not x or not y then
        return false
    end

    return x >= node.boundary.x_min and x < node.boundary.x_max and y >= node.boundary.y_min and y < node.boundary.y_max
end

local QuadTree = {
    new_root = new_root,
    insert = insert,
    remove = remove,
    exist = exist,
    clear = clear,
    update = update,
}

return QuadTree
