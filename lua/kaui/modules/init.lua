local modules = {}

-- Future runtime modules are registered here so main.lua stays stable.
local registry = {
    require('kaui.modules.heartbeat'),
    require('kaui.ui').create_module,
}

function modules.registry()
    return registry
end

function modules.load_all(context)
    local loaded = {}

    for _, module_factory in ipairs(registry) do
        local module = module_factory(context)
        if module then
            table.insert(loaded, module)
        end
    end

    return loaded
end

return modules
