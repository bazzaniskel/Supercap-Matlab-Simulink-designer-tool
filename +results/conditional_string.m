function str = conditional_string(condition, true_str, false_str)
%CONDITIONAL_STRING Return true_str if condition else false_str.
    if condition
        str = true_str;
    else
        str = false_str;
    end
end
