%% function windowedData = FL_applyHammingTaper(inputData, halfPercentOfTrace)
%  Applies a symmetric Hann taper on the two sides of the vector data
% Rob Porritt, July 2014

function windowedData = FL_applyHammingTaper(inputData, halfPercentOfTrace)

if halfPercentOfTrace > 50
    halfPercentOfTrace = 50;
end

windowedData = inputData;

f0 = 0.54;
f1 = 0.46;
omega = pi / (length(inputData) * halfPercentOfTrace/100);

windowLength = round(length(inputData) * halfPercentOfTrace/100);

MyWindow = ones(1,length(inputData));

% front
for iwin=1:windowLength
    MyWindow(iwin) = f0 - f1 * cos(omega*(iwin-1));
end

% back
jwin = 1;
for iwin=length(inputData):-1:length(inputData)-nptsWin+1
    MyWindow(iwin) = MyWindow(jwin);
    jwin = jwin+ 1;
end


windowedData = inputData .* MyWindow;



end