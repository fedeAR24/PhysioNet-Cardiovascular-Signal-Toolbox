function windowRRintervals = CreateWindowRRintervals(tNN, NN, HRVparams,option)
%
% windowRRintervals = CreateWindowRRintervals(NN, tNN, settings, options)
%   
%   OVERVIEW:   This function returns the starting time (in seconds) of 
%               each window to be analyzed.
%
%   INPUT:      tNN       : a single row of time indices of the rr interval 
%                           data (seconds)
%               NN        : a single row of NN (normal normal) interval
%                           data in seconds
%               HRVparams : struct of settings for hrv_toolbox analysis
%               option    : 'normal', 'af', 'sqi'
%               
%   OUTPUT:     windowRRintervals : array containing the starting time 
%                                   (in seconds) of each window to be
%                                   analyzed
%                                   
%
%   DEPENDENCIES & LIBRARIES:
%       HRV_toolbox https://github.com/cliffordlab/hrv_toolbox
%       WFDB Matlab toolbox https://github.com/ikarosilva/wfdb-app-toolbox
%       WFDB Toolbox s+https://physionet.org/physiotools/wfdb.shtml
%   REFERENCE: 
%	REPO:       
%       https://github.com/cliffordlab/hrv_toolbox
%   ORIGINAL SOURCE AND AUTHORS:     
%       Main script written by Adriana N. Vest
%       Dependent scripts written by various authors 
%       (see functions for details)   
%	COPYRIGHT (C) 2016 
%   LICENSE:    
%       This software is offered freely and without warranty under 
%       the GNU (v3 or later) public license. See license file for
%       more information
%%


% Verify input arguments

if nargin< 1
    error('Need to supply time to create windows')
end
if nargin<4 || isempty(HRVparams) 
     option = 'normal';
end

% Set Defaults

increment = HRVparams.increment;
windowlength = HRVparams.windowlength;
win_tol = HRVparams.win_tol;

switch option
    case 'af'
        increment = HRVparams.af.increment;
        windowlength = HRVparams.af.windowlength;
    case 'mse'
        increment = HRVparams.MSE.increment;
        windowlength = HRVparams.MSE.windowlength;
        if isempty(increment)
            windowRRintervals = 0;
            return % no need to crate windows , use entair signal
        end 
    case 'dfa'
        increment = HRVparams.DFA.increment;
        windowlength = HRVparams.DFA.windowlength;
        if isempty(increment)
            windowRRintervals = 0;
            return  % no need to crate windows , use entair signal
        end       
    case 'sqi'
        increment = HRVparams.sqi.increment;
        windowlength = HRVparams.sqi.windowlength;
end

% Initialize output matrix
windowRRintervals = [];

% Initialize loop variables
t_window_start = 0;     % Window Start Time
i = 1;                       % Counter

% for j = 1:(floor(tNN(end))-(windowlength))/increment
%     indicies = [];
%     try
%         indicies = find(tNN >= (j-1)*increment & tNN < windowlength+(j-1)*increment);
%         % windows_all: first coloumn is start time of sliding window
%         % and second column is end time of sliding window
%         windows_all(j,1) = tNN(indicies(1));
%         windows_all(j,2) = tNN(indicies(end));
%     catch
%         windows_all(j,1) = NaN;
%         windows_all(j,2) = NaN;
%     end
% end


while t_window_start <= tNN(end) - windowlength + increment
    
    % Find indices of time values in this segment
    idx_window = find(tNN >= t_window_start & tNN < t_window_start + windowlength);
    t_win = tNN(idx_window);
    
    % if NN intervals are supplied, assign them to the current window
    % if not, put in place a vector of ones as a place holder
    if ~isempty(NN)
        nn_win = NN(idx_window);
    else
        nn_win = (windowlength/length(t_win))* ones(length(t_win),1);
    end
    
    % Store the begin time of window
    windowRRintervals(i) = t_window_start;
   
    % Increment time by sliding segment length (sec)
    t_window_start = t_window_start + increment;
    
    % Check Actual Window Length and mark windows that do not meet the
    % crieria for Adequate Window Length
    % First remove unphysiologic beats from candidates for this
    % measurement:
    idxhi = find(nn_win > HRVparams.preprocess.upperphysiolim);
    idxlo = find(nn_win < HRVparams.preprocess.lowerphysiolim);
    comb = [idxhi idxlo];
    nn_win(comb) = [];
    % Now query the true length of the window by adding up all of the NN
    % intervals
    truelength = sum(nn_win(:));
    if truelength < (windowlength * (1-win_tol))
        % Only remove window if not working in 'AF' or 'SQI' Mode
        if ~strcmp(option,'af') && ~strcmp(option,'sqi')
            windowRRintervals(i) = NaN; 
        end
    end
    
    % Increment loop index
    i = i + 1;
end


end % end of function