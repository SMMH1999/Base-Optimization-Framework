function [bestFitness, bestPosition, convergenceCurve] = ORCAS_4_1(lowerBound, upperBound, dimension, numAgents, maxIterations, costFunction, functionIndex, details)
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
    % پارامترها (قابل تنظیم)
    c0 = 0.50;   % مقدار اولیه
    cF = 0.10;   % مقدار نهایی

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

    %% Main Loop
    for it = 1:maxIterations

        % Spying orcas mean position
        spyGroup = pop(1:ns);
        meanPos  = mean(cat(1, spyGroup.Position), 1);

        newpop = repmat(struct('Position', [], 'Cost', []), nw, 1);

        t  = it / maxIterations;    % iter از 0 تا maxIterations
        % کاهش مربعی
        c = cF + (c0 - cF) * (1 - t)^2;

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
        pop = [pop; newpop];
        for i = 1:nPop
            [pop(i).Position, pop(i).Cost] = Opposite(lowerBound, upperBound, pop(i).Position, costFunction, functionIndex, details);
        end
        [~, sortIdx] = sort([pop.Cost]);
        pop = pop(sortIdx);

        % Keep nw best + add spying back
        pop = pop(1 : nw + ns);

        % Update best solution
        % BestSol = pop(ns+1);
        BestSol = pop(1);
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

function [Population, Fitness] = Opposite(LB, UB, Population, Cost_Function, Function_Number, costFunctionDetails)
    %% Make Opposition Population Based on Opposite Number Definition
    OppositePopulation = LB + UB - Population.* rand();
    OppositePopulation = min(max(OppositePopulation, LB), UB);

    %% Calculate Fitness for Population and OppositePopulation
    Population_Size = size(Population, 1);
    Fitness = zeros(1, Population_Size);
    OppositeFitness = zeros(1, Population_Size);


    % Calculate the objective function for each search agent
    if strcmp(func2str(costFunctionDetails), 'CEC_2005_Function') || strcmp(func2str(costFunctionDetails), 'ProbInfo')
        % For objective function 2005
        for i = 1 : Population_Size
            Fitness(i) = Cost_Function(Population(i, :));
            OppositeFitness(i) = Cost_Function(OppositePopulation(i, :));
        end
    elseif strcmp(func2str(costFunctionDetails), 'ProbInfo')
        for i = 1 : Population_Size
            Fitness(i) = Cost_Function(Population(i, :));
            OppositeFitness(i) = Cost_Function(OppositePopulation(i, :));
        end
    else
        % For after objective function 2005
        Fitness = Cost_Function(Population', Function_Number);
        OppositeFitness = Cost_Function(OppositePopulation', Function_Number);
    end

    % Change Population loop
    for i = 1:size(Population, 1)
        % Change solution i-th of Population with solution i-th of OppositePopulation
        % If OppositeFitness is better than Fitness i-th solution
        if OppositeFitness(i) < Fitness(i)
            Population(i, :) = OppositePopulation(i, :);
            Fitness(i) = OppositeFitness(i);
        end
    end
end