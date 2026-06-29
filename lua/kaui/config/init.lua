local config = {
    default_ini_prefix = 'KissAssist',
}

config.ini = require('kaui.config.ini')
config.schema = require('kaui.config.schema')
config.lists = require('kaui.config.lists')
config.manager = require('kaui.config.manager')

return config
