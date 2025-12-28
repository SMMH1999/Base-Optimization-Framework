function [Best_Fitness, Best_Position, Convergence_curve] = GSABBO(LB, UB, Dim, SearchAgents_no, Max_iter, Cost_Function, Function_Number, costFunctionDetails)
    % Improved GSA (with BBO-based enhancements) - signature remains unchanged

    %% Algorithm parameters
    Rnorm        = 2;
    Rpower       = 1;
    ElitistCheck = 1;

    %% BBO-related parameters
    k   = 1;
    I   = 0.9;
    E1  = 2;
    Pos = 0.5;
    Siv = 0.7;
    n   = 5;

    %% Initialization
    Positions         = Population_Generator(SearchAgents_no, Dim, UB, LB);
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

        % NEW: apply BBO-based new fitness calculation
        Nfit = newFitness(M, I, E1, k, Siv, Pos, n); %#ok<NASGU>

        % gravitational constant
        G = Gconstant(t, Max_iter);

        % compute accelerations
        a = Gfield(M, Positions, G, Rnorm, Rpower, ElitistCheck, t, Max_iter);

        % NEW: expand search space using BBO strategy
        a = gSearchspace(a, I, E1, k, n);

        % move agents
        [Positions, V] = move(Positions, a, V);
    end
end

%%----------------------------------------------------------------------%%
function f = evalCost(x, Cost_Function, Function_Number, costFunctionDetails)
    % Evaluate cost with correct signature
    name = func2str(costFunctionDetails);
    if strcmp(name,'CEC_2005_Function') || strcmp(name,'ProbInfo')
        f = Cost_Function(x);
    else
        f = Cost_Function(x', Function_Number);
    end
end
