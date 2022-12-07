local __namespace, __module = ...

local Addon = __module.Addon --- @class Addon
local Array = __module.Array --- @class Array
local MySettings = __module.Settings

local onLoad = Addon.onLoad
local useHook = Addon.useHook

local module = {}

function module.isQuestFrameShown()
  return QuestFrame:IsShown()
end

function module.getGossipText()
  return C_GossipInfo.GetText()
end

function module.getQuestLogTitle()
  return C_QuestLog.GetTitleForQuestID(QuestMapFrame_GetFocusedQuestID())
end

function module.useGossipUpdateHook(fn)
  useHook("Update", fn, "secure-function", GossipFrame)
end

function module.initPlayButton(buttons, factory)
  buttons:push(factory(QuestMapFrame.DetailsFrame, 18, 30, "quest:focused"))
  buttons:push(factory(QuestFrame, -20, 0, "quest"))
  buttons:push(factory(GossipFrame, -20, 0, "gossip"))
  buttons:push(factory(ItemTextFrame, -20, 0, "book"))
end

function module.initSettings()
  local function proxyCheckSetting(setting, frame)
    onLoad(
      function()
        frame:SetChecked(setting.get())
      end
    )

    frame:SetScript(
      "OnClick", function()
        if frame:GetChecked() then
          PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        else
          PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        end

        setting.set(frame:GetChecked())
      end
    )
  end

  local function proxyVoiceSetting(setting, frame)
    local voices = Array.new(C_VoiceChat.GetTtsVoices())

    local chunks = voices:reduce(
      function(accumulator, element, index, array)
        local chunkIndex = math.ceil(index / 10)

        if not accumulator[chunkIndex] then
          accumulator[chunkIndex] = Array.new()
        end

        accumulator[chunkIndex]:push(element)

        return accumulator
      end, Array.new()
    )

    local function updateOption()
      local voice = voices:find(
        function(v)
          if v.voiceID == setting.get() then
            return true
          end
        end
      )

      UIDropDownMenu_SetText(frame, (voice or {}).name)
      CloseDropDownMenus()
    end

    onLoad(updateOption)

    UIDropDownMenu_SetWidth(frame, 150)

    UIDropDownMenu_Initialize(
      frame, function(_, level, menuList)
        level = level or 1

        if level == 1 then
          chunks:forEach(
            function(element, index, array)

              if index == 1 then
                element:forEach(
                  function(voice)
                    local info = UIDropDownMenu_CreateInfo()

                    info.text = voice.name
                    info.value = voice.voiceID
                    info.checked = setting.get() == info.value
                    info.func = function()
                      setting.set(info.value)
                      updateOption()
                    end

                    UIDropDownMenu_AddButton(info, level)
                  end
                )
              else
                local info = UIDropDownMenu_CreateInfo()
                local chunkLength = chunks[1]:length()
                local startIndex = chunkLength * (index - 1)
                local stopIndex = startIndex + chunkLength

                info.text = "Voices " .. startIndex + 1 .. " - " .. stopIndex
                info.menuList = element:map(
                  function(voice, i)
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = voice.name
                    info.value = voice.voiceID
                    info.checked = setting.get() == info.value
                    info.func = function()
                      setting.set(info.value)
                      updateOption()
                    end

                    return info
                  end
                )
                info.hasArrow = true
                info.notCheckable = true

                UIDropDownMenu_AddButton(info, level)
              end

            end
          )
        elseif menuList then
          menuList:forEach(
            function(info)
              UIDropDownMenu_AddButton(info, level)
            end
          )
        end

      end
    )
  end

  local function proxySliderSetting(setting, frame, min, max, step)
    onLoad(
      function()
        frame:SetValue(setting.get())
      end
    )

    frame:SetMinMaxValues(min, max)
    frame:SetValueStep(step)
    frame:SetScript(
      "OnValueChanged", function(self, value)
        setting.set(value)
      end
    )
  end

  local frame = CreateFrame("Frame", "QuestTTSOptionsPanel")

  local title = frame:CreateFontString(
    "QuestTTSOptionsPanelTitle", "ARTWORK", "GameFontNormalLarge"
  )
  title:SetText(__namespace)
  title:SetJustifyH("LEFT")
  title:SetJustifyV("TOP")
  title:SetPoint("TOPLEFT", 16, -16)

  local description = frame:CreateFontString(
    "QuestTTSOptionsPanelSubText", "ARTWORK", "GameFontHighlightSmall"
  )
  description:SetText("I don't know what to write here...")
  description:SetNonSpaceWrap(true)
  description:SetMaxLines(3)
  description:SetJustifyH("LEFT")
  description:SetJustifyV("TOP")
  description:SetSize(32, 0)
  description:SetPoint(
    "TOPLEFT", "QuestTTSOptionsPanelTitle", "BOTTOMLEFT", 0, -8
  )
  description:SetPoint("RIGHT", 32, 0)

  local readTitle = CreateFrame(
    "CheckButton", "QuestTTSOptionsPanelReadTitle", frame,
    "OptionsBaseCheckButtonTemplate"
  )
  readTitle:SetPoint(
    "TOPLEFT", "QuestTTSOptionsPanelSubText", "BOTTOMLEFT", -2, -8
  )
  local readTitleText = readTitle:CreateFontString(
    "QuestTTSOptionsPanelReadTitleText", "ARTWORK", "GameFontHighlightLeft"
  )
  readTitleText:SetText("Read quest title")
  readTitleText:SetSize(275, 275)
  readTitleText:SetPoint("LEFT", readTitle, "RIGHT", 2, 1)
  proxyCheckSetting(MySettings.readTitle, readTitle)

  local readObjective = CreateFrame(
    "CheckButton", "QuestTTSOptionsPanelReadObjective", frame,
    "OptionsBaseCheckButtonTemplate"
  )
  readObjective:SetPoint(
    "TOPLEFT", "QuestTTSOptionsPanelReadTitle", "BOTTOMLEFT", 0, -8
  )
  local readObjectiveText = readObjective:CreateFontString(
    "QuestTTSOptionsPanelReadObjectiveText", "ARTWORK", "GameFontHighlightLeft"
  )
  readObjectiveText:SetText("Read quest objective")
  readObjectiveText:SetSize(275, 275)
  readObjectiveText:SetPoint("LEFT", readObjective, "RIGHT", 2, 1)
  proxyCheckSetting(MySettings.readObjective, readObjective)

  local skipRecentText = CreateFrame(
    "CheckButton", "QuestTTSOptionsPanelSkipRecentText", frame,
    "OptionsBaseCheckButtonTemplate"
  )
  skipRecentText:SetPoint(
    "TOPLEFT", "QuestTTSOptionsPanelReadObjective", "BOTTOMLEFT", 0, -8
  )
  local skipRecentTextText = readObjective:CreateFontString(
    "QuestTTSOptionsPanelSkipRecentTextText", "ARTWORK", "GameFontHighlightLeft"
  )
  skipRecentTextText:SetText("Skip recently played text")
  skipRecentTextText:SetSize(275, 275)
  skipRecentTextText:SetPoint("LEFT", skipRecentText, "RIGHT", 2, 1)
  proxyCheckSetting(MySettings.skipRecentText, skipRecentText)

  local autoReadQuest = CreateFrame(
    "CheckButton", "QuestTTSOptionsPanelAutoReadQuest", frame,
    "OptionsBaseCheckButtonTemplate"
  )
  autoReadQuest:SetPoint(
    "TOPLEFT", "QuestTTSOptionsPanelSubText", "BOTTOMLEFT", 300, -8
  )
  local autoReadQuestText = autoReadQuest:CreateFontString(
    "QuestTTSOptionsPanelAutoReadQuestText", "ARTWORK", "GameFontHighlightLeft"
  )
  autoReadQuestText:SetText("Auto read quest text")
  autoReadQuestText:SetSize(275, 275)
  autoReadQuestText:SetPoint("LEFT", autoReadQuest, "RIGHT", 2, 1)
  proxyCheckSetting(MySettings.autoReadQuest, autoReadQuest)

  local autoReadGossip = CreateFrame(
    "CheckButton", "QuestTTSOptionsPanelAutoReadGossip", frame,
    "OptionsBaseCheckButtonTemplate"
  )
  autoReadGossip:SetPoint(
    "TOPLEFT", "QuestTTSOptionsPanelAutoReadQuest", "BOTTOMLEFT", 0, -8
  )
  local autoReadGossipText = autoReadGossip:CreateFontString(
    "QuestTTSOptionsPanelAutoReadGossipText", "ARTWORK", "GameFontHighlightLeft"
  )
  autoReadGossipText:SetText("Auto read gossip text")
  autoReadGossipText:SetSize(275, 275)
  autoReadGossipText:SetPoint("LEFT", autoReadGossip, "RIGHT", 2, 1)
  proxyCheckSetting(MySettings.autoReadGossip, autoReadGossip)

  local autoStopRead = CreateFrame(
    "CheckButton", "QuestTTSOptionsPanelAutoStopRead", frame,
    "OptionsBaseCheckButtonTemplate"
  )
  autoStopRead:SetPoint(
    "TOPLEFT", "QuestTTSOptionsPanelReadObjective", "BOTTOMLEFT", 300, -8
  )
  local autoStopReadText = readObjective:CreateFontString(
    "QuestTTSOptionsPanelAutoStopReadText", "ARTWORK", "GameFontHighlightLeft"
  )
  autoStopReadText:SetText(
    "Auto stop read when closing quest/gossip frame or interacting with npc"
  )
  autoStopReadText:SetSize(275, 275)
  autoStopReadText:SetPoint("LEFT", autoStopRead, "RIGHT", 2, 1)
  proxyCheckSetting(MySettings.autoStopRead, autoStopRead)

  local hookAutoTurnIn = CreateFrame(
    "CheckButton", "QuestTTSOptionsPanelHookAutoTurnIn", frame,
    "OptionsBaseCheckButtonTemplate"
  )
  hookAutoTurnIn:SetPoint(
    "TOPLEFT", "QuestTTSOptionsPanelSkipRecentText", "BOTTOMLEFT", 0, -8
  )
  local hookAutoTurnInText = readObjective:CreateFontString(
    "QuestTTSOptionsPanelHookAutoTurnInText", "ARTWORK", "GameFontHighlightLeft"
  )
  hookAutoTurnInText:SetText(
    "Enable experimental AutoTurnIn integration (requires reload)"
  )
  hookAutoTurnInText:SetSize(275, 275)
  hookAutoTurnInText:SetPoint("LEFT", hookAutoTurnIn, "RIGHT", 2, 1)
  proxyCheckSetting(MySettings.hookAutoTurnIn, hookAutoTurnIn)

  local voice1 = CreateFrame(
    "Frame", "QuestTTSOptionsPanelVoice1DropDown", frame,
    "UIDropDownMenuTemplate"
  )
  voice1:EnableMouse(true)
  voice1:SetPoint(
    "TOPLEFT", "QuestTTSOptionsPanelHookAutoTurnIn", "BOTTOMLEFT", -13, -24
  )
  local voice1Text = voice1:CreateFontString(
    "QuestTTSOptionsPanelVoice1DropDownText", "BACKGROUND",
    "GameFontHighlightLeft"
  )
  voice1Text:SetText("Voice for male npc")
  voice1Text:SetPoint("BOTTOMLEFT", voice1, "TOPLEFT", 16, 3)
  proxyVoiceSetting(MySettings.voice1, voice1)

  local voice2 = CreateFrame(
    "Frame", "QuestTTSOptionsPanelVoice2DropDown", frame,
    "UIDropDownMenuTemplate"
  )
  voice2:EnableMouse(true)
  voice2:SetPoint(
    "TOPLEFT", "QuestTTSOptionsPanelHookAutoTurnIn", "BOTTOMLEFT", 195, -24
  )
  local voice2Text = voice2:CreateFontString(
    "QuestTTSOptionsPanelVoice2DropDownText", "BACKGROUND",
    "GameFontHighlightLeft"
  )
  voice2Text:SetText("Voice for female npc")
  voice2Text:SetPoint("BOTTOMLEFT", voice2, "TOPLEFT", 16, 3)
  proxyVoiceSetting(MySettings.voice2, voice2)

  local voice3 = CreateFrame(
    "Frame", "QuestTTSOptionsPanelVoice3DropDown", frame,
    "UIDropDownMenuTemplate"
  )
  voice3:EnableMouse(true)
  voice3:SetPoint(
    "TOPLEFT", "QuestTTSOptionsPanelHookAutoTurnIn", "BOTTOMLEFT", 400, -24
  )
  local voice3Text = voice3:CreateFontString(
    "QuestTTSOptionsPanelVoice3DropDownText", "BACKGROUND",
    "GameFontHighlightLeft"
  )
  voice3Text:SetText("Voice for other gender npcs")
  voice3Text:SetPoint("BOTTOMLEFT", voice3, "TOPLEFT", 16, 3)
  proxyVoiceSetting(MySettings.voice3, voice3)

  local voiceSpeed = CreateFrame(
    "Slider", "QuestTTSOptionsPanelVoiceSpeed", frame, "OptionsSliderTemplate"
  )
  voiceSpeed:SetSize(235, 17)
  voiceSpeed:SetPoint(
    "TOPLEFT", "QuestTTSOptionsPanelVoice1DropDown", "TOPLEFT", 17, -50
  )
  voiceSpeed:SetOrientation("HORIZONTAL")
  _G["QuestTTSOptionsPanelVoiceSpeedText"]:SetText("Voice speed")
  _G["QuestTTSOptionsPanelVoiceSpeedLow"]:SetText("Slow")
  _G["QuestTTSOptionsPanelVoiceSpeedHigh"]:SetText("Fast")
  proxySliderSetting(
    MySettings.voiceSpeed, voiceSpeed, TEXTTOSPEECH_RATE_MIN,
    TEXTTOSPEECH_RATE_MAX, 1
  )

  local voiceVolume = CreateFrame(
    "Slider", "QuestTTSOptionsPanelVoiceVolume", frame, "OptionsSliderTemplate"
  )
  voiceVolume:SetSize(235, 17)
  voiceVolume:SetPoint(
    "TOPLEFT", "QuestTTSOptionsPanelVoice1DropDown", "TOPLEFT", 365, -50
  )
  voiceVolume:SetOrientation("HORIZONTAL")
  _G["QuestTTSOptionsPanelVoiceVolumeText"]:SetText("Voice volume")
  _G["QuestTTSOptionsPanelVoiceVolumeLow"]:SetText("0%")
  _G["QuestTTSOptionsPanelVoiceVolumeHigh"]:SetText("100%")
  proxySliderSetting(
    MySettings.voiceVolume, voiceVolume, TEXTTOSPEECH_VOLUME_MIN,
    TEXTTOSPEECH_VOLUME_MAX, 1
  )

  local advertisement = CreateFrame(
    "Frame", "QuestTTSOptionsPanelAdvertisement", frame, "QuestTTSAdvertisement"
  )
  advertisement:SetSize(590, 200)
  advertisement:SetPoint("BOTTOMLEFT", 18, 22)

  frame.name = __namespace
  InterfaceOptions_AddCategory(frame)
end

if not Addon.isRetail then
  __module.CrossExp = module
end
