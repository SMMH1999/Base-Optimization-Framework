function [CostFunction, CostFunctionDetails, functionNo] = CECRW_Benchmarks(Index)
%% This function return all informations we need about CEC

% Address of CECs file
addressFile = readlines("C:\Users\pc\Desktop\کد نویسی و برنامه‌ها\پیش نیازها\RWP\RW_Address.txt");
address = addressFile(Index);
cd(address);

% Load CostFunctions
CostFunctions = readlines("C:\Users\pc\Desktop\کد نویسی و برنامه‌ها\پیش نیازها\RWP\RW_CostFunctions.txt");
CostFunction = str2func(CostFunctions(Index));

% Load CostFunctions informations like UperBound and etc
CostFunctionsDetails = readlines("C:\Users\pc\Desktop\کد نویسی و برنامه‌ها\پیش نیازها\RWP\RW_CostFunctionsDetails.txt");
CostFunctionDetails = str2func(CostFunctionsDetails(Index));

% Load and set functionNumber for each CECs
functionsNumber = readlines("C:\Users\pc\Desktop\کد نویسی و برنامه‌ها\پیش نیازها\RWP\RW_FunctionsNumber.txt");
functionNo = str2double(functionsNumber(Index));

end