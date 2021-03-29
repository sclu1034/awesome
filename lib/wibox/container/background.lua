---------------------------------------------------------------------------
-- A container capable of changing the background color, foreground color and
-- widget shape.
--
--@DOC_wibox_container_defaults_background_EXAMPLE@
-- @author Uli Schlachter
-- @copyright 2010 Uli Schlachter
-- @containermod wibox.container.background
---------------------------------------------------------------------------

local base = require("wibox.widget.base")
local color = require("gears.color")
local surface = require("gears.surface")
local beautiful = require("beautiful")
local cairo = require("lgi").cairo
local gtable = require("gears.table")
local gshape = require("gears.shape")
local gdebug = require("gears.debug")
local setmetatable = setmetatable
local type = type
local unpack = unpack or table.unpack -- luacheck: globals unpack (compatibility with Lua 5.1)

local background = { mt = {} }

-- The Cairo SVG backend doesn't support surface as patterns correctly.
-- The result is both glitchy and blocky. It is also impossible to introspect.
-- Calling this function replaces the normal code path with a "less correct",
-- but more widely compatible version.
function background._use_fallback_algorithm()
    background.before_draw_children = function(self, _, cr, width, height)
        local border_left = self._private.border_left
        local border_right = self._private.border_right
        local border_top = self._private.border_top
        local border_bottom = self._private.border_bottom

        local has_border = border_left ~= 0 or
                           border_right ~= 0 or
                           border_top ~= 0 or
                           border_bottom ~= 0

        local shape = self._private.shape or gshape.rectangle
        local inner_width = width - (border_left + border_right)
        local inner_height = height - (border_top + border_bottom)

        if self._private.background then
            -- Save to avoid messing with the original source
            cr:save()
            cr:set_source(self._private.background)
            cr:paint()
            cr:restore()
        end

        -- Adjust the content's position and size to add border around it
        if has_border then
            cr:translate(border_left, border_top)
            inner_width = width - (border_left + border_right)
            inner_height = height - (border_top + border_bottom)
        end

        -- Apply shape to inner content
        shape(cr, inner_width, inner_height)

        if has_border then
            cr:translate(-border_left, -border_top)
        end

        if self._private.foreground then
            cr:set_source(self._private.foreground)
        end
    end
    background.after_draw_children = function(self, _, cr, width, height)
        local border_left = self._private.border_left
        local border_right = self._private.border_right
        local border_top = self._private.border_top
        local border_bottom = self._private.border_bottom

        local has_border = border_left ~= 0 or
                           border_right ~= 0 or
                           border_top ~= 0 or
                           border_bottom ~= 0

        if not has_border then
            return
        end

        local border_color = self._private.shape_border_color or
                             self._private.foreground or
                             beautiful.fg_normal

        cr:set_source(color(border_color))

        -- For each side, draw a line with that side's border
        cr:set_line_width(border_left)
        cr:move_to(0, 0)
        cr:line_to(0, height)
        cr:stroke_preserve()

        cr:set_line_width(border_bottom)
        cr:move_to(0, height)
        cr:line_to(width, height)
        cr:stroke_preserve()

        cr:set_line_width(border_right)
        cr:move_to(width, height)
        cr:line_to(width, 0)
        cr:stroke_preserve()

        cr:set_line_width(border_top)
        cr:move_to(0, 0)
        cr:line_to(width, 0)
        cr:stroke_preserve()
    end
end

-- Draw background color and/or image
function background:before_draw_children(context, cr, width, height)
    local border_left = self._private.border_left
    local border_right = self._private.border_right
    local border_top = self._private.border_top
    local border_bottom = self._private.border_bottom

    local has_border = border_left ~= 0 or
                       border_right ~= 0 or
                       border_top ~= 0 or
                       border_bottom ~= 0

    -- Redirect drawing to a temporary surface. We'll need this later.
    if has_border then
        cr:push_group_with_content(cairo.Content.COLOR_ALPHA)
    end

    -- Draw the background color
    if self._private.background then
        cr:save()
        cr:set_source(self._private.background)
        cr:rectangle(0, 0, width, height)
        cr:fill()
        cr:restore()
    end

    if self._private.bgimage then
        cr:save()
        if type(self._private.bgimage) == "function" then
            self._private.bgimage(context, cr, width, height, unpack(self._private.bgimage_args))
        else
            local pattern = cairo.Pattern.create_for_surface(self._private.bgimage)
            cr:set_source(pattern)
            cr:rectangle(0, 0, width, height)
            cr:fill()
        end
        cr:restore()
    end

    -- Set the default color for children
    if self._private.foreground then
        cr:set_source(self._private.foreground)
    end
end

-- Draw the border.
-- Layout for the `inner` strategy has already been handled.
function background:after_draw_children(_, cr, width, height)
    local border_left = self._private.border_left
    local border_right = self._private.border_right
    local border_top = self._private.border_top
    local border_bottom = self._private.border_bottom

    local has_border = border_left ~= 0 or
                       border_right ~= 0 or
                       border_top ~= 0 or
                       border_bottom ~= 0

    if not has_border then
        return
    end

    local shape = self._private.shape or gshape.rectangle
    local border_color = self._private.shape_border_color or
                         self._private.foreground or
                         beautiful.fg_normal
    local inner_width = width - (border_left + border_right)
    local inner_height = height - (border_top + border_bottom)

    -- We begin with building a mask on a temporary surface
    cr:push_group_with_content(cairo.Content.ALPHA)

    -- Mark everything as potential border
    cr:set_source_rgba(0, 0, 0, 1)
    cr:paint()

    -- Apply the inner shape
    cr:translate(border_left, border_top)
    shape(
        cr,
        inner_width,
        inner_height,
        unpack(self._private.shape_args or {})
    )
    cr:translate(-border_left, -border_top)

    -- Crucial operator change, so that the following
    -- transparency draws correctly into the mask
    cr:set_operator(cairo.Operator.SOURCE)
    -- By drawing with full transparency, we mark the inner part as
    -- "not border"
    cr:set_source_rgba(0, 0, 0, 0)
    cr:fill()

    local mask = cr:pop_group()

    -- We got our mask.
    -- Now actually draw the border via the mask we just created.
    cr:set_source(color(border_color))
    cr:set_operator(cairo.Operator.OVER)
    cr:mask(mask)

    -- And clean up after ourselves
    local _, s = mask:get_surface()
    s:finish()

    -- We pushed in `background:before_draw_children`, so everything done
    -- can be turned into a single source. This can then be drawn using the
    -- outer shape.
    cr:pop_group_to_source()
    shape(
        cr,
        width,
        height,
        unpack(self._private.shape_args or {})
    )
    cr:fill()
end

-- Layout this widget
function background:layout(_, width, height)
    if not self._private.widget then
        return
    end

    if self._private.border_strategy ~= "inner" then
        return { base.place_widget_at(
            self._private.widget, 0, 0, width, height
        ) }
    end

    local border_left = self._private.border_left
    local border_right = self._private.border_right
    local border_top = self._private.border_top
    local border_bottom = self._private.border_bottom

    local inner_width = width - (border_left + border_right)
    local inner_height = height - (border_top + border_bottom)

    return { base.place_widget_at(
        self._private.widget, border_left, border_top, inner_width, inner_height
    ) }
end

-- Fit this widget into the given area
function background:fit(context, width, height)
    if not self._private.widget then
        return 0, 0
    end

    if self._private.border_strategy ~= "inner" then
        return base.fit_widget(
            self, context, self._private.widget, width, height
        )
    end

    local border_left = self._private.border_left
    local border_right = self._private.border_right
    local border_top = self._private.border_top
    local border_bottom = self._private.border_bottom

    local inner_width = width - (border_left + border_right)
    local inner_height = height - (border_top + border_bottom)

    local w, h = base.fit_widget(
        self, context, self._private.widget, inner_width, inner_height
    )

    return w + (border_left + border_right), h + (border_top + border_bottom)
end

--- The widget displayed in the background widget.
-- @property widget
-- @tparam widget widget The widget to be disaplayed inside of the background
--  area.
-- @interface container

background.set_widget = base.set_widget_common

function background:get_widget()
    return self._private.widget
end

function background:get_children()
    return {self._private.widget}
end

function background:set_children(children)
    self:set_widget(children[1])
end

--- The background color/pattern/gradient to use.
--
--@DOC_wibox_container_background_bg_EXAMPLE@
--
-- @property bg
-- @tparam color bg A color string, pattern or gradient
-- @see gears.color
-- @propemits true false

function background:set_bg(bg)
    if bg then
        self._private.background = color(bg)
    else
        self._private.background = nil
    end
    self:emit_signal("widget::redraw_needed")
    self:emit_signal("property::bg", bg)
end

function background:get_bg()
    return self._private.background
end

--- The foreground (text) color/pattern/gradient to use.
--
--@DOC_wibox_container_background_fg_EXAMPLE@
--
-- @property fg
-- @tparam color fg A color string, pattern or gradient
-- @propemits true false
-- @see gears.color

function background:set_fg(fg)
    if fg then
        self._private.foreground = color(fg)
    else
        self._private.foreground = nil
    end
    self:emit_signal("widget::redraw_needed")
    self:emit_signal("property::fg", fg)
end

function background:get_fg()
    return self._private.foreground
end

--- The background shape.
--
-- Use `set_shape` to set additional shape paramaters.
--
--@DOC_wibox_container_background_shape_EXAMPLE@
--
-- @property shape
-- @tparam gears.shape|function shape A function taking a context, width and height as arguments
-- @see gears.shape
-- @see set_shape

--- Set the background shape.
--
-- Any other arguments will be passed to the shape function.
--
-- @method set_shape
-- @tparam gears.shape|function shape A function taking a context, width and height as arguments
-- @propemits true false
-- @see gears.shape
-- @see shape
function background:set_shape(shape, ...)
    local args = {...}

    if shape == self._private.shape and #args == 0 then return end

    self._private.shape = shape
    self._private.shape_args = {...}
    self:emit_signal("widget::redraw_needed")
    self:emit_signal("property::shape", shape)
end

function background:get_shape()
    return self._private.shape
end

--- When a `shape` is set, also draw a border.
--
-- See `wibox.container.background.shape` for an usage example.
--
-- @deprecatedproperty shape_border_width
-- @tparam number width The border width
-- @renamedin 4.4 border_width
-- @see border_width

--- Add a border of a specific width.
-- Pass a number to set all four edges to the same border width. Pass
-- a table to specify individual values.
--
-- If the shape is set, both border and content will be shaped.
--
--@DOC_wibox_container_background_border_EXAMPLE@
--
-- @property border_width
-- @tparam[opt=0] number|table width The border width.
-- @propemits true false
-- @introducedin 4.4
-- @see border_color

function background:set_border_width(val)
    if not val then
        val = 0
    end

    if type(val) == "number" then
        if self._private.border_left   == val and
           self._private.border_right  == val and
           self._private.border_top    == val and
           self._private.border_bottom == val then
            return
        end

        self._private.border_left   = val
        self._private.border_right  = val
        self._private.border_top    = val
        self._private.border_bottom = val
    elseif type(val) == "table" then
        self._private.border_left   = val.left   or self._private.border_left
        self._private.border_right  = val.right  or self._private.border_right
        self._private.border_top    = val.top    or self._private.border_top
        self._private.border_bottom = val.bottom or self._private.border_bottom
    end

    self:emit_signal("widget::redraw_needed")
    self:emit_signal("property::border_width", val)
end

function background:get_border_width()
    return self._private.shape_border_width
end

function background.get_shape_border_width(...)
    gdebug.deprecate("Use `border_width` instead of `shape_border_width`",
        {deprecated_in=5})

    return background.get_border_width(...)
end

function background.set_shape_border_width(...)
    gdebug.deprecate("Use `border_width` instead of `shape_border_width`",
        {deprecated_in=5})

    background.set_border_width(...)
end

--- When a `shape` is set, also draw a border.
--
-- See `wibox.container.background.shape` or
-- `wibox.container.background.border_width` for a usage example.
--
-- @deprecatedproperty shape_border_color
-- @usebeautiful beautiful.fg_normal Fallback when 'fg' and `border_color` aren't set.
-- @tparam[opt=self._private.foreground] color fg The border color, pattern or gradient
-- @renamedin 4.4 border_color
-- @see gears.color
-- @see border_color

--- Set the color for the border.
--
-- See `wibox.container.background.shape` or
-- `wibox.container.background.border_width` for a usage example.
-- @property border_color
-- @tparam[opt=self._private.foreground] color fg The border color, pattern or gradient
-- @propemits true false
-- @usebeautiful beautiful.fg_normal Fallback when 'fg' and `border_color` aren't set.
-- @introducedin 4.4
-- @see gears.color
-- @see border_width

function background:set_border_color(fg)
    if self._private.shape_border_color == fg then return end

    self._private.shape_border_color = fg
    self:emit_signal("widget::redraw_needed")
    self:emit_signal("property::border_color", fg)
end

function background:get_border_color()
    return self._private.shape_border_color
end

function background.get_shape_border_color(...)
    gdebug.deprecate("Use `border_color` instead of `shape_border_color`",
        {deprecated_in=5})

    return background.get_border_color(...)
end

function background.set_shape_border_color(...)
    gdebug.deprecate("Use `border_color` instead of `shape_border_color`",
        {deprecated_in=5})

    background.set_border_color(...)
end

function background:set_shape_clip(value)
    if value then return end
    require("gears.debug").print_warning("shape_clip property of background container was removed."
        .. " Use wibox.layout.stack instead if you want shape_clip=false.")
end

function background:get_shape_clip()
    require("gears.debug").print_warning("shape_clip property of background container was removed."
        .. " Use wibox.layout.stack instead if you want shape_clip=false.")
    return true
end

--- How the border width affects the contained widget.
--
-- The valid values are:
--
-- * *none*: Just apply the border, do not affect the content size (default).
-- * *inner*: Squeeze the size of the content by the border width.
--
-- @property border_strategy
-- @tparam[opt="none"] string border_strategy

function background:set_border_strategy(value)
    self._private.border_strategy = value
    self:emit_signal("widget::layout_changed")
    self:emit_signal("property::border_strategy", value)
end

--- The background image to use.
--
-- If `image` is a function, it will be called with `(context, cr, width, height)`
-- as arguments. Any other arguments passed to this method will be appended.
--
-- @property bgimage
-- @tparam string|surface|function image A background image or a function
-- @see gears.surface

function background:set_bgimage(image, ...)
    self._private.bgimage = type(image) == "function" and image or surface.load(image)
    self._private.bgimage_args = {...}
    self:emit_signal("widget::redraw_needed")
    self:emit_signal("property::bgimage", image)
end

function background:get_bgimage()
    return self._private.bgimage
end

--- Returns a new background container.
--
-- A background container applies a background and foreground color
-- to another widget.
--
-- @tparam[opt] widget widget The widget to display.
-- @tparam[opt] color bg The background to use for that widget.
-- @tparam[opt] gears.shape|function shape A `gears.shape` compatible shape function
-- @constructorfct wibox.container.background
local function new(widget, bg, shape)
    local ret = base.make_widget(nil, nil, {
        enable_properties = true,
    })

    gtable.crush(ret, background, true)

    ret._private.shape = shape

    ret:set_widget(widget)
    ret:set_bg(bg)
    ret:set_border_width(0)

    return ret
end

function background.mt:__call(...)
    return new(...)
end

--@DOC_widget_COMMON@

--@DOC_object_COMMON@

return setmetatable(background, background.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
