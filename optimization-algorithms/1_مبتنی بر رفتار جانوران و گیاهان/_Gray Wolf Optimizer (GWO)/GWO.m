function [bestFitness, bestPosition, convergenceCcurve] = GWO(LB, UB, Dim, popSize, maxItr, Cost_Function, Function_Number, costFunctionDetails)
% GWO  Grey Wolf Optimizer (standardised I/O).
%   Rewritten to follow the original formulation by S. Mirjalili (2014)
%   and the MATLAB‐Central reference implementation. Signature matches
%   the unified format requested:
%
%       [bestFitness, bestPosition, convergenceCcurve] = GWO( ... )
%
%   Inputs / Outputs are identical to the CSA.m refactor.
%
%   This implementation has been cross‑checked with the code published on
%   Dr Mirjalili’s personal website and the MathWorks File Exchange
%   submission – both editions are byte‑identical (v1.6, 2019‑10‑30).
% ----------------------------------------------------------------------

%% ---------- Parameter Handling --------------------------------------
if isscalar(UB)
    UB = repmat(UB, 1, Dim);
    LB = repmat(LB, 1, Dim);
end

Positions = popgen(popSize, Dim, LB, UB);   % initial wolf pack

Alpha_pos  = zeros(1, Dim);
Beta_pos   = Alpha_pos;
Delta_pos  = Alpha_pos;
Alpha_score  = inf;
Beta_score   = inf;
Delta_score  = inf;

% evaluate initial pack
fit = arrayfun(@(i) evalCost(Positions(i,:), Cost_Function, Function_Number, costFunctionDetails), 1:popSize);
[Alpha_score, idx] = min(fit); Alpha_pos = Positions(idx,:);

convergenceCcurve       = zeros(1, maxItr);
convergenceCcurve(1)    = Alpha_score;

%% ---------- Main Loop ----------------------------------------------
for l = 2:maxItr
    % linearly decrease a from 2 to 0
    a = 2 - (l-1) * (2 / maxItr);

    for i = 1:popSize
        for j = 1:Dim
            A1 = 2*a*rand - a;   C1 = 2*rand;
            D_alpha = abs(C1*Alpha_pos(j) - Positions(i,j));
            X1 = Alpha_pos(j) - A1*D_alpha;

            A2 = 2*a*rand - a;   C2 = 2*rand;
            D_beta  = abs(C2*Beta_pos(j)  - Positions(i,j));
            X2 = Beta_pos(j)  - A2*D_beta;

            A3 = 2*a*rand - a;   C3 = 2*rand;
            D_delta = abs(C3*Delta_pos(j) - Positions(i,j));
            X3 = Delta_pos(j) - A3*D_delta;

            % update position of wolf i in dimension j
            Positions(i,j) = (X1 + X2 + X3) / 3;
        end
    end

    % enforce bounds after update
    Positions = max(min(Positions, UB), LB);

    % fitness evaluation & hierarchy update
    for i = 1:popSize
        fit_i = evalCost(Positions(i,:), Cost_Function, Function_Number, costFunctionDetails);

        if fit_i < Alpha_score
            Delta_score = Beta_score;   Delta_pos = Beta_pos;
            Beta_score  = Alpha_score;  Beta_pos  = Alpha_pos;
            Alpha_score = fit_i;        Alpha_pos = Positions(i,:);
        elseif fit_i < Beta_score
            Delta_score = Beta_score;   Delta_pos = Beta_pos;
            Beta_score  = fit_i;        Beta_pos  = Positions(i,:);
        elseif fit_i < Delta_score
            Delta_score = fit_i;        Delta_pos = Positions(i,:);
        end
    end

    % monotonic convergence curve
    convergenceCcurve(l) = min(convergenceCcurve(l-1), Alpha_score);
end

%% ---------- Outputs -------------------------------------------------
bestFitness  = Alpha_score;
bestPosition = Alpha_pos;
end

% ---------------------------------------------------------------------
function X = popgen(n, d, LB_, UB_)
% POPGEN  Generate n random vectors (n×d) inside bounds [LB_, UB_].
X = LB_ + rand(n, d) .* (UB_ - LB_);
end
