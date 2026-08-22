classdef SearchBehaviorRecorder < handle
    %SEARCHBEHAVIORRECORDER Capture full-dimensional evaluated candidates for E/E.

    properties (SetAccess=private)
        positions
        count=0
        capacity
        dimension
        truncated=false
    end

    methods
        function obj=SearchBehaviorRecorder(capacity,dimension)
            validateattributes(capacity,{'numeric'}, ...
                {'scalar','integer','positive','finite'});
            validateattributes(dimension,{'numeric'}, ...
                {'scalar','integer','positive','finite'});

            obj.capacity=double(capacity);
            obj.dimension=double(dimension);
            obj.positions=nan(obj.capacity,obj.dimension);
        end

        function add(obj,x)
            candidates=normalizeCandidates(x,obj.dimension);
            candidateCount=size(candidates,1);
            if candidateCount<1
                return;
            end

            available=obj.capacity-obj.count;
            writeCount=min(candidateCount,available);
            if writeCount>0
                targetRows=obj.count+(1:writeCount);
                obj.positions(targetRows,:)=candidates(1:writeCount,:);
                obj.count=obj.count+writeCount;
            end
            if writeCount<candidateCount
                obj.truncated=true;
            end
        end

        function [positions,count,truncated]=snapshot(obj)
            count=obj.count;
            truncated=obj.truncated;
            if count<1
                positions=zeros(0,obj.dimension);
            else
                positions=obj.positions(1:count,:);
            end
        end
    end
end

function candidates=normalizeCandidates(x,dimension)
x=double(x);
if isempty(x)
    candidates=zeros(0,dimension);
    return;
end

if isvector(x)
    flat=x(:)';
    candidates=nan(1,dimension);
    copyCount=min(numel(flat),dimension);
    candidates(1:copyCount)=flat(1:copyCount);
elseif size(x,1)==dimension
    % Match the benchmark wrapper convention: a Dim-by-N matrix contains
    % candidates in columns. This branch intentionally precedes NxDim.
    candidates=x.';
elseif size(x,2)==dimension
    candidates=x;
else
    flat=x(:)';
    candidateCount=floor(numel(flat)/dimension);
    if candidateCount<1
        candidates=nan(1,dimension);
        copyCount=min(numel(flat),dimension);
        candidates(1:copyCount)=flat(1:copyCount);
    else
        candidates=reshape(flat(1:candidateCount*dimension),dimension,[]).';
    end
end
end
