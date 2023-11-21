clc
clearvars
close all

instance_size = 80;
% select which swap attempt to get results
max_swaps = 100;

% Parameters
sweeps_per_swap = 100; % The number of sweeps per swap
num_instances_per_size = 100; % Number of instances per size
num_runs_per_instance = 1000; % Number of runs per instance
confidence_level = 0.99; % The desired confidence level for the TTS

idx = 1;

% Prepare to load data and calculate min and max swaps needed
swaps_range = [];
all_swaps = [];


pi_tf_values_per_instance = zeros(1,num_instances_per_size);
tts_values_per_instance = zeros(1,num_instances_per_size);

num_instances_with_data = 0;
for instance = 1:num_instances_per_size
    filename = sprintf('./cpu_data/n%d_instance_%ddata.mat', instance_size, instance);
    % Check if the data file exists before loading
    if exist(filename, 'file')
        data = load(filename, 'swaps');
        all_swaps = [data.swaps];
        num_instances_with_data = num_instances_with_data + 1;
    end


    swaps_range = [min(all_swaps), max(all_swaps)];


    ln_one_minus_confidence = log(1 - confidence_level);


    % Calculate pi_tf across all instances that have data
    successful_runs = all_swaps < max_swaps;

    pi_tf_values = sum(successful_runs) / num_runs_per_instance;


    % Calculate TTS for the given pi_tf
    if pi_tf_values > 0
        tf = max_swaps; % Constant tf as per your previous instruction
        tts_values = tf * ln_one_minus_confidence / log(1 - pi_tf_values);
    else
        tts_values = Inf;
    end


    pi_tf_values_per_instance(instance) = pi_tf_values;
    tts_values_per_instance(instance) = tts_values;
end




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
pi_tf_values_per_instance_fpga = zeros(1,num_instances_with_data);
tts_values_per_instance_fpga = zeros(1,num_instances_with_data);

instance = 1;
num_instances_with_data_fpga = 0;
% Load data for each instance
for instance_idx = instances_to_load
    filename = sprintf('swaps_n%d_s%d.mat', instance_size, instance_idx);
    file_path = fullfile(base_dir, sprintf('instance_%d', instance_idx), filename);

    if exist(file_path, 'file')
        load(file_path, 'total_swaps'); % 'total_swaps' should be a variable in your .mat file
        all_swaps = [total_swaps(1:num_runs_per_instance)]; % Append data for this instance
        num_instances_with_data_fpga = num_instances_with_data_fpga + 1;
    else
        disp(['File does not exist: ', file_path]);
    end


    % Calculate min and max swaps needed
    swaps_range = [min(all_swaps), max(all_swaps)];



    % Calculate pi_tf across all instances
    successful_runs = all_swaps < max_swaps;
    pi_tf_values = sum(successful_runs) / num_runs_per_instance;

    % Calculate TTS for the given pi_tf
    if pi_tf_values > 0
        tf = max_swaps; % Use tf as per the max_swaps
        tts_values = tf * ln_one_minus_confidence / log(1 - pi_tf_values);
    else
        tts_values = Inf;
    end


    pi_tf_values_per_instance_fpga(instance) = pi_tf_values;
    tts_values_per_instance_fpga(instance) = tts_values;
    instance = instance +1;

end


mininum_combined_instance = min(num_instances_with_data_fpga,num_instances_with_data);
pi_tf_values_per_instance = pi_tf_values_per_instance (1:mininum_combined_instance );
tts_values_per_instance = tts_values_per_instance(1:mininum_combined_instance);
pi_tf_values_per_instance_fpga = pi_tf_values_per_instance_fpga (1:mininum_combined_instance );
tts_values_per_instance_fpga = tts_values_per_instance_fpga(1:mininum_combined_instance );



% Plot pi_tf

% Define the plot style
markersize = 10;
line_complete = 'o-'; % Style for all-to-all (complete)
line_sparse = 's-'; % Style for master graph (sparse)
color_complete = [0, 0.4470, 0.7410]; % Color for all-to-all (complete)
color_sparse = [0.8500, 0.3250, 0.0980]; % Color for master graph (sparse)


% Combine the data into a matrix and take the first 20 highest probabilities
combined_data = [pi_tf_values_per_instance(:), pi_tf_values_per_instance_fpga(:)];
[~, sorted_indices] = sort(max(combined_data, [], 2), 'descend'); % Sort based on the maximum of either probability
top_indices = sorted_indices(1:20); % Take the top 20
data_for_bars = combined_data(top_indices, :);  % Use only the top 20 for grouped bars

%Create grouped bar plot for the top 20
fig_grouped_bar = figure;
b = bar(data_for_bars, 'grouped');  % Use the 'grouped' option for grouped bars

% Set the colors for each group
colormap([color_complete; color_sparse]);

% Adjust the opacity of each bar
for k = 1:length(b)
    b(k).FaceAlpha = 1;
end

% Adjust x-ticks to show only the top 20 instances
xticks(1:2:20);
%xticklabels(arrayfun(@(x) sprintf('%d', x), top_indices, 'UniformOutput', false)); % Label with the actual instance numbers

% Set the labels and legend
xlabel('sample instances');
ylabel('p_i');
lgd = legend({'all-to-all (complete)', 'master graph (sparse)'}, 'Location', 'northeast');
set(lgd, 'Box', 'off', 'TextColor', 'black'); % Legend box is turned off
title(sprintf('n = %d, swap attempts = %d',instance_size,max_swaps));
ylim([0 1])

% Adjust font and axes properties
set(gca, 'FontName', 'Arial', 'FontSize', 24, 'FontWeight', 'bold', 'TickLength', [0 0]);

% Save the figure
orient(fig_grouped_bar, 'landscape');
print(fig_grouped_bar, 'FIG2D', '-dpdf', '-bestfit');
