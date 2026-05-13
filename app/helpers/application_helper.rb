module ApplicationHelper
  def yield_meta_tag(name, default = nil)
    content_for?(name) ? content_for(name) : default
  end
end
