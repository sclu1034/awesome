--DOC_GEN_IMAGE --DOC_HIDE
local parent    = ... --DOC_HIDE
local wibox     = require("wibox") --DOC_HIDE
local beautiful = require("beautiful") --DOC_HIDE

local function create_text(text) --DOC_HIDE
    return wibox.widget { --DOC_HIDE
        widget = wibox.widget.textbox, --DOC_HIDE
        markup = "<b>" .. text .. "</b>", --DOC_HIDE
    } --DOC_HIDE
end --DOC_HIDE

local text_widget = {
    text   = "Hello world!",
    widget = wibox.widget.textbox
}

local widgets = {
    create_text("no border"), --DOC_HIDE
    -- no border
    {
        text_widget,
        bg = beautiful.bg_normal,
        widget = wibox.container.background,
    },
    create_text("uniform border"), --DOC_HIDE
    -- uniform borders
    {
        text_widget,
        border_width = beautiful.border_width,
        border_color = beautiful.border_color,
        bg = beautiful.bg_normal,
        widget = wibox.container.background,
    },
    create_text("individual borders"), --DOC_HIDE
    -- individual borders
    {
        text_widget,
        border_width = { left = 10, right = 2, top = 0, bottom = 2 },
        border_color = beautiful.border_color,
        bg = beautiful.bg_normal,
        widget = wibox.container.background,
    },
}

widgets.layout = wibox.layout.fixed.vertical --DOC_HIDE
widgets.spacing = 10 --DOC_HIDE

parent:setup(widgets) --DOC_HIDE

--DOC_HIDE vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
