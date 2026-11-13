# Определение ботов по User-Agent.
#
# Основную работу делает гем browser (его список краулеров регулярно обновляется),
# сюда дописываем только тех, кого гем не узнаёт. Кандидатов видно по логам nginx
# и по блоку «Топ IP» в админской сводке.
class BotDetector
  # имя для сводки => регулярка по User-Agent
  CUSTOM_BOTS = {
    'Turnitin'    => /turnitin/i,      # антиплагиат-краулер
    'pdfmin'      => /pdfmin/i,        # качает PDF-версии страниц
    'axios'       => /\baxios\//i,     # http-клиент из node.js
    'Claude-User' => /claude-user|claude-code/i,
  }.freeze

  # заглушки на месте настоящего User-Agent (реальный браузер всегда присылает полный UA)
  JUNK_UAS = ['-', 'android', 'unknown'].freeze

  class << self
    # browser — объект Browser (гем browser) или nil
    def bot?(browser)
      return false if browser.nil?
      return true if browser.bot?

      ua = browser.ua.to_s
      JUNK_UAS.include?(ua) || CUSTOM_BOTS.any? { |_name, regexp| ua.match?(regexp) }
    end

    # имя бота для сводки; осмысленно только когда bot? вернул true
    def bot_name(browser)
      return browser.bot.name if browser&.bot?

      ua = browser&.ua.to_s
      CUSTOM_BOTS.each { |name, regexp| return name if ua.match?(regexp) }
      return 'UA-заглушка' if JUNK_UAS.include?(ua)

      nil
    end
  end
end
