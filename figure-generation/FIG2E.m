clc
clearvars
close all

instance_sizes = 16:16:112; % Define a range of instance sizes

% Parameters
sweeps_per_swap = 100; % The number of sweeps per swap
num_instances_per_size = 100; % Number of instances per size
num_runs_per_instance = 1000; % Number of runs per instance
confidence_level = 0.99; % The desired confidence level for the TTS

% Choose the instance size and which instance to plot
instance_number = 'all'; % Example: 1, 2, ..., 100 or 'all'

% Set up tiled layout figures for pi_tf and TTS
fig_pi_tf = figure;

% Define labels for the instance being plotted
if isnumeric(instance_number)
    instance_label = sprintf('Instance %d', instance_number);
else
    instance_label = '100 Instances';
end

% Define markers for different instance sizes
% Define markers for different instance sizes
markers = {'o', 's', 'd', '^', 'v', '>', '<', 'p', 'h', '+', '*'}; % 10 Different markers

idx = 1;
% Loop over each instance size
for instance_size = instance_sizes
    % Prepare to load data and calculate min and max swaps needed
    swaps_range = [];
    all_swaps = [];

    if isnumeric(instance_number)
        filename = sprintf('./cpu_data/n%d_instance_%ddata.mat', instance_size, instance_number);
        data = load(filename, 'swaps','beta');
        swaps_range = [min(data.swaps), max(data.swaps)];
        num_replicas(idx) = length(data.beta);
        % Check for the 'all' case
    elseif strcmp(instance_number, 'all')
        num_instances_with_data = 0; % Counter for the number of instances with data
        for instance = 1:num_instances_per_size
            filename = sprintf('./cpu_data/n%d_instance_%ddata.mat', instance_size, instance);
            % Check if the data file exists before loading
            if exist(filename, 'file')
                data = load(filename, 'swaps');
                all_swaps = [all_swaps; data.swaps];
                num_instances_with_data = num_instances_with_data + 1;
            end
        end
        % Update the range based on the loaded data
        if num_instances_with_data > 0
            swaps_range = [min(all_swaps), 3000];
        else
            continue; % Skip the rest of the loop if no data was found
        end
    end

    % Sweep over max_swaps and calculate pi_tf and TTS for each value
    max_swaps_values = linspace(swaps_range(1), swaps_range(2), swaps_range(2)-swaps_range(1)+1);
    %max_swaps_values = unique(all_swaps);
    % skip = 1;
    %max_swaps_values = min(max_swaps_values):skip:max(max_swaps_values);
    % max_swaps_values  = max_swaps_values (1:10:end);
    pi_tf_values = zeros(size(max_swaps_values));
    tts_values = zeros(size(max_swaps_values));
    ln_one_minus_confidence = log(1 - confidence_level);

    % Define confidence level for the error bars (95% confidence interval)
    alpha = 0.05;

    % Initialize arrays to hold the lower and upper bounds of the confidence intervals
    lower_bounds = zeros(size(max_swaps_values));
    upper_bounds = zeros(size(max_swaps_values));

    for i = 1:length(max_swaps_values)
        max_swaps = max_swaps_values(i);
        if isnumeric(instance_number)
            % Calculate pi_tf for a single instance
            successful_runs = data.swaps < max_swaps;
            pi_tf_values(i) = sum(successful_runs) / num_runs_per_instance;
        elseif strcmp(instance_number, 'all')
            % Calculate pi_tf across all instances that have data
            successful_runs = all_swaps < max_swaps;

            if num_instances_with_data > 0
                pi_tf_values(i) = sum(successful_runs) / (num_instances_with_data * num_runs_per_instance);
            else
                pi_tf_values(i) = 0;
            end
        end

        % Calculate TTS for the given pi_tf
        if pi_tf_values(i) > 0
            tf = max_swaps; % Constant tf as per your previous instruction
            tts_values(i) = tf * ln_one_minus_confidence / log(1 - pi_tf_values(i));

            % Calculate the 95% confidence intervals using bootci
            % Here we assume that 'all_swaps' contains all the swap data across runs for the current max_swaps
            % ci = bootci(1000, {@(x) sum(x < max_swaps) / numel(x), all_swaps}, 'alpha', alpha)
            % % Store the lower and upper bounds
            % lower_bounds(i) = ci(1);
            % upper_bounds(i) = ci(2);


        else
            tts_values(i) = Inf;
        end
    end

    markersize = 8;

    % Plot pi_tf
    figure(fig_pi_tf);

    % Define the plot style
    line_complete = 'o-'; % Style for all-to-all (complete)
    line_sparse = 's-'; % Style for master graph (sparse)
    color_complete = [0, 0.4470, 0.7410]; % Color for all-to-all (complete)
    color_sparse = [0.8500, 0.3250, 0.0980]; % Color for master graph (sparse)


    % Blend with white to create a lighter color
    blend_ratio = 1; % Adjust this to control how light the color becomes
    lighter_color = blend_ratio * color_complete + (1 - blend_ratio) * [1 1 1]; % Blending with white

    lighter_color_FPGA = blend_ratio * color_sparse + (1 - blend_ratio) * [1 1 1]; % Blending with white



    % Plot pi_tf for all-to-all (complete)
    plot(max_swaps_values, pi_tf_values, line_complete, 'Color', lighter_color, 'LineWidth', 8,'marker','none');
    hold on

    min_tts_values(idx) = min(tts_values);
    idx = idx +1;
end



%% FPGA


% FPGA problem sizes and their corresponding directory paths and start instances
fpga_sizes = instance_sizes;

base_dirs = {
    './fpga_data\16_pbit_experiments\master',
    './fpga_data\32_pbit_experiments\master',
    './fpga_data\48_pbit_experiments\master',
    './fpga_data\64_pbit_experiments\master',
    './fpga_data\80_pbit_experiments\master',
    './fpga_data\96_pbit_experiments\master',
    './fpga_data\112_pbit_experiments\master'
    };
start_instance_numbers = [901, 2101, 3102, 101, 201,301,501]; % Starting instance numbers for each problem size

% individual
% base_dirs = {
%       'D:\DAC_to_Navid\Experiment Results\FPGA\80_pbit_experiments\master'
% };
% start_instance_numbers=201

% Loop over each FPGA problem size
for idx = 1:length(fpga_sizes)
    instance_size = fpga_sizes(idx);
    base_dir = base_dirs{idx};
    start_instance = start_instance_numbers(idx);

    % Prepare to load data
    all_swaps = [];

    % Determine the instances to load
    if strcmp(instance_number, 'all')
        instances_to_load = start_instance:(start_instance + num_instances_per_size - 1);
    else
        instances_to_load = start_instance + instance_number - 1;
    end

    num_instances_with_data = 0;
    % Load data for each instance
    for instance_idx = instances_to_load
        filename = sprintf('swaps_n%d_s%d.mat', instance_size, instance_idx);
        file_path = fullfile(base_dir, sprintf('instance_%d', instance_idx), filename);

        if exist(file_path, 'file')
            load(file_path, 'total_swaps'); % 'total_swaps' should be a variable in your .mat file
            all_swaps = [all_swaps total_swaps(1:num_runs_per_instance)]; % Append data for this instance
            num_instances_with_data = num_instances_with_data + 1;
        else
            disp(['File does not exist: ', file_path]);
        end
    end

    % Calculate min and max swaps needed
    swaps_range = [min(all_swaps), 3000];

    % Sweep over max_swaps and calculate pi_tf and TTS for each value
    max_swaps_values = linspace(swaps_range(1), swaps_range(2), swaps_range(2)-swaps_range(1)+1);
    %max_swaps_values = unique(all_swaps);
    % max_swaps_values  = max_swaps_values (1:10:end);
    pi_tf_values = zeros(size(max_swaps_values));
    tts_values = zeros(size(max_swaps_values));
    ln_one_minus_confidence = log(1 - confidence_level);

    for i = 1:length(max_swaps_values)
        max_swaps = max_swaps_values(i);
        % Calculate pi_tf across all instances
        successful_runs = all_swaps < max_swaps;
        pi_tf_values(i) = sum(successful_runs) / (num_instances_with_data * num_runs_per_instance);

        % Calculate TTS for the given pi_tf
        if pi_tf_values(i) > 0
            tf = max_swaps; % Use tf as per the max_swaps
            tts_values(i) = tf * ln_one_minus_confidence / log(1 - pi_tf_values(i));
        else
            tts_values(i) = Inf;
        end
    end

    % Plot pi_tf

    hold on
    plot(max_swaps_values, pi_tf_values, line_sparse, 'Color', lighter_color_FPGA, 'LineWidth', 4,'marker','none');

    %   plot(max_swaps_values, pi_tf_values, line_sparse, 'Color', color_sparse,'Marker','s', 'MarkerSize', markersize-7, 'LineWidth', 2);

    %  plot(max_swaps_values, pi_tf_values, 'LineStyle', '-', 'Color', color_sparse, 'Marker', markers{idx}, 'MarkerSize', 2, 'LineWidth', 4);
    hold on;

    set(gca, 'FontName', 'Arial', 'FontSize', 24, 'FontWeight', 'bold', 'LineWidth', 1.5);
    xlabel('swap attempts');
    ylabel('mean p_i');
    %title(sprintf('Problem size n = %d, %s', instance_size, instance_label));


    % Store the minimum TTS values for this FPGA size
    min_tts_values(idx) = min(tts_values);
end


axisfont = 24;

%bar(X,success_rate)
set(groot,{'DefaultAxesXColor','DefaultAxesYColor','DefaultAxesZColor'},{'k','k','k'})
set(gca,'FontName', 'Arial','FontSize',axisfont,'fontweight','bold','linewidth',1.5)


legend_str = arrayfun(@(x) sprintf('CPU n = %d', x), instance_sizes, 'UniformOutput', false);
legend_str = [legend_str, arrayfun(@(x) sprintf('FPGA n = %d', x), instance_sizes, 'UniformOutput', false)];
legend(legend_str, 'Location', 'southeast', 'Box', 'off');

%legend('all-to-all (complete)','master graph (sparse)','box','off','fontname','arial','fontsize',24,'location','southeast')
xlim([-5 500])
ylim([-0.005 1.01])





% ... (rest of your code for the TTS and FPGA sizes)

orient(gcf,'landscape')
fig =gcf;
print(fig, 'FIG2E', '-dpdf', '-bestfit')


