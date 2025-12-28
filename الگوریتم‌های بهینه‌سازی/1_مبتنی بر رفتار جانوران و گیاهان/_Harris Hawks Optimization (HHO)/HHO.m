function [bestFitness, bestPosition, convergenceCcurve] = HHO(LB, UB, Dim, popSize, maxItr, Cost_Function, Function_Number, costFunctionDetails)
    % HHO  Harris' Hawks Optimizer (standardised I/O, 2019 core intact)
    %   Rewritten to match unified signature and evalCost gateway.
    %   Core functionality (exploration/exploitation phases, energy-based
    %   transitions, Levy flight) remains identical to the reference code by
    %   Heidari et al. (2019) as hosted on MATLAB Central and the author's
    %   website. Only variable names, I/O, and defensive clamping have been
    %   adapted for consistency.

    %% ---------- Parameter Handling --------------------------------------
    if isscalar(UB)
        UB = repmat(UB, 1, Dim);
        LB = repmat(LB, 1, Dim);
    end

    %% ---------- Initialization -----------------------------------------
    X = popgen(popSize, Dim, LB, UB);   % hawk positions
    Rabbit_Energy   = inf;              % best fitness so far
    Rabbit_Location = zeros(1, Dim);    % best position

    convergenceCcurve = zeros(1, maxItr);
    convergenceCcurve(1) = Rabbit_Energy;

    %% ---------- Main Loop ----------------------------------------------
    for t = 1:maxItr
        % Fitness evaluation & rabbit update
        for i = 1:popSize
            X(i,:) = max(min(X(i,:), UB), LB);   % clamp
            fit_i  = evalCost(X(i,:), Cost_Function, Function_Number, costFunctionDetails);
            if fit_i < Rabbit_Energy
                Rabbit_Energy   = fit_i;
                Rabbit_Location = X(i,:);
            end
        end

        % Energy factor decreases from 2 to 0
        E1 = 2 * (1 - t / maxItr);

        % Position update for each hawk
        for i = 1:popSize
            E0 = 2*rand - 1;                 % (-1,1)
            E  = E1 * E0;                    % escaping energy

            if abs(E) >= 1   % ---------------- Exploration --------------
                q = rand;
                randIdx = randi(popSize);
                X_rand  = X(randIdx,:);
                if q < 0.5
                    X(i,:) = X_rand - rand .* abs(X_rand - 2*rand .* X(i,:));
                else
                    X(i,:) = (Rabbit_Location - mean(X,1)) - rand .* ((UB - LB).*rand + LB);
                end

            else             % ---------------- Exploitation --------------
                r  = rand;
                J  = 2*(1 - rand);           % jump strength

                if r >= 0.5 && abs(E) < 0.5  % Hard besiege
                    X(i,:) = Rabbit_Location - E .* abs(Rabbit_Location - X(i,:));

                elseif r >= 0.5 && abs(E) >= 0.5  % Soft besiege
                    X(i,:) = (Rabbit_Location - X(i,:)) - E .* abs(J .* Rabbit_Location - X(i,:));

                elseif r < 0.5 && abs(E) >= 0.5   % Soft besiege + rapid dives
                    X1 = Rabbit_Location - E .* abs(J .* Rabbit_Location - X(i,:));
                    X2 = X1 + rand(1,Dim) .* levy(Dim);
                    X1 = max(min(X1, UB), LB);
                    X2 = max(min(X2, UB), LB);
                    f  = evalCost(X(i,:), Cost_Function, Function_Number, costFunctionDetails);
                    f1 = evalCost(X1,      Cost_Function, Function_Number, costFunctionDetails);
                    f2 = evalCost(X2,      Cost_Function, Function_Number, costFunctionDetails);
                    if f1 < f, X(i,:) = X1; f = f1; end
                    if f2 < f, X(i,:) = X2; end

                else                           % Hard besiege + rapid dives
                    X1 = Rabbit_Location - E .* abs(J .* Rabbit_Location - mean(X,1));
                    X2 = X1 + rand(1,Dim) .* levy(Dim);
                    X1 = max(min(X1, UB), LB);
                    X2 = max(min(X2, UB), LB);
                    f  = evalCost(X(i,:), Cost_Function, Function_Number, costFunctionDetails);
                    f1 = evalCost(X1,      Cost_Function, Function_Number, costFunctionDetails);
                    f2 = evalCost(X2,      Cost_Function, Function_Number, costFunctionDetails);
                    if f1 < f, X(i,:) = X1; f = f1; end
                    if f2 < f, X(i,:) = X2; end
                end
            end
        end

        % Monotonic convergence curve
        convergenceCcurve(t) = min(convergenceCcurve(max(t-1,1)), Rabbit_Energy);
    end

    %% ---------- Outputs -------------------------------------------------
    bestFitness  = Rabbit_Energy;
    bestPosition = Rabbit_Location;
end

% ---------------------------------------------------------------------
function L = levy(d)
    % Stable Levy flight (beta = 1.5) identical to reference implementation.
    beta = 1.5;
    sigma = (gamma(1 + beta) * sin(pi * beta / 2) / (gamma((1 + beta) / 2) * beta * 2^((beta - 1) / 2)))^(1 / beta);
    u = randn(1, d) * sigma;
    v = randn(1, d);
    L = u ./ abs(v).^(1 / beta);
end


function X = popgen(n, d, LB_, UB_)
    % POPGEN  Generate n random vectors inside [LB_, UB_].
    X = LB_ + rand(n, d) .* (UB_ - LB_);
end
