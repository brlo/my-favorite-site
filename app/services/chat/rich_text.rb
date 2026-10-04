require 'erb'

module Chat
  # Проверяет документ TipTap (JSON) по белому списку и строит из него HTML и простой текст.
  # HTML от клиента никогда не принимаем: он собирается здесь, на сервере.
  #
  # Узлы:  doc, paragraph, blockquote, text, hardBreak
  # Метки: bold, underline, strike, link (ссылки — только если allow_links)
  # Всё прочее (заголовки, списки, курсив и т.п.) превращается в простой текст.
  class RichText
    class Invalid < StandardError; end

    Result = Struct.new(:json, :html, :text, keyword_init: true)

    MARKS = %w[bold underline strike link].freeze
    MARK_TAGS = { 'bold' => 'strong', 'underline' => 'u', 'strike' => 's' }.freeze
    MAX_NODES = 2000
    MAX_DEPTH = 6

    def initialize(doc, allow_links:)
      @doc = doc
      @allow_links = allow_links
      @nodes = 0
      @text_length = 0
    end

    def call
      doc = @doc.respond_to?(:to_unsafe_h) ? @doc.to_unsafe_h : @doc
      doc = JSON.parse(doc) if doc.is_a?(String)
      raise Invalid, 'bad document' unless doc.is_a?(Hash) && doc['type'] == 'doc'

      blocks = normalize_blocks(Array(doc['content']), depth: 0, in_quote: false)
      blocks = trim_empty(blocks)
      raise Invalid, 'empty' if blocks.empty?
      raise Invalid, 'too long' if @text_length > Chat::MAX_TEXT_LENGTH

      json = { 'type' => 'doc', 'content' => blocks }
      Result.new(json: json, html: render_blocks(blocks), text: plain_blocks(blocks).strip)
    rescue JSON::ParserError
      raise Invalid, 'bad json'
    end

    private

    # ---------- нормализация ----------

    def normalize_blocks(nodes, depth:, in_quote:)
      raise Invalid, 'too deep' if depth > MAX_DEPTH

      result = []
      pending_inline = []
      flush = lambda do
        result << { 'type' => 'paragraph', 'content' => pending_inline } if pending_inline.any?
        pending_inline = []
      end

      nodes.each do |node|
        next unless node.is_a?(Hash)

        count_node!
        case node['type']
        when 'paragraph', 'heading', 'codeBlock'
          flush.call
          result << { 'type' => 'paragraph', 'content' => normalize_inline(Array(node['content']), depth + 1) }
        when 'blockquote'
          flush.call
          inner = normalize_blocks(Array(node['content']), depth: depth + 1, in_quote: true)
          if in_quote
            result.concat(inner) # вложенные цитаты разворачиваем
          elsif inner.any?
            result << { 'type' => 'blockquote', 'content' => inner }
          end
        when 'bulletList', 'orderedList', 'listItem', 'taskList', 'taskItem'
          flush.call
          result.concat(normalize_blocks(Array(node['content']), depth: depth + 1, in_quote: in_quote))
        when 'text', 'hardBreak'
          pending_inline.concat(normalize_inline([node], depth + 1))
        else
          # неизвестный узел: пытаемся сохранить хотя бы его текст
          flush.call
          result.concat(normalize_blocks(Array(node['content']), depth: depth + 1, in_quote: in_quote))
        end
      end
      flush.call
      result
    end

    def normalize_inline(nodes, depth)
      raise Invalid, 'too deep' if depth > MAX_DEPTH

      nodes.each_with_object([]) do |node, acc|
        next unless node.is_a?(Hash)

        count_node!
        case node['type']
        when 'text'
          text = node['text'].to_s.delete("\u0000")
          next if text.empty?

          @text_length += text.length
          item = { 'type' => 'text', 'text' => text }
          marks = normalize_marks(node['marks'])
          item['marks'] = marks if marks.any?
          acc << item
        when 'hardBreak'
          @text_length += 1
          acc << { 'type' => 'hardBreak' }
        else
          acc.concat(normalize_inline(Array(node['content']), depth + 1))
        end
      end
    end

    def normalize_marks(marks)
      Array(marks).filter_map do |mark|
        next unless mark.is_a?(Hash) && MARKS.include?(mark['type'])

        if mark['type'] == 'link'
          next unless @allow_links

          href = safe_href(mark.dig('attrs', 'href'))
          next unless href

          { 'type' => 'link', 'attrs' => { 'href' => href } }
        else
          { 'type' => mark['type'] }
        end
      end.uniq { |m| m['type'] }
    end

    def safe_href(href)
      uri = URI.parse(href.to_s.strip)
      return nil unless %w[http https].include?(uri.scheme&.downcase) && uri.host.present?

      uri.to_s[0, 2000]
    rescue URI::InvalidURIError
      nil
    end

    # убираем пустые абзацы в начале и в конце
    def trim_empty(blocks)
      blank = ->(b) { b['type'] == 'paragraph' && b['content'].all? { |n| n['type'] == 'hardBreak' || n['text'].to_s.strip.empty? } }
      blocks = blocks.drop_while(&blank)
      blocks = blocks.reverse.drop_while(&blank).reverse
      blocks
    end

    def count_node!
      @nodes += 1
      raise Invalid, 'too many nodes' if @nodes > MAX_NODES
    end

    # ---------- HTML ----------

    def render_blocks(blocks)
      blocks.map do |b|
        case b['type']
        when 'paragraph' then "<p>#{render_inline(b['content'])}</p>"
        when 'blockquote' then "<blockquote>#{render_blocks(b['content'])}</blockquote>"
        end
      end.join
    end

    def render_inline(nodes)
      nodes.map do |n|
        next '<br>' if n['type'] == 'hardBreak'

        html = ERB::Util.html_escape(n['text'])
        Array(n['marks']).each do |m|
          html =
            if m['type'] == 'link'
              href = ERB::Util.html_escape(m.dig('attrs', 'href'))
              %(<a href="#{href}" rel="nofollow ugc noopener noreferrer" target="_blank">#{html}</a>)
            else
              tag = MARK_TAGS[m['type']]
              "<#{tag}>#{html}</#{tag}>"
            end
        end
        html
      end.join
    end

    # ---------- простой текст ----------

    def plain_blocks(blocks)
      blocks.map do |b|
        case b['type']
        when 'paragraph' then plain_inline(b['content'])
        when 'blockquote' then plain_blocks(b['content']).lines.map { |l| "> #{l}" }.join
        end
      end.join("\n")
    end

    def plain_inline(nodes)
      nodes.map { |n| n['type'] == 'hardBreak' ? "\n" : n['text'] }.join
    end
  end
end
