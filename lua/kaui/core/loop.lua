local loop = {}

local function safe_module_call(logger, module, hook_name, context)
    local hook = module and module[hook_name]
    if type(hook) ~= 'function' then
        return true
    end

    local ok, err = pcall(hook, context)
    if not ok then
        logger.error(string.format('Module error %s.%s: %s', module.name or '?', hook_name, tostring(err)))
        return false
    end

    return true
end

function loop.call_hook_for_all(state, logger, hook_name, context)
    for _, module in ipairs(state:get_modules()) do
        if module.enabled ~= false then
            safe_module_call(logger, module, hook_name, context)
        end
    end
end

function loop.run(state, context)
    local logger = context.logger
    local mq_helpers = context.mq
    logger.info(string.format('Main loop active: pulse %d ms.', state.pulse_ms))

    while state.running do
        if not state.paused then
            state:refresh(mq_helpers)
            loop.call_hook_for_all(state, logger, 'onPulse', context)
        end

        if mq_helpers and mq_helpers.is_available() then
            mq_helpers.delay(state.pulse_ms)
        else
            -- Outside MacroQuest, avoid blocking the terminal with an infinite loop.
            state:stop()
        end
    end
end

return loop
