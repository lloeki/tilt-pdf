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
      files = aux_files
      files << main_html_file
      render_to_tmp(*files, scope, locals, block) do |tmp|
        opts = pdfkit_options

        if header
          htmp = tmp.select { |_, f, _| f == header }.first[2]
          opts.merge!('header-html' => htmp) if header
        end

        if footer
          ftmp = tmp.select { |_, f, _| f == footer }.first[2]
          opts.merge!('footer-html' => ftmp) if footer
        end

        main = tmp.select { |_, f, _| f == main_html_file }.first[2]
        kit = PDFKit.new(File.read(main), opts)

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
      files = []
      files.concat css_files
      files.concat js_files
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

    def js_files
      js_from_config || find_js
    end

    def js_from_config
      return unless config.key?('javascripts')

      config.fetch('javascripts', []).map { |f| absolutize(f) }
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

    def find_js
      Dir.glob(File.join(dirname, name + '.js*'))
    end

    def render_html(file, scope, locals, &block)
      Tilt.new(file).render(scope, locals, &block)
    end

    def inject_css!(document, stylesheet)
      append_to_head!(document, "<style>#{stylesheet}</style>")
    end

    def inject_js!(document, script)
      append_to_head!(document, "<script>#{script}</script>")
    end

    def append_to_head!(document, tag)
      if document.match(/<\/head>/)
        document.gsub!(/(<\/head>)/) { |s| tag + s }
      else
        document.insert(0, tag)
      end
    end

    def render_to_tmp(*files, scope, locals, block)
      tmps = []
      no_tilt = %w[html css js]

      result = files.map do |file|
        ext = File.extname(file).sub(/^\./, '')
        if no_tilt.include?(ext)
          mime = case ext
                 when 'js', 'javascript' then 'application/javascript'
                 else "text/#{ext}"
                 end
          rendered = File.read(file)
        else
          template = Tilt.new(file)
          mime = template.class.default_mime_type
          ext = mime.split('/').last
          rendered = template.render(scope, locals, &block)
        end

        [ext, mime, file, rendered]
      end

      result.sort! do |a, b|
        a[1] <=> b[1]  # css < html
      end

      styles = result.select { |_, mime, _, _| mime == 'text/css' }
      scripts = result.select { |_, mime, _, _| mime == 'application/javascript' }
      result.map! do |ext, mime, file, rendered|
        if mime == 'text/html'
          styles.each do |_, _, _, style|
            inject_css!(rendered, style)
          end
          scripts.each do |_, _, _, script|
            inject_js!(rendered, script)
          end
        end

        [ext, mime, file, rendered]
      end

      result.map! do |ext, mime, file, rendered|
        tmp = Tempfile.new([File.basename(file), '.' + ext])
        tmps << tmp
        tmp.write(rendered)
        tmp.close

        path = tmp.path

        [mime, file, path]
      end

      yield result
    ensure
      tmps.each { |tmp| tmp.close! }
    end
  end
end

Tilt.register Tilt::PDFTemplate, 'rpdf'
