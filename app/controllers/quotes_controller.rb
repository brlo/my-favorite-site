class QuotesController < ApplicationController
  def index
    @page_title = 'Избранные цитаты'
  end

  def show
    @page_title = 'Цитаты — ' + params[:topic_name]

    @topic_name = params[:topic_name]
    puts "=== params[:topic_name]: #{params[:topic_name]}"
    @topic_id = ::TOPICS[@topic_name]
    puts "=== @topic_id: #{@topic_id}"

    @quotes = ::Quote.where(topic_id: @topic_id).limit(300)
    @quotes_yes = []
    @quotes_no = []
    @quotes.each { |q| q.is_yes ? @quotes_yes.push(q) : @quotes_no.push(q) }
  end
end
