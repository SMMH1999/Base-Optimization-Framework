function [CostFunction, CostFunctionDetails, functionNo] = CEC_Config()
% RW suite adapter to match the CEC interface expected by Load_CEC_Function/RunBenchmarkSuite.

    CostFunction        = @RW_Evaluator;  % must be: y = f(X, funcNo)
    CostFunctionDetails = @RW_Function;   % must be: [LB, UB, Dim] = details(funcNo)
    functionNo          = 13;             % number of RW problems
end
