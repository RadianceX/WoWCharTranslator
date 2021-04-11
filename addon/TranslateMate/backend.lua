local utf8lib = TSMATE.libs.utf8

Translator = {}
function Translator:new(lang_uniq_symbols)
    local private = {}

        function private:encoding_alphabet_from_msg(message)
            --[[
            Extract encoding alphabet from filtered message
            :param message: filtered message
            :return: encoding alphabet
            --]]
            local alphabet_start_index = utf8lib.utf8len(private.head) + 1  -- +1 because lua counts indexes starting from 1
            local alphabet_len = #private.encoding_alphabet
            local alphabet_end_index = alphabet_start_index + alphabet_len - 1
            local other_alphabet = utf8lib.utf8sub(message, alphabet_start_index, alphabet_end_index)
            local other_alphabet_table = {}
            for i = 1, utf8lib.utf8len(other_alphabet) do
                other_alphabet_table[i] = utf8lib.utf8sub(other_alphabet, i, i)
            end
            return other_alphabet_table
        end

        function private:translate_message(message)
            --[[
            Translate message from other language to current.
            Extract other alphabet from the message. Replace message symbols by current language symbols.
            E.g:
                our_alphabet: [a, b, c, ...]
                their_alphabet: [1, 2, 3, ...]
                According to alphabets 1==b 2==b 3==c and so on
                message: "1 2 3"
                translated_message: "a b c"
            :param message: filtered message
            :return: translated message
            --]]
            local other_alphabet = private:encoding_alphabet_from_msg(message)
            local our_alphabet = private.encoding_alphabet

            -- Remove other_alphabet from message
            local alphabet_start_index = utf8lib.utf8len(private.head)
            local alphabet_len = #private.encoding_alphabet
            local alphabet_end_index = alphabet_start_index + alphabet_len
            local msg = utf8lib.utf8sub(message, 1, alphabet_start_index)..utf8lib.utf8sub(message, alphabet_end_index + 1, utf8lib.utf8len(message))

            -- Translate message
            local translate_alphabet_table = {}
            for i=1, #our_alphabet do
                translate_alphabet_table[ other_alphabet[i] ] = our_alphabet[i]
            end

            local msg = utf8lib.utf8replace(msg, translate_alphabet_table)

            return msg
        end

        function private:filter_message(message)
            --[[
            Remove unneeded data from message
            :param message: input message
            :return: filtered message
            --]]
            local msg = message:gsub(" ", "")
            return msg
        end

        function private:setup_message_alphabet()
            --[[
            Generate input message alphabet
            :return: tuple with alphabet chars
            --]]
            local ascii_lowercase = {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'}
            local ascii_uppercase = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'}
            local cyrillic_lowercase = {'е', 'ц', 'ь', 'ю', 'л', 'т', 'й', 'ж', 'д', 'б', 'п', 'ф', 'ч', 'г', 'ъ', 'у', 'к', 'р', 'о', 'а', 'з', 'х', 'в', 'с', 'я', 'м', 'э', 'и', 'н', 'ы', 'щ', 'ё', 'ш', 'і', 'є', 'ї'}
            local cyrillic_uppercase = {'Е', 'Ц', 'Ь', 'Ю', 'Л', 'Т', 'Й', 'Ж', 'Д', 'Б', 'П', 'Ф', 'Ч', 'Г', 'Ъ', 'У', 'К', 'Р', 'О', 'А', 'З', 'Х', 'В', 'С', 'Я', 'М', 'Э', 'И', 'Н', 'Ы', 'Щ', 'Ё', 'Ш', 'І', 'Є', 'Ї'}
            local digits = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'}
            local punctuation = {'№', '!', '"', '#', '$', '%', '&', "'", '(', ')', '*', '+', ',', '-', '.', '/', ':', ';', '<', '=', '>', '?', '@', '[', '\\', ']', '^', '_', '`', '{', '|', '}', '~'}
            local special_chars = {' '}

            local alphabet = private:array_concat(
                ascii_lowercase,
                ascii_uppercase,
                cyrillic_lowercase,
                cyrillic_uppercase,
                digits,
                punctuation,
                special_chars
            )
            return alphabet
        end

        function private:get_prefix()
            --[[
            Create encoded message head
            :return: message head
            --]]
            local symbol_index = #private.encoding_alphabet
            local encoding_value = private.encoding_alphabet[symbol_index]
            local prefix = string.rep(encoding_value, private.num_symbols_used_to_encode - 1) .. private.encoding_alphabet[1]
            return prefix
        end

        function private:get_postfix()
            --[[
            Create encoded message tail
            :return: message tail
            --]]
            local symbol_index = #private.encoding_alphabet
            local encoding_value = private.encoding_alphabet[symbol_index]
            local prefix = string.rep(encoding_value, private.num_symbols_used_to_encode - 1) .. private.encoding_alphabet[2]
            return prefix
        end

        function private:array_concat(...)
            -- https://stackoverflow.com/a/1413919/13356680
            local t = {}
            for n = 1,select("#",...) do
                local arg = select(n,...)
                if type(arg)=="table" then
                    for _,v in ipairs(arg) do
                        t[#t+1] = v
                    end
                else
                    t[#t+1] = arg
                end
            end
            return t
        end

        function private:setup_encoding_table()
            --[[
            Generate encoding dictionary
            :return: dictionary with "input char": "encoded representation" items
            --]]
            local coder_values = {}
            local encoding_table = {}

            for i, a in ipairs(private.encoding_alphabet) do
                for _, b in ipairs(private.encoding_alphabet) do
                    for _, c in ipairs(private.encoding_alphabet) do
                        table.insert(coder_values, #coder_values+1, tostring(a)..tostring(b)..tostring(c))
                    end
                end
            end

            for i, val in ipairs(private.message_alphabet) do
                encoding_table[val] = coder_values[i]
            end

            return encoding_table
        end

        function private:setup_decoding_table()
            --[[
            Generate decoding dictionary
            :return: dictionary with "encoded representation": "input char" items
            --]]

            local decoding_table = {}

            for key, val in pairs(private.encoding_table) do
                decoding_table[val] = key
            end
            return decoding_table
        end

        function private:str_to_table(str)
            local t = {}
            for i = 1, utf8lib.utf8len(str) do
                t[i] = utf8lib.utf8sub(str, i, i)
            end
            return t
        end

        function private:prepare_message(message)
            --[[
            Prepare message for printing
            :param message: encoded message
            :return: prepared message
            --]]

            -- https://stackoverflow.com/a/33968863/13356680
            local msg = ""

            for i = 1, utf8lib.utf8len(message) do
                msg = msg .. utf8lib.utf8sub(message, i, i) .. ' '
            end

            msg = utf8lib.utf8sub(msg, 1, utf8lib.utf8len(msg)-1)

            return msg
        end

        function private:fast_check(message)
            --[[
            Checks that message is encoded
            :param message: input message (without whitespaces)
            :return: bool result
            --]]
            local msg_chars = private:str_to_table(message)
            local min_message_len = #private.head + #private.encoding_alphabet + #private.tail
            -- Message is too short to conrain any information
            if utf8lib.utf8len(message) < min_message_len then
                return false
            end
            -- First two symbols of head and tail always the same
            if (msg_chars[0] ~= msg_chars[1]) or 
               (msg_chars[#msg_chars-2] ~= msg_chars[#msg_chars-3]) or
               (msg_chars[0] ~= msg_chars[#msg_chars-2]) then
                return false
            end
            -- Message lenght should be multiple of a encoded_symbol lenght
            if (utf8lib.utf8len(message) - #private.encoding_alphabet) % private.num_symbols_used_to_encode then
                return false
            end
            return true
        end

        private.num_symbols_used_to_encode = 3
        private.encoding_alphabet = lang_uniq_symbols
        private.message_alphabet = private:setup_message_alphabet()
        private.head = private:get_prefix()
        private.tail = private:get_postfix()
        private.encoding_table = private:setup_encoding_table()
        private.decoding_table = private.setup_decoding_table()

        local public = {}
        function public:encode(message)
            --[[
            Encode message. Add service data
            Structure of the message:
                head
                alphabet
                message
                tail
            :param message: input message
            :return: encoded message
            --]]
            local message_chars = private:str_to_table(message)
            local encoded_chars = {}
            encoded_chars = private:array_concat(encoded_chars, private.head)
            encoded_chars = private:array_concat(encoded_chars, private.encoding_alphabet)
            for _, val in ipairs(message_chars) do
                local encoded_char = private.encoding_table[val]
                table.insert(encoded_chars, #encoded_chars +1, encoded_char)
            end
            encoded_chars = private:array_concat(encoded_chars, private.tail)
            local encoded_string = table.concat(encoded_chars, '')
            encoded_string = private:prepare_message(encoded_string)

            return encoded_string
        end

        function public:decode(message)
            --[[
            Decode message. Assume that message is valid
            :param message: input message
            :return: decoded message
            --]]
            local message = private:filter_message(message)
            local translated_message = private:translate_message(message)

            -- Remove head and tail from message
            translated_message = string.gsub(translated_message, "^"..private.head, "")
            translated_message = string.gsub(translated_message, private.tail.."$", "")

            -- Slice encoded message by parts of encoded symbol len
            local encoded_symbols = {}
            for i=1, utf8lib.utf8len(translated_message), private.num_symbols_used_to_encode do
                local slice_begin = i
                local slice_end = i + private.num_symbols_used_to_encode - 1
                local encoded_symbol = utf8lib.utf8sub(translated_message, slice_begin, slice_end)
                table.insert(encoded_symbols, #encoded_symbols+1, encoded_symbol)
            end

            -- Decode chars
            local decoded_symbols = {}
            for i, val in ipairs(encoded_symbols) do
                decoded_symbols[i] = private.decoding_table[val]
            end

            local decoded_message = table.concat(decoded_symbols, '')
            return decoded_message
        end

        function public:is_encoded(message)
            --[[
            Check that message is encoded
            :param message: input message
            :return: bool result
            --]]
            local filtered_message = private:filter_message(message)
            if private:fast_check(filtered_message) == true then
                return true
            end
            return false
        end

    setmetatable(public,self)
    self.__index = self; return public
end

TSMATE.backend = Translator
