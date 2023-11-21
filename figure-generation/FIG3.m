clc;
clearvars;
close all;

q_value = 50;

set(groot,{'DefaultAxesXColor','DefaultAxesYColor','DefaultAxesZColor'},{'k','k','k'})
% % Load your data and plot it, rename to 'APT (CPU)'
load_name = sprintf('./extracted_tts_data/data_q%d_cpu.mat',q_value);
load(load_name, 'problem_sizes', 'min_tts_values' ,'ci_lower', 'ci_upper');

% Load the data
load_name = sprintf('./extracted_tts_data/data_q%d_fpga.mat',q_value);
load(load_name, 'fpga_sizes', 'min_tts_values_fpga' ,'ci_lower_fpga', 'ci_upper_fpga');

[cpu_masked_size, cpu_index] = setdiff(problem_sizes,fpga_sizes);


% Define problem sizes and time per MCS
prob_size = [16,32,48,64,80,96,112,128,144,160,176,192,208];
prob_size_fpga = fpga_sizes;
time_per_MCS_CPU = [22.139,28.85,45.40,59.132,72.185,89.26,100.10,138.56,166.38,206.00,212.13,241.56,305.05];
time_per_MCS_FPGA = 1/(15e6)*1e6*ones(size(prob_size_fpga));

% Perform linear fits and print slopes
p_cpu = polyfit(prob_size, log10(time_per_MCS_CPU), 1);
fprintf('Slope for time_per_MCS_CPU: %f\n', p_cpu(1));

p_fpga= polyfit(prob_size_fpga, log10(time_per_MCS_FPGA), 1);
fprintf('Slope for time_per_MCS_FPGA: %f\n', p_fpga(1));

fitted_time_per_MCS_CPU= 10.^(p_cpu(1) * prob_size +p_cpu(2));
fitted_time_per_MCS_FPGA=  10.^(p_fpga(1) *prob_size_fpga + p_fpga(2));

% Define colors and styles
colors = get(gca, 'ColorOrder');
line_complete = 'o-'; 
line_sparse = 's-'; 
color_complete = [0, 0.4470, 0.7410]; 
color_sparse = [0.8500, 0.3250, 0.0980];



% Plotting Fig. 3b as the first subplot
subplot(1,2,2);
scatter(prob_size,time_per_MCS_CPU,89,'o','color',color_complete,'MarkerFaceColor',color_complete,'MarkerEdgeColor',color_complete,'MarkerFaceAlpha',1);
hold on;
% plot(prob_size,fitted_time_per_MCS_CPU,'--','color',color_complete);
% hold on

scatter(prob_size_fpga,time_per_MCS_FPGA,144,'s','color',color_sparse,'MarkerFaceColor',color_sparse,'MarkerEdgeColor',color_sparse,'MarkerFaceAlpha',1);
% hold on;
plot(prob_size(cpu_index),mean(time_per_MCS_FPGA),'s','color',color_sparse,'MarkerFaceColor','none','MarkerEdgeColor',color_sparse,'MarkerSize',10.6);
box on



%xlabel('problem size, n');
xlim([10 218])
ylabel('time per sweep (\mus)');
set(gca,'XScale','linear');
set(gca,'YScale','log');
legend('all-to-all (CPU)','master graph (FPGA)','box','off','location','best');
set(gca,'FontName', 'Arial','FontSize',24,'fontweight','bold','linewidth',1.25);
hold off;

sweeps_to_swap_ratio = 102;


% Plotting Fig. 3a as the second subplot
subplot(1,2,1);
scatter(problem_sizes,min_tts_values*sweeps_to_swap_ratio,121,'o','MarkerFaceColor',colors(1,:),'MarkerEdgeColor',colors(1,:),'MarkerFaceAlpha',1);
box on
hold on;
scatter(fpga_sizes,min_tts_values_fpga*sweeps_to_swap_ratio,49,'s','MarkerFaceColor',colors(2,:),'MarkerEdgeColor',colors(2,:),'MarkerFaceAlpha',1);


%xlabel('problem size, n');
ylabel('optimal median sweeps to solution');
set(gca,'XScale','linear');
set(gca,'YScale','log');
xlim([10 218])
% legend('all-to-all(CPU)','master graph (FPGA)','box','off','location','best');
set(gca,'FontName', 'Arial','FontSize',24,'fontweight','bold','linewidth',1.25);
hold off;

% Adjust layout
orient(gcf,'landscape');
fig = gcf;
set(gcf, 'PaperPositionMode', 'auto');

% Save the combined figure
print(fig, 'FIG3AB', '-dpdf', '-bestfit');



chosen_data_points = 7:length(min_tts_values); % for fit
% Calculate the Total Time to Solution (TTS) for CPU and FPGA
TTS_CPU = time_per_MCS_CPU'/1e6 .* min_tts_values*sweeps_to_swap_ratio;
TTS_FPGA = time_per_MCS_FPGA'/1e6 .* min_tts_values_fpga*sweeps_to_swap_ratio;
TTS_projected = mean(time_per_MCS_FPGA)/1e6* min_tts_values(chosen_data_points)*sweeps_to_swap_ratio;


% Perform linear fits and print slopes
p_cpu_optTTS = polyfit(prob_size(chosen_data_points), log10(TTS_CPU(chosen_data_points)), 1);
fprintf('\n\nSlope for optTTS CPU (including O(n)): %f\n', p_cpu_optTTS(1));

p_fpga_optTTS= polyfit(prob_size_fpga(2:end), log10(TTS_FPGA(2:end)), 1);
fprintf('Slope optTTS FPGA (lower part fit): %f\n', p_fpga_optTTS(1));

p_projected_optTTS= polyfit(prob_size(chosen_data_points), log10(TTS_projected), 1);
fprintf('Slope optTTS FPGA projected %f\n', p_projected_optTTS(1));


fitted_TTS_CPU= 10.^(p_cpu_optTTS(1) * prob_size +p_cpu_optTTS(2));
fitted_TTS_FPGA=  10.^(p_fpga_optTTS(1) *prob_size_fpga + p_fpga_optTTS(2));
fitted_TTS_projected=  10.^(p_projected_optTTS(1) *prob_size + p_projected_optTTS(2));

my_ci_lower_cpu = sweeps_to_swap_ratio*ci_lower.* time_per_MCS_CPU'/1e6 ;
my_ci_upper_cpu= sweeps_to_swap_ratio*ci_upper.*time_per_MCS_CPU'/1e6 ;
lower_error_cpu = TTS_CPU - my_ci_lower_cpu;
upper_error_cpu = my_ci_upper_cpu - TTS_CPU;
errors_cpu = [lower_error_cpu; upper_error_cpu];


my_ci_lower_FPGA = sweeps_to_swap_ratio*ci_lower_fpga.* time_per_MCS_FPGA'/1e6 ;
my_ci_upper_FPGA= sweeps_to_swap_ratio*ci_upper_fpga.*time_per_MCS_FPGA'/1e6 ;
lower_error_FPGA = TTS_FPGA - my_ci_lower_FPGA;
upper_error_FPGA = my_ci_upper_FPGA - TTS_FPGA;
errors_FPGA = [lower_error_FPGA; upper_error_FPGA];

my_ci_lower_projected = sweeps_to_swap_ratio*ci_lower(chosen_data_points)* mean(time_per_MCS_FPGA)/1e6 ;
my_ci_upper_projected= sweeps_to_swap_ratio*ci_upper(chosen_data_points)*mean(time_per_MCS_FPGA)/1e6 ;
lower_error_projected = TTS_projected - my_ci_lower_projected;
upper_error_projected = my_ci_upper_projected - TTS_projected;
errors_projected = [lower_error_projected; upper_error_projected];


legend_entries = cell(2, 1);
% Create a new figure for TTS plots
ax = axes(figure);

% Plot TTS for CPU
h_cpu  = errorbar(prob_size, TTS_CPU, lower_error_cpu, upper_error_cpu, 'linestyle','none','Marker','o','MarkerFaceColor',colors(1,:),'MarkerEdgeColor',colors(1,:),'markersize',10);
legend_entries{1} = sprintf('all-to-all (CPU)');
hold on;

% Plot TTS for FPGA
h_fpga = errorbar(prob_size_fpga, TTS_FPGA, lower_error_FPGA, upper_error_FPGA,'linestyle','none','Marker','s','MarkerFaceColor',colors(2,:),'MarkerEdgeColor',colors(2,:),'markersize',12);
legend_entries{2} = sprintf('master graph (FPGA)');
hold on

plot(prob_size, fitted_TTS_projected, 'linestyle','--','Marker','none','LineWidth',2);
plot(prob_size(cpu_index), fitted_TTS_projected(cpu_index), 'linestyle','none','Marker','s','MarkerFaceColor','none','MarkerEdgeColor',colors(2,:),'markersize',12,'LineWidth',2);


set(ax,'YScale', 'log'); % Log scale for y-axis

% Customize the ylabel based on q_value
if q_value == 50
    ylabel_str = 'optimal median TTS (sec)';
else
    ylabel_str = sprintf('optimal Q%d TTS (sec)', q_value);
end


% Customize the plot
%xlabel('problem size n');
ylabel(ylabel_str);
%legend('Location', 'northwest');
set(gca, 'GridLineStyle', '-', 'MinorGridLineStyle', '-','LineWidth',1); % Set grid lines to solid
grid('on'); % Add grid for better readability

xlim([0 218])
ylim([1e-5 1e5])
yticks([1e-5 1 1e5])
% Add a legend
legend('Location', 'best');

% Set the font name, size, weight, and axis line width
set(gca, 'FontName', 'Arial', 'FontSize', 24, 'FontWeight', 'bold', 'LineWidth', 1.25);


% Update the plot handles array with your CPU and FPGA data handles
plot_handles = [h_cpu; h_fpga];  % 'h_cpu' and 'h_fpga' are the handles from your CPU and FPGA plots
% Update the legend
legend(plot_handles, legend_entries, 'Location', 'northwest','Interpreter','none','box','off');



% Hold off to finish the plot
hold off;



% Adjust layout
orient(gcf,'landscape');
fig = gcf;
set(gcf, 'PaperPositionMode', 'auto');

% Save the combined figure
print(fig, 'FIG3c', '-dpdf', '-bestfit');

