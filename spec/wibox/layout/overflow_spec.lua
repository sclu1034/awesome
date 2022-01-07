---------------------------------------------------------------------------
-- @author Lucas Schwiderski
-- @copyright 2021 Lucas Schwiderski
---------------------------------------------------------------------------

local overflow = require("wibox.layout.overflow")
local base = require("wibox.widget.base")
local utils = require("wibox.test_utils")
local p = require("wibox.widget.base").place_widget_at
local spy = require("luassert.spy")

describe("wibox.layout.overflow", function()
    local layout_vertical
    local layout_horizontal
    before_each(function()
        layout_vertical = overflow.vertical()
        layout_horizontal = overflow.horizontal()
    end)

    it("empty layout fit", function()
        assert.widget_fit(layout_vertical, { 10, 10 }, { 0, 0 })
        assert.widget_fit(layout_horizontal, { 10, 10 }, { 0, 0 })
    end)

    it("empty layout layout", function()
        assert.widget_layout(layout_vertical, { 0, 0 }, {})
        assert.widget_layout(layout_horizontal, { 0, 0 }, {})
    end)

    it("empty add", function()
        assert.has_error(function()
            layout_vertical:add()
            layout_horizontal:add()
        end)
    end)

    describe("with widgets", function()
        local first, second, third

        before_each(function()
            first = utils.widget_stub(10, 10)
            second = utils.widget_stub(15, 15)
            third = utils.widget_stub(10, 10)

            layout_vertical:add(first, second, third)
            layout_horizontal:add(first, second, third)
        end)

        describe("with enough space", function()
            it("fit", function()
                assert.widget_fit(layout_vertical, { 100, 100 }, { 15, 35 })
                assert.widget_fit(layout_horizontal, { 100, 100 }, { 35, 15 })
            end)

            it("layout", function()
                assert.widget_layout(layout_vertical, { 100, 100 }, {
                    p(first,  0,  0, 100, 10),
                    p(second, 0, 10, 100, 15),
                    p(third,  0, 25, 100, 10),
                })
                assert.widget_layout(layout_horizontal, { 100, 100 }, {
                    p(first,   0, 0, 100, 10),
                    p(second, 10, 0, 100, 15),
                    p(third,  20, 0, 100, 10),
                })
            end)
        end)

        describe("without enough width", function()
            it("fit", function()
                assert.widget_fit(layout_vertical, { 5, 100 }, { 5, 35 })
                assert.widget_fit(layout_horizontal, { 5, 100 }, { 5, 15 })
            end)

            it("layout", function()
                assert.widget_layout(layout_vertical, { 5, 100 }, {
                    p(first,  0,  0, 5, 10),
                    p(second, 0, 10, 5, 15),
                    p(third,  0, 25, 5, 10),
                })
                assert.widget_layout(layout_horizontal, { 5, 100 }, {
                    p(first,   0, 0, 10, 10),
                    p(second, 10, 0, 15, 15),
                    p(third,  25, 5, 10, 10),
                })
            end)
        end)

        describe("without enough height", function()
            it("fit", function()
                assert.widget_fit(layout_vertical, { 100, 20 }, { 20, 20 })
                assert.widget_fit(layout_horizontal, { 100, 20 }, { 20, 20 })
            end)

            it("layout", function()
                local scrollbar = utils.widget_stub(10, 10)
                layout_vertical:set_scrollbar_widget(scrollbar)
                layout_horizontal:set_scrollbar_widget(scrollbar)

                assert.widget_layout(layout_vertical, { 100, 20 }, {
                    p(scrollbar,   95,  0,  5, 10),
                    p(first,  0,  0, 95, 10),
                    p(second, 0, 10, 95, 15),
                })
                assert.widget_layout(layout_horizontal, { 100, 20 }, {
                    p(scrollbar,   95,  0,  5, 10),
                    p(first,  0,  0, 95, 10),
                    p(second, 0, 10, 95, 15),
                })
            end)
        end)
    end)

    describe("scrolling", function()
        local first, second, third
        local scrollbar = utils.widget_stub(10, 10)

        before_each(function()
            first = utils.widget_stub(10, 10)
            second = utils.widget_stub(15, 15)
            third = utils.widget_stub(10, 10)

            layout_vertical:add(first, second, third)
            layout_vertical:set_scrollbar_widget(scrollbar)

            layout_horizontal:add(first, second, third)
            layout_horizontal:set_scrollbar_widget(scrollbar)
        end)

        it("to end", function()
            assert.widget_layout(layout_vertical, { 100, 20 }, {
                p(scrollbar,   95,  0,  5, 10),
                p(first,  0,  0, 95, 10),
                p(second, 0, 10, 95, 15),
            })
            assert.widget_layout(layout_horizontal, { 100, 20 }, {
                p(scrollbar,   95,  0,  5, 10),
                p(first,  0,  0, 95, 10),
                p(second, 0, 10, 95, 15),
            })

            layout_vertical:set_scroll_factor(1)
            layout_horizontal:set_scroll_factor(1)

            assert.widget_layout(layout_vertical, { 100, 20 }, {
                p(scrollbar,   95,  9,  5, 10),
                p(first,  0,  -15, 95, 10),
                p(second, 0, -5, 95, 15),
                p(third, 0, 10, 95, 10),
            })
            assert.widget_layout(layout_horizontal, { 100, 20 }, {
                p(scrollbar,   95,  9,  5, 10),
                p(first,  0,  -15, 95, 10),
                p(second, 0, -5, 95, 15),
                p(third, 0, 10, 95, 10),
            })
        end)

        it("one step", function()
            assert.widget_layout(layout_vertical, { 100, 20 }, {
                p(scrollbar,   95,  0,  5, 10),
                p(first,  0,  0, 95, 10),
                p(second, 0, 10, 95, 15),
            })
            assert.widget_layout(layout_horizontal, { 100, 20 }, {
                p(scrollbar,   95,  0,  5, 10),
                p(first,  0,  0, 95, 10),
                p(second, 0, 10, 95, 15),
            })

            layout_vertical:scroll(1)
            layout_horizontal:scroll(1)

            assert.widget_layout(layout_vertical, { 100, 20 }, {
                p(scrollbar,   95,  2,  5, 10),
                p(first,  0,  -5, 95, 10),
                p(second, 0, 5, 95, 15),
            })

            assert.widget_layout(layout_horizontal, { 100, 20 }, {
                p(scrollbar,   95,  2,  5, 10),
                p(first,  0,  -5, 95, 10),
                p(second, 0, 5, 95, 15),
            })
        end)
    end)

    describe("emitting signals", function()
        local spy_vertical
        local spy_horizontal
        before_each(function()
            -- I'm not aware of a method to reset a spy's counters,
            -- so they have to be re-created.
            layout_vertical:disconnect_signal("widget::layout_changed", spy_vertical)
            layout_horizontal:disconnect_signal("widget::layout_changed", spy_horizontal)

            spy_vertical = spy(function() end)
            spy_horizontal = spy(function() end)

            layout_vertical:connect_signal("widget::layout_changed", spy_vertical)
            layout_horizontal:connect_signal("widget::layout_changed", spy_horizontal)
        end)

        it("add", function()
            local w1, w2 = base.empty_widget(), base.empty_widget()
            assert.is.equal(0, layout_changed)
            layout:add(w1)
            assert.is.equal(1, layout_changed)
            layout:add(w2)
            assert.is.equal(2, layout_changed)
            layout:add(w2)
            assert.is.equal(3, layout_changed)
        end)

        it("set_spacing", function()
            assert.is.equal(0, layout_changed)
            layout:set_spacing(0)
            assert.is.equal(0, layout_changed)
            layout:set_spacing(5)
            assert.is.equal(1, layout_changed)
            layout:set_spacing(2)
            assert.is.equal(2, layout_changed)
            layout:set_spacing(2)
            assert.is.equal(2, layout_changed)
        end)

        it("reset", function()
            assert.is.equal(0, layout_changed)
            layout:add(base.make_widget())
            assert.is.equal(1, layout_changed)
            layout:reset()
            assert.is.equal(2, layout_changed)
        end)

        it("fill_space", function()
            assert.is.equal(0, layout_changed)
            layout:fill_space(false)
            assert.is.equal(1, layout_changed)
            layout:fill_space(true)
            assert.is.equal(2, layout_changed)
            layout:fill_space(true)
            assert.is.equal(2, layout_changed)
            layout:fill_space(false)
            assert.is.equal(3, layout_changed)
        end)
    end)

    it("set_children", function()
        local w1, w2 = base.empty_widget(), base.empty_widget()

        assert.is.same({}, layout:get_children())

        layout:add(w1)
        assert.is.same({ w1 }, layout:get_children())

        layout:add(w2)
        assert.is.same({ w1, w2 }, layout:get_children())

        layout:reset()
        assert.is.same({}, layout:get_children())
    end)

    it("can draw `wibox.layout.fixed` as child", function()
        local fixed = require("wibox.layout.fixed")
        local w1 = utils.widget_stub(10, 10)
        local w2 = utils.widget_stub(10, 10)
        local lfixed = fixed.vertical()
        lfixed:add(w1)
        lfixed:add(w2)

        layout:add(lfixed)

        assert.widget_layout(layout, { 100, 100 }, {
            p(lfixed, 0, 0, 100, 20),
        })
    end)
end)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
