function [bestFitness, bestPosition, convergenceCcurve] = SBO(LB, UB, Dim, popSize, maxItr, Cost_Function, Function_Number, costFunctionDetails)
    % SBO  Satin Bowerbird Optimizer (Karthikeyan & Gandomi 2020)
    %   Standard‑signature rewrite preserving core functionality:
    %     • Attraction via probability‑weighted lambda (α)
    %     • Gaussian mutation (σ) with probability pMutation
    %     • Roulette‑wheel target selection
    %     • Elitist replacement & population sort
    % ----------------------------------------------------------------------

    %% ---------- Parameters ----------------------------------------------
    alpha      = 0.94;                       % greatest step size
    pMutation  = 0.05;                       % mutation probability
    Z          = 0.02;                       % σ ratio

    if isscalar(UB)
        UB = repmat(UB,1,Dim); LB = repmat(LB,1,Dim);
    end
    sigma = Z * (max(UB) - min(LB));         % Gaussian σ

    %% ---------- Initialization -----------------------------------------
    X   = popgen(popSize, Dim, LB, UB);
    fit = arrayfun(@(i) evalCost(X(i,:), Cost_Function, Function_Number, costFunctionDetails), 1:popSize);

    [bestFitness, idx] = min(fit);
    bestPosition       = X(idx,:);

    convergenceCcurve      = zeros(1,maxItr);
    convergenceCcurve(1)   = bestFitness;

    %% ---------- Main Loop ----------------------------------------------
    for t = 2:maxItr
        %% probability weights (higher fitness → lower weight)
        F = 1 ./ (1 + max(0,fit));           % transform fitness
        P = F ./ sum(F);

        %% generate new population
        Xnew  = X;   fitNew = zeros(1,popSize);
        for i = 1:popSize
            for d = 1:Dim
                j = rouletteSelect(P);
                lambda = alpha / (1 + P(j));
                Xnew(i,d) = X(i,d) + lambda * (((X(j,d)+bestPosition(d))/2) - X(i,d));
                % mutation
                if rand < pMutation
                    Xnew(i,d) = Xnew(i,d) + sigma * randn();
                end
            end
        end

        % clamp
        Xnew = max(min(Xnew, UB), LB);

        % evaluate
        fitNew = arrayfun(@(i) evalCost(Xnew(i,:), Cost_Function, Function_Number, costFunctionDetails), 1:popSize);

        %% combine and select top popSize
        X   = [X;   Xnew ];
        fit = [fit, fitNew];
        [fit, order] = sort(fit);
        X = X(order(1:popSize), :);
        fit = fit(1:popSize);

        %% update elite
        if fit(1) < bestFitness
            bestFitness  = fit(1);
            bestPosition = X(1,:);
        end

        convergenceCcurve(t) = min(convergenceCcurve(t-1), bestFitness);
    end
end

% ---------------------------------------------------------------------
function idx = rouletteSelect(P)
    % ROULETTESELECT  Choose index via roulette‑wheel.
    C = cumsum(P);
    idx = find(rand <= C, 1, 'first');
end

function X = popgen(n, d, LB_, UB_)
    X = LB_ + rand(n,d) .* (UB_ - LB_);
end
