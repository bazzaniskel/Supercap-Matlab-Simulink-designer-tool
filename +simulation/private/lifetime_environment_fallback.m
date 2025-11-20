function temp = lifetime_environment_fallback(profile)
%LIFETIME_ENVIRONMENT_FALLBACK Provide a default temperature if missing.

    if isfield(profile, 'meanTemp') && ~isempty(profile.meanTemp)
        temp = profile.meanTemp;
    elseif isfield(profile, 'temps') && ~isempty(profile.temps)
        temp = mean(profile.temps);
    else
        temp = 25;
    end
end
