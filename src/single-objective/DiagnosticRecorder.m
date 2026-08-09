classdef DiagnosticRecorder < handle
    %DIAGNOSTICRECORDER Capture lightweight objective-evaluation telemetry.

    properties (SetAccess=private)
        positions
        fitness
        count=0
        capacity
        truncated=false
    end

    methods
        function obj=DiagnosticRecorder(capacity)
            obj.capacity=capacity;
            obj.positions=nan(capacity,2);
            obj.fitness=nan(capacity,1);
        end

        function add(obj,x,value)
            if obj.count>=obj.capacity
                obj.truncated=true;
                return;
            end

            obj.count=obj.count+1;
            flat=double(x(:));

            if ~isempty(flat)
                obj.positions(obj.count,1)=flat(1);
                if numel(flat)>=2
                    obj.positions(obj.count,2)=flat(2);
                end
            end

            obj.fitness(obj.count)=double(value);
        end

        function [positions,fitness,count,truncated]=snapshot(obj)
            count=obj.count;
            truncated=obj.truncated;

            if count<1
                positions=zeros(0,2);
                fitness=zeros(0,1);
            else
                positions=obj.positions(1:count,:);
                fitness=obj.fitness(1:count,:);
            end
        end
    end
end
