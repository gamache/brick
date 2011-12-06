Brick::Application.routes.draw do
  get 'maag/:year', :to => 'maag#show'
  get 'maag', :to => 'maag#show'
  root :to => 'maag#show'
end
