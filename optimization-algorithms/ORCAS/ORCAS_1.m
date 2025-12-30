function [bestFitness, bestPosition, convergenceCurve] = ORCAS_1(lowerBound, upperBound, dimension, numAgents, maxIterations, costFunction, functionIndex, details)
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
    % numAgents = 50;
    nPop = numAgents;
    VarMin = lowerBound;
    VarMax = upperBound;
    VarSize = dimension;

    nw = 20;   % Orcas making waves
    ns = 10;   % Orcas spying
    c  = 0.18; % Exploration control parameter

    %% Initialization
    pop = struct('Position', [], 'Cost', []);
    pop = repmat(pop, nPop, 1);

    for i = 1:nPop
        pop(i).Position = Population_Generator(1, dimension, upperBound, lowerBound);
        pop(i).Cost     = evalCost(pop(i).Position, costFunction, functionIndex, details);
    end

    % Sort population
    [~, sortIdx] = sort([pop.Cost]);
    pop = pop(sortIdx);

    % Best solution so far
    BestSol = pop(1);
    BestCost = zeros(maxIterations, 1);

    % Spying orcas mean position
    spyGroup = pop(1:ns);
    meanPos  = mean(cat(1, spyGroup.Position), 1);

    %% Main Loop
    for it = 1:maxIterations
        newpop = repmat(struct('Position', [], 'Cost', []), nw, 1);

        % Orcas create waves (exploration)
        for i = 1:nw
            d  = norm(pop(i+ns).Position - meanPos);
            e  = c * unifrnd(-1, +1);
            dd = abs((rand * d) + 0.01 / (d + 0.01));

            % Update position
            newpos = pop(i+ns).Position .* dd + e;

            % Bound handling
            newpos = max(newpos, VarMin);
            newpos = min(newpos, VarMax);

            % Evaluate
            newpop(i).Position = newpos;
            newpop(i).Cost     = evalCost(newpos, costFunction, functionIndex, details);
        end

        % Merge and select
        pop = [pop(ns+1:end); newpop];
        [~, sortIdx] = sort([pop.Cost]);
        pop = pop(sortIdx);

        % Keep nw best + add spying back
        pop = [spyGroup; pop(1:nw)];

        % Update best solution
        BestSol = pop(ns+1);
        BestCost(it) = BestSol.Cost;

        %% TODO: Adaptive control of parameter c (e.g. decrease over iterations)
        %% TODO: Use best individual instead of meanPos for stronger exploitation
        %% TODO: Mutation/diversification to prevent premature convergence
        %% TODO: Try dynamic ns and nw values (more exploration early, more exploitation later)
        %% TODO: Hybridize with local search (e.g. Nelder–Mead or DE step here)
    end

    %% Results
    bestFitness      = BestSol.Cost;
    bestPosition     = BestSol.Position;
    convergenceCurve = BestCost;
end

%% Cost Evaluation Function
function f = evalCost(x, costFunction, functionIndex, details)
    name = func2str(details);
    if strcmp(name, 'CEC_2005_Function') || strcmp(name, 'ProbInfo')
        f = costFunction(x);
    else
        f = costFunction(x', functionIndex);
    end
end

function Population = Population_Generator(SearchAgents_no, Dim, UB, LB)
    %% Initialize the positions of search agents

    %% Single Objective Bound
    if size(UB, 2) == 1
        Population = rand(SearchAgents_no, Dim) .* (UB - LB) + LB;
    end

    %% Multiple Objective Bound
    if size(UB, 2) > 1
        for i = 1 : Dim
            UB_i = UB(i);
            LB_i = LB(i);
            Population(:, i) = rand(SearchAgents_no, 1) .* (UB_i - LB_i) + LB_i;
        end
    end
end