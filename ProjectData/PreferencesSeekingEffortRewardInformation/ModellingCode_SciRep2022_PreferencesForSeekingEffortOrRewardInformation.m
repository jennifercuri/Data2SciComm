

%% Function to fit the parabolic effort discounting model to the choice data (accept or reject work offer) in Müller, Husain, & Apps (2022, Scientific Reports)

% The code is adapted from the function to fit the parabolic effort discounting model to the Pre-Task choice data in Müller, Klein-Flügge, Manohar, Husain, & Apps (2021, Nature Communications).

% The function uses negative log-likelihood and fminsearch, with participant data
% stored in/taken from "s".

%%

function model_results = parab_choice(s)


num_subs = max(size(s));
num_models = 1;

 model_names = {'parabolic_discount'}


models = { 
@(p,reward,effort,chosen,base) prob_para(p,reward,effort,chosen,base);

};

model_params = 2;
clear j
for j = 1:num_subs
    
    clear reward
    clear effort
    clear chosen
    j
    
reward = s(j).choice_only_reward;
effort = s(j).choice_only_effort;
chosen = s(j).choice_only_choice;

 chosen(isnan(chosen)) = 0;
for u = 1:length(reward)
   if chosen(u) == 0
    reward(u) = 0;
    effort(u) = 0;
  end
end

chosen = nonzeros(chosen);
reward = nonzeros(reward);
effort = nonzeros(effort);
chosen = chosen-1;


 base = 1;

for z =  1
    pfunc = (models{z});
    neg_likelihood_func = @(p) -sum(log(eps+pfunc(p,reward,effort,chosen,base))) ;
    p{z}=[]; nll(z)=inf;
    
    %for k=1:50 % use different random starting values 
    for k=1:50
      startp(1) = rand;
      startp(2) = rand;
      
 constrained_nll = @(p) neg_likelihood_func(p) + (p(1)<0.0276)*realmax + (p(2)<0)*realmax;

[pk nllk] = fminsearch( constrained_nll  , startp, ...  % find best params 
    optimset('MaxFunEvals',10000,'MaxIter',10000) );
      if nllk<nll(z)  % is this better than previous estimates?
        nll(z)=nllk; p{z}=pk; % if so, update the 'best' estimate
      end
      model_results.all_nll(j,z,k) = nllk;
      model_results.all_p{j,z,k}  = pk;
    end
    
  % for each model, store probabilities of each trial  
 model_results.prob{j,z} =   pfunc(p{z},reward,effort,chosen,base);

end % next model

likelihood = nll;
  model_results.likelihood(j,:) = nll; % LIKELIHOOD (SUBJECT, MODEL)
  model_results.params{j,:} = p; % PARAMS {SUBJECT, MODEL} ( PARAMETER_NUMBER )
  
end

model_results.models       = models;
model_results.model_names  = model_names;
model_results.model_params = model_params;

%

function prob = prob_para(p,reward,effort,chosen,base)
% p(1) = single discount parameter
% p(2) = softmax beta


discount = p(1);
beta = p(2);
val = reward-(discount.*effort.^2);
prob =  exp(val.*beta)./(exp(base*beta) + exp(beta.*val));
prob(~chosen) =  1 - prob(~chosen);
prob = prob(:,1);

% 

