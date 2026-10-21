require 'nokogiri'

# Том CCEL (ANF/NPNF) в формате ThML: метаданные и разделы (div1..div6) по их id.
module Ccel
  class Volume
    SERIES = {
      'anf'   => 'Ante-Nicene Fathers',
      'npnf1' => 'Nicene and Post-Nicene Fathers, Series I',
      'npnf2' => 'Nicene and Post-Nicene Fathers, Series II',
    }.freeze

    DIV = /\Adiv[1-6]\z/

    attr_reader :code, :doc

    def self.load(dir, code)
      new(code, ::File.read(::File.join(dir, "#{code}.xml")))
    end

    def initialize(code, xml)
      @code = code
      @doc = ::Nokogiri::XML(xml) { |c| c.noent.huge }
    end

    # "ANF01. The Apostolic Fathers with Justin Martyr and Irenaeus"
    def title
      @title ||= squish(@doc.at_xpath('/ThML/ThML.head//DC.Title')&.text)
    end

    # "anf01" -> "anf", "npnf109" -> "npnf1"
    def series_code = code[/\A(anf|npnf[12])/, 1]

    def series = SERIES[series_code]

    # "anf01" -> 1, "npnf214" -> 14
    def number = code[/\d{2}\z/].to_i

    def editors
      @editors ||= @doc.xpath('/ThML/ThML.head//DC.Creator[@scheme="short-form"]').map { squish(_1.text) }.uniq
    end

    def url(node_id = nil)
      base = "https://ccel.org/ccel/schaff/#{code}"
      node_id ? "#{base}/#{code}.#{node_id}.html" : base
    end

    def node(id)
      @nodes ||= divs.index_by { _1['id'] }
      @nodes[id] or raise ArgumentError, "#{code}: нет раздела #{id}"
    end

    def divs = @doc.xpath('//ThML.body//*[starts-with(name(), "div")]').select { DIV.match?(_1.name) }

    def self.div?(el) = el.element? && DIV.match?(el.name)

    def self.children_divs(el) = el.element_children.select { div?(_1) }

    # Заголовок раздела: атрибут title, иначе первый h1-h6 внутри
    def self.title_of(el)
      t = el['title'].to_s
      t = el.at_xpath('./*[self::h1 or self::h2 or self::h3 or self::h4 or self::h5]')&.text.to_s if t.strip.empty?
      t.gsub(/\s+/, ' ').strip
    end

    # Автор по разметке CCEL: <ThML.head> перед разделом (есть только в ANF)
    def self.ccel_author_of(el)
      head = el.previous_element
      head&.name == 'ThML.head' ? head.at_xpath('.//authorID')&.text : nil
    end

    # Номера печатных страниц внутри раздела: ["1", "21"]
    def self.page_range(el)
      pages = el.xpath('.//pb/@n').map(&:value)
      pages.empty? ? [] : [pages.first, pages.last].uniq
    end

    private

    def squish(str) = str.to_s.gsub(/\s+/, ' ').strip
  end
end
