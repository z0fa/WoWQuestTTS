local __namespace, __module = ...
local GameSettings = _G["Settings"]
local Addon = __module.Addon --- @class Addon
local Array = __module.Array --- @class Array
local onLoad = Addon.onLoad
local useSavedVariable = Addon.useSavedVariable

local module = {} --- @class Settings

module.CATEGORY_ID = nil
module.readTitle = useSavedVariable("readTitle", true)
module.readObjective = useSavedVariable("readObjective", true)
module.readNpcName = useSavedVariable("readNpcName", false)
module.voice1 = useSavedVariable("voice1", Enum.TtsVoiceType.Standard)
module.voice2 = useSavedVariable("voice2", Enum.TtsVoiceType.Standard)
module.voice3 = useSavedVariable("voice3", Enum.TtsVoiceType.Standard)
module.voiceSpeed = useSavedVariable("voiceSpeed", 0)
module.voiceVolume = useSavedVariable("voiceVolume", 100)
module.autoReadQuest = useSavedVariable("autoReadQuest", false)
module.autoReadGossip = useSavedVariable("autoReadGossip", false)
module.skipRecentText = useSavedVariable("skipRecentText", false)
module.autoStopRead = useSavedVariable("autoStopRead", true)
module.hookAutoTurnIn = useSavedVariable("hookAutoTurnIn", false)
module.alert = useSavedVariable("alert", 0)
module.useNarrator = useSavedVariable("useNarrator", false)

function module.open()
  GameSettings.OpenToCategory(module.CATEGORY_ID)
end

onLoad(
  function()
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
        category, varName, varKey, varTbl, type(defaultValue), name,
        defaultValue
      )

      local originalSetValue = toRet.SetValue
      toRet.SetValue = function(self, value, force)
          local valueToSet = value
       
          if type(value) == "table" then
              if value.value ~= nil then
                  valueToSet = value.value
              else
                  return originalSetValue(self, value, force)
              end
          end

          local result = originalSetValue(self, valueToSet, force)
          setting.value = toRet:GetValue()
          return result
      end

      onLoad(
        function()
          if setting.value ~= nil then
            toRet:SetValue(setting.value)
          end
        end
      )

      return toRet
    end

    local category, layout = GameSettings.RegisterVerticalLayoutCategory(
      __namespace
    )
    module.CATEGORY_ID = category:GetID()

    local readTitle = proxySetting(
      category, module.readTitle, "Read quest title"
    )
    GameSettings.CreateCheckbox(category, readTitle, "")

    local readObjective = proxySetting(
      category, module.readObjective, "Read quest objective"
    )
    GameSettings.CreateCheckbox(category, readObjective, "")

    local readNpcName = proxySetting(
      category, module.readNpcName, "Read npc name"
    )
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

    local voiceVolume = proxySetting(
      category, module.voiceVolume, "Voice volume"
    )
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
)

__module.Settings = module
