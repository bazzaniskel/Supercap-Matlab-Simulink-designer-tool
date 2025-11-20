function value = get_valid_input(prompt, validation_func)
%GET_VALID_INPUT Read numeric input with validation callback, retrying on errors.

    while true
        raw = input(prompt, 's');
        value = str2double(raw);
        if ~isnan(value)
            if validation_func(value)
                return;
            else
                fprintf('Invalid input. Please try again.\n');
            end
        else
            fprintf('Invalid input format. Please enter a number.\n');
        end
    end
end
