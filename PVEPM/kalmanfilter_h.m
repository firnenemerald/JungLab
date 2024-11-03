function result = kalmanfilter_h(inputdata)

head_x = inputdata(:,1);
head_y = inputdata(:,2);
head_likelihood = inputdata(:,3);

x = [head_x(1); head_y(1); 0; 0]; 
P = eye(4);                     

time =[ 0:1/29.99:1/29*size(inputdata,1)]';
dt = mean(diff(time)); 
F = [1 0 dt 0; 0 1 0 dt; 0 0 1 0; 0 0 0 1]; 
H = [1 0 0 0; 0 1 0 0];


Q = 0.1 * eye(4); 
R_base = 1;       

filtered_x = zeros(size(head_x));
filtered_y = zeros(size(head_y));

for i = 2:length(head_x)
    R = R_base / head_likelihood(i);
    
    x = F * x;
    P = F * P * F' + Q;
    
    z = [head_x(i); head_y(i)]; 
    y = z - H * x;              
    S = H * P * H' + R * eye(2); 
    K = P * H' / S;              
    x = x + K * y;               
    P = (eye(4) - K * H) * P;    
  
    
    filtered_x(i) = x(1);
    filtered_y(i) = x(2);
end

result = [filtered_x,filtered_y];