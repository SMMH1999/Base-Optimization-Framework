
function [f_valc, xc]=hfpso_v4(iter,swarm_size,c1,c2,LB,UB,D,vmax_coef,func_no,fhd)

% usage ->  hfpso_v3(50,30,1.49445,1.49445,down,up,dim,0.1,func_no,'test_functions');

%If you have two or more variables, and if the lower and upper boundaries are different for both the variables, then how %to specify it? Please use updated Version4 link: %https://drive.google.com/file/d/1LtGsZsCHzDckv-F5K_Zjfsw5oOTkeNQE/view?usp=sharing
%Usage--> dim=4; down = [0 0 0 0]; up= [5 10 3 15]; func_no=1; results(func_no,:) = %hfpso_v4(50,30,1.49445,1.49445,down,up,dim,0.1,func_no,'test_functions');


% new research cooperation are welcome with me:  berkanaydilek@harran.edu.tr

% please cite my article
% ibrahim Berkan Aydilek, 
% A hybrid firefly and particle swarm optimization algorithm for computationally expensive numerical problems,
% Applied Soft Computing, Volume 66, May 2018, Pages 232-249


rand('state', sum(100*clock));

v_max= vmax_coef* (UB-LB);
v_min=-v_max;

for sw=1:swarm_size
    for ds=1:D
particles_x(sw,ds)=LB(ds)+rand*(UB(ds)-LB(ds));
particles_v(sw,ds)=v_min(ds)+rand*(v_max(ds)-v_min(ds));
    end
end



for piiz=1:swarm_size
f_val(piiz,1)=feval(fhd,particles_x(piiz,:),func_no,D);
end

p_best=particles_x;
p_best_val=f_val;
[~,index]= min(f_val(:,1));
g_best=particles_x(index,:);
g_best_val=f_val(index,1);
dmax = (UB-LB)*sqrt(D);

for i=1:iter
w_linear = 0.9-((0.9-0.5)/iter)*i; % Linear Decreasing Inertia Weight
    w=w_linear;
    
for j=1:swarm_size
 
 if (i>2) && (f_val(j,1)<=g_best_val_t(i-2,:))
    
 rij=norm(particles_x(j,:) - g_best_t(i-2,:))./dmax;
alpha=0.2;
beta0=2; 
m=2;
gamma=1;
beta=beta0*exp(-gamma*rij.^m);  
e=rand(1,D)-1/2;
prev_pos=particles_x(j,:);
particles_x(j,:)= particles_x(j,:)+ beta.*(particles_x(j,:)- g_best_t(i-2,:) )+ alpha.*e;
for k=1:D
   if particles_x(j,k)>UB(k)
       particles_x(j,k)=UB(k); 
   end
       if particles_x(j,k)<LB(k)
           particles_x(j,k)=LB(k); 
       end
end
particles_v(j,:)=  particles_x(j,:)-prev_pos;
 
for k=1:D
   if particles_v(j,k)>v_max(k)
       particles_v(j,k)=v_max(k); 
   end
       if particles_v(j,k)<v_min(k)
           particles_v(j,k)=v_min(k);
       end 
end
     
    else
       
    for k=1:D
    r1=rand();
    r2=rand();
    
particles_v(j,k)=w*particles_v(j,k)+c1*r1*(p_best(j,k)-particles_x(j,k))+c2*r2*(g_best(1,k)-particles_x(j,k)); 
    end

  for k=1:D
   if particles_v(j,k)>v_max(k)
       particles_v(j,k)=v_max(k); 
   end
       if particles_v(j,k)<v_min(k)
           particles_v(j,k)=v_min(k);
       end
  end


particles_x(j,:)=particles_x(j,:)+particles_v(j,:);

for k=1:D
   if particles_x(j,k)>UB(k)
       particles_x(j,k)=UB(k); 
   end
       if particles_x(j,k)<LB(k)
           particles_x(j,k)=LB(k); 
       end
end

 end
end


for piiz=1:swarm_size
f_val(piiz,1)=feval(fhd,particles_x(piiz,:),func_no,D);
end

for j=1:swarm_size
    
if f_val(j,1)<p_best_val(j,1)
p_best(j,:)=particles_x(j,:);
p_best_val(j,1)=f_val(j,1);
end

if p_best_val(j,1)<g_best_val
g_best=particles_x(j,:);
g_best_val=p_best_val(j,1);
end

end

g_best_t(i,:)=g_best;
g_best_val_t(i,:)=g_best_val;

variabless(i,:)=g_best;
valuess(i,1)=g_best_val;
%disp(['Iteration ' num2str(i) ': Best Cost = ' num2str(valuess(i,1))]);

end

xc=variabless(iter,:);
f_valc=valuess(iter,:);

end



