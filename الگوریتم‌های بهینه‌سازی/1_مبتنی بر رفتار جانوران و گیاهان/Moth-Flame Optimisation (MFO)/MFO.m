%===============================================================================
% Moth-Flame Optimization (MFO) Algorithm - Fixed Version
%===============================================================================
% This version has been updated to:
% 1) Preserve best flames from previous iterations.
% 2) Update moths beyond flameNo relative to the last flame.
% 3) Ensure non-increasing convergence curve.
%-------------------------------------------------------------------------------
function [bestFitness, bestPosition, convergenceCurve] = MFO( ...
        LB, UB, Dim, popSize, maxItr, ...
        Cost_Function, Function_Number, costFunctionDetails)

    % 1) Initialize moth positions randomly within bounds
    mothPos = initialization(popSize, Dim, UB, LB);

    % Evaluate initial fitness for all moths
    mothFit = arrayfun(@(r) evalCost(mothPos(r,:), ...
        Cost_Function, Function_Number, costFunctionDetails), ...
        (1:popSize).').';

    % Preallocate convergence curve
    convergenceCurve = inf(maxItr,1);

    % Initialize best flames positions and fitness
    bestFlamesPos = mothPos;
    bestFlamesFit = mothFit;

    % 2) Main optimization loop
    for itr = 1:maxItr

        % Sort current moths by fitness
        [mothFitSorted, idx] = sort(mothFit);
        mothPosSorted        = mothPos(idx,:);

        % Calculate the number of flames (Eq. 3.14)
        flameNo  = round(popSize - itr*((popSize-1)/maxItr));

        % Combine current population with previous best flames
        combinedPos = [mothPos; bestFlamesPos];
        combinedFit = [mothFit; bestFlamesFit];

        % Sort combined population
        [combinedFitSorted, idxCombined] = sort(combinedFit);
        combinedPosSorted = combinedPos(idxCombined,:);

        % Update best flames for this iteration
        bestFlamesPos = combinedPosSorted(1:popSize,:);
        bestFlamesFit = combinedFitSorted(1:popSize);

        % Record current best solution
        bestFitness  = bestFlamesFit(1);
        bestPosition = bestFlamesPos(1,:);

        % Linearly decreasing parameter a from -1 to -2
        a = -1 + itr*(-1/maxItr);

        % Update moth positions
        for i = 1:popSize
            for d = 1:Dim

                % Determine flame index to follow
                if i <= flameNo
                    flameIdx = i;          % follow corresponding flame
                else
                    flameIdx = flameNo;   % follow last flame
                end

                % Calculate distance to flame
                dist = abs(bestFlamesPos(flameIdx,d) - mothPos(i,d));
                t    = (a-1)*rand + 1;  % spiral factor

                % Update position using spiral equation
                mothPos(i,d) = dist * exp(t) * cos(2*pi*t) + bestFlamesPos(flameIdx,d);
            end
        end

        % Keep moths within search bounds
        mothPos = max(min(mothPos, UB), LB);

        % Re-evaluate fitness for updated positions
        mothFit = arrayfun(@(r) evalCost(mothPos(r,:), ...
            Cost_Function, Function_Number, costFunctionDetails), ...
            (1:popSize).').';

        % Update convergence curve (non-increasing)
        if itr == 1
            convergenceCurve(itr) = bestFitness;
        else
            convergenceCurve(itr) = min(convergenceCurve(itr-1), bestFitness);
        end
    end

    % Ensure global non-increasing convergence curve (safety measure)
    convergenceCurve = cummin(convergenceCurve);
end

%-------------------------------------------------------------------------------
% Initialization function: generate random positions within bounds
function X = initialization(nAgents, dim, ub, lb)
    if isscalar(ub) && isscalar(lb)
        X = rand(nAgents, dim).*(ub-lb) + lb;
    else
        X = zeros(nAgents, dim);
        for d = 1:dim
            X(:,d) = rand(nAgents,1).*(ub(d)-lb(d)) + lb(d);
        end
    end
end

%-------------------------------------------------------------------------------
% Unified cost function evaluation
function f = evalCost(x, Cost_Function, Function_Number, costFunctionDetails)
    name = func2str(costFunctionDetails);
    if strcmp(name,'CEC_2005_Function') || strcmp(name,'ProbInfo')
        f = Cost_Function(x);
    else
        f = Cost_Function(x', Function_Number);
    end
end
