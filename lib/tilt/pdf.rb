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

      render_to_tmp(*aux_files, scope, locals, block) do |tmp|
        opts = pdfkit_options

        if header
          htmp = tmp.select { |_, f| f =~ /#{File.basename header}/ }.first[1]
          opts.merge!('header-html' => htmp) if header
        end

        if footer
          ftmp = tmp.select { |_, f| f =~ /#{File.basename footer}/ }.first[1]
          opts.merge!('footer-html' => ftmp) if footer
        end

        kit = PDFKit.new(main, opts)
        tmp.each { |t, f| kit.stylesheets << f if t == 'text/css' }

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

    def aux_files
      files = css_files
      files << header if header
      files << footer if footer

      files
    end

    def header
      if (f = config['header'])
        absolutize(f)
      end
    end

    def footer
      if (f = config['footer'])
        absolutize(f)
      end
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

    def render_to_tmp(*files, scope, locals, block)
      tmps = []
      noop = %w[html css]

      css = files.map do |file|
        ext = File.extname(file).sub(/^\./, '')
        if noop.include?(ext)
          ["text/#{ext}", file]
        else
          template = Tilt.new(file)
          mime = template.class.default_mime_type
          ext = mime.split('/').last
          tmp = Tempfile.new([File.basename(file), '.' + ext])
          tmps << tmp
          rendered = template.render(scope, locals, &block)
          tmp.write(rendered)
          tmp.close

          [mime, tmp.path]
        end
      end

      yield css
    ensure
      tmps.each { |tmp| tmp.close! }
    end
  end
end

Tilt.register Tilt::PDFTemplate, 'rpdf'
