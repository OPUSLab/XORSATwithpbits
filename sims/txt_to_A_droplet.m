function [W,h] = txt_to_A_droplet(txtfile, varargin)

%% This function generates sparse A (W,h) matrix from txt file

fid = fopen(txtfile);
if fid<0
    return
end
k=1;
while ~feof(fid)
    tline = fgetl(fid);
    tline = strtrim(tline);
    if isempty(tline)
        continue;
    end
    
    if (tline(1)~= '#') % discard comments
        x = str2num(tline);
        if (x(1)==x(2))
            h(x(1))=x(3);
        else
            W(x(1),x(2))= x(3);
            W(x(2),x(1))= x(3);
        end
        
        k=k+1;
    end
    
end
fclose(fid);

h=h';
W=sparse(W);
end
