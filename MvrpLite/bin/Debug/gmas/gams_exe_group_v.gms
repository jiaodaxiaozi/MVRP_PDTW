$ontext

    vehicle group problem
    junhua Chen.   cjh@bjtu.edu.cn
    5/28,2016

$offtext

set g 'groups';
set v 'vehicles';
scalar max_v;
scalar group_number;

parameter p_number(g);
parameter c(v,g);



binary variable x(v,g);
binary variable y(g);
variable z;

equations
         obj_main,
         v_once_constrain(v),
         v_in_group_constrain_1(g),
         v_in_group_constrain_2(g)
;
obj_main..
         z=e=sum((v,g),c(v,g)*x(v,g));
v_once_constrain(v)..
         sum(g,x(v,g))=e=1;
v_in_group_constrain_1(g)..
         sum(v,x(v,g))=l=max_v;
v_in_group_constrain_2(g)..
         sum(v,x(v,g))=l=p_number(g);

model model_group / obj_main,
         v_once_constrain,
         v_in_group_constrain_1,
         v_in_group_constrain_2
         /;

*****input data

$include "..\gams_group_v_input.txt";

************

solve model_group minimizing z using MIP;
display x.l;
display z.l;

*************************************
**output

File output_results_x  /'..\gams_group_v_output.txt'/;
put output_results_x;
loop((v,g)$(x.l(v,g)=1), put @1, v.tl, @5,g.tl, @10, x.l(v,g)/);
