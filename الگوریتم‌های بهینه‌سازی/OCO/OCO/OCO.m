function [bestFitness, bestPosition, convergenceCurve] = OCO(LB, UB, Dim, popSize, maxItr, Cost_Function, Function_Number, costFunctionDetails)
    % opposition_chemical_optimization implements an opposition-based local-search algorithm
    %
    % Inputs:
    %   LB                 - 1xDim lower bounds of the search space
    %   UB                 - 1xDim upper bounds of the search space
    %   Dim                - dimensionality of the problem
    %   popSize            - number of particles (population size)
    %   maxItr             - maximum number of iterations
    %   Cost_Function      - handle to the cost function
    %   Function_Number    - identifier for cost function (if needed)
    %   costFunctionDetails- additional details/function handle name
    %
    % Outputs:
    %   bestFitness        - best fitness value found
    %   bestPosition       - 1xDim position of the best solution
    %   convergenceCurve   - maxItrx1 vector of best fitness values per iteration

    % Initialize particles in the search space
    particles = rand(popSize, Dim) .* (UB - LB) + LB;

    % Evaluate initial best
    bestPosition = particles(1, :);
    bestFitness = evalCost(bestPosition, Cost_Function, Function_Number, costFunctionDetails);
    convergenceCurve = zeros(maxItr, 1);

    % Main optimization loop
    for iter = 1:maxItr
        % Local search on each particle
        for i = 1:popSize
            newPos = local_search_with_bounds(particles(i, :), LB, UB);
            particles(i, :) = newPos;
            fitness = evalCost(newPos, Cost_Function, Function_Number, costFunctionDetails);
            if fitness < bestFitness
                bestFitness = fitness;
                bestPosition = newPos;
            end
        end

        % Opposition-based learning phase
        oppParticles = UB + LB - particles;
        for i = 1:popSize
            newPos = local_search_with_bounds(oppParticles(i, :), LB, UB);
            fitness = evalCost(newPos, Cost_Function, Function_Number, costFunctionDetails);
            if fitness < bestFitness
                bestFitness = fitness;
                bestPosition = newPos;
            end
        end

        % Record convergence
        convergenceCurve(iter) = bestFitness;
    end
end

function f = evalCost(x, Cost_Function, Function_Number, costFunctionDetails)
    % evalCost evaluates the cost with the provided function signature
    name = func2str(costFunctionDetails);
    if strcmp(name, 'CEC_2005_Function') || strcmp(name, 'ProbInfo')
        f = Cost_Function(x);
    else
        f = Cost_Function(x', Function_Number);
    end
end

function new_position = local_search_with_bounds(current_position, LB, UB)
    % local_search_with_bounds perturbs a position and enforces bounds
    perturbation = randn(size(current_position)) * 0.1;
    new_position = current_position + perturbation;
    new_position = max(min(new_position, UB), LB);
end
