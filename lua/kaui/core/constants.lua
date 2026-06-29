local constants = {
    APP_NAME = 'KAUI',
    DISPLAY_NAME = 'KAUI / KissAssist Lua',
    VERSION = '0.5.0',
    INI_PREFIX = 'KissAssist',
    DEFAULT_PULSE_MS = 250,
}

function constants.banner()
    return string.format('%s v%s', constants.DISPLAY_NAME, constants.VERSION)
end

return constants
