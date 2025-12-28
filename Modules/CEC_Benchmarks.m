function [CostFunction, CostFunctionDetails, functionNo] = CEC_Benchmarks(Index)
    % This function returns all information we need about CEC benchmarks

    % Get the project root directory (one level above the script folder)
    scriptPath = mfilename('fullpath');
    moduleDir  = fileparts(scriptPath);
    projectDir = fileparts(moduleDir);

    % Read the relative paths of CEC benchmark folders from Address.txt
    addressFile = readlines("\Address.txt");
    relativeAddress = strtrim(addressFile(Index));
    address = fullfile(projectDir, relativeAddress);
    
    % Change the working directory to the selected CEC folder
    cd(address);

    % Load cost functions
    CostFunctions = readlines("\CostFunctions.txt");
    CostFunction = str2func(strtrim(CostFunctions(Index)));

    % Load cost function details (upper bound, lower bound, etc.)
    CostFunctionsDetails = readlines("\CostFunctionsDetails.txt");
    CostFunctionDetails = str2func(strtrim(CostFunctionsDetails(Index)));

    % Load and set the function number for the selected CEC benchmark
    functionsNumber = readlines("\functionsNumber.txt");
    functionNo = str2double(functionsNumber(Index));

end
