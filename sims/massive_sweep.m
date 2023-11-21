clc
clearvars
close all

addpath('./3r3x_Instances/n16','./3r3x_Instances/n32','./3r3x_Instances/n48','./3r3x_Instances/n64','./3r3x_Instances/n80','./3r3x_Instances/n96','./3r3x_Instances/n112','./3r3x_Instances/n128');

warning('OFF')

numworkers=12;

min_ps = 16;
max_ps = 128;

NUM_SWAPS = 3000;

alpha = 1;

if(isempty('gcp'))
    parpool('local',numworkers);
end

for ps=min_ps:16:max_ps

    files = dir(strcat('3r3x_Instances/n', string(ps), '/*.txt'));

    

    % Run APT-Preprocessing on the first instance to create a temp. profile
    % for that problem class.
    file = files(1).name;
    
    [J,h] = txt_to_A_droplet(file);
    
    e = length(file) - 4;
    colorMap = readmatrix(strcat('colorMap_', file(1:e), '.csv'));
    
    [beta, sigma] = APT_preprocess(J, h, colorMap, alpha, 1);
    
    disp(strcat("Length of beta for ", string(ps), "is", string(length(beta))));
    for instance=1:100
        file = files(instance).name;
        disp(file);
        
        [J,h] = txt_to_A_droplet(file);
        
        e = length(file) - 4;
        colorMap = readmatrix(strcat('colorMap_', file(1:e), '.csv'));
        
        base_seed = 2000;
        
        sweeps_per_swap = 100;
        num_runs = 1000;
        success_swaps = zeros(num_runs, size(beta,2));
        i_energy = zeros(num_runs, length(beta), NUM_SWAPS);
        swaps = zeros(num_runs, 1);
        times = zeros(num_runs, 1);
        
        parfor j=1:num_runs
        
	        sstream = RandStream('mt19937ar','Seed',base_seed+j);  % added by Shuvro
            RandStream.setGlobalStream(sstream);                     % added by Shuvro
            now1 = tic();
            [attempts, success_attempts, num_swaps_taken, EnergyList] = APT(J, h, colorMap, beta, NUM_SWAPS, sweeps_per_swap, base_seed+j);  % modified by Shuvro
            now2 = toc(now1);
        
            success_swaps(j,:) = success_attempts ./ attempts;
            swaps(j) = num_swaps_taken;
            i_energy(j, :, :) = EnergyList;
            times(j) = now2;
        end
        save(strcat('n', string(ps), '_instance_', string(instance), 'data.mat'), 'times', 'success_swaps', 'beta', "swaps")
    end
end