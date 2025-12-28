function f = evalCost(x, Cost_Function, Function_Number, costFunctionDetails)
    % evalCost  Unified gateway for all benchmark and custom cost functions.
    %   This wrapper guarantees every algorithm can call **one** function
    %   regardless of whether the benchmark expects a row‑vector, column‑vector
    %   or additional index.
    %
    %   INPUTS
    %       x                – 1×Dim or Dim×1 decision vector (row or column)
    %       Cost_Function    – function handle to the benchmark (e.g. @CEC_2005_Function)
    %       Function_Number  – scalar index for multifunc benchmarks (ignored if not needed)
    %       costFunctionDetails – same handle used for identification (pass the
    %                             same Cost_Function or annotation struct)
    %
    %   OUTPUT
    %       f  – scalar fitness value
    % ----------------------------------------------------------------------
    % Ensure x is row for row‑based CEC functions and column otherwise.
    name = func2str(costFunctionDetails);

    switch name
        case {'CEC_2005_Function','ProbInfo'}
            % These implementations expect a **row vector** input.
            if size(x,1) > 1, x = x'; end
            f = Cost_Function(x);
        otherwise
            % Generic case: many recent CEC functions expect column vector and index.
            if size(x,2) > 1, x = x'; end
            f = Cost_Function(x, Function_Number);
    end
end
