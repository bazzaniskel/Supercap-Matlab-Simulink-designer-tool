function result = get_yes_no_input(prompt)
%GET_YES_NO_INPUT Utility that accepts y/n answers.
    if nargin < 1 || isempty(prompt)
        prompt = 'Enter choice';
    end
    prompt = strtrim(prompt);
    if ~contains(lower(prompt), 'y/n')
        prompt = sprintf('%s (y/n): ', prompt);
    else
        if ~endsWith(prompt, ':')
            prompt = [prompt ':'];
        end
        prompt = [prompt ' '];
    end
    while true
        response = input(prompt, 's');
        if any(strcmpi(response, {'y', 'yes'}))
            result = true;
            return;
        elseif any(strcmpi(response, {'n', 'no'}))
            result = false;
            return;
        end
        fprintf('Please enter y/n or yes/no.\n');
    end
end
