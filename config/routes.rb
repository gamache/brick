Brick::Application.routes.draw do
  get 'maag/:year', :to => 'maag#show'
  get 'maag', :to => 'maag#show'

  resources :players, :only => [:show]

  resource :locale, :only => [:show, :create]

  root :to => 'maag#show'
end
