local new_set = MiniTest.new_set
local expect = MiniTest.expect

local comment_list = require("review.ui.comment_list")
local config = require("review.config")
local export = require("review.export.markdown")
local state = require("review.state")

local original_export_send = export.send

local T = new_set({
    hooks = {
        pre_case = function()
            config.setup()
            state.reset()
            export.send = original_export_send
        end,
        post_case = function()
            export.send = original_export_send
            if comment_list.current then
                comment_list.destroy()
            end
        end,
    },
})

T["s keymap is registered and triggers send"] = function()
    state.add_comment("test.lua", 1, "note", "A review comment")

    local called_on_send = false
    local bufnr = vim.api.nvim_create_buf(false, true)
    local winid = vim.api.nvim_open_win(bufnr, true, {
        relative = "editor",
        width = 40,
        height = 10,
        row = 0,
        col = 0,
    })

    comment_list.create({ bufnr = bufnr, winid = winid }, {
        on_send = function()
            called_on_send = true
        end,
    })

    local keymaps = vim.api.nvim_buf_get_keymap(bufnr, "n")
    local s_map = nil
    for _, map in ipairs(keymaps) do
        if map.lhs == "s" then
            s_map = map
            break
        end
    end

    expect.equality(s_map ~= nil, true)
    expect.equality(s_map.desc, "Send comments")

    s_map.callback()
    expect.equality(called_on_send, true)

    if vim.api.nvim_win_is_valid(winid) then
        vim.api.nvim_win_close(winid, true)
    end
end

T["s keymap defaults to export.send when on_send callback is not provided"] = function()
    state.add_comment("test.lua", 1, "note", "A review comment")

    local original_send = export.send
    local export_send_called = false
    export.send = function()
        export_send_called = true
        return true
    end

    local bufnr = vim.api.nvim_create_buf(false, true)
    local winid = vim.api.nvim_open_win(bufnr, true, {
        relative = "editor",
        width = 40,
        height = 10,
        row = 0,
        col = 0,
    })

    comment_list.create({ bufnr = bufnr, winid = winid }, {})

    local keymaps = vim.api.nvim_buf_get_keymap(bufnr, "n")
    local s_map = nil
    for _, map in ipairs(keymaps) do
        if map.lhs == "s" then
            s_map = map
            break
        end
    end

    expect.equality(s_map ~= nil, true)
    s_map.callback()
    export.send = original_send

    expect.equality(export_send_called, true)

    if vim.api.nvim_win_is_valid(winid) then
        vim.api.nvim_win_close(winid, true)
    end
end

return T
