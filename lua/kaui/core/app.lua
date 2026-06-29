local constants = require('kaui.core.constants')
local logger = require('kaui.core.logger')
local runtime = require('kaui.core.runtime')
local mq_helpers = require('kaui.core.mq')
local loop = require('kaui.core.loop')
local commands = require('kaui.core.commands')
local config_manager = require('kaui.config.manager')
local module_registry = require('kaui.modules')

local app = {}

function app.start(options)
    options = options or {}

    logger.configure({ mq = options.mq })
    mq_helpers.configure({ mq = options.mq })

    local state = runtime.new({
        mq = options.mq,
        pulse_ms = options.pulse_ms,
        mode = options.mode,
        role = options.role,
        args = options.args,
    })
    state:start()

    local context = {
        runtime = state,
        logger = logger,
        mq = mq_helpers,
    }

    logger.info('Starting ' .. constants.banner())

    if not options.mq then
        logger.warn('MacroQuest Lua not detected: limited standalone mode.')
    end

    if options.load_config ~= false then
        local config_state, _, config_error = config_manager.load_or_create(mq_helpers, logger, options.config)
        state.config = config_state
        state.config_error = config_error
    end

    local loaded_modules = module_registry.load_all(context)
    for _, module in ipairs(loaded_modules) do
        state:register_module(module)
        logger.info('Module loaded: ' .. module.name)
    end

    loop.call_hook_for_all(state, logger, 'onInit', context)

    if commands.bind(mq_helpers, state, logger) then
        logger.info('Command available: /kaui help')
    end

    logger.info('Bootstrap complete.')

    loop.run(state, context)

    loop.call_hook_for_all(state, logger, 'onShutdown', context)
    commands.unbind(mq_helpers)

    logger.info('Clean shutdown complete.')

    return state
end

return app
