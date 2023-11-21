%% Adaptive Parallel Tempering (APT)
%
function [beta, saveSigma] = APT_preprocess(J, h, colorMap, alpha, beta_0)

% Set parameters
numParallelComputations = 1e2;
MCMC_sweeps = 2e3;
num_sweeps_read = 1e2;

J = -J; h = -h;

% Step 1: Normalize energy with |J_ij| ~ 1 %
normFactor = full(max(max(abs((J)))));
J = J / normFactor; h = h / normFactor;
N = length(J);
if size(h, 1) == 1, h = h'; end % Handling dimension error

% Step 2: Initialize beta_0 ~ 0.5 (chosen such that the largest spins can flip often enough)
beta = beta_0;
iteration = 1;
energyVariance = 1000; % Set to a large energy variance to start APT loop
energyVarianceMin = 0.5 * min(abs(J(J ~= 0))); % APT loop terminating energy variance

fixed_a = 6; fixed_b = 6;
beta_max = (2^fixed_a - 2^-fixed_b) / 2; % Max beta*J_binary needs to be less than max fixed point weight in s[a][b]

% Enable parallel processing

savedState = zeros(numParallelComputations, N);

% Step 4: APT loop until freezeout, typically avg_variance < sigma_min ~ 0.5*(smallest J_ij)
while (energyVariance > energyVarianceMin)
    

    % Step 4c: Compute new beta_i+1 = beta_i +(0.85-1.25)/avg_variance
    if iteration ~= 1
        beta(iteration) = beta(iteration - 1) + alpha / energyVariance;
    end

    Energy = zeros(numParallelComputations, num_sweeps_read);
    
    % Change regular for loop to parfor loop
    parfor j = 1:numParallelComputations
        if iteration == 1
            m_start = sign(2 .* rand(length(J), 1) - 1);
        else
            m_start = savedState(j, :)';
        end

        % Step 4a.i: MCMC (10k steps, iterate s, beta_i); returns final s_j and E_j
        M = MCMC_GC(MCMC_sweeps, m_start, beta(iteration), J, h, colorMap, 0);
        mm = M(:, end - num_sweeps_read + 1:end);

        for kk = 1:num_sweeps_read
            m = mm(:, kk)';
            Energy(j, kk) = -(m * J / 2 * m' + m * h); % Compute E_j
        end
        savedState(j, :) = m;
    end
    % Compute Energy sigma
    energyVariance = mean(std(Energy'));

    if(beta(iteration) > beta_max)
        break;
    end

    saveSigma(iteration) = energyVariance;
    iteration = iteration + 1;

    
end
end
