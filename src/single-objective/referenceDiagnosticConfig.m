function config=referenceDiagnosticConfig(action,value)
%REFERENCEDIAGNOSTICCONFIG Store and retrieve reference diagnostic settings.

persistent storedConfig

if isempty(storedConfig)
    storedConfig=defaultConfig();
end

if nargin<1 || isempty(action)
    action='get';
end

switch lower(string(action))
    case "get"
        config=storedConfig;
    case "set"
        if nargin<2 || ~isstruct(value)
            error('referenceDiagnosticConfig:InvalidInput', ...
                'A configuration struct is required.');
        end
        storedConfig=mergeConfig(defaultConfig(),value);
        validateConfig(storedConfig);
        config=storedConfig;
    case "reset"
        storedConfig=defaultConfig();
        config=storedConfig;
    otherwise
        error('referenceDiagnosticConfig:UnknownAction', ...
            'Unknown action: %s',string(action));
end
end

function config=defaultConfig()
config=struct();
config.enabled=false;
config.cecIndex=1;
config.functionIndices=[1 5 8 9 11];
config.runSelection="median";
config.validateReplay=true;
config.saveReplayData=true;
config.exportFigures=true;
config.surfaceGridSize=60;
config.maxDisplayedPoints=2500;
config.maxCapturedEvaluations=100000;
end

function output=mergeConfig(defaults,inputConfig)
output=defaults;
fields=fieldnames(inputConfig);

for i=1:numel(fields)
    output.(fields{i})=inputConfig.(fields{i});
end
end

function validateConfig(config)
% The diagnostic renderer is intentionally tied to the 23-function CEC2005
% baseline because those functions provide the problem-space visualization
% contract used by runReferenceDiagnostics.
if ~isscalar(config.cecIndex) || ~isnumeric(config.cecIndex) || ...
        ~isfinite(config.cecIndex) || config.cecIndex~=1
    error('referenceDiagnosticConfig:UnsupportedCECIndex', ...
        'Reference diagnostics are supported only for CEC2005 (cecIndex = 1).');
end

if ~isempty(config.functionIndices) && ...
        (~isnumeric(config.functionIndices) || ~isvector(config.functionIndices) || ...
        any(~isfinite(config.functionIndices)) || ...
        any(config.functionIndices<1) || ...
        any(config.functionIndices>23) || ...
        any(fix(config.functionIndices)~=config.functionIndices))
    error('referenceDiagnosticConfig:InvalidFunctionIndices', ...
        'functionIndices must be a vector containing CEC2005 function indices from 1 through 23.');
end

logicalFields={"enabled","validateReplay","saveReplayData","exportFigures"};
for i=1:numel(logicalFields)
    fieldName=logicalFields{i};
    fieldValue=config.(fieldName);
    isLogicalScalar=islogical(fieldValue) && isscalar(fieldValue);
    isBinaryNumeric=isnumeric(fieldValue) && isscalar(fieldValue) && ...
        isfinite(fieldValue) && any(fieldValue==[0 1]);
    if ~(isLogicalScalar || isBinaryNumeric)
        error('referenceDiagnosticConfig:InvalidLogicalField', ...
            '%s must be a logical scalar (or numeric 0/1).',fieldName);
    end
end

if lower(string(config.runSelection))~="median"
    error('referenceDiagnosticConfig:InvalidRunSelection', ...
        'Only median run selection is currently supported.');
end

if ~isscalar(config.surfaceGridSize) || ~isnumeric(config.surfaceGridSize) || ...
        ~isfinite(config.surfaceGridSize) || config.surfaceGridSize<2 || ...
        fix(config.surfaceGridSize)~=config.surfaceGridSize
    error('referenceDiagnosticConfig:InvalidSurfaceGridSize', ...
        'surfaceGridSize must be an integer scalar greater than or equal to 2.');
end

integerFields={"maxDisplayedPoints","maxCapturedEvaluations"};
for i=1:numel(integerFields)
    fieldName=integerFields{i};
    fieldValue=config.(fieldName);
    if ~isscalar(fieldValue) || ~isnumeric(fieldValue) || ...
            ~isfinite(fieldValue) || fieldValue<1 || fix(fieldValue)~=fieldValue
        error('referenceDiagnosticConfig:InvalidNumericField', ...
            '%s must be a positive integer scalar.',fieldName);
    end
end
end
