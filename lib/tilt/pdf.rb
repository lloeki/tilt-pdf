require 'pdfkit'
require 'tilt'
require 'tilt/template'
require 'yaml'
require 'tempfile'

module Tilt
  class PDFTemplate < Template
    self.default_mime_type = 'application/pdf'

    def prepare; end

    def evaluate(scope, locals, &block)
      main = render_html(main_html_file, scope, locals, &block)

      render_css(*css_files) do |*css|
        kit = PDFKit.new(main, pdfkit_options)
        css.each { |f| kit.stylesheets << f }
        @output = kit.to_pdf
      end

      @output
    end

    private

    def absolutize(path)
      Pathname.new(path).absolute? ? path : File.join(dirname, path)
    end

    def config
      @config = (YAML.load(data) || {})
    end

    def main_html_file
      main_html_from_config || find_html
    end

    def main_html_from_config
      if (f = config['main'])
        absolutize(f)
      end
    end

    def css_files
      css_from_config || find_css
    end

    def css_from_config
      return unless config.key?('stylesheets')

      config.fetch('stylesheets', []).map { |f| absolutize(f) }
    end

    def pdfkit_options
      config.fetch('pdfkit', {})
    end

    def dirname
      File.dirname(eval_file)
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
