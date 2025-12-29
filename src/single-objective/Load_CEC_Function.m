function [CostFunction, CostFunctionDetails, functionNo] = Load_CEC_Function(Index)
    %% This function return all informations we need about CEC

    % Address of CECs file
    addressFile = readlines('\Address.txt');
    address = fullfile(addressFile(Index));
    cd(address);

    % Load CostFunctions
    CostFunctions = readlines('\CostFunctions.txt');
    CostFunction = str2func(CostFunctions(Index));

    % Load CostFunctions informations like UperBound and etc
    CostFunctionsDetails = readlines('\CostFunctionsDetails.txt');
    CostFunctionDetails = str2func(CostFunctionsDetails(Index));

    % Load and set functionNumber for each CECs
    functionsNumber = readlines('\functionsNumber.txt');
    functionNo = str2double(functionsNumber(Index));

end
