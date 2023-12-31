class ApplicationMongoRecord
  def updated_at_word
    time = self.updated_at
    diff_sec = Time.now - time

    if diff_sec < 3.minute.to_i
      'Сейчас'
    elsif diff_sec < 60.minutes.to_i
      min = (diff_sec / (60)).to_i
      "#{min} мин."
    elsif diff_sec < 24.hours.to_i
      h = (diff_sec / (60*60)).to_i
      "#{h} ч."
    elsif diff_sec < 30.days.to_i
      d = (diff_sec / (60*60*24)).to_i
      "#{d} д."
    else
      time.strftime("%Y-%m-%d %H:%M:%S")
    end
  end

  private

  def sanitizer
    @sanitizer ||= ::Rails::Html::SafeListSanitizer.new
  end
end
