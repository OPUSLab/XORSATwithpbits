% Clear workspace and close all figures
clc
clearvars
close all

% Parameters
instance_size = 80; % Set your instance size here
num_instances_per_size = 100;
num_runs_per_instance = 1000;

% Directory containing the .mat files
data_dir = './cpu_data'; % Modify this to your directory path

% Construct file search pattern based on instance size
file_pattern = sprintf('n%d_instance_*data.mat', instance_size);

% Find all .mat files in the directory with the specified instance size
mat_files = dir(fullfile(data_dir, file_pattern));

% Initialize a matrix to hold all swap rates
all_swap_rates = [];

% Loop over each .mat file
for file_idx = 1:length(mat_files)
    % Load the file
    file_path = fullfile(mat_files(file_idx).folder, mat_files(file_idx).name);
    data = load(file_path, 'success_swaps','beta');
    
    if file_idx == 1, num_replicas = length(data.beta); end

    % Extract the swap acceptance rates for the actual number of replicas
    swap_rates = data.success_swaps(:, 1:num_replicas-1);

    % Append the swap rates for this instance to the matrix of all swap rates
    all_swap_rates = [all_swap_rates; swap_rates]; % Vertically concatenate
end

% Handling NaNs when calculating the mean swap acceptance rate
mean_swap_rates = mean(all_swap_rates, 1, 'omitnan');


%% FPGA


% FPGA problem sizes and their corresponding directory paths and start instances
base_dir = sprintf('./fpga_data\\%d_pbit_experiments\\master',instance_size);
start_instance_numbers = [901, 2101, 3102, 101, 201, 301, 501]; % Starting instance numbers for each problem size


if instance_size == 16
    start_instance = start_instance_numbers(1);
elseif instance_size == 32
    start_instance = start_instance_numbers(2);
elseif instance_size == 48
    start_instance = start_instance_numbers(3);
elseif instance_size == 64
    start_instance = start_instance_numbers(4);
elseif instance_size == 80
    start_instance = start_instance_numbers(5);
elseif instance_size == 96
    start_instance = start_instance_numbers(6);
elseif instance_size == 112
    start_instance = start_instance_numbers(7);
end

% Prepare to load data
all_swaps = [];

instances_to_load = start_instance:(start_instance + num_instances_per_size - 1);

% Load data for each instance
num_instances_with_data = 0; % Counter for the number of instances with data
all_swap_rates_fpga = [];


for instance_idx = instances_to_load
    filename = sprintf('success_swaps_n%d_s%d.mat', instance_size, instance_idx);
    file_path = fullfile(base_dir, sprintf('instance_%d', instance_idx), filename);

    if exist(file_path, 'file')

        data_fpga = load(file_path, 'success_swaps');

        % Extract the swap acceptance rates for the actual number of replicas
        swap_rates_fpga = data_fpga.success_swaps(:, 1:num_replicas-1);

        % Append the swap rates for this instance to the matrix of all swap rates
        all_swap_rates_fpga = [all_swap_rates_fpga; swap_rates_fpga]; % Vertically concatenate
        num_instances_with_data = num_instances_with_data + 1;
    else
        disp(['File does not exist: ', file_path]);
    end
end


% Handling NaNs when calculating the mean swap acceptance rate
mean_swap_rates_fpga = mean(all_swap_rates_fpga, 1, 'omitnan');


% Prepare data for grouped bar plot
data_grouped = [mean_swap_rates; mean_swap_rates_fpga]';
num_pairs = size(all_swap_rates, 2); % Assuming there are 7 pairs

% Create labels for replica pairs
pair_labels = arrayfun(@(x) sprintf('[%d,%d]', x, x+1), 1:num_pairs, 'UniformOutput', false);

color_complete = [0, 0.4470, 0.7410]; % Color for all-to-all (complete)
color_sparse = [0.8500, 0.3250, 0.0980]; % Color for master graph (sparse)


% Create grouped bar plot
fig_grouped_bar = figure;
bar_handle = bar(data_grouped, 'grouped');
% Set the colors for each group
colormap([color_complete; color_sparse]);

% Adjust the opacity of each bar
for k = 1:length(bar_handle)
    bar_handle(k).FaceAlpha = 1;
end

legend({'all-to-all (complete)', 'master graph (sparse)'}, 'Location', 'northeast', 'Box', 'off');
xlabel('replica pairs', 'FontSize', 20, 'FontWeight', 'bold');
ylabel('swap acceptance rate', 'FontSize', 20, 'FontWeight', 'bold');
%title('Comparison of Average Swap Acceptance Rates: CPU vs FPGA', 'FontSize', 20, 'FontWeight', 'bold');
set(gca, 'XTick', 1:num_pairs, 'XTickLabel', pair_labels, 'FontSize', 20, 'FontWeight', 'bold');

% Adjust font and axes properties
set(gca, 'FontName', 'Arial', 'FontSize', 24, 'FontWeight', 'bold', 'TickLength', [0 0]);
set(groot,{'DefaultAxesXColor','DefaultAxesYColor','DefaultAxesZColor'},{'k','k','k'})
set(gca,'FontName', 'Arial','FontSize',24,'fontweight','bold','linewidth',1.5)

ylim([0 0.7])
% Save the figure
orient(fig_grouped_bar, 'landscape');
print(fig_grouped_bar, 'FIG2C', '-dpdf', '-bestfit');

