%% function windowedData = FL_applyHannTaper(inputData, halfPercentOfTrace)
%  Applies a symmetric Hann taper on the two sides of the vector data
% Rob Porritt, July 2014

function windowedData = FL_applyHannTaper(inputData, halfPercentOfTrace)

if halfPercentOfTrace > 50
    halfPercentOfTrace = 50;
end


%  Old version doesn't always return symmetric taper!
% 
% windowedData = inputData;
% 
% f0 = 0.5;
% f1 = 0.5;
% omega = pi / (length(inputData) * halfPercentOfTrace/100);
% 
% windowLength = round(length(inputData) * halfPercentOfTrace/100);
% 
% % front
% for iwin=1:windowLength
%     windowedData(iwin) = inputData(iwin) * (f0 - f1 * cos(omega*(iwin-1)));
% end
% 
% % back
% % for iwin=length(inputData)-windowLength:length(inputData)
% %     windowedData(iwin) = inputData(iwin) * (f0 - f1 * cos(omega*(iwin-1)));
% % end

f0 = 0.5;
MyWindow = ones(1,length(inputData));
nptsWin = round(length(inputData) * halfPercentOfTrace/100);
for iwin=1:nptsWin
    MyWindow(iwin) = f0 * (1 - cos((pi*iwin)/nptsWin));
end
jwin=1;
for iwin=length(inputData):-1:length(inputData)-nptsWin+1
    MyWindow(iwin) = MyWindow(jwin);
    jwin = jwin+1;
end

windowedData = inputData .* MyWindow;




end