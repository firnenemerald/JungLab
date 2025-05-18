function [tcorrdat] = fn_corrcoef(Neurons_cin,cellProps)

meancor=[];meanabscor=[];
    corrdat=[];corrp=[];tempcorrdat=[];tempcorrp=[];corrdatd1=[];corrpd1=[];
    cellProps = cell2mat(cellProps);
    for i=1:size(Neurons_cin,2)
        for j=i+1:size(Neurons_cin,2)
            [R1, p1] = corrcoef(Neurons_cin(:,i),Neurons_cin(:,j)); % motor correlation
            dist = sqrt((cellProps(i,1)-cellProps(j,1))^2 + (cellProps(i,2)-cellProps(j,2))^2);
            xdist = cellProps(i,1)-cellProps(j,1);
            ydist = cellProps(i,2)-cellProps(j,2);
            
            tempcorrdat = [R1(1,2) dist*5 xdist*5 ydist*5];  
            tempcorrp = [p1(1,2)];
            corrdatd1 = [corrdatd1;tempcorrdat];
            corrpd1 = [corrpd1 ; tempcorrp];
        end
    end
    corrdatd11 = corrdatd1;
    tcorrdat = {corrdatd11};
%     meancor = mean(tcorrdat(:,1));
    corrdatd11=[];

end