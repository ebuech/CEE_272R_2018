% Stanford University - CEE272R - Spring 2017

% This function computes the DCOPF of a general network - All inputs should be in per-unit.
% 
% Inputs: 
% Y - Ybus matrix of the network [n x n] (n is # of buses)

% PGl, PGu - lower and upper limits of real power generated at each bus [n
% x 1].

% PD - Real power consumed at each bus [n x 1] - A load will be a positive
% value

% PF - Power flow transmission line constraints.  Ordered as follows:
% (PF=[P_{1,2} P_{1,3}...P_{1,n} P_{2,3} P_{2,4}...P_{2,n}...P_{n-1,n}] - PF_{i,j}
% - power flow constraint for line connecting bus i to j).
%I.e. for a 3 bus network with
% L1, L2, and L3, PF = [PF12 PF13 PF23]'

% thetaL and thetaU - lower and upper limits of phase angle at each bus

% CQ - Quadratic part of cost function
% CL - Linear part of cost function

% slack - Slack bus
% 
% Outputs:
% .PF_opt - upper triangular matrix where PF(i,j) is the optimal flow
% from bus i to bus j [nxn]
% .Cost - optimal solution 
% .P_opt - optimal power generated by each generator [nx1]
% .theta_opt - optimal phase angle [nx1]
% .LMP_opt - Locational marginal price [nx1]

  function [dcopf]=DCOPF_2(Y,PGl,PGu,PD,thetaL,thetaU,CQ,CL,PF,slack)
    n=length(Y);
    B = imag(Y);
    x=1;        % Counter

cvx_begin
    variable PG(n); % optimization variable: PG_i
    variable theta(n); % optimization variable: theta_i
    dual variable lmp; % lagrange multiplier for power balance at bus i

    
    minimize(PG'*diag(CQ)*PG + PG'*CL) % objective function
    subject to
    
    %%%%%%%%%Power generation constraints
    
    PGl<=PG;
    PG<=PGu;
    
    %%%%%%%%%Line capacity constraints
    count = 0;
    for i=1:n           
        for j=(i+1):n
            count = count + 1;
            -PF(count)<=B(i,j)*(theta(i)-theta(j));
            B(i,j)*(theta(i)-theta(j))<=PF(count);
        end
    end
    
    %%%%%%%%%Bus phase angle constraints
    
    thetaL<=theta;
    theta<=thetaU;
    
    %%%%%%%%%Power balance constraint
        
    lmp : PG-PD==-B*theta;
    
    %%%%%%%%%Slack angle constraint   
    
    theta(1)==0;
        
        
cvx_end

dcopf.PF_opt = zeros(n);
for i=1:n
    for j=i+1:1:n
        dcopf.PF_opt(i,j)=B(i,j)*(theta(i)-theta(j));
        x=x+1;
    end
end
dcopf.Cost=cvx_optval;
dcopf.P_opt=PG;
dcopf.theta_opt = theta;
dcopf.LMP_opt = lmp;
end