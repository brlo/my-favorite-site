module Api
  class StatsController < ApiApplicationController
    before_action :reject_by_read_privs
    # before_action :reject_by_update_privs, only: [:create, :update, :destroy]

    def visits
      @week_visits = ::PageVisits.week_visits()

      render(json: {'success': 'ok', week_visits: @week_visits}, status: :ok)
    end

    private

    def success_response
      {'success': 'ok'}
    end

    def reject_by_read_privs
      if !::Current.user.ability?('pages_read')
        render json: {success: 'fail', errors: 'access denied'}, status: 401
      end
    end

    def reject_by_update_privs
      if !::Current.user.ability?('pages_update')
        render json: {success: 'fail', errors: 'access denied'}, status: 401
      end
    end

    # def dump
    #   data = ''

    #   ::QuotesPage.order(title: 1).each do |qp|
    #     data += "<START>\n"
    #     data += "title\n"
    #     data += qp.title.to_s + "\n"
    #     data += "meta_desc\n"
    #     data += qp.meta_desc.to_s + "\n"
    #     data += "lang\n"
    #     data += qp.lang.to_s + "\n"
    #     data += "path\n"
    #     data += qp.path.to_s + "\n"
    #     data += "s_id\n"
    #     data += qp.s_id.to_s + "\n"
    #     data += "position\n"
    #     data += qp.position.to_s + "\n"
    #     data += "body\n"
    #     data += qp.body.to_s + "\n"
    #     data += "<END>\n"
    #   end

    #   send_data(
    #     data,
    #     :filename => "bibleox-quotes-#{Date.today}.txt",
    #     :type => "text/plain"
    #   )
    # end
  end
end
