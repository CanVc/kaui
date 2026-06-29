local constants = require('kaui.core.constants')

local runtime = {}
runtime.__index = runtime

function runtime.new(options)
    options = options or {}

    return setmetatable({
        name = constants.APP_NAME,
        version = constants.VERSION,
        mq = options.mq,
        running = false,
        paused = false,
        mode = options.mode or 'manual',
        role = options.role or 'unknown',
        pulse_ms = options.pulse_ms or constants.DEFAULT_PULSE_MS,
        pulse_count = 0,
        started_at = os.time(),
        timers = {
            started_at = os.time(),
            last_pulse = nil,
            last_snapshot = nil,
        },
        me = {
            name = nil,
            class = nil,
            level = nil,
            pct_hp = nil,
        },
        target = {
            id = nil,
            name = nil,
            pct_hp = nil,
        },
        config = nil,
        config_error = nil,
        ui = nil,
        modules = {},
        module_order = {},
    }, runtime)
end

function runtime:start()
    self.running = true
end

function runtime:stop()
    self.running = false
end

function runtime:pause()
    self.paused = true
end

function runtime:resume()
    self.paused = false
end

function runtime:register_module(module)
    if module and module.name and not self.modules[module.name] then
        self.modules[module.name] = module
        table.insert(self.module_order, module)
    end
end

function runtime:get_modules()
    return self.module_order
end

function runtime:refresh(mq_helpers)
    self.pulse_count = self.pulse_count + 1
    self.timers.last_pulse = os.time()
    self.timers.last_snapshot = self.timers.last_pulse

    if not mq_helpers or not mq_helpers.is_available() then
        return
    end

    self.me.name = mq_helpers.me_name()
    self.me.class = mq_helpers.me_class()
    self.me.level = mq_helpers.me_level()
    self.me.pct_hp = mq_helpers.me_pct_hp()

    self.target.id = mq_helpers.target_id()
    self.target.name = mq_helpers.target_name()
    self.target.pct_hp = mq_helpers.target_pct_hp()
end

return runtime
