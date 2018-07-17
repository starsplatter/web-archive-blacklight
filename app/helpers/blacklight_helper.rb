module BlacklightHelper
  include Blacklight::BlacklightHelperBehavior

def weblink options={}
options[:document] # the original document
options[:field] # the field to render
options[:value] # the value of the field
if !options[:value].blank?
    link_to options[:value][0],options[:value][0]
end
end
end