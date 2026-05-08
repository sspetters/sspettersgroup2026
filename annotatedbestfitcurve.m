function quicklook
% A function (no inputs/outputs) that scans the current directory (the
% current folder that you have this code in is the directory),
% processes all valid .csv files, fits aerosol size distributions,
% and plots individual + global average curves.

%To run this function you need to have numberDist_dN_dD.m 
%and 
%numberDist_dN_dlogD.m downloaded in the same folder

% Initializes two empty column vectors that will grow inside the loop
% to accumulate x (diameter) and y (concentration) data from ALL files.
all_x_data = [];   % [] creates an empty matrix; will be appended with [a; b] (vertical concat)
all_y_data = [];

% dir with no arguments returns a struct array describing every item
% (files AND folders) in the current working directory.
% Each element has fields: .name, .folder, .date, .bytes, .isdir, .datenum
list = dir;

% colormap(hsv(N)) generates an N-row matrix of RGB colors cycling through
% the hue-saturation-value rainbow. One distinct color per file.
clr1 = colormap(hsv(length(list)));  % length(list) = total number of items in dir

% Outer loop: LL is the index stepping through every item returned by dir
for LL = 1:length(list)

    % contains(str, pattern) returns true if pattern is found inside str.
    % ~ is logical NOT. So: skip this item if its name does NOT contain '.csv'
    if ~contains(list(LL).name, '.csv'); continue; end

    % Skip files whose names contain 'out' — these are output files we wrote
    if contains(list(LL).name, 'out'); continue; end

    % Skip files whose names contain '#' — likely temp/corrupt files
    if contains(list(LL).name, '#'); continue; end

    % .name is the filename string from the dir struct
    filename = list(LL).name;

    % fopen(filename, 'r') opens the file in read-only mode.
    % Returns an integer file identifier (fid). If it fails, fid = -1.
    fid = fopen(filename, 'r');

    % fgetl(fid) reads one line from the file as a character vector,
    % stripping the newline character. Returns -1 (numeric) at end-of-file.
    tline = fgetl(fid);

    % Tracks which line of the file we're on (used to skip the header row)
    linecount = 1;

    % Square-bracket string concatenation: builds 'filename.csv.out'
    outname = [filename '.out'];

    % fopen(outname, 'w') opens (or creates) the output file for writing.
    % 'w' mode overwrites any existing file with the same name.
    fout = fopen(outname, 'w');

    % ischar(tline) is true when tline is a character vector (a real line).
    % At end-of-file, fgetl returns the number -1, so ischar returns false,
    % ending the loop cleanly.
    while ischar(tline)

        % strfind(str, pattern) returns a row vector of starting indices
        % where the pattern (here ',') occurs inside str.
        % icomma is used below to locate each column boundary.
        icomma = strfind(tline, ',');

        % Extract the text between the 4th and 5th commas (column 5 raw = stateDMA1).
        % icomma(4)+1 is the character right after the 4th comma;
        % icomma(5)-1 is the character right before the 5th comma.
        stateDMA1 = tline(icomma(4)+1 : icomma(5)-1);

        % switch/case converts the text state label into a numeric string.
        % 'CLASSIFIER' → '1'; anything else → '2'
        switch(stateDMA1)
            case 'CLASSIFIER';  stateDMA1 = '1';
            otherwise;          stateDMA1 = '2';
        end

        % Same extraction for stateDMA2: between the 8th and 9th commas.
        stateDMA2 = tline(icomma(8)+1 : icomma(9)-1);

        % Map four known scan-phase labels to numeric strings 1-4; else 5.
        switch(stateDMA2)
            case 'UPSCAN';   stateDMA2 = '1';
            case 'UPHOLD';   stateDMA2 = '2';
            case 'DOWNSCAN'; stateDMA2 = '3';
            case 'DONE';     stateDMA2 = '4';
            otherwise;       stateDMA2 = '5';
        end

        % linecount > 1 skips the header row (row 1), processing only data rows.
        if linecount > 1

            % Slice out columns 2-4 (between comma 1 and comma 4), 
            % dropping the timestamp string in column 1 which load() can't parse.
            tline2 = tline(icomma(1)+1 : icomma(4)-1);

            % Columns 6-8: between comma 5 and comma 8
            tline3 = tline(icomma(5)+1 : icomma(8)-1);

            % Columns 10 onward: from comma 9 to end of line
            tline4 = tline(icomma(9)+1 : end);

            % Reassemble the line with the numeric state strings replacing
            % the original text labels. Square brackets concatenate strings;
            % commas between variables are literal comma characters here.
            tline = [tline2 ',' stateDMA1 ',' tline3 ',' stateDMA2 ',' tline4];

            % fprintf(fid, format, data) writes formatted text.
            % '%s\n' = print the string tline followed by a newline character.
            % No fid argument here → prints to the Command Window (stdout).
            fprintf('%s\n', tline);

            % Same format, but fout directs output to the .out file on disk.
            fprintf(fout, '%s\n', tline);
        end

        % Increment line counter before reading the next line
        linecount = linecount + 1;

        % Advance fid to the next line; overwrites tline each iteration.
        % When EOF is reached this returns -1, failing ischar() and exiting the while loop.
        tline = fgetl(fid);
    end

    % fclose(fid) releases the file handle for the input .csv.
    % Always close files you've opened to avoid resource leaks.
    fclose(fid);
    fclose(fout);   % Close the output .out file as well

    % load(filename) reads a whitespace/comma-delimited numeric text file
    % into a 2-D double matrix. Each row = one time step; each column = one variable.
    data = load(outname);

    % Index into the matrix columns by number to name each variable
    ptime       = data(:,1);   % (:) selects every row; ,1 selects column 1
    Int64time   = data(:,2);
    LapseTime   = data(:,3);
    stateDMA1   = data(:,4);
    voltageSetDMA1  = data(:,5);
    voltageReadDMA1 = data(:,6);
    currentDiameterDMA1 = data(:,7);
    stateDMA2       = data(:,8);
    voltageSetDMA2  = data(:,9);
    voltageReadDMA2 = data(:,10);
    currentDiameterDMA2 = data(:,11);
    TESet           = data(:,12);
    TE1ReadT1       = data(:,13);
    TE1ReadT2       = data(:,14);
    N1cpcCount      = data(:,15);
    N2cpcCount      = data(:,16);
    N1cpcSerial     = data(:,17);
    N2cpcSerial     = data(:,18);
    RH1             = data(:,19);
    RH2             = data(:,20);

    % figure(1) makes figure window 1 the place for all plot commands.
    % hold on keeps existing plots in the figure instead of erasing them.
    figure(1); hold on;

    % plot(x, y, marker, PropertyName, Value, ...)
    % '.'        → single-pixel dot marker (no connecting line)
    % 'Color'    → sets the marker/line color; clr1(LL,:) picks row LL from
    %              the colormap (a 1×3 [R G B] vector)
    % 'DisplayName' → label string shown in the legend for this series
    plot(currentDiameterDMA2, N2cpcSerial, '.', 'Color', clr1(LL,:), 'DisplayName', filename);

    % Copy the two data columns for cleaner variable names before filtering
    xData = currentDiameterDMA2;
    yData = N2cpcSerial;

    % Build a logical index vector: true only where both x and y are
    % positive (required for log-space fitting) AND neither is NaN.
    % & is element-wise logical AND across equal-length vectors.
    validIdx = (xData > 0) & (yData > 0) & ~isnan(xData) & ~isnan(yData);

    % Apply the logical mask: keeps only rows where validIdx is true
    xClean = xData(validIdx);
    yClean = yData(validIdx);

    % Vertical concatenation [A; B] appends xClean below whatever is
    % already in all_x_data, growing the global pool one file at a time.
    all_x_data = [all_x_data; xClean];
    all_y_data = [all_y_data; yClean];

    % Initial guess vector [Dbar, sigma_g, N] passed to the solver.
    % The solver starts its search from these values.
    param0 = [150, 1.5, 1000];

    % Lower bounds for each parameter — solver will never go below these.
    lb = [10, 1.01, 1];

    % Upper bounds for each parameter — solver will never exceed these.
    ub = [1000, 3.0, 1e6];   % 1e6 = 1,000,000 in scientific notation

    % optimoptions creates an options object for the named solver.
    % 'Display','off' suppresses the per-iteration text output in the Command Window.
    options = optimoptions('lsqcurvefit', 'Display', 'off');

    % try/catch lets the loop continue even if lsqcurvefit fails on a bad file.
    try
        % lsqcurvefit(fun, x0, xdata, ydata, lb, ub, options)
        % Finds the parameter vector that minimizes sum((fun(params,xdata) - ydata).^2)
        % fun            = @numberDist_dN_dlogD, a function handle to the model
        % x0 = param0    = starting parameter guess
        % xdata = xClean = independent variable (diameter) data
        % ydata = yClean = observed dependent variable (concentration) data
        % lb, ub         = parameter bounds
        % options        = solver settings defined above
        fitParams = lsqcurvefit(@numberDist_dN_dlogD, param0, xClean, yClean, lb, ub, options);

        % logspace(a, b, N) generates N points evenly spaced on a log10 scale
        % from 10^a to 10^b. log10(min(...)) and log10(max(...)) set the range
        % to match the actual data extent. Transposed with ' to make a column vector.
        xFit = logspace(log10(min(xClean)), log10(max(xClean)), 200)';

        % Evaluate the fitted model at the 200 smooth x points
        yFit = numberDist_dN_dlogD(fitParams, xFit);

        % Plot the smooth fit line in the same color as the dots for this file.
        % 'HandleVisibility','off' excludes this line from the legend
        % so only the raw-data scatter entry appears.
        plot(xFit, yFit, '-', 'Color', clr1(LL,:), 'HandleVisibility', 'off');
    catch
        % If lsqcurvefit throws an error (e.g. too few points), print a warning
        % and move on without crashing the whole script.
        disp(['Could not fit curve for file: ', filename]);
    end

    % title, xlabel, ylabel set the text annotations on the active axes.
    title('Aerosol Size Distribution');
    xlabel('Electrical Mobility Diameter (nm)');
    ylabel('Particle Concentration (cm^{-3})');  % ^{-3} renders as a superscript in the label

    % gca = "get current axes" — returns a handle to the active axes object.
    % 'YScale','log' switches the y-axis to logarithmic spacing.
    % 'XScale','log' does the same for x. Both needed for a log-log plot.
    set(gca, 'YScale', 'log', 'XScale', 'log')

    % continue jumps immediately to the next iteration of the for loop,
    % skipping any code below (the commented-out figure 2 and 3 blocks).
    continue

end % end of the LL for-loop

% Sets y-axis of the current axes to log scale (redundant here but harmless)
set(gca, 'YScale', 'log')

% gcf = "get current figure" — returns a handle to the active figure window.
% 'Units','inch'          → interpret all subsequent size values in inches
% 'PaperPosition',[0 0 5 3] → when printing/saving, place the plot at
%                             (0,0) inches with width=5, height=3 inches
% 'PaperSize',[5 3]       → set the paper canvas itself to 5×3 inches
%                           (matches PaperPosition so there's no white border)
% 'Color','w'             → set the figure background color to white
% 'InvertHardcopy','off'  → do NOT auto-invert colors when saving to file
%                           (keeps your black lines black, white bg white)
set(gcf, 'Units', 'inch', 'PaperPosition', [0 0 5 3], 'PaperSize', [5 3], ...
    'Color', 'w', 'InvertHardcopy', 'off');

% 'Display','iter' makes lsqcurvefit print a table of residuals and
% step sizes to the Command Window on every iteration — useful for
% monitoring convergence of the global fit.
options = optimoptions('lsqcurvefit', 'Display', 'iter');

try
    param0 = [150, 1.5, 1000];
    lb = [10, 1.01, 1];
    ub = [1000, 3.0, 1e6];

    % Same lsqcurvefit call as inside the loop, but now using the giant
    % concatenated arrays (all files combined) instead of one file at a time.
    fitParamsAvg = lsqcurvefit(@numberDist_dN_dlogD, param0, all_x_data, all_y_data, lb, ub, options);

    % Build a smooth x vector spanning the full range of ALL collected data
    xFitAvg = logspace(log10(min(all_x_data)), log10(max(all_x_data)), 200)';

    % Evaluate the average-fit model at those 200 points
    yFitAvg = numberDist_dN_dlogD(fitParamsAvg, xFitAvg);

    figure(1); hold on;

    % '-k'         → solid black line (k = black in MATLAB color shorthand)
    % 'LineWidth',3 → draw the line 3 points thick so it stands out over
    %                 the thinner colored per-file lines
    % 'DisplayName' → this string appears in the legend for this series
    plot(xFitAvg, yFitAvg, '-k', 'LineWidth', 3, 'DisplayName', 'GLOBAL AVERAGE FIT');

    % legend('show') makes the legend visible.
    % 'Location','best' tells MATLAB to auto-pick the corner with the
    % least overlap with the plotted data.
    legend('show', 'Location', 'best');

    % \n in fprintf inserts a newline. %.2f formats a floating-point number
    % with exactly 2 decimal places. fitParamsAvg(1/2/3) indexes the
    % returned parameter vector: [Dbar, sigma_g, N].
    fprintf('\n--- GLOBAL AVERAGE FIT RESULTS ---\n');
    fprintf('Average Dbar: %.2f\n', fitParamsAvg(1));
    fprintf('Average s (sigma_g): %.2f\n', fitParamsAvg(2));
    fprintf('Average N: %.2f\n', fitParamsAvg(3));

% PRINT THE EQUATION OF THE BLACK LINE TO THE COMMAND WINDOW 
%I tried out Jose's suggestion of using Claude to generate this bit

fprintf('\n--- EQUATION OF THE BLACK LINE ---\n');
% fprintf() prints formatted text to the Command Window.
% The text inside the quotes '' is printed exactly as written,
% except for special codes that start with \ (called escape sequences):
%   \n = newline character (moves the cursor to the next line)
% So \n at the START adds a blank line before the header,
% and \n at the END moves to a new line after it.
% The --- dashes are just decorative, to make it easy to spot in the output.

fprintf('dN/d(logD) = log(10) * D * (N / (sqrt(2*pi) * s * D)) * exp( -(log(D) - log(Dbar))^2 / (2*s^2) )\n');
% This prints the UNSIMPLIFIED symbolic equation — showing every term
% explicitly so you can see exactly where each piece comes from:
%
%   log(10)          = ln(10) ≈ 2.3026, the chain rule conversion factor
%   D                = diameter (the variable, not a number)
%   N                = total particle concentration (fitted parameter 3)
%   sqrt(2*pi)       = the normalisation constant from the Gaussian/normal
%                      distribution (≈ 2.507), ensures area under curve = N
%   s                = log(sigma_g), the width parameter (fitted parameter 2)
%   D (in denominator) = cancels with the D in the numerator (shown in next line)
%   exp(...)         = e raised to the power of the bracketed term —
%                      this is the "bell curve" shape part of the equation
%   -(log(D)-log(Dbar))^2 / (2*s^2) = the exponent that controls the shape:
%       log(D) - log(Dbar) = distance of diameter D from the peak, in log space
%       squaring it         = makes it symmetric (same shape left and right of peak)
%       dividing by 2*s^2   = s controls how wide the bell is;
%                             larger s = wider curve, smaller s = narrower curve
%       negative sign        = flips it so the peak is a maximum, not a minimum
%
% The whole thing is just a lognormal probability distribution
% scaled by N (total particles) and converted to log-diameter space.
% \n at the end moves to the next line after printing.

fprintf('\nSimplified:\n');
% Prints a blank line (\n at start), then the word "Simplified:", then
% another new line. Just a readable section header.

fprintf('dN/d(logD) = (log(10) * N) / (sqrt(2*pi) * s) * exp( -(log(D) - log(Dbar))^2 / (2*s^2) )\n');
% This prints the SIMPLIFIED version of the same equation.
% The simplification: the D in the numerator and the D in the denominator
% of the unsimplified form cancel each other out:
%
%   log(10) * D * N / (sqrt(2*pi) * s * D)
%                             ↓
%   (log(10) * N) / (sqrt(2*pi) * s)     ← D cancels, cleaner to read
%
% This is the form that is actually computed inside numberDist_dN_dlogD.
% D only appears once now, inside the exp() term.

fprintf('\nWith fitted values substituted in:\n');
% Another section header. \n at the start = blank line before it.
% \n at the end = new line after it. Plain readable label.

fprintf('dN/d(logD) = (log(10) * %.2f) / (sqrt(2*pi) * %.4f) * exp( -(log(D) - log(%.2f))^2 / (2 * %.4f^2) )\n', ...
    fitParamsAvg(3), fitParamsAvg(2), fitParamsAvg(1), fitParamsAvg(2));
% This prints the equation again, but with the actual FITTED NUMBERS
% plugged in for N, s, and Dbar — so you get a concrete usable equation.
%
% HOW THE NUMBER FORMATTING WORKS:
% fprintf replaces each % code with the next number in the list after the comma.
% The codes and what they do:
%   %.2f = print a decimal number with exactly 2 digits after the decimal point
%   %.4f = print a decimal number with exactly 4 digits after the decimal point
%   f    = "fixed point" format (e.g. 4521.30, not 4.52130e+03)
%
% THE NUMBERS ARE INSERTED IN THIS ORDER (left to right):
%   fitParamsAvg(3) → N     → printed with %.2f  (2 decimal places, e.g. 4521.30)
%   fitParamsAvg(2) → s     → printed with %.4f  (4 decimal places, e.g. 1.8342)
%   fitParamsAvg(1) → Dbar  → printed with %.2f  (2 decimal places, e.g. 147.23)
%   fitParamsAvg(2) → s     → printed with %.4f  again (s appears twice in equation)
%
% NOTE: s is used TWICE in the equation (once in the front coefficient,
% once inside the exp() exponent), so fitParamsAvg(2) appears TWICE
% in the argument list.
%
% THE ... (ellipsis) at the end of the first line means "this MATLAB
% statement continues on the next line." It's just for readability —
% the line was getting too long to read comfortably in one line.
%
% EXAMPLE OUTPUT might look like:
% dN/d(logD) = (log(10) * 4521.30) / (sqrt(2*pi) * 1.8342) * exp( -(log(D) - log(147.23))^2 / (2 * 1.8342^2) )
catch
    % If the global fit fails (e.g. all_x_data is empty), print a message
    % rather than crashing.
    disp('Failed to calculate the global average fit.');
end