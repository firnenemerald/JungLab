function result=geteventonset(mobile_doric,gcamp)
for i = 1 : size(mobile_doric,1)
    result(i,:) = gcamp(mobile_doric(i,1)-60:mobile_doric(i,1)+60,1);
end
end