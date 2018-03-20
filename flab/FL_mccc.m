function [tdel] = FL_mccc(seis,dt,twin);

% Function MCCC determines optimum relative delay times for a 
% set of seismograms based on the VanDecar & Crosson multi-channel
% cross-correlation algorithm. SEIS is the set of seismograms
% arranged such that columns are time samples and rows are stations. It
% is assumed that this set includes the window of interest and 
% nothing more since we calculate the correlation functions in the
% Fourier domain. DT is the sample interval and TWIN is the window
% about zero in which the maximum search is performed (if TWIN is
% not specified, the search is performed over the entire correlation
% interval).

% Set nt to twice length of seismogram section to avoid 
% spectral contamination/overlap. Note we assume that 
% columns enumerate time samples, and rows enumerate stations.
nt=size(seis,2)*2;
ns=size(seis,1);
tcc=zeros(ns);

% Set width of window around 0 time to search for maximum.
mask=ones(1,nt);
if nargin == 3
  itw=fix(twin/(2*dt));
  mask=zeros(1,nt);
  mask(1:itw)=1.0;
  mask(nt-itw-1:nt)=1.0;
end

% Determine relative delay times between all pairs of
% traces.
for is=1:ns-1
  ffis=conj(fft(seis(is,:),nt));
  for js=is+1:ns
    ffjs=fft(seis(js,:),nt);
    ccf=real(ifft([ffis.*ffjs],nt)).*mask;
    [cmax,tcc(is,js)]=max(ccf);
  end    
end

% Correct negative delays.
ix=find(tcc>nt/2);
tcc(ix)=tcc(ix)-(nt+1);

% Multiply by sample rate.
tcc=tcc*dt;

% Use sum rule to assemble optimal delay times with zero mean.
for is=1:ns
  tdel(is)=(-sum(tcc(1:is-1,is))+sum(tcc(is,is+1:ns)))/ns;
end