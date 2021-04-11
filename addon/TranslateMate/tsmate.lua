local utf8lib = TSMATE.libs.utf8
local DEBUG_ = true

function DEBUG_MESSAGE(msg)
    if DEBUG_ == true then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000"..msg.."|r") 
    end
end

TranslateMate = {}
function TranslateMate:new()
    local private = {}
    local public = {}

        function private:Addon_OnLogin(event, eventType, arg1, arg2, arg3, arg4)
            if (event == "PLAYER_LOGIN") then
                if (private.player_language == nil) then
                    private:colorized_message(private.player_language.." is not supported. Only Orcish and Common available.")
                else
                    local version = GetAddOnMetadata("TranslateMate", "Version");
                    private:colorized_message("TranslateMate v"..version.." loaded. Type /translatemate for usage.")
                end
            end
        end

        function private:colorized_message(msg)
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA11"..msg.."|r")
        end

        function private:encode_input_message(msg, language)
            SendChatMessage(self.translator:encode(msg), "SAY", language)
        end

        function private:try_to_translate(eventType, msg, speaker, language, ...)
            DEBUG_MESSAGE("try_to_translate call")
            if (string.find(private.supported_languages, language)) == nil then
                DEBUG_MESSAGE("LANG NOT SUPPORTED "..language)
                return false
            end
            -- if private.translator:is_encoded(msg) == false then
            --     DEBUG_MESSAGE("MESSAGE NOT ENCODED "..msg)
            --     return false
            -- end
            -- Decode message
            local decoded = private.translator:decode(msg)
            DEBUG_MESSAGE(decoded)
            if decoded ~= nil then
                return false, decoded, speaker, "|cFFFFAA11"..language.."|r", ...;
            end
            -- Nothing was decoded
            return false
        end

        function private:setup_supported_languages()
            for key, val in pairs(TSMATE.languages) do
                private.supported_languages = private.supported_languages .. key
            end
        end

        function private:handle_player_input(msg, editBox)
            --[[
            Checks user input.
            If message has correct len - encode it. Otherwise print help
            :param msg: input message
            :param editBox: chat window???
            ]]
            DEBUG_MESSAGE("handle_player_input call")
            if (not msg or msg == "") then
                private:colorized_message("    DEBUG ADDON DESCIPTION")
                return
            end

            if (utf8lib.utf8len(msg) > private.max_message_len) then
                private:colorized_message("Message too long to encode. Max lenght is " .. private.max_message_len)
                return
            end

            private:encode_input_message(msg, editBox.language)
        end

        private.player_language = nil
        private.max_message_len = 40
        private.supported_languages = ""

        function public:Init()
            -- Register input  message handler
            DEBUG_MESSAGE("Init call")
            SLASH_TS1 = "/ts"
            SLASH_TS2 = "/translatemate"
            SlashCmdList["TS"] = function(msg, editBox) private:handle_player_input(msg, editBox) end

            -- Register addon
            local this = CreateFrame("Frame", "TranslateMate", UIParent)
            this:SetScript("OnEvent", private.Addon_OnLogin)
            this:RegisterEvent("PLAYER_LOGIN")
            -- Init translator
            private.player_language = GetDefaultLanguage("player")
            private.translator = TSMATE.backend:new(TSMATE.languages[private.player_language])
            --DEFAULT_CHAT_FRAME:AddMessage(TSMATE.languages[private.player_language])
            private:setup_supported_languages()

            ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", private.try_to_translate)
        end



    setmetatable(public,self)
    self.__index = self; return public
end


local tsmate = TranslateMate:new()
tsmate:Init()
