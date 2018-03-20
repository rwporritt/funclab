function smoothedMatrix = smooth_nxm_matrix(roughMatrix, nxsmooth, nysmooth)
% function smoothedMatrix = smooth_nxm_matrix(roughMatrix, nxsmooth, nysmooth)
%
% given a matrix of nxm points, runs an inverse to distance weighted average smoothing
%

% Get dimensions of matrix and allocate output matrix
[nx, ny] = size(roughMatrix);
smoothedMatrix = roughMatrix;

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

if nysmooth < 1
    disp('Error, nysmooth less than 1!')
    return
end



for x=1:nx
    for y=1:ny

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
        
        if (y-floor(nysmooth)/2) < 1
            y_start = 1;
        else
            y_start = y-floor(nysmooth/2);
        end
        
        if (x+floor(nxsmooth/2) > nx)
            x_end = nx;
        else
            x_end = x+floor(nxsmooth/2);
        end
        
        if (y+floor(nysmooth/2) > ny)
            y_end = ny;
        else
            y_end = y+floor(nysmooth/2);
        end
        
        % find weight and add to mean
        for xx=x_start:x_end
            for yy=y_start:y_end
                
                if ( x == xx && y == yy) 
                    weight = 1.5;
                else
                    distance = sqrt((xx-x)^2 + (yy-y)^2);
                    weight = 1/distance;
                end
                
                %fprintf('x: %d y: %d xx: %d yy: %d weight: %f\n',x,y,xx,yy,weight);
                if (~isnan(roughMatrix(xx,yy)) && ~isinf(roughMatrix(xx,yy)))
                    sum = sum + (weight * roughMatrix(xx,yy));
                    totalWeight = totalWeight + weight;
                end
            end
        end
        smoothedMatrix(x,y) = sum/totalWeight;
        
    end
end
