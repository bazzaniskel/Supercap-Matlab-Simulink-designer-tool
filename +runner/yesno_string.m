function str = yesno_string(flag)
%YESNO_STRING Convert logical flag to Yes/No text.
    if flag
        str = 'Yes';
    else
        str = 'No';
    end
end
