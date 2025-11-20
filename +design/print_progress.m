function print_progress(label, current, total, start_time)
%PRINT_PROGRESS Display elapsed and estimated remaining time for a phase.

    if nargin < 4 || isempty(start_time)
        return;
    end
    if nargin < 3 || total <= 0
        total = current;
    end
    if nargin < 2 || current <= 0
        current = 1;
    end

    elapsed = toc(start_time);
    avg_time = elapsed / max(current, eps);
    remaining = max(0, (total - current) * avg_time);

    fprintf('   %s progress: %d/%d | Elapsed: %s | Est. remaining: %s\n', ...
        label, min(current, total), total, design.format_duration(elapsed), design.format_duration(remaining));
end
