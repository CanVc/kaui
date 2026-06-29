-- KAUI / KissAssist Lua entrypoint
-- Launch from MacroQuest with: /lua run kaui/main.lua

local source = debug.getinfo(1, 'S').source
local script_path = source:sub(1, 1) == '@' and source:sub(2) or source
local script_dir = script_path:match('^(.*[\\/])') or './'
local normalized_dir = script_dir:gsub('\\', '/')
local lua_root = normalized_dir:match('^(.*)/kaui/$') or normalized_dir

package.path = table.concat({
    lua_root .. '/?.lua',
    lua_root .. '/?/init.lua',
    normalized_dir .. '/?.lua',
    normalized_dir .. '/?/init.lua',
    package.path,
}, ';')

local ok_mq, mq = pcall(require, 'mq')
if not ok_mq then
    mq = nil
end

local app = require('kaui.core.app')

return app.start({ mq = mq })
