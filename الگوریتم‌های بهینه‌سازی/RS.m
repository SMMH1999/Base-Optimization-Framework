function [bestScore, bestPos, curve] = RS(LB, UB, Dim, populationNo, maxItr, objective)
% RS_TEST Random Search with mean-based filtering
% Only candidates worse than population mean are considered (for minimization)

    % Normalize bounds
    if isscalar(LB), LB = repmat(LB, 1, Dim); end
    if isscalar(UB), UB = repmat(UB, 1, Dim); end

    bestScore = inf;
    bestPos   = zeros(1, Dim);
    curve     = zeros(maxItr, 1);

    for it = 1:maxItr
        % Generate population
        X = rand(populationNo, Dim) .* (UB - LB) + LB;

        % Evaluate fitness of whole population
        fitness = zeros(populationNo, 1);
        for i = 1:populationNo
            fitness(i) = objective(X(i, :)');
        end

        % Mean fitness of population
        meanFitness = mean(fitness);

        % Process only worse-than-average individuals (minimization)
        for i = 1:populationNo
            if fitness(i) > meanFitness   % worse than mean
                if fitness(i) < bestScore
                    bestScore = fitness(i);
                    bestPos   = X(i, :);
                end
            end
        end

        curve(it) = bestScore;
    end
end
