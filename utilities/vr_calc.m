function vr = vr_calc( xx, yy )
%VR_CALC Calculates the variance reduction between two vectors x and y
%  Perfect fit is 100%, no fit is 0% and complete opposite is -100%
% //variance reduction between xx and yy
% double vr_calc(int n, double *xx, double *yy) {
%    
%     /*calculate variance reduction between x and y*/
%     /* local variables */
%     int i, j=0;
%     double sum_xx, sum_yy, avg_xx, avg_yy;
%     double var_xx, var_yy, cov_xy;
%     double se_xx, se_yy;
%     double pvr;
%    
%     /* compute the average value for x and y */
%     sum_xx = 0.0;
%     sum_yy = 0.0;
%     for (i=0; i<n; i++) {
%         sum_xx = sum_xx + xx[j];
%         sum_yy = sum_yy + yy[j];
%         j++;
%     }
%     avg_xx = sum_xx / (float) j;
%     avg_yy = sum_yy / (float) j;
%    
%     /* initialize component variance */
%     var_xx = 0.0;
%     var_yy = 0.0;
%    
%     /* remove mean and sum squares */
%     for (i=0; i<n; i++) {
%         var_xx = var_xx + ((xx[i] - avg_xx) * (xx[i] - avg_xx));
%         var_yy = var_yy + ((yy[i] - avg_yy) * (yy[i] - avg_yy));
%     }
%    
%     /* compute standard error */
%     se_xx = sqrt(var_xx);
%     se_yy = sqrt(var_yy);
% 
%     /* initialize the output variances */
%     var_xx = 0.0;
%     var_yy = 0.0;
%     cov_xy = 0.0;
% 
%     /* sum up the x, y, and co variances */
%     for (i=0; i<n; i++) {
%         cov_xy = cov_xy + (((xx[i]-avg_xx) / se_xx) * ((yy[i]-avg_yy) / se_yy));
%         var_xx = var_xx + (((xx[i]-avg_xx) / se_xx) * ((xx[i]-avg_xx) / se_xx));
%         var_yy = var_yy + (((yy[i]-avg_yy) / se_yy) * ((yy[i]-avg_yy) / se_yy));
%     }
%    
%     /* compute return value */
%     pvr = 100.0 * cov_xy;
% 
%     return pvr;
% } // end vr_calc subroutine
% //END

if size(xx,2) ~= size(yy,2)
    disp('Error, vectors xx and yy must be the same size.')
    return
end

sum_xx = 0;
sum_yy = 0;
n=size(xx,2);
j=0;
for i=1:n
    j=j+1;
    sum_xx = sum_xx + xx(j);
    sum_yy = sum_yy + yy(j);
end

avg_xx = sum_xx / j;
avg_yy = sum_yy / j;

var_xx = 0.0;
var_yy = 0.0;
for i=1:n
    var_xx = var_xx + ((xx(i) - avg_xx) * (xx(i) - avg_xx));
    var_yy = var_yy + ((yy(i) - avg_yy) * (yy(i) - avg_yy));
end

se_xx = sqrt(var_xx);
se_yy = sqrt(var_yy);

var_xx = 0.0;
var_yy = 0.0;
cov_xy = 0.0;

for i=1:n
    cov_xy = cov_xy + (((xx(i)-avg_xx) / se_xx) * ((yy(i)-avg_yy) / se_yy));
    var_xx = var_xx + (((xx(i)-avg_xx) / se_xx) * ((xx(i)-avg_xx) / se_xx));
    var_yy = var_yy + (((yy(i)-avg_yy) / se_yy) * ((yy(i)-avg_yy) / se_yy));
end
   
vr = 100.0 * cov_xy;

end

