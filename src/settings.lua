local __namespace, __module = ...

local Addon = __module.Addon --- @class Addon
local Array = __module.Array --- @class Array
local GameSettings = _G["Settings"]

local onLoad = Addon.onLoad
local useSavedVariable = Addon.useSavedVariable

local globalDB = "QuestTTSGlobalDB"
local module = {
  CATEGORY_ID = nil,
  readTitle = useSavedVariable(globalDB, "readTitle", true),
  readObjective = useSavedVariable(globalDB, "readObjective", true),
  readNpcName = useSavedVariable(globalDB, "readNpcName", false),
  voice1 = useSavedVariable(globalDB, "voice1", Enum.TtsVoiceType.Standard),
  voice2 = useSavedVariable(globalDB, "voice2", Enum.TtsVoiceType.Standard),
  voice3 = useSavedVariable(globalDB, "voice3", Enum.TtsVoiceType.Standard),
  voiceSpeed = useSavedVariable(globalDB, "voiceSpeed", 0),
  voiceVolume = useSavedVariable(globalDB, "voiceVolume", 100),
  autoReadQuest = useSavedVariable(globalDB, "autoReadQuest", false),
  autoReadGossip = useSavedVariable(globalDB, "autoReadGossip", false),
  skipRecentText = useSavedVariable(globalDB, "skipRecentText", false),
  autoStopRead = useSavedVariable(globalDB, "autoStopRead", true),
  hookAutoTurnIn = useSavedVariable(globalDB, "hookAutoTurnIn", false),
  alert = useSavedVariable(globalDB, "alert", 0),
  useNarrator = useSavedVariable(globalDB, "useNarrator", false),
}

function module.init()
  local function getVoiceOptions()
    local toRet = GameSettings.CreateControlTextContainer()

    Array.new(C_VoiceChat.GetTtsVoices()):forEach(
      function(voice)
        toRet:Add(voice.voiceID, voice.name)
      end
    )

    return toRet:GetData()
  end

  local function proxySetting(category, setting, name)
    local globalName = setting.globalName
    local varName = setting.varName
    local defaultValue = setting.defaultValue

    local varTbl = _G[globalName]
    local varKey = varName
    local toRet = GameSettings.RegisterAddOnSetting(
      category, varName, varKey, varTbl, type(defaultValue), name, defaultValue
    )

    local SetValue = toRet.SetValue
    toRet.SetValue = function(self, value, force)
      local tmp = SetValue(self, value, force)

      setting.set(toRet:GetValue())

      return tmp
    end

    onLoad(
      function()
        toRet:SetValue(setting.get())
      end
    )

    return toRet
  end

  local category, layout = GameSettings.RegisterVerticalLayoutCategory(
    __namespace
  )
  module.CATEGORY_ID = category:GetID()

  local readTitle = proxySetting(category, module.readTitle, "Read quest title")
  GameSettings.CreateCheckbox(category, readTitle, "")

  local readObjective = proxySetting(
    category, module.readObjective, "Read quest objective"
  )
  GameSettings.CreateCheckbox(category, readObjective, "")

  local readNpcName =
    proxySetting(category, module.readNpcName, "Read npc name")
  GameSettings.CreateCheckbox(category, readNpcName, "")

  local autoReadQuest = proxySetting(
    category, module.autoReadQuest, "Auto read quest text"
  )
  GameSettings.CreateCheckbox(category, autoReadQuest, "")

  local autoReadGossip = proxySetting(
    category, module.autoReadGossip, "Auto read gossip text"
  )
  GameSettings.CreateCheckbox(category, autoReadGossip, "")

  local skipRecentText = proxySetting(
    category, module.skipRecentText, "Skip recently played text"
  )
  GameSettings.CreateCheckbox(category, skipRecentText, "")

  local autoStopRead = proxySetting(
    category, module.autoStopRead,
    "Auto stop read when closing quest/gossip frame or interacting with npc"
  )
  GameSettings.CreateCheckbox(category, autoStopRead, "")

  local hookAutoTurnIn = proxySetting(
    category, module.hookAutoTurnIn,
    "Enable experimental AutoTurnIn integration (requires reload)"
  )
  GameSettings.CreateCheckbox(category, hookAutoTurnIn, "")

  local voice1 = proxySetting(category, module.voice1, "Voice for male npcs")
  GameSettings.CreateDropdown(category, voice1, getVoiceOptions, "")

  local voice2 = proxySetting(category, module.voice2, "Voice for female npcs")
  GameSettings.CreateDropdown(category, voice2, getVoiceOptions, "")

  local voice3 = proxySetting(
    category, module.voice3, "Voice for other gender npcs"
  )
  GameSettings.CreateDropdown(category, voice3, getVoiceOptions, "")

  local useNarrator = proxySetting(
    category, module.useNarrator, "Use other gender voice as narrator"
  )
  GameSettings.CreateCheckbox(
    category, useNarrator,
    "Reads quest titles, npc names, objectives and text in <> using other gender voice."
  )

  local voiceSpeed = proxySetting(category, module.voiceSpeed, "Voice speed")
  local voiceSpeedOptions = GameSettings.CreateSliderOptions(
    TEXTTOSPEECH_RATE_MIN, TEXTTOSPEECH_RATE_MAX, 1
  )
  voiceSpeedOptions:SetLabelFormatter(
    MinimalSliderWithSteppersMixin.Label.Left, function()
      return "Slow"
    end
  )
  voiceSpeedOptions:SetLabelFormatter(
    MinimalSliderWithSteppersMixin.Label.Right, function()
      return "Fast"
    end
  )
  GameSettings.CreateSlider(category, voiceSpeed, voiceSpeedOptions, "")

  local voiceVolume = proxySetting(category, module.voiceVolume, "Voice volume")
  local voiceVolumeOptions = GameSettings.CreateSliderOptions(
    TEXTTOSPEECH_VOLUME_MIN, TEXTTOSPEECH_VOLUME_MAX, 1
  )
  voiceVolumeOptions:SetLabelFormatter(
    MinimalSliderWithSteppersMixin.Label.Top, function(val)
      return val .. "%"
    end
  )
  GameSettings.CreateSlider(category, voiceVolume, voiceVolumeOptions, "")

  GameSettings.RegisterAddOnCategory(category)
end

onLoad(
  function()
    module.init()
  end
)

__module.Settings = module
