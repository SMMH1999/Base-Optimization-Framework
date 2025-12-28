function [bestFitness, bestPosition, convergenceCurve] = MADFOA(lowerBound, upperBound, dimension, numAgents, maxIterations, costFunction, functionIndex, details)
    % MADFOA + Hybrid Gaussian-Cauchy Mutation
    % Enhanced version with a nonlinear schedule to balance Cauchy and Gaussian mutations

    % ───────────── Prepare bounds ─────────────
    lb = reshape(lowerBound, 1, []); % Ensure row vector
    ub = reshape(upperBound,  1, []); % Ensure row vector
    if isscalar(lb), lb = repmat(lb, 1, dimension); end % Expand scalar lower bound
    if isscalar(ub), ub = repmat(ub, 1, dimension); end % Expand scalar upper bound
    dim = dimension; N = numAgents; Tmax = maxIterations;

    % ───────────── Hyperparameters ─────────────
    topK              = max(10, min(N, ceil(0.15*N))); % Number of elites
    chaosInterval     = 100;   % Interval for chaotic jump
    restartInterval   = 200;   % Interval for random restart of worst solutions
    localSearchPeriod = 100;   % Frequency of local search
    mutationProb      = 0.25;  % Probability of mutation
    betaGrow          = 1.05;  % Growth factor for beta
    betaShrink        = 0.99;  % Shrink factor for beta
    mutGrow           = 1.01;  % Growth factor for mutation strength
    mutShrink         = 0.95;  % Shrink factor for mutation strength

    % ───────────── Initialization ─────────────
    pos     = lb + (ub - lb).*rand(N, dim); % Random initial positions
    fitness = zeros(N,1);
    for i=1:N
        fitness(i) = evalCost(pos(i,:), costFunction, functionIndex, details);
    end

    [bestFitness, bestIdx] = min(fitness);
    bestPosition = pos(bestIdx, :);

    beta     = 1 + rand(N,1);         % Step size control
    mutation = 0.05 * ones(N,1);      % Mutation strength
    memory     = pos;                 % Memory of solutions
    memoryFit  = fitness;             % Fitness of memory

    convergenceCurve = inf(1, Tmax);
    convergenceCurve(1) = bestFitness;

    stagnation = 0; % Counter for stagnation

    % ───────────── Main loop ─────────────
    for t = 1:Tmax

        % --- Elite selection and covariance ---
        [~, sortedIdx] = sort(fitness, 'ascend'); % Sort by fitness
        k = min(topK, N);
        top = pos(sortedIdx(1:k), :);
        if size(top,1) >= 2
            C = cov(top) + 1e-8*eye(dim); % Covariance of elites
        else
            C = 1e-2*eye(dim); % Fallback covariance
        end
        R = safe_chol(C); % Cholesky decomposition
        xMean = mean(pos, 1);
        xGood = mean(top, 1);
        medFit = median(fitness);

        % --- Position update ---
        for i = 1:N
            if i == bestIdx, continue; end % Skip best solution

            r        = rand;
            dbest    = bestPosition - pos(i,:);
            dmean    = xMean        - pos(i,:);
            dgood    = xGood        - pos(i,:);
            nmean    = norm(dmean) + 1e-8; % Avoid division by zero

            % Levy/Brownian jumps
            if t <= Tmax/3
                jump = levy_flight(dim, 1.5) .* dbest;
            elseif t <= 2*Tmax/3
                if mod(i,2)==0
                    jump = randn(1,dim) .* dbest;
                else
                    jump = levy_flight(dim, 1.5) .* dbest;
                end
            else
                jump = randn(1,dim) .* dbest;
            end

            % Covariance-guided step
            covStep = 0.1 * (randn(1,dim) * R);

            % Candidate position generation
            cand = pos(i,:) ...
                + beta(i) * r * tanh(dbest) ...
                + 0.5 * r * (dmean / nmean) ...
                + 0.3 * tanh(dgood) ...
                + jump + covStep;

            % --- Hybrid Mutation (Gaussian vs Cauchy) ---
            if rand < mutationProb
                % Nonlinear scheduling: more Cauchy early, more Gaussian later
                pCauchy = exp(-3 * (t/Tmax)^2); % Decays nonlinearly with iterations
                if rand < pCauchy
                    % Cauchy mutation for exploration (long jumps)
                    cand = cand + mutation(i) * cauchy_rnd(1,dim);
                else
                    % Gaussian mutation for exploitation (small steps)
                    cand = cand + mutation(i) * randn(1,dim);
                end
            end

            % Bounds check
            cand = clamp(cand, lb, ub);

            % Evaluate and update memory
            fNew = evalCost(cand, costFunction, functionIndex, details);
            if fNew < memoryFit(i)
                pos(i,:)     = cand;
                memory(i,:)  = cand;
                memoryFit(i) = fNew;
                fitness(i)   = fNew;
            else
                pos(i,:)   = memory(i,:);
                fitness(i) = memoryFit(i);
            end

            % OBL (Opposition-Based Learning) every 5 iterations or for weak solutions
            if mod(t,5)==0 || fitness(i) > medFit
                opp  = opposition_point(pos(i,:), lb, ub);
                fOpp = evalCost(opp, costFunction, functionIndex, details);
                if fOpp < fitness(i)
                    pos(i,:)    = opp;
                    fitness(i)  = fOpp;
                    memory(i,:) = opp;
                    memoryFit(i)= fOpp;
                end
            end
        end

        % --- Social learning ---
        [fitness, reIdx] = sort(fitness, 'ascend');
        pos       = pos(reIdx, :);
        memory    = memory(reIdx, :);
        memoryFit = memoryFit(reIdx);
        [currBest, bestIdx] = min(fitness);
        bestPosition = pos(bestIdx, :);

        for i = 1:N
            if i == bestIdx, continue; end
            if i > 1
                j = randi(i-1);
                r = rand;
                % Learning from better solutions
                pos(i,:) = pos(i,:) + beta(i) * r * (pos(j,:) - pos(i,:));
                pos(i,:) = clamp(pos(i,:), lb, ub);
                fitness(i) = evalCost(pos(i,:), costFunction, functionIndex, details);
            end
        end

        % --- Adaptation and stagnation ---
        if currBest < bestFitness
            bestFitness = currBest;
            beta(bestIdx)     = beta(bestIdx) * betaGrow; % Strengthen step size
            mutation(bestIdx) = max(1e-6, mutation(bestIdx) * mutShrink); % Reduce mutation
            stagnation = 0;
        else
            beta     = beta * betaShrink; % Shrink beta
            mutation = mutation * mutGrow; % Increase mutation strength
            stagnation = stagnation + 1;
        end

        % Chaotic jump if stagnation persists
        if stagnation > chaosInterval
            c = rand; c = 4*c*(1-c); % Logistic map
            bestPosition = bestPosition .* (1 + 0.005*(2*c - 1));
            bestPosition = clamp(bestPosition, lb, ub);
            bestFitness  = evalCost(bestPosition, costFunction, functionIndex, details);
            stagnation = 0;
        end

        % Local search on elites
        if localSearchPeriod > 0 && mod(t, localSearchPeriod) == 0
            [~, sIdx] = sort(fitness, 'ascend');
            elites = sIdx(1:min(topK, N));
            opts = optimset('Display','off','MaxFunEvals',200*dim,'MaxIter',200*dim);
            for jj = 1:numel(elites)
                x0 = pos(elites(jj), :);
                [loc, fval] = fminsearch(@(x) evalCost(clamp(x,lb,ub), costFunction, functionIndex, details), x0, opts);
                loc = clamp(loc, lb, ub);
                if fval < bestFitness
                    bestFitness  = fval;
                    bestPosition = loc;
                end
                pos(elites(jj), :) = loc;
                fitness(elites(jj)) = evalCost(loc, costFunction, functionIndex, details);
            end
            [fitness, reIdx] = sort(fitness, 'ascend');
            pos = pos(reIdx, :);
            [bestFitness, bestIdx] = min(fitness);
            bestPosition = pos(bestIdx, :);
        end

        % Periodic restart of worst solutions
        if restartInterval > 0 && mod(t, restartInterval) == 0
            [~, sIdx] = sort(fitness, 'ascend');
            numR = max(1, round(0.20*N)); % Restart 20% of worst
            worst = sIdx(end-numR+1:end);
            pos(worst, :) = lb + rand(numR, dim).*(ub - lb);
            for k = 1:numR
                fitness(worst(k)) = evalCost(pos(worst(k),:), costFunction, functionIndex, details);
            end
            [bestFitness, bestIdx] = min(fitness);
            bestPosition = pos(bestIdx, :);
        end

        % Convergence curve update
        convergenceCurve(t) = bestFitness;
        if t > 1
            convergenceCurve(t) = min(convergenceCurve(t-1), convergenceCurve(t));
        end
    end
end % ===== END of MADFOA =====

% ─────────────────────────── Helpers ───────────────────────────
function y = clamp(x, lb, ub)
    % Clamp values within bounds
    y = min(max(x, lb), ub);
end

function opp = opposition_point(x, lb, ub)
    % Opposition-Based Learning (OBL) candidate generation
    opp = lb + ub - x .* rand();
    opp = clamp(opp, lb, ub);
end

function L = levy_flight(d, beta)
    % Levy flight random step generator
    sigma = (gamma(1+beta)*sin(pi*beta/2) / (gamma((1+beta)/2)*beta*2^((beta-1)/2)))^(1/beta);
    u = randn(1,d) * sigma; v = randn(1,d);
    L = u ./ abs(v).^(1/beta);
end

function R = safe_chol(C)
    % Safe Cholesky decomposition (with fallback if matrix not PSD)
    eps0 = 1e-8; I = eye(size(C,1));
    for k=1:6
        [R,p] = chol(C + eps0*I, 'lower');
        if p==0, return; end
        eps0 = eps0*10;
    end
    R = diag(sqrt(max(diag(C), 1e-8)));
end

function f = evalCost(x, costFunction, functionIndex, details)
    % Evaluate objective function with compatibility for benchmark suites
    name = func2str(details);
    if strcmp(name,'CEC_2005_Function') || strcmp(name,'ProbInfo')
        f = costFunction(x);
    else
        f = costFunction(x', functionIndex);
    end
end

function y = cauchy_rnd(m, n)
    % Generate random numbers from standard Cauchy distribution
    u = rand(m,n);
    y = tan(pi*(u - 0.5));
end