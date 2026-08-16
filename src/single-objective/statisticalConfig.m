function config=statisticalConfig(action,value)
    %STATISTICALCONFIG Store and retrieve statistical output settings.

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
                error('statisticalConfig:InvalidInput','A configuration struct is required.');
            end
            storedConfig=mergeConfig(defaultConfig(),value);
            config=storedConfig;
        case "reset"
            storedConfig=defaultConfig();
            config=storedConfig;
        otherwise
            error('statisticalConfig:UnknownAction','Unknown action: %s',string(action));
    end
end

function config=defaultConfig()
    config=struct();
    config.enabled=true;
    config.alpha=0.05;
    config.referenceAlgorithm=1;
    config.performanceDirection="min";
    config.rankingMetric="mean";
    config.comparisonAbsoluteTolerance=1e-14;
    config.comparisonUlpFactor=16;
    config.applyHolm=true;
    config.exportBoxplots=false;
    config.boxplotCEC="2005";
    config.boxplotFunctions=[];
end

function output=mergeConfig(defaults,inputConfig)
    output=defaults;
    fields=fieldnames(inputConfig);
    for i=1:numel(fields)
        output.(fields{i})=inputConfig.(fields{i});
    end
end
