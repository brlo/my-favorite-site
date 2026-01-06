require 'shellwords'
require 'json'

class GitPageVersioningService
  # REPO_PATH = Rails.root.join('tmp/wiki_repo')
  # MAIN_BRANCH = 'main'

  # def initialize
  #   ensure_repo!
  # end

  # # === 1. Предложить правки ===
  # def propose_edit(page:, user:, new_content:, comment: nil)
  #   mr = MergeRequest.create!(
  #     page: page,
  #     user: user,
  #     comment: comment,
  #     status: 0 # pending
  #   )

  #   branch_name = "mr/#{mr.id}"

  #   GitLock.synchronize do
  #     # Создаём ветку из main
  #     run_git("checkout #{MAIN_BRANCH}")
  #     run_git("checkout -b #{branch_name}")

  #     # Сохраняем файл статьи
  #     write_page_file(page, new_content, branch_name)

  #     # Коммитим
  #     run_git("add .")
  #     author = "#{user.name} <#{user.email}>"
  #     run_git(%Q[commit -m "Propose edit for page #{page.path} (MR ##{mr.id})" --author=#{Shellwords.escape(author)}])
  #   end

  #   mr.update!(source_branch: branch_name)
  #   mr
  # end

  # # === 2. Показать diff ===
  # def diff(mr)
  #   page = mr.page
  #   filepath = page_file_path(page)

  #   GitLock.synchronize do
  #     # Получаем содержимое из main и из MR-ветки
  #     old_content = file_content_at(filepath, MAIN_BRANCH)
  #     new_content = file_content_at(filepath, mr.source_branch)

  #     # Используем diffy для красивого HTML
  #     Diffy::Diff.new(
  #       old_content,
  #       new_content,
  #       format: :html,
  #       css: :class,
  #       diff: :lines # или :words, если хочешь по словам
  #     ).to_s
  #   end
  # end

  # # === 3. Принять правки ===
  # def accept_merge_request(mr)
  #   raise "MR already processed" unless mr.status == 0

  #   GitLock.synchronize do
  #     # Переключаемся на main
  #     run_git("checkout #{MAIN_BRANCH}")

  #     # Мержим MR-ветку
  #     run_git("merge #{mr.source_branch} --no-ff -m 'Merge MR ##{mr.id}'")

  #     # (опционально) удаляем ветку
  #     # run_git("branch -d #{mr.source_branch}")
  #   end

  #   mr.update!(status: 1) # merged
  # end

  # # === 4. Отклонить правки ===
  # def reject_merge_request(mr)
  #   raise "MR already processed" unless mr.status == 0
  #   # Ничего в Git не делаем — просто помечаем
  #   mr.update!(status: 2) # rejected
  # end

  # # === 5. Rebase MR на main (если устарел) ===
  # def rebase_merge_request(mr)
  #   raise "Cannot rebase non-pending MR" unless mr.status == 0

  #   GitLock.synchronize do
  #     run_git("checkout #{mr.source_branch}")
  #     result = run_git("rebase #{MAIN_BRANCH}", raise_on_error: false)

  #     if $?.success?
  #       true
  #     else
  #       # Конфликты — возвращаем false или текст ошибки
  #       false
  #     end
  #   end
  # end

  # private

  # def ensure_repo!
  #   return if Dir.exist?(File.join(REPO_PATH, '.git'))

  #   FileUtils.mkdir_p(REPO_PATH)
  #   Dir.chdir(REPO_PATH) do
  #     system("git init --initial-branch=#{MAIN_BRANCH}")
  #     system("git config user.name 'WikiBot'")
  #     system("git config user.email 'wiki@yoursite.com'")
  #     # Создаём начальный коммит (пустой)
  #     system("git commit --allow-empty -m 'Initial commit'")
  #   end
  # end

  # def page_file_path(page)
  #   lang = page.lang
  #   path = page.path
  #   filename = path.blank? ? "index.json" : "#{path}.json"
  #   File.join(lang, filename)
  # end

  # def write_page_file(page, content, branch)
  #   # content — хэш с полями статьи
  #   filepath = File.join(REPO_PATH, page_file_path(page))
  #   FileUtils.mkdir_p(File.dirname(filepath))
  #   File.write(filepath, JSON.pretty_generate(content))
  # end

  # def file_content_at(filepath, ref)
  #   full_path = File.join(REPO_PATH, filepath)
  #   # Если файла нет в этой ветке — вернёт пустую строку
  #   `cd #{REPO_PATH} && git show #{Shellwords.escape(ref)}:#{Shellwords.escape(filepath)} 2>/dev/null`.chomp
  # rescue
  #   ""
  # end

  # def run_git(command, raise_on_error: true)
  #   cmd = "cd #{REPO_PATH} && git #{command}"
  #   output = `#{cmd} 2>&1`
  #   unless $?.success?
  #     raise "Git command failed: #{cmd}\n#{output}" if raise_on_error
  #   end
  #   output
  # end
end
