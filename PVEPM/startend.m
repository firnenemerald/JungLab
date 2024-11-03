function result = startend(inputdata)
endind = inputdata(find(diff(inputdata)>1));
startind = inputdata(find(diff(inputdata)>1)+1);
startind = [inputdata(1,1);startind(1:end-1)];
result = [startind,endind];
end