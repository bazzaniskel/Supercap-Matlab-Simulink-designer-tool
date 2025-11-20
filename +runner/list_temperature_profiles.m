function profiles = list_temperature_profiles(profileDir)
%LIST_TEMPERATURE_PROFILES Discover available temperature profiles.

    if nargin < 1 || isempty(profileDir)
        profileDir = runner.get_temperature_profile_directory();
    end

    profiles = struct('displayName', {}, 'path', {}, 'functionName', {});
    if ~exist(profileDir, 'dir')
        return;
    end

    m_files = dir(fullfile(profileDir, '*.m'));
    idx = 1;
    for f = 1:numel(m_files)
        [~, name] = fileparts(m_files(f).name);
        if startsWith(lower(name), 'template')
            continue;
        end
        profiles(idx).displayName = name;
        profiles(idx).path = fullfile(m_files(f).folder, m_files(f).name);
        profiles(idx).functionName = name;
        idx = idx + 1;
    end

    if idx == 1
        profiles = struct('displayName', {}, 'path', {}, 'functionName', {});
    else
        [~, order] = sort({profiles.displayName});
        profiles = profiles(order);
    end
end
