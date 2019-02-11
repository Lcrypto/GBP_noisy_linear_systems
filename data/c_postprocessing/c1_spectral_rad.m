 function [bp] = c1_spectral_rad(user, bp)


 
%------------------------Coefficient Matrix--------------------------------
 Ja = bp.Aind';
 H  = spdiags(nonzeros(Ja), 0, bp.Nmsg, bp.Nmsg);
 Hi = (H \ speye([bp.Nmsg bp.Nmsg]));
%--------------------------------------------------------------------------


%-------------------Messages Variance fv Matrix----------------------------
 v_fv_i = sparse(bp.row, bp.col, bp.v_fvi, bp.Nind, bp.Nvar);
 Vfv    = v_fv_i';
 Vi     = spdiags(nonzeros(Vfv), 0, bp.Nmsg, bp.Nmsg);
%-------------------------------------------------------------------------- 


%-------------------------Computational Matrix Sf--------------------------
 nu = reshape(cumsum(reshape(bp.Inc', 1, [])), [bp.Nvar bp.Nind])';
 id = nu .* full(bp.Inc);

 [i, ~] = find(id'); 
 col    = id(:,i);
 [~, j] = find(col);

 idx = [j nonzeros(col)];
 d   = j ~= nonzeros(col);
 idx = idx(d,:);

 Sf = sparse(idx(:,1),idx(:,2), 1, bp.Nmsg, bp.Nmsg);
%--------------------------------------------------------------------------


%---------------------Local Variances Matrix Vd----------------------------
 l  = spdiags(1 ./ bp.vloc, 0, bp.Nvar, bp.Nvar);
 li = (l * bp.Inc')';
 ij = nonzeros(id);
 Vd = sparse(ij, ij, nonzeros(li), bp.Nmsg, bp.Nmsg);
%--------------------------------------------------------------------------


%-----------------------Constant Equation Parts----------------------------
 idx = find(H);
 
 M = Sf * Vi * Sf';
 M = spdiags(M(idx), 0, bp.Nmsg, bp.Nmsg);
 
 VdM = Vd + M; 
 W   = spdiags(1 ./ VdM(idx), 0, bp.Nmsg, bp.Nmsg);
%--------------------------------------------------------------------------


%-------------------------Computational Matrix Sx--------------------------
 c   = sum(bp.Inc, 2);
 n   = size(c,1); 
 tmp = cell(n,1);
 
 for i = 1:n
     tmp{i} = 1 - speye(c(i));   
 end
 Sx = sparse(blkdiag(tmp{:}));
%--------------------------------------------------------------------------


%--------------Spectral Radius for Synchronous Scheduling------------------
 Ome_syn = Hi * Sx * H * W * Sf' * Vi;
  
 opts.tol   = 1e-14;
 opts.maxit = 500;
 try
    bp.rho_syn = abs(eigs(Ome_syn,1,'lm',opts));
 catch
    warning('EIGS Failed. EIG is is used.');
    bp.rho_syn = max(abs(eig(full(Ome_syn))));
 end 
%--------------------------------------------------------------------------


%------------Spectral Radius for Randomized Damping Scheduling-------------
 mix = bp.idx(bp.wow);
 wow = id(mix);

 Q = speye([bp.Nmsg bp.Nmsg]);
 Q(wow, wow) = 0; 
  
 R = speye([bp.Nmsg bp.Nmsg]) - Q;
 
 Ome_rda = Q * Ome_syn + (1 - user.alph) * R * Ome_syn - user.alph * R; 
 
 try
    bp.rho_rda = abs(eigs(Ome_rda,1,'lm',opts));
 catch
    warning('EIGS failed. EIG is used.');
    bp.rho_rda = max(abs(eig(full(Ome_rda))));
 end 
%--------------------------------------------------------------------------