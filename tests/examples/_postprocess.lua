#!/usr/bin/env lua

-- This script takes `.svg` file generated by Cairo or Inkscape and
-- replace hardcoded colors so they can be set using CSS or the
-- web browser itself. This makes the accessibility mode work and
-- allows themes to be created for the documentation.

local input, output = ...

-- The second 24bit is just the 32 bit converted to #010001 and back.
local FOREGROUNDS = {
    "rgb[(]0[.]5%%,0%%,0[.]5%%[)];",
    "rgb[(]0[.]392157%%,0%%,0[.]392157%%[)];"
}

local CLASSES = {
    stroke = ".svg_stroke",
    fill   = ".svg_fill"
}

local i, o = io.open(input, "r"), io.open(output, "w")

if (not i) or (not o) then return end

local line, count = i:read("*line"), 0

while line do
    -- Deduplicate and concatenate the classes.
    local classes = {}

    for _, token in ipairs { "fill", "stroke" } do

        for _, color in ipairs(FOREGROUNDS) do
            line, count = line:gsub(token .. ":" .. color, token .. ":currentcolor;")

            -- Add the CSS class.
            if count > 0 then
                classes[CLASSES[token]] = true
            end
        end
    end

    local class_str = {}

    for class in pairs(classes) do
        table.insert(class_str, class)
    end

    if #class_str > 0 then
        line = line:gsub(' style="', ' class="' .. table.concat(class_str, ",") .. '" style="')
    end

    o:write(line .. "\n")
    line = i:read("*line")
end

o:close()
