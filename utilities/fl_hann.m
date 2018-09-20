function arrOut = fl_hann( npts )
% Simple hann taper to replace the signal processing hann taper routine
arrOut=ones(1,npts(1));
f0 = 0.5;
f1 = 0.5;
omega = 2*pi / npts(1);

% front
for iwin=1:npts(1)
    arrOut(iwin) = f0 - f1 * cos(omega*(iwin-1));
end


end

