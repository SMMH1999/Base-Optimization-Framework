function [nDim, LB, UB, Vio, GloMin, Obj] = ProbInfo(n)
    nDim = [7,3,4,2,4,5,4,2,4,4,11,4,3];
    if n == 1
        % Speed Reducer
        LB = [2.6, 0.7, 17, 7.3, 7.3, 2.9, 5];
        UB = [3.6, 0.8, 28, 8.3, 8.3, 3.9, 5.5];
        Vio = [50 10 1 1 1 20 1 300 1 1 50 1];
        Obj = @f1;
        GloMin = 2994.4244658;
    elseif n == 2
        % Tension/compression spring design
        LB = [0.05,0.25,2.00];
        UB = [2,1.3,15.0];
        Vio = [3 4 0.1 0.1 1];
        Obj = @f2;
        GloMin = 0.012665232788;
    elseif n == 3
        % Pressure vessel design
        LB = [0.51,0.51,10,10];
        UB = [99.49,99.49,200,200];
        Vio = [12000 8000 1 1 1];
        Obj = @f3;
        GloMin = 6059.714335048436 ;
    elseif n == 4
        % Three-bar truss design problem
        LB = 0*ones(1,nDim(n));
        UB = 1*ones(1,nDim(n));
        Vio = [140 7 15 1];
        Obj = @f4;
        GloMin = 2.6389584338E+02;
    elseif n == 5
        % Design of gear train
        LB = 12*ones(1,nDim(n));
        UB = 60*ones(1,nDim(n));
        Vio = [1 1];
        Obj = @f5;
        GloMin = 2.70085714e-12-1e-4;
    elseif n == 6
        % Cantilever beam
        LB = [0.01 0.01 0.01 0.01 0.01];
        UB = [100 100 100 100 100];
        Vio = [10 1];
        Obj = @f6;
        GloMin = 1.3399576;
    elseif n == 7
        % Minimize I-beam vertical deflection
        LB = [10 10 0.9 0.9];
        UB = [80 50 5.0 5.0];
        Vio = 0.1*[1 1 1];
        Obj = @f7;
        GloMin = 0.0130741;
    elseif n == 8
        % Tubular column design
        LB = [2 0.2];
        UB = [14 0.8];
        Vio = [100 1 1 1 1 1 1];
        Obj = @f8;
        GloMin = 26.486361473;
    elseif n == 9
        % Piston lever
        LB = [0.05 0.05 0.05 0.05];
        UB = [500 500 500 120];
        Vio = [1 1 1 100 1];
        Obj = @f9;
        GloMin = 8.41269832311;
    elseif n == 10
        % Corrugated bulkhead design
        LB = [0 0 0 0];
        UB = [100 100 100 5];
        Vio = [1 1 3 3 100 1 1];
        Obj = @f10;
        GloMin = 6.8429580100808;
    elseif n == 11
        % Car side impact design
        LB = [0.50 0.50 0.50 0.50 0.50 0.50 0.50 0 0 -30 -30];
        UB = [1.50 1.50 1.50 1.50 1.50 1.50 1.50 1 1 +30 +30];
        Vio = [1 1 1 1 1 1 10 29.8 2 6 1];
        Obj = @f11;
        GloMin = 22.84296954;
    elseif n == 12
        % Design of welded beam design
        LB = [0.1 0.1 0.1 0.1];
        UB = [2 10 10 2];
        Vio = [1 1 4 0.001 1 0.5 1 1];
        Obj = @f12;
        GloMin = 1.724852308597366;
    elseif n==13
        % Reinforced concrete beam design
        LB = [0 0 5];
        UB = [1 1 10];
        Vio = [50 30 1];
        Obj=@f13;
        GloMin=359.2080;
    end
    nDim = nDim(n);
end

%% Objective Subjective Functions
function [z, g, h] = f1(x)
    % Weight Minimization of a Speed Reducer
    z = 0.7854*x(:,1).*x(:,2).^2.*(3.3333.*x(:,3).^2+14.9334.*x(:,3)-43.0934)-1.508.*x(:,1).*(x(:,6).^2+x(:,7).^2).....
        +7.477.*(x(:,6).^3+x(:,7).^3)+0.7854.*(x(:,4).*x(:,6).^2+x(:,5).*x(:,7).^2);

    g(:,1) = -x(:,1).*x(:,2).^2.*x(:,3)+27;
    g(:,2) = -x(:,1).*x(:,2).^2.*x(:,3).^2+397.5;
    g(:,3) = -x(:,2).*x(:,6).^4.*x(:,3).*x(:,4).^(-3)+1.93;
    g(:,4) = -x(:,2).*x(:,7).^4.*x(:,3)./x(:,5).^3+1.93;
    g(:,5) = 10.*x(:,6).^(-3).*sqrt(16.91.*10^6+(745.*x(:,4)./(x(:,2).*x(:,3))).^2)-1100;
    g(:,6) = 10.*x(:,7).^(-3).*sqrt(157.5.*10^6+(745.*x(:,5)./(x(:,2).*x(:,3))).^2)-850;
    g(:,7) = x(:,2).*x(:,3)-40;
    g(:,8) = -x(:,1)./x(:,2)+5;
    g(:,9) = x(:,1)./x(:,2)-12;
    g(:,10) = 1.5.*x(:,6)-x(:,4)+1.9;
    g(:,11) = 1.1.*x(:,7)-x(:,5)+1.9;
    h = 0;
end

function [z, g, h] = f2(x)
    % Tension/compression  spring  design (case 1)
    z = x(:,1).^2.*x(:,2).*(x(:,3)+2);
    h = 0;
    g(:,1) = 1-(x(:,2).^3.*x(:,3))./(71785.*x(:,1).^4);
    g(:,2) = (4.*x(:,2).^2-x(:,1).*x(:,2))./(12566.*(x(:,2).*x(:,1).^3-x(:,1).^4))....
        + 1./(5108.*x(:,1).^2)-1;
    g(:,3) = 1-140.45.*x(:,1)./(x(:,2).^2.*x(:,3));
    g(:,4) = (x(:,1)+x(:,2))./1.5-1;
end

function [z, g, h] = f3(x)
    % update
    x(:,1) = 0.0625.*round(x(:,1));
    x(:,2) = 0.0625.*round(x(:,2));
    % Pressure vessel design
    z = 0.6224.*x(:,1).*x(:,3).*x(:,4)+1.7781.*x(:,2).*x(:,3).^2....
        +3.1661.*x(:,1).^2.*x(:,4)+19.84.*x(:,1).^2.*x(:,3);
    g(:,1) = -x(:,1)+0.0193.*x(:,3);
    g(:,2) = -x(:,2)+0.00954.*x(:,3);
    g(:,3) = -pi.*x(:,3).^2.*x(:,4)-4/3.*pi.*x(:,3).^3+1296000;
    g(:,4) = x(:,4)-240;
    h = 0;
end

function [z, g, h] = f4(x)
    % Three-bar truss design problem
    z = (2.*sqrt(2).*x(:,1)+x(:,2))*100;
    g(:,1) = (sqrt(2).*x(:,1)+x(:,2))./(sqrt(2).*x(:,1).^2+2.*x(:,1).*x(:,2))*2-2;
    g(:,2) = x(:,2)./(sqrt(2).*x(:,1).^2+2.*x(:,1).*x(:,2))*2-2;
    g(:,3) = 1./(sqrt(2).*x(:,2)+x(:,1))*2-2;
    h=0;
end

function [z, g, h] = f5(x)
    % Design of gear train - True
    x=round(x); term1=1/6.931; term2=(x(3)*x(2))/(x(1)*x(4));
    z = (term1-term2)^2;
    g = 0;
    h = 0;
end

function [z, g, h] = f6(x)
    % Cantilever beam
    z = 0.0624*(x(1)+x(2)+x(3)+x(4)+x(5));
    g(1) = (61/x(1)^3)+(37/x(2)^3)+(19/x(3)^3)+(7/x(4)^3)+(1/x(5)^3)-1;
    h = 0;
end

function [z, g, h] = f7(x)
    % Minimize I-beam vertical deflection
    term1 = x(3)*(x(1)-2*x(4))^3/12; term2 = x(2)*x(4)^3/6; term3 = 2*x(2)*x(4)*((x(1)-x(4))/2)^2;
    z = 5000/(term1+term2+term3);
    g(1) = 2*x(2)*x(4)+x(3)*(x(1)-2*x(4))-300;
    term1 = x(3)*(x(1)-2*x(4))^3;
    term2 = 2*x(2)*x(4)*(4*x(4)^2+3*x(1)*(x(1)-2*x(4)));
    term3 = (x(1)-2*x(4))*x(3)^3;
    term4 = 2*x(4)*x(2)^3;
    g(2) = ((18*x(1)*10^4)/(term1+term2))+((15*x(2)*10^3)/(term3+term4))-6;
    h = 0;
end

function [z, g, h] = f8(x)
    % Tubular column design
    z = 9.8*x(1)*x(2)+2*x(1);
    g(1)=1.59-x(1)*x(2);
    g(2)=47.4-x(1)*x(2)*(x(1)^2+x(2)^2);
    g(3)=2/x(1)-1;
    g(4)=x(1)/14-1;
    g(5)=2/x(1)-1;
    g(6)=x(1)/8-1;
    h = 0;
end

function [z, g, h] = f9(x)
    % Piston lever
    teta = 0.25*pi; H=x(1); B=x(2); D=x(3); X=x(4);
    l2=((X*sin(teta)+H)^2+(B-X*cos(teta))^2)^0.5;
    l1=((X-B)^2+H^2)^0.5;
    z=0.25*pi*D^2*(l2-l1);
    teta = 0.25*pi; H=x(1); B=x(2); D=x(3); X=x(4); P=1500; Q=10000; L=240; Mmax=1.8e+6;
    R=abs(-X*(X*sin(teta)+H)+H*(B-X*cos(teta)))/sqrt((X-B)^2+H^2);
    F=0.25*pi*P*D^2;
    l2=((X*sin(teta)+H)^2+(B-X*cos(teta))^2)^0.5;
    l1=((X-B)^2+H^2)^0.5;
    g(1)=Q*L*cos(teta)-R*F;
    g(2)=Q*(L-X)-Mmax;
    g(3)=1.2*(l2-l1)-l1;
    g(4)=0.5*D-B;
    h = 0;
end

function [z, g, h] = f10(x)
    % Corrugated bulkhead design
    b=x(1); h=x(2); l=x(3); t=x(4); ABD = abs(l^2-h^2);
    z = (5.885*t*(b+l))/(b+(abs(l^2-h^2))^0.5);
    g(1)=-t*h*(0.4*b+l/6)+8.94*(b+(ABD)^0.5);
    g(2)=-t*h^2*(0.2*b+l/12)+2.2*(8.94*(b+(ABD)^0.5))^(4/3);
    g(3)=-t+0.0156*b+0.15;
    g(4)=-t+0.0156*l+0.15;
    g(5)=-t+1.05;
    g(6)=-l+h;
    h = 0;
end

function [z, g, h] = f11(x)
    % Sections
    Sec8 = [0.192 0.345];
    Sec9 = [0.192 0.345];
    nSec8 = numel(Sec8);
    nSec9 = numel(Sec9);
    x(8) = Sec8(min(floor(x(8)*nSec8+1),nSec8));
    x(9) = Sec8(min(floor(x(9)*nSec9+1),nSec9));

    % Objective
    z=1.98+4.90*x(1)+6.67*x(2)+6.98*x(3)+4.01*x(4)+1.78*x(5)+2.73*x(7);

    % Subjective
    Fa =1.16-0.3717*x(2)*x(4)-0.00931*x(2)*x(10)-0.484*x(3)*x(9)+0.01343*x(6)*x(10);
    VCu =0.261-0.0159*x(1)*x(2)-0.188*x(1)*x(8)-0.019*x(2)*x(7)+0.0144*x(3)*x(5)+0.0008757*x(5)*x(10)+0.08045*x(6)*x(9)+0.00139*x(8)*x(11)+0.00001575*x(10)*x(11);
    VCm =0.214+0.00817*x(5)-0.131*x(1)*x(8)-0.0704*x(1)*x(9)+0.03099*x(2)*x(6)-0.018*x(2)*x(7)+0.0208*x(3)*x(8)+0.121*x(3)*x(9)-0.00364*x(5)*x(6)+0.0007715*x(5)*x(10)-0.0005354*x(6)*x(10)+0.00121*x(8)*x(11)+0.00184*x(9)*x(10)-0.02*x(2)^2;
    VCl=0.74-0.61*x(2)-0.163*x(3)*x(8)+0.001232*x(3)*x(10)-0.166*x(7)*x(9)+0.227*x(2)^(2);
    Dur=28.98+3.818*x(3)-4.2*x(1)*x(2)+0.0207*x(5)*x(10)+6.63*x(6)*x(9)-7.7*x(7)*x(8)+0.32*x(9)*x(10);
    Dmr=33.86+2.95*x(3)+0.1792*x(10)-5.057*x(1)*x(2)-11*x(2)*x(8)-0.0215*x(5)*x(10)-9.98*x(7)*x(8)+22*x(8)*x(9);
    Dlr=46.36-9.9*x(2)-12.9*x(1)*x(8)+0.1107*x(3)*x(10);
    Fp=4.72-0.5*x(4)-0.19*x(2)*x(3)-0.0122*x(4)*x(10)+0.009325*x(6)*x(10)+0.000191*x(11)^(2);
    VMBP=10.58-0.674*x(1)*x(2)-1.95*x(2)*x(8)+0.02054*x(3)*x(10)-0.0198*x(4)*x(10)+0.028*x(6)*x(10);
    VFD=16.45-0.489*x(3)*x(7)-0.843*x(5)*x(6)+0.0432*x(9)*x(10)-0.0556*x(9)*x(11)-0.000786*x(11)^(2);
    g = [Fa-1, VCu-0.32, VCm-0.32, VCl-0.32, Dur-32, Dmr-32, Dlr-32, Fp-4, VMBP-9.9, VFD-15.7];
    h = 0;
end

function [z, g, h] = f12(x)
    % A welded beam design problem
    z = 1.10471*x(1)^2*x(2)+0.04811*x(3)*x(4)*(14+x(2));
    % subjectives
    p = 6000;
    l = 14;
    e = 30e6;
    g = 12e6;
    deltamax=0.25;
    tomax=13600;
    sigmamax=30000;
    m = p*(l+x(2)/2);
    r = ((x(2)/2)^2+((x(1)+x(3))/2)^2)^0.5;
    j = 2*(2^0.5*x(1)*x(2)*(x(2)^2/12 + ((x(1)+x(3))/2)^2));
    toprim = p/(2^0.5*x(1)*x(2));
    tozegond = m*r/j;
    sigma = 6*p*l/(x(4)*x(3)^2);
    delta = (4*p*l^3)/(e*x(3)^3*x(4));
    pc = ((4.013*e*(x(3)^2*x(4)^6/36)^0.5)/l^2)...
        *(1-0.5*(x(3)/l)*(e/(4*g))^0.5);
    to = (toprim^2+2*toprim*tozegond*x(2)/(2*r)+tozegond^2)^0.5;
    g(1)=to-tomax;
    g(2)=sigma-sigmamax;
    g(3)=x(1)-x(4);
    g(4)=1.10471*x(1)^2+0.04811*x(3)*x(4)*(14+x(2))-5;
    g(5)=0.125-x(1);
    g(6)=delta-deltamax;
    g(7)=p-pc;
    h = 0;
end

function [z, g, h] = f13(x)
    % Beam Design Params
    x1 = [6 6.16 6.32 6.6 7 7.11 7.2 7.8 7.9 8 8.4];
    nx1 = numel(x1);
    x2 = 28:40;
    nx2 = numel(x2);

    As = x1(min(floor(x(1)*nx1+1),nx1));
    b = x2(min(floor(x(2)*nx2+1),nx2));
    h = x(3);

    % Objective
    z=29.4*As+0.6*b*h;

    % Subjectives
    g(1)=b/h-4;
    g(2)=180+7.375*As^2/h-As*b;
    h=0;
end