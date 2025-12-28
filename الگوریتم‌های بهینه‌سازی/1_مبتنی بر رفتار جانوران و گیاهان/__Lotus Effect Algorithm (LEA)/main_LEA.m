

SearchAgents_no=30; % Number of search agents

Function_name='F1'; % Name of the test function that can be from F1 to F29 

Max_iteration=500; % Maximum numbef of iterations

% Load details of the selected benchmark function
[lb,ub,dim,fobj]=Get_Functions_details(Function_name);

[Best_score,Best_pos,fcg_curve]=LEA(SearchAgents_no,Max_iteration,lb,ub,dim,fobj);

figure('Position',[400 400 560 190])

%Draw search space
subplot(1,2,1);
func_plot(Function_name);
title('Test function')
xlabel('x_1');
ylabel('x_2');
zlabel([Function_name,'( x_1 , x_2 )'])
grid off

%Draw objective space
subplot(1,2,2);
semilogy(fcg_curve,'Color','r')
title('Convergence curve')
xlabel('Iteration');
ylabel('Best score obtained so far');

axis tight
grid off
box on
legend('LEA')

%display(['The best solution obtained by LEA is : ', num2str(Best_pos')]);
display(['The best optimal value of the objective funciton found by LEA is : ', num2str(Best_score)]);

        



