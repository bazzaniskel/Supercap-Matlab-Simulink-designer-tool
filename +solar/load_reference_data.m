function data = load_reference_data()
%LOAD_REFERENCE_DATA Load cached solar reference profiles.

    persistent cached;
    if ~isempty(cached)
        data = cached;
        return;
    end

    file_path = fullfile('data', 'solar_reference_profiles.json');
    if ~exist(file_path, 'file')
        data = struct();
        cached = data;
        return;
    end

    try
        raw = fileread(file_path);
        data = jsondecode(raw);
    catch
        warning('Failed to parse %s. Falling back to empty reference list.', file_path);
        data = struct();
    end
    cached = data;
end
