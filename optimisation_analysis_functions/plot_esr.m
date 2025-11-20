function plot_esr(time, esr_rolling, module_dir)
    figure('Position', [100 100 800 400]);
    plot(time, esr_rolling, 'LineWidth', 1.5)
    grid on
    xlabel('Time [s]')
    ylabel('ESR [mΩ]')
    title('Time-Weighted Rolling ESR')
    set(gca, 'FontName', 'Arial', 'FontSize', 14)
    savefig(fullfile(module_dir, 'esr_results.fig'))
    close;
end
