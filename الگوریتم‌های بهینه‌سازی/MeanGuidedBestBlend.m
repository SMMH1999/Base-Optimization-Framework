function [bestScore, bestPos, curve] = MeanGuidedBestBlend(LB, UB, Dim, popNo, maxItr, obj)
% MeanGuidedBestBlend
% A population-based minimization algorithm based on:
% - per-agent running means of positions and fitness
% - two-stage adaptive blending toward mean and toward (local/global) bests
%
% Inputs:
%   LB, UB : bounds (scalar or 1xDim)
%   Dim    : problem dimension
%   popNo  : population size
%   maxItr : iterations
%   obj    : objective function handle (expects a candidate; wrapper in suite handles shape)
%
% Outputs:
%   bestScore : global best fitness found
%   bestPos   : global best position found
%   curve     : convergence curve (bestScore per iteration)

    % ---- Bounds normalize to 1xDim
    LB = reshapeBound(LB, Dim);
    UB = reshapeBound(UB, Dim);

    % ---- Initialize population uniformly
    X = rand(popNo, Dim) .* (UB - LB) + LB;

    % ---- Evaluate initial fitness
    F = zeros(popNo, 1);
    for i = 1:popNo
        F(i) = obj(X(i, :).');
    end

    % ---- Running means init (each agent has seen exactly 1 sample)
    meanX = X;          % mean_x_i
    meanF = F;          % mean_f_i
    count = ones(popNo, 1);

    % ---- Bests init: local == global at start (per your note)
    [f_b_g, idxg] = min(F);
    x_b_g = X(idxg, :);

    x_b_l = x_b_g;
    f_b_l = f_b_g;

    curve = zeros(maxItr, 1);

    % ---- Hyper (you can tune)
    alpha = 0.5;    % blend between stage1 and stage2 positions

    for t = 1:maxItr

        % ---- Local best of current iteration (based on current population BEFORE moving)
        [f_b_l, idxl] = min(F);
        x_b_l = X(idxl, :);

        for i = 1:popNo

            xi = X(i, :);
            fi = F(i);

            % =========================
            % Stage 1: blend xi vs meanX(i,:)
            % Normalize fi between f_b_l and meanF(i)  --> w1 in [0,1]
            % =========================
            denom1 = (meanF(i) - f_b_l);
            if abs(denom1) < 1e-12
                w1 = 0; % if meanF == best_local, keep xi (avoid instability)
            else
                w1 = (fi - f_b_l) / denom1;
                w1 = clamp01(w1);
            end

            x1 = (1 - w1) * xi + w1 * meanX(i, :);

            % Bound handling
            x1 = min(max(x1, LB), UB);

            f1 = obj(x1.');  % fitness of x1

            % =========================
            % Stage 2: follow local/global bests
            % Normalize f1 between f_b_g and f_b_l --> w2 in [0,1]
            % w2 نزدیک 0  => نزدیک global best => بیشتر سمت x_b_g
            % w2 نزدیک 1  => نزدیک local  best => بیشتر سمت x_b_l
            % =========================
            denom2 = (f_b_l - f_b_g);
            if abs(denom2) < 1e-12
                w2 = 0.5; % local and global equal
            else
                w2 = (f1 - f_b_g) / denom2;
                w2 = clamp01(w2);
            end

            x2 = w2 * x_b_l + (1 - w2) * x_b_g;

            % Final blend (keeps some memory/mean influence)
            xNew = alpha * x1 + (1 - alpha) * x2;

            % Bound handling
            xNew = min(max(xNew, LB), UB);

            fNew = obj(xNew.');

            % Accept (greedy) — you can change to always-replace if you want
            if fNew <= fi
                X(i, :) = xNew;
                F(i) = fNew;
                xi = xNew;
                fi = fNew;
            end

            % ---- Update running means with the FINAL stored state (xi, fi)
            count(i) = count(i) + 1;
            c = count(i);

            meanX(i, :) = meanX(i, :) + (xi - meanX(i, :)) / c;
            meanF(i)    = meanF(i)    + (fi - meanF(i))    / c;

        end

        % ---- Update global best
        [curBest, idx] = min(F);
        if curBest < f_b_g
            f_b_g = curBest;
            x_b_g = X(idx, :);
        end

        curve(t) = f_b_g;
    end

    bestScore = f_b_g;
    bestPos   = x_b_g(:); % column vector (often expected)
end

% ========================= Helper functions =========================

function b = reshapeBound(B, Dim)
    if isscalar(B)
        b = repmat(double(B), 1, Dim);
    else
        B = double(B(:).');
        if numel(B) ~= Dim
            error('Bound size mismatch: expected %d, got %d.', Dim, numel(B));
        end
        b = B;
    end
end

function y = clamp01(x)
    y = min(max(x, 0), 1);
end
