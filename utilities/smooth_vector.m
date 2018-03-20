function smoothedVector = smooth_vector(roughVector, nxsmooth)
% function smoothedVector = smooth_vector(roughVector, nxsmooth)
%
% given a vector of n points, runs an inverse to distance weighted average smoothing
%

% Get dimensions of matrix and allocate output matrix
[nx, ny] = size(roughVector);
if nx ~= 1 && ny ~= 1
    disp('smooth_vector: Error, need to have 1xn vector as input')
elseif nx == 1 && ny == 1
    disp('smooth_vector: Error, only 1 value in vector')
    smoothedVector = roughVector;
    return
end
smoothedVector = roughVector;

% Check dimensions given
if nx < 1
    disp('Error, nx less than 1!')
    return
end

if ny < 1
    disp('Error, ny less than 1!')
    return
end

if nxsmooth < 1
    disp('Error, nxsmooth less than 1!')
    return
end

for x=1:nx

    % Init
    %weight = 0.0;
    sum=0.0;
    %count = 0;
    totalWeight = 0.0;

    % Find min/max of smoothing window
    if (x-floor(nxsmooth/2) < 1)
        x_start = 1;
    else
        x_start = x-floor(nxsmooth/2);
    end


    if (x+floor(nxsmooth/2) > nx)
        x_end = nx;
    else
        x_end = x+floor(nxsmooth/2);
    end
     % find weight and add to mean
    for xx=x_start:x_end
        if ( x == xx) 
            weight = 1.5;
        else
            distance = sqrt((xx-x)^2);
            weight = 1/distance;
        end

        %fprintf('x: %d y: %d xx: %d yy: %d weight: %f\n',x,y,xx,yy,weight);
        if (~isnan(roughVector(xx)) && ~isinf(roughVector(xx)))
            sum = sum + (weight * roughVector(xx));
            totalWeight = totalWeight + weight;
        end
    end
    smoothedVector(x) = sum/totalWeight;

end
