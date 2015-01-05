class CoursesOfActionController < ComponentsController
  def index
    @components = CourseOfAction.all.group_by {|c| c.type.try(&:value) }
    @components['Unknown Type'] = @components.delete(nil) if @components[nil]
  end

  def klass
    CourseOfAction
  end
end
