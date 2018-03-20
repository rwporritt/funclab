%%  function [newmean, newsdsd] = recursive_mean_sd(new_value, old_mean, prev_sd, n)
% function [mean, sd] = recursive_mean_sd(new_value, old_mean, prev_sd, n)
% Calculates the mean and standard deviation recursively
% For use in a loop to avoid making arrays

% Based on a c program with the full listing:
% //compute a mean value recursively
% double recursive_mean(double new_value, double old_mean, int n) {
%         if (n >= 1 ) {
%                 return (1 / (double) n) * (( (double) n-1) * old_mean + new_value);
%         } else {
%                 return new_value;
%         }
% }
% //END
% 
% //compute a standard deviation recursively
% double recursive_standard_deviation(double new_value, double current_mean, double prev_value, int n) {
%         double temp=0.0, new_sd=0.0;
%         if (n > 1) {
%                 temp = (prev_value * prev_value * ((double) n-2)) + ((double) n/( (double) n-1)) * (current_mean - new_value) * (current_mean - new_value);
%                 new_sd = sqrt(temp/((double) n-1));
%         } else {
%                 //fprintf(stderr,"Recursive_standard_deviation error: n must be greater than 1! n: %d\n",n);
%                 new_sd = 0.0;
%         }
%         return new_sd;
% }
% //END
% 
% int main (int argc, char *argv[]) {
% 
%     int count=0;
%     double tmpval=0, tmpmean=0, tmpsd=0;
%     char InputFileName[300], buff[300];
%     FILE *inputFile;
% 
%     if (argc != 2) {
%         fprintf(stderr,"Usage: %s singleColumnValuesFile\n",argv[0]);
%         fprintf(stderr,"Reads the single column file and outputs the mean and standard deviation.\n");
%         exit(1);
%     }
% 
%     sscanf(argv[1],"%s",InputFileName);
%     if ((inputFile = fopen(InputFileName,"r")) == NULL) {
%         fprintf(stderr,"Error, file %s not found!\n",InputFileName);
%         exit(1);
%     }
% 
%     count = 0;
%     while(fgets(buff,300,inputFile)) {
%         sscanf(buff,"%lf",&tmpval);
%         count = count + 1;
%         tmpmean = recursive_mean(tmpval, tmpmean, count);
%         tmpsd = recursive_standard_deviation(tmpval, tmpmean, tmpsd, count);
%     }
% 
%     fclose(inputFile);
% 
%     fprintf(stdout,"%lf %lf\n",tmpmean, tmpsd);
% 
%     return 0;
% }



function [newmean, newsd] = recursive_mean_sd(new_value, old_mean, prev_sd, n)
    if (n >= 1 )
        newmean = (1 / n) * ((n-1) * old_mean + new_value);
    else
        newmean =  new_value;
    end

    if n > 1 
        temp = (prev_sd * prev_sd * (n-2)) + (n/(n-1)) * (newmean - new_value) * (newmean - new_value);
        newsd = sqrt(temp/(n-1));
    else
        newsd = 0.0;
    end
    