function [bestFitness, bestPosition, convergenceCurve] = ORCAS(lowerBound, upperBound, dimension, numAgents, maxIterations, costFunction, functionIndex, details)
    % ORCAS Metaheuristic Optimization Algorithm
    % Inspired by the cooperative hunting behavior of orcas.
    %
    % INPUTS:
    %   lowerBound    - Lower bound of the search space
    %   upperBound    - Upper bound of the search space
    %   dimension     - Number of decision variables
    %   numAgents     - Number of orcas (population size)
    %   maxIterations - Maximum number of iterations
    %   costFunction  - Objective (fitness) function
    %   functionIndex - Function index (for benchmark functions)
    %   details       - Extra information for benchmark functions
    %
    % OUTPUTS:
    %   bestFitness       - Best fitness value found
    %   bestPosition      - Best solution vector found
    %   convergenceCurve  - Convergence history of the algorithm

    %% Parameters
    MaxIt = maxIterations;      % Maximum iterations
    nPop = numAgents;           % Population size (orcas)
    VarMin = lowerBound;        % Lower bound
    VarMax = upperBound;        % Upper bound
    VarSize = dimension;        % Problem dimensionality

    nw = 20;   % Number of orcas making waves
    ns = 10;   % Number of orcas spying
    c = 0.18;  % Control parameter for exploration

    %% Initialization
    % Empty orca structure
    orca.Position = [];
    orca.Cost = [];

    % Initialize population
    pop = repmat(orca, nPop, 1);
    for i = 1:nPop
        pop(i).Position = popgen(1, VarSize, VarMin, VarMax);
        pop(i).Cost = evalCost(pop(i).Position(1, :), costFunction, functionIndex, details);
    end

    % Sort population by fitness
    [~, SortOrder] = sort([pop.Cost]);
    pop = pop(SortOrder);

    % Best solution found so far
    BestSol = pop(1);

    % Convergence curve
    BestCost = zeros(MaxIt, 1);

    % Compute initial mean of spying orcas
    firstpop = pop(1:ns);
    meanPos = mean(cat(1, firstpop.Position), 1);

    %% Main Loop
    for it = 1:MaxIt
        % Orcas create waves
        for i = 1:nw
            d = norm(pop(i+ns).Position - meanPos);       % Distance from mean position
            e = c * unifrnd(-1, +1);                     % Random exploration factor
            dd = abs((rand * d) + 0.01 / (d + 0.01));    % Wave effect

            % Update position
            newpop(i).Position = pop(i+ns).Position .* dd + e;
            newpop(i).Position = max(newpop(i).Position, VarMin);
            newpop(i).Position = min(newpop(i).Position, VarMax);

            % Evaluate new solution
            newpop(i).Cost = evalCost(newpop(i).Position, costFunction, functionIndex, details);
        end

        % Merge and sort population
        pop = [pop(ns+1:nPop); newpop'];
        [~, SortOrder] = sort([pop.Cost]);
        pop = pop(SortOrder);
        pop = pop(1:nw);

        % Add spying orcas back
        pop = [firstpop; pop]; %#ok

        % Update best solution
        BestSol = pop(ns+1);

        % Store best cost
        BestCost(it) = BestSol.Cost;

    end

    %% Results
    bestFitness = BestSol.Cost;
    bestPosition = BestSol.Position;
    convergenceCurve = BestCost;
end

function X = popgen(n, d, LB_, UB_)
% POPGEN  Generate n random vectors (n×d) inside bounds [LB_, UB_].
X = LB_ + rand(n, d) .* (UB_ - LB_);
end

%% Cost Evaluation Function
function f = evalCost(x, costFunction, functionIndex, details)
    % Evaluate the cost function depending on benchmark type
    name = func2str(details);
    if strcmp(name, 'CEC_2005_Function') || strcmp(name, 'ProbInfo')
        f = costFunction(x);
    else
        f = costFunction(x', functionIndex);
    end
end
