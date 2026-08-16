function ctx=ProjectContext(action,varargin)
%PROJECTCONTEXT Manage project paths and selected result templates.
% Usage:
%   ProjectContext('init',projectRoot,selectedIndex,cecsDim)
%   ctx=ProjectContext('get')
%
% Creates a versioned run folder under <projectRoot>/results and copies only
% the spreadsheet templates required by the selected benchmark suites and
% their configured dimensions.

persistent C

if nargin==0
    action='get';
end

switch lower(action)
    case 'init'
        projectRoot='';
        selectedIndex=[];
        cecsDim={};

        if ~isempty(varargin)
            projectRoot=varargin{1};
        end
        if numel(varargin)>=2
            selectedIndex=varargin{2};
        end
        if numel(varargin)>=3
            cecsDim=varargin{3};
        end

        if isempty(projectRoot)
            thisFile=mfilename('fullpath');
            here=fileparts(thisFile);
            projectRoot=fileparts(fileparts(here));
        end

        if isempty(selectedIndex) || isempty(cecsDim)
            error('ProjectContext:MissingBenchmarkSelection', ...
                ['ProjectContext must be initialized with selectedIndex and CECsDim ' ...
                 'so only required result templates are copied.']);
        end

        templateRoot=findTemplateRoot(projectRoot);
        copyPlan=buildTemplateCopyPlan(templateRoot,selectedIndex,cecsDim);

        stamp=datestr(now,'yy-mm-dd HH-MM');
        resultsBase=fullfile(projectRoot,'results');
        resultsRoot=createUniqueResultsRoot(resultsBase,['result_' stamp]);

        if exist(resultsBase,'dir')~=7
            mkdir(resultsBase);
        end
        mkdir(resultsRoot);

        for fileIndex=1:size(copyPlan,1)
            sourceFile=copyPlan{fileIndex,1};
            relativeFolder=copyPlan{fileIndex,2};
            targetFolder=fullfile(resultsRoot,relativeFolder);

            if exist(targetFolder,'dir')~=7
                mkdir(targetFolder);
            end

            [status,message]=copyfile(sourceFile,targetFolder);
            if ~status
                error('ProjectContext:TemplateCopyFailed', ...
                    'Failed to copy template:\n%s\n%s',sourceFile,message);
            end
        end

        C.projectRoot=projectRoot;
        C.templateRoot=templateRoot;
        C.resultsRoot=resultsRoot;
        C.stamp=stamp;
        C.selectedIndex=selectedIndex;
        C.cecsDim=cecsDim;

        ctx=C;

    case 'get'
        if isempty(C) || ~isfield(C,'resultsRoot') || isempty(C.resultsRoot)
            error('ProjectContext:NotInitialized', ...
                ['ProjectContext is not initialized. Run main.m or call ' ...
                 'ProjectContext(''init'',projectRoot,selectedIndex,CECsDim) first.']);
        end
        ctx=C;

    otherwise
        error('ProjectContext:UnknownAction','Unknown action: %s',action);
end
end

function templateRoot=findTemplateRoot(projectRoot)
templateCandidates={ ...
    fullfile(projectRoot,'src','results_template'), ...
    fullfile(projectRoot,'src','results','results_template')};

templateRoot='';
for candidateIndex=1:numel(templateCandidates)
    if exist(templateCandidates{candidateIndex},'dir')==7
        templateRoot=templateCandidates{candidateIndex};
        break;
    end
end

if isempty(templateRoot)
    error('ProjectContext:TemplateRootNotFound', ...
        'Result template root was not found under the project src folder.');
end
end

function copyPlan=buildTemplateCopyPlan(templateRoot,selectedIndex,cecsDim)
benchmarkFolders={ ...
    'CEC2005', ...
    'CEC2014', ...
    'CEC2017', ...
    'CEC2019', ...
    'CEC2020', ...
    'CEC2022', ...
    'Real World Problems'};

selectedIndex=selectedIndex(:).';
if any(~isfinite(selectedIndex)) || any(selectedIndex~=fix(selectedIndex)) || ...
        any(selectedIndex<1) || any(selectedIndex>numel(benchmarkFolders))
    error('ProjectContext:InvalidBenchmarkIndex', ...
        'selectedIndex must contain integer benchmark indices from 1 to %d.', ...
        numel(benchmarkFolders));
end

if numel(cecsDim)<max(selectedIndex)
    error('ProjectContext:MissingDimensionConfiguration', ...
        'CECsDim does not contain dimension configuration for every selected benchmark.');
end

selectedIndex=unique(selectedIndex,'stable');
copyPlan=cell(0,2);

for selectionIndex=1:numel(selectedIndex)
    benchmarkIndex=selectedIndex(selectionIndex);
    benchmarkFolder=benchmarkFolders{benchmarkIndex};
    sourceFolder=fullfile(templateRoot,benchmarkFolder);

    if exist(sourceFolder,'dir')~=7
        error('ProjectContext:BenchmarkTemplateFolderNotFound', ...
            'Template folder was not found for benchmark index %d:\n%s', ...
            benchmarkIndex,sourceFolder);
    end

    dimensionConfigs=cecsDim{benchmarkIndex};
    if ~iscell(dimensionConfigs)
        dimensionConfigs=num2cell(dimensionConfigs);
    end

    if isempty(dimensionConfigs)
        error('ProjectContext:EmptyDimensionConfiguration', ...
            'No dimensions are configured for benchmark %s.',benchmarkFolder);
    end

    dimensionTags=cell(1,numel(dimensionConfigs));
    for dimIndex=1:numel(dimensionConfigs)
        dimensionTags{dimIndex}=dimensionTag(dimensionConfigs{dimIndex});
    end
    dimensionTags=unique(dimensionTags,'stable');

    for dimIndex=1:numel(dimensionTags)
        templateFile=[dimensionTags{dimIndex} '.xlsx'];
        sourceFile=fullfile(sourceFolder,templateFile);

        if exist(sourceFile,'file')~=2
            error('ProjectContext:TemplateNotFound', ...
                ['Required template does not exist for the current benchmark selection:\n' ...
                 '%s'],sourceFile);
        end

        copyPlan(end+1,:)={sourceFile,benchmarkFolder}; %#ok<AGROW>
    end
end
end

function tag=dimensionTag(dimensionConfig)
if iscell(dimensionConfig)
    if isempty(dimensionConfig)
        error('ProjectContext:InvalidDimensionConfiguration', ...
            'Dimension configuration cannot be empty.');
    end
    dimensionValue=dimensionConfig{1};
else
    dimensionValue=dimensionConfig;
end

if isnumeric(dimensionValue)
    if ~isscalar(dimensionValue) || ~isfinite(dimensionValue)
        error('ProjectContext:InvalidDimension', ...
            'Numeric dimensions must be finite scalar values.');
    end

    if dimensionValue==0
        tag='fixDim';
    else
        tag=sprintf('%gDim',dimensionValue);
    end
    return;
end

value=lower(strtrim(string(dimensionValue)));
if ~isscalar(value) || ismissing(value) || strlength(value)==0
    error('ProjectContext:InvalidDimensionTag', ...
        'Dimension tags must be nonempty scalar text values.');
end

if value=="fix" || value=="fixdim"
    tag='fixDim';
elseif endsWith(value,"dim")
    numericPart=extractBefore(value,strlength(value)-2);
    tag=[char(numericPart) 'Dim'];
else
    tag=[char(value) 'Dim'];
end
end

function resultsRoot=createUniqueResultsRoot(resultsBase,folderName)
resultsRoot=fullfile(resultsBase,folderName);
if exist(resultsRoot,'dir')~=7
    return;
end

suffix=2;
while true
    candidate=fullfile(resultsBase,sprintf('%s_%02d',folderName,suffix));
    if exist(candidate,'dir')~=7
        resultsRoot=candidate;
        return;
    end
    suffix=suffix+1;
end
end
