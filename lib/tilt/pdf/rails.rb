require 'tilt-pdf'
require 'action_view/template/handlers'

module ActionView
  class Template
    module Handlers
      class PDFTemplate
        class_attribute :default_format
        self.default_format = :pdf

        def call(template)
          "Tilt.new('#{template.identifier}').render(self)"
        end
      end
    end

    register_template_handler :rpdf, Handlers::PDFTemplate.new
  end
end

module Tilt::PDFTemplate::Rails
  class Railtie < ::Rails::Railtie
    config.app_generators.template_engine :rpdf
  end
end
