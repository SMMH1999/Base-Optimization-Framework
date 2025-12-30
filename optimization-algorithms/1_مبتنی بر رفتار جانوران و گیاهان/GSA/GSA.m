function [Best_Fitness, Best_Position, Convergence_curve] = GSA( ...
        LB, UB, Dim, SearchAgents_no, Max_iter, Cost_Function, Function_Number, costFunctionDetails)
    % GSA  Gravitational Search Algorithm (standalone)
    %
    % Inputs:
    %   LB, UB              – 1×Dim vectors of lower and upper bounds
    %   Dim                 – problem dimension
    %   SearchAgents_no     – number of agents
    %   Max_iter            – maximum number of iterations
    %   Cost_Function       – handle to objective function
    %   Function_Number     – extra parameter for Cost_Function
    %   costFunctionDetails – handle tag for dispatching cost calls
    %
    % Outputs:
    %   Best_Fitness        – best objective value found
    %   Best_Position       – 1×Dim best solution location
    %   Convergence_curve   – 1×Max_iter record of best fitness per iteration

    %% Algorithm parameters
    Rnorm        = 2;
    Rpower       = 1;
    ElitistCheck = 1;

    %% Initialization
    Positions         = initialization(SearchAgents_no, Dim, UB, LB);
    V                 = zeros(SearchAgents_no, Dim);
    fitnessAll        = inf(SearchAgents_no, 1);
    Convergence_curve = inf(1, Max_iter);
    Best_Fitness      = inf;
    Best_Position     = zeros(1, Dim);

    %% Main loop
    for t = 1:Max_iter
        % enforce bounds
        Positions = space_bound(Positions, LB, UB);

        % evaluate fitness
        for i = 1:SearchAgents_no
            fitnessAll(i) = evalCost(Positions(i,:), Cost_Function, Function_Number, costFunctionDetails);
        end

        % update global best
        [currentBest, idxBest] = min(fitnessAll);
        if currentBest < Best_Fitness
            Best_Fitness  = currentBest;
            Best_Position = Positions(idxBest, :);
        end
        Convergence_curve(t) = Best_Fitness;

        % compute masses
        M = massCalculation(fitnessAll, 1);

        % gravitational constant
        G = Gconstant(t, Max_iter);

        % compute accelerations
        a = Gfield(M, Positions, G, Rnorm, Rpower, ElitistCheck, t, Max_iter);

        % move agents
        [Positions, V] = moveAgents(Positions, a, V);
    end
end

%%----------------------------------------------------------------------%%
function f = evalCost(x, Cost_Function, Function_Number, costFunctionDetails)
    % dispatch cost evaluation
    name = func2str(costFunctionDetails);
    if strcmp(name, 'CEC_2005_Function') || strcmp(name, 'ProbInfo')
        f = Cost_Function(x);
    else
        f = Cost_Function(x', Function_Number);
    end
end

%%----------------------------------------------------------------------%%
function X = initialization(N, dim, UB, LB)
    % random initialization in [LB, UB]
    if isvector(UB)
        X = rand(N, dim) .* (UB - LB) + LB;
    else
        X = zeros(N, dim);
        for j = 1:dim
            X(:,j) = rand(N,1) * (UB(j) - LB(j)) + LB(j);
        end
    end
end

%%----------------------------------------------------------------------%%
function X = space_bound(X, LB, UB)
    % enforce lower and upper bounds
    X = min(max(X, LB), UB);
end

%%----------------------------------------------------------------------%%
function M = massCalculation(fit, min_flag)
    % compute normalized masses (minimization if min_flag==1)
    Fmax = max(fit);
    Fmin = min(fit);
    if Fmax == Fmin
        m = ones(size(fit));
    else
        if min_flag == 1
            best  = Fmin; worst = Fmax;
        else
            best  = Fmax; worst = Fmin;
        end
        m = (fit - worst) ./ (best - worst + eps);
    end
    M = m ./ sum(m);
end

%%----------------------------------------------------------------------%%
function G = Gconstant(iteration, max_it)
    % gravitational constant schedule
    alpha = 20;
    G0    = 100;
    G     = G0 * exp(-alpha * iteration / max_it);
end

%%----------------------------------------------------------------------%%
function a = Gfield(M, X, G, Rnorm, Rpower, ElitistCheck, iteration, max_it)
    % compute accelerations via gravitational interactions
    [N, dim] = size(X);
    final_per = 2; % percent of top agents
    if ElitistCheck == 1
        kbest = final_per + (1 - iteration/max_it) * (100 - final_per);
        kbest = round(N * kbest/100);
    else
        kbest = N;
    end
    [~, ds] = sort(M, 'descend');
    a = zeros(N, dim);
    for i = 1:N
        for ii = 1:kbest
            j = ds(ii);
            if j ~= i
                R = norm(X(i,:) - X(j,:), Rnorm)^Rpower + eps;
                for d = 1:dim
                    a(i,d) = a(i,d) + rand * M(j) * (X(j,d) - X(i,d)) / R;
                end
            end
        end
    end
    a = a * G;
end

%%----------------------------------------------------------------------%%
function [X, V] = moveAgents(X, a, V)
    % update velocities and positions
    [N, dim] = size(X);
    for i = 1:N
        V(i,:) = rand(1,dim).*V(i,:) + a(i,:);
        X(i,:) = X(i,:) + V(i,:);
    end
end
