function plot_soh_history(timeline, caseConfig, results_folder)
%PLOT_SOH_HISTORY Plot SOH vs time with lifetime target marker.

    fig = figure('Name', 'SOH Evolution', 'Position', [200 200 900 420]);
    hold on;
    plot(timeline.time_years, timeline.soh_percent, 'LineWidth', 2);
    yline(0, 'k--');
    xline(caseConfig.lifetime.targetYears, 'r--', sprintf('Target %.1f y', caseConfig.lifetime.targetYears));
    xlabel('Years');
    ylabel('SOH (%)');
    title('SOH Evolution Across Lifetime Simulation');
    grid on;
    ylim([0 105]);
    if ~isempty(timeline.time_years)
        xlim([0 max(timeline.time_years)]);
    end
    saveas(fig, fullfile(results_folder, 'soh_evolution.png'));
    close(fig);
end
