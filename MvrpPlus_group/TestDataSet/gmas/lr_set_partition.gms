$ontext

    set partition problem based on LR
    junhua Chen.   cjh@bjtu.edu.cn
    3/31,2016

$offtext

set g 'group';
set s 'states patter';
set p 'passenger';

parameter c(g,s);
parameter a(g,p,s);
**parameter initx(g,s);

*input data
$include "../input_gams_data.txt";

*--------------------------------------------------------------------
* standard MIP problem formulation
* solve as RMIP to get initial values for the duals
*--------------------------------------------------------------------
binary variable x(g,s);
variable z;

equations
         obj_main
         assign_pattern(g)
         assign_passenger(p)
;
obj_main..
         z=e=sum((g,s),c(g,s)*x(g,s));
assign_pattern(g)..
         sum(s,x(g,s))=e=1;
assign_passenger(p)..
         sum((g,s),a(g,p,s)*x(g,s))=e=1;

option optcr=0;
model model_main /obj_main,assign_pattern,assign_passenger/;
solve model_main using rmip minimizing z;

*---------------------------------------------------------------------
* Lagrangian dual
* Let assign_passenger be the complicating constraint
*---------------------------------------------------------------------
parameter u(p);
variable z_bound;
equation obj_lr;
obj_lr..
         z_bound=e=sum((g,s),c(g,s)*x(g,s))
                 +sum(p,u(p)*(1-sum((g,s),a(g,p,s)*x(g,s))));
model model_lr /obj_lr,assign_pattern/;
*---------------------------------------------------------------------
* subgradient iterations
*---------------------------------------------------------------------

set iter /iter1*iter60/;
scalar continue /1/;
parameter stepsize;
scalar theta /2/;
scalar noimprovement /0/;
scalar bestbound /-INF/;
parameter gamma(p);
scalar norm;
scalar upperbound;
parameter uprevious(p);
scalar deltau;
scalar k/1/;
parameter results(iter,*);
*
* initialize u with relaxed duals
*
u(p) = assign_passenger.m(p);
u(p)=2;
display u;

*
* an upperbound on L
*
scalar bFeasibleFlag;

*upperbound = sum((g,s),c(g,s)*initx(g,s));
upperbound=200;
display upperbound;

loop(iter$continue,
*
* solve the lagrangian dual problem
*
    option optcr=0;
    option limrow = 0;
    option limcol = 0;
*    model_lr.solprint = 0;
    solve  model_lr using mip minimizing z_bound;
    results(iter,'dual_bound') = z_bound.l;


    if (z_bound.l > bestbound,
         bestbound = z_bound.l;
         display bestbound;
         noimprovement = 0;
    else
         noimprovement = noimprovement + 1;
         if (noimprovement > 1,
            theta = theta/2;
            noimprovement = 0;
         );
    );

    results(iter,'noimprov') = noimprovement;
    results(iter,'theta') = theta;
*
* calculate step size
*
    gamma(p) = 1-sum((g,s),a(g,p,s)*x.l(g,s));
    norm = sum(p,sqr(gamma(p)));
    stepsize = theta*(upperbound-z_bound.l)/norm;
    results(iter,'norm') = norm;
    results(iter,'step') = stepsize;
    display gamma;


    bFeasibleFlag=1;
    if (norm <> 0,
       bFeasibleFlag = -1;
    else
       upperbound=z_bound.l;
    );
    results(iter,'low_bound') = bestbound;
    results(iter,'up_bound')=upperbound;
*
* update duals u
*
    uprevious(p) = u(p);

*    stepsize=1/k;
    u(p) = max(0, u(p)+stepsize*gamma(p));
    k=k+1;
    display u;
*
* converged ?
*
    deltau = smax(p,abs(uprevious(p)-u(p)));
    results(iter,'deltau') = deltau;
    if( deltau < 0.01,
         display "Converged";
         display x.l;
         continue = 0;
    );
);

display results;

****out put
File output_results_x  /'gams_out_x.txt'/;
put output_results_x;
loop((g,s)$(x.l(g,s)=1), put @1, g.tl, @5,s.tl, @10,x.l(g,s)/);

File output_results_lr /'gams_out_lr.txt'/;
put output_results_lr;
put          @1,'iter',@10,'dual_bound',@24,'low_bound',@45,'up_bound' /;
loop(iter,
         put @1,iter.tl, @10,results(iter,'dual_bound'), @20, results(iter,'low_bound') ,@40, results(iter,'up_bound') /
    );
