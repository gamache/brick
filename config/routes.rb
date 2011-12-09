Brick::Application.routes.draw do
  get 'maag/:year', :to => 'maag#show'
  get 'maag', :to => 'maag#show'

  resources :players, :only => [:show]

  root :to => 'maag#show'
end
