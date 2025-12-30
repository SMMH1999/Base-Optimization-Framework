function [Best_Fitness, Best_Position, Convergence_curve] = HFPSO( ...
    LB, UB, Dim, SearchAgents_no, Max_iter, Cost_Function, Function_Number, costFunctionDetails)
% HFPSO  Hybrid Firefly-PSO Optimizer, standalone
%
% Inputs:
%   LB, UB              – scalar or 1×Dim bounds
%   Dim                 – problem dimension
%   SearchAgents_no     – population size
%   Max_iter            – maximum iterations
%   Cost_Function       – handle to objective function
%   Function_Number     – extra parameter for Cost_Function
%   costFunctionDetails – tag for dispatching cost calls
%
% Outputs:
%   Best_Fitness        – best cost found
%   Best_Position       – 1×Dim best solution
%   Convergence_curve   – 1×Max_iter record of best cost per iteration

    % PSO parameters
    c1 = 2;
    c2 = 2;
    vmaxFactor = 0.1;

    % Ensure LB and UB are vectors
    if isscalar(LB), LB = repmat(LB, 1, Dim); end
    if isscalar(UB), UB = repmat(UB, 1, Dim); end

    % Initialize positions and velocities
    Positions  = initialization(SearchAgents_no, Dim, UB, LB);
    velocities = rand(SearchAgents_no, Dim) .* (repmat(vmaxFactor*(UB-LB)*2, SearchAgents_no, 1)) ...
                 - repmat(vmaxFactor*(UB-LB), SearchAgents_no, 1);

    % Initial fitness and personal bests
    fitnessAll = zeros(SearchAgents_no,1);
    for i = 1:SearchAgents_no
        fitnessAll(i) = evalCost(Positions(i,:), Cost_Function, Function_Number, costFunctionDetails);
    end
    pBestPos   = Positions;
    pBestCost  = fitnessAll;
    [bestCost, idx] = min(pBestCost);
    bestPos    = pBestPos(idx, :);

    % Prepare convergence curve
    Convergence_curve = inf(1, Max_iter);
    Best_Fitness      = bestCost;
    Best_Position     = bestPos;

    % Main optimization loop
    for iter = 1:Max_iter
        w = 0.9 - 0.4 * iter / Max_iter;  % inertia weight
        prevBest = bestPos;

        for i = 1:SearchAgents_no
            % Choose movement strategy
            if iter > 2 && fitnessAll(i) <= Convergence_curve(iter-2)
                [Positions(i,:), velocities(i,:)] = fireflyMove( ...
                    Positions(i,:), prevBest, LB, UB);
            else
                % PSO velocity update
                r1 = rand(1, Dim);
                r2 = rand(1, Dim);
                velocities(i,:) = w*velocities(i,:) ...
                    + c1 * r1 .* (pBestPos(i,:) - Positions(i,:)) ...
                    + c2 * r2 .* (prevBest      - Positions(i,:));
                % Velocity bounds
                vmax = vmaxFactor * (UB - LB);
                velocities(i,:) = min(max(velocities(i,:), -vmax), vmax);
                % Position update with bounds
                Positions(i,:) = min(max(Positions(i,:) + velocities(i,:), LB), UB);
            end
        end

        % Evaluate fitness after movement
        for i = 1:SearchAgents_no
            fitnessAll(i) = evalCost(Positions(i,:), Cost_Function, Function_Number, costFunctionDetails);
        end

        % Update personal and global bests
        improved = fitnessAll < pBestCost;
        pBestPos(improved,:)  = Positions(improved,:);
        pBestCost(improved)   = fitnessAll(improved);
        [bestCost, idx]       = min(pBestCost);
        bestPos               = pBestPos(idx,:);
        Best_Fitness          = bestCost;
        Best_Position         = bestPos;
        Convergence_curve(iter) = Best_Fitness;
    end
end

%%----------------------------------------------------------------------%%
function f = evalCost(x, Cost_Function, Function_Number, costFunctionDetails)
    % Dispatch cost evaluation
    name = func2str(costFunctionDetails);
    if strcmp(name, 'CEC_2005_Function') || strcmp(name, 'ProbInfo')
        f = Cost_Function(x);
    else
        f = Cost_Function(x', Function_Number);
    end
end

%%----------------------------------------------------------------------%%
function X = initialization(N, dim, UB, LB)
    % Random initialization in [LB, UB]
    if isvector(UB)
        X = rand(N, dim) .* (UB - LB) + LB;
    else
        X = zeros(N, dim);
        for k = 1:dim
            X(:, k) = rand(N, 1) .* (UB(k) - LB(k)) + LB(k);
        end
    end
end

%%----------------------------------------------------------------------%%
function [newX, newV] = fireflyMove(x, bestPrev, LB, UB)
    % Firefly-based move towards previous best
    beta0 = 2;
    gamma = 1;
    m     = 2;
    alpha = 0.2;

    ratio = norm(x - bestPrev) / (norm(UB - LB) + eps);
    beta  = beta0 * exp(-gamma * ratio^m);
    step  = levyStep(numel(x));

    newX = x + beta*(x - bestPrev) + alpha*step;
    newX = min(max(newX, LB), UB);
    newV = newX - x;
end

%%----------------------------------------------------------------------%%
function L = levyStep(d)
    % Generate a Lévy flight step
    beta  = 1.5;
    sigma = (gamma(1+beta) * sin(pi*beta/2) / ...
            (gamma((1+beta)/2) * beta * 2^((beta-1)/2)))^(1/beta);
    u = randn(1, d) * sigma;
    v = randn(1, d);
    L = u ./ abs(v).^(1/beta);
end
