function [bestScore, bestPos, curve] = MemoryCV_Optimizer(LB, UB, Dim, populationNo, maxItr, objective)

    if isscalar(LB), LB = repmat(LB, 1, Dim); end
    if isscalar(UB), UB = repmat(UB, 1, Dim); end

    epsVal = 1e-12;

    %% --- Initialization ---
    X = rand(populationNo, Dim) .* (UB - LB) + LB;
    fitness = zeros(populationNo, 1);

    meanX = X;                     % memory of positions (mean)
    meanF = zeros(populationNo, 1);% memory of fitness (mean)

    for i = 1:populationNo
        fitness(i) = objective(X(i, :)');
        meanF(i)   = fitness(i);
    end

    [bestScore, bestIdx] = min(fitness);
    bestPos = X(bestIdx, :);

    curve = zeros(maxItr, 1);

    %% --- Main Loop ---
    for it = 1:maxItr

        % best of CURRENT iteration (for freezing best member)
        [~, bestIdx] = min(fitness);

        for i = 1:populationNo

            % --- Update memory BEFORE moving (as you requested) ---
            meanX(i, :) = (meanX(i, :) + X(i, :)) / 2;
            meanF(i)    = (meanF(i)    + fitness(i)) / 2;

            % --- Best member does not move ---
            if i == bestIdx
                continue;
            end

            % --- Normalize among (bestScore, fitness(i), meanF(i)) فقط ---
            trio = [bestScore, fitness(i), meanF(i)];
            tMin = min(trio);
            tMax = max(trio);
            denom = (tMax - tMin) + epsVal;

            b_norm  = (bestScore  - tMin) / denom; %#ok<NASGU>  % usually 0 (minimization)
            f_norm  = (fitness(i) - tMin) / denom;
            mf_norm = (meanF(i)   - tMin) / denom;

            % --- Coefficient of Variation (0..1) ---
            CV = mf_norm / (f_norm + mf_norm + epsVal);

            % --- Generate new position (طبق ساختاری که گفتی) ---
            % موقعیت جدید از ترکیب:
            % (meanX * ضریب نرمال میانگین برازش) و (X * ضریب نرمال برازش فعلی)
            X_new = CV      * (mf_norm .* meanX(i, :)) + ...
                    (1-CV)  * (f_norm  .* X(i, :));

            % --- Boundary control ---
            X_new = max(min(X_new, UB), LB);

            % --- Evaluate new fitness ---
            f_new = objective(X_new');

            % --- Apply only if NEW is worse than mean fitness (minimization: bigger is worse) ---
            if f_new > meanF(i)
                X(i, :)     = X_new;
                fitness(i)  = f_new;
            end
            % در غیر این صورت هیچ تغییری روی X و fitness اعمال نمیشه
        end

        % --- Update global best ---
        [currentBest, idx] = min(fitness);
        if currentBest < bestScore
            bestScore = currentBest;
            bestPos   = X(idx, :);
        end

        curve(it) = bestScore;
    end
end
