%      Improved Salp Swarm Algorithm (ISSA) source code version 1.0.0
%..........................................................................
% Authored and programmed by: Dorian Sidea
% 
% e-mail:   doriansidea@gmail.com 
%
%..........................................................................
% The algorithm is developed as part of the paper:
%   Andrei Tudose, Dorian Sidea, Irina Picioroaga, Nicolae Anton, Constantin Bulac
%    Increasing Distributed Generation Hosting Capacity Based on a 
%    Sequential Optimization Approach Using an Improved Salp Swarm Algorithm
%  (Currently under review for publishing)
%
%       This research was supported by the project AOSR TEAMS, grant number 
%       301/14.04.2022, funded by the Academy of Romanian Scientists.
% 
%..........................................................................
%  In order to use the ISSA you can define the objective funciton in a
%  separte file and provide a handle to it
% 
% The ISSA input parameters are:
% fobj  - Handle to the objective function (@fobj)
% Nvars - Number of variables
% Ntot  - Total number of salps
% LoB   - Row vector containing the lower bounds for the variables
% UpB   - Row vector containing the upper bounds for the variables
% tMax  - Maximum number of iterations
% 
% The ISSA output parameters are: 
% FoodFit - The best objective function value found by ISSA
% FoodPos - The variables values corresponding to the optimal solution
% Convergence_curve - The FoodFit value at each iteration
%..........................................................................
clear all;clc;
%% Example for Rastrigin's Function

fobj =@rastriginsfcn;           % Handle to the objective function (@fobj)
Nvars = 30;                     % Number of variables
LoB = ones(1,Nvars) * (-5.12);  % Lower Bounds
UpB = ones(1,Nvars) * 5.12;     % Upper Bounds
Ntot = 1000;                     % Total number of salps
tMax = 1000;                    % Maximum number of iterations


%% Run  ISSA 
tic
[FoodFit,FoodPos,ConvCurve] = ISSA(Ntot,tMax,LoB,UpB,Nvars,fobj);
RunTime = toc;

%% Show the results
figure(1);clf;set(1,'color','w')
plot(ConvCurve','LineWidth',1.5);
title('ISSA Convergence Curve');
xlabel('Iteration');
ylabel('Objective function value');
grid on;

display(['Improved Salp Swarm Optimizer'])
display(['The best ISSA solution score is: ',num2str(FoodFit)])
display(['Runing time: ',num2str(RunTime)])
% disp(['The best ISSA solution is: ',num2str(FoodPos)])
