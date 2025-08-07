# # Создаёт файлы пдф-версии страниц на диске, отдаёт относительный путь к файлу.

# class PdfGenerator
#   # PdfGenerator.path_to_page_pdf(page, is_rebuild: false)
#   def self.path_to_page_pdf(page, is_rebuild: false)
#     # путь к файлу, где пдф уже мог быть сгенерирован
#     page_pdf_path = "/s/page_pdfs/#{page.id.to_s}.pdf"

#     # Если пдф уже сгенерирован, то просто отдаём путь к нему, не надо генерировать его опять
#     # (при изменении страницы, файл просто удаляется, без пересоздания)
#     return page_pdf_path if ::File.exist?("public/#{page_pdf_path}") && is_rebuild != true

#     if page.parent_id
#       parent_page = ::Page.only(:id, :p_id, :title, :path, :page_type).find_by!(id: page.parent_id)
#     end

#     clazzs = page.is_page_verses? ? 'verse-page' : 'text-page'
#     html = []
#     html << "<!DOCTYPE html lang='ru'><html>"

#     # мета - css
#     html << '<head><meta charset="UTF-8">'
#     html << '<style>mark {background-color: transparent;color: #ef4848;}</style>'
#     html << '</head>'

#     html << '<body style="background-color: #f6f4e4; padding: 0 25px;">'

#     # шапка
#     html << '
#       <header>
#         <div class="container">
#           <div class="logo">
#             <a href="https://bibleox.com/">
#               <img src="https://res.bibleox.com/logo/bibleox.png">
#             </a>
#           </div>
#         </div>
#       </header>'

#     html << '<div class="flex-wrap">'
#     html << '<div class="content main">'

#     html << "<section id='page-content' class='looks-like-page #{clazzs}'>"

#     html << "<div style='text-align: center;'>"
#     if parent_page.present?
#       html << "<h2 class='parent-title'><a href='https://bibleox.com/ru/ru/w/#{parent_page.path}'>#{parent_page.title}</a></h2>"
#     end
#     html << "<h1><a href='https://bibleox.com/ru/ru/w/#{page.path}'>#{page.title}</a></h1>"
#     html << "<div id='title-sub'>#{page.title_sub}</div>"
#     html << "</div>"

#     html << "<article id='page-body' itemprop='articleBody' class='verses'>"

#     # МЕНЮ (для страницы в виде стихов меню не делаем)
#     if page.body_menu.present? && !page.is_page_verses?
#       html << ActionController::Base.new.render_to_string(
#         partial: 'pages/body_menu',
#         layout: false,
#         locals: { page: page }
#       )
#     end

#     # ТЕКСТ СТАТЬИ
#     if page.body_rendered.present?
#       # СТАТЬЯ СТИХАМИ
#       if page.is_page_verses? && page.verses.present?
#           i_glob = 0
#           page.verses.each do |chapter_data|
#             if chapter_data['title'].present?
#               html << "<h3>#{ chapter_data['title'].to_s.html_safe }</h3>"
#             end

#             chapter_data['lines'].each do |l|
#               i_glob << 1
#               html << "<p>#{i_glob}. #{l.html_safe}</p>"
#             end
#           end
#       else
#         # СТАТЬЯ ОБЫЧНЫМ ТЕКСТОМ
#         html << page.body_rendered.html_safe
#       end
#     else
#       # КАКОЙ_ТО ДРУГОЙ НЕИЗВЕСТНЫЙ СЛУЧАЙ
#       html << page.body.to_s.html_safe
#     end

#     html << "</article>"

#     # СНОСКИ
#     if page.references.present?
#       html << "<section id='page-references' class='looks-like-page'>"
#       html << "  <h2 id='page-references-title'>#{::I18n.t('page.references') }</h2>"
#       html << "  <div id='page-references-text'>"
#       if page.body_rendered.present?
#         html << page.references_rendered.to_s.html_safe
#       else
#         html << page.references.to_s.html_safe
#       end
#       html << "  </div>"
#       html << "</section>"

#       html << '</div>'
#       html << '</div>'

#       html << "</body></html>"
#     end

#     html = html.join # КОНЕЦ HTML

#     # Генерация PDF
#     ::Grover.configure do |config|
#       config.options = {
#         format: 'A4',
#         margin: {
#           top: '1cm',
#           bottom: '1cm'
#         },
#         # Можно посмотреть некоторую информацию из хост-машины: http://localhost:9222/json/version
#         # Но между машинами в докере, chrome доступен по стандартному его порту 3000
#         browser_ws_endpoint: "ws://chrome:3000/chrome",
#       }
#     end

#     grover = ::Grover.new(html, format: 'A4', style_tag_options: [
#       { path: "#{Rails.root}/app/assets/stylesheets/application.css" },
#       { path: "#{Rails.root}/app/assets/stylesheets/custom.css" },
#       { path: "#{Rails.root}/app/assets/stylesheets/page.css" },
#     ])
#     pdf = grover.to_pdf

#     # # Сохранение PDF в файл (открываем для записи (w) в бинарном режиме (b), потому что в pdf находятся бинарные данные)
#     # file = nil
#     # begin
#     #   # Создаем временный файл, затем переименовываем (атомарная операция)
#     #   temp_path = "tmp/#{path}.pdf.tmp"
#     #   File.open(temp_path, 'wb') { |f| f.write(pdf) }
#     #   File.rename(temp_path, "public/#{page_pdf_path}")
#     # rescue => e
#     #   Rails.logger.error " === PDF generation failed: #{e.message}"
#     #   File.delete(temp_path) if File.exist?(temp_path)
#     #   raise
#     # end
#     # Сохранение PDF в файл (открываем для записи (w) в бинарном режиме (b), потому что в pdf находятся бинарные данные)
#     file = nil
#     begin
#       file = ::File.open("public/#{page_pdf_path}", 'wb')
#       file.write(pdf)
#     ensure
#       file&.close
#     end
#     # страница в формате пдф-сгенерирована, отдаём путь к файлу
#     page_pdf_path
#   end

#   # Удалить пдф-версию страницы (вызывается при изменении страницы)
#   def self.page_pdf_remove(page)
#     page_pdf_path = "/s/page_pdfs/#{page.id.to_s}.pdf"
#     if ::File.exist?("public/#{page_pdf_path}")
#       ::File.delete("public/#{page_pdf_path}")
#     end
#   end
# end
