clc
clearvars
close all

num_bootstrap_samples = 1000;
num_instances_per_bootstrap_sample = 100;

num_instances_per_size = 100; % Number of instances per size
num_runs_per_instance = 1000; % Number of runs per instance
confidence_level = 0.99; % The desired confidence level for the TTS
max_swaps_allowed =3000;


% FPGA problem sizes and their corresponding directory paths and start instances
fpga_sizes = [16, 32, 48, 64 80 96 112];
instance_sizes = fpga_sizes;
base_dirs = {
    './fpga_data\16_pbit_experiments\master',
    './fpga_data\32_pbit_experiments\master',
    './fpga_data\48_pbit_experiments\master',
    './fpga_data\64_pbit_experiments\master',
    './fpga_data\80_pbit_experiments\master',
    './fpga_data\96_pbit_experiments\master',
    './fpga_data\112_pbit_experiments\master'
    };
start_instance_numbers = [901, 2101, 3102, 101, 201, 301, 501]; % Starting instance numbers for each problem size

% Initialize arrays for quantiles
q25 = zeros(length(instance_sizes), 1);
q50 = zeros(length(instance_sizes), 1);
q75 = zeros(length(instance_sizes), 1);


% Initialize arrays for storing mean TTS values
meanTTS50 = zeros(max_swaps_allowed, 1);
meanTTS25 = zeros(max_swaps_allowed, 1);
meanTTS75 = zeros(max_swaps_allowed, 1);

c25 = zeros(2,max_swaps_allowed);
c50 = zeros(2,max_swaps_allowed);
c75 = zeros(2,max_swaps_allowed);

ci_lower_allq_fpga = zeros(length(instance_sizes), 3); % For lower bounds of CI
ci_upper_allq_fpga = zeros(length(instance_sizes), 3); % For upper bounds of CI

idx = 1;

% Loop over each FPGA problem size
for size_idx = 1:length(fpga_sizes)
    instance_size = fpga_sizes(size_idx);
    base_dir = base_dirs{size_idx};
    start_instance = start_instance_numbers(size_idx);

    % Prepare to load data
    all_swaps = [];

    instances_to_load = start_instance:(start_instance + num_instances_per_size - 1);

    num_instances_with_data = 0; % Counter for the number of instances with data
    current_instance_data_swaps = zeros(num_instances_per_size, num_runs_per_instance);
    current_instance_swaps_range = zeros(num_instances_per_size, 2);
    for instance = 1:num_instances_per_size
        instance_idx = instances_to_load(instance);
        filename = sprintf('swaps_n%d_s%d.mat', instance_size, instance_idx);
        file_path = fullfile(base_dir, sprintf('instance_%d', instance_idx), filename);

        if exist(file_path, 'file')
            load(file_path, 'total_swaps'); % 'total_swaps' should be a variable in your .mat file
            num_instances_with_data = num_instances_with_data + 1;
            current_instance_data_swaps(instance, :) = total_swaps(1:num_runs_per_instance);
            current_instance_swaps_range(instance,:) = [min(total_swaps(1:num_runs_per_instance)), max(total_swaps(1:num_runs_per_instance))];
        else
            disp(['File does not exist: ', file_path]);

        end
    end

    ln_one_minus_confidence = log(1 - confidence_level);

    max_swaps_values = 1:max_swaps_allowed;
    for i = 1:length(max_swaps_values)   % for each tf
        max_swaps = max_swaps_values(i);

        bootstat25 = zeros(1,num_bootstrap_samples);
        bootstat50 = zeros(1,num_bootstrap_samples);
        bootstat75 =zeros(1,num_bootstrap_samples);


        for bs = 1:1:num_bootstrap_samples  % for each bs sample
            bs_instances = randi([1,num_instances_with_data],num_instances_per_bootstrap_sample); % choose instances randomly with repitition

            tts_values = zeros(1,length(bs_instances));
            for cur_ins = 1:1:length(bs_instances)  % for each sampled instance

                current_instance = bs_instances(cur_ins);
                % Calculate pi_tf for a single instance
                successful_runs = current_instance_data_swaps(current_instance, :) < max_swaps;
                pi_tf_values = sum(successful_runs) / num_runs_per_instance;

                % Kowalsky et al.
                % pi_tf_values = betarnd(0.5+sum(successful_runs),0.5+num_runs_per_instance-sum(successful_runs))*(sum(successful_runs)>0);


                % Calculate TTS for the given pi_tf
                if pi_tf_values > 0
                    tf = max_swaps; % Constant tf as per your previous instruction
                    tts_values(cur_ins) = tf * ln_one_minus_confidence / log(1 - pi_tf_values);

                    if pi_tf_values > 0.99
                        tts_values(cur_ins) = tf;
                    end
                else
                    tts_values(cur_ins) = Inf;
                end
            end
            % sampling and TTS generation is complete
            % now find the quartiles for this bs sample
            bootstat25(bs) = quantile(tts_values,0.25);
            bootstat50(bs) = quantile(tts_values,0.50);
            bootstat75(bs) = quantile(tts_values,0.75);
        end

        % I have quartitles for each bs sample now
        % now take their averages

        meanTTS25(i) = mean(bootstat25);
        meanTTS50(i) = mean(bootstat50);
        meanTTS75(i) = mean(bootstat75);


        c25(1,i) = quantile(bootstat25,0.025);
        c25(2,i) = quantile(bootstat25,0.0975);
        c50(1,i) = quantile(bootstat50,0.025);
        c50(2,i) = quantile(bootstat50,0.0975);
        c75(1,i) = quantile(bootstat75,0.025);
        c75(2,i) = quantile(bootstat75,0.0975);

    end

    % I have mean of quartiles for each time step now
    % let's find the minimum

    [q25(idx),xx1] = min(meanTTS25);
    [q50(idx),xx2] = min(meanTTS50);
    [q75(idx),xx3] = min(meanTTS75);
    [instance_size q50(idx)]

    % Calculate confidence intervals for each quantile using bootci
    ci_lower_allq_fpga(idx, 1) = c25(1,xx1);
    ci_upper_allq_fpga(idx, 1) = c25(2,xx1);

    ci_lower_allq_fpga(idx, 2) = c50(1,xx2);
    ci_upper_allq_fpga(idx, 2) = c50(2,xx2);

    ci_lower_allq_fpga(idx, 3) = c75(1,xx3);
    ci_upper_allq_fpga(idx, 3) = c75(2,xx3);

    idx = idx +1;
end


% Plotting the results with confidence intervals
figure;
hold on;
errorbar(instance_sizes, q25, q25 - ci_lower_allq_fpga(:,1), ci_upper_allq_fpga(:,1) - q25, 'b-o','LineWidth',2);
errorbar(instance_sizes, q50, q50 - ci_lower_allq_fpga(:,2), ci_upper_allq_fpga(:,2) - q50, 'r-s','LineWidth',2);
errorbar(instance_sizes, q75, q75 - ci_lower_allq_fpga(:,3), ci_upper_allq_fpga(:,3) - q75, 'g-^','LineWidth',2);
xlabel('Problem size n');
ylabel('Optimal TTS');
legend('25th Quantile', 'Median', '75th Quantile','Location','northwest');
set(gca, 'YScale', 'log')
%title('Quantiles of TTS with Confidence Intervals');
hold off;
box on


axisfont = 24


set(groot,{'DefaultAxesXColor','DefaultAxesYColor','DefaultAxesZColor'},{'k','k','k'})
set(gca,'FontName', 'Arial','FontSize',axisfont,'fontweight','bold','linewidth',1.5)


fpga_sizes = instance_sizes;
for q_value = [25 50 75]
    if(q_value == 25)
        min_tts_values_fpga = q25;
        ci_lower_fpga = ci_lower_allq_fpga(:,1);
        ci_upper_fpga = ci_upper_allq_fpga(:,1);

    elseif (q_value == 50)

        min_tts_values_fpga = q50;
        ci_lower_fpga = ci_lower_allq_fpga(:,2);
        ci_upper_fpga = ci_upper_allq_fpga(:,2);

    elseif (q_value == 75)

        min_tts_values_fpga = q75;
        ci_lower_fpga = ci_lower_allq_fpga(:,3);
        ci_upper_fpga = ci_upper_allq_fpga(:,3);
    end

    mkdir("extracted_tts_data")
    save_name = sprintf('./extracted_tts_data/data_q%d_fpga.mat',q_value)
    save(save_name, 'fpga_sizes', 'min_tts_values_fpga' ,'ci_lower_fpga', 'ci_upper_fpga');

end

