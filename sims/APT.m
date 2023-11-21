function [attempts, success_swap, ii, EnergyList] = APT(J, h, colorMap, beta, numSwaps, num_sweeps_per_swap, base_seed)
num_replicas = length(beta);

%% loading single replica J, h
%% Enter clauses as matrix
J=-J; h=-h;

ground = -2*length(h);

norm_factor = full(max(max(abs((J)))));

W_org = J; h_org = h; %original values from 1 replica

startingBeta = 1;
selectedBeta = startingBeta: startingBeta+num_replicas-1; % choose beta that you select


I0 = beta(selectedBeta);
I0 =I0/norm_factor;


% replicating W,h from single matrices to num of replicas
W = I0(1)*W_org; % 1st replica
h = I0(1)*h_org; % 1st replica

for replica_i =2:num_replicas
    W = blkdiag(W,I0(replica_i)*W_org);
    h((replica_i-1)*length(h_org)+1:replica_i*length(h_org)) = h_org*I0(replica_i);
end

h=h';

%% MCMC setup
num_swap_attempts= numSwaps;

%% RANDOMIZE THE EXPERIMENT INITIALS
m_start=sign(2.*rand(length(W),1)-1);

colorMap = repmat(colorMap,1,num_replicas);

% generate all possible consecutive pairs of replicas
all_pairs = reshape(1:num_replicas-1, [], 1) + [0 1];
oddAttempts = all_pairs(1:2:end,:);
evenAttempts = all_pairs(2:2:end,:);

EnergyList = zeros(num_replicas, num_swap_attempts);

attempts = zeros(num_replicas, 1);
success_swap = zeros(num_replicas, 1);
for ii = 1:num_swap_attempts
    [M] = MCMC_GC (num_sweeps_per_swap, m_start, 1, W, h, colorMap, 0);
    
    mm = M(:,end)';
    m_start = M(:,end);

    for inst=1:num_replicas
        m_sel = mm(end,1+(inst-1)*length(W_org):inst*length(W_org))';
        E_sel=-m_sel'*W_org*m_sel/2 -  m_sel'*h_org;
        EnergyList(inst, ii) = E_sel;
        if(E_sel == ground) 
            return;
        end
    end
    if mod(ii, 2) == 0
        selected_pairs = evenAttempts;
    else
        selected_pairs = oddAttempts;
    end
    % select subsequent non-overlapping pairs
    for jj = 1:size(selected_pairs)
        % Select a random replica
        
        sel= selected_pairs(jj,1);
        next = selected_pairs(jj,2);

        if(sel == 0 && next == 0)
            continue
        end

        attempts(sel) = attempts(sel)+1;

        m_sel = mm(end,1+(sel-1)*length(W_org):sel*length(W_org))';
        m_next = mm(end,1+(next-1)*length(W_org):next*length(W_org))';

        E_sel=-m_sel'*W_org*m_sel/2 -  m_sel'*h_org;
        E_next=-m_next'*W_org*m_next/2 -  m_next'*h_org;
        beta_sel=I0(sel);
        beta_next=I0(next);


        DeltaE=E_next-E_sel;
        DeltaB=beta_next-beta_sel;

        if rand<min(1,exp(DeltaB*DeltaE))

            success_swap(sel) = success_swap(sel)+1;

            m_start(1+(sel-1)*length(W_org):sel*length(W_org)) = m_next;
            m_start(1+(next-1)*length(W_org):next*length(W_org)) = m_sel;
        end

    end

end
end
