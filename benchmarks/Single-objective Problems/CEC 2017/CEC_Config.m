function [CostFunction, CostFunctionDetails, functionNo] = CEC_Config()
% CEC_Config - Local configuration for this CEC suite.
% This file MUST live in the CEC folder itself (PWD == CEC folder).

    CostFunction        = @cec17_func;         % MEX / core evaluator
    CostFunctionDetails = @CEC_2017_Function;  % details / wrapper
    functionNo          = 30;                  % number of functions in this suite
end
