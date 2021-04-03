Translator = {}
function Translator:new(lang_uniq_symbols)
    local private = {}
        private.numSymbolsUsedToEncode = 3
        private.encoding_alphabet = lang_uniq_symbols
        private.messageAlphabet = private:setup_message_alphabet()
        private.head = private:get_prefix()
        private.tail = private:get_postfix()
        private.encoding_table = private:__setup_encoding_table()
        private.decoding_table = private.__setup_decoding_table()

        function private:encoding_alphabet_from_msg(message)
            --[[
            Extract encoding alphabet from filtered message
            :param message: filtered message
            :return: encoding alphabet
            --]]
            local alphabet_start_index = #private.head
            local alphabet_len = #private.encoding_alphabet
            local alphabet_end_index = alphabet_start_index + alphabet_len
            local other_alphabet = string.sub(message, alphabet_start_index, alphabet_end_index)

            return other_alphabet
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
            local alphabet_start_index = #private.head
            local alphabet_len = #private.encoding_alphabet
            local alphabet_end_index = alphabet_start_index + alphabet_len
            local message = string.sub(message, 0, alphabet_start_index)..string.sub(message, alphabet_end_index, #message)

            -- Translate message
            local translate_alphabet_table = {}
            for i=1, #our_alphabet do
                translate_alphabet_table[ other_alphabet[i] ] = our_alphabet[i]
            end

            for match, substitution in pairs(translate_alphabet_table) do
                message = string.gsub(message, match, substitution)
            end

            return message
        end

        function private:__filter_message(message)
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
            local punctuation = {'!', '"', '#', '$', '%', '&', "'", '(', ')', '*', '+', ',', '-', '.', '/', ':', ';', '<', '=', '>', '?', '@', '[', '\\', ']', '^', '_', '`', '{', '|', '}', '~'}
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
            local prefix = string.rep(encoding_value, private.numSymbolsUsedToEncode - 1) .. private.encoding_alphabet[1]
            return prefix
        end

        function private:get_postfix()
            --[[
            Create encoded message tail
            :return: message tail
            --]]
            local symbol_index = #private.encoding_alphabet
            local encoding_value = private.encoding_alphabet[symbol_index]
            local prefix = string.rep(encoding_value, private.numSymbolsUsedToEncode - 1) .. private.encoding_alphabet[2]
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
            local encoding_table

            for i, a in ipairs(private.encoding_alphabet) do
                for _, b in ipairs(private.encoding_alphabet) do
                    for _, c in ipairs(private.encoding_alphabet) do
                        encoding_table.insert(tostring(a)..tostring(b)..tostring(c))
                    end
                end
            end
            return encoding_table
        end

        function private:setup_decoding_table()
            --[[
            Generate decoding dictionary
            :return: dictionary with "encoded representation": "input char" items
            --]]

            local decoding_table

            for key, val in pairs(private.encoding_table) do
                decoding_table[val] = key
            end
            return decoding_table
        end

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
            local encoded_data = {}
            encoded_data = private:array_concat(encoded_data, private.head)
            encoded_data = private:array_concat(encoded_data, private.encoding_alphabet)
            for _, val in ipairs(message) do
                local encoded_char = private.encoding_table[val]
                private:array_concat(encoded_data, {encoded_char})
            end
            encoded_data = private:array_concat(encoded_data, private.tail)
            local encoded_string = table.concat(encoded_data, ' ')

            return encoded_string
        end

        function public:decode(message)
            --[[
            Decode message. Assume that message is valid
            :param message: input message
            :return: decoded message
            --]]
            local message = private:__filter_message(message)
            local translated_message = private:translate_message(message)

            -- Remove head and tail from message
            local translated_message = string.gsub(translated_message, "^"..private.head, "")
            local translated_message = string.gsub(translated_message, private.tail.."$", "")

            -- Slice encoded message by parts of encoded symbol len
            local encoded_symbols = {}
            for i=1, #translated_message, private.num_symbols_used_to_encode do
                local slice_begin = i
                local slice_end = i + private.num_symbols_used_to_encode
                local encoded_symbol = string.sub(translated_message, slice_begin, slice_end)
                table.insert(encoded_symbols, #encoded_symbols+1, encoded_symbol)
            end

            -- Decode chars
            local decoded_symbols = {}
            for i, val in ipairs(encoded_symbols) do
                table.insert(decoded_symbols, i, private.decoding_table[val])
            end

            local decoded_message = table.concat(decoded_symbols, '')
            return decoded_message
        end

    setmetatable(public,self)
    self.__index = self; return public
end
