$ontext

    vehicle and passenger partition problem
    junhua Chen.   cjh@bjtu.edu.cn
    5/27,2016

$offtext

set g 'group';
set p 'passenger';
scalar max_p;
scalar max_g;
parameter c(p,g);



binary variable x(p,g);
binary variable y(g);
variable z;

equations
         obj_main,
         p_once_constrain(p),
         p_in_group_constrain(g),
         g_number_constrain,
         xy_connect(g)
;
obj_main..
         z=e=sum((p,g),c(p,g)*x(p,g));
p_once_constrain(p)..
         sum(g,x(p,g))=e=1;
p_in_group_constrain(g)..
         sum(p,x(p,g))=l=max_p*y(g);
g_number_constrain..
         sum(g,y(g))=l=max_g;
xy_connect(g)..
         sum(p,x(p,g))=g=y(g);

model model_group / obj_main,
         p_once_constrain,
         p_in_group_constrain,
         g_number_constrain,
         xy_connect
         /;

*****input data

$include "..\gams_group_p_input.txt";

************

solve model_group minimizing z using MIP;
display x.l;
display y.l;
display z.l;

*************************************
**output

File output_results_x  /'..\gams_group_p_output.txt'/;
put output_results_x;
loop((p,g)$(x.l(p,g)=1), put @1, p.tl, @5,g.tl, @10, x.l(p,g)/);