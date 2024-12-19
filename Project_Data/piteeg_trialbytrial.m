clear all
close all
clc

%% Import data from CSV file
% Update the path to your CSV file
opts = delimitedTextImportOptions("NumVariables", 8);

% Specify range and delimiter
opts.DataLines = [2, Inf];
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["VarName1", "CS", "res", "nres", "trial", "rt", "hrv", "ID"];
opts.VariableTypes = ["double", "categorical", "double", "double", "double", "double", "double", "string"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, "ID", "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["CS", "ID"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, "res", "TrimNonNumeric", true);
opts = setvaropts(opts, "res", "ThousandsSeparator", ",");

% Import the data
tbl = readtable('/Users/jencuri/Documents/GitHub/Data2SciComm/Project_Data/DB.csv', opts);

%% Convert to output type
VarName1 = tbl.VarName1;
CS = tbl.CS;
res = tbl.res;
nres = tbl.nres;
trial = tbl.trial;
rt = tbl.rt;
hrv = tbl.hrv;
ID = tbl.ID;

subj = unique(ID);

% Initialize cell arrays
cs = cell(1, length(subj));
response = cell(1, length(subj));
nresponse = cell(1, length(subj));
trials = cell(1, length(subj));
rt_data = cell(1, length(subj));

for zz = 1:length(subj)
    IDindex = find(ID == subj(zz));
    cs{zz} = CS(IDindex);
    response{zz} = res(IDindex);
    nresponse{zz} = nres(IDindex);
    trials{zz} = trial(IDindex);
    rt_data{zz} = rt(IDindex);
    clear IDindex
end

%% Clear temporary variables
clear opts tbl CS res nres trial

%% EXCLUSION OF RT OUTLIERS (+-2 SD from the mean for each subject)
rtNOoutliers = cell(1, length(subj));
csNOoutliers = cell(1, length(subj));
typeNOoutliers = cell(1, length(subj));

for zz = 1:length(subj)
    meanCS = mean(rt_data{zz});
    stdCS = std(rt_data{zz});
    indexnooutliers = find(rt_data{zz} > (meanCS - 2 * stdCS) & rt_data{zz} < (meanCS + 2 * stdCS));
    rtNOoutliers{zz} = rt_data{zz}(indexnooutliers);
    csNOoutliers{zz} = cs{zz}(indexnooutliers);
    typeNOoutliers{zz} = response{zz}(indexnooutliers);
    clear meanCS stdCS indexnooutliers
end

%% REACTION TIME ANALYSIS
% Extracting mean reaction times for each subject after excluding outliers
rtpercs = [];

for zz = 1:length(subj)
    rtpercs(zz, :) = [subj(zz), mean(rtNOoutliers{zz})];
end

%% SAVE REACTION TIMES TO CSV FILE
% Save the extracted reaction times to a CSV in your Downloads folder
writematrix(rtpercs, '/Users/jencuri/Downloads/reaction_times.csv');
