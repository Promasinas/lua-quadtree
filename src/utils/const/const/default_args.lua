

local default_args = {
    QuadTree = {
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
}

return default_args