module Api
  class QuotesController < ApplicationController
    def add
      quote = ::Quote.create(address: attrs[:quote_address], s_id: attrs[:subject_id])
      if quote
        render json: {id: quote._id.to_s, address: quote.address}.merge(success_response)
      else
        render json: {errors: quote.errors}, status: 422
      end
    end

    def del
      quote = ::Quote.find_by(id: params.permit(:id)[:id])
      begin
        quote.destroy!
        render json: success_response
      rescue ActiveRecord::RecordNotDestroyed => error
        render json: {errors: error.record.errors}, status: 422
      end
    end

    private

    def success_response
      {'success': 'ok'}
    end

    # def quote
      # qs = ::QuotesSubject.where(id: attrs[:id]).first
    # end

    def attrs
      @attrs ||= params.permit(:subject_id, :quote_address, :locale, :quote => {})
    end
  end
end
