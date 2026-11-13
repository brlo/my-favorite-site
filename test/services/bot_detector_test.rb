require 'test_helper'

class BotDetectorTest < ActiveSupport::TestCase
  CHROME = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36'
  IPHONE = 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/147.0.0.0 Mobile/15E148 Safari/604.1'

  test 'известные гему боты определяются' do
    [
      'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)',
      'Mozilla/5.0 (compatible; YandexBot/3.0; +http://yandex.com/bots)',
      'Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; GPTBot/1.4; +https://openai.com/gptbot)',
      'Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Reflectionbot/1.0; +https://reflection.ai/bot) Chrome/151.0.0.0 Safari/537.36',
      'Mozilla/5.0 (compatible; ElevenlabsCrawler/1.0; +https://elevenlabs.io/docs/bots)',
      'TokenFoundryBot/1.0 (TFBot@service.alibaba.com)',
      'curl/8.5.0',
      '' # пустой User-Agent — тоже бот
    ].each do |ua|
      assert BotDetector.bot?(Browser.new(ua)), "должен быть ботом: #{ua[0, 50].inspect}"
    end
  end

  test 'боты, которых гем не знает, определяются кастомным списком' do
    [
      ['Turnitin (https://bit.ly/2UvnfoQ)', 'Turnitin'],
      ['msh-pdfmin/1', 'pdfmin'],
      ['axios/1.7.2', 'axios'],
      ['Claude-User (claude-code/2.1.317; +https://support.anthropic.com/)', 'Claude-User']
    ].each do |ua, name|
      browser = Browser.new(ua)
      assert BotDetector.bot?(browser), "должен быть ботом: #{ua}"
      assert_equal name, BotDetector.bot_name(browser)
    end
  end

  test 'UA-заглушки вместо браузера считаются ботами' do
    ['-', 'android'].each do |ua|
      assert BotDetector.bot?(Browser.new(ua)), "должен быть ботом: #{ua.inspect}"
      assert_equal 'UA-заглушка', BotDetector.bot_name(Browser.new(ua))
    end
  end

  test 'живые браузеры ботами не считаются' do
    [CHROME, IPHONE,
     'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 YaBrowser/26.10.0.0 Safari/537.36',
     'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/157.0.0.0 Mobile Safari/537.36'
    ].each do |ua|
      browser = Browser.new(ua)
      assert_not browser.bot?, 'гем не должен считать этот UA ботом (иначе тест проверяет не то)'
      assert_not BotDetector.bot?(browser), "не должен быть ботом: #{ua[0, 50]}"
    end
  end

  test 'имя бота из списка гема' do
    assert_equal 'Yandex', BotDetector.bot_name(Browser.new('Mozilla/5.0 (compatible; YandexBot/3.0; +http://yandex.com/bots)'))
    assert_equal 'ChatGPT', BotDetector.bot_name(Browser.new('Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; GPTBot/1.4; +https://openai.com/gptbot)'))
  end

  test 'nil браузер — не бот (старое поведение day_visit)' do
    assert_not BotDetector.bot?(nil)
    assert_nil BotDetector.bot_name(nil)
  end
end
