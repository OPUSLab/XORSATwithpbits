function [M] = MCMC_GC (num_sweeps, m_start, beta, J, h, colormap, anneal)

%% inputs:
% num_sweeps: how many MCMC sweeps are requested
% m_start:    seed value of the states
% beta:       inverse temperature, put maximum one if anneal
% J:          weight matrix of size N x N where N is size of graph
% h:          bias is of size N x 1 where N is size of graph
% colormap:   color list for the nodes, should be size of 1xN where N is size of graph
% anneal:     1 if you want to anneal, 0 if not

%% output:
% M:          M matrix containing all the sweeps in bipolar form. size N x num_sweeps

%% Initial value
N=length(J); % size of graph
m = m_start; % seed value of the states
x = zeros(N,1); % input signal initialization
M = zeros(N,num_sweeps); % state matrix initialization
J = sparse(J); % using sparse J for fast performance
if size(h,1)==1, h =h';end % handling dimension error

required_colors = length(unique(colormap)); % num of colors required

Groups = cell(1,required_colors); % groups to be updated in parallel
for k = 1:required_colors
    Groups{k} = find(colormap==k);
end

beta_run = zeros(1,num_sweeps);
for jj=1:num_sweeps % time step loop
    if mod(jj,1e4==0)
       % fprintf('%1.1f:Percent complete\n',round(jj/num_sweeps*100));
    end

    if anneal, beta_run(jj) = beta*jj/num_sweeps;
    else,      beta_run(jj) = beta; end

    %% GC for loop
    for ijk = 1:1:required_colors  % color group loop
        x(Groups{ijk}) = beta_run(jj)*(J(Groups{ijk},:)*m + h(Groups{ijk}));
        m(Groups{ijk}) = sign(tanh(x(Groups{ijk}))-2*rand(length(Groups{ijk}),1)+1);
    end
    M(:,jj)=m; % collect all states over time in bipolar

end
end