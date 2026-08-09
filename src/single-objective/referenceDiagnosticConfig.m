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
if ~isscalar(config.cecIndex) || ~isnumeric(config.cecIndex) || ...
        ~isfinite(config.cecIndex) || config.cecIndex<1 || ...
        fix(config.cecIndex)~=config.cecIndex
    error('referenceDiagnosticConfig:InvalidCECIndex', ...
        'cecIndex must be a positive integer scalar.');
end

if ~isnumeric(config.functionIndices) || ...
        any(~isfinite(config.functionIndices)) || ...
        any(config.functionIndices<1) || ...
        any(fix(config.functionIndices)~=config.functionIndices)
    error('referenceDiagnosticConfig:InvalidFunctionIndices', ...
        'functionIndices must contain positive integer values.');
end

if lower(string(config.runSelection))~="median"
    error('referenceDiagnosticConfig:InvalidRunSelection', ...
        'Only median run selection is currently supported.');
end

integerFields={"surfaceGridSize","maxDisplayedPoints","maxCapturedEvaluations"};
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
