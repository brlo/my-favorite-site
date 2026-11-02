book, ch, from, to = ARGV[0], ARGV[1].to_i, (ARGV[2] || 1).to_i, (ARGV[3] || 999).to_i
::Verse.where(tr_code: 'gr-ru', book: book, chapter: ch, line: from..to).order(:line).each { |v| puts "#{v.line}: #{v.data['w'].join(' ')}" }
