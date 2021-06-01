local str = {}

function str.get_extension(s)
    return s:match("[^.]+$")
end

function str.contains_non_latin(s)
    return s:match("[^%c%p%s%w]")
end

function str.capitalize_first(s)
    return s:gsub("^%l", s.upper)
end

function str.escape_special_chars(s)
    local entities = {
        ['&'] = '&amp;',
        ['"'] = '&quot;',
        ["'"] = '&apos;',
        ['<'] = '&lt;',
        ['>'] = '&gt;',
    }
    return s:gsub('[&"\'<>]', entities)
end

function str.remove_ext(fp)
    return fp:gsub('%.%w+$', '')
end

function str.remove_special_chars(s)
    return s:gsub('[%c%p%s]', ''):gsub('　', '')
end

function str.remove_text_in_brackets(s)
    return s:gsub('%b[]', ''):gsub('【.-】', '')
end

function str.remove_text_in_parentheses(s)
    -- Remove text like （泣き声） or （ドアの開く音）
    -- Note: the modifier `-´ matches zero or more occurrences.
    -- However, instead of matching the longest sequence, it matches the shortest one.
    return s:gsub('%b()', ''):gsub('（.-）', '')
end

function str.remove_newlines(s)
    return s:gsub('[\n\r]+', ' ')
end

function str.remove_leading_trailing_spaces(s)
    return s:gsub('^%s*(.-)%s*$', '%1')
end

function str.remove_all_spaces(s)
    return s:gsub('%s*', '')
end

function str.trim(s)
    s = str.remove_spaces(s)
    s = str.remove_text_in_parentheses(s)
    s = str.remove_newlines(s)
    return s
end

return str
