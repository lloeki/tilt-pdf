require 'pdfkit'
require 'tilt'
require 'tilt/template'
require 'yaml'

module Tilt
  class PDFTemplate < Template
    self.default_mime_type = 'application/pdf'

    def prepare; end

    def evaluate(scope, locals, &block)
      html_file = find_html
      html = render_html(html_file, scope, locals, &block)

      css_files = find_css
      render_css(*css_files) do |*css|
        kit = PDFKit.new(html, pdfkit_options)
        css.each { |f| kit.stylesheets << f }
        @output = kit.to_pdf
      end

      @output
    end

    private

    def pdfkit_options
      YAML.load(data) || {}
    end

    def dirname
      eval_file.gsub(/#{basename}$/, '').chomp('/')
    end

    def find_html
      Dir.glob(File.join(dirname, name + '.html*')).first
    end

    def find_css
      Dir.glob(File.join(dirname, name + '.css*'))
    end

    def render_html(file, scope, locals, &block)
      Tilt.new(file).render(scope, locals, &block)
    end

    def render_css(*files)
      tmps = []

      files.each do |file|
        case file
        when /.*\.css$/
          yield file
        else
          tmp = Tempfile.new(File.basename(file))
          tmps << tmp
          css = Tilt.new(file).render
          tmp.write(css)
          tmp.close
          yield tmp.path
        end
      end
    ensure
      tmps.each { |tmp| tmp.close! }
    end
  end
end

Tilt.register Tilt::PDFTemplate, 'rpdf'
