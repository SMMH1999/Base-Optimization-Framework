function [CostFunction, CostFunctionDetails, functionNo] = CEC_Config()
% CEC_Config - Local configuration for this CEC suite.
% This file MUST live in the CEC folder itself (PWD == CEC folder).

    CostFunction        = @cec14_func;         % MEX / core evaluator
    CostFunctionDetails = @CEC_2014_Function;  % details / wrapper
    functionNo          = 30;                  % number of functions in this suite
end
