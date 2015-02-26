class IdentitiesController < ApplicationController
  skip_before_filter :authorize!, :only => [:new]
  layout 'bare'

  def new
    @identity = env['omniauth.identity']
  end
end
