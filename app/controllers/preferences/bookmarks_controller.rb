class Preferences::BookmarksController < ApplicationController
  before_filter :find_class, :find_component

  def create
    result = !!current_user.add_bookmark(@component)

    respond_to do |format|
      format.json { render :json => {:success => result} }
      format.xml { render :xml => {:success => result} }
    end
  end

  def destroy
    result = !!current_user.remove_bookmark(@component)

    respond_to do |format|
      format.json { render :json => {:success => result} }
      format.xml { render :xml => {:success => result} }
    end
  end

  private

  def find_component
    @component = @class.find_by_mongo_id(params[:id])

    not_found('Component not found') if @component.nil?
  end

  def find_class
    if User::BOOKMARKABLE_CLASSES.include?(params[:class])
      @class = params[:class].constantize
    else
      not_found("Component class not found")
    end
  end
end
