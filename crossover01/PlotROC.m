function PlotROC (datafile)

% PlotROC plots the ROC points from each setsize
% 
% One argument must be provided, giving the path to the file
% containing data to plot.

% Authors: David E. Fencsik
% $LastChangedDate$

if nargin < 1 || isempty(datafile)
   error('data filename missing');
end

fid = fopen(datafile, 'r');
if fid == -1, error(sprintf('Cannot open file %s for reading', datafile)); end

%%% load header information
format = ['%s', repmat(' %s', 1, 24)];
header2 = textscan(fid, format, 1, 'delimiter', '\t');
header = cell(1, length(header2));
for n = 1:length(header2)
   header{n} = header2{n}{1};
end

% for n = 1:length(header)
%    fprintf('header{%d} = %s\n', n, header{n});
% end

%%% which columns go with certain variables
colSubject = find(strcmp(header, 'sinit'));
colCondition = find(strcmp(header, 'cond'));
colPractice = find(strcmp(header, 'pr/exp'));
colTrial = find(strcmp(header, 'ctr'));
colSetSize = find(strcmp(header, 'ss'));
colTarget = find(strcmp(header, 'TP?'));
colError = find(strcmp(header, 'err'));
colNoise = find(strcmp(header, 'noiseParam'));

%%% load the remaining data
format = '%s %s %d %s %s %s %s %d %d %f %d %d %d %d %f %s %d %d %d %d %s %s %d %d %f';
dt = textscan(fid, format, 10000, 'delimiter', '\t');
fclose(fid);

subject = dt{colSubject};
condition = dt{colCondition};
trial = dt{colTrial};
setsize = dt{colSetSize};
target = dt{colTarget};
prac = strcmp(dt{colPractice}, 'practice');
correct = 1 - dt{colError};
noise = dt{colNoise};

% filter out DEF's extraneous trials
filter = ~(strcmp(subject, 'DEF') & strcmp(condition, 'Conj') & noise == 0.75);
subject = subject(filter);
condition = condition(filter);
trial = trial(filter);
setsize = setsize(filter);
target = target(filter);
prac = prac(filter);
correct = correct(filter);
noise = noise(filter);

AllConditions = sort(unique(condition));
AllNoiseLevels = sort(unique(noise));
AllSetSizes = sort(unique(setsize));

dprime = nan(length(AllSetSizes), length(AllNoiseLevels));
x = AllSetSizes;

Subjects = sort(unique(subject));
for nsub = 1:length(Subjects)
   sub = Subjects{nsub};
   % filter out all other subjects
   filterSub = strcmp(subject, sub) & prac == 0;
   % figure out which condition this subject ran in
   Conditions = sort(unique(condition(filterSub)));

   figure;
   colors = 'bgrcmyk';
   points = 'os^x+d*';
   counter = 1;

   for ncond = 1:length(Conditions)
      cond = Conditions{ncond};
      % filter out all other conditions and subjects
      filterSubCond = filterSub & strcmp(condition, cond);
      % figure out which noise levels were run for this condition and subject
      NoiseLevels = sort(unique(noise(filterSubCond)));
      SetSizes = sort(unique(setsize(filterSubCond)));
      
      npos = nan(length(SetSizes), length(NoiseLevels));
      nneg = npos; cpos = npos; cneg = npos;
      
      for n = 1:length(NoiseLevels)
         % filter out all other noise levels (etc.)
         filterSubCondNoise = filterSubCond & noise == NoiseLevels(n);
         % figure out which setsizes were run at this noise level (etc.)
         SetSizes = sort(unique(setsize(filterSubCondNoise)));

         for s = 1:length(SetSizes)
            % filter out all other setsizes (etc.)
            filter = filterSubCondNoise & setsize == SetSizes(s);

            % compute total trials for target present/absent
            npos(s, n) = length(correct(filter & target));
            nneg(s, n) = length(correct(filter & ~target));
            % compute number of correct responses for target present/absent
            cpos(s, n) = sum(correct(filter & target));
            cneg(s, n) = sum(correct(filter & ~target));

         end % loop over setsizes

      end % loop over noise levels

      % correct counts
      index = cpos == 0;    if any(any(index)), cpos(index) = 0.5;               end
      index = cpos == npos; if any(any(index)), cpos(index) = npos(index) - 0.5; end
      index = cneg == 0;    if any(any(index)), cneg(index) = 0.5;               end
      index = cneg == nneg; if any(any(index)), cneg(index) = nneg(index) - 0.5; end

      % compute d', etc.
      [dprime, ci, hr, fa] = ComputeDprime(cpos, cneg, npos, nneg);

      fprintf('  Noise  SetSize Pos  Neg   Hits  TNegs   HitRate FARate   d''\n');
      legendtext = cell(1, length(NoiseLevels));
      for n = 1:length(NoiseLevels)
         for s = 1:length(SetSizes)
            fprintf('%8.5f%5.0f  %5.0f%5.0f%7.1f%7.1f%8.2f%8.2f%7.2f\n', ...
                    NoiseLevels(n), SetSizes(s), ...
                    npos(s, n), nneg(s, n), cpos(s, n), cneg(s, n), ...
                    hr(s, n), fa(s, n), dprime(s, n));
            % plot ROC points
            plot(fa(s, n), hr(s, n), [colors(counter), points(counter)], ...
                 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'w');
            hold on;
            text(fa(s, n)+.025, hr(s, n), sprintf('SS%02d', SetSizes(s)), ...
                 'Color', colors(counter));
         end
      end
      axis([0 1 0 1], 'square');
      title(sprintf('Subject %s', sub, cond));
      xlabel('False-alarm rate');
      ylabel('Hit rate');
      plot([0 1], [0 1], 'k:');
      plot([0 1], [1 0], 'k:');

      counter = counter + 1;
   end % loop over conditions
   hold off;

end % loop over subjects



% function to compute dprimes and 95%-confidence intervals around them
function [dprime, ci, hr, fa] = ComputeDprime (cpos, cneg, npos, nneg)
hr = cpos ./ npos;
fa = 1 - cneg ./ nneg;
phiHR = 1 ./ sqrt(2*pi) .* exp(-.5 .* norminv(hr));
phiFA = 1 ./ sqrt(2*pi) .* exp(-.5 .* norminv(fa));
dprime = norminv(hr) - norminv(fa);
ci = 1.96 * sqrt( hr .* (1-hr) ./ npos ./ (phiHR.^2) + fa .* (1-fa) ./ nneg ./ (phiFA.^2));
