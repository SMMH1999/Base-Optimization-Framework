function [bestFitness, bestPosition, convergenceCcurve] = PSO_CEC(LB, UB, Dim, popSize, maxItr, Cost_Function, Function_Number, costFunctionDetails)
    % PSO_CEC  Particle Swarm Optimization baseline used in CEC‑PSO (2013–2020)
    %   Implements inertia‐weight schedule, velocity clamping, and 25‑% random
    %   relocation strategy identical to the canonical "PSO_func" distributed
    %   with CEC benchmarks, while conforming to the unified signature.
    % ----------------------------------------------------------------------

    %% ---------- Parameter / Bounds prep --------------------------------
    if isscalar(UB)
        UB = repmat(UB, 1, Dim);
        LB = repmat(LB, 1, Dim);
    end

    UBM = UB;  LBM = LB;                 % matrices for vector ops
    range = UBM - LBM;

    % inertia weight linearly decreasing 0.9 → 0.4
    wSchedule = linspace(0.9, 0.4, maxItr);

    c1 = 2.0;   c2 = 2.0;                % acceleration constants

    %% ---------- Velocity limits per CEC rule ---------------------------
    Vmax = 0.5 .* range;                 % upper bound of velocity
    Vmin = -Vmax;

    %% ---------- Initialization -----------------------------------------
    X = popgen(popSize, Dim, LB, UB);    % positions
    V = Vmin + (Vmax - Vmin) .* rand(popSize, Dim);   % random velocities

    fit = arrayfun(@(i) evalCost(X(i,:), Cost_Function, Function_Number, costFunctionDetails), 1:popSize);
    pBestPos = X;                        % personal bests
    pBestFit = fit;
    [bestFitness, idx] = min(fit);       % global best
    bestPosition = X(idx,:);

    convergenceCcurve       = zeros(1, maxItr);
    convergenceCcurve(1)    = bestFitness;

    %% ---------- Main Loop ---------------------------------------------
    for t = 2:maxItr
        w = wSchedule(t);

        % velocity update (vectorised)
        r1 = rand(popSize, Dim);
        r2 = rand(popSize, Dim);
        V = w .* V + c1 .* r1 .* (pBestPos - X) + c2 .* r2 .* (bestPosition - X);

        % velocity clamping
        V = min(max(V, Vmin), Vmax);

        % position update
        X = X + V;

        % random relocation strategy when out‑of‑bounds (25% band)
        LBmat   = repmat(LB , popSize, 1);   %  popSize × Dim
        UBmat   = repmat(UB , popSize, 1);
        rangeMat= UBmat - LBmat;

        lowMask  = X < LBmat;
        highMask = X > UBmat;

        % 25% رندُم داخل نوار
        X(lowMask)  = LBmat(lowMask)  + 0.25 .* rangeMat(lowMask)  .* rand(nnz(lowMask ),1);
        X(highMask) = UBmat(highMask) - 0.25 .* rangeMat(highMask) .* rand(nnz(highMask),1);

        % fitness evaluation
        fit = arrayfun(@(i) evalCost(X(i,:), Cost_Function, Function_Number, costFunctionDetails), 1:popSize);

        % personal best update
        improved = fit < pBestFit;
        pBestFit(improved)    = fit(improved);
        pBestPos(improved,:)  = X(improved,:);

        % global best update
        [currentBest, idx] = min(pBestFit);
        if currentBest < bestFitness
            bestFitness  = currentBest;
            bestPosition = pBestPos(idx,:);
        end

        % monotonic convergence curve
        convergenceCcurve(t) = min(convergenceCcurve(t-1), bestFitness);
    end
end

% ---------------------------------------------------------------------
function X = popgen(n, d, LB_, UB_)
    % POPGEN  Generate n random vectors inside bounds [LB_, UB_].
    X = LB_ + rand(n, d) .* (UB_ - LB_);
end
