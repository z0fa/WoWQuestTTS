local __namespace, __module = ...

local Array = __module.Array --- @class Array

local module = {} --- @class Addon

local frame = CreateFrame("Frame", nil)
local onLoadHooks = Array.new()
local onUpdateHooks = Array.new()
local debugValues = {} --- @type table<string, any>
local listeners = {} --- @type table<WowEvent, Array>
local hooks = Array.new()

--- @class ReactiveData
--- @field get fun(): unknown
--- @field set fun(newValue: unknown)
--- @field sub fun(listener: fun(newValue: unknown)): fun()

--- @class ReactiveSavedVariable: ReactiveData
--- @field globalName string
--- @field varName string
--- @field defaultValue unknown

--- comment
--- @param initialValue unknown
--- @return ReactiveData
function module.useState(initialValue)
  local value = initialValue
  local subscribers = Array.new()

  local function get()
    return value
  end

  local function set(newValue)
    if value == newValue then
      return
    end

    value = newValue
    subscribers:forEach(
      function(item)
        item(value)
      end
    )
  end

  local function sub(listener)
    subscribers:push(listener)

    return function()
      subscribers = subscribers:filter(
        function(item)
          return item ~= listener
        end
      )
    end
  end

  return { get = get, set = set, sub = sub }
end

--- comment
--- @param fn fun()
--- @param deps ReactiveData[]
function module.useEffect(fn, deps)
  local toPush = { fn = fn, deps = nil }

  if type(deps) == "table" then
    toPush.deps = Array.new(deps):forEach(
      function(dep)
        dep.sub(fn)
      end
    )

    module.onLoad(fn)
  end

  hooks:push(toPush)
end

--- @param fn fun()
--- @param deps ReactiveData[]?
function module.useMemo(fn, deps)
end

--- comment
function module.useContext()
end

--- comment
--- @param globalName string
--- @param varName string
--- @param defaultValue unknown
--- @return ReactiveSavedVariable
function module.useSavedVariable(globalName, varName, defaultValue)
  local state = module.useState(defaultValue)

  local toRet = {
    get = state.get,
    set = state.set,
    sub = state.sub,
    globalName = globalName,
    varName = varName,
    defaultValue = defaultValue,
  }

  module.onLoad(
    function()
      _G[globalName] = _G[globalName] or {}

      if (_G[globalName][varName] == nil) then
        _G[globalName][varName] = defaultValue
      end

      toRet.set(_G[globalName][varName])
    end
  )

  module.useEffect(
    function()
      _G[globalName][varName] = toRet.get()
    end, { toRet }
  )

  return toRet
end

--- comment
--- @param fn fun(...)
--- @param events WowEvent[]
--- @param once boolean?
function module.useEvent(fn, events, once)
  local eventsArray = Array.new(events or {})
  once = once or false

  local function unsub()
  end

  local function handler(...)
    local result = fn(...)

    if once then
      unsub()
    end

    return result
  end

  unsub = function()
    eventsArray:forEach(
      function(event)
        listeners[event] = listeners[event]:filter(
          function(h)
            return h ~= handler
          end
        )

        if listeners[event]:length() == 0 then
          frame:UnregisterEvent(event)
        end
      end
    )
  end

  eventsArray:forEach(
    function(event)
      if not listeners[event] then
        frame:RegisterEvent(event)
        listeners[event] = Array.new()
      end

      listeners[event]:push(handler)
    end
  )

  return unsub
end

--- comment
--- @param fn fun(arg1?: string, arg2?: string, arg3?: string)
--- @param aliases string[]
function module.useSlashCmd(fn, aliases)
  local cmdsArray = Array.new(aliases)
  local name = aliases[1]:upper()

  cmdsArray:forEach(
    function(cmd, index)
      _G["SLASH_" .. name .. index] = "/" .. cmd
    end
  )

  SlashCmdList[name] = function(msg)
    local args = {}

    for arg in msg:gmatch("%S+") do
      table.insert(args, arg)
    end

    fn(unpack(args))
  end
end

--- comment
--- @param fnName string
--- @param fn function
--- @param hookType? "function" | "secure-function" | "widget" | "secure-widget"
--- @param srcTable? table
--- @param once? boolean
function module.useHook(fnName, fn, hookType, srcTable, once)
  hookType = hookType or "function"
  srcTable = srcTable or _G

  local function unhook()
  end

  local enabled = true
  local oldFn = nil
  local hookProxy = {}
  local hookFn = function(...)
    if once then
      unhook()
    end

    return hookProxy(...)
  end

  setmetatable(
    hookProxy, {
      __call = function(...)
        if not enabled and oldFn then
          return oldFn(...)
        elseif not enabled then
          return
        end

        return fn(...)
      end,
      __index = function(t, k)
        if k == "__enabled" then
          return enabled
        elseif k == "__oldFn" then
          return oldFn
        elseif k == "__srcTable" then
          return srcTable
        elseif type(srcTable[k]) == "function" then
          return function(_, ...)
            return srcTable[k](srcTable, ...)
          end
        else
          return srcTable[k]
        end
      end,
      __newindex = function(t, k, v)
        if k == "__enabled" then
          enabled = v
        elseif k == "__oldFn" then
          oldFn = v
        else
          srcTable[k] = v
        end
      end,
    }
  )

  unhook = function()
    enabled = false
  end

  if hookType == "function" then
    oldFn = srcTable[fnName]
    srcTable[fnName] = hookFn
  elseif hookType == "secure-function" and srcTable then
    hooksecurefunc(srcTable, fnName, hookFn)
  elseif hookType == "secure-function" then
    hooksecurefunc(fnName, hookFn)
  elseif hookType == "widget" then
    oldFn = srcTable:GetScript(fnName)
    srcTable:SetScript(fnName, hookFn)
  elseif hookType == "secure-widget" then
    srcTable:HookScript(fnName, hookFn)
  end

  return unhook
end

--- comment
--- @param label string
--- @param dep ReactiveData
function module.useDebugValue(label, dep)
  module.useEffect(
    function()
      debugValues[label] = dep.get()
    end, { dep }
  )
end

--- comment
--- @param fn function
function module.nextTick(fn)
  C_Timer.After(0, fn)
end

--- comment
--- @param msg any
function module.print(msg)
  print("|cffff8000" .. __namespace .. ": |r" .. tostring(msg))
end

--- comment
--- @param fn function
function module.onLoad(fn)
  onLoadHooks:push(fn)
end

--- comment
--- @param fn function
function module.onInit(fn)
  fn()
end

--- comment
--- @param fn fun(delta: number)
function module.onUpdate(fn)
  onUpdateHooks:push(fn)

  if not frame:GetScript("OnUpdate") then
    frame:SetScript(
      "OnUpdate", function(frame, delta)
        onUpdateHooks:forEach(
          function(fn)
            fn(delta)
          end
        )
      end
    )
  end
end

frame:SetScript(
  "OnEvent", function(frame, event, ...)
    local handlers = listeners[event] or Array.new()
    local args = { ... }

    handlers:forEach(
      function(handler)
        handler(event, unpack(args))
      end
    )
  end
)

module.useEvent(
  function(evetName, addonName)
    if addonName == __namespace then
      onLoadHooks:forEach(
        function(fn)
          fn()
        end
      )

      module.nextTick(
        function()
          if next(debugValues) == nil then
            return
          end

          if not IsAddOnLoaded("Blizzard_DebugTools") then
            UIParentLoadAddOn("Blizzard_DebugTools")
          end

          local inspector = DisplayTableInspectorWindow(debugValues)
          inspector:SetDynamicUpdates(true)
        end
      )
    end
  end, { "ADDON_LOADED" }
)

module.isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
module.isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
module.isTBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
module.isWOTLK = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
module.isCata = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC

__module.Addon = module
