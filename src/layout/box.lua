local class = require("lua-objects")

local Box = require("wonderful.geometry").Box
local Layout = require("wonderful.layout").Layout
local LayoutItem = require("wonderful.layout").LayoutItem

local Direction = {
  TopToBottom = 0,
  BottomToTop = 1,
  LeftToRight = 2,
  RightToLeft = 3
}

local function isVertical(direction)
  return direction == Direction.TopToBottom
      or direction == Direction.BottomToTop
end

local BoxLayout = class(Layout, {name = "wonderful.layout.box.BoxLayout"})

function BoxLayout:__new__(direction)
  self.direction = direction
end

function BoxLayout:recompose(el)  -- do not touch
  -- TODO: handle BTT and RTL directions

  local chunks = {}
  local i = 0
  local filled = 0
  local count = 0
  local lastMut = 0

  for _, child in ipairs(el:getLayoutItems()) do
    if child:getStretch() == 0 then
      local w, h = child:sizeHint()
      local margin = child:getMargin()

      if not chunks[i] or not chunks[i].const then
        i = i + 1
        chunks[i] = {const = true}
      end

      table.insert(chunks[i], child)
      filled = filled + (isVertical(self.direction)
                         and h + margin.t + margin.b
                          or w + margin.l + margin.r)
    else
      local margin = child:getMargin()

      i = i + 1
      count = count + child:getStretch()

      filled = filled + (isVertical(self.direction)
                         and margin.t + margin.b
                          or margin.l + margin.r)

      chunks[i] = {const = false, stretch = child:getStretch(), el = child}
      lastMut = i
    end
  end

  local box = el:getLayoutBox()
  local pad = el:getLayoutPadding()

  local full = isVertical(self.direction)
           and (box.h - pad.t - pad.b)
            or (box.w - pad.l - pad.r)

  local basis = (full - filled) / count
  local x, y = box.x + pad.l, box.y + pad.t

  for j, chunk in ipairs(chunks) do
    if chunk.const then
      for _, el in ipairs(chunk) do
        local w, h = el:sizeHint()
        local margin = el:getMargin()

        el:boxCalculated(Box(x + margin.l, y + margin.t, el:sizeHint()))

        if isVertical(self.direction) then
          y = y + h + margin.t + margin.b
        else
          x = x + w + margin.l + margin.r
        end
      end
    else
      local el = chunk.el

      local w, h = el:sizeHint()
      local margin = el:getMargin()

      if isVertical(self.direction) then
        h = math.floor(basis * chunk.stretch + 0.5)
      else
        w = math.floor(basis * chunk.stretch + 0.5)
      end

      if j == lastMut and isVertical(self.direction) then
        h = full - filled 
      elseif j == #chunks then
        w = full - filled
      end

      el:boxCalculated(Box(x + margin.l, y + margin.t, w, h))

      if isVertical(self.direction) then
        filled = filled + h
        y = y + h + margin.t + margin.b
      else
        filled = filled + w
        x = x + w + margin.l + margin.r
      end
    end
  end
end

function BoxLayout:sizeHint(el)
  local width, height = 0, 0

  for _, child in ipairs(el:getLayoutItems()) do
    local hw, hh = child:sizeHint()
    local margin = child:getMargin()

    if isVertical(self.direction) then
      width = math.max(width, hw)
      height = height + hh + margin.t + margin.b
    else
      height = math.max(height, hh)
      width = width + hw + margin.l + margin.r
    end
  end

  return width, height
end

local VBoxLayout = class(BoxLayout, {name = "wonderful.layout.box.VBoxLayout"})

function VBoxLayout:__new__(reversed)
  self:superCall(BoxLayout, "__new__",
      reversed and Direction.BottomToTop or Direction.TopToBottom)
end

local HBoxLayout = class(BoxLayout, {name = "wonderful.layout.box.HBoxLayout"})

function HBoxLayout:__new__(reversed)
  self:superCall(BoxLayout, "__new__",
      reversed and Direction.RightToLeft or Direction.LeftToRight)
end

return {
  Direction = Direction,
  BoxLayout = BoxLayout,
  VBoxLayout = VBoxLayout,
  HBoxLayout = HBoxLayout
}
