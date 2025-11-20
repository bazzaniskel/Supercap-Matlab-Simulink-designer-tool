function str = format_duration(seconds)
%FORMAT_DURATION Format seconds as hh mm ss string.

    if nargin == 0 || isempty(seconds) || ~isfinite(seconds)
        seconds = 0;
    end
    seconds = max(0, seconds);

    h = floor(seconds / 3600);
    m = floor(mod(seconds, 3600) / 60);
    s = floor(mod(seconds, 60));

    str = sprintf('%02dh %02dm %02ds', h, m, s);
end
