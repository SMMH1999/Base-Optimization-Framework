clc; 
clear; 
close all;

%% Problems
% # 1 - Speed reducer design
% # 2 - Tension/compression spring design
% # 3 - Pressure vessel design
% # 4 - Three-bar truss design problem
% # 5 - Design of gear train
% # 6 - Cantilever beam
% # 7 - Minimize I-beam vertical deflection
% # 8 - Tubular column design
% # 9 - Piston lever
% #10 - Corrugated bulkhead design
% #11 - Car side impact design
% #12 - Design of welded beam design
% #13 - A reinforced concrete beam design

%% Run Information
nRun = 30;                      % Number of runs
Prob2Run = 1:13;                % Selected problems
nPop = 30;                      % Population size
e2s = 1e-8;                     % Erorr to stop
MaxEval=9000*ones(1,13);        % Maximum NFEs for each problem

%% Run algorithm
for Prob = Prob2Run
    for Run = 1:nRun
        % Run SNS
        data(Prob,Run) = sns(Prob,MaxEval,nPop,e2s);

        % Run step
        clc;
        disp(['Prob: ' num2str(Prob)])
        disp(['Run : ' num2str(Run)])
    end
end