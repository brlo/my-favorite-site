require "open-uri"

namespace :dict do
  STEP_LEXICONS_URL = 'https://raw.githubusercontent.com/STEPBible/STEPBible-Data/master/Lexicons/'
  STEP_LEXICONS = {
    'as'  => ['TBESG - Translators Brief lexicon of Extended Strongs for Greek - STEPBible.org CC BY.txt'],
    'lsj' => ['TFLSJ  0-5624 - Translators Formatted full LSJ Bible lexicon - STEPBible.org CC BY.txt',
              'TFLSJ extra - Translators Formatted full LSJ Bible lexicon - STEPBible.org CC BY.txt'],
  }

  # Словари Abbott-Smith и LSJ (STEPBible) для слов подстрочника: bin/rails dict:import_step
  # Файлы качаются с GitHub STEPBible в tmp/step_lexicons (уже скачанные не перекачиваются, DIR=... - своя папка).
  desc "Import Abbott-Smith and LSJ entries from STEPBible lexicons for interlinear words"
  task :import_step => :environment do
    dir = Pathname(ENV.fetch('DIR', Rails.root.join('tmp/step_lexicons').to_s))
    FileUtils.mkdir_p(dir)

    files = STEP_LEXICONS.transform_values do |names|
      names.map do |name|
        path = dir.join(name)
        unless path.exist?
          puts "download: #{name}"
          path.binwrite(URI.open(STEP_LEXICONS_URL + ERB::Util.url_encode(name)).read)
        end
        path.to_s
      end
    end

    puts ::StepLexiconImporter.call(files).inspect
  end
end
