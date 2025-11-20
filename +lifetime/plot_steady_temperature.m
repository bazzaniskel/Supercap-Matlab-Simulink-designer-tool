function plot_steady_temperature(timeline, mcSummary, results_folder)
%PLOT_STEADY_TEMPERATURE Plot steady-state cell temperature vs SOH.

    if ~isfield(timeline, 'steady_temps') || isempty(timeline.steady_temps)
        return;
    end

    sohs = timeline.soh_percent(:)';
    temps = timeline.steady_temps(:)';
    valid = ~isnan(temps);
    if ~any(valid)
        return;
    end

    fig = figure('Name', 'Steady-state Temperature vs SOH', 'Position', [200 200 900 420]);
    hold on;

    if nargin >= 2 && isstruct(mcSummary) && mcSummary.enabled && isfield(mcSummary, 'tempStats')
        stats = mcSummary.tempStats;
        x = stats.soh;
        plot_envelope_band(x, stats.p10, stats.p90, [0.9 0.7 0.7]);
        plot_envelope_band(x, stats.p25, stats.p75, [0.8 0.5 0.5]);
        plot(x, stats.mean, 'Color', [0.7 0.1 0.1], 'LineWidth', 1.6);
        legend_entries = {'10-90%','25-75%','Monte Carlo Mean'};
        if any(valid)
            plot(sohs(valid), temps(valid), 'k--', 'LineWidth', 1.2);
            legend_entries{end+1} = 'Deterministic';
        end
        legend(legend_entries, 'Location', 'best');
    else
        plot(sohs(valid), temps(valid), 'LineWidth', 2);
    end

    xlabel('SOH (%)');
    ylabel('Steady-state Cell Temperature (°C)');
    title('Steady-state Temperature Evolution');
    grid on;
    xlim([min(sohs) max(sohs)]);
    saveas(fig, fullfile(results_folder, 'steady_temperature_vs_soh.png'));
    close(fig);
end

function plot_envelope_band(x, lower, upper, color)
    valid = ~(isnan(lower) | isnan(upper));
    if ~any(valid)
        return;
    end
    x = x(valid);
    lower = lower(valid);
    upper = upper(valid);
    fill([x fliplr(x)], [upper fliplr(lower)], color, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
end
