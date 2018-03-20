function result = prfm_tPs( depth, eta_p, eta_s )
% prfm_tPs( depth, eta_p, eta_s )
% time taken for Ps conversion
result = ( eta_s - eta_p )*depth;
