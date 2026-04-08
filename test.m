function test
clc
tic

fprintf('hello world\n\n');  % "f" print -> dumps a string to the command window
string1 = sprintf('hello1'); % "s" print -> saves a string

string1

% Create x, y 'data'
x = linspace(0,10,100)'; % create array
y = sin(x);

% FIRST PLOT
figure(1);clf;hold on;
plot(x,y,'-m')
plot(x,x,'og')

% Integrate under curve?
sum_of_areas = 0;
for ii = 2:15
    plot(x(ii),y(ii),'*r');
    width  = x(ii)-x(ii-1);
    height = mean( [ y(ii)    y(ii-1)] );
    sum_of_areas = sum_of_areas + width*height;
    rectangle('Position', [x(ii) 0 width height],  'FaceColor',[.5 0 .4])
end


% OPEN FILE
dat = load('data.txt'); % path can be long
x = dat(:,1); % assign x to column 1
y = dat(:,2);




% SECOND PLOT
figure(2);clf;hold on;
for ii = 1:length(x)
    plot(x(ii),y(ii),'ok','MarkerFaceColor',[47 255 25]/255);
    s1 = sprintf('%d',ii);
    text(x(ii),y(ii),s1)
end


elapsedt = toc
end