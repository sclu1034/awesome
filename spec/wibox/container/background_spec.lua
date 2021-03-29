---------------------------------------------------------------------------
-- @author Uli Schlachter
-- @copyright 2017 Uli Schlachter
---------------------------------------------------------------------------

local background = require("wibox.container.background")
local utils = require("wibox.test_utils")
local p = require("wibox.widget.base").place_widget_at

describe("wibox.container.background", function()
    it("common interfaces", function()
        utils.test_container(background())
    end)

    describe("layout", function()
        describe("empty", function()
            it("no border", function()
                local w = background()
                assert.widget_layout(w, { 0, 0 }, {})
            end)

            it("border", function()
                local w = background()
                w:set_border_width(5)
                assert.widget_layout(w, { 0, 0 }, {})
            end)

            it("inner border", function()
                local w = background()
                w:set_border_width(5)
                w:set_border_strategy("inner")
                assert.widget_layout(w, { 0, 0 }, {})
            end)
        end)

        describe("child widget", function()
            local child = utils.widget_stub(10, 10)
            local widget

            before_each(function()
                widget = background(child)
            end)

            it("has widget", function()
                assert.widget_layout(widget, { 10, 10 }, {
                    p(child, 0, 0, 10, 10 )
                })
            end)

            it("uniform border", function()
                widget:set_border_width(5)
                assert.widget_layout(widget, { 10, 10 }, {
                    p(child, 0, 0, 10, 10 )
                })
            end)

            it("inner uniform border", function()
                widget:set_border_width(5)
                widget:set_border_strategy("inner")
                assert.widget_layout(widget, { 20, 20 }, {
                    p(child, 5, 5, 10, 10 )
                })
            end)

            it("separate borders", function()
                widget:set_border_width({ left = 5, right = 0, top = 0, bottom = 2 })
                assert.widget_layout(widget, { 10, 10 }, {
                    p(child, 0, 0, 10, 10 )
                })
            end)

            it("separate inner borders", function()
                widget:set_border_width({ left = 5, right = 0, top = 0, bottom = 2 })
                widget:set_border_strategy("inner")
                assert.widget_layout(widget, { 20, 20 }, {
                    p(child, 5, 0, 15, 18 )
                })
            end)
        end)
    end)

    describe("fit", function()
        describe("empty", function()
            it("no border", function()
                local w = background()
                assert.widget_fit(w, { 0, 0 }, { 0, 0 })
            end)

            it("border", function()
                local w = background()
                w:set_border_width(5)
                assert.widget_fit(w, { 0, 0 }, { 0, 0 })
            end)

            it("inner border", function()
                local w = background()
                w:set_border_width(5)
                w:set_border_strategy("inner")
                assert.widget_fit(w, { 0, 0 }, { 0, 0 })
            end)
        end)

        describe("child widget", function()
            local child = utils.widget_stub(10, 10)
            local widget

            before_each(function()
                widget = background(child)
            end)

            it("has widget", function()
                assert.widget_fit(widget, { 10, 10 }, { 10, 10 })
            end)

            it("uniform border", function()
                widget:set_border_width(5)
                assert.widget_fit(widget, { 10, 10 }, { 10, 10 })
            end)

            it("inner uniform border", function()
                widget:set_border_width(5)
                widget:set_border_strategy("inner")
                assert.widget_fit(widget, { 20, 20 }, { 20, 20 })
            end)

            it("separate borders", function()
                widget:set_border_width({ left = 5, right = 0, top = 0, bottom = 2 })
                assert.widget_fit(widget, { 10, 10 }, { 10, 10 })
            end)

            it("separate inner borders", function()
                widget:set_border_width({ left = 5, right = 0, top = 0, bottom = 2 })
                widget:set_border_strategy("inner")
                assert.widget_fit(widget, { 20, 20 }, { 15, 12 })
            end)
        end)
    end)
end)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
