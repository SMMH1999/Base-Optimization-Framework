function [bestFitness, bestPosition, convergenceCcurve] = CSA(LB, UB, Dim, popSize, maxItr, Cost_Function, Function_Number, costFunctionDetails)
    % CSA  Crow Search Algorithm (rewritten with standard signature).
    %   This implementation follows the original formulation by A. Askarzadeh
    %   (2016) and conforms to the I/O convention you specified.
    %
    %   Inputs:
    %       LB, UB            - Lower/upper bounds (scalar or 1×Dim).
    %       Dim               - Problem dimension.
    %       popSize           - Number of crows (population size).
    %       maxItr            - Maximum number of iterations.
    %       Cost_Function     - Handle to cost function (CEC or custom).
    %       Function_Number   - Index of the CEC test function (if used).
    %       costFunctionDetails - Additional details for evalCost.
    %
    %   Outputs:
    %       bestFitness       - Best objective value found.
    %       bestPosition      - Decision vector of bestFitness.
    %       convergenceCcurve - Monotonic non‑increasing bestFitness over iterations.
    %
    %   Example call:
    %       [bf,bp,curv] = CSA(-100,100,30,30,500,@CEC_2005_Function,1,@CEC_2005_Function);
    %
    %   --------------------------------------------------------------------

    %% ---------- Parameter Handling --------------------------------------
    if isscalar(UB)
        UB = repmat(UB, 1, Dim);
        LB = repmat(LB, 1, Dim);
    end

    AP = 0.1;     % Awareness Probability
    FL = 2;       % Flight Length (constant here but can be adapted)

    %% ---------- Initialization -----------------------------------------
    X  = popgen(popSize, Dim, LB, UB);        % current positions
    M  = X;                                   % memory of each crow
    fit = arrayfun(@(i) evalCost(X(i,:), Cost_Function, Function_Number, costFunctionDetails), 1:popSize);

    [globalBest, gIdx] = min(fit);
    GbestPos = X(gIdx,:);

    convergenceCcurve = zeros(1, maxItr);
    convergenceCcurve(1) = globalBest;

    %% ---------- Main Loop ----------------------------------------------
    for t = 2:maxItr
        % select a crow to follow for each individual
        followIdx = randi(popSize, popSize, 1);
        randMask  = rand(popSize, 1) < AP;   % TRUE -> random location (scout)

        % flight step
        R = rand(popSize, Dim);
        Xnew = X + FL .* R .* (M(followIdx,:) - X);

        % replacement with random positions where mask is true
        randPos = popgen(sum(randMask), Dim, LB, UB);
        Xnew(randMask,:) = randPos;

        % apply bounds
        Xnew = max(min(Xnew, UB), LB);

        % evaluate new positions
        fitNew = arrayfun(@(i) evalCost(Xnew(i,:), Cost_Function, Function_Number, costFunctionDetails), 1:popSize);

        % update memory where improvement occurs
        improved = fitNew < fit;
        M(improved,:) = Xnew(improved,:);
        fit(improved) = fitNew(improved);

        % update global best
        [currentBest, gIdx] = min(fit);
        if currentBest < globalBest
            globalBest = currentBest;
            GbestPos   = X(gIdx,:);
        end

        % enforce monotonic non‑increasing convergence curve
        convergenceCcurve(t) = min(convergenceCcurve(t-1), globalBest);

        % move current population to new positions (exploration step)
        X = Xnew;
    end

    %% ---------- Outputs -------------------------------------------------
    bestFitness      = globalBest;
    bestPosition     = GbestPos;
    % convergenceCcurve already filled
end

% ---------------------------------------------------------------------
function X = popgen(n, d, LB_, UB_)
    % POPGEN  Generate n random vectors of dimension d within [LB_, UB_].
    X = LB_ + rand(n, d) .* (UB_ - LB_);
end
