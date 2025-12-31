function y = RW_Evaluator(X, functionNo)
% RW_Evaluator(X, functionNo)
% X can be D×N (preferred, like CEC) or N×D (will be auto-fixed).
% Output y is 1×N (like typical CEC mex evaluators).

    % Get problem info
    [Dim, LB, ~, VioFactor, ~, Obj] = ProbInfo(functionNo); %#ok<ASGLU>
    Dim = double(Dim);

    % Normalize shape: accept vector, D×N, or N×D
    if isvector(X)
        X = X(:);  % make column
    end

    % If given N×D, transpose to D×N
    if size(X,1) ~= Dim && size(X,2) == Dim
        X = X.';
    end

    if size(X,1) ~= Dim
        error("RW_Evaluator:BadShape", ...
            "Expected X as D×N with D=%d (or N×D). Got %dx%d.", ...
            Dim, size(X,1), size(X,2));
    end

    % Convert to N×D because your RW Obj functions are written for rows (x(:,i), etc.)
    x = X.';  % N×D

    % CostFunction returns [z, Data], we only need z
    z = CostFunction(x, VioFactor, Obj);

    % Return row vector 1×N (CEC-like)
    y = z(:).';
end
