clc
clearvars
close all


set(groot,{'DefaultAxesXColor','DefaultAxesYColor','DefaultAxesZColor'},{'k','k','k'})

q_value =50;


time_per_sweeps_fpga =  1/15e6;
sweeps_per_swap_attempt= 102;


% Define the solvers and their corresponding fit parameters
solvers = {'DAU', 'SBM', 'PT', 'MEM', 'SATonGPU', 'DWA'};

% Placeholder for alpha and beta values depending on q_value
alpha_quantile = [];
beta_quantile = [];

% Check the value of q_value and set the corresponding alpha and beta values
if q_value == 25
    alpha_quantile = [0.0181, 0.0211, 0.0239, 0.030, NaN, NaN];  % Alpha for q = 0.25
    beta_quantile = [-3.51, -2.6, -0.92, -1, NaN, NaN];  % Beta for q = 0.25

    plot_handles = gobjects(length(solvers)-2, 1);  % gobjects creates an array of graphic handles
    legend_entries = cell(length(solvers)-2, 1);  % Initialize cell array for legend entries

elseif q_value == 50
    alpha_quantile = [0.0185, 0.0217, 0.0248, 0.025, 0.0171, 0.08];  % Alpha for q = 0.50 (median)
    beta_quantile = [-3.56, -2.6, -0.97, -0.6, -5.9, -6];  % Beta for q = 0.50 (median)

    plot_handles = gobjects(length(solvers), 1);  % gobjects creates an array of graphic handles
    legend_entries = cell(length(solvers), 1);  % Initialize cell array for legend entries

elseif q_value== 75
    alpha_quantile = [0.0190, 0.0234, 0.0252, 0.024, NaN, NaN];  % Alpha for q = 0.75
    beta_quantile = [-3.49, -2.7, -0.97, -0.2, NaN, NaN];  % Beta for q = 0.75

    plot_handles = gobjects(length(solvers)-2, 1);  % gobjects creates an array of graphic handles
    legend_entries = cell(length(solvers)-2, 1);  % Initialize cell array for legend entries

else
    error('Invalid q_value. Please use 25, 50, or 75.');
end


DWA_size =[16:16:80];
MEM_size = 16:16:112;
PT_size = 64:16:224;
DAU_size = 144:16:240;
SBM_size = [176 208 222 256];
SATGPU_size = [200 256 512 640];
%SATGPU_size = 256

% Colors, markers, and linestyles for each solver
colors = {[0, 0, 0], [230 159 0]/255, [86 180 233]/255, [0,153,102]/255, ...
    [0 114 178]/255, [213 94 0]/255, [204 153 51]/255};
markers = {'o', '>', 'd', '^', 'v', 'o', 's'};
%linestyles = {'-', '--', ':', '-.', '-', '--', ':'};
linestyles = {'--', '--', '--', '--', '--', '--', '--'};
% Set up the figure
fig = figure;
ax = axes(fig);
hold(ax, 'on');
set(ax, 'YScale', 'log'); % Log scale for y-axis
set(ax, 'FontSize', 20, 'FontName', 'Arial', 'FontWeight', 'bold'); % Set font size and style


% Plot TTS for each solver
for i = 1:length(solvers)
    if isnan(alpha_quantile(i))
        % If alpha is NaN, the solver data is not available; skip plotting
        continue;
    else
        % Select the appropriate size range for each solver
        switch solvers{i}
            case 'DAU'
                size_range = DAU_size;
            case 'SBM'
                size_range = SBM_size;
            case 'PT'
                size_range = PT_size;
            case 'MEM'
                size_range = MEM_size;
            case 'SATonGPU'
                size_range = SATGPU_size;
            case 'DWA'
                size_range = DWA_size;
            otherwise
                size_range = []; % Empty array for unrecognized solvers
        end

        % Check if size range is available
        if isempty(size_range)
            continue; % Skip plotting if no size range
        end
        % Calculate TTS for the specific size range
        TTS = 10.^(alpha_quantile(i) * size_range + beta_quantile(i));

        % Plot the TTS for the specific size range
        if strcmp(solvers{i}, 'SATonGPU')
            % Plot the fit line for SATonGPU using the full size range
            fit_line = semilogy(ax, SATGPU_size, TTS, 'LineStyle', linestyles{i}, ...
                'Color', colors{i}, 'LineWidth', 2, 'HandleVisibility', 'off');
        else
            % For other solvers, plot as usual
            plot_handles(i) = semilogy(ax, size_range, TTS, 'LineStyle', linestyles{i}, ...
                'Color', colors{i}, 'Marker', markers{i}, ...
                'LineJoin', 'round','DisplayName', solvers{i}, 'LineWidth', 2, 'MarkerSize', 12, 'MarkerFaceColor',colors{i});
            legend_entries{i} = sprintf('%s', solvers{i});
        end

    end
end

% After plotting all solvers, plot only the marker for SATonGPU size 256
% Find the index of SATonGPU in the solvers array
sat_idx = find(strcmp(solvers, 'SATonGPU'));
% Plot only the marker for size 256
if ~isnan(alpha_quantile(sat_idx))
    TTS_256 = 10.^(alpha_quantile(sat_idx) * 256 + beta_quantile(sat_idx));
    plot_handles(sat_idx) = semilogy(ax, 256, TTS_256, 'LineStyle', 'none', ...
        'Color', colors{sat_idx}, 'Marker', markers{sat_idx}, ...
        'DisplayName', solvers{sat_idx}, 'MarkerSize', 12, 'MarkerFaceColor',colors{sat_idx});
    legend_entries{sat_idx} = sprintf('%s', solvers{sat_idx});
end

% Customize the ylabel based on q_value
if q_value == 50
    ylabel_str = 'optimal median TTS (sec)';
else
    ylabel_str = sprintf('optimal Q%d TTS (sec)', q_value);
end


% Customize the plot
xlabel(ax, 'problem size, n');
ylabel(ax, ylabel_str);
%title(ax, 'Optimal Median TTS vs Problem Size');
legend(ax, 'Location', 'northwest');
set(gca, 'GridLineStyle', '-', 'MinorGridLineStyle', '-','LineWidth',1.1); % Set grid lines to solid
grid(ax, 'on'); % Add grid for better readability

% Release the hold on the current figure
%hold(ax, 'off');


% % Load your data and plot it, rename to 'APT (projected)'
load_name = sprintf('./extracted_tts_data/data_q%d_cpu.mat',q_value);
load(load_name, 'problem_sizes', 'min_tts_values' ,'ci_lower', 'ci_upper');

my_min_tts_values_projected= min_tts_values.* sweeps_per_swap_attempt* time_per_sweeps_fpga;
my_ci_lower_projected = ci_lower.* sweeps_per_swap_attempt* time_per_sweeps_fpga;
my_ci_upper_projected = ci_upper.* sweeps_per_swap_attempt* time_per_sweeps_fpga;
%caclulate projected slope


chosen_data_points = 7:length(min_tts_values); % for fit
log_my_tts_values = log10(my_min_tts_values_projected(chosen_data_points));
my_fit_params = polyfit(problem_sizes(chosen_data_points), log_my_tts_values, 1);  % Note x is not log-transformed
projected_alpha = my_fit_params(1);  % This is the slope in the semilog plot
projected_beta = my_fit_params(2); % Intercept of the fitted line in semilog scale
%


fprintf('\n\nFPGA projected Alpha: %0.4f\n', projected_alpha);
fprintf('FPGA projected Beta: %0.2f\n', projected_beta);

%% 95% fit to compute () of slopes
log_my_ci_lower_projected  = log10(my_ci_lower_projected(chosen_data_points));
my_fit_params_low95 = polyfit(problem_sizes(chosen_data_points), log_my_ci_lower_projected , 1);  % Note x is not log-transformed
projected_alpha_low95 = my_fit_params_low95(1);  % This is the slope in the semilog plot
projected_beta_low95 = my_fit_params_low95(2); % Intercept of the fitted line in semilog scale

log_my_ci_upper_projected  = log10(my_ci_upper_projected(chosen_data_points));
my_fit_params_up95 = polyfit(problem_sizes(chosen_data_points), log_my_ci_upper_projected , 1);  % Note x is not log-transformed
projected_alpha_up95 = my_fit_params_up95(1);  % This is the slope in the semilog plot
projected_beta_up95 = my_fit_params_up95(2); % Intercept of the fitted line in semilog scale

fprintf('\n\nFPGA projected Alpha max deviation at CI 95: %0.4f\n', max(abs(projected_alpha_up95-projected_alpha), abs(projected_alpha_low95-projected_alpha)));
fprintf('FPGA projected Beta max deviation at CI: %0.2f\n', max(abs(projected_beta_up95-projected_beta), abs(projected_beta_low95-projected_beta)));

%
% Choose appropriate x and y coordinates for the text position
textX = max(problem_sizes) * 0.6; % Example: 60% along the x-axis range
textY = max(TTS) * 0.8;           % Example: 80% along the y-axis (TTS) range

% Prepare the text string
textStr = sprintf('projected Alpha: %.4f\nprojected Beta: %.4f', projected_alpha, projected_beta);

% Add the text to the plot
text(textX, textY, textStr, 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');




%% FPGA
load_name = sprintf('./extracted_tts_data/data_q%d_fpga.mat',q_value);
load(load_name, 'fpga_sizes', 'min_tts_values_fpga' ,'ci_lower_fpga', 'ci_upper_fpga');


%+  0*(num_replicas-1)/2*2;

% Assuming the conversion is the same as for the projected data
% Assuming num_replicas, time_per_sweeps, sweeps_per_swap_attempt, and projected_ratio are the same for FPGA
my_min_tts_values_fpga = min_tts_values_fpga .* sweeps_per_swap_attempt* time_per_sweeps_fpga;
my_ci_lower_fpga = ci_lower_fpga.* sweeps_per_swap_attempt* time_per_sweeps_fpga;
my_ci_upper_fpga = ci_upper_fpga.* sweeps_per_swap_attempt* time_per_sweeps_fpga;

fpga_color = 'r'; % A shade of green, for example
fpga_marker_size = 16;

% Calculate the errors relative to your data points
lower_error_fpga = my_min_tts_values_fpga - my_ci_lower_fpga;
upper_error_fpga = my_ci_upper_fpga - my_min_tts_values_fpga;
errors_fpga = [lower_error_fpga; upper_error_fpga];

% Plot the FPGA data with error bars
h_fpga = errorbar(ax, fpga_sizes, my_min_tts_values_fpga, lower_error_fpga, upper_error_fpga, "pentagram", ...
    'Color', fpga_color, 'LineWidth', 2, 'MarkerSize', fpga_marker_size, 'MarkerFaceColor', fpga_color);


[projected_sizes, projected_index] = setdiff(problem_sizes,fpga_sizes);
% Calculate the errors relative to your data points
lower_error_projected = my_min_tts_values_projected(projected_index) - my_ci_lower_projected(projected_index);
upper_error_projected = my_ci_upper_projected(projected_index) - my_min_tts_values_projected(projected_index);
errors_projected = [lower_error_projected; upper_error_projected];

% Plot the projected data with error bars
h_projected =plot(ax, projected_sizes, my_min_tts_values_projected(projected_index), 's',...
    'Color', fpga_color, 'LineWidth', 2, 'MarkerSize', fpga_marker_size+2, 'MarkerFaceColor', 'none',MarkerEdgeColor=fpga_color);


% h_projected = semilogy(ax, projected_sizes, my_min_tts_values_projected(projected_index), '*-','MarkerFaceColor',fpga_color, ...
%     'Color', fpga_color, 'MarkerSize', fpga_marker_size, 'LineWidth', 2);
%legend_entries{end+1} = sprintf('APT (projected) projected');

% Calculate the slope for the FPGA data
chosen_data_points_fpga = 2:length(min_tts_values_fpga); % Choose points for fit
log_my_tts_values_fpga = log10(my_min_tts_values_fpga(chosen_data_points_fpga));
fpga_fit_params = polyfit(fpga_sizes(chosen_data_points_fpga), log_my_tts_values_fpga, 1);
fpga_alpha = fpga_fit_params(1);  % Slope in the semilog plot for FPGA
fpga_beta = fpga_fit_params(2);  % Intercept of the fitted line in semilog scale for FPGA

fpga_sizes_full = 16:16:256;
num_replicas =  [5     6     7     8     8     9     9     10    11    11    11    12    12   12  13  13]; % last 3 projected

fpga_fitted_TTS = 10.^(projected_alpha * fpga_sizes_full + projected_beta);

% Plot the fitted line for the FPGA data as a dashed line on your existing axes
semilogy(ax, fpga_sizes_full, fpga_fitted_TTS,'color',fpga_color,'linestyle', '--', ...
    'LineWidth', 2);
legend_entries{end+1} = sprintf('p-computer');


%% MTJ Projection
fp = 1e6./(fpga_sizes_full.*num_replicas);

%=fp=ones(size(fp))
MTJ_fitted_TTS = fpga_fitted_TTS*15/1000./fp;
semilogy(ax, fpga_sizes_full(7:end), MTJ_fitted_TTS(7:end),'color',[169 169 169]/255,'linestyle', '--', ...
    'LineWidth', 2);

MTJ_fit_params = polyfit(fpga_sizes_full(7:end), log10(MTJ_fitted_TTS(7:end)), 1);
fpga_alpha = MTJ_fit_params(1);  % Slope in the semilog plot for FPGA
fpga_beta = MTJ_fit_params(2);  % Intercept of the fitted line in semilog scale for FPGA

% Print the FPGA fit parameters
fprintf('\n\nMTJ projected Alpha: %0.6f\n', fpga_alpha);
fprintf('MTJ projected Beta: %0.6f\n', fpga_beta);


ax.YMinorTick = 'off';
ax.MinorGridLineStyle = 'none';  % Turn off minor grid lines if any
%legend_entries{end+1} = sprintf('p-computer');
% Update the plot
drawnow;

set(groot,{'DefaultAxesXColor','DefaultAxesYColor','DefaultAxesZColor'},{'k','k','k'})
box on

% Update the plot handles array with your projected and FPGA data handles
plot_handles = [plot_handles; h_fpga];  % 'h_projected' and 'h_fpga' are the handles from your projected and FPGA plots
% Remove empty entries from plot_handles
plot_handles = plot_handles(plot_handles ~= 0);
% Add the FPGA slope to the legend

% Update the legend
%legend(plot_handles, legend_entries, 'Location', 'northwest','Interpreter','none','box','off');
%legend(plot_handles, legend_entries, 'Location', 'northwest', 'Interpreter', 'none', 'box', 'off', 'NumColumns', 2);
legend(plot_handles, legend_entries, 'Location', 'northwest', 'Interpreter', 'none', 'Box', 'on', 'NumColumns', 2, 'Color', [1 1 1], 'EdgeColor', 'black');

% Refresh the figure to show all changes
figure(fig);

xlim([0 300])
%title('LIDAR BETA METHOD')

orient(gcf,'landscape')
fig =gcf;
print(fig, sprintf('FIG4'), '-dpdf', '-bestfit')


